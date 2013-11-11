# Provides easy ways to do things with Widgets, without
# all that hassle of initializing values and whatnot.
#
# ## Usage
#
# They're all methods to the RNDK::Screen class.
# For example:
#
#     curses_win = Ncurses.initscr
#     rndkscreen = RNDK::Screen.new(curses_win)
#     message = ["awesome quick label!"]
#     rndkscreen.popupLabel message
#
require 'rndk/label'
require 'rndk/dialog'

module RNDK
  class Screen

    # Executes a block of code without modifying the
    # screen state.
    #
    # See usage right below.
    def cleanly &block
      prev_state = Ncurses.curs_set 0

      yield

      Ncurses.curs_set prev_state
      self.erase
      self.refresh
    end

    # Quickly pops up a `message`.
    #
    # Creates a centered pop-up Label Widget that
    # waits until the user hits a character.
    #
    # @note: `message` must be an array of strings.
    def popupLabel message
      return if message.class != Array or message.empty?

      self.cleanly do
        count = message.size

        popup = RNDK::LABEL.new(self, CENTER, CENTER, message, count, true, false)
        popup.draw(true)

        # Wait for some input.
        Ncurses.keypad(popup.win, true)
        popup.getch([])
        popup.destroy
      end
    end

    # Quickly pops up a `message`, using `attrib` for
    # the background of the dialog.
    #
    # @note: `message` must be an array of strings.
    def popupLabelAttrib(message, attrib)
      return if message.class != Array or message.empty?

      self.cleanly do
        popup = RNDK::LABEL.new(self, CENTER, CENTER, message, message.size, true, false)
        popup.setBackgroundAttrib attrib
        popup.draw(true)

        # Wait for some input
        Ncurses.keypad(popup.win, true)
        popup.getch([])

        popup.destroy
      end
    end

    # Shows a centered pop-up Dialog box with `message` label and
    # each button label on `buttons`.
    #
    # @returns The user choice or `nil` if wrong parameters
    #          were given.
    #
    # @note: `message` and `buttons` must be Arrays of Strings.
    def popupDialog(message, buttons)
      return nil if message.class != Array or message.empty?
      return nil if buttons.class != Array or buttons.empty?

      self.cleanly do
        popup = RNDK::DIALOG.new(self,
                                 RNDK::CENTER,
                                 RNDK::CENTER,
                                 message,
                                 message.size,
                                 buttons,
                                 buttons.size,
                                 Ncurses::A_REVERSE,
                                 true, true, false)
        popup.draw(true)
        choice = popup.activate('')
        popup.destroy
      end
      choice
    end

    # Display a string set `info` in a Viewer Widget.
    #
    # `title` and `buttons` are applied to the Widget.
    # This allows the user to view information.
    #
    # @return The index of the selected button.
    # @note `info` and `buttons` must be Arrays of Strings.
    def view_info(title, info, buttons, interpret)
      return nil if info.class != Array or info.empty?
      return nil if buttons.class != Array or buttons.empty?

      selected = -1

      # Create the file viewer to view the file selected.
      viewer = RNDK::VIEWER.new(self,
                                RNDK::CENTER,
                                RNDK::CENTER,
                                -6,
                                -16,
                                buttons,
                                buttons.size,
                                Ncurses::A_REVERSE,
                                true,
                                true)

      # Set up the viewer title, and the contents of the widget.
      viewer.set(title,
                 info,
                 info.size,
                 Ncurses::A_REVERSE,
                 interpret,
                 true,
                 true)

      selected = viewer.activate([])

      # Make sure they exited normally.
      if viewer.exit_type != :NORMAL
        viewer.destroy
        return -1
      end

      # Clean up and return the button index selected
      viewer.destroy
      selected
    end

    # Reads `filename`'s contents and display it on a Viewer Widget.
    #
    # `title` and `buttons` are applied to the Widget.
    #
    # The viewer shows the contents of the file supplied by the
    # `filename` value.
    #
    # It returns the index of the button selected, or -1 if the file
    # does not exist or if the widget was exited early.
    def view_file(title, filename, buttons)

      info = []
      result = 0

      # Open the file and read the contents.
      lines = RNDK.readFile(filename, info)

      # If we couldn't read the file, return an error.
      if lines == -1
        result = lines
      else
        result = self.view_info(title,
                                info,
                                buttons,
                                true)
      end
      result
    end

  end
end

