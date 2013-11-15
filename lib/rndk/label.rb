require 'rndk'

module RNDK

  # Customizable text on the screen.
  #
  class Label < Widget

    # Raw Ncurses window.
    attr_accessor :win

    # Creates a Label Widget.
    #
    # * `x` is the x position - can be an integer or `RNDK::LEFT`,
    #   `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `y` is the y position - can be an integer or `RNDK::TOP`,
    #   `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `message` is an Array of Strings with all the lines you'd want
    #   to show. RNDK markup applies (see RNDK#Markup).
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    # If the Widget cannot be created, returns `nil`.
    def initialize(screen, config={})
      super()
      @widget_type = :label

      # This is UGLY AS HELL
      # But I don't have time to clean this up right now
      # (lots of widgets, you know)  :(
      x      = 0
      y      = 0
      text   = "label"
      box    = true
      shadow = false

      config.each do |key, val|
        x      = val if key == :x
        y      = val if key == :y
        text   = val if key == :text
        box    = val if key == :box
        shadow = val if key == :shadow
      end
      # End of darkness

      # Adjusting if the user sent us a String
      text = [text] if text.class == String
      return nil if text.class != Array or text.empty?
      rows = text.size

      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window
      box_width  = -2**30  # -INFINITY
      box_height = 0
      xpos = [x]
      ypos = [y]
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
        @info << RNDK.char2Chtype(text[x], info_len, info_pos)
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
      RNDK.alignxy(screen.window, xpos, ypos, box_width, box_height)

      @screen = screen
      @parent = screen.window
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
      screen.register(:label, self)
    end

    # Obsolete entrypoint which calls Label#draw.
    def activate(actions=[])
      self.draw @box
    end

    # Sets multiple attributes of the Widget.
    #
    # See Label#initialize.
    def set(text, box)
      # This is UGLY ATTRIBUTESS HELL
      # But I don't have time to clean this up right now
      # (lots of widgets, you know)  :(
      x      = 0
      y      = 0
      text   = "label"
      box    = false
      shadow = false

      config.each do |key, val|
        x      = val if key == :x
        y      = val if key == :y
        text   = val if key == :text
        box    = val if key == :box
        shadow = val if key == :shadow
      end

      self.set_message text if defined? text
      self.set_box box      if defined? box
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
      RNDK.window_erase @win
      RNDK.window_erase @shadow_win
    end

    # Removes the Widget from the Screen, deleting it's
    # internal windows.
    def destroy
      RNDK.window_delete @shadow_win
      RNDK.window_delete @win

      self.clean_bindings

      @screen.unregister self
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

