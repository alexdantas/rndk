require 'rndk'

module RNDK

  class Button < Widget

    # A button with a label attached to a callback.
    #
    # ## Settings
    #
    # * `x` is the x position - can be an integer or `RNDK::LEFT`,
    #   `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `y` is the y position - can be an integer or `RNDK::TOP`,
    #   `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `label` is the String that will appear on the button.
    # * `action` is a Proc that will execute when the button is
    #   pressed.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    # ## Usage
    # ```
    # b = RNDK::Button.new(screen, {
    #                       :x => 50,
    #                       :y => 8,
    #                       :label => "</77>button",
    #                     })
    #
    # b.bind_signal(:pressed) do
    #   screen.popup_label "Button pressed"
    # end
    # ```
    #
    # @note When binding signals, remember that if you return
    #       `false` it stops executing other signals.
    #       So that's a nice idea for a `:before_pressing`
    #       signal that asks the user if he's certain of pressing.
    def initialize(screen, config={})
      super()
      @widget_type = :button
      @supported_signals += [:before_pressing, :pressed]

      x        = 0
      y        = 0
      label    = "button"
      action   = nil
      box      = true
      shadow   = false

      config.each do |key, val|
        x        = val if key == :x
        y        = val if key == :y
        label    = val if key == :label
        action   = val if key == :action
        box      = val if key == :box
        shadow   = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window
      box_width = 0
      x = x
      y = y

      self.set_box box
      box_height = 1 + 2 * @border_size

      # Translate the string to a chtype array.
      info_len = []
      info_pos = []
      @info = RNDK.char2Chtype(label, info_len, info_pos)
      @info_len = info_len[0]
      @info_pos = info_pos[0]
      box_width = [box_width, @info_len].max + 2 * @border_size

      # Create the string alignments.
      @info_pos = RNDK.justifyString(box_width - 2 * @border_size,
                                     @info_len,
                                     @info_pos)

      # Make sure we didn't extend beyond the dimensions of the
      # window.
      box_width = if box_width > parent_width
                  then parent_width
                  else box_width
                  end
      box_height = if box_height > parent_height
                   then parent_height
                   else box_height
                   end

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      x = xtmp[0]
      y = ytmp[0]

      # Create the button.
      @screen = screen
      # ObjOf (button)->fn = &my_funcs;
      @parent = screen.window
      @win = Ncurses.newwin(box_height, box_width, y, x)
      @shadow_win = nil
      @x = x
      @y = y
      @box_width = box_width
      @box_height = box_height
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow

      if @win.nil?
        self.destroy
        return nil
      end

      Ncurses.keypad(@win, true)

      set_shadow @shadow

      # Register this baby.
      screen.register(@widget_type, self)
    end

    # Sets multiple attributes of the Widget.
    #
    # See Button#initialize.
    #
    # @note Don't try to change `x`/`y` positions here,
    #       use Button#move
    # @note Don't try to change `action` here,
    #       use TODO
    def set(config)
      label    = @label
      box      = @box
      shadow   = @shadow

      config.each do |key, val|
        label    = val if key == :label
        box      = val if key == :box
        shadow   = val if key == :shadow
      end

      self.set_label(label)   if label  != @label
      self.set_box(box)       if box    != @box
      self.set_shadow(shadow) if shadow != @shadow
    end

    # Sets the text within the button.
    def set_label label
      label_len = []
      label_pos = []
      @label = RNDK.char2Chtype(label, label_len, label_pos)
      @label_len = label_len[0]
      @label_pos = RNDK.justifyString(@box_width - 2 * @border_size,
                                     label_pos[0])

      # Redraw the button widget.
      self.erase
      self.draw(box)
    end

    def get_label
      return @info
    end

    # Turns on/off the shadow around the window
    def set_shadow option
      if option and @shadow_win.nil?
          @shadow_win = Ncurses.newwin(box_height,
                                       box_width,
                                       y + 1,
                                       x + 1)

      elsif (not option) and (not @shadow_win.nil?)
          RNDK::window_delete @shadow_win
      end
    end

    # This sets the background attribute of the widget.
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
    end

    def draw_label
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
          c = RNDK::Color[:reverse] | c
        end

        Ncurses.mvwaddch(@win, @border_size, i + @border_size, c)
      end
    end

    # This draws the button widget
    def draw
      # Is there a shadow?
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box the widget if asked.
      draw_box @win if @box

      self.draw_label
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
    def move(x, y, relative, refresh_flag)
      current_x = Ncurses.getbegx(@win)
      current_y = Ncurses.getbegy(@win)
      x = x
      y = y

      # If this is a relative move, then we will adjust where we want
      # to move to.
      if relative
        x = Ncurses.getbegx(@win) + x
        y = Ncurses.getbegy(@win) + y
      end

      # Adjust the window if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      x = xtmp[0]
      y = ytmp[0]

      # Get the difference
      xdiff = current_x - x
      ydiff = current_y - y

      # Move the window to the new location.
      RNDK.window_move(@win, -xdiff, -ydiff)
      RNDK.window_move(@shadow_win, -xdiff, -ydiff)

      # Thouch the windows so they 'move'.
      RNDK.window_refresh(@screen.window)

      # Redraw the window, if they asked for it.
      if refresh_flag
        self.draw
      end
    end

    # This destroys the button widget pointer.
    def destroy
      RNDK.window_delete @shadow_win
      RNDK.window_delete @win

      self.clean_bindings

      @screen.unregister self
    end

    # Activates the Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    # @return `true` if pressed, `false` elsewhere.
    def activate(actions=[])
      self.draw
      ret = false

      if actions.nil? || actions.size == 0
        while true
          input = self.getch

          # Inject the character into the widget.
          ret = self.inject input

          return ret if @exit_type != :EARLY_EXIT
        end
      else
        # Inject each character one at a time.
        actions.each do |x|
          ret = self.inject action

          return ret if @exit_type == :EARLY_EXIT
        end
      end

      # Set the exit type and exit
      self.set_exit_type(0)
      return false
    end

    # This injects a single character into the widget.
    def inject input
      ret = false
      complete = false

      self.set_exit_type(0)

      # Check a predefined binding.
      if self.is_bound? input
        self.run_key_binding input
        #complete = true

      else
        case input
        when RNDK::KEY_ESC, Ncurses::ERR
          self.set_exit_type(input)
          complete = true

        when ' '.ord, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
          keep_going = self.run_signal_binding(:before_pressing)

          # RUBY DOESN'T HAVE BREAK INSIDE CASE..WHEN BLOCKS
          # AGHGW

          if keep_going
            run_signal_binding(:pressed)
            focus
            set_exit_type(Ncurses::KEY_ENTER)
            ret = true
            complete = true
          end

        when RNDK::REFRESH
          @screen.erase
          @screen.refresh

        else
          RNDK.beep
        end
      end

      self.set_exit_type(0) unless complete

      @result_data = ret
      ret
    end

    def focus
      self.draw_label
      Ncurses.wrefresh @win
    end

    def unfocus
      self.draw_label
      Ncurses.wrefresh @win
    end

    # @see Widget#position
    def position
      # Declare some variables
      orig_x = Ncurses.getbegx(@win)
      orig_y = Ncurses.getbegy(@win)
      key = 0

      # Let them move the widget around until they hit return
      while key != Ncurses::KEY_ENTER && key != RNDK::KEY_RETURN
        key = self.getch
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

  end
end

