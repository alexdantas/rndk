#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class ButtonboxExample < Example
  # This program demonstrates the Rndk buttonbox widget.
  def ButtonboxExample.main
    buttons = [" OK ", " Cancel "]

    # Set up RNDK.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Start color.
    RNDK::Draw.initRNDKColor

    # Create the entry widget.
    entry = RNDK::ENTRY.new(rndkscreen, RNDK::CENTER, RNDK::CENTER,
        "<C>Enter a name", "Name ", Ncurses::A_NORMAL, '.', :MIXED,
        40, 0, 256, true, false)

    if entry.nil?
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      $stderr.puts "Cannot create entry-widget"
      exit # EXIT_FAILURE
    end

    # Create the button box widget.
    button_widget = RNDK::BUTTONBOX.new(rndkscreen,
        Ncurses.getbegx(entry.win), Ncurses.getbegy(entry.win) + entry.box_height - 1,
        1, entry.box_width - 1, '', 1, 2, buttons, 2, Ncurses::A_REVERSE,
        true, false)

    if button_widget.nil?
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      $stderr.puts "Cannot create buttonbox-widget"
      exit # EXIT_FAILURE
    end

    # Set the lower left and right characters of the box.
    entry.setLLchar(Ncurses::ACS_LTEE)
    entry.setLRchar(Ncurses::ACS_RTEE)
    button_widget.setULchar(Ncurses::ACS_LTEE)
    button_widget.setURchar(Ncurses::ACS_RTEE)

    # Bind the Tab key in the entry field to send a
    # Tab key to the button box widget.
    entryCB = lambda do |rndktype, object, client_data, key|
      client_data.inject(key)
      return true
    end

    entry.bind(:ENTRY, RNDK::KEY_TAB, entryCB, button_widget)

    # Activate the entry field.
    button_widget.draw(true)
    info = entry.activate('')
    selection = button_widget.current_button

    # Clean up.
    button_widget.destroy
    entry.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk

    puts "You typed in (%s) and selected button (%s)" % [
        if !(info.nil?) && info.size > 0 then info else '<null>' end,
        buttons[selection]
    ]
    exit # EXIT_SUCCESS
  end
end

ButtonboxExample.main
