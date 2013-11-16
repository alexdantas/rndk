require 'rndk'

module RNDK

  class Dialog < Widget

    attr_reader :current_button

    MIN_DIALOG_WIDTH = 10

    def initialize(screen, config={})
      super()
      @widget_type = :dialog

      x            = 0
      y            = 0
      text         = "dialog"
      buttons      = ["button"]
      highlight    = Ncurses::A_REVERSE
      separator    = true
      box          = true
      shadow       = false

      config.each do |key, val|
        x            = val if key == :x
        y            = val if key == :y
        text         = val if key == :text
        buttons      = val if key == :buttons
        highlight    = val if key == :highlight
        separator    = val if key == :separator
        box          = val if key == :box
        shadow       = val if key == :shadow
      end

      # Adjusting if the user sent us a String as text
      text = [text] if text.class == String
      return nil if text.class != Array or text.empty?
      rows = text.size

      # Adjusting if the user sent us a String as buttons
      buttons = [buttons] if buttons.class == String
      return nil if buttons.class != Array or buttons.empty?
      button_count = buttons.size

      box_width = Dialog::MIN_DIALOG_WIDTH
      max_message_width = -1
      button_width = 0
      xpos = x
      ypos = y
      temp = 0
      buttonadj = 0
      @info = []
      @info_len = []
      @info_pos = []
      @buttons = []
      @button_len = []
      @button_pos = []

      @screen = screen
      @parent = screen.window

      if rows <= 0 || button_count <= 0
        self.destroy
        return nil
      end

      self.set_box box
      box_height = if separator then 1 else 0 end
      box_height += rows + 2 * @border_size + 1

      # Translate the string message to a chtype array
      (0...rows).each do |x|
        info_len = []
        info_pos = []
        @info << RNDK.char2Chtype(text[x], info_len, info_pos)
        @info_len << info_len[0]
        @info_pos << info_pos[0]
        max_message_width = [max_message_width, info_len[0]].max
      end

      # Translate the button label string to a chtype array
      (0...button_count).each do |x|
        button_len = []
        @buttons << RNDK.char2Chtype(buttons[x], button_len, [])
        @button_len << button_len[0]
        button_width += button_len[0] + 1
      end

      button_width -= 1

      # Determine the final dimensions of the box.
      box_width = [box_width, max_message_width, button_width].max
      box_width = box_width + 2 + 2 * @border_size

      # Now we have to readjust the x and y positions.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Set up the dialog box attributes.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)
      @shadow_win = nil
      @button_count = button_count
      @current_button = 0
      @message_rows = rows
      @box_height = box_height
      @box_width = box_width
      @highlight = highlight
      @separator = separator
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow

      # If we couldn't create the window, we should return a nil value.
      if @win.nil?
        self.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      # Find the button positions.
      buttonadj = (box_width - button_width) / 2
      (0...button_count).each do |x|
        @button_pos[x] = buttonadj
        buttonadj = buttonadj + @button_len[x] + @border_size
      end

      # Create the string alignments.
      (0...rows).each do |x|
        @info_pos[x] = RNDK.justifyString(box_width - 2 * @border_size,
            @info_len[x], @info_pos[x])
      end

      # Was there a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Register this baby.
      screen.register(@widget_type, self)
    end

    # This lets the user select the button.
    def activate(actions=[])
      input = 0

      # Draw the dialog box.
      self.draw

      # Lets move to the first button.
      Draw.writeChtypeAttrib(@win,
                             @button_pos[@current_button],
                             @box_height - 1 - @border_size, @buttons[@current_button],
                             @highlight,
                             RNDK::HORIZONTAL,
                             0,
                             @button_len[@current_button])
      Ncurses.wrefresh @win

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

      # Set the exit type and exit
      self.set_exit_type(0)
      return -1
    end

    # This injects a single character into the dialog widget
    def inject(input)
      first_button = 0
      last_button = @button_count - 1
      pp_return = true
      ret = false
      complete = false

      # Set the exit type.
      self.set_exit_type(0)

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(@widget_type,
                                           self,
                                           @pre_process_data,
                                           input)
      end

      # Should we continue?
      if pp_return
        # Check for a key binding.
        if self.is_bound? input
          self.run_key_binding input
          #complete = true

        else
          case input
          when Ncurses::KEY_LEFT, Ncurses::KEY_BTAB, Ncurses::KEY_BACKSPACE
            if @current_button == first_button
              @current_button = last_button
            else
              @current_button -= 1
            end
          when Ncurses::KEY_RIGHT, RNDK::KEY_TAB, ' '.ord
            if @current_button == last_button
              @current_button = first_button
            else
              @current_button += 1
            end
          when Ncurses::KEY_UP, Ncurses::KEY_DOWN
            RNDK.beep
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            complete = true
          when Ncurses::ERR
            self.set_exit_type(input)
          when Ncurses::KEY_ENTER, RNDK::KEY_RETURN
            self.set_exit_type(input)
            ret = @current_button
            complete = true
          end
        end

        # Should we call a post_process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(@widget_type,
                                  self,
                                  @post_process_data,
                                  input)
        end
      end

      unless complete
        self.drawButtons
        Ncurses.wrefresh @win
        self.set_exit_type(0)
      end

      @result_data = ret
      return ret
    end

    # This function draws the dialog widget.
    def draw
      # Is there a shadow?
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box the widget if they asked.
      Draw.drawObjBox(@win, self) if @box

      # Draw in the message.
      (0...@message_rows).each do |x|
        Draw.writeChtype(@win,
                         @info_pos[x] + @border_size,
                         x + @border_size,
                         @info[x],
                         RNDK::HORIZONTAL,
                         0,
                         @info_len[x])
      end

      # Draw in the buttons.
      self.drawButtons

      Ncurses.wrefresh @win
    end

    # This function destroys the dialog widget.
    def destroy
      # Clean up the windows.
      RNDK.window_delete(@win)
      RNDK.window_delete(@shadow_win)

      # Clean the key bindings
      self.clean_bindings

      # Unregister this widget
      @screen.unregister self
    end

    # This function erases the dialog widget from the screen.
    def erase
      if self.valid?
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # This sets attributes of the dialog box.
    def set(highlight, separator, box)
      self.set_highlight(highlight)
      self.setSeparator(separator)
      self.set_box(box)
    end

    # This sets the highlight attribute for the buttons.
    def set_highlight(highlight)
      @highlight = highlight
    end

    def getHighlight
      return @highlight
    end

    # This sets whether or not the dialog box will have a separator line.
    def setSeparator(separator)
      @separator = separator
    end

    def getSeparator
      return @separator
    end

    # This sets the background attribute of the widget.
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
    end

    # This draws the dialog buttons and the separation line.
    def drawButtons
      (0...@button_count).each do |x|
        Draw.writeChtype(@win,
                         @button_pos[x],
                         @box_height -1 - @border_size,
                         @buttons[x],
                         RNDK::HORIZONTAL,
                         0,
                         @button_len[x])
      end

      # Draw the separation line.
      if @separator
        boxattr = @BXAttr

        (1...@box_width).each do |x|
          Ncurses.mvwaddch(@win,
                           @box_height - 2 - @border_size,
                           x,
                           Ncurses::ACS_HLINE | boxattr)
        end

        Ncurses.mvwaddch(@win,
                         @box_height - 2 - @border_size,
                         0,
                         Ncurses::ACS_LTEE | boxattr)
        Ncurses.mvwaddch(@win,
                         @box_height - 2 - @border_size,
                         Ncurses.getmaxx(@win) - 1,
                         Ncurses::ACS_RTEE | boxattr)
      end
      Draw.writeChtypeAttrib(@win,
                             @button_pos[@current_button],
                             @box_height - 1 - @border_size,
                             @buttons[@current_button],
                             @highlight,
                             RNDK::HORIZONTAL,
                             0,
                             @button_len[@current_button])
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
  end
end

