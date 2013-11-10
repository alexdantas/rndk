module RNDK
  class RNDKOBJS
    attr_accessor :screen_index, :screen, :has_focus, :is_visible, :box
    attr_accessor :ULChar, :URChar, :LLChar, :LRChar, :HZChar, :VTChar, :BXAttr
    attr_reader :binding_list, :accepts_focus, :exit_type, :border_size

    @@g_paste_buffer = ''

    def initialize
      @has_focus = true
      @is_visible = true

      RNDK::ALL_OBJECTS << self

      # set default line-drawing characters
      @ULChar = Ncurses::ACS_ULCORNER
      @URChar = Ncurses::ACS_URCORNER
      @LLChar = Ncurses::ACS_LLCORNER
      @LRChar = Ncurses::ACS_LRCORNER
      @HZChar = Ncurses::ACS_HLINE
      @VTChar = Ncurses::ACS_VLINE
      @BXAttr = Ncurses::A_NORMAL

      # set default exit-types
      @exit_type = :NEVER_ACTIVATED
      @early_exit = :NEVER_ACTIVATED

      @accepts_focus = false

      # Bound functions
      @binding_list = {}
    end

    def object_type
      # no type by default
      :NULL
    end

    def validObjType(type)
      # dummy version for now
      true
    end

    def SCREEN_XPOS(n)
      n + @border_size
    end

    def SCREEN_YPOS(n)
      n + @border_size + @title_lines
    end

    def draw(a)
    end

    def erase
    end

    def move(xplace, yplace, relative, refresh_flag)
      self.move_specific(xplace, yplace, relative, refresh_flag,
          [@win, @shadow_win], [])
    end

    def move_specific(xplace, yplace, relative, refresh_flag,
        windows, subwidgets)
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

      # Adjust the window if we need to
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      windows.each do |window|
        RNDK.moveCursesWindow(window, -xdiff, -ydiff)
      end

      subwidgets.each do |subwidget|
        subwidget.move(xplace, yplace, relative, false)
      end

      # Touch the windows so they 'move'
      RNDK::SCREEN.refreshRNDKWindow(@screen.window)

      # Redraw the window, if they asked for it
      if refresh_flag
        self.draw(@box)
      end
    end

    def inject(a)
    end

    def setBox(box)
      @box = box
      @border_size = if @box then 1 else 0 end
    end

    def getBox
      return @box
    end

    def focus
    end

    def unfocus
    end

    def saveData
    end

    def refreshData
    end

    def destroy
    end

    # Set the object's upper-left-corner line-drawing character.
    def setULchar(ch)
      @ULChar = ch
    end

    # Set the object's upper-right-corner line-drawing character.
    def setURchar(ch)
      @URChar = ch
    end

    # Set the object's lower-left-corner line-drawing character.
    def setLLchar(ch)
      @LLChar = ch
    end

    # Set the object's upper-right-corner line-drawing character.
    def setLRchar(ch)
      @LRChar = ch
    end

    # Set the object's horizontal line-drawing character
    def setHZchar(ch)
      @HZChar = ch
    end

    # Set the object's vertical line-drawing character
    def setVTchar(ch)
      @VTChar = ch
    end

    # Set the object's box-attributes.
    def setBXattr(ch)
      @BXAttr = ch
    end

    # This sets the background color of the widget.
    def setBackgroundColor(color)
      return if color.nil? || color == ''

      junk1 = []
      junk2 = []

      # Convert the value of the environment variable to a chtype
      holder = RNDK.char2Chtype(color, junk1, junk2)

      # Set the widget's background color
      self.SetBackAttrObj(holder[0])
    end

    # Set the widget's title.
    def setTitle (title, box_width)
      if !title.nil?
        temp = title.split("\n")
        @title_lines = temp.size

        if box_width >= 0
          max_width = 0
          temp.each do |line|
            len = []
            align = []
            holder = RNDK.char2Chtype(line, len, align)
            max_width = [len[0], max_width].max
          end
          box_width = [box_width, max_width + 2 * @border_size].max
        else
          box_width = -(box_width - 1)
        end

        # For each line in the title convert from string to chtype array
        title_width = box_width - (2 * @border_size)
        @title = []
        @title_pos = []
        @title_len = []
        (0...@title_lines).each do |x|
          len_x = []
          pos_x = []
          @title << RNDK.char2Chtype(temp[x], len_x, pos_x)
          @title_len.concat(len_x)
          @title_pos << RNDK.justifyString(title_width, len_x[0], pos_x[0])
        end
      end

      return box_width
    end

    # Draw the widget's title
    def drawTitle(win)
      (0...@title_lines).each do |x|
        Draw.writeChtype(@win, @title_pos[x] + @border_size,
            x + @border_size, @title[x], RNDK::HORIZONTAL, 0,
            @title_len[x])
      end
    end

    # Remove storage for the widget's title.
    def cleanTitle
      @title_lines = ''
    end

    # Set data for preprocessing
    def setPreProcess (fn, data)
      @pre_process_func = fn
      @pre_process_data = data
    end

    # Set data for postprocessing
    def setPostProcess (fn, data)
      @post_process_func = fn
      @post_process_data = data
    end

    # Set the object's exit-type based on the input.
    # The .exitType field should have been part of the RNDKOBJS struct, but it
    # is used too pervasively in older applications to move (yet).
    def setExitType(ch)
      case ch
      when Ncurses::ERR
        @exit_type = :ERROR
      when RNDK::KEY_ESC
        @exit_type = :ESCAPE_HIT
      when RNDK::KEY_TAB, Ncurses::KEY_ENTER, RNDK::KEY_RETURN
        @exit_type = :NORMAL
      when 0
        @exit_type = :EARLY_EXIT
      end
    end

    def validRNDKObject
      result = false
      if RNDK::ALL_OBJECTS.include?(self)
        result = self.validObjType(self.object_type)
      end
      result
    end

    def getc
      rndktype = self.object_type
      test = self.bindableObject(rndktype)
      result = Ncurses.wgetch @input_window

      if result >= 0 && !(test.nil?) && test.binding_list.include?(result) &&
          test.binding_list[result][0] == :getc
        result = test.binding_list[result][1]
      elsif test.nil? || !(test.binding_list.include?(result)) ||
          test.binding_list[result][0].nil?
        case result
        when "\r".ord, "\n".ord
          result = Ncurses::KEY_ENTER
        when "\t".ord
          result = RNDK::KEY_TAB
        when RNDK::DELETE
          result = Ncurses::KEY_DC
        when "\b".ord
          result = Ncurses::KEY_BACKSPACE
        when RNDK::BEGOFLINE
          result = Ncurses::KEY_HOME
        when RNDK::ENDOFLINE
          result = Ncurses::KEY_END
        when RNDK::FORCHAR
          result = Ncurses::KEY_RIGHT
        when RNDK::BACKCHAR
          result = Ncurses::KEY_LEFT
        when RNDK::NEXT
          result = RNDK::KEY_TAB
        when RNDK::PREV
          result = Ncurses::KEY_BTAB
        end
      end

      return result
    end

    def getch(function_key)
      key = self.getc
      function_key << (key >= Ncurses::KEY_MIN && key <= Ncurses::KEY_MAX)
      return key
    end

    def bindableObject(rndktype)
      if rndktype != self.object_type
        return nil
      elsif [:FSELECT, :ALPHALIST].include?(self.object_type)
        return @entry_field
      else
        return self
      end
    end

    def bind(type, key, function, data)
      obj = self.bindableObject(type)
      if key.ord < Ncurses::KEY_MAX && !(obj.nil?)
        if key.ord != 0
          obj.binding_list[key.ord] = [function, data]
        end
      end
    end

    def unbind(type, key)
      obj = self.bindableObject(type)
      unless obj.nil?
        obj.binding_list.delete(key)
      end
    end

    def cleanBindings(type)
      obj = self.bindableObject(type)
      if !(obj.nil?) && !(obj.binding_list.nil?)
        obj.binding_list.clear
      end
    end

    # This checks to see if the binding for the key exists:
    # If it does then it runs the command and returns its value, normally true
    # If it doesn't it returns a false.  This way we can 'overwrite' coded
    # bindings.
    def checkBind(type, key)
      obj = self.bindableObject(type)
      if !(obj.nil?) && obj.binding_list.include?(key)
        function = obj.binding_list[key][0]
        data = obj.binding_list[key][1]

        if function == :getc
          return data
        else
          return function.call(type, obj, data, key)
        end
      end
      return false
    end

    # This checks to see if the binding for the key exists.
    def isBind(type, key)
      result = false
      obj = self.bindableObject(type)
      unless obj.nil?
        result = obj.binding_list.include?(key)
      end

      return result
    end

    # This allows the user to use the cursor keys to adjust the
    # postion of the widget.
    def position(win)
      parent = @screen.window
      orig_x = Ncurses.getbegx win
      orig_y = Ncurses.getbegy win
      beg_x = Ncurses.getbegx parent
      beg_y = Ncurses.getbegy parent
      end_x = beg_x + Ncurses.getmaxx(@screen.window)
      end_y = beg_y + Ncurses.getmaxy(@screen.window)

      # Let them move the widget around until they hit return.
      while not [RNDK::KEY_RETURN, Ncurses::KEY_ENTER].include?(
        (key = self.getch([])))
        case key
        when Ncurses::KEY_UP, '8'.ord
          if Ncurses.getbegy(win) > beg_y
            self.move(0, -1, true, true)
          else
            RNDK.Beep
          end
        when Ncurses::KEY_DOWN, '2'.ord
          if (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(0, 1, true, true)
          else
            RNDK.Beep
          end
        when Ncurses::KEY_LEFT, '4'.ord
          if Ncurses.getbegx(win) > beg_x
            self.move(-1, 0, true, true)
          else
            RNDK.Beep
          end
        when Ncurses::KEY_RIGHT, '6'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x
            self.move(1, 0, true, true)
          else
            RNDK.Beep
          end
        when '7'.ord
          if Ncurses.getbegy(win) > beg_y && Ncurses.getbegx(win) > beg_x
            self.move(-1, -1, true, true)
          else
            RNDK.Beep
          end
        when '9'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x && Ncurses.getbegy(win) > beg_y
            self.move(1, -1, true, true)
          else
            RNDK.Beep
          end
        when '1'.ord
          if Ncurses.getbegx(win) > beg_x && (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(-1, 1, true, true)
          else
            RNDK.Beep
          end
        when '3'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x &&
              (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(1, 1, true, true)
          else
            RNDK.Beep
          end
        when '5'.ord
          self.move(RNDK::CENTER, RNDK::CENTER, false, true)

        when 't'.ord
          self.move(Ncurses.getbegx(win), RNDK::TOP, false, true)

        when 'b'.ord
          self.move(Ncurses.getbegx(win), RNDK::BOTTOM, false, true)

        when 'l'.ord
          self.move(RNDK::LEFT, Ncurses.getbegy(win), false, true)

        when 'r'.ord
          self.move(RNDK::RIGHT, Ncurses.getbegy(win), false, true)

        when 'c'.ord
          self.move(RNDK::CENTER, Ncurses.getbegy(win), false, true)

        when 'C'.ord
          self.move(Ncurses.getbegx(win), RNDK::CENTER, false, true)

        when RNDK::REFRESH
          @screen.erase
          @screen.refresh

        when RNDK::KEY_ESC
          self.move(orig_x, orig_y, false, true)
        else
          RNDK.Beep
        end
      end
    end
  end
end
