require 'rndk'

module RNDK
  class Template < Widget
    def initialize(screen, config={})
      super()
      @widget_type = :template
      @supported_signals += [:before_input, :after_input]

      x       = 0
      y       = 0
      title   = "template"
      label   = "label"
      plate   = "##/##/####"
      overlay = "dd/mm/yyyy"
      box     = true
      shadow  = false

      config.each do |key, val|
        x       = val if key == :x
        y       = val if key == :y
        title   = val if key == :title
        label   = val if key == :label
        plate   = val if key == :plate
        overlay = val if key == :overlay
        box     = val if key == :box
        shadow  = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window
      box_width = 0
      box_height = if box then 3 else 1 end
      plate_len = 0

      return nil if plate.nil? || plate.size == 0

      self.set_box box

      field_width = plate.size + 2 * @border_size

      # Set some basic values of the template field.
      @label = []
      @label_len = 0
      @label_win = nil

      # Translate the label string to achtype array
      if !(label.nil?) && label.size > 0
        label_len = []
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
      end

      # Translate the char * overlay to a chtype array
      if !(overlay.nil?) && overlay.size > 0
        overlay_len = []
        @overlay = RNDK.char2Chtype(overlay, overlay_len, [])
        @overlay_len = overlay_len[0]
        @field_attr = @overlay[0] & RNDK::Color[:extract]
      else
        @overlay = []
        @overlay_len = 0
        @field_attr = RNDK::Color[:normal]
      end

      # Set the box width.
      box_width = field_width + @label_len + 2 * @border_size

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

      # Make the template window
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)

      # Is the template window nil?
      if @win.nil?
        self.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      # Make the label window.
      if label.size > 0
        @label_win = Ncurses.subwin(@win, 1, @label_len,
            ypos + @title_lines + @border_size,
            xpos + horizontal_adjust + @border_size)
      end

      # Make the field window
      @field_win = Ncurses.subwin(@win, 1, field_width,
            ypos + @title_lines + @border_size,
            xpos + @label_len + horizontal_adjust + @border_size)
      Ncurses.keypad(@field_win, true)

      # Set up the text field.
      @plate_len = plate.size
      @text = ''
      # Copy the plate to the template
      @plate = plate.clone

      # Set up the rest of the structure.
      @screen = screen
      @parent = screen.window
      @shadow_win = nil
      @field_width = field_width
      @box_height = box_height
      @box_width = box_width
      @plate_pos = 0
      @screen_pos = 0
      @text_pos = 0
      @min = 0
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow
      @callbackfn = lambda do |template, input|
        failed = false
        change = false
        moveby = false
        amount = 0
        mark = @text_pos
        have = @text.size

        if input == Ncurses::KEY_LEFT
          if mark != 0
            moveby = true
            amount = -1
          else
            failed = true
          end
        elsif input == Ncurses::KEY_RIGHT
          if mark < @text.size
            moveby = true
            amount = 1
          else
            failed = true
          end
        else
          test = @text.clone
          if input == Ncurses::KEY_BACKSPACE
            if mark != 0
              front = @text[0...mark-1] || ''
              back = @text[mark..-1] || ''
              test = front + back
              change = true
              amount = -1
            else
              failed = true
            end
          elsif input == Ncurses::KEY_DC
            if mark < @text.size
              front = @text[0...mark] || ''
              back = @text[mark+1..-1] || ''
              test = front + back
              change = true
              amount = 0
            else
              failed = true
            end
          elsif RNDK.is_char?(input) && @plate_pos < @plate.size
            test[mark] = input.chr
            change = true
            amount = 1
          else
            failed = true
          end

          if change
            if self.valid_template? test
              @text = test
              self.draw_field
            else
              failed = true
            end
          end
        end

        if failed
          RNDK.beep
        elsif change || moveby
          @text_pos += amount
          @plate_pos += amount
          @screen_pos += amount

          self.adjust_cursor(amount)
        end
      end

      # Do we need to create a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      screen.register(@widget_type, self)
    end

    # This actually manages the tempalte widget
    def activate(actions=[])
      self.draw

      if actions.nil? || actions.size == 0
        while true
          input = self.getch

          # Inject each character into the widget.
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
      return ret
    end

    # This injects a character into the widget.
    def inject input
      pp_return = true
      complete = false
      ret = false

      self.set_exit_type(0)

      # Move the cursor.
      self.draw_field

      # Check if there is a pre-process function to be called.
      keep_going = self.run_signal_binding(:before_input, input)

      if keep_going

        # Check a predefined binding
        if self.is_bound? input
          self.run_key_binding input
          #complete = true
        else
          case input
          when RNDK::ERASE
            if @text.size > 0
              clean
              self.draw_field
            end
          when RNDK::CUT
            if @text.size > 0
              @@g_paste_buffer = @text.clone
              clean
              self.draw_field
            else
              RNDK.beep
            end
          when RNDK::COPY
            if @text.size > 0
              @@g_paste_buffer = @text.clone
            else
              RNDK.beep
            end
          when RNDK::PASTE
            if @@g_paste_buffer.size > 0
              clean

              # Start inserting each character one at a time.
              (0...@@g_paste_buffer.size).each do |x|
                @callbackfn.call(self, @@g_paste_buffer[x])
              end
              self.draw_field
            else
              RNDK.beep
            end
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            if @text.size < @min
              RNDK.beep
            else
              self.set_exit_type(input)
              ret = @text
              complete = true
            end
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
            @callbackfn.call(self, input)
          end
        end

        self.run_signal_binding(:after_input) if not complete
      end


      self.set_exit_type(0) if not complete
      @return_data = ret

      ret
    end

    def valid_template? input
      pp = 0
      ip = 0
      while ip < input.size && pp < @plate.size
        newchar = input[ip]
        while pp < @plate.size && !RNDK::Template.isPlateChar(@plate[pp])
          pp += 1
        end
        if pp == @plate.size
          return false
        end

        # Check if the input matches the plate
        if RNDK.digit?(newchar) && 'ACc'.include?(@plate[pp])
          return false
        end
        if !RNDK.digit?(newchar) && @plate[pp] == '#'
          return false
        end

        # Do we need to convert the case?
        if @plate[pp] == 'C' || @plate[pp] == 'X'
          newchar = newchar.upcase
        elsif @plate[pp] == 'c' || @plate[pp] == 'x'
          newchar = newchar.downcase
        end
        input[ip] = newchar
        ip += 1
        pp += 1
      end
      return true
    end

    # Return a mixture of the plate-overlay and field-text
    def mix
      mixed_string = ''
      plate_pos = 0
      text_pos = 0

      if @text.size > 0
        mixed_string = ''
        while plate_pos < @plate_len && text_pos < @text.size
          mixed_string << if RNDK::Template.isPlateChar(@plate[plate_pos])
                          then text_pos += 1; @text[text_pos - 1]
                          else @plate[plate_pos]
                          end
          plate_pos += 1
        end
      end

      return mixed_string
    end

    # Return the field_text from the mixed string.
    def unmix(text)
      pos = 0
      unmixed_string = ''

      while pos < @text.size
        if RNDK::Template.isPlateChar(@plate[pos])
          unmixed_string << text[pos]
        end
        pos += 1
      end

      return unmixed_string
    end

    # Move the template field to the given location.
    def move(x, y, relative, refresh_flag)
      windows = [@win, @label_win, @field_win, @shadow_win]
      self.move_specific(x, y, relative, refresh_flag,
          windows, [])
    end

    # Draw the template widget.
    def draw
      # Do we need to draw the shadow.
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      draw_box @win if @box
      self.draw_title(@win)
      Ncurses.wrefresh @win

      self.draw_field
    end

    # Draw the template field
    def draw_field
      field_color = 0

      # Draw in the label and the template widget.
      unless @label_win.nil?
        Draw.writeChtype(@label_win, 0, 0, @label, RNDK::HORIZONTAL,
            0, @label_len)
        Ncurses.wrefresh @label_win
      end

      # Draw in the template
      if @overlay.size > 0
        Draw.writeChtype(@field_win, 0, 0, @overlay, RNDK::HORIZONTAL,
            0, @overlay_len)
      end

      # Adjust the cursor.
      if @text.size > 0
        pos = 0
        (0...[@field_width, @plate.size].min).each do |x|
          if RNDK::Template.isPlateChar(@plate[x]) && pos < @text.size
            field_color = @overlay[x] & RNDK::Color[:extract]
            Ncurses.mvwaddch(@field_win, 0, x, @text[pos].ord | field_color)
            pos += 1
          end
        end
        Ncurses.wmove(@field_win, 0, @screen_pos)
      else
        self.adjust_cursor(1)
      end
      Ncurses.wrefresh @field_win
    end

    # Adjust the cursor for the template
    def adjust_cursor(direction)
      while @plate_pos < [@field_width, @plate.size].min &&
          !RNDK::Template.isPlateChar(@plate[@plate_pos])
        @plate_pos += direction
        @screen_pos += direction
      end
      Ncurses.wmove(@field_win, 0, @screen_pos)
      Ncurses.wrefresh @field_win
    end

    # Set the background attribute of the widget.
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)
      Ncurses.wbkgd(@label_win, attrib) unless @label_win.nil?
    end

    # Destroy this widget.
    def destroy
      clean_title

      # Delete the windows
      RNDK.window_delete(@field_win)
      RNDK.window_delete(@label_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      clean_bindings

      @screen.unregister self
    end

    # Erase the widget.
    def erase
      if self.valid?
        RNDK.window_erase(@field_win)
        RNDK.window_erase(@label_win)
        RNDK.window_erase(@shadow_win)
        RNDK.window_erase(@win)
      end
    end

    # Set the value given to the template
    def set(new_value, box)
      self.setValue(new_value)
      self.set_box(box)
    end

    # Set the value given to the template.
    def setValue(new_value)
      len = 0

      # Just to be sure, let's make sure the new value isn't nil
      if new_value.nil?
        clean
        return
      end

      # Determine how many characters we need to copy.
      copychars = [@new_value.size, @field_width, @plate.size].min

      @text = new_value[0...copychars]

      # Use the function which handles the input of the characters.
      (0...new_value.size).each do |x|
        @callbackfn.call(self, new_value[x].ord)
      end
    end

    def getValue
      return @text
    end

    # Set the minimum number of characters to enter into the widget.
    def setMin(min)
      if min >= 0
        @min = min
      end
    end

    def getMin
      return @min
    end

    # Erase the textrmation in the template widget.
    def clean
      @text = ''
      @screen_pos = 0
      @text_pos = 0
      @plaste_pos = 0

      draw
    end

    def empty?
      @text.empty?
    end

    # Set the callback function for the widget.
    def setCB(callback)
      @callbackfn = callback
    end

    def focus
      self.draw
    end

    def unfocus
      self.draw
    end

    def self.isPlateChar(c)
      '#ACcMXz'.include?(c.chr)
    end

    def position
      super(@win)
    end



  end
end
