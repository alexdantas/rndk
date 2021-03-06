# Provides easy ways to do things with Widgets, without
# all that hassle of initializing values and whatnot.
#
# ## Usage
#
# They're all methods to the RNDK::Screen class.
#
# For example:
#
#     screen = RNDK::Screen.new
#     message = ["awesome quick label!"]
#     screen.popup_label message
#

# Since I'm including a lot of widgets here, maybe I
# should make the user require 'quick_widgets'
# explicitly?
require 'rndk/label'
require 'rndk/dialog'
require 'rndk/viewer'
require 'rndk/entry'
require 'rndk/scroll'

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
    # @note: `message` must be a String or an Array of Strings.
    def popup_label message
      self.cleanly do
        popup = RNDK::Label.new(self, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :text => message
                                })
        popup.draw

        # Wait for some input.
        Ncurses.keypad(popup.win, true)
        popup.getch
        popup.destroy
      end
    end

    # Quickly pops up a `message`, using `attrib` for
    # the background of the dialog.
    #
    # @note: `message` must be an array of strings.
    def popup_label_color(message, attrib)
      self.cleanly do
        popup = RNDK::Label.new(self, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :text => message
                                })

        popup.set_bg_color attrib
        popup.draw

        # Wait for some input
        Ncurses.keypad(popup.win, true)
        popup.getch
        popup.destroy
      end
    end

    # Shows a centered pop-up Dialog box with `message` label and
    # each button label on `buttons`.
    #
    # @return The user choice or `nil` if wrong parameters
    #         were given.
    #
    # @note: `message` and `buttons` must be Arrays of Strings.
    def popup_dialog(message, buttons)
      return nil if message.empty? or buttons.empty?

      choice = 0
      self.cleanly do
        popup = RNDK::Dialog.new(self, {
                                   :x => RNDK::CENTER,
                                   :y => RNDK::CENTER,
                                   :text => message,
                                   :buttons => buttons
                                 })

        popup.draw
        choice = popup.activate
        popup.destroy
      end
      choice
    end

    # Display a long string set `info` in a Viewer Widget.
    #
    # `title` and `buttons` are applied to the Widget.
    #
    # `hide_control_chars` tells if we want to hide those
    # ugly `^J`, `^M` chars.
    #
    # @return The index of the selected button.
    # @note `info` and `buttons` must be Arrays of Strings.
    def view_info(title, info, buttons, hide_control_chars=true)
      return nil if info.class != Array or info.empty?
      return nil if buttons.class != Array or buttons.empty?

      selected = -1

      # Create the file viewer to view the file selected.
      viewer = RNDK::Viewer.new(self, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :width => -6,
                                  :height => -16,
                                  :buttons => buttons,
                                  :shadow => true
                                })

      # Set up the viewer title, and the contents of the widget.
      viewer.set({
                   :title => title,
                   :items => info,
                   :hide_control_chars => hide_control_chars
                 })

      selected = viewer.activate

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
      lines = RNDK.read_file filename

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

    # Displays a file-selection dialog with `title`.
    #
    # @return The selected filename, or `nil` if none was selected.
    #
    # TODO FIXME This widget is VERY buggy.
    #
    def select_file title

      fselect = RNDK::Fselect.new(self, {
                                    :x => RNDK::CENTER,
                                    :y => RNDK::CENTER,
                                    :width =>-20,
                                    :height => -4,
                                    :title => title,
                                    :label => 'File: '
                                  })

      filename = fselect.activate

      # Check the way the user exited the selector.
      if fselect.exit_type != :NORMAL
        fselect.destroy
        self.refresh
        return nil
      end

      # Otherwise...
      fselect.destroy
      self.refresh
      filename
    end

    # Display a scrollable `list` of strings in a Dialog, allowing
    # the user to select one.
    #
    # @return The index in the list of the value selected.
    #
    # If `numbers` is true, the displayed list items will
    # be numbered.
    #
    # @note `list` must be Arrays of Strings.
    def get_list_index(title, list, numbers)
      return nil if list.class != Array or list.empty?

      selected = -1
      height = 10
      width = -1
      len = 0

      # Determine the height of the list.
      if list.size < 10
        height = list.size + if title.size == 0 then 2 else 3 end
      end

      # Determine the width of the list.
      list.each { |item| width = [width, item.size + 10].max }

      width = [width, title.size].max
      width += 5

      scrollp = RNDK::Scroll.new(self, {
                                   :x => RNDK::CENTER,
                                   :y => RNDK::CENTER,
                                   :width => width,
                                   :height => height,
                                   :title => title,
                                   :items => list,
                                   :numbers => numbers
                                 })
      if scrollp.nil?
        self.refresh
        return -1
      end

      selected = scrollp.activate

      # Check how they exited.
      if scrollp.exit_type != :NORMAL
        selected = -1
      end

      scrollp.destroy
      self.refresh

      selected
    end

    # Pops up an Entry Widget and returns the value supplied
    # by the user.
    #
    # `title`, `label` and `initial_text` are passed to the Widget.
    def get_string(title, label, initial_text="")

      widget = RNDK::Entry.new(self, {
                                 :x => RNDK::CENTER,
                                 :y => RNDK::CENTER,
                                 :title => title,
                                 :label => label,
                                 :field_width => 40,
                                 :initial_text => initial_text
                               })

      value = widget.activate

      # Make sure they exited normally.
      if widget.exit_type != :NORMAL
        widget.destroy
        return nil
      end

      # Return a copy of the string typed in.
      value = widget.get_text.clone
      widget.destroy

      value
    end
  end
end

