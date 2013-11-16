require 'rndk'

module RNDK
  class TEMPLATE < Widget
    def initialize(screen, config={})
      super()
      @widget_type = :TEMPLATE

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

      parent_width = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)
      box_width = 0
      box_height = if box then 3 else 1 end
      plate_len = 0

      if plate.nil? || plate.size == 0
        return nil
      end

      self.set_box(box)

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
        @field_attr = @overlay[0] & Ncurses::A_COLORUTES
      else
        @overlay = []
        @overlay_len = 0
        @field_attr = Ncurses::A_NORMAL
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

      # Set up the info field.
      @plate_len = plate.size
      @info = ''
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
      @info_pos = 0
      @min = 0
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow
      @callbackfn = lambda do |template, input|
        failed = false
        change = false
        moveby = false
        amount = 0
        mark = @info_pos
        have = @info.size

        if input == Ncurses::KEY_LEFT
          if mark != 0
            moveby = true
            amount = -1
          else
            failed = true
          end
        elsif input == Ncurses::KEY_RIGHT
          if mark < @info.size
            moveby = true
            amount = 1
          else
            failed = true
          end
        else
          test = @info.clone
          if input == Ncurses::KEY_BACKSPACE
            if mark != 0
              front = @info[0...mark-1] || ''
              back = @info[mark..-1] || ''
              test = front + back
              change = true
              amount = -1
            else
              failed = true
            end
          elsif input == Ncurses::KEY_DC
            if mark < @info.size
              front = @info[0...mark] || ''
              back = @info[mark+1..-1] || ''
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
            if self.validTemplate(test)
              @info = test
              self.drawField
            else
              failed = true
            end
          end
        end

        if failed
          RNDK.beep
        elsif change || moveby
          @info_pos += amount
          @plate_pos += amount
          @screen_pos += amount

          self.adjustCursor(amount)
        end
      end

      # Do we need to create a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      screen.register(:TEMPLATE, self)
    end

    # This actually manages the tempalte widget
    def activate(actions=[])
      self.draw(@box)

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
    def inject(input)
      pp_return = true
      complete = false
      ret = false

      self.set_exit_type(0)

      # Move the cursor.
      self.drawField

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(:TEMPLATE, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return
        # Check a predefined binding
        if self.check_bind(input)
          complete = true
        else
          case input
          when RNDK::ERASE
            if @info.size > 0
              self.clean
              self.drawField
            end
          when RNDK::CUT
            if @info.size > 0
              @@g_paste_buffer = @info.clone
              self.clean
              self.drawField
            else
              RNDK.beep
            end
          when RNDK::COPY
            if @info.size > 0
              @@g_paste_buffer = @info.clone
            else
              RNDK.beep
            end
          when RNDK::PASTE
            if @@g_paste_buffer.size > 0
              self.clean

              # Start inserting each character one at a time.
              (0...@@g_paste_buffer.size).each do |x|
                @callbackfn.call(self, @@g_paste_buffer[x])
              end
              self.drawField
            else
              RNDK.beep
            end
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            if @info.size < @min
              RNDK.beep
            else
              self.set_exit_type(input)
              ret = @info
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

        # Should we call a post-process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(:TEMPLATE, self, @post_process_data, input)
        end
      end

      if !complete
        self.set_exit_type(0)
      end

      @return_data = ret
      return ret
    end

    def validTemplate(input)
      pp = 0
      ip = 0
      while ip < input.size && pp < @plate.size
        newchar = input[ip]
        while pp < @plate.size && !RNDK::TEMPLATE.isPlateChar(@plate[pp])
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

    # Return a mixture of the plate-overlay and field-info
    def mix
      mixed_string = ''
      plate_pos = 0
      info_pos = 0

      if @info.size > 0
        mixed_string = ''
        while plate_pos < @plate_len && info_pos < @info.size
          mixed_string << if RNDK::TEMPLATE.isPlateChar(@plate[plate_pos])
                          then info_pos += 1; @info[info_pos - 1]
                          else @plate[plate_pos]
                          end
          plate_pos += 1
        end
      end

      return mixed_string
    end

    # Return the field_info from the mixed string.
    def unmix(info)
      pos = 0
      unmixed_string = ''

      while pos < @info.size
        if RNDK::TEMPLATE.isPlateChar(@plate[pos])
          unmixed_string << info[pos]
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
    def draw(box)
      # Do we need to draw the shadow.
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box it if needed
      if box
        Draw.drawObjBox(@win, self)
      end

      self.draw_title(@win)

      Ncurses.wrefresh @win

      self.drawField
    end

    # Draw the template field
    def drawField
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
      if @info.size > 0
        pos = 0
        (0...[@field_width, @plate.size].min).each do |x|
          if RNDK::TEMPLATE.isPlateChar(@plate[x]) && pos < @info.size
            field_color = @overlay[x] & Ncurses::A_COLORUTES
            Ncurses.mvwaddch(@field_win, 0, x, @info[pos].ord | field_color)
            pos += 1
          end
        end
        Ncurses.wmove(@field_win, 0, @screen_pos)
      else
        self.adjustCursor(1)
      end
      Ncurses.wrefresh @field_win
    end

    # Adjust the cursor for the template
    def adjustCursor(direction)
      while @plate_pos < [@field_width, @plate.size].min &&
          !RNDK::TEMPLATE.isPlateChar(@plate[@plate_pos])
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
      self.clean_title

      # Delete the windows
      RNDK.window_delete(@field_win)
      RNDK.window_delete(@label_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      self.clean_bindings

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
        self.clean
        return
      end

      # Determine how many characters we need to copy.
      copychars = [@new_value.size, @field_width, @plate.size].min

      @info = new_value[0...copychars]

      # Use the function which handles the input of the characters.
      (0...new_value.size).each do |x|
        @callbackfn.call(self, new_value[x].ord)
      end
    end

    def getValue
      return @info
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

    # Erase the information in the template widget.
    def clean
      @info = ''
      @screen_pos = 0
      @info_pos = 0
      @plaste_pos = 0
    end

    # Set the callback function for the widget.
    def setCB(callback)
      @callbackfn = callback
    end

    def focus
      self.draw(@box)
    end

    def unfocus
      self.draw(@box)
    end

    def self.isPlateChar(c)
      '#ACcMXz'.include?(c.chr)
    end

    def position
      super(@win)
    end



  end
end
