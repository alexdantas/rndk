require 'rndk'

module RNDK

  # Allows user to select from a list of alphabetically sorted words.
  #
  # Use the arrow keys to navigate on the list or type in the
  # beginning of the word and it'll automagically adjust
  # itself in the correct place.
  #
  # ## Keybindings
  #
  # Since Alphalist is built from both the Scroll and Entry Widgets,
  # the key bindings are the same for the respective fields.
  #
  # Extra key bindings are listed below:
  #
  # Up Arrow::   Scrolls the scrolling list up one line.
  # Down Arrow:: Scrolls the scrolling list down one line.
  # Page Up::    Scrolls the scrolling list up one page.
  # CTRL-B::     Scrolls the scrolling list up one page.
  # Page Down::  Scrolls the scrolling list down one page.
  # CTRL-F::     Scrolls the scrolling list down one page.
  # Tab::        Tries to complete the word in the entry field.
  #              If the word segment is not unique then the widget
  #              will beep  and  present  a list of close matches.
  # Return::     Returns the word in the entry field.
  #              It  also  sets  the widget data exitType to `:NORMAL`.
  # Escape::     Exits the widget and returns `nil`.
  #              It  also sets the widget data exitType to `:ESCAPE_HIT`.
  #
  # ## Developer notes
  #
  # This widget, like the file selector widget, is a compound widget
  # of both the entry field widget and the scrolling list widget - sorted.
  #
  class Alphalist < Widget
    attr_reader :scroll_field, :entry_field, :list

    # Creates an Alphalist Widget.
    #
    # * `xplace` is the x position - can be an integer or `RNDK::LEFT`,
    #   `RNDK::RIGHT`, `RNDK::CENTER`.
    # * `yplace` is the y position - can be an integer or `RNDK::TOP`,
    #   `RNDK::BOTTOM`, `RNDK::CENTER`.
    # * `width`/`height` are integers - if either are 0, Widget
    #   will be created with full width/height of the screen.
    #   If it's a negative value, will create with full width/height
    #   minus the value.
    # * `message` is an Array of Strings with all the lines you'd want
    #   to show. RNDK markup applies (see RNDK#Markup).
    # * `title` can be more than one line - just split them
    #   with `\n`s.
    # * `label` is the String that will appear on the label
    #   of the Entry field.
    # * `list` is an Array of Strings with the content to
    #   display.
    # * `filler_char` is the character to display on the
    #   empty spaces in the Entry field.
    # * `highlight` is the attribute/color of the current
    #   item.
    # * `box` if the Widget is drawn with a box outside it.
    # * `shadow` turns on/off the shadow around the Widget.
    #
    def initialize(rndkscreen,
                   xplace,
                   yplace,
                   width,
                   height,
                   title,
                   label,
                   list,
                   filler_char,
                   highlight,
                   box,
                   shadow)
      super()

      parent_width  = Ncurses.getmaxx rndkscreen.window
      parent_height = Ncurses.getmaxy rndkscreen.window

      box_width  = width
      box_height = height

      label_len = 0

      bindings = {
        RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
        RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
      }

      if not self.createList list
        self.destroy
        return nil
      end

      self.set_box box

      # If the height is a negative value, the height will be ROWS-height,
      # otherwise the height will be the given height.
      box_height = RNDK.setWidgetDimension(parent_height, height, 0)

      # If the width is a negative value, the width will be COLS-width,
      # otherwise the width will be the given width.
      box_width = RNDK.setWidgetDimension(parent_width, width, 0)

      # Translate the label string to a chtype array
      if label.size > 0
        lentmp = []
        chtype_label = RNDK.char2Chtype(label, lentmp, [])
        label_len = lentmp[0]
      end

      # Rejustify the x and y positions if we need to.
      xtmp = [xplace]
      ytmp = [yplace]
      RNDK.alignxy(rndkscreen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make the file selector window.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)

      if @win.nil?
        self.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      @screen = rndkscreen
      @parent = rndkscreen.window
      @highlight   = highlight
      @filler_char = filler_char

      @box_width  = box_width
      @box_height = box_height

      @shadow = shadow
      @shadow_win = nil

      # Do we want a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width, ypos+1, xpos+1)
      end

      # Create the entry field.
      temp_width =  if Alphalist.isFullWidth(width)
                    then RNDK::FULL
                    else box_width - 2 - label_len
                    end

      @entry_field = RNDK::Entry.new(rndkscreen,
                                     Ncurses.getbegx(@win),
                                     Ncurses.getbegy(@win),
                                     title,
                                     label,
                                     Ncurses::A_NORMAL,
                                     filler_char,
                                     :MIXED,
                                     temp_width,
                                     0,
                                     512,
                                     box,
                                     false)
      if @entry_field.nil?
        self.destroy
        return nil
      end
      @entry_field.setLLchar Ncurses::ACS_LTEE
      @entry_field.setLRchar Ncurses::ACS_RTEE

      # Callback functions
      adjust_alphalist_cb = lambda do |object_type, object, alphalist, key|
        scrollp = alphalist.scroll_field
        entry   = alphalist.entry_field

        if scrollp.list_size > 0
          # Adjust the scrolling list.
          alphalist.injectMyScroller(key)

          # Set the value in the entry field.
          current = RNDK.chtype2Char scrollp.item[scrollp.current_item]
          entry.setValue current
          entry.draw entry.box
          return true
        end

        RNDK.beep
        false
      end

      complete_word_cb = lambda do |object_type, object, alphalist, key|
        entry = alphalist.entry_field
        scrollp = nil
        selected = -1
        ret = 0
        alt_words = []

        if entry.info.size == 0
          RNDK.beep
          return true
        end

        # Look for a unique word match.
        index = RNDK.searchList(alphalist.list, alphalist.list.size, entry.info)

        # if the index is less than zero, return we didn't find a match
        if index < 0
          RNDK.beep
          return true
        end

        # Did we find the last word in the list?
        if index == alphalist.list.size - 1
          entry.setValue alphalist.list[index]
          entry.draw entry.box
          return true
        end

        # Ok, we found a match, is the next item similar?
        len = [entry.info.size, alphalist.list[index + 1].size].min
        ret = alphalist.list[index + 1][0...len] <=> entry.info
        if ret == 0
          current_index = index
          match = 0
          selected = -1

          # Start looking for alternate words
          # FIXME(original): bsearch would be more suitable.
          while (current_index < alphalist.list.size) and
              ((alphalist.list[current_index][0...len] <=> entry.info) == 0)
            alt_words << alphalist.list[current_index]
            current_index += 1
          end

          # Determine the height of the scrolling list.
          height = if alt_words.size < 8 then alt_words.size + 3 else 11 end

          # Create a scrolling list of close matches.
          scrollp = RNDK::Scroll.new(entry.screen,
                                     RNDK::CENTER,
                                     RNDK::CENTER,
                                     RNDK::RIGHT,
                                     height,
                                     -30,
                                     "<C></B/5>Possible Matches.",
                                     alt_words,
                                     true,
                                     Ncurses::A_REVERSE,
                                     true,
                                     false)

          # Allow them to select a close match.
          match = scrollp.activate
          selected = scrollp.current_item

          # Check how they exited the list.
          if scrollp.exit_type == :ESCAPE_HIT
            # Destroy the scrolling list.
            scrollp.destroy

            RNDK.beep

            # Redraw the alphalist and return.
            alphalist.draw(alphalist.box)
            return true
          end

          # Destroy the scrolling list.
          scrollp.destroy

          # Set the entry field to the selected value.
          entry.set(alt_words[match], entry.min, entry.max, entry.box)

          # Move the highlight bar down to the selected value.
          (0...selected).each do |x|
            alphalist.injectMyScroller(Ncurses::KEY_DOWN)
          end

          # Redraw the alphalist.
          alphalist.draw alphalist.box

        else
          # Set the entry field with the found item.
          entry.set(alphalist.list[index], entry.min, entry.max, entry.box)
          entry.draw entry.box
        end
        true
      end

      pre_process_entry_field = lambda do |rndktype, object, alphalist, input|
        scrollp = alphalist.scroll_field
        entry = alphalist.entry_field
        info_len = entry.info.size
        result = 1
        empty = false

        if alphalist.isBind(:alphalist, input)
          result = 1  # Don't try to use this key in editing

        elsif (RNDK.is_char?(input) &&
            input.chr.match(/^[[:alnum:][:punct:]]$/)) ||
            [Ncurses::KEY_BACKSPACE, Ncurses::KEY_DC].include?(input)

          index = 0
          curr_pos = entry.screen_col + entry.left_char
          pattern = entry.info.clone

          if [Ncurses::KEY_BACKSPACE, Ncurses::KEY_DC].include? input

            curr_pos -= 1 if input == Ncurses::KEY_BACKSPACE

            pattern.slice!(curr_pos) if curr_pos >= 0

          else
            front   = (pattern[0...curr_pos] or '')
            back    = (pattern[curr_pos..-1] or '')
            pattern = front + input.chr + back
          end

          if pattern.size == 0
            empty = true

          elsif (index = RNDK.searchList(alphalist.list,
                                         alphalist.list.size,
                                         pattern)) >= 0

            # XXX: original uses n scroll downs/ups for <10 positions change
              scrollp.setPosition(index)
            alphalist.drawMyScroller

          else
            RNDK.beep
            result = 0
          end
        end

        if empty
          scrollp.setPosition(0)
          alphalist.drawMyScroller
        end

        result
      end

      # Set the key bindings for the entry field.
      @entry_field.bind(:entry, Ncurses::KEY_UP,    adjust_alphalist_cb, self)
      @entry_field.bind(:entry, Ncurses::KEY_DOWN,  adjust_alphalist_cb, self)
      @entry_field.bind(:entry, Ncurses::KEY_NPAGE, adjust_alphalist_cb, self)
      @entry_field.bind(:entry, Ncurses::KEY_PPAGE, adjust_alphalist_cb, self)
      @entry_field.bind(:entry, RNDK::KEY_TAB,      complete_word_cb,    self)

      # Set up the post-process function for the entry field.
      @entry_field.before_processing(pre_process_entry_field, self)

      # Create the scrolling list.  It overlaps the entry field by one line if
      # we are using box-borders.
      temp_height = Ncurses.getmaxy(@entry_field.win) - @border_size
      temp_width = if Alphalist.isFullWidth(width)
                   then RNDK::FULL
                   else box_width - 1
                   end

      @scroll_field = RNDK::Scroll.new(rndkscreen,
                                      Ncurses.getbegx(@win),
                                      Ncurses.getbegy(@entry_field.win) + temp_height,
                                      RNDK::RIGHT,
                                      box_height - temp_height,
                                      temp_width,
                                      '',
                                      list,
                                      false,
                                       Ncurses::A_REVERSE,
                                      box,
                                      false)

      @scroll_field.setULchar Ncurses::ACS_LTEE
      @scroll_field.setURchar Ncurses::ACS_RTEE

      # Setup the key bindings.
      bindings.each do |from, to|
        self.bind(:alphalist, from, :getc, to)
      end

      rndkscreen.register(:alphalist, self)
    end

    # @see Widget#erase
    def erase
      if self.valid_widget?
        @scroll_field.erase
        @entry_field.erase

        RNDK.window_erase(@shadow_win)
        RNDK.window_erase(@win)
      end
    end

    # @see Widget#move
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@win, @shadow_win]
      subwidgets = [@entry_field, @scroll_field]
      self.move_specific(xplace, yplace, relative, refresh_flag, windows, subwidgets)
    end

    # The alphalist's focus resides in the entry widget. But the scroll widget
    # will not draw items highlighted unless it has focus. Temporarily adjust
    # the focus of the scroll widget when drawing on it to get the right
    # highlighting.
    def saveFocus
      @save = @scroll_field.has_focus
      @scroll_field.has_focus = @entry_field.has_focus
    end

    def restoreFocus
      @scroll_field.has_focus = @save
    end

    def drawMyScroller
      self.saveFocus
      @scroll_field.draw(@scroll_field.box)
      self.restoreFocus
    end

    def injectMyScroller(key)
      self.saveFocus
      @scroll_field.inject(key)
      self.restoreFocus
    end

    # Draws the Widget on the Screen.
    #
    # If `box` is true, it is drawn with a box.
    def draw box
      Draw.drawShadow @shadow_win unless @shadow_win.nil?

      # Draw in the entry field.
      @entry_field.draw @entry_field.box

      # Draw in the scroll field.
      self.drawMyScroller
    end

    # Activates the Alphalist Widget, letting the user interact with it.
    #
    # `actions` is an Array of characters. If it's non-null,
    # will #inject each char on it into the Widget.
    #
    # See Alphalist for keybindings.
    #
    # @return The text currently inside the entry field (and
    #         `exit_type` will be `:NORMAL`) or `nil` (and
    #         `exit_type` will be `:ESCAPE_HIT`).
    def activate(actions=[])
      ret = 0

      # Draw the widget.
      self.draw(@box)

      # Activate the widget.
      ret = @entry_field.activate actions

      # Copy the exit type from the entry field.
      @exit_type = @entry_field.exit_type

      # Determine the exit status.
      if @exit_type != :EARLY_EXIT
        return ret
      end
      return 0
    end

    # Makes the Alphalist react to `char` just as if the user
    # had pressed it.
    #
    # Nice to simulate batch actions on a Widget.
    #
    # Besides normal keybindings (arrow keys and such), see
    # Widget#set_exit_type to see how the Widget exits.
    #
    def inject char
      ret = -1

      self.draw @box

      # Inject a character into the widget.
      ret = @entry_field.inject char

      # Copy the eixt type from the entry field.
      @exit_type = @entry_field.exit_type

      # Determine the exit status.
      ret = -1 if @exit_type == :EARLY_EXIT

      @result_data = ret
      ret
    end

    # Sets multiple attributes of the Widget.
    #
    # See Alphalist#initialize.
    def set(list, filler_char, highlight, box)
      self.set_contents   list
      self.set_filler_char filler_char
      self.set_highlight highlight
      self.set_box box
    end

    # This function sets the information inside the alphalist.
    def set_contents list
      return if not self.createList list

      # Set the information in the scrolling list.
      @scroll_field.set(@list, @list_size, false,
          @scroll_field.highlight, @scroll_field.box)

      # Clean out the entry field.
      self.set_current_item(0)
      @entry_field.clean

      # Redraw the widget.
      self.erase
      self.draw @box
    end

    # This returns the contents of the widget.
    def getContents size
      size << @list_size
      return @list
    end

    # Get/set the current position in the scroll widget.
    def get_current_item
      return @scroll_field.get_current_item
    end

    def set_current_item item
      if @list_size != 0
        @scroll_field.set_current_item item
        @entry_field.setValue @list[@scroll_field.get_current_item]
      end
    end

    # This sets the filler character of the entry field of the alphalist.
    def set_filler_char char
      @filler_char = char
      @entry_field.set_filler_char char
    end

    def get_filler_char
      return @filler_char
    end

    # This sets the highlgith bar attributes
    def set_highlight(highlight)
      @highlight = highlight
    end

    def getHighlight
      @highlight
    end

    # These functions set the drawing characters of the widget.
    def setMyULchar(character)
      @entry_field.setULchar(character)
    end

    def setMyURchar(character)
      @entry_field.setURchar(character)
    end

    def setMyLLchar(character)
      @scroll_field.setLLchar(character)
    end

    def setMyLRchar(character)
      @scroll_field.setLRchar(character)
    end

    def setMyVTchar(character)
      @entry_field.setVTchar(character)
      @scroll_field.setVTchar(character)
    end

    def setMyHZchar(character)
      @entry_field.setHZchar(character)
      @scroll_field.setHZchar(character)
    end

    def setMyBXattr(character)
      @entry_field.setBXattr(character)
      @scroll_field.setBXattr(character)
    end

    # This sets the background attribute of the widget.
    def set_bg_attrib(attrib)
      @entry_field.set_bg_attrib(attrib)
      @scroll_field.set_bg_attrib(attrib)
    end

    def destroyInfo
      @list = ''
      @list_size = 0
    end

    # This destroys the alpha list
    def destroy
      self.destroyInfo

      # Clean the key bindings.
      self.clean_bindings(:alphalist)

      @entry_field.destroy
      @scroll_field.destroy

      # Free up the window pointers.
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Unregister the object.
      RNDK::Screen.unregister(:alphalist, self)
    end

    # This function sets the pre-process function.
    def before_processing(callback, data)
      @entry_field.before_processing(callback, data)
    end

    # This function sets the post-process function.
    def after_processing(callback, data)
      @entry_field.after_processing(callback, data)
    end

    def createList list
      if list.size >= 0
        newlist = []

        # Copy in the new information.
        status = true
        (0...list.size).each do |x|
          newlist << list[x]
          if newlist[x] == 0
            status = false
            break
          end
        end
        if status
          self.destroyInfo
          @list_size = list.size
          @list = newlist
          @list.sort!
        end
      else
        self.destroyInfo
        status = true
      end
      status
    end

    def focus
      self.entry_field.focus
    end

    def unfocus
      self.entry_field.unfocus
    end

    def self.isFullWidth(width)
      width == RNDK::FULL || (Ncurses.COLS != 0 && width >= Ncurses.COLS)
    end

    def position
      super(@win)
    end

    def object_type
      :alphalist
    end
  end
end
