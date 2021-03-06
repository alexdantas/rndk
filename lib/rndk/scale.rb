require 'rndk'

module RNDK

  class Scale < Widget

    def initialize(screen, config={})
      super()
      @widget_type = :scale
      @supported_signals += [:before_input, :after_input]

      x              = 0
      y              = 0
      title          = "scale"
      label          = "label"
      field_color    = RNDK::Color[:normal]
      field_width    = 0
      start          = 0
      low            = 0
      high           = 100
      inc            = 1
      fast_increment = 5
      box            = true
      shadow         = false

      config.each do |key, val|
        x              = val if key == :x
        y              = val if key == :y
        title          = val if key == :title
        label          = val if key == :label
        field_color    = val if key == :field_color
        field_width    = val if key == :field_width
        start          = val if key == :start
        low            = val if key == :low
        high           = val if key == :high
        inc            = val if key == :inc
        fast_increment = val if key == :fast_increment
        box            = val if key == :box
        shadow         = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window

      self.set_box box

      box_width  = field_width + 2 * @border_size
      box_height = @border_size * 2 + 1

      # Set some basic values of the widget's data field.
      @label = []
      @label_len = 0
      @label_win = nil

      # If the field_width is a negative value, the field_width will
      # be COLS-field_width, otherwise the field_width will be the
      # given width.
      field_width = RNDK.set_widget_dimension(parent_width,
                                              field_width,
                                              0)
      box_width = field_width + 2 * @border_size

      # Translate the label string to a chtype array
      unless label.nil?
        label_len = []
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
        box_width = @label_len + field_width + 2
      end

      old_width = box_width
      box_width = self.set_title(title, box_width)
      horizontal_adjust = (box_width - old_width) / 2

      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = [box_width, parent_width].min
      box_height = [box_height, parent_height].min
      field_width = [field_width,
          box_width - @label_len - 2 * @border_size].min

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the widget's window.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)

      # Is the main window nil?
      if @win.nil?
        self.destroy
        return nil
      end

      # Create the widget's label window.
      if @label.size > 0
        @label_win = Ncurses.subwin(@win,
                                    1,
                                    @label_len,
                                    ypos + @title_lines + @border_size,
                                    xpos + horizontal_adjust + @border_size)
        if @label_win.nil?
          self.destroy
          return nil
        end
      end

      # Create the widget's data field window.
      @field_win = Ncurses.subwin(@win,
                                  1,
                                  field_width,
                                  ypos + @title_lines + @border_size,
                                  xpos + @label_len + horizontal_adjust + @border_size)
      if @field_win.nil?
        self.destroy
        return nil
      end

      Ncurses.keypad(@field_win, true)
      Ncurses.keypad(@win, true)

      # Create the widget's data field.
      @screen = screen
      @parent = screen.window
      @shadow_win = nil
      @box_width = box_width
      @box_height = box_height
      @field_width = field_width
      @field_color = field_color
      @current = low
      @low = low
      @high = high
      @current = start
      @inc = inc
      @fastinc = fast_increment
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow
      @field_edit = 0

      # Do we want a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height,
                                     box_width,
                                     ypos + 1,
                                     xpos + 1)
        if @shadow_win.nil?
          self.destroy
          return nil
        end
      end

      # Setup the key bindings.

      self.bind_key('u') { self.increment @inc     }
      self.bind_key('U') { self.increment @fastinc }
      self.bind_key('g') { @current = @low         }
      self.bind_key('^') { @current = @low         }
      self.bind_key('G') { @current = @high        }
      self.bind_key('$') { @current = @high        }

      screen.register(self.widget_type, self)
    end

    # This allows the person to use the widget's data field.
    def activate(actions=[])
      ret = false

      self.draw

      if actions.nil? || actions.size == 0
        input = 0
        while true
          input = self.getch

          # Inject the character into the widget.
          ret = self.inject(input)

          return ret if @exit_type != :EARLY_EXIT
        end
      else
        # Inject each character one at a time.
        actions.each do |action|
          ret = self.inject(action)
        end

        return ret if @exit_type != :EARLY_EXIT
      end

      # Set the exit type and return.
      self.set_exit_type(0)
      ret
    end

    # Check if the value lies outsid the low/high range. If so, force it in.
    def limitCurrentValue
      if @current < @low
        @current = @low
      elsif @current > @high
        @current = @high
      end
      RNDK.beep
    end

    # Move the cursor to the given edit-position
    def moveToEditPosition(new_position)
      Ncurses.wmove(@field_win, 0, @field_width - new_position - 1)
    end

    # Check if the cursor is on a valid edit-position. This must be one of
    # the non-blank cells in the field.
    def validEditPosition(new_position)
      if new_position <= 0 || new_position >= @field_width
        return false
      end
      if self.moveToEditPosition(new_position) == Ncurses::ERR
        return false
      end
      ch = Ncurses.winch(@field_win)
      if ch.chr != ' '
        return true
      end
      if new_position > 1
        # Don't use recursion - only one level is wanted
        if self.moveToEditPosition(new_position - 1) == Ncurses::ERR
          return false
        end
        ch = Ncurses.winch(@field_win)
        return ch.chr != ' '
      end
      return false
    end

    # Set the edit position. Normally the cursor is one cell to the right of
    # the editable field.  Moving it left over the field allows the user to
    # modify cells by typing in replacement characters for the field's value.
    def setEditPosition(new_position)
      if new_position < 0
        RNDK.beep
      elsif new_position == 0
        @field_edit = new_position
      elsif self.validEditPosition(new_position)
        @field_edit = new_position
      else
        RNDK.beep
      end
    end

    # Remove the character from the string at the given column, if it is blank.
    # Returns true if a change was made.
    def self.removeChar(string, col)
      result = false
      if col >= 0 && string[col] != ' '
        while col < string.size - 1
          string[col] = string[col + 1]
          col += 1
        end
        string.chop!
        result = true
      end
      return result
    end

    # Perform an editing function for the field.
    def performEdit(input)
      result = false
      modify = true
      base = 0
      need = @field_width
      temp = ''
      col = need - @field_edit - 1

      Ncurses.wmove(@field_win, 0, base)
      Ncurses.winnstr(@field_win, temp, need)
      temp << ' '
      if RNDK.is_char?(input)  # Replace the char at the cursor
        temp[col] = input.chr
      elsif input == Ncurses::KEY_BACKSPACE
        # delete the char before the cursor
        modify = Scale.removeChar(temp, col - 1)
      elsif input == Ncurses::KEY_DC
        # delete the char at the cursor
        modify = Scale.removeChar(temp, col)
      else
        modify = false
      end
      if modify &&
          ((value, test) = temp.scanf(self.SCAN_FMT)).size == 2 &&
          test == ' ' &&
          value >= @low && value <= @high
        self.setValue(value)
        result = true
      end

      return result
    end

    def decrement by
      @current = @current - by if (@current - by) < @current
    end

    def increment by
      @current = @current + by if (@current + by) > @current
    end

    # This function injects a single character into the widget.
    def inject input
      pp_return = true
      ret = false
      complete = false

      # Set the exit type.
      self.set_exit_type(0)

      # Draw the field.
      self.draw_field

      # Check if there is a pre-process function to be called.
      keep_going = self.run_signal_binding(:before_input, input)

      if keep_going

        # Check for a key bindings.
        if self.is_bound? input
          self.run_key_binding input
          #complete = true

        else
          case input
          when Ncurses::KEY_LEFT
            self.setEditPosition(@field_edit + 1)
          when Ncurses::KEY_RIGHT
            self.setEditPosition(@field_edit - 1)

          when Ncurses::KEY_DOWN  then self.decrement @inc
          when Ncurses::KEY_UP    then self.increment @inc
          when Ncurses::KEY_HOME  then @current = @low
          when Ncurses::KEY_END   then @current = @high
          when Ncurses::KEY_PPAGE, RNDK::BACKCHAR
            self.increment @fastinc
          when Ncurses::KEY_NPAGE, RNDK::FORCHAR
            self.decrement @fastinc
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            self.set_exit_type(input)
            ret = @current
            complete = true
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            complete = true
          when Ncurses::ERR
            self.set_exit_type(input)
            complete = true
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          else
            if @field_edit != 0
              if !self.performEdit(input)
                RNDK.beep
              end
            else
              # The cursor is not within the editable text. Interpret
              # input as commands.
              case input
              when 'd'.ord, '-'.ord
                return self.inject(Ncurses::KEY_DOWN)
              when '+'.ord
                return self.inject(Ncurses::KEY_UP)
              when 'D'.ord
                return self.inject(Ncurses::KEY_NPAGE)
              when '0'.ord
                return self.inject(Ncurses::KEY_HOME)
              else
                RNDK.beep
              end
            end
          end
        end
        self.limitCurrentValue

        self.run_signal_binding(:after_input) if not complete
      end

      if not complete
        self.draw_field
        self.set_exit_type 0
      end

      @result_data = ret
      return ret
    end

    # This moves the widget's data field to the given location.
    def move(x, y, relative, refresh_flag)
      windows = [@win, @label_win, @field_win, @shadow_win]

      self.move_specific(x, y, relative, refresh_flag, windows, [])
    end

    # This function draws the widget.
    def draw
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      draw_box @win if @box

      self.draw_title @win

      # Draw the label.
      unless @label_win.nil?
        Draw.writeChtype(@label_win,
                         0,
                         0,
                         @label, RNDK::HORIZONTAL,
                         0,
                         @label_len)
        Ncurses.wrefresh @label_win
      end
      Ncurses.wrefresh @win

      # Draw the field window.
      self.draw_field
    end

    # This draws the widget.
    def draw_field
      Ncurses.werase(@field_win)

      # Draw the value in the field.
      temp = @current.to_s
      Draw.writeCharAttrib(@field_win,
                           @field_width - temp.size - 1,
                           0,
                           temp,
                           @field_color,
                           RNDK::HORIZONTAL,
                           0,
                           temp.size)

      self.moveToEditPosition(@field_edit)
      Ncurses.wrefresh(@field_win)
    end

    # This sets the background attribute of teh widget.
    def set_bg_color attrib
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)
      Ncurses.wbkgd(@label_win, attrib) unless @label_win.nil?
    end

    # This function destroys the widget.
    def destroy
      self.clean_title
      @label = []

      # Clean up the windows.
      RNDK.window_delete @field_win
      RNDK.window_delete @label_win
      RNDK.window_delete @shadow_win
      RNDK.window_delete @win

      # Clean the key bindings.
      self.clean_bindings

      # Unregister this widget
      @screen.unregister(self.widget_type, self)
    end

    # This function erases the widget from the screen.
    def erase
      if self.valid?
        RNDK.window_erase @label_win
        RNDK.window_erase @field_win
        RNDK.window_erase @win
        RNDK.window_erase @shadow_win
      end
    end

    # This function sets the low/high/current values of the widget.
    def set(low, high, value, box)
      self.setLowHigh(low, high)
      self.setValue value
      self.set_box box
    end

    # This sets the widget's value
    def setValue value
      @current = value
      self.limitCurrentValue
    end

    def getValue
      return @current
    end

    # This function sets the low/high values of the widget.
    def setLowHigh(low, high)
      # Make sure the values aren't out of bounds.
      if low <= high
        @low = low
        @high = high
      elsif low > high
        @low = high
        @high = low
      end

      # Make sure the user hasn't done something silly.
      self.limitCurrentValue
    end

    def getLowValue
      return @low
    end

    def getHighValue
      return @high
    end

    def focus
      self.draw
    end

    def unfocus
      self.draw
    end

    def position
      super(@win)
    end

    def SCAN_FMT
      '%d%c'
    end

  end
end
