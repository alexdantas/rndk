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
  # Home::        Sets the value to the low value.
  # g::           Sets the value to the low value.
  # End::         Sets the value to the high value.
  # G::           Sets the value to the high value.
  # $::           Sets the value to the high value.
  # Return::      Exits the widget and returns the current value. This also sets the widget data `exit_type` to `:NORMAL`.
  # Tab::         Exits the widget and returns the current value. This also sets the widget data `exit_type` to `:NORMAL`.
  # Escape::      Exits the widget and returns `nil`.  Also  sets the widget data `exit_type` to `:ESCAPE_HIT`.
  # Ctrl-L::      Refreshes the screen.
  #
  # If the cursor  is not pointing to the field's value,
  # the following key bindings apply.
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
  # 0::           Sets the scale to the low value.
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
    # * `low`/`high` are the minimum and maximum values of
    #   the slider.
    # * `inc` is the increment value.
    # * `fast_inc` is the accelerated increment value.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    def initialize(screen, config={})
      super()
      @widget_type = :slider

      x           = 0
      y           = 0
      title       = "slider"
      label       = "label"
      filler      = ' '.ord | Ncurses::A_REVERSE
      field_width = 0
      start       = 0
      low         = 0
      high        = 100
      inc         = 1
      fast_inc    = 5
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
        low         = val if key == :low
        high        = val if key == :high
        inc         = val if key == :inc
        fast_inc    = val if key == :fast_inc
        box         = val if key == :box
        shadow      = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)

      bindings = {
          'u'           => Ncurses::KEY_UP,
          'U'           => Ncurses::KEY_PPAGE,
          RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
          RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
          'g'           => Ncurses::KEY_HOME,
          '^'           => Ncurses::KEY_HOME,
          'G'           => Ncurses::KEY_END,
          '$'           => Ncurses::KEY_END,
      }
      self.set_box(box)
      box_height = @border_size * 2 + 1

      # Set some basic values of the widget's data field.
      @label = []
      @label_len = 0
      @label_win = nil
      high_value_len = self.formattedSize(high)

      # If the field_width is a negative will be COLS-field_width,
      # otherwise field_width will be the given width.
      field_width = RNDK.setWidgetDimension(parent_width, field_width, 0)

      # Translate the label string to a chtype array.
      if !(label.nil?) && label.size > 0
        label_len = []
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
        box_width = @label_len + field_width +
            high_value_len + 2 * @border_size
      else
        box_width = field_width + high_value_len + 2 * @border_size
      end

      old_width = box_width
      box_width = self.set_title(title, box_width)
      horizontal_adjust = (box_width - old_width) / 2

      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensions of the window.
      box_width = [box_width, parent_width].min
      box_height = [box_height, parent_height].min
      field_width = [field_width, box_width - @label_len - high_value_len - 1].min

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
                                  field_width + high_value_len - 1,
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
      @low = low
      @high = high
      @current = start
      @inc = inc
      @fastinc = fast_inc
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow
      @field_edit = 0

      # Set the start value.
      if start < low
        @current = low
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
      bindings.each do |from, to|
        self.bind(from, :getc, to)
      end

      screen.register(:slider, self)
    end

    # Activates the Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    # @return The current value of the slider.
    def activate(actions=[])
      self.draw @box

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

    # Check if the value lies outside the low/high range. If so, force it in.
    def limitCurrentValue
      if @current < @low
        @current = @low
        RNDK.beep
      elsif @current > @high
        @current = @high
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
      if RNDK.CharOf(ch) != ' '
        return true
      end
      if new_position > 1
        # Don't use recursion - only one level is wanted
        if self.moveToEditPosition(new_position - 1) == Ncurses::ERR
          return false
        end
        ch = Ncurses.winch(@field_win)
        return RNDK.CharOf(ch) != ' '
      end
      return false
    end

    # Set the edit position.  Normally the cursor is one cell to the right of
    # the editable field.  Moving it left, over the field, allows the user to
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
          test == ' ' && value >= @low && value <= @high
        self.setValue(value)
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

      # Set the exit type.
      self.set_exit_type(0)

      # Draw the field.
      self.drawField

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        # Call the pre-process function.
        pp_return = @pre_process_func.call(:slider, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return
        # Check for a key binding.
        if self.check_bind(input)
          complete = true
        else
          case input
          when Ncurses::KEY_LEFT
            self.setEditPosition(@field_edit + 1)
          when Ncurses::KEY_RIGHT
            self.setEditPosition(@field_edit - 1)
          when Ncurses::KEY_DOWN
            @current = RNDK::Slider.Decrement(@current, @inc)
          when Ncurses::KEY_UP
            @current = RNDK::Slider.Increment(@current, @inc)
          when Ncurses::KEY_PPAGE
            @current = RNDK::Slider.Increment(@current, @fastinc)
          when Ncurses::KEY_NPAGE
            @current = RNDK::Slider.Decrement(@current, @fastinc)
          when Ncurses::KEY_HOME
            @current = @low
          when Ncurses::KEY_END
            @current = @high
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

        # Should we call a post-process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(:slider, self, @post_process_data, input)
        end
      end

      if !complete
        self.drawField
        self.set_exit_type(0)
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
    def draw box

      # Draw the shadow.
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      # Box the widget if asked.
      Draw.drawObjBox(@win, self) if box

      self.draw_title @win

      # Draw the label.
      unless @label_win.nil?
        Draw.writeChtype(@label_win, 0, 0, @label, RNDK::HORIZONTAL,
            0, @label_len)
        Ncurses.wrefresh(@label_win)
      end
      Ncurses.wrefresh @win

      # Draw the field window.
      self.drawField
    end

    # This draws the widget.
    def drawField
      step = 1.0 * @field_width / (@high - @low)

      # Determine how many filler characters need to be drawn.
      filler_characters = (@current - @low) * step

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
    def set_bg_attrib(attrib)
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

    # This function sets the low/high/current values of the widget.
    def set(low, high, value, box)
      self.setLowHigh(low, high)
      self.setValue(value)
      self.set_box(box)
    end

    # This sets the widget's value.
    def setValue(value)
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
      self.draw(@box)
    end

    def unfocus
      self.draw(@box)
    end

    def SCAN_FMT
      '%d%c'
    end

    def position
      super(@win)
    end

  end
end
