require 'rndk'

module RNDK

  # A text-entry box with a label and an entry field.
  #
  # ## Keybindings
  #
  # Left Arrow::  Moves the cursor to the left.
  # CTRL-B::      Moves the cursor to the left.
  # Right Arrow:: Moves the cursor to the right.
  # CTRL-F::      Moves the cursor to the right.
  # Delete::      Deletes the character at the cursor.
  # Backspace::   Deletes the character before cursor,
  #               moves cursor left.
  # CTRL-V::      Pastes from the paste buffer into the widget
  # CTRL-X::      Cuts the contents from the widget into the
  #               paste buffer.
  # CTRL-Y::      Copies the contents of the widget into the
  #               paste buffer.
  # CTRL-U::      Erases the contents of the widget.
  # CTRL-A::      Moves the cursor to the beginning of the entry field.
  # CTRL-E::      Moves the cursor to the end of the entry field.
  # CTRL-T::      Transposes the character under the cursor
  #               with the character to the right.
  # Return::      Exits the widget and returns the text typed
  #               into the field.
  #               It also sets the widget data exitType to `:NORMAL`.
  # Tab::         Exits the widget and returns the text typed
  #               into the field.
  #               It also sets the widget data exitType to `:NORMAL`.
  # Escape::      Exits the widget and returns `nil`.
  #               It also sets the widget data exitType to `:ESCAPE_HIT`.
  # Ctrl-L::      Refreshes the screen.
  #
  # ## Behavior
  #
  # When passing the `disp_type` argument to Entry#initialize,
  # you can modify the Entry behavior when receiving chars
  # from the user.
  #
  # Send one of those for an action:
  #
  # `:CHAR`::     Only accepts alphabetic characters.
  # `:LCHAR`::    Only accepts alphabetic characters.
  #               Maps the character to lower case when a character
  #               has been accepted.
  # `:UCHAR`::    Only accepts alphabetic characters.
  #               Maps the  character to upper case when a character
  #               has been accepted.
  # `:HCHAR`::    Only accepts alphabetic characters.  Displays
  #               a period  (.)  when  a  character  has  been
  #               accepted.
  # `:UHCHAR`::   Only accepts alphabetic characters.  Displays
  #               a period (.) and maps the character to upper
  #               case when a character has been accepted.
  # `:LHCHAR`::   Only accepts alphabetic characters.  Displays
  #               a period (.) and maps the character to lower
  #               case when a character has been accepted.
  # `:INT`::      Only accepts numeric characters.
  # `:HINT`::     Only accepts numeric characters.  Displays  a
  #               period   (.)  when   a  character     has  been
  #               accepted.
  # `:MIXED`::    Accepts any character types.
  # `:LMIXED`::   Accepts any character types.  Maps the  char-
  #               acter  to lower case when an alphabetic char-
  #               acter has been accepted.
  # `:UMIXED`::   Accepts any character types.  Maps the  char-
  #               acter  to upper case when an alphabetic char-
  #               acter has been accepted.
  # `:HMIXED`::   Accepts  any  character  types.   Displays  a
  #               period   (.)   when   a  character     has  been
  #               accepted.
  # `:LHMIXED`::  Accepts  any  character  types.   Displays  a
  #               period  (.)  and  maps the character to lower
  #               case when a character has been accepted.
  # `:UHMIXED`::  Accepts  any  character  types.   Displays  a
  #               period  (.)  and  maps the character to upper
  #               case when a character has been accepted.
  # `:VIEWONLY`:: Uneditable field.
  #
  class Entry < Widget
    attr_accessor :info, :left_char, :screen_col
    attr_reader :win, :box_height, :box_width, :max, :field_width
    attr_reader :min, :max


    # Creates an Entry Widget.
    #
    # ## Arguments
    #
    # * `xplace` is the x position - can be an integer or
    #   `RNDK::LEFT`, `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `yplace` is the y position - can be an integer or
    #   `RNDK::TOP`, `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `title` can be more than one line - just split them
    #   with `\n`s.
    # * `label` is the String that will appear on the label
    #   of the Entry field.
    # * `field_attr` is the attribute/color of the characters
    #   that are typed in.
    # * `filler_char` is the character to display on the
    #   empty spaces in the entry field.
    # * `disp_type` tells how the entry field will behave.
    #   _See main Entry documentation_.
    # * `f_width` is the width of the field. It it's 0,
    #   will be created with full width of the screen.
    #   If it's a negative value, will create with full width
    #   minus that value.
    # * `min` is the minimum number of characters the user
    #   must insert before can exit the entry field.
    # * `max` is the maximum number of characters the user
    #   can enter on the entry field.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    def initialize(rndkscreen,
                   xplace,
                   yplace,
                   title,
                   label,
                   field_attr,
                   filler,
                   disp_type,
                   f_width,
                   min,
                   max,
                   box,
                   shadow)
      super()

      parent_width  = Ncurses.getmaxx rndkscreen.window
      parent_height = Ncurses.getmaxy rndkscreen.window

      field_width = f_width
      box_width   = 0

      xpos = xplace
      ypos = yplace

      self.set_box box
      box_height = @border_size*2 + 1

      # If the field_width is a negative value, the field_width will be
      # COLS-field_width, otherwise the field_width will be the given width.
      field_width = RNDK.setWidgetDimension(parent_width, field_width, 0)
      box_width = field_width + 2*@border_size

      # Set some basic values of the entry field.
      @label = 0
      @label_len = 0
      @label_win = nil

      # Translate the label string to a chtype array
      if !(label.nil?) && label.size > 0
        label_len = [@label_len]
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
        box_width += @label_len
      end

      old_width = box_width
      box_width = self.set_title(title, box_width)
      horizontal_adjust = (box_width - old_width) / 2

      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensinos of the window.
      box_width = [box_width, parent_width].min
      box_height = [box_height, parent_height].min
      field_width = [field_width,
          box_width - @label_len - 2 * @border_size].min

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(rndkscreen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the label window.
      @win = Ncurses.subwin(rndkscreen.window, box_height, box_width, ypos, xpos)
      if @win.nil?
        self.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      # Make the field window.
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

      # make the label win, if we need to
      if !(label.nil?) && label.size > 0
        @label_win = Ncurses.subwin(@win, 1, @label_len,
            ypos + @title_lines + @border_size,
            xpos + horizontal_adjust + @border_size)
      end

      # cleanChar (entry->info, max + 3, '\0');
      @info = ''
      @info_width = max + 3

      # Set up the rest of the structure.
      @screen = rndkscreen
      @parent = rndkscreen.window
      @shadow_win = nil
      @field_attr = field_attr
      @field_width = field_width
      @filler = filler
      @hidden = filler
      @input_window = @field_win
      @accepts_focus = true
      @data_ptr = nil
      @shadow = shadow
      @screen_col = 0
      @left_char = 0
      @min = min
      @max = max
      @box_width = box_width
      @box_height = box_height
      @disp_type = disp_type
      @callbackfn = lambda do |entry, character|
        plainchar = Display.filter_by_display_type(entry, character)

        if plainchar == Ncurses::ERR || entry.info.size >= entry.max
          RNDK.beep
        else
          # Update the screen and pointer
          if entry.screen_col != entry.field_width - 1
            front = (entry.info[0...(entry.screen_col + entry.left_char)] or '')
            back  = (entry.info[(entry.screen_col + entry.left_char)..-1] or '')

            entry.info = front + plainchar.chr + back
            entry.screen_col += 1

          else
            # Update the character pointer.
            entry.info << plainchar
            # Do not update the pointer if it's the last character
            entry.left_char += 1 if (entry.info.size < entry.max)
          end

          # Update the entry field.
          entry.drawField
        end
      end

      # Do we want a shadow?
      if shadow
        @shadow_win = Ncurses.subwin(rndkscreen.window,
                                     box_height,
                                     box_width,
                                     ypos + 1,
                                     xpos + 1)
      end

      rndkscreen.register(:entry, self)
    end

    # Activates the Entry Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    # @return The text currently inside the entry field (and
    #         `exit_type` will be `:NORMAL`) or `nil` (and
    #         `exit_type` will be `:ESCAPE_HIT`).
    def activate(actions=[])
      input = 0
      ret = 0

      # Draw the widget.
      self.draw(@box)

      if actions.nil? or actions.size == 0
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

      # Make sure we return the correct info.
      if @exit_type == :NORMAL
        return @info
      else
        return 0
      end
    end

    # @see Widget#inject
    def inject input
      pp_return = true
      ret = 1
      complete = false

      # Set the exit type
      self.set_exit_type(0)

      # Refresh the widget field.
      self.drawField

      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(:entry, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return

        # Check a predefined binding
        if self.checkBind(:entry, input)
          complete = true

        else
          curr_pos = @screen_col + @left_char

          case input
          when Ncurses::KEY_UP, Ncurses::KEY_DOWN
            RNDK.beep

          when Ncurses::KEY_HOME
            @left_char = 0
            @screen_col = 0
            self.drawField

          when RNDK::TRANSPOSE
            if curr_pos >= @info.size - 1
              RNDK.beep
            else
              holder = @info[curr_pos]
              @info[curr_pos] = @info[curr_pos + 1]
              @info[curr_pos + 1] = holder
              self.drawField
            end

          when Ncurses::KEY_END
            self.setPositionToEnd
            self.drawField

          when Ncurses::KEY_LEFT
            if curr_pos <= 0
              RNDK.beep
            elsif @screen_col == 0
              # Scroll left.
              @left_char -= 1
              self.drawField
            else
              @screen_col -= 1
              Ncurses.wmove(@field_win, 0, @screen_col)
            end

          when Ncurses::KEY_RIGHT
            if curr_pos >= @info.size
              RNDK.beep
            elsif @screen_col == @field_width - 1
              # Scroll to the right.
              @left_char += 1
              self.drawField
            else
              # Move right.
              @screen_col += 1
              Ncurses.wmove(@field_win, 0, @screen_col)
            end

          when Ncurses::KEY_BACKSPACE, Ncurses::KEY_DC
            if @disp_type == :VIEWONLY
              RNDK.beep
            else
              success = false
              if input == Ncurses::KEY_BACKSPACE
                curr_pos -= 1
              end

              if curr_pos >= 0 && @info.size > 0
                if curr_pos < @info.size
                  @info = @info[0...curr_pos] + @info[curr_pos+1..-1]
                  success = true
                elsif input == Ncurses::KEY_BACKSPACE
                  @info = @info[0...-1]
                  success = true
                end
              end

              if success
                if input == Ncurses::KEY_BACKSPACE
                  if @screen_col > 0
                    @screen_col -= 1
                  else
                    @left_char -= 1
                  end
                end
                self.drawField
              else
                RNDK.beep
              end
            end
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            complete = true

          when RNDK::ERASE
            if @info.size != 0
              self.clean
              self.drawField
            end

          when RNDK::CUT
            if @info.size != 0
              @@g_paste_buffer = @info.clone
              self.clean
              self.drawField
            else
              RNDK.beep
            end

          when RNDK::COPY
            if @info.size != 0
              @@g_paste_buffer = @info.clone
            else
              RNDK.beep
            end

          when RNDK::PASTE
            if @@g_paste_buffer != 0
              self.set_text(@@g_paste_buffer)
              self.drawField
            else
              RNDK.beep
            end

          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            if @info.size >= @min
              self.set_exit_type(input)
              ret = @info
              complete = true
            else
              RNDK.beep
            end

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

        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(:entry, self, @post_process_data, input)
        end
      end

      unless complete
        self.set_exit_type(0)
      end

      @result_data = ret
      return ret
    end

    # @see Widget#move
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@win, @field_win, @label_win, @shadow_win]

      self.move_specific(xplace, yplace, relative, refresh_flag, windows, [])
    end

    # Clears the text from the entry field.
    def clean
      width = @field_width

      @info = ''

      # Clean the entry screen field.
      Ncurses.mvwhline(@field_win, 0, 0, @filler.ord, width)

      # Reset some variables
      @screen_col = 0
      @left_char = 0

      # Refresh the entry field.
      Ncurses.wrefresh @field_win
    end

    # Draws the Widget on the Screen.
    #
    # If `box` is true, it is drawn with a box.
    def draw box
      # Did we ask for a shadow?
      Draw.drawShadow @shadow_win unless @shadow_win.nil?

      # Box the widget if asked.
      Draw.drawObjBox(@win, self) if box

      self.drawTitle @win
      Ncurses.wrefresh @win

      # Draw in the label to the widget.
      unless @label_win.nil?
        Draw.writeChtype(@label_win,
                         0,
                         0,
                         @label,
                         RNDK::HORIZONTAL,
                         0,
                         @label_len)

        Ncurses.wrefresh @label_win
      end

      self.drawField
    end

    # @see Widget#erase
    def erase
      if self.valid_widget?
        RNDK.window_erase(@field_win)
        RNDK.window_erase(@label_win)
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # @see Widget#destroy
    def destroy
      self.cleanTitle

      RNDK.window_delete(@field_win)
      RNDK.window_delete(@label_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      self.clean_bindings(:entry)

      RNDK::Screen.unregister(:entry, self)
    end

    # Sets multiple attributes of the Widget.
    #
    # See Entry#initialize.
    def set(text, min, max, box)
      self.set_text text
      self.set_min min
      self.set_max max

      ## FIXME TODO
      ## what about the `box`?
    end

    # Sets the current text on the entry field.
    def set_text new_value
      if new_value.nil?
        @info = ''

        @left_char = 0
        @screen_col = 0
      else
        @info = new_value.clone

        self.setPositionToEnd
      end
    end

    # Returns the current text on the entry field.
    def get_text
      return @info
    end

    # Sets the maximum length of the string that
    # will be accepted.
    def set_max max
      @max = max
    end

    def get_max
      @max
    end

    # Sets the minimum length of the string that
    # will be accepted.
    def set_min min
      @min = min
    end

    def get_min
      @min
    end

    # Sets the character to draw unused space on the field.
    def set_filler_char(filler_char)
      @filler = filler_char
    end

    def get_filler_char
      @filler
    end

    # Sets the character to hide input when a hidden
    # type is used.
    #
    # See Entry#initialize
    def set_hidden_char char
      @hidden = char
    end

    def get_hidden_char
      @hidden
    end

    # Sets the background attribute/color of the widget.
    def set_bg_attrib attrib
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)

      @label_win.wbkgd(attrib) unless @label_win.nil?
    end

    # Sets the background attribute/color of the entry field.
    #
    # `cursor` tells if we hide the blinking cursor or not.
    # See Ncurses#curs_set.
    def set_highlight(highlight, cursor)
      Ncurses.wbkgd(@field_win, highlight)
      @field_attr = highlight
      Ncurses.curs_set cursor

      # FIXME(original) - if (cursor) { move the cursor to this widget }
    end

    def focus
      Ncurses.wmove(@field_win, 0, @screen_col)
      Ncurses.wrefresh @field_win
    end

    def unfocus
      self.draw box
      Ncurses.wrefresh @field_win
    end

    # @see Widget#position
    def position
      super @win
    end

    def object_type
      :entry
    end

    # Allows the programmer to set a different widget input handler.
    #
    # @note Unless you're very low-level and know what you're doing
    #       you shouldn't need this.
    def setCB(callback)
      @callbackfn = callback
    end

    protected

    def drawField
      # Draw in the filler characters.
      Ncurses.mvwhline(@field_win, 0, 0, @filler.ord, @field_width)

      # If there is information in the field then draw it in.
      if (not @info.nil?) and (@info.size > 0)
        # Redraw the field.
        if Display.is_hidden_display_type(@disp_type)
          (@left_char...@info.size).each do |x|
            Ncurses.mvwaddch(@field_win, 0, x - @left_char, @hidden)
          end
        else
          (@left_char...@info.size).each do |x|
            Ncurses.mvwaddch(@field_win, 0, x - @left_char, @info[x].ord | @field_attr)
          end
        end
        Ncurses.wmove(@field_win, 0, @screen_col)
      end

      Ncurses.wrefresh @field_win
    end

    def setPositionToEnd
      if @info.size >= @field_width
        if @info.size < @max
          char_count = @field_width - 1
          @left_char = @info.size - char_count
          @screen_col = char_count
        else
          @left_char = @info.size - @field_width
          @screen_col = @info.size - 1
        end
      else
        @left_char = 0
        @screen_col = @info.size
      end
    end

  end
end
