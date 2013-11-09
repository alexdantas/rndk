require_relative 'cdk_objs'

module CDK
  class MENU < CDK::CDKOBJS
    TITLELINES = 1
    MAX_MENU_ITEMS = 30
    MAX_SUB_ITEMS = 98

    attr_reader :current_title, :current_subtitle
    attr_reader :sublist

    def initialize(cdkscreen,
                   menu_list,
                   menu_items,
                   subsize,
                   menu_location,
                   menu_pos,
                   title_attr,
                   subtitle_attr)
      super()

      right_count = menu_items - 1
      rightloc = Ncurses.getmaxx cdkscreen.window
      leftloc = 0
      xpos = Ncurses.getbegx cdkscreen.window
      ypos = Ncurses.getbegy cdkscreen.window
      ymax = Ncurses.getmaxy cdkscreen.window

      # Start making a copy of the information.
      @screen = cdkscreen
      @box = false
      @accepts_focus = false
      rightcount = menu_items - 1
      @parent = cdkscreen.window
      @menu_items = menu_items
      @title_attr = title_attr
      @subtitle_attr = subtitle_attr
      @current_title = 0
      @current_subtitle = 0
      @last_selection = -1
      @menu_pos = menu_pos

      @pull_win = [nil] * menu_items
      @title_win = [nil] * menu_items
      @title = [''] * menu_items
      @title_len = [0] * menu_items
      @sublist = (1..menu_items).map {[nil] * subsize.max}.compact
      @sublist_len = (1..menu_items).map {
          [0] * subsize.max}.compact
      @subsize = [0] * menu_items


      # Create the pull down menus.
      (0...menu_items).each do |x|
        x1 = if menu_location[x] == CDK::LEFT
             then x
             else
               rightcount -= 1
               rightcount + 1
             end
        x2 = 0
        y1 = if menu_pos == CDK::BOTTOM then ymax - 1 else 0 end
        y2 = if menu_pos == CDK::BOTTOM
             then ymax - subsize[x] - 2
             else CDK::MENU::TITLELINES
             end
        high = subsize[x] + CDK::MENU::TITLELINES

        # Limit the menu height to fit on the screen.
        if high + y2 > ymax
          high = ymax - CDK::MENU::TITLELINES
        end

        max = -1
        (CDK::MENU::TITLELINES...subsize[x]).to_a.each do |y|
          y0 = y - CDK::MENU::TITLELINES
          sublist_len = []
          @sublist[x1][y0] = CDK.char2Chtype(menu_list[x][y],
              sublist_len, [])
          @sublist_len[x1][y0] = sublist_len[0]
          max = [max, sublist_len[0]].max
        end

        if menu_location[x] == CDK::LEFT
          x2 = leftloc
        else
          x2 = (rightloc -= max + 2)
        end

        title_len = []
        @title[x1] = CDK.char2Chtype(menu_list[x][0], title_len, [])
        @title_len[x1] = title_len[0]
        @subsize[x1] = subsize[x] - CDK::MENU::TITLELINES
        @title_win[x1] = Ncurses.subwin(cdkscreen.window, CDK::MENU::TITLELINES,
            @title_len[x1] + 2, ypos + y1, xpos + x2)
        @pull_win[x1] = Ncurses.subwin(cdkscreen.window, high, max + 2,
            ypos + y2, xpos + x2)
        if @title_win[x1].nil? || @pull_win[x1].nil?
          self.destroy
          return nil
        end

        leftloc += @title_len[x] + 1
        Ncurses.keypad(@title_win[x1], true)
        Ncurses.keypad(@pull_win[x1], true)
      end
      @input_window = @title_win[@current_title]

      # Register this baby.
      cdkscreen.register(:MENU, self)
    end

    # This activates the CDK Menu
    def activate(actions)
      ret = 0

      # Draw in the screen.
      @screen.refresh

      # Display the menu titles.
      self.draw(@box)

      # Highlight the current title and window.
      self.drawSubwin

      # If the input string is empty this is an interactive activate.
      if actions.nil? || actions.size == 0
        @input_window = @title_win[@current_title]

        # Start taking input from the keyboard.
        while true
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        actions.each do |action|
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      end

      # Set the exit type and return.
      self.setExitType(0)
      return -1
    end

    def drawTitle(item)
      Draw.writeChtype(@title_win[item], 0, 0, @title[item],
          CDK::HORIZONTAL, 0, @title_len[item])
    end

    def drawItem(item, offset)
      Draw.writeChtype(@pull_win[@current_title], 1,
          item + CDK::MENU::TITLELINES - offset,
          @sublist[@current_title][item],
          CDK::HORIZONTAL, 0, @sublist_len[@current_title][item])
    end

    # Highlight the current sub-menu item
    def selectItem(item, offset)
      Draw.writeChtypeAttrib(@pull_win[@current_title], 1,
          item + CDK::MENU::TITLELINES - offset,
          @sublist[@current_title][item], @subtitle_attr,
          CDK::HORIZONTAL, 0, @sublist_len[@current_title][item])
    end

    def withinSubmenu(step)
      next_item = CDK::MENU.wrapped(@current_subtitle + step,
          @subsize[@current_title])

      if next_item != @current_subtitle
        ymax = Ncurses.getmaxy(@screen.window)

        if 1 + @pull_win[@current_title].getbegy + @subsize[@current_title] >=
            ymax
          @current_subtitle = next_item
          self.drawSubwin
        else
          # Erase the old subtitle.
          self.drawItem(@current_subtitle, 0)

          # Set the values
          @current_subtitle = next_item

          # Draw the new sub-title.
          self.selectItem(@current_subtitle, 0)

          Ncurses.wrefresh @pull_win[@current_title]
        end

        @input_window = @title_win[@current_title]
      end
    end

    def acrossSubmenus(step)
      next_item = CDK::MENU.wrapped(@current_title + step, @menu_items)

      if next_item != @current_title
        # Erase the menu sub-window.
        self.eraseSubwin
        @screen.refresh

        # Set the values.
        @current_title = next_item
        @current_subtitle = 0

        # Draw the new menu sub-window.
        self.drawSubwin
        @input_window = @title_win[@current_title]
      end
    end

    # Inject a character into the menu widget.
    def inject(input)
      pp_return = 1
      ret = -1
      complete = false

      # Set the exit type.
      self.setExitType(0)

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        # Call the pre-process function.
        pp_return = @pre_process_func.call(:MENU, self,
            @pre_process_data, input)
      end

      # Should we continue?

      if pp_return != 0
        # Check for key bindings.
        if self.checkBind(:MENU, input)
          complete = true
        else
          case input
          when Ncurses::KEY_LEFT
            self.acrossSubmenus(-1)
          when Ncurses::KEY_RIGHT, CDK::KEY_TAB
            self.acrossSubmenus(1)
          when Ncurses::KEY_UP
            self.withinSubmenu(-1)
          when Ncurses::KEY_DOWN, ' '.ord
            self.withinSubmenu(1)
          when Ncurses::KEY_ENTER, CDK::KEY_RETURN
            self.cleanUpMenu
            self.setExitType(input)
            @last_selection = @current_title * 100 + @current_subtitle
            ret = @last_selection
            complete = true
          when CDK::KEY_ESC
            self.cleanUpMenu
            self.setExitType(input)
            @last_selection = -1
            ret = @last_selection
            complete = true
          when Ncurses::ERR
            self.setExitType(input)
            complete = true
          when CDK::REFRESH
            self.erase
            self.refresh
          end
        end

        # Should we call a post-process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(:MENU, self, @post_process_data, input)
        end
      end

      if !complete
        self.setExitType(0)
      end

      @result_data = ret
      return ret
    end

    # Draw a menu item subwindow
    def drawSubwin
      high = Ncurses.getmaxy(@pull_win[@current_title]) - 2
      x0 = 0
      x1 = @subsize[@current_title]

      if x1 > high
        x1 = high
      end

      if @current_subtitle >= x1
        x0 = @current_subtitle - x1 + 1
        x1 += x0
      end

      # Box the window
      @pull_win[@current_title]
      Ncurses.box(@pull_win[@current_title], Ncurses::ACS_VLINE, Ncurses::ACS_HLINE)
      if @menu_pos == CDK::BOTTOM
        Ncurses.mvwaddch(@pull_win[@current_title],
                         @subsize[@current_title] + 1,
                         0,
                         Ncurses::ACS_LTEE)
      else
        Ncurses.mvwaddch(@pull_win[@current_title],
                         0,
                         0,
                         Ncurses::ACS_LTEE)
      end

      # Draw the items.
      (x0...x1).each do |x|
        self.drawItem(x, x0)
      end

      self.selectItem(@current_subtitle, x0)
      Ncurses.wrefresh @pull_win[@current_title]

      # Highlight the title.
      Draw.writeChtypeAttrib(@title_win[@current_title], 0, 0,
          @title[@current_title], @title_attr, CDK::HORIZONTAL,
          0, @title_len[@current_title])
      Ncurses.wrefresh @title_win[@current_title]
    end

    # Erase a menu item subwindow
    def eraseSubwin
      CDK.eraseCursesWindow(@pull_win[@current_title])

      # Redraw the sub-menu title.
      self.drawTitle(@current_title)
      Ncurses.wrefresh @title_win[@current_title]
    end

    # Draw the menu.
    def draw(box)
      # Draw in the menu titles.
      (0...@menu_items).each do |x|
        self.drawTitle(x)
        Ncurses.wrefresh @title_win[x]
      end
    end

    # Move the menu to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@screen.window]
      (0...@menu_items).each do |x|
        windows << @title_win[x]
      end
      self.move_specific(xplace, yplace, relative, refresh_flag,
          windows, [])
    end

    # Set the background attribute of the widget.
    def setBKattr(attrib)
      (0...@menu_items).each do |x|
        @title_win[x].wbkgd(attrib)
        @pull_win[x].wbkgd(attrib)
      end
    end

    # Destroy a menu widget.
    def destroy
      # Clean up the windows
      (0...@menu_items).each do |x|
        CDK.deleteCursesWindow(@title_win[x])
        CDK.deleteCursesWindow(@pull_win[x])
      end

      # Clean the key bindings.
      self.cleanBindings(:MENU)

      # Unregister the object
      CDK::SCREEN.unregister(:MENU, self)
    end

    # Erase the menu widget from the screen.
    def erase
      if self.validCDKObject
        (0...@menu_items).each do |x|
          Ncurses.werase   @title_win[x]
          Ncurses.wrefresh @title_win[x]
          Ncurses.werase   @pull_win[x]
          Ncurses.wrefresh @pull_win[x]
        end
      end
    end

    def set(menu_item, submenu_item, title_highlight, subtitle_highlight)
      self.setCurrentItem(menu_item, submenu_item)
      self.setTitleHighlight(title_highlight)
      self.setSubTitleHighlight(subtitle_highlight)
    end

    # Set the current menu item to highlight.
    def setCurrentItem(menuitem, submenuitem)
      @current_title = CDK::MENU.wrapped(menuitem, @menu_items)
      @current_subtitle = CDK::MENU.wrapped(
          submenuitem, @subsize[@current_title])
    end

    def getCurrentItem(menu_item, submenu_item)
      menu_item << @current_title
      submenu_item << @current_subtitle
    end

    # Set the attribute of the menu titles.
    def setTitleHighlight(highlight)
      @title_attr = highlight
    end

    def getTitleHighlight
      return @title_attr
    end

    # Set the attribute of the sub-title.
    def setSubTitleHighlight(highlight)
      @subtitle_attr = highlight
    end

    def getSubTitleHighlight
      return @subtitle_attr
    end

    # Exit the menu.
    def cleanUpMenu
      # Erase the sub-menu.
      self.eraseSubwin
      Ncurses.wrefresh @pull_win[@current_title]

      # Refresh the screen.
      @screen.refresh
    end

    def focus
      self.drawSubwin
      @input_window = @title_win[@current_title]
    end

    # The "%" operator is simpler but does not handle negative values
    def self.wrapped(within, limit)
      if within < 0
        within = limit - 1
      elsif within >= limit
        within = 0
      end
      return within
    end

    def object_type
      :MENU
    end
  end
end
