require 'rndk'

module RNDK

  # TODO There's something wrong with this widget
  #      why wont it work with Traverse?
  class Viewer < Widget

    DOWN = 0
    UP   = 1

    def initialize(screen, config={})
      super()
      @widget_type = :viewer

      # This is UGLY AS HELL
      # But I don't have time to clean this up right now
      # (lots of widgets, you know)  :(
      x                = 0
      y                = 0
      width            = 0
      height           = 0
      title            = "viewer"
      buttons          = []
      button_highlight = Ncurses::A_REVERSE
      box              = true
      shadow           = false

      config.each do |key, val|
        x                = val if key == :x
        y                = val if key == :y
        width            = val if key == :width
        height           = val if key == :height
        title            = val if key == :title
        buttons          = val if key == :buttons
        button_highlight = val if key == :button_highlight
        box              = val if key == :box
        shadow           = val if key == :shadow
      end

      button_count  = buttons.size
      parent_width  = Ncurses.getmaxx screen.window
      parent_height = Ncurses.getmaxy screen.window

      box_width  = width
      box_height = height

      button_width = 0
      button_adj = 0
      button_pos = 1

      bindings = {
          RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
          'b'            => Ncurses::KEY_PPAGE,
          'B'            => Ncurses::KEY_PPAGE,
          RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
          ' '            => Ncurses::KEY_NPAGE,
          'f'            => Ncurses::KEY_NPAGE,
          'F'            => Ncurses::KEY_NPAGE,
          '|'            => Ncurses::KEY_HOME,
          '$'            => Ncurses::KEY_END,
      }

      self.set_box box

      box_width  = RNDK.set_widget_dimension(parent_width, width, 0)
      box_height = RNDK.set_widget_dimension(parent_height, height, 0)

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the viewer window.
      @win= Ncurses.newwin(box_height, box_width, ypos, xpos)
      if @win.nil?
        self.destroy
        return nil
      end

      # Turn the keypad on for the viewer.
      Ncurses.keypad(@win, true)

      # Create the buttons.
      @button_count = button_count
      @button = []
      @button_len = []
      @button_pos = []

      if button_count > 0
        (0...button_count).each do |x|
          button_len = []
          @button << RNDK.char2Chtype(buttons[x], button_len, [])
          @button_len << button_len[0]
          button_width += @button_len[x] + 1
        end
        button_adj = (box_width - button_width) / (button_count + 1)
        button_pos = 1 + button_adj
        (0...button_count).each do |x|
          @button_pos << button_pos
          button_pos += button_adj + @button_len[x]
        end
      end

      # Set the rest of the variables.
      @screen = screen
      @parent = screen.window
      @shadow_win = nil
      @button_highlight = button_highlight
      @box_height = box_height
      @box_width = box_width - 2
      @view_size = height - 2
      @input_window = @win
      @shadow = shadow
      @current_button = 0
      @current_top = 0
      @length = 0
      @left_char = 0
      @max_left_char = 0
      @max_top_line = 0
      @characters = 0
      @items_size = -1
      @show_line_items = 1
      @exit_type = :EARLY_EXIT

      self.set_title title

      # Do we need to create a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height,
                                     box_width + 1,
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

      screen.register(@widget_type, self)
    end

    # This function sets various attributes of the widget.
    def set(config)
      x                = 0
      y                = 0
      width            = 0
      height           = 0
      items            = []
      hide_control_chars = true
      show_line_items   = true
      title            = "viewer"
      buttons          = []
      button_highlight = Ncurses::A_REVERSE
      box              = true
      shadow           = false

      config.each do |key, val|
        x                = val if key == :x
        y                = val if key == :y
        width            = val if key == :width
        height           = val if key == :height
        title            = val if key == :title
        items            = val if key == :items
        hide_control_chars = val if key == :hide_control_chars
        show_line_items   = val if key == :show_line_items
        buttons          = val if key == :buttons
        button_highlight = val if key == :button_highlight
        box              = val if key == :box
        shadow           = val if key == :shadow
      end

      self.set_title(title)                  if title != "viewer"
      self.set_highlight(button_highlight)   if button_highlight != Ncurses::A_REVERSE
      self.set_items_line(show_line_items)
      self.set_box(box)                      if box
      self.set_items(items, hide_control_chars) if not items.empty?
    end

    # This sets the title of the viewer. (A nil title is allowed.
    # It just means that the viewer will not have a title when drawn.)
    def set_title title
      super(title, -(@box_width + 1))
      @title_adj = @title_lines

      # Need to set @view_size
      @view_size = @box_height - (@title_lines + 1) - 2
    end

    def get_title
      @title
    end

    def setup_line(interpret, items, x)
      # Did they ask for attribute interpretation?
      if interpret
        items_len = []
        items_pos = []
        @items[x] = RNDK.char2Chtype(items, items_len, items_pos)
        @items_len[x] = items_len[0]
        @items_pos[x] = RNDK.justifyString(@box_width, @items_len[x], items_pos[0])
      else
        # We must convert tabs and other nonprinting characters. The curses
        # library normally does this, but we are bypassing it by writing
        # chtypes directly.
        t = ''
        len = 0
        (0...items.size).each do |y|
          if items[y] == "\t".ord
            begin
              t  << ' '
              len += 1
            end while (len & 7) != 0
          elsif RNDK.CharOf(items[y].ord).match(/^[[:print:]]$/)
            t << RNDK.CharOf(items[y].ord)
            len += 1
          else
            t << Ncurses.unctrl(items[y].ord)
            len += 1
          end
        end
        @items[x] = t
        @items_len[x] = t.size
        @items_pos[x] = 0
      end
      @widest_line = [@widest_line, @items_len[x]].max
    end

    def free_line(x)
      @items[x] = '' if x < @items_size
    end

    # This function sets the contents of the viewer.
    def set_items(items, interpret)
      current_line = 0
      viewer_size = items.size

      if items.size < 0
        items.size = items.size
      end

      # Compute the size of the resulting display
      viewer_size = items.size
      if items.size > 0 && interpret
        (0...items.size).each do |x|
          filename = ''
          if RNDK.checkForLink(items[x], filename) == 1
            file_contents = []
            file_len = RNDK.read_file(filename, file_contents)

            if file_len >= 0
              viewer_size += (file_len - 1)
            end
          end
        end
      end

      # Clean out the old viewer items. (if there is any)
      @in_progress = true
      self.clean
      self.create_items(viewer_size)

      # Keep some semi-permanent items
      @interpret = interpret

      # Copy the itemsrmation given.
      current_line = 0
      x = 0
      while x < items.size && current_line < viewer_size
        if items[x].size == 0
          @items[current_line] = ''
          @items_len[current_line] = 0
          @items_pos[current_line] = 0
          current_line += 1
        else
          # Check if we have a file link in this line.
          filename = []
          if RNDK.checkForLink(items[x], filename) == 1
            # We have a link, open the file.
            file_contents = []
            file_len = 0

            # Open the file and put it into the viewer
            file_len = RNDK.read_file(filename, file_contents)
            if file_len == -1
              fopen_fmt = if Ncurses.has_colors?
                          then '<C></16>Link Failed: Could not open the file %s'
                          else '<C></K>Link Failed: Could not open the file %s'
                          end
              temp = fopen_fmt % filename
              self.setup_line(true, temp, current_line)
              current_line += 1
            else
              # For each line read, copy it into the viewer.
              file_len = [file_len, viewer_size - current_line].min
              (0...file_len).each do |file_line|
                if current_line >= viewer_size
                  break
                end
                self.setup_line(false, file_contents[file_line], current_line)
                @characters += @items_len[current_line]
                current_line += 1
              end
            end
          elsif current_line < viewer_size
            self.setup_line(@interpret, items[x], current_line)
            @characters += @items_len[current_line]
            current_line += 1
          end
        end
        x+= 1
      end

      # Determine how many characters we can shift to the right before
      # all the items have been viewer off the screen.
      if @widest_line > @box_width
        @max_left_char = (@widest_line - @box_width) + 1
      else
        @max_left_char = 0
      end

      # Set up the needed vars for the viewer items.
      @in_progress = false
      @items_size = viewer_size
      if @items_size <= @view_size
        @max_top_line = 0
      else
        @max_top_line = @items_size - 1
      end
      return @items_size
    end

    def get_items(size)
      size << @items_size
      @items
    end

    # This function sets the highlight type of the buttons.
    def set_highlight(button_highlight)
      @button_highlight = button_highlight
    end

    def get_highlight
      @button_highlight
    end

    # This sets whether or not you wnat to set the viewer
    # items line.
    def set_items_line(show_line_items)
      @show_line_items = show_line_items
    end

    def get_items_line
      @show_line_items
    end

    # This removes all the lines inside the scrolling window.
    def clean
      # Clean up the memory used...
      (0...@items_size).each do |x|
        self.free_line(x)
      end

      # Reset some variables.
      @items_size = 0
      @max_left_char = 0
      @widest_line = 0
      @current_top = 0
      @max_top_line = 0

      # Redraw the window.
      self.draw @box
    end

    def PatternNotFound(pattern)
      temp_items = [
          "</U/5>Pattern '%s' not found.<!U!5>" % pattern,
      ]
      self.pop_up_label(temp_items)
    end

    # This function actually controls the viewer...
    def activate(actions=[])
      refresh = false
      # Create the itemsrmation about the file stats.
      file_items = [
          '</5>      </U>File Statistics<!U>     <!5>',
          '</5>                          <!5>',
          '</5/R>Character Count:<!R> %-4d     <!5>' % @characters,
          '</5/R>Line Count     :<!R> %-4d     <!5>' % @items_size,
          '</5>                          <!5>',
          '<C></5>Press Any Key To Continue.<!5>'
      ]

      temp_items = ['<C></5>Press Any Key To Continue.<!5>']

      # Set the current button.
      @current_button = 0

      # Draw the widget items.
      self.draw(@box)

      # Do this until KEY_ENTER is hit.
      while true
        # Reset the refresh flag.
        refresh = false

        input = self.getch
        if !self.check_bind(input)
          case input
          when RNDK::KEY_TAB
            if @button_count > 1
              if @current_button == @button_count - 1
                @current_button = 0
              else
                @current_button += 1
              end

              # Redraw the buttons.
              self.draw_buttons
            end
          when RNDK::PREV
            if @button_count > 1
              if @current_button == 0
                @current_button = @button_count - 1
              else
                @current_button -= 1
              end

              # Redraw the buttons.
              self.draw_buttons
            end
          when Ncurses::KEY_UP
            if @current_top > 0
              @current_top -= 1
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_DOWN
            if @current_top < @max_top_line
              @current_top += 1
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_RIGHT
            if @left_char < @max_left_char
              @left_char += 1
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_LEFT
            if @left_char > 0
              @left_char -= 1
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_PPAGE
            if @current_top > 0
              if @current_top - (@view_size - 1) > 0
                @current_top = @current_top - (@view_size - 1)
              else
                @current_top = 0
              end
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_NPAGE
            if @current_top < @max_top_line
              if @current_top + @view_size < @max_top_line
                @current_top = @current_top + (@view_size - 1)
              else
                @current_top = @max_top_line
              end
              refresh = true
            else
              RNDK.beep
            end
          when Ncurses::KEY_HOME
            @left_char = 0
            refresh = true
          when Ncurses::KEY_END
            @left_char = @max_left_char
            refresh = true
          when 'g'.ord, '1'.ord, '<'.ord
            @current_top = 0
            refresh = true
          when 'G'.ord, '>'.ord
            @current_top = @max_top_line
            refresh = true
          when 'L'.ord
            x = (@items_size + @current_top) / 2
            if x < @max_top_line
              @current_top = x
              refresh = true
            else
              RNDK.beep
            end
          when 'l'.ord
            x = @current_top / 2
            if x >= 0
              @current_top = x
              refresh = true
            else
              RNDK.beep
            end
          when '?'.ord
            @search_direction = RNDK::Viewer::UP
            self.get_and_store_pattern(@screen)
            if !self.search_for_word(@search_pattern, @search_direction)
              self.PatternNotFound(@search_pattern)
            end
            refresh = true
          when '/'.ord
            @search_direction = RNDK::Viewer:DOWN
            self.get_and_store_pattern(@screen)
            if !self.search_for_word(@search_pattern, @search_direction)
              self.PatternNotFound(@search_pattern)
            end
            refresh = true
          when 'N'.ord, 'n'.ord
            if @search_pattern == ''
              temp_items[0] = '</5>There is no pattern in the buffer.<!5>'
              self.pop_up_label(temp_items)
            elsif !self.search_for_word(@search_pattern,
                if input == 'n'.ord
                then @search_direction
                else 1 - @search_direction
                end)
              self.PatternNotFound(@search_pattern)
            end
            refresh = true
          when ':'.ord
            @current_top = self.jump_to_line
            refresh = true
          when 'i'.ord, 's'.ord, 'S'.ord
            self.pop_up_label(file_items)
            refresh = true
          when RNDK::KEY_ESC
            self.set_exit_type(input)
            return -1
          when Ncurses::ERR
            self.set_exit_type(input)
            return -1
          when Ncurses::KEY_ENTER, RNDK::KEY_RETURN
            self.set_exit_type(input)
            return @current_button
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          else
            RNDK.beep
          end
        end

        # Do we need to redraw the screen?
        if refresh
          self.draw_items
        end
      end
    end

    # This searches the document looking for the given word.
    def get_and_store_pattern(screen)
      temp = ''

      # Check the direction.
      if @search_direction == RNDK::Viewer::UP
        temp = '</5>Search Up  : <!5>'
      else
        temp = '</5>Search Down: <!5>'
      end

      # Pop up the entry field.
      get_pattern = RNDK::Entry.new(screen, RNDK::CENTER, RNDK::CENTER,
          '', label, Ncurses.COLOR_PAIR(5) | Ncurses::A_BOLD,
          '.' | Ncurses.COLOR_PAIR(5) | Ncurses::A_BOLD,
          :MIXED, 10, 0, 256, true, false)

      # Is there an old search pattern?
      if @search_pattern.size != 0
        get_pattern.set(@search_pattern, get_pattern.min, get_pattern.max,
            get_pattern.box)
      end

      # Activate this baby.
      items = get_pattern.activate([])

      # Save teh items.
      if items.size != 0
        @search_pattern = items
      end

      # Clean up.
      get_pattern.destroy
    end

    # This searches for a line containing the word and realigns the value on
    # the screen.
    def search_for_word(pattern, direction)
      found = false

      # If the pattern is empty then return.
      if pattern.size != 0
        if direction == RNDK::Viewer::DOWN
          # Start looking from 'here' down.
          x = @current_top + 1
          while !found && x < @items_size
            pos = 0
            y = 0
            while y < @items[x].size
              plain_char = RNDK.CharOf(@items[x][y])

              pos += 1
              if @RNDK.CharOf(pattern[pos-1]) != plain_char
                y -= (pos - 1)
                pos = 0
              elsif pos == pattern.size
                @current_top = [x, @max_top_line].min
                @left_char = if y < @box_width then 0 else @max_left_char end
                found = true
                break
              end
              y += 1
            end
            x += 1
          end
        else
          # Start looking from 'here' up.
          x = @current_top - 1
          while ! found && x >= 0
            y = 0
            pos = 0
            while y < @items[x].size
              plain_char = RNDK.CharOf(@items[x][y])

              pos += 1
              if RNDK.CharOf(pattern[pos-1]) != plain_char
                y -= (pos - 1)
                pos = 0
              elsif pos == pattern.size
                @current_top = x
                @left_char = if y < @box_width then 0 else @max_left_char end
                found = true
                break
              end
            end
          end
        end
      end
      found
    end

    # This allows us to 'jump' to a given line in the file.
    def jump_to_line
      newline = RNDK::Scale.new(@screen, RNDK::CENTER, RNDK::CENTER,
          '<C>Jump To Line', '</5>Line :', Ncurses::A_BOLD,
          @items_size.size + 1, @current_top + 1, 0, @max_top_line + 1,
          1, 10, true, true)
      line = newline.activate([])
      newline.destroy
      line - 1
    end

    # This pops a little message up on the screen.
    def pop_up_label(mesg)
      # Set up variables.
      label = RNDK::Label.new(@screen, RNDK::CENTER, RNDK::CENTER,
          mesg, mesg.size, true, false)

      # Draw the label and wait.
      label.draw(true)
      label.getch

      # Clean up.
      label.destroy
    end

    # This moves the viewer field to the given location.
    # Inherited
    # def move(x, y, relative, refresh_flag)
    # end

    # This function draws the viewer widget.
    def draw box
      # Do we need to draw in the shadow?
      unless @shadow_win.nil?
        Draw.drawShadow @shadow_win
      end

      # Box it if it was asked for.
      if box
        Draw.drawObjBox(@win, self)
        Ncurses.wrefresh @win
      end

      # Draw the items in the viewer.
      self.draw_items
    end

    # This redraws the viewer buttons.
    def draw_buttons
      # No buttons, no drawing
      return if @button_count == 0

      # Redraw the buttons.
      (0...@button_count).each do |x|
        Draw.writeChtype(@win,
                         @button_pos[x],
                         @box_height - 2,
                         @button[x],
                         RNDK::HORIZONTAL,
                         0,
                         @button_len[x])
      end

      # Highlight the current button.
      (0...@button_len[@current_button]).each do |x|
        # Strip the character of any extra attributes.
        character = RNDK.CharOf(@button[@current_button][x])

        # Add the character into the window.
        Ncurses.mvwaddch(@win,
                         @box_height - 2,
                         @button_pos[@current_button] + x,
                         character.ord | @button_highlight)
      end

      # Refresh the window.
      Ncurses.wrefresh @win
    end

    # This sets the background attribute of the widget.
    def set_bg_color(attrib)
      Ncurses.wbkgd(@win, attrib)
    end

    def destroy_items
      @items = []
      @items_pos = []
      @items_len = []
    end

    # This function destroys the viewer widget.
    def destroy
      self.destroy_items
      self.clean_title

      # Clean up the windows.
      RNDK.window_delete @shadow_win
      RNDK.window_delete @win

      # Clean the key bindings.
      self.clean_bindings

      # Unregister this widget.
      @screen.unregister self
    end

    # This function erases the viewer widget from the screen.
    def erase
      if self.valid?
        RNDK.window_erase(@win)
        RNDK.window_erase(@shadow_win)
      end
    end

    # This draws the viewer items lines.
    def draw_items
      temp = ''
      line_adjust = false

      # Clear the window.
      Ncurses.werase(@win)

      self.draw_title @win

      # Draw in the current line at the top.
      if @show_line_items == true
        # Set up the items line and draw it.
        if @in_progress
          temp = 'processing...'
        elsif @items_size != 0
          temp = '%d/%d %2.0f%%' % [@current_top + 1, @items_size,
              ((1.0 * @current_top + 1) / (@items_size)) * 100]
        else
          temp = '%d/%d %2.0f%%' % [0, 0, 0.0]
        end

        # The items_adjust variable tells us if we have to shift down one line
        # because the person asked for the line X of Y line at the top of the
        # screen. We only want to set this to true if they asked for the items
        # line and there is no title or if the two items overlap.
        if @title_lines == '' || @title_pos[0] < temp.size + 2
          items_adjust = true
        end
        Draw.writeChar(@win,
                       1,
                       if items_adjust then @title_lines else 0 end + 1,
                       temp,
                       RNDK::HORIZONTAL,
                       0,
                       temp.size)
      end

      # Determine the last line to draw.
      last_line = [@items_size, @view_size].min
      last_line -= if items_adjust then 1 else 0 end

      # Redraw the items.
      (0...last_line).each do |x|
        if @current_top + x < @items_size
          screen_pos = @items_pos[@current_top + x] + 1 - @left_char

          Draw.writeChtype(@win,
                           if screen_pos >= 0 then screen_pos else 1 end,
                           x + @title_lines + if items_adjust then 1 else 0 end + 1,
                           @items[x + @current_top],
                           RNDK::HORIZONTAL,
                           if screen_pos >= 0
                           then 0
                           else @left_char - @items_pos[@current_top + x]
                           end,
                           @items_len[x + @current_top])
        end
      end

      # Box it if we have to.
      if @box
        Draw.drawObjBox(@win, self)
        Ncurses.wrefresh @win
      end

      # Draw the separation line.
      if @button_count > 0
        boxattr = @BXAttr

        (1..@box_width).each do |x|
          Ncurses.mvwaddch(@win, @box_height - 3, x, @HZChar | boxattr)
        end

        Ncurses.mvwaddch(@win, @box_height - 3, 0, Ncurses::ACS_LTEE | boxattr)
        Ncurses.mvwaddch(@win, @box_height - 3, Ncurses.getmaxx(@win) - 1, Ncurses::ACS_RTEE | boxattr)
      end

      # Draw the buttons. This will call refresh on the viewer win.
      self.draw_buttons
    end

    # The items_size may be negative, to assign no definite limit.
    def create_items(items_size)
      status = false

      self.destroy_items

      if items_size >= 0
        status = true

        @items = []
        @items_pos = []
        @items_len = []
      end
      return status
    end

    def position
      super(@win)
    end

  end
end

