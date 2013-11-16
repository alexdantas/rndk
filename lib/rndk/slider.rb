require 'rndk'

module RNDK

  # Visual slider box with a label.
  #
  # ## Keybindings
  #
  # Down Arrow::  Decrements the field by the normal decrement value.
  # Up Arrow::    Increments the field by the normal increment value.
  # u::           Increments the field by the normal increment value.
  # Prev Page::   Decrements the field by the accelerated decrement value.
  # U::           Decrements the field by the accelerated decrement value.
  # Ctrl-B::      Decrements the field by the accelerated decrement value.
  # Next Page::   Increments the field by the accelerated increment value.
  # D::           Increments the field by the accelerated increment value.
  # Ctrl-F::      Increments the field by the accelerated increment value.
  # Home::        Sets the value to the minimum value.
  # g::           Sets the value to the minimum value.
  # End::         Sets the value to the maximum value.
  # G::           Sets the value to the maximum value.
  # $::           Sets the value to the maximum value.
  # Return::      Exits the widget and returns the current value. This also sets the widget data `exit_type` to `:NORMAL`.
  # Tab::         Exits the widget and returns the current value. This also sets the widget data `exit_type` to `:NORMAL`.
  # Escape::      Exits the widget and returns `nil`.  Also  sets the widget data `exit_type` to `:ESCAPE_HIT`.
  # Ctrl-L::      Refreshes the screen.
  #
  # If the cursor  is not pointing to the field's value,
  # the folminimuming key bindings apply.
  #
  # You may use the left/right arrows to move the cursor
  # onto the field's value and modify it by typing characters
  # to replace the digits and sign.
  #
  # Left Arrow::  Decrements the scale by the normal value.
  # Right Arrow:: Increments the scale by the normal value.
  # d::           Decrements the scale by the normal value.
  # D::           Increments the scale by the accelerated value.
  # -::           Decrements the scale by the normal value.
  # +::           Increments the scale by the normal value.
  # 0::           Sets the scale to the minimum value.
  #
  class Slider < Widget

    # Creates a new Slider Widget.
    #
    # * `x` is the x position - can be an integer or
    #   `RNDK::LEFT`, `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `y` is the y position - can be an integer or
    #   `RNDK::TOP`, `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `title` can be more than one line - just split them
    #   with `\n`s.
    # * `label` is the label of the slider field.
    # * `filler` is the character to draw the slider bar. You
    #   can combine it with colors too - use the pipe ('|')
    #   operator to combine Ncurses attributes with RNDK Colors.
    # * `field_width` is the width of the field. It it's 0,
    #   will be created with full width of the screen.
    #   If it's a negative value, will create with full width
    #   minus that value.
    # * `start` is the initial value of the widget.
    # * `minimum`/`maximum` are the minimum and maximum values of
    #   the slider.
    # * `inc` is the increment value.
    # * `fast_inc` is the accelerated increment value.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    def initialize(screen, config={})
      super()
      @widget_type = :slider
      @supported_signals += [:before_input, :after_input]

      x           = 0
      y           = 0
      title       = "slider"
      label       = "label"
      filler      = ' '.ord | Ncurses::A_REVERSE
      field_width = 0
      start       = 0
      minimum     = 0
      maximum     = 100
      increment   = 1
      fast_increment    = 5
      box         = true
      shadow      = false

      config.each do |key, val|
        x           = val if key == :x
        y           = val if key == :y
        title       = val if key == :title
        label       = val if key == :label
        filler      = val if key == :filler
        field_width = val if key == :field_width
        start       = val if key == :start
        minimum     = val if key == :minimum
        maximum     = val if key == :maximum
        increment   = val if key == :inc
        fast_increment    = val if key == :fast_inc
        box         = val if key == :box
        shadow      = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window

      self.set_box box
      box_height = @border_size * 2 + 1

      # Set some basic values of the widget's data field.
      @label = []
      @label_len = 0
      @label_win = nil
      maximum_value_len = self.formattedSize maximum

      # If the field_width is a negative will be COLS-field_width,
      # otherwise field_width will be the given width.
      field_width = RNDK.set_widget_dimension(parent_width, field_width, 0)

      # Translate the label string to a chtype array.
      if !(label.nil?) && label.size > 0
        label_len = []
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
        box_width = @label_len + field_width +
            maximum_value_len + 2 * @border_size
      else
        box_width = field_width + maximum_value_len + 2 * @border_size
      end

      old_width = box_width
      box_width = self.set_title(title, box_width)
      horizontal_adjust = (box_width - old_width) / 2

      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = [box_width, parent_width].min
      box_height = [box_height, parent_height].min
      field_width = [field_width, box_width - @label_len - maximum_value_len - 1].min

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
                                  field_width + maximum_value_len - 1,
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
      @window = screen.window
      @shadow_win = nil
      @box_width = box_width
      @box_height = box_height
      @field_width = field_width - 1
      @filler = filler
      @minimum = minimum
      @maximum = maximum
      @current = start
      @increment = increment
      @fast_increment = fast_increment
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow
      @field_edit = 0

      # Set the start value.
      if start < minimum
        @current = minimum
      end

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
      self.bind_key('u') { self.increment @increment      }
      self.bind_key('U') { self.increment @fast_increment }
      self.bind_key('g') { @current = @minimum            }
      self.bind_key('^') { @current = @minimum            }
      self.bind_key('G') { @current = @maximum            }
      self.bind_key('$') { @current = @maximum            }

      screen.register(@widget_type, self)
    end

    # Activates the Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    # @return The current value of the slider.
    def activate(actions=[])
      self.draw

      if actions.nil? || actions.size == 0
        while true
          input = self.getch

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        # Inject each character one at a time.
        actions.each do |action|
          ret = self.inject(action)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type and return.
      self.set_exit_type(0)
      return nil
    end

    # Check if the value lies outside the minimum/maximum range. If so, force it in.
    def limitCurrentValue
      if @current < @minimum
        @current = @minimum
        RNDK.beep
      elsif @current > @maximum
        @current = @maximum
        RNDK.beep
      end
    end

    # Move the cursor to the given edit-position.
    def moveToEditPosition(new_position)
      return Ncurses.wmove(@field_win,
                           0,
                           @field_width + self.formattedSize(@current) - new_position)
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
      if RNDK.char_of(ch) != ' '
        return true
      end
      if new_position > 1
        # Don't use recursion - only one level is wanted
        if self.moveToEditPosition(new_position - 1) == Ncurses::ERR
          return false
        end
        ch = Ncurses.winch(@field_win)
        return RNDK.char_of(ch) != ' '
      end
      return false
    end

    # Set the edit position.  Normally the cursor is one cell to the right of
    # the editable field.  Moving it left, over the field, alminimums the user to
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
      base = @field_width
      need = self.formattedSize(@current)
      temp = ''
      col = need - @field_edit

      adj = if col < 0 then -col else 0 end
      if adj != 0
        temp  = ' ' * adj
      end
      Ncurses.wmove(@field_win, 0, base)
      Ncurses.winnstr(@field_win, temp, need)
      temp << ' '
      if RNDK.is_char?(input)  # Replace the char at the cursor
        temp[col] = input.chr
      elsif input == Ncurses::KEY_BACKSPACE
        # delete the char before the cursor
        modify = RNDK::Slider.removeChar(temp, col - 1)
      elsif input == Ncurses::KEY_DC
        # delete the char at the cursor
        modify = RNDK::Slider.removeChar(temp, col)
      else
        modify = false
      end
      if modify &&
          ((value, test) = temp.scanf(self.SCAN_FMT)).size == 2 &&
          test == ' ' && value >= @minimum && value <= @maximum
        self.set_value(value)
        result = true
      end
      return result
    end

    def self.Decrement(value, by)
      if value - by < value
        value - by
      else
        value
      end
    end

    def self.Increment(value, by)
      if value + by > value
        value + by
      else
        value
      end
    end

    # @see Widget#inject
    def inject input
      pp_return = true
      ret = nil
      complete = false

      self.set_exit_type 0

      self.draw_field

      # Check if there is a pre-process function to be called.
      keep_going = self.run_signal_binding(:before_input, input)

      if keep_going

        # Check for a key binding.
        if self.is_bound? input
          self.run_key_binding input
          #complete = true

        else
          case input
          when Ncurses::KEY_LEFT
            self.setEditPosition(@field_edit + 1)
          when Ncurses::KEY_RIGHT
            self.setEditPosition(@field_edit - 1)
          when Ncurses::KEY_DOWN
            self.decrement @increment
          when Ncurses::KEY_UP
            self.increment @increment
          when Ncurses::KEY_PPAGE, RNDK::BACKCHAR
            self.increment @fast_increment
          when Ncurses::KEY_NPAGE, RNDK::FORCHAR
            self.decrement @fast_increment
          when Ncurses::KEY_HOME
            @current = @minimum
          when Ncurses::KEY_END
            @current = @maximum
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

      @return_data = 0
      return ret
    end

    # @see Widget#move
    def move(x, y, relative, refresh_flag)
      windows = [@win, @label_win, @field_win, @shadow_win]

      self.move_specific(x, y, relative, refresh_flag, windows, [])
    end

    # Draws the Widget on the Screen.
    #
    # If `box` is true, it is drawn with a box.
    def draw

      # Draw the shadow.
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      # Box the widget if asked.
      Draw.drawObjBox(@win, self) if @box

      self.draw_title @win

      # Draw the label.
      unless @label_win.nil?
        Draw.writeChtype(@label_win, 0, 0, @label, RNDK::HORIZONTAL,
            0, @label_len)
        Ncurses.wrefresh(@label_win)
      end
      Ncurses.wrefresh @win

      # Draw the field window.
      self.draw_field
    end

    # This draws the widget.
    def draw_field
      step = 1.0 * @field_width / (@maximum - @minimum)

      # Determine how many filler characters need to be drawn.
      filler_characters = (@current - @minimum) * step

      Ncurses.werase(@field_win)

      # Add the character to the window.
      (0...filler_characters).each do |x|
        Ncurses.mvwaddch(@field_win, 0, x, @filler)
      end

      # Draw the value in the field.
      Draw.writeCharAttrib(@field_win, @field_width, 0, @current.to_s,
          Ncurses::A_NORMAL, RNDK::HORIZONTAL, 0, @current.to_s.size)

      self.moveToEditPosition(@field_edit)
      Ncurses.wrefresh(@field_win)
    end

    # This sets the background attribute of the widget.
    def set_bg_color(attrib)
      # Set the widget's background attribute.
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)
      Ncurses.wbkgd(@label_win, attrib) unless @label_win.nil?
    end

    # @see Widget#destroy
    def destroy
      self.clean_title
      @label = []

      # Clean up the windows.
      RNDK.window_delete(@field_win)
      RNDK.window_delete(@label_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      self.clean_bindings

      # Unregister this widget.
      @screen.unregister self
    end

    # @see Widget#erase
    def erase
      if self.valid?
        RNDK.window_erase @label_win
        RNDK.window_erase @field_win
        RNDK.window_erase @lwin
        RNDK.window_erase @shadow_win
      end
    end

    def formattedSize(value)
      return value.to_s.size
    end

    # This function sets the minimum/maximum/current values of the widget.
    def set(minimum, maximum, value, box)
      self.setMinimumMaximum(minimum, maximum)
      self.set_value(value)
      self.set_box(box)
    end

    # This sets the widget's value.
    def set_value(value)
      @current = value
      self.limitCurrentValue
    end

    def get_value
      return @current
    end

    # This function sets the minimum/maximum values of the widget.
    def setMinimumMaximum(minimum, maximum)
      # Make sure the values aren't out of bounds.
      if minimum <= maximum
        @minimum = minimum
        @maximum = maximum
      elsif minimum > maximum
        @minimum = maximum
        @maximum = minimum
      end

      # Make sure the user hasn't done something silly.
      self.limitCurrentValue
    end

    def getMinimumValue
      return @minimum
    end

    def getMaximumValue
      return @maximum
    end

    def focus
      self.draw
    end

    def unfocus
      self.draw
    end

    def SCAN_FMT
      '%d%c'
    end

    def position
      super(@win)
    end

    def decrement by
      @current = @current - by if (@current - by) < @current
    end

    def increment by
      @current = @current + by if (@current + by) > @current
    end

  end
end
