require 'rndk'

module RNDK
  class BUTTON < Widget
    def initialize(screen, xplace, yplace, text, callback, box, shadow)
      super()
      @widget_type = :BUTTON

      parent_width = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)
      box_width = 0
      xpos = xplace
      ypos = yplace

      self.set_box(box)
      box_height = 1 + 2 * @border_size

      # Translate the string to a chtype array.
      info_len = []
      info_pos = []
      @info = RNDK.char2Chtype(text, info_len, info_pos)
      @info_len = info_len[0]
      @info_pos = info_pos[0]
      box_width = [box_width, @info_len].max + 2 * @border_size

      # Create the string alignments.
      @info_pos = RNDK.justifyString(box_width - 2 * @border_size,
          @info_len, @info_pos)

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = if box_width > parent_width
                  then parent_width
                  else box_width
                  end
      box_height = if box_height > parent_height
                   then parent_height
                   else box_height
                   end

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Create the button.
      @screen = screen
      # ObjOf (button)->fn = &my_funcs;
      @parent = screen.window
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)
      @shadow_win = nil
      @xpos = xpos
      @ypos = ypos
      @box_width = box_width
      @box_height = box_height
      @callback = callback
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow

      if @win.nil?
        self.destroy
        return nil
      end

      Ncurses.keypad(@win, true)

      # If a shadow was requested, then create the shadow window.
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Register this baby.
      screen.register(:BUTTON, self)
    end

    # This was added for the builder.
    def activate(actions)
      self.draw(@box)
      ret = false

      if actions.nil? || actions.size == 0
        while true
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        # Inject each character one at a time.
        actions.each do |x|
          ret = self.inject(action)
          if @exit_type == :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type and exit
      self.set_exit_type(0)
      return -1
    end

    # This sets multiple attributes of the widget.
    def set(mesg, box)
      self.set_message(mesg)
      self.set_box(box)
    end

    # This sets the information within the button.
    def set_message(info)
      info_len = []
      info_pos = []
      @info = RNDK.char2Chtype(info, info_len, info_pos)
      @info_len = info_len[0]
      @info_pos = RNDK.justifyString(@box_width - 2 * @border_size,
          info_pos[0])

      # Redraw the button widget.
      self.erase
      self.draw(box)
    end

    def get_message
      return @info
    end

    # This sets the background attribute of the widget.
    def set_bg_attrib(attrib)
      Ncurses.wbkgd(@win, attrib)
    end

    def drawText
      box_width = @box_width

      # Draw in the message.
      (0...(box_width - 2 * @border_size)).each do |i|
        pos = @info_pos
        len = @info_len
        if i >= pos && (i - pos) < len
          c = @info[i - pos]
        else
          c = ' '
        end

        if @has_focus
          c = Ncurses::A_REVERSE | c
        end

        Ncurses.mvwaddch(@win, @border_size, i + @border_size, c)
      end
    end

    # This draws the button widget
    def draw(box)
      # Is there a shadow?
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box the widget if asked.
      if @box
        Draw.drawObjBox(@win, self)
      end
      self.drawText
      Ncurses.wrefresh @win
    end

    # This erases the button widget.
    def erase
      if self.valid?
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # @see Widget#move
    def move(xplace, yplace, relative, refresh_flag)
      current_x = Ncurses.getbegx(@win)
      current_y = Ncurses.getbegy(@win)
      xpos = xplace
      ypos = yplace

      # If this is a relative move, then we will adjust where we want
      # to move to.
      if relative
        xpos = Ncurses.getbegx(@win) + xplace
        ypos = Ncurses.getbegy(@win) + yplace
      end

      # Adjust the window if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      RNDK.window_move(@win, -xdiff, -ydiff)
      RNDK.window_move(@shadow_win, -xdiff, -ydiff)

      # Thouch the windows so they 'move'.
      RNDK.window_refresh(@screen.window)

      # Redraw the window, if they asked for it.
      if refresh_flag
        self.draw(@box)
      end
    end

    # This allows the user to use the cursor keys to adjust the
    # position of the widget.
    def position
      # Declare some variables
      orig_x = Ncurses.getbegx(@win)
      orig_y = Ncurses.getbegy(@win)
      key = 0

      # Let them move the widget around until they hit return
      while key != Ncurses::KEY_ENTER && key != RNDK::KEY_RETURN
        key = self.getch([])
        if key == Ncurses::KEY_UP || key == '8'.ord
          if Ncurses.getbegy(@win) > 0
            self.move(0, -1, true, true)
          else
            RNDK.beep
          end
        elsif key == Ncurses::KEY_DOWN || key == '2'.ord
          if Ncurses.getbegy(@win) + Ncurses.getmaxy(@win) < Ncurses.getmaxy(@screen.window) - 1
            self.move(0, 1, true, true)
          else
            RNDK.beep
          end
        elsif key == Ncurses::KEY_LEFT || key == '4'.ord
          if Ncurses.getbegx(@win) > 0
            self.move(-1, 0, true, true)
          else
            RNDK.beep
          end
        elsif key == Ncurses::KEY_RIGHT || key == '6'.ord
          if Ncurses.getbegx(@win) + @win.getmaxx < Ncurses.getmaxx(@screen.window) - 1
            self.move(1, 0, true, true)
          else
            RNDK.beep
          end
        elsif key == '7'.ord
          if Ncurses.getbegy(@win) > 0 && Ncurses.getbegx(@win) > 0
            self.move(-1, -1, true, true)
          else
            RNDK.beep
          end
        elsif key == '9'.ord
          if Ncurses.getbegx(@win) + @win.getmaxx < Ncurses.getmaxx(@screen.window) - 1 &&
              Ncurses.getbegy(@win) > 0
            self.move(1, -1, true, true)
          else
            RNDK.beep
          end
        elsif key == '1'.ord
          if Ncurses.getbegx(@win) > 0 &&
              Ncurses.getbegx(@win) + @win.getmaxx < Ncurses.getmaxx(@screen.window) - 1
            self.move(-1, 1, true, true)
          else
            RNDK.beep
          end
        elsif key == '3'.ord
          if Ncurses.getbegx(@win) + @win.getmaxx < Ncurses.getmaxx(@screen.window) - 1 &&
              Ncurses.getbegy(@win) + Ncurses.getmaxy(@win) < Ncurses.getmaxy(@screen.window) - 1
            self.move(1, 1, true, true)
          else
            RNDK.beep
          end
        elsif key == '5'.ord
          self.move(RNDK::CENTER, RNDK::CENTER, false, true)
        elsif key == 't'.ord
          self.move(Ncurses.getbegx(@win), RNDK::TOP, false, true)
        elsif key == 'b'.ord
          self.move(Ncurses.getbegx(@win), RNDK::BOTTOM, false, true)
        elsif key == 'l'.ord
          self.move(RNDK::LEFT, Ncurses.getbegy(@win), false, true)
        elsif key == 'r'
          self.move(RNDK::RIGHT, Ncurses.getbegy(@win), false, true)
        elsif key == 'c'
          self.move(RNDK::CENTER, Ncurses.getbegy(@win), false, true)
        elsif key == 'C'
          self.move(Ncurses.getbegx(@win), RNDK::CENTER, false, true)
        elsif key == RNDK::REFRESH
          @screen.erase
          @screen.refresh
        elsif key == RNDK::KEY_ESC
          self.move(orig_x, orig_y, false, true)
        elsif key != RNDK::KEY_RETURN && key != Ncurses::KEY_ENTER
          RNDK.beep
        end
      end
    end

    # This destroys the button widget pointer.
    def destroy
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      self.clean_bindings

      @screen.unregister self
    end

    # This injects a single character into the widget.
    def inject(input)
      ret = false
      complete = false

      self.set_exit_type(0)

      # Check a predefined binding.
      if self.check_bind(input)
        complete = true
      else
        case input
        when RNDK::KEY_ESC
          self.set_exit_type(input)
          complete = true
        when Ncurses::ERR
          self.set_exit_type(input)
          complete = true
        when ' '.ord, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
          unless @callback.nil?
            @callback.call(self)
          end
          self.set_exit_type(Ncurses::KEY_ENTER)
          ret = 0
          complete = true
        when RNDK::REFRESH
          @screen.erase
          @screen.refresh
        else
          RNDK.beep
        end
      end

      unless complete
        self.set_exit_type(0)
      end

      @result_data = ret
      return ret
    end

    def focus
      self.drawText
      Ncurses.wrefresh @win
    end

    def unfocus
      self.drawText
      Ncurses.wrefresh @win
    end

  end
end

