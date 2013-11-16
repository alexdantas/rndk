require 'rndk'

module RNDK

  class Fselect < Widget

    attr_reader :scroll_field, :entry_field
    attr_reader :dir_colorute, :file_colorute, :link_colorute, :highlight
    attr_reader :sock_colorute, :field_colorute, :filler_character
    attr_reader :dir_contents, :file_counter, :pwd, :pathname

    def initialize(screen, config={})
      super()
      @widget_type = :fselect

      x               = 0
      y               = 0
      width           = 0
      height          = 0
      title           = "fselect"
      label           = "label"
      field_colorute = Ncurses::A_NORMAL
      filler_char     = '_'
      highlight       = Ncurses::A_REVERSE
      d_colorute     = "</5>"
      f_colorute     = "</48>"
      l_colorute     = "</N>"
      s_colorute     = "</N>"
      box             = true
      shadow          = false

      config.each do |key, val|
        x               = val if key == :x
        y               = val if key == :y
        width           = val if key == :width
        height          = val if key == :height
        title           = val if key == :title
        label           = val if key == :label
        field_colorute = val if key == :field_colorute
        filler_char     = val if key == :filler_char
        highlight       = val if key == :highlight
        d_colorute     = val if key == :d_colorute
        f_colorute     = val if key == :f_colorute
        l_colorute     = val if key == :l_colorute
        s_colorute     = val if key == :s_colorute
        box             = val if key == :box
        shadow          = val if key == :shadow
      end

      parent_width  = Ncurses.getmaxx(screen.window)
      parent_height = Ncurses.getmaxy(screen.window)

      bindings = {
          RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
          RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
      }

      self.set_box box

      # If the height is a negative value the height will be ROWS-height,
      # otherwise the height will be the given height
      box_height = RNDK.set_widget_dimension(parent_height, height, 0)

      # If the width is a negative value, the width will be COLS-width,
      # otherwise the width will be the given width.
      box_width = RNDK.set_widget_dimension(parent_width, width, 0)

      # Rejustify the x and y positions if we need to.
      xtmp = [x]
      ytmp = [y]
      RNDK.alignxy(screen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Make sure the box isn't too small.
      box_width = [box_width, 15].max
      box_height = [box_height, 6].max

      # Make the file selector window.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)

      # is the window nil?
      if @win.nil?
        fselect.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      # Set some variables.
      @screen = screen
      @parent = screen.window
      @dir_colorute = d_colorute.clone
      @file_colorute = f_colorute.clone
      @link_colorute = l_colorute.clone
      @sock_colorute = s_colorute.clone
      @highlight = highlight
      @filler_character = filler_char
      @field_colorute = field_colorute
      @box_height = box_height
      @box_width = box_width
      @file_counter = 0
      @pwd = ''
      @input_window = @win
      @shadow = shadow
      @shadow_win = nil

      # Get the present working directory.
      # XXX need error handling (set to '.' on error)
      @pwd = Dir.getwd

      # Get the contents of the current directory
      self.setDirContents

      # Create the entry field in the selector
      label_len = []
      RNDK.char2Chtype(label, label_len, [])
      label_len = label_len[0]

      temp_width = if RNDK::Fselect.isFullWidth(width)
                   then RNDK::FULL
                   else box_width - 2 - label_len
                   end
      @entry_field = RNDK::Entry.new(screen, Ncurses.getbegx(@win), Ncurses.getbegy(@win),
          title, label, field_colorute, filler_char, :MIXED, temp_width,
          0, 512, box, false)

      # Make sure the widget was created.
      if @entry_field.nil?
        self.destroy
        return nil
      end

      # Set the lower left/right characters of the entry field.
      @entry_field.setLLchar(Ncurses::ACS_LTEE)
      @entry_field.setLRchar(Ncurses::ACS_RTEE)

      # This is a callback to the scrolling list which displays information
      # about the current file.  (and the whole directory as well)
      display_file_info_cb = lambda do |widget_type, entry, fselect, key|
        # Get the file name.
        filename = fselect.entry_field.info

        # Get specific information about the files.
        # lstat (filename, &fileStat);
        file_stat = File.stat(filename)

        # Determine the file type
        filetype = case
                   when file_stat.symlink?
                     'Symbolic Link'
                   when file_stat.socket?
                     'Socket'
                   when file_stat.file?
                     'Regular File'
                   when file_stat.directory?
                     'Directory'
                   when file_stat.chardev?
                     'Character Device'
                   when file_stat.blockdev?
                     'Block Device'
                   when file_stat.ftype == 'fif'
                     'FIFO Device'
                   else
                     'Unknown'
                   end

        # Get the user name and group name.
        pw_ent = Etc.getpwuid(file_stat.uid)
        gr_ent = Etc.getgrgid(file_stat.gid)

        # Convert the mode to both string and int
        # intMode = mode2Char (stringMode, fileStat.st_mode);

        # Create the message.
        mesg = [
            'Directory  : </U>%s' % [fselect.pwd],
            'Filename   : </U>%s' % [filename],
            'Owner      : </U>%s<!U> (%d)' % [pw_ent.name, file_stat.uid],
            'Group      : </U>%s<!U> (%d)' % [gr_ent.name, file_stat.gid],
            'Permissions: </U>%s<!U> (%o)' % [string_mode, int_mode],
            'Size       : </U>%ld<!U> bytes' % [file_stat.size],
            'Last Access: </U>%s' % [file_stat.atime],
            'Last Change: </U>%s' % [file_stat.ctime],
            'File Type  : </U>%s' % [filetype]
        ]

        # Create the pop up label.
        info_label = RNDK::Label.new(entry.screen, RNDK::CENTER, RNDK::CENTER,
            mesg, 9, true, false)
        info_label.draw(true)
        info_label.getch

        info_label.destroy

        # Redraw the file selector.
        fselect.draw(fselect.box)
        return true
      end

      # This tries to complete the filename
      complete_filename_cb = lambda do |widget_type, widget, fselect, key|
        scrollp = fselect.scroll_field
        entry = fselect.entry_field
        filename = entry.info.clone
        mydirname = RNDK.dirName(filename)
        current_index = 0

        # Make sure the filename is not nil/empty.
        if filename.nil? || filename.size == 0
          RNDK.beep
          return true
        end

        # Try to expand the filename if it starts with a ~
        unless (new_filename = RNDK::Fselect.expandTilde(filename)).nil?
          filename = new_filename
          entry.set_text(filename)
          entry.draw(entry.box)
        end

        # Make sure we can change into the directory.
        is_directory = Dir.exists?(filename)
        # if (chdir (fselect->pwd) != 0)
        #    return FALSE;
        #Dir.chdir(fselect.pwd)

        # XXX original: isDirectory ? mydirname : filename
        fselect.set(if is_directory then filename else mydirname end,
            fselect.field_colorute, fselect.filler_character,
            fselect.highlight, fselect.dir_colorute, fselect.file_colorute,
            fselect.link_colorute, fselect.sock_colorute, fselect.box)

        # If we can, change into the directory.
        # XXX original: if isDirectory (with 0 as success result)
        if is_directory
          entry.set_text(filename)
          entry.draw(entry.box)
        end

        # Create the file list.
        list = []
        (0...fselect.file_counter).each do |x|
          list << fselect.contentToPath(fselect.dir_contents[x])
        end

        # Look for a unique filename match.
        index = RNDK.searchList(list, fselect.file_counter, filename)

        # If the index is less than zero, return we didn't find a match.
        if index < 0
          RNDK.beep
        else
          # Move to the current item in the scrolling list.
          # difference = Index - scrollp->currentItem;
          # absoluteDifference = abs (difference);
          # if (difference < 0)
          # {
          #    for (x = 0; x < absoluteDifference; x++)
          #    {
          #       injectMyScroller (fselect, KEY_UP);
          #    }
          # }
          # else if (difference > 0)
          # {
          #    for (x = 0; x < absoluteDifferene; x++)
          #    {
          #       injectMyScroller (fselect, KEY_DOWN);
          #    }
          # }
          scrollp.setPosition(index)
          fselect.drawMyScroller

          # Ok, we found a match, is the next item similar?
          if index + 1 < fselect.file_counter && index + 1 < list.size &&
              list[index + 1][0..([filename.size, list[index + 1].size].min)] ==
              filename
            current_index = index
            base_chars = filename.size
            matches = 0

            # Determine the number of files which match.
            while current_index < fselect.file_counter
              if current_index + 1 < list.size
                if list[current_index][0..(
                    [filename.size, list[current_index].size].max)] == filename
                  matches += 1
                end
              end
              current_index += 1
            end

            # Start looking for the common base characters.
            while true
              secondary_matches = 0
              (index...index + matches).each do |x|
                if list[index][base_chars] == list[x][base_chars]
                  secondary_matches += 1
                end
              end

              if secondary_matches != matches
                RNDK.beep
                break
              end

              # Inject the character into the entry field.
              fselect.entry_field.inject(list[index][base_chars])
              base_chars += 1
            end
          else
            # Set the entry field with the found item.
            entry.set_text(list[index])
            entry.draw(entry.box)
          end
        end

        return true
      end

      # This allows the user to delete a file.
      delete_file_cb = lambda do |widget_type, fscroll, fselect|
        buttons = ['No', 'Yes']

        # Get the filename which is to be deleted.
        filename = RNDK.chtype2Char(fscroll.item[fscroll.current_item])
        filename = filename[0...-1]

        # Create the dialog message.
        mesg = [
            '<C>Are you sure you want to delete the file:',
            '<C></U>"%s"?' % [filename]
        ]

        # Create the dialog box.
        question = RNDK::Dialog.new(fselect.screen, RNDK::CENTER, RNDK::CENTER,
            mesg, 2, buttons, 2, Ncurses::A_REVERSE, true, true, false)

        # If the said yes then try to nuke it.
        if question.activate([]) == 1
          # If we were successful, reload the scrolling list.
          if File.unlink(filename) == 0
            # Set the file selector information.
            fselect.set(fselect.pwd, fselect.field_colorute,
                fselect.filler_character, fselect.highlight,
                fselect.dir_colorute, fselect.file_colorute,
                fselect.link_colorute, fselect.sock_colorute, fselect.box)
          else
            # Pop up a message.
            # mesg[0] = copyChar (errorMessage ("<C>Cannot delete file: %s"));
            # mesg[1] = copyChar (" ");
            # mesg[2] = copyChar("<C>Press any key to continue.");
            # popup_label(ScreenOf (fselect), (RNDK_CSTRING2) mesg, 3);
            # freeCharList (mesg, 3);
          end
        end

        # Clean up.
        question.destroy

        # Redraw the file seoector.
        fselect.draw(fselect.box)
      end

      # Start of callback functions.
      adjust_scroll_cb = lambda do |widget_type, widget, fselect, key|
        scrollp = fselect.scroll_field
        entry = fselect.entry_field

        if scrollp.list_size > 0
          # Move the scrolling list.
          fselect.injectMyScroller(key)

          # Get the currently highlighted filename.
          current = RNDK.chtype2Char(scrollp.item[scrollp.current_item])
          #current = RNDK.chtype2String(scrollp.item[scrollp.current_item])
          current = current[0...-1]

          temp = RNDK::Fselect.make_pathname(fselect.pwd, current)

          # Set the value in the entry field.
          entry.set_text(temp)
          entry.draw(entry.box)

          return true
        end
        RNDK.beep
        return false
      end

      # Define the callbacks for the entry field.
      @entry_field.bind(Ncurses::KEY_UP, adjust_scroll_cb, self)
      @entry_field.bind(Ncurses::KEY_PPAGE, adjust_scroll_cb, self)
      @entry_field.bind(Ncurses::KEY_DOWN, adjust_scroll_cb, self)
      @entry_field.bind(Ncurses::KEY_NPAGE, adjust_scroll_cb, self)
      @entry_field.bind(RNDK::KEY_TAB, complete_filename_cb, self)
      @entry_field.bind(RNDK.CTRL('^'), display_file_info_cb, self)

      # Put the current working directory in the entry field.
      @entry_field.set_text(@pwd)

      # Create the scrolling list in the selector.
      temp_height = Ncurses.getmaxy(@entry_field.win) - @border_size
      temp_width = if RNDK::Fselect.isFullWidth(width)
                   then RNDK::FULL
                   else box_width - 1
                   end
      @scroll_field = RNDK::Scroll.new(screen,
                                       Ncurses.getbegx(@win),
                                       Ncurses.getbegy(@win) + temp_height,
                                       RNDK::RIGHT,
                                       temp_width,
                                       box_height - temp_height,
                                       '',
                                       @dir_contents,
                                       false,
                                       @highlight,
                                       box,
                                       false)

      # Set the lower left/right characters of the entry field.
      @scroll_field.setULchar Ncurses::ACS_LTEE
      @scroll_field.setURchar Ncurses::ACS_RTEE

      # Do we want a shadow?
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Setup the key bindings
      bindings.each do |from, to|
        self.bind(from, :getc, to)
      end

      screen.register(@widget_type, self)
    end

    # This erases the file selector from the screen.
    def erase
      if self.valid?
        @scroll_field.erase
        @entry_field.erase
        RNDK.window_erase(@win)
      end
    end

    # This moves the fselect field to the given location.
    def move(x, y, relative, refresh_flag)
      windows = [@win, @shadow_win]
      subwidgets = [@entry_field, @scroll_field]

      self.move_specific(x, y, relative, refresh_flag,
          windows, subwidgets)
    end

    # The fselect's focus resides in the entry widget. But the scroll widget
    # will not draw items highlighted unless it has focus.  Temporarily adjust
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

    # This draws the file selector widget.
    def draw(box)
      # Draw in the shadow if we need to.
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Draw in the entry field.
      @entry_field.draw(@entry_field.box)

      # Draw in the scroll field.
      self.drawMyScroller
    end

    # This means you want to use the given file selector. It takes input
    # from the keyboard and when it's done it fills the entry info element
    # of the structure with what was typed.
    def activate(actions=[])
      input = 0
      ret = 0

      # Draw the widget.
      self.draw

      if actions.nil? || actions.size == 0
        while true
          input = @entry_field.getch

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
      return 0
    end

    # This injects a single character into the file selector.
    def inject(input)
      ret = false
      complete = false

      # Let the user play.
      filename = @entry_field.inject(input)

      # Copy the entry field exit_type to the file selector.
      @exit_type = @entry_field.exit_type

      # If we exited early, make sure we don't interpret it as a file.
      if @exit_type == :EARLY_EXIT
        return 0
      end

      # Can we change into the directory
      #file = Dir.chdir(filename)
      #if Dir.chdir(@pwd) != 0
      #  return 0
      #end

      # If it's not a directory, return the filename.
      if !Dir.exists?(filename)
        # It's a regular file, create the full path
        @pathname = filename.clone

        # Return the complete pathname.
        ret = @pathname
        complete = true
      else
        # Set the file selector information.
        self.set(filename, @field_colorute, @filler_character, @highlight,
            @dir_colorute, @file_colorute, @link_colorute, @sock_colorute,
            @box)

        # Redraw the scrolling list.
        self.drawMyScroller
      end

      if !complete
        self.set_exit_type(0)
      end

      @result_data = ret
      return ret
    end

    # This function sets the information inside the file selector.
    def set(directory, field_color, filler, highlight, dir_colorute,
        file_colorute, link_colorute, sock_colorute, box)
      fscroll = @scroll_field
      fentry = @entry_field
      new_directory = ''

      # keep the info sent to us.
      @field_colorute = field_color
      @filler_character = filler
      @highlight = highlight

      # Set the attributes of the entry field/scrolling list.
      self.set_filler_char(filler)
      self.set_highlight(highlight)

      # Only do the directory stuff if the directory is not nil.
      if !(directory.nil?) && directory.size > 0
        # Try to expand the directory if it starts with a ~
        if (temp_dir = RNDK::Fselect.expandTilde(directory)).size > 0
          new_directory = temp_dir
        else
          new_directory = directory.clone
        end

        # Change directories.
        if Dir.chdir(new_directory) != 0
          RNDK.beep

          # Could not get into the directory, pop up a little message.
          mesg = [
              '<C>Could not change into %s' % [new_directory],
              '<C></U>%s' % ['Unknown reason.'],  # errorMessage(format)
              ' ',
              '<C>Press Any Key To Continue.'
          ]

          # Pop up a message.
          @screen.popup_label(mesg, 4)

          # Get out of here.
          self.erase
          self.draw
          return
        end
      end

      # if the information coming in is the same as the information
      # that is already there, there is no need to destroy it.
      if @pwd != directory
        @pwd = Dir.getwd
      end

      @file_colorute = file_colorute.clone
      @dir_colorute = dir_colorute.clone
      @link_colorute = link_colorute.clone
      @sock_colorute = sock_colorute.clone

      # Set the contents of the entry field.
      fentry.set_text(@pwd)
      fentry.draw(fentry.box)

      # Get the directory contents.
      unless self.setDirContents
        RNDK.beep
        return
      end

      # Set the values in the scrolling list.
      fscroll.set_items(@dir_contents, false)
    end

    # This creates a list of the files in the current directory.
    def setDirContents
      dir_list = []

      # Get the directory contents
      dir_list = RNDK.get_directory_contents @pwd

      return false if dir_list.size <= 0

      @dir_contents = dir_list
      @file_counter = dir_list.size

      # Set the properties of the files.
      (0...@file_counter).each do |x|
        attr = ''
        mode = '?'

        # FIXME(original): access() would give a more correct answer
        # TODO: add error handling
        file_stat = File.stat(dir_list[x])
        if file_stat.executable?
          mode = '*'
        else
          mode = ' '
        end

        case
        when file_stat.symlink?
          attr = @link_colorute
          mode = '@'
        when file_stat.socket?
          attr = @sock_colorute
          mode = '&'
        when file_stat.file?
          attr = @file_colorute
        when file_stat.directory?
          attr = @dir_colorute
          mode = '/'
        end
        @dir_contents[x] = '%s%s%s' % [attr, dir_list[x], mode]
      end
      return true
    end

    def getDirContents(count)
      count << @file_counter
      return @dir_contents
    end

    # This sets the current directory of the file selector.
    def setDirectory(directory)
      fentry = @entry_field
      fscroll = @scroll_field
      result = 1

      # If the directory supplied is the same as what is already there, return.
      if @pwd != directory
        # Try to chdir into the given directory.
        if Dir.chdir(directory) != 0
          result = 0
        else
          @pwd = Dir.getwd

          # Set the contents of the entry field.
          fentry.set_text(@pwd)
          fentry.draw(fentry.box)

          # Get the directory contents.
          if self.setDirContents
            # Set the values in the scrolling list.
            fscroll.set_items(@dir_contents, @file_counter, false)
          else
            result = 0
          end
        end
      end
      return result
    end

    def getDirectory
      return @pwd
    end

    # This sets the filler character of the entry field.
    def set_filler_char(filler)
      @filler_character = filler
      @entry_field.set_filler_char(filler)
    end

    def getFillerChar
      return @filler_character
    end

    # This sets the highlight bar of the scrolling list.
    def set_highlight(highlight)
      @highlight = highlight
      @scroll_field.set_highlight(highlight)
    end

    def getHighlight
      return @highlight
    end

    # This sets the attribute of the directory attribute in the
    # scrolling list.
    def setDirAttribute(attribute)
      # Make sure they are not the same.
      if @dir_colorute != attribute
        @dir_colorute = attribute
        self.setDirContents
      end
    end

    def getDirAttribute
      return @dir_colorute
    end

    # This sets the attribute of the link attribute in the scrolling list.
    def setLinkAttribute(attribute)
      # Make sure they are not the same.
      if @link_colorute != attribute
        @link_colorute = attribute
        self.setDirContents
      end
    end

    def getLinkAttribute
      return @link_colorute
    end

    # This sets the attribute of the socket attribute in the scrolling list.
    def setSocketAttribute(attribute)
      # Make sure they are not the same.
      if @sock_colorute != attribute
        @sock_colorute = attribute
        self.setDirContents
      end
    end

    def getSocketAttribute
      return @sock_colorute
    end

    # This sets the attribute of the file attribute in the scrolling list.
    def setFileAttribute(attribute)
      # Make sure they are not the same.
      if @file_colorute != attribute
        @file_colorute = attribute
        self.setDirContents
      end
    end

    def getFileAttribute
      return @file_colorute
    end

    # this sets the contents of the widget
    def setContents(list, list_size)
      scrollp = @scroll_field
      entry = @entry_field

      if !self.createList(list, list_size)
        return
      end

      # Set the information in the scrolling list.
      scrollp.set(@dir_contents, @file_counter, false, scrollp.highlight,
          scrollp.box)

      # Clean out the entry field.
      self.setCurrentItem(0)
      entry.clean

      # Redraw the widget.
      self.erase
      self.draw
    end

    def getContents(size)
      size << @file_counter
      return @dir_contents
    end

    # Get/set the current position in the scroll wiget.
    def getCurrentItem
      return @scroll_field.getCurrent
    end

    def setCurrentItem(item)
      if @file_counter != 0
        @scroll_field.setCurrent(item)

        data = self.contentToPath(@dir_contents[@scroll_field.getCurrentItem])
        @entry_field.set_text(data)
      end
    end

    # These functions set the draw characters of the widget.
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
    def set_bg_color(attrib)
      @entry_field.set_bg_color(attrib)
      @scroll_field.set_bg_color(attrib)
    end

    # This destroys the file selector.
    def destroy
      self.clean_bindings

      # Destroy the other RNDK widgets
      @scroll_field.destroy
      @entry_field.destroy

      # Free up the windows
      RNDK.window_delete(@shadow_win)
      RNDK.window_delete(@win)

      # Clean the key bindings.
      # Unregister the widget.
      @screen.unregister self
    end

    # Currently a wrapper for File.expand_path
    def self.make_pathname(directory, filename)
      if filename == '..'
        return File.expand_path(directory) + '/..'
      else
        return File.expand_path(filename, directory)
      end
    end

    # Return the plain string that corresponds to an item in dir_contents
    def contentToPath(content)
      # XXX direct translation of original but might be redundant
      temp_chtype = RNDK.char2Chtype(content, [], [])
      temp_char = RNDK.chtype2Char(temp_chtype)
      temp_char = temp_char[0..-1]

      # Create the pathname.
      result = RNDK::Fselect.make_pathname(@pwd, temp_char)

      return result
    end

    # Currently a wrapper for File.expand_path
    def self.expandTilde(filename)
      return File.expand_path(filename)
    end

    def destroyInfo
      @dir_contents = []
      @file_counter = 0
    end

    def createList(list, list_size)
      status = false

      if list_size >= 0
        newlist = []

        # Copy in the new information
        status = true
        (0...list_size).each do |x|
          newlist << list[x]
          if newlist[x] == 0
            status = false
            break
          end
        end

        if status
          self.destroyInfo
          @file_counter = list_size
          @dir_contents = newlist
        end
      else
        self.destroyInfo
        status = true
      end
      return status
    end

    def focus
      @entry_field.focus
    end

    def unfocus
      @entry_field.unfocus
    end

    def self.isFullWidth(width)
      width == RNDK::FULL || (Ncurses.COLS != 0 && width >= Ncurses.COLS)
    end

    def position
      super(@win)
    end



  end
end
