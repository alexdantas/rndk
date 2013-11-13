require 'rndk'

module RNDK
  class MARQUEE < Widget
    def initialize(rndkscreen, xpos, ypos, width, box, shadow)
      super()

      @screen = rndkscreen
      @parent = rndkscreen.window
      @win = Ncurses.newwin(1, 1, ypos, xpos)
      @active = true
      @width = width
      @shadow = shadow

      self.set_box(box)
      if @win.nil?
        self.destroy
        # return (0);
      end

      rndkscreen.register(:MARQUEE, self)
    end

    # This activates the widget.
    def activate(mesg, delay, repeat, box)
      mesg_length = []
      start_pos = 0
      first_char = 0
      last_char = 1
      repeat_count = 0
      view_size = 0
      message = []
      first_time = true

      if mesg.nil? or mesg == ''
        return -1
      end

      # Keep the box info, setting BorderOf()
      self.set_box(box)

      padding = if mesg[-1] == ' ' then 0 else 1 end

      # Translate the string to a chtype array
      message = RNDK.char2Chtype(mesg, mesg_length, [])

      # Draw in the widget.
      self.draw(@box)
      view_limit = @width - (2 * @border_size)

      # Start doing the marquee thing...
      oldcurs = Ncurses.curs_set(0)
      while @active
        if first_time
          first_char = 0
          last_char = 1
          view_size = last_char - first_char
          start_pos = @width - view_size - @border_size

          first_time = false
        end

        # Draw in the characters.
        y = first_char
        (start_pos...(start_pos + view_size)).each do |x|
          ch = if y < mesg_length[0] then message[y].ord else ' '.ord end
          Ncurses.mvwaddch(@win, @border_size, x, ch)
          y += 1
        end
        Ncurses.wrefresh @win

        # Set my variables
        if mesg_length[0] < view_limit
          if last_char < (mesg_length[0] + padding)
            last_char += 1
            view_size += 1
            start_pos = @width - view_size - @border_size
          elsif start_pos > @border_size
            # This means the whole string is visible.
            start_pos -= 1
            view_size = mesg_length[0] + padding
          else
            # We have to start chopping the view_size
            start_pos = @border_size
            first_char += 1
            view_size -= 1
          end
        else
          if start_pos > @border_size
            last_char += 1
            view_size += 1
            start_pos -= 1
          elsif last_char < mesg_length[0] + padding
            first_char += 1
            last_char += 1
            start_pos = @border_size
            view_size = view_limit
          else
            start_pos = @border_size
            first_char += 1
            view_size -= 1
          end
        end

        # OK, let's check if we have to start over.
        if view_size <= 0 && first_char == (mesg_length[0] + padding)
          # Check if we repeat a specified number or loop indefinitely
          repeat_count += 1
          if repeat > 0 && repeat_count >= repeat
            break
          end

          # Time to start over.
          Ncurses.mvwaddch(@win, @border_size, @border_size, ' '.ord)
          Ncurses.wrefresh @win
          first_time = true
        end

        # Now sleep
        Ncurses.napms(delay * 10)
      end
      if oldcurs < 0
        oldcurs = 1
      end
      Ncurses.curs_set(oldcurs)
      return 0
    end

    # This de-activates a marquee widget.
    def deactivate
      @active = false
    end

    # This moves the marquee field to the given location.
    # Inherited
    # def move(xplace, yplace, relative, refresh_flag)
    # end

    # This draws the marquee widget on the screen.
    def draw(box)
      # Keep the box information.
      @box = box

      # Do we need to draw a shadow???
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box it if needed.
      if box
        Draw.drawObjBox(@win, self)
      end

      # Refresh the window.
      Ncurses.wrefresh @win
    end

    # This destroys the widget.
    def destroy
      # Clean up the windows.
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      self.clean_bindings(:MARQUEE)

      # Unregister this object.
      RNDK::Screen.unregister(:MARQUEE, self)
    end

    # This erases the widget.
    def erase
      if self.valid_widget?
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # This sets the widgets box attribute.
    def set_box(box)
      xpos = if @win.nil? then 0 else Ncurses.getbegx(@win) end
      ypos = if @win.nil? then 0 else Ncurses.getbegy(@win) end

      super

      self.layoutWidget(xpos, ypos)
    end

    def object_type
      :MARQUEE
    end

    def position
      super(@win)
    end

    # This sets the background attribute of the widget.
    def set_bg_attrib(attrib)
      Ncurses.wbkgd(@win, attrib)
    end

    def layoutWidget(xpos, ypos)
      rndkscreen = @screen
      parent_width = Ncurses.getmaxx(@screen.window)

      RNDK::MARQUEE.discardWin(@win)
      RNDK::MARQUEE.discardWin(@shadow_win)

      box_width = RNDK.setWidgetDimension(parent_width, @width, 0)
      box_height = (@border_size * 2) + 1

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(@screen.window, xtmp, ytmp, box_width, box_height)
      window = Ncurses.newwin(box_height, box_width, ytmp[0], xtmp[0])

      unless window.nil?
        @win = window
        @box_height = box_height
        @box_width = box_width

        Ncurses.keypad(@win, true)

        # Do we want a shadow?
        if @shadow
          @shadow_win = Ncurses.subwin(@screen.window,
                                       box_height,
                                       box_width,
                                       ytmp[0] + 1,
                                       xtmp[0] + 1)
        end
      end
    end

    def self.discardWin(winp)
      unless winp.nil?
        Ncurses.werase(winp)
        Ncurses.wrefresh(winp)
        Ncurses.delwin(winp)
      end
    end
  end
end
