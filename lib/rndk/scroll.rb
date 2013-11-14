require 'rndk/scroller'

module RNDK

  # A scrolling list of text.
  #
  # ## Keybindings
  #
  # Left Arrow::  Shift the list left one column.
  # Right Arrow:: Shift the list right one column.
  # Up Arrow::    Select the previous item in the list.
  # Down Arrow::  Select the next item in the list.
  # Prev Page::   Scroll one page backward.
  # Ctrl-B::      Scroll one page backward.
  # Next Page::   Scroll one page forward.
  # Ctrl-F::      Scroll one page forward.
  # 1::           Move to the first element in the list.
  # <::           Move to the first element in the list.
  # g::           Move to the first element in the list.
  # Home::        Move to the first element in the list.
  # >::           Move to the last element in the list.
  # G::           Move to the last element in the list.
  # End::         Move to the last element in the list.
  # $::           Shift the list to the far right.
  # |::           Shift the list to the far left.
  # Return::      Exit  the  widget and return the index
  #               of the selected item. Also  set  the
  #               widget `exit_type` to `:NORMAL`.
  # Tab::         Exit  the  widget and return the index
  #               of the selected item.   Also  set  the
  #               widget `exit_type` to `:NORMAL`.
  # Escape::      Exit the  widget and return -1.  Also
  #               set the widget `exit_type` `:ESCAPE_HIT`.
  # Ctrl-L::      Refreshes the screen.
  #
  class Scroll < SCROLLER
    attr_reader :item, :list_size, :current_item, :highlight

    # Creates a Scroll Widget.
    #
    # * `xplace` is the x position - can be an integer or
    #   `RNDK::LEFT`, `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `yplace` is the y position - can be an integer or
    #   `RNDK::TOP`, `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `splace` is where the scrollbar will be placed.
    #   It can be only `RNDK::LEFT`, `RNDK::RIGHT` or
    #   `RNDK::NONE`, for no scrollbar.
    # * `width`/`height` are integers - if either are 0, Widget
    #   will be created with full width/height of the screen.
    #   If it's a negative value, will create with full width/height
    #   minus the value.
    # * `title` can be more than one line - just split them
    #   with `\n`s.
    # * `list` is an Array of Strings to be shown on the Widget.
    # * `numbers` is a flag to turn on/off line numbering at
    #   the front of the list items.
    # * `highlight` is the attribute/color of the currently selected
    #   item at the list.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    def initialize (rndkscreen,
                    xplace,
                    yplace,
                    splace,
                    width,
                    height,
                    title,
                    list,
                    numbers,
                    highlight,
                    box,
                    shadow)
      super()

      parent_width  = Ncurses.getmaxx rndkscreen.window
      parent_height = Ncurses.getmaxy rndkscreen.window

      box_width  = width
      box_height = height

      xpos = xplace
      ypos = yplace

      scroll_adjust = 0

      bindings = {
        RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
        RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
        'g'            => Ncurses::KEY_HOME,
        '1'            => Ncurses::KEY_HOME,
        'G'            => Ncurses::KEY_END,
        '<'            => Ncurses::KEY_HOME,
        '>'            => Ncurses::KEY_END
      }

      self.set_box box

      # If the height is a negative value, the height will be ROWS-height,
      # otherwise the height will be the given height
      box_height = RNDK.setWidgetDimension(parent_height, height, 0)

      # If the width is a negative value, the width will be COLS-width,
      # otherwise the width will be the given width
      box_width = RNDK.setWidgetDimension(parent_width, width, 0)

      box_width = self.set_title(title, box_width)

      # Set the box height.
      if @title_lines > box_height
        box_height = @title_lines + [list.size, 8].min + 2 * @border_size
      end

      # Adjust the box width if there is a scroll bar
      if splace == RNDK::LEFT || splace == RNDK::RIGHT
        @scrollbar = true
        box_width += 1
      else
        @scrollbar = false
      end

      # Make sure we didn't extend beyond the dimensions of the window.
      @box_width = if box_width > parent_width
                   then parent_width - scroll_adjust
                   else box_width
                   end
      @box_height = if box_height > parent_height
                    then parent_height
                    else box_height
                    end

      self.set_view_size(list.size)

      # Rejustify the x and y positions if we need to.
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(rndkscreen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the scrolling window
      @win = Ncurses.newwin(@box_height, @box_width, ypos, xpos)

      # Is the scrolling window null?
      if @win.nil?
        return nil
      end

      # Turn the keypad on for the window
      Ncurses.keypad(@win, true)

      # Create the scrollbar window.
      if splace == RNDK::RIGHT
        @scrollbar_win = Ncurses.subwin(@win,
                                        self.max_view_size,
                                        1,
                                        self.Screen_YPOS(ypos),
                                        xpos + box_width - @border_size - 1)
      elsif splace == RNDK::LEFT
        @scrollbar_win = Ncurses.subwin(@win,
                                        self.max_view_size,
                                        1,
                                        self.Screen_YPOS(ypos),
                                        self.Screen_XPOS(xpos))
      else
        @scrollbar_win = nil
      end

      # create the list window
      @list_win = Ncurses.subwin(@win,
                                 self.max_view_size,
                                 box_width - (2 * @border_size) - scroll_adjust,
                                 self.Screen_YPOS(ypos),
                                 self.Screen_XPOS(xpos) + (if splace == RNDK::LEFT then 1 else 0 end))

      # Set the rest of the variables
      @screen = rndkscreen
      @parent = rndkscreen.window
      @shadow_win = nil
      @scrollbar_placement = splace
      @max_left_char = 0
      @left_char = 0
      @highlight = highlight
      # initExitType (scrollp);
      @accepts_focus = true
      @input_window = @win
      @shadow = shadow

      self.set_position(0);

      # Create the scrolling list item list and needed variables.
      return nil unless self.create_item_list(numbers, list)

      # Do we need to create a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(@box_height,
                                     box_width,
                                     ypos + 1,
                                     xpos + 1)
      end

      # Set up the key bindings.
      bindings.each do |from, to|
        #self.bind(:scroll, from, getc_lambda, to)
        self.bind(:scroll, from, :getc, to)
      end

      rndkscreen.register(:scroll, self);

      self
    end

    def object_type
      :scroll
    end

    # @see Widget#position
    def position
      super @win
    end

    # Activates the Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    def activate(actions=[])
      self.draw @box

      if actions.nil? || actions.size == 0
        loop do
          self.fix_cursor_position
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject input

          return ret if @exit_type != :EARLY_EXIT
        end
      else
        # Inject each character one at a time.
        actions.each do |action|
          ret = self.inject action

          return ret if @exit_type != :EARLY_EXIT
        end
      end

      # Set the exit type for the widget and return
      self.set_exit_type(0)
      return nil
    end

    # @see Widget#inject
    def inject input
      ret = nil
      complete = false

      self.set_exit_type 0

      # Draw the scrolling list
      self.draw_list @box

      # Calls a pre-process block if exists
      pp_return = true
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(:scroll,
                                           self,
                                           @pre_process_data,
                                           input)
      end

      # Should we continue?
      if pp_return

        # Check for a predefined key binding.
        if self.checkBind(:scroll, input) != false
          #self.checkEarlyExit
          complete = true

        else
          case input
          when Ncurses::KEY_UP    then self.KEY_UP
          when Ncurses::KEY_DOWN  then self.KEY_DOWN
          when Ncurses::KEY_RIGHT then self.KEY_RIGHT
          when Ncurses::KEY_LEFT  then self.KEY_LEFT
          when Ncurses::KEY_PPAGE then self.KEY_PPAGE
          when Ncurses::KEY_NPAGE then self.KEY_NPAGE
          when Ncurses::KEY_HOME  then self.KEY_HOME
          when Ncurses::KEY_END   then self.KEY_END
          when '$'                then @left_char = @max_left_char
          when '|'                then @left_char = 0

          when RNDK::KEY_ESC
            self.set_exit_type(input)
            complete = true

          when Ncurses::ERR
            self.set_exit_type(input)
            complete = true

          when RNDK::REFRESH
            @screen.erase
            @screen.refresh

          when RNDK::KEY_TAB, Ncurses::KEY_ENTER, RNDK::KEY_RETURN
            self.set_exit_type(input)
            ret = @current_item
            complete = true
          end
        end

        if (not complete) and @post_process_func
          @post_process_func.call(:scroll,
                                  self,
                                  @post_process_data,
                                  input)
        end
      end

      if not complete
        self.draw_list(@box)
        self.set_exit_type(0)
      end

      self.fix_cursor_position
      @result_data = ret

      ret
    end

    # This moves the scroll field to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@win, @list_win, @shadow_win, @scrollbar_win]

      self.move_specific(xplace, yplace, relative, refresh_flag, windows, [])
    end

    # This function draws the scrolling list widget.
    def draw(box)
      # Draw in the shadow if we need to.
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      self.drawTitle(@win)

      # Draw in the scrolling list items.
      self.draw_list(box)
    end

    # This sets the background attribute of the widget.
    def set_bg_attrib(attrib)
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@list_win, attrib)

      unless @scrollbar_win.nil?
        Ncurses.wbkgd(@scrollbar_win, attrib)
      end
    end

    # This function destroys
    def destroy
      self.cleanTitle

      # Clean up the windows.
      RNDK.window_delete(@scrollbar_win)
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@list_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      self.clean_bindings(:scroll)

      # Unregister this object
      RNDK::Screen.unregister(:scroll, self)
    end

    # This function erases the scrolling list from the screen.
    def erase
      RNDK.window_erase(@win)
      RNDK.window_erase(@shadow_win)
    end

    # This sets certain attributes of the scrolling list.
    def set(list, numbers, highlight, box)
      self.set_items(list, numbers)
      self.set_highlight(highlight)
      self.set_box(box)
    end

    # Sets the scrolling list items.
    # See Scroll#initialize.
    def set_items(list, numbers)
      return unless self.create_item_list(numbers, list)

      # Clean up the display.
      (0...@view_size).each do |x|
        Draw.writeBlanks(@win, 1, x, RNDK::HORIZONTAL, 0, @box_width - 2);
      end

      self.set_view_size(list_size)
      self.set_position(0)
      self.erase

      @left_char = 0
    end

    def get_items(list)
      (0...@list_size).each do |x|
        list << RNDK.chtype2Char(@item[x])
      end

      @list_size
    end

    # This sets the highlight of the scrolling list.
    def set_highlight(highlight)
      @highlight = highlight
    end

    def get_highlight(highlight)
      return @highlight
    end

    # Adds a single item to a scrolling list, at the end of
    # the list.
    def add_item(item)
      item_number = @list_size
      widest_item = self.widest_item
      temp = ''
      have = 0

      if (self.alloc_list_arrays(@list_size, @list_size + 1)) and
          (self.alloc_list_item(item_number,
                               temp,
                               have,
                               if @numbers then item_number + 1 else 0 end,
                               item))
        # Determine the size of the widest item.
        widest_item = [@item_len[item_number], widest_item].max

        self.update_view_width(widest_item)
        self.set_view_size(@list_size + 1)
      end
    end

    # Adds a single item to a scrolling list before the current
    # item.
    def insert_item(item)
      widest_item = self.widest_item
      temp = ''
      have = 0

      if self.alloc_list_arrays(@list_size, @list_size + 1) &&
          self.insert_list_item(@current_item) &&
          self.alloc_list_item(@current_item,
                               temp,
                               have,
                               if @numbers then @current_item + 1 else 0 end,
                               item)

        # Determine the size of the widest item.
        widest_item = [@item_len[@current_item], widest_item].max

        self.update_view_width(widest_item)
        self.set_view_size(@list_size + 1)
        self.resequence
      end
    end

    # This removes a single item from a scrolling list.
    def delete_item(position)
      if position >= 0 && position < @list_size
        # Adjust the list
        @item = @item[0...position] + @item[position+1..-1]
        @item_len = @item_len[0...position] + @item_len[position+1..-1]
        @item_pos = @item_pos[0...position] + @item_pos[position+1..-1]

        self.set_view_size(@list_size - 1)

        self.resequence if @list_size > 0

        if @list_size < self.max_view_size
          Ncurses.werase @win  # force the next redraw to be complete
        end

        # do this to update the view size, etc
        self.set_position(@current_item)
      end
    end

    def focus
      self.draw_current
      Ncurses.wrefresh @list_win
    end

    def unfocus
      self.draw_current
      Ncurses.wrefresh @list_win
    end

    #                  _            _           _
    #                 | |          | |         | |
    #  _ __  _ __ ___ | |_ ___  ___| |_ ___  __| |
    # | '_ \| '__/ _ \| __/ _ \/ __| __/ _ \/ _` |
    # | |_) | | | (_) | ||  __| (__| ||  __| (_| |
    # | .__/|_|  \___/ \__\___|\___|\__\___|\__,_|
    # | |
    # |_|
    protected

    # Creates the scrolling list information and sets up the
    # needed variables for the scrolling list to work correctly.
    def create_item_list(numbers, list)
      status = false

      if list.size > 0
        widest_item = 0
        x = 0
        have = 0
        temp = ''

        if alloc_list_arrays(0, list.size)
          # Create the items in the scrolling list.
          status = true
          (0...list.size).each do |x|
            number = if numbers then x + 1 else 0 end

            unless self.alloc_list_item(x, temp, have, number, list[x])
              status = false
              break
            end

            widest_item = [@item_len[x], widest_item].max
          end

          if status
            self.update_view_width widest_item

            # Keep the boolean flag 'numbers'
            @numbers = numbers
          end
        end

      else
        status = true  # null list is ok - for a while
      end

      @list_size = list.size
      status
    end

    def alloc_list_arrays(old_size, new_size)

      new_list = Array.new new_size
      new_len  = Array.new new_size
      new_pos  = Array.new new_size

      (0...old_size).each do |n|
        new_list[n] = @item[n]
        new_len[n]  = @item_len[n]
        new_pos[n]  = @item_pos[n]
      end

      @item     = new_list
      @item_len = new_len
      @item_pos = new_pos

      true
    end

    # Creates a single item on the scroll list.
    def alloc_list_item(which, work, used, number, value)

      if number > 0
        value = "%4d. %s" % [number, value]
      end

      item_len = []
      item_pos = []
      @item[which] = RNDK.char2Chtype(value, item_len, item_pos)
      @item_len[which] = item_len[0]
      @item_pos[which] = item_pos[0]

      @item_pos[which] = RNDK.justifyString(@box_width,
                                            @item_len[which],
                                            @item_pos[which])
      true
    end

    # Resequence the numbers after an insertion/deletion.
    def resequence
      if @numbers
        (0...@list_size).each do |j|
          target = @item[j]

          source = "%4d. %s" % [j + 1, ""]

          k = 0
          while k < source.size
            # handle deletions that change the length of number
            if source[k] == "." && target[k] != "."
              source = source[0...k] + source[k+1..-1]
            end

            target[k] &= Ncurses::A_ATTRIBUTES
            target[k] |= source[k].ord
            k += 1
          end
        end
      end
    end

    def insert_list_item(item)
      @item = @item[0..item] + @item[item..-1]
      @item_len = @item_len[0..item] + @item_len[item..-1]
      @item_pos = @item_pos[0..item] + @item_pos[item..-1]

      true
    end

    def available_width
      @box_width - (2 * @border_size)
    end

    def update_view_width(widest)
      @max_left_char = if @box_width > widest
                       then 0
                       else widest - self.available_width
                       end
    end

    def widest_item
      @max_left_char + self.available_width
    end

    # Draws the scrolling list.
    def draw_list box

      # If the list is empty, don't draw anything.
      if @list_size > 0

        # Redraw the list
        (0...@view_size).each do |j|
          k = j + @current_top

          Draw.writeBlanks(@list_win,
                           0,
                           j,
                           RNDK::HORIZONTAL, 0,
                           @box_width - (2 * @border_size))

          # Draw the elements in the scrolling list.
          if k < @list_size
            ################################################################################
            if @item_pos[k].nil?
              RNDK::Screen.end_rndk
              puts "lol"
              puts k
              puts @list_size
              puts "lol"
              exit!
            end

            screen_pos = @item_pos[k] - @left_char
            ypos = j

            # Write in the correct line.
            Draw.writeChtype(@list_win,
                             if screen_pos >= 0 then screen_pos else 1 end,
                             ypos, @item[k], RNDK::HORIZONTAL,
                             if screen_pos >= 0 then 0 else 1 - screen_pos end,
                             @item_len[k])
          end
        end

        self.draw_current

        # Determine where the toggle is supposed to be.
        unless @scrollbar_win.nil?
          @toggle_pos = (@current_item * @step).floor

          # Make sure the toggle button doesn't go out of bounds.
          if @toggle_pos >= Ncurses.getmaxy(@scrollbar_win)
            @toggle_pos = Ncurses.getmaxy(@scrollbar_win) - 1
          end

          # Draw the scrollbar
          Ncurses.mvwvline(@scrollbar_win,
                           0,
                           0,
                           Ncurses::ACS_CKBOARD,
                           Ncurses.getmaxy(@scrollbar_win))

          Ncurses.mvwvline(@scrollbar_win,
                           @toggle_pos,
                           0,
                           ' '.ord | Ncurses::A_REVERSE,
                           @toggle_size)
        end
      end

      Draw.drawObjBox(@win, self) if box
      Ncurses.wrefresh @win
    end

    def get_current_top
      @current_top
    end

    def set_current_top(item)
      if item < 0
        item = 0
      elsif item > @max_top_item
        item = @max_top_item
      end
      @current_top = item

      self.set_position(item);
    end

    def draw_current
      # Rehighlight the current menu item.
      screen_pos = @item_pos[@current_item] - @left_char
      highlight = if self.has_focus
                  then @highlight
                  else Ncurses::A_NORMAL
                  end

      Draw.writeChtypeAttrib(@list_win,
                             if screen_pos >= 0 then screen_pos else 0 end,
                             @current_high, @item[@current_item], highlight, RNDK::HORIZONTAL,
                             if screen_pos >= 0 then 0 else 1 - screen_pos end,
                             @item_len[@current_item])
    end

    # Put the cursor on the currently-selected item's row.
    def fix_cursor_position
      scrollbar_adj = if @scrollbar_placement == LEFT then 1 else 0 end
      ypos = self.Screen_YPOS(@current_item - @current_top)
      xpos = self.Screen_XPOS(0) + scrollbar_adj

      Ncurses.wmove(@input_window, ypos, xpos)
      Ncurses.wrefresh(@input_window)
    end

  end
end
