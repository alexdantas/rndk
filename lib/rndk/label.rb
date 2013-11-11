require 'rndk'

module RNDK

  # Pop-up Label window.
  #
  class LABEL < RNDK::Widget

    # Raw Ncurses window.
    attr_accessor :win

    # Creates a Label Widget.
    #
    # * `xplace` is the x position - can be an integer or `RNDK::LEFT`,
    #   `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `yplace` is the y position - can be an integer or `RNDK::TOP`,
    #   `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `message` is an Array of Strings with all the lines you'd want
    #   to show. RNDK markup applies (see RNDK#Markup).
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    # If the Widget cannot be created, returns `nil`.
    def initialize(rndkscreen, xplace, yplace, mesg, box, shadow)
      return nil if mesg.class != Array or mesg.empty?

      super()
      rows = mesg.size

      parent_width  = Ncurses.getmaxx rndkscreen.window
      parent_height = Ncurses.getmaxy rndkscreen.window
      box_width  = -2**30  # -INFINITY
      box_height = 0
      xpos = [xplace]
      ypos = [yplace]
      x = 0

      self.set_box box
      box_height = rows + 2*@border_size

      @info = []
      @info_len = []
      @info_pos = []

      # Determine the box width.
      (0...rows).each do |x|

        # Translate the string to a chtype array
        info_len = []
        info_pos = []
        @info << RNDK.char2Chtype(mesg[x], info_len, info_pos)
        @info_len << info_len[0]
        @info_pos << info_pos[0]

        box_width = [box_width, @info_len[x]].max
      end
      box_width += 2 * @border_size

      # Create the string alignments.
      (0...rows).each do |x|
        @info_pos[x] = RNDK.justifyString(box_width - 2*@border_size,
                                          @info_len[x],
                                          @info_pos[x])
      end

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = if box_width > parent_width
                  then parent_width
                  else box_width
                  end
      box_height = if box_height > parent_height
                   then parent_height
                   else box_height
                   end

      # Rejustify the x and y positions if we need to
      RNDK.alignxy(rndkscreen.window, xpos, ypos, box_width, box_height)

      @screen = rndkscreen
      @parent = rndkscreen.window
      @win    = Ncurses.newwin(box_height, box_width, ypos[0], xpos[0])
      @shadow_win = nil
      @xpos = xpos[0]
      @ypos = ypos[0]
      @rows = rows
      @box_width    = box_width
      @box_height   = box_height
      @input_window = @win
      @has_focus = false
      @shadow    = shadow

      if @win.nil?
        self.destroy
        return nil
      end

      Ncurses.keypad(@win, true)

      # If a shadow was requested, then create the shadow window.
      if shadow
        @shadow_win = Ncurses.newwin(box_height,
                                     box_width,
                                     ypos[0] + 1,
                                     xpos[0] + 1)
      end

      # Register this
      rndkscreen.register(:LABEL, self)
    end

    # Obsolete entrypoint which calls Label#draw.
    def activate(actions=[])
      self.draw @box
    end

    # Sets multiple attributes of the Widget.
    #
    # See Label#initialize.
    def set(mesg, box)
      self.set_message mesg
      self.set_box box
    end

    # Sets the contents of the Label Widget.
    # @note `info` is an Array of Strings.
    def set_message info
      return if info.class != Array or info.empty?

      info_size = info.size
      # Clean out the old message.
      (0...@rows).each do |x|
        @info[x]     = ''
        @info_pos[x] = 0
        @info_len[x] = 0
      end

      @rows = if info_size < @rows
              then info_size
              else @rows
              end

      # Copy in the new message.
      (0...@rows).each do |x|
        info_len = []
        info_pos = []
        @info[x] = RNDK.char2Chtype(info[x], info_len, info_pos)
        @info_len[x] = info_len[0]
        @info_pos[x] = RNDK.justifyString(@box_width - 2 * @border_size,
                                          @info_len[x],
                                          info_pos[0])
      end

      # Redraw the label widget.
      self.erase
      self.draw @box
    end

    # Returns current contents of the Widget.
    def get_message(size)
      size << @rows
      return @info
    end

    def object_type
      :LABEL
    end

    def position
      super(@win)
    end

    # Sets the background attribute/color of the widget.
    def set_bg_attrib attrib
      Ncurses.wbkgd(@win, attrib)
    end

    # Draws the Label Widget on the Screen.
    #
    # If `box` is `true`, the Widget is drawn with a box.
    def draw(box=false)

      # Is there a shadow?
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      # Box the widget if asked.
      Draw.drawObjBox(@win, self) if @box

      # Draw in the message.
      (0...@rows).each do |x|
        Draw.writeChtype(@win,
                         @info_pos[x] + @border_size,
                         x + @border_size,
                         @info[x],
                         RNDK::HORIZONTAL,
                         0,
                         @info_len[x])
      end

      Ncurses.wrefresh @win
    end

    # This erases the label widget
    def erase
      RNDK.eraseCursesWindow @win
      RNDK.eraseCursesWindow @shadow_win
    end

    # Removes the Widget from the Screen, deleting it's
    # internal windows.
    def destroy
      RNDK.deleteCursesWindow @shadow_win
      RNDK.deleteCursesWindow @win

      self.clean_bindings :LABEL

      RNDK::Screen.unregister(:LABEL, self)
    end

    # Waits for the user to press a key.
    #
    # If no key is provided, waits for a
    # single keypress of any key.
    def wait(key=0)

      if key.ord == 0
        code = self.getch
        return code
      end

      # Only exit when a specific key is hit
      loop do
        code = self.getch
        break if code == key.ord
      end
      code
    end

  end
end
