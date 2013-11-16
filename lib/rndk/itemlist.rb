require 'rndk'

module RNDK

  class Itemlist < Widget

    def initialize(screen, config={})
      super()
      @widget_type = :itemlist

      x            = 0
      y            = 0
      title        = "itemlist"
      label        = "label"
      items        = []
      default_item = 0
      box          = true
      shadow       = false

      config.each do |key, val|
        x            = val if key == :x
        y            = val if key == :y
        title        = val if key == :title
        label        = val if key == :label
        items        = val if key == :items
        default_item = val if key == :default_item
        box          = val if key == :box
        shadow       = val if key == :shadow
      end

      count = items.size
      parent_width = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)
      field_width = 0

      if !self.create_list items
        self.destroy
        return nil
      end

      self.set_box(box)
      box_height = (@border_size * 2) + 1

      # Set some basic values of the item list
      @label = ''
      @label_len = 0
      @label_win = nil

      # Translate the label string to a chtype array
      if !(label.nil?) && label.size > 0
        label_len = []
        @label = RNDK.char2Chtype(label, label_len, [])
        @label_len = label_len[0]
      end

      # Set the box width. Allow an extra char in field width for cursor
      field_width = self.maximumFieldWidth + 1
      box_width = field_width + @label_len + 2 * @border_size
      box_width = self.set_title(title, box_width)
      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensions of the window
      @box_width = [box_width, parent_width].min
      @box_height = [box_height, parent_height].min
      self.updateFieldWidth

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the window.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)
      if @win.nil?
        self.destroy
        return nil
      end

      # Make the label window if there was a label.
      if @label.size > 0
        @label_win = Ncurses.subwin(@win, 1, @label_len,
            ypos + @border_size + @title_lines,
            xpos + @border_size)

        if @label_win.nil?
          self.destroy
          return nil
        end
      end

      Ncurses.keypad(@win, true)

      # Make the field window.
      if !self.createFieldWin(
          ypos + @border_size + @title_lines,
          xpos + @label_len + @border_size)
        self.destroy
        return nil
      end

      # Set up the rest of the structure
      @screen = screen
      @parent = screen.window
      @shadow_win = nil
      @accepts_focus = true
      @shadow = shadow

      # Set the default item.
      if default_item >= 0 && default_item < @list_size
        @current_item = default_item
        @default_item = default_item
      else
        @current_item = 0
        @default_item = 0
      end

      # Do we want a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
        if @shadow_win.nil?
          self.destroy
          return nil
        end
      end

      # Register this baby.
      screen.register(@widget_type, self)
    end

    # This allows the user to play with the widget.
    def activate(actions=[])
      ret = false

      # Draw the widget.
      self.draw
      self.drawField(true)

      if actions.nil? || actions.size == 0
        input = 0

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

      # Set the exit type and exit.
      self.set_exit_type(0)
      return ret
    end

    # This injects a single character into the widget.
    def inject(input)
      pp_return = true
      ret = false
      complete = false

      # Set the exit type.
      self.set_exit_type(0)

      # Draw the widget field
      self.drawField(true)

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(@widget_type, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return
        # Check a predefined binding.
        if self.is_bound? input
          self.run_binding input
          #complete = true
        else
          case input
          when Ncurses::KEY_UP, Ncurses::KEY_RIGHT, ' '.ord, '+'.ord, 'n'.ord
            if @current_item < @list_size - 1
              @current_item += 1
            else
              @current_item = 0
            end
          when Ncurses::KEY_DOWN, Ncurses::KEY_LEFT, '-'.ord, 'p'.ord
            if @current_item > 0
              @current_item -= 1
            else
              @current_item = @list_size - 1
            end
          when 'd'.ord, 'D'.ord
            @current_item = @default_item
          when '0'.ord
            @current_item = 0
          when '$'.ord
            @current_item = @list_size - 1
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            complete = true
          when Ncurses::ERR
            self.set_exit_type(input)
            complete = true
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            self.set_exit_type(input)
            ret = @current_item
            complete = true
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          else
            RNDK.beep
          end
        end

        # Should we call a post-process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(@widget_type, self, @post_process_data, input)
        end
      end

      if !complete
        self.drawField(true)
        self.set_exit_type(0)
      end

      @result_data = ret
      return ret
    end

    # This moves the itemlist field to the given location.
    def move(x, y, relative, refresh_flag)
      windows = [@win, @field_win, @label_win, @shadow_win]
      self.move_specific(x, y, relative, refresh_flag,
          windows, [])
    end

    # This draws the widget on the screen.
    def draw
      # Did we ask for a shadow?
      Draw.drawShadow(@shadow_win) unless @shadow_win.nil?

      self.draw_title(@win)

      # Draw in the label to the widget.
      unless @label_win.nil?
        Draw.writeChtype(@label_win, 0, 0, @label, RNDK::HORIZONTAL,
            0, @label.size)
      end

      # Box the widget if asked.
      Draw.drawObjBox(@win, self) if @box

      Ncurses.wrefresh @win

      # Draw in the field.
      self.drawField(false)
    end

    # This sets the background attribute of the widget
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)
      Ncurses.wbkgd(@label_win, attrib) unless @label_win.nil?
    end

    # This function draws the contents of the field.
    def drawField(highlight)
      # Declare local vars.
      current_item = @current_item

      # Determine how much we have to draw.
      len = [@item_len[current_item], @field_width].min

      # Erase the field window.
      Ncurses.werase(@field_win)

      # Draw in the current item in the field.
      (0...len).each do |x|
        c = @item[current_item][x]

        if highlight
          c = c.ord | Ncurses::A_REVERSE
        end

        Ncurses.mvwaddch(@field_win, 0, x + @item_pos[current_item], c)
      end

      # Redraw the field window.
      Ncurses.wrefresh(@field_win)
    end

    # This function removes the widget from the screen.
    def erase
      if self.valid?
        RNDK.window_erase(@field_win)
        RNDK.window_erase(@label_win)
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    def destroyInfo
      @list_size = 0
      @item = ''
    end

    # This function destroys the widget and all the memory it used.
    def destroy
      self.clean_title
      self.destroyInfo

      # Delete the windows
      RNDK.window_delete(@field_win)
      RNDK.window_delete(@label_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      self.clean_bindings

      @screen.unregister self
    end

    # This sets multiple attributes of the widget.
    def set(list, count, current, box)
      self.set_values(list, count, current)
      self.set_box(box)
    end

    # This function sets the contents of the list
    def set_values(item, default_item)
      if self.create_list item
        old_width = @field_width

        # Set the default item.
        if default_item >= 0 && default_item < @list_size
          @current_item = default_item
          @default_item = default_item
        end

        # This will not resize the outer windows but can still make a usable
        # field width if the title made the outer window wide enough
        self.updateFieldWidth
        if @field_width > old_width
          self.createFieldWin(@field_win.getbegy, @field_win.getbegx)
        end

        # Draw the field.
        self.erase
        self.draw
      end
    end

    def getValues(size)
      size << @list_size
      return @item
    end

    # This sets the default/current item of the itemlist
    def setCurrentItem(current_item)
      # Set the default item.
      if current_item >= 0 && current_item < @list_size
        @current_item = current_item
      end
    end

    def getCurrentItem
      return @current_item
    end

    # This sets the default item in the list.
    def setDefaultItem(default_item)
      # Make sure the item is in the correct range.
      if default_item < 0
        @default_item = 0
      elsif default_item >= @list_size
        @default_item = @list_size - 1
      else
        @default_item = default_item
      end
    end

    def getDefaultItem
      return @default_item
    end

    def focus
      self.drawField(true)
    end

    def unfocus
      self.drawField(false)
    end

    def create_list item
      count = item.size

      status = false
      new_items = []
      new_pos = []
      new_len = []
      if count >= 0
        field_width = 0

        # Go through the list and determine the widest item.
        status = true
        (0...count).each do |x|
          # Copy the item to the list.
          lentmp = []
          postmp = []
          new_items << RNDK.char2Chtype(item[x], lentmp, postmp)
          new_len << lentmp[0]
          new_pos << postmp[0]
          if new_items[0] == 0
            status = false
            break
          end
          field_width = [field_width, new_len[x]].max
        end

        # Now we need to justify the strings.
        (0...count).each do |x|
          new_pos[x] = RNDK.justifyString(field_width + 1,
              new_len[x], new_pos[x])
        end

        if status
          self.destroyInfo

          # Copy in the new information
          @list_size = count
          @item = new_items
          @item_pos = new_pos
          @item_len = new_len
        end
      else
        self.destroyInfo
        status = true
      end

      return status
    end

    # Go through the list and determine the widest item.
    def maximumFieldWidth
      max_width = -2**30

      (0...@list_size).each do |x|
        max_width = [max_width, @item_len[x]].max
      end
      max_width = [max_width, 0].max

      return max_width
    end

    def updateFieldWidth
      want = self.maximumFieldWidth + 1
      have = @box_width - @label_len - 2 * @border_size
      @field_width = [want, have].min
    end

    # Make the field window.
    def createFieldWin(ypos, xpos)
      @field_win = Ncurses.subwin(@win, 1, @field_width, ypos, xpos)

      unless @field_win.nil?
        Ncurses.keypad(@field_win, true)
        @input_window = @field_win
        return true
      end
      return false
    end

    def position
      super(@win)
    end



  end
end
