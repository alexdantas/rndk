require 'rndk/scroller'

module RNDK

  class Radio < Scroller

    def initialize(screen, config={})
      super()
      @widget_type = :radio
      @supported_signals += [:before_input, :after_input]

      x           = 0
      y           = 0
      scrollbar      = RNDK::RIGHT
      width       = 0
      height      = 0
      title       = "radio"
      items        = []
      choice_char = '#'.ord | RNDK::Color[:reverse]
      default    = 0
      highlight   = RNDK::Color[:reverse]
      box         = true
      shadow      = false

      config.each do |key, val|
        x           = val if key == :x
        y           = val if key == :y
        scrollbar      = val if key == :scrollbar
        width       = val if key == :width
        height      = val if key == :height
        title       = val if key == :title
        items       = val if key == :items
        choice_char = val if key == :choice_char
        default     = val if key == :default
        highlight   = val if key == :highlight
        box         = val if key == :box
        shadow      = val if key == :shadow
      end

      items_size = items.size
      parent_width = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)
      box_width = width
      box_height = height
      widest_item = 0

      self.set_box box

      # If the height is a negative value, height will be ROWS-height,
      # otherwise the height will be the given height.
      box_height = RNDK.set_widget_dimension(parent_height, height, 0)

      # If the width is a negative value, the width will be COLS-width,
      # otherwise the width will be the given width.
      box_width = RNDK.set_widget_dimension(parent_width, width, 5)

      box_width = self.set_title(title, box_width)

      # Set the box height.
      if @title_lines > box_height
        box_height = @title_lines + [items_size, 8].min + 2 * @border_size
      end

      # Adjust the box width if there is a scroll bar.
      if scrollbar == RNDK::LEFT || scrollbar == RNDK::RIGHT
        box_width += 1
        @scrollbar = true
      else
        scrollbar = false
      end

      # Make sure we didn't extend beyond the dimensions of the window
      @box_width = [box_width, parent_width].min
      @box_height = [box_height, parent_height].min

      self.set_view_size(items_size)

      # Each item in the needs to be converted to chtype array
      widest_item = self.create_items(items, @box_width)
      if widest_item > 0
        self.updateViewWidth(widest_item)
      elsif items_size > 0
        self.destroy
        return nil
      end

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the radio window
      @win = Ncurses.newwin(@box_height, @box_width, ypos, xpos)

      # Is the window nil?
      if @win.nil?
        self.destroy
        return nil
      end

      # Turn on the keypad.
      Ncurses.keypad(@win, true)

      # Create the scrollbar window.
      if scrollbar == RNDK::RIGHT
        @scrollbar_win = Ncurses.subwin(@win, self.max_view_size, 1,
            self.Screen_YPOS(ypos), xpos + @box_width - @border_size - 1)
      elsif scrollbar == RNDK::LEFT
        @scrollbar_win = Ncurses.subwin(@win, self.max_view_size, 1,
            self.Screen_YPOS(ypos), self.Screen_XPOS(xpos))
      else
        @scrollbar_win = nil
      end

      # Set the rest of the variables
      @screen = screen
      @parent = screen.window
      @scrollbar_placement = scrollbar
      @widest_item = widest_item
      @left_char = 0
      @selected_item = 0
      @highlight = highlight
      @choice_char = choice_char.ord
      @left_box_char = '['.ord
      @right_box_char = ']'.ord
      @default = default
      @input_window = @win
      @accepts_focus = true
      @shadow = shadow

      self.set_current_item(0)

      # Do we need to create the shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width + 1,
            ypos + 1, xpos + 1)
      end

      # Setup the key bindings
      self.bind_key('g') { self.scroll_begin }
      self.bind_key('1') { self.scroll_begin }
      self.bind_key('G') { self.scroll_end   }
      self.bind_key('<') { self.scroll_begin }
      self.bind_key('>') { self.scroll_end   }

      screen.register(@widget_type, self)
    end

    # Put the cursor on the currently-selected item.
    def fix_cursor_position
      scrollbar_adj = if @scrollbar_placement == RNDK::LEFT then 1 else 0 end
      ypos = self.Screen_YPOS(@current_item - @current_top)
      xpos = self.Screen_XPOS(0) + scrollbar_adj

      Ncurses.wmove(@input_window, ypos, xpos)
      Ncurses.wrefresh @input_window
    end

    # This actually manages the radio widget.
    def activate(actions=[])
      # Draw the radio items.
      self.draw

      if actions.nil? || actions.size == 0
        while true
          self.fix_cursor_position
          input = self.getch

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        actions.each do |action|
          ret = self.inject(action)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type and return
      self.set_exit_type(0)
      return -1
    end

    # This injects a single character into the widget.
    def inject input
      pp_return = true
      ret = false
      complete = false

      # Set the exit type
      self.set_exit_type(0)

      # Draw the widget items
      self.draw_items(@box)

      # Check if there is a pre-process function to be called.
      keep_going = self.run_signal_binding(:before_input, input)

      if keep_going

        # Check for a predefined key binding.
        if self.is_bound? input
          self.run_key_binding input
          #complete = true
        else
          case input
          when Ncurses::KEY_UP    then self.scroll_up
          when Ncurses::KEY_DOWN  then self.scroll_down
          when Ncurses::KEY_RIGHT then self.scroll_right
          when Ncurses::KEY_LEFT  then self.scroll_left
          when Ncurses::KEY_HOME  then self.scroll_begin
          when Ncurses::KEY_END   then self.scroll_end
          when Ncurses::KEY_PPAGE, RNDK::BACKCHAR
            self.scroll_page_up
          when Ncurses::KEY_NPAGE, RNDK::FORCHAR
            self.scroll_page_down
          when '$'.ord
            @left_char = @max_left_char
          when '|'.ord
            @left_char = 0
          when ' '.ord
            @selected_item = @current_item
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            ret = false
            complete = true
          when Ncurses::ERR
            self.set_exit_type(input)
            complete = true
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            self.set_exit_type(input)
            ret = @selected_item
            complete = true
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          end
        end

        # Should we call a post-process?
        self.run_signal_binding(:after_input) if not complete
      end

      if not complete
        self.draw_items(@box)
        self.set_exit_type(0)
      end

      self.fix_cursor_position
      @return_data = ret
      return ret
    end

    # This moves the radio field to the given location.
    def move(x, y, relative, refresh_flag)
      windows = [@win, @scrollbar_win, @shadow_win]
      self.move_specific(x, y, relative, refresh_flag,
          windows, subwidgets)
    end

    # This function draws the radio widget.
    def draw
      # Do we need to draw in the shadow?
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      self.draw_title @win

      # Draw in the radio items.
      self.draw_items @box
    end

    # This redraws the radio items.
    def draw_items(box)
      scrollbar_adj = if @scrollbar_placement == RNDK::LEFT then 1 else 0 end
      screen_pos = 0

      # Draw the items
      (0...@view_size).each do |j|
        k = j + @current_top
        if k < @items_size
          xpos = self.Screen_XPOS(0)
          ypos = self.Screen_YPOS(j)

          screen_pos = self.ScreenPOS(k, scrollbar_adj)

          # Draw the empty string.
          Draw.writeBlanks(@win, xpos, ypos, RNDK::HORIZONTAL, 0,
              @box_width - @border_size)

          # Draw the line.
          Draw.writeChtype(@win,
              if screen_pos >= 0 then screen_pos else 1 end,
              ypos, @item[k], RNDK::HORIZONTAL,
              if screen_pos >= 0 then 0 else 1 - screen_pos end,
              @item_len[k])

          # Draw the selected choice
          xpos += scrollbar_adj
          Ncurses.mvwaddch(@win, ypos, xpos, @left_box_char)
          Ncurses.mvwaddch(@win, ypos, xpos + 1,
              if k == @selected_item then @choice_char else ' '.ord end)
          Ncurses.mvwaddch(@win, ypos, xpos + 2, @right_box_char)
        end
      end

      # Highlight the current item
      if @has_focus
        k = @current_item
        if k < @items_size
          screen_pos = self.ScreenPOS(k, scrollbar_adj)
          ypos = self.Screen_YPOS(@current_high)

          Draw.writeChtypeAttrib(@win,
              if screen_pos >= 0 then screen_pos else 1 + scrollbar_adj end,
              ypos, @item[k], @highlight, RNDK::HORIZONTAL,
              if screen_pos >= 0 then 0 else 1 - screen_pos end,
              @item_len[k])
        end
      end

      if @scrollbar
        @toggle_pos = (@current_item * @step).floor
        @toggle_pos = [@toggle_pos, Ncurses.getmaxy(@scrollbar_win) - 1].min

        Ncurses.mvwvline(@scrollbar_win,
                         0,
                         0,
                         Ncurses::ACS_CKBOARD,
                         Ncurses.getmaxy(@scrollbar_win))

        Ncurses.mvwvline(@scrollbar_win,
                         @toggle_pos,
                         0,
                         ' '.ord | RNDK::Color[:reverse],
                         @toggle_size)
      end

      draw_box @win if @box
      fix_cursor_position
    end

    # This sets the background attribute of the widget.
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@scrollbar_win, attrib) unless @scrollbar_win.nil?
    end

    def destroy_info
      @item = ''
    end

    # This function destroys the radio widget.
    def destroy
      self.clean_title
      self.destroy_info

      # Clean up the windows.
      RNDK.window_delete(@scrollbar_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean up the key bindings.
      self.clean_bindings

      # Unregister this widget.
      @screen.unregister self
    end

    # This function erases the radio widget
    def erase
      if self.valid?
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # This sets various attributes of the radio items.
    def set(highlight, choice_char, box)
      self.set_highlight(highlight)
      self.setChoiceCHaracter(choice_char)
      self.set_box(box)
    end

    # This sets the radio items items.
    def set_items(items)
      widest_item = self.create_items(items, @box_width)
      return if widest_item <= 0

      # Clean up the display.
      (0...@view_size).each do |j|
        Draw.writeBlanks(@win, self.Screen_XPOS(0), self.Screen_YPOS(j),
            RNDK::HORIZONTAL, 0, @box_width - @border_size)
      end

      self.set_view_size(items_size)

      self.set_current_item(0)
      @left_char = 0
      @selected_item = 0

      self.updateViewWidth(widest_item)
    end

    def getItems(items)
      (0...@items_size).each do |j|
        items << RNDK.chtype2Char(@item[j])
      end
      return @items_size
    end

    # This sets the highlight bar of the radio items.
    def set_highlight(highlight)
      @highlight = highlight
    end

    def getHighlight
      return @highlight
    end

    # This sets the character to use when selecting na item in the items.
    def setChoiceCharacter(character)
      @choice_char = character
    end

    def getChoiceCharacter
      return @choice_char
    end

    # This sets the character to use to drw the left side of the choice box
    # on the items
    def setLeftBrace(character)
      @left_box_char = character
    end

    def getLeftBrace
      return @left_box_char
    end

    # This sets the character to use to draw the right side of the choice box
    # on the items
    def setRightBrace(character)
      @right_box_char = character
    end

    def getRightBrace
      return @right_box_char
    end

    # This sets the current highlighted item of the widget
    def set_current_item(item)
      self.set_position(item)
      @selected_item = item
    end

    def getCurrentItem
      return @current_item
    end

    # This sets the selected item of the widget
    def setSelectedItem(item)
      @selected_item = item
    end

    def getSelectedItem
      return @selected_item
    end

    def focus
      self.draw_items(@box)
    end

    def unfocus
      self.draw_items(@box)
    end

    def create_items(items, box_width)
      status = false
      widest_item = 0

      if items.size >= 0
        new_items = []
        new_len = []
        new_pos = []

        # Each item in the needs to be converted to chtype array
        status = true
        box_width -= 2 + @border_size
        (0...items.size).each do |j|
          lentmp = []
          postmp = []
          new_items << RNDK.char2Chtype(items[j], lentmp, postmp)
          new_len << lentmp[0]
          new_pos << postmp[0]
          if new_items[j].nil? || new_items[j].size == 0
            status = false
            break
          end
          new_pos[j] = RNDK.justifyString(box_width, new_len[j], new_pos[j]) + 3
          widest_item = [widest_item, new_len[j]].max
        end
        if status
          self.destroy_info
          @item = new_items
          @item_len = new_len
          @item_pos = new_pos
        end
      end
      @items_size = items.size

      return (if status then widest_item else 0 end)
    end

    # Determine how many characters we can shift to the right
    # before all the items have been scrolled off the screen.
    def AvailableWidth
      @box_width - 2 * @border_size - 3
    end

    def updateViewWidth(widest)
      @max_left_char = if @box_width > widest
                       then 0
                       else widest - self.AvailableWidth
                       end
    end

    def WidestItem
      @max_left_char + self.AvailableWidth
    end

    def ScreenPOS(n, scrollbar_adj)
      @item_pos[n] - @left_char + scrollbar_adj + @border_size
    end



  end
end
