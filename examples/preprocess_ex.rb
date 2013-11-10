#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class PreProcessExample < Example
  # This program demonstrates the Rndk preprocess feature.
  def PreProcessExample.main
    title = "<C>Type in anything you want\n<C>but the dreaded letter </B>G<!B>!"

    # Set up RNDK.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Start color.
    RNDK::Draw.initRNDKColor

    # Create the entry field widget.
    widget = RNDK::ENTRY.new(rndkscreen, RNDK::CENTER, RNDK::CENTER,
        title, '', Ncurses::A_NORMAL, '.', :MIXED, 40, 0, 256,
        true, false)

    if widget.nil?
      # Clean up
      rndkscreen.destroy
      RNDK.endRNDK

      puts "Cannot create the entry box. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    entry_pre_process_cb = lambda do |rndktype, entry, client_data, input|
      buttons = ["OK"]
      button_count = 1
      mesg = []

      # Check the input.
      if input == 'g'.ord || input == 'G'.ord
        mesg << "<C><#HL(30)>"
        mesg << "<C>I told you </B>NOT<!B> to type G"
        mesg << "<C><#HL(30)>"

        dialog = RNDK::DIALOG.new(entry.screen, RNDK::CENTER, RNDK::CENTER,
            mesg, mesg.size, buttons, button_count, Ncurses::A_REVERSE,
            false, true, false)
        dialog.activate('')
        dialog.destroy
        entry.draw(entry.box)
        return 0
      end
      return 1
    end

    widget.setPreProcess(entry_pre_process_cb, nil)

    # Activate the entry field.
    info = widget.activate('')

    # Tell them what they typed.
    if widget.exit_type == :ESCAPE_HIT
      mesg = [
          "<C>You hit escape. No information passed back.",
          "",
          "<C>Press any key to continue."
      ]

      rndkscreen.popupLabel(mesg, 3)
    elsif widget.exit_type == :NORMAL
      mesg = [
          "<C>You typed in the following",
          "<C>(%.*s)" % [236, info],  # FIXME: magic number
          "",
          "<C>Press any key to continue."
      ]

      rndkscreen.popupLabel(mesg, 4)
    end

    # Clean up and exit.
    widget.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    exit  # EXIT_SUCCESS
  end
end

PreProcessExample.main
