#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class RNDKScreenExample < Example
  # This demonstrates how to create four different Rndk screens
  # and flip between them.
  def RNDKScreenExample.main
    buttons = ["Continue", "Exit"]

    # Create the curses window.
    curses_win = Ncurses.initscr

    # Create the screens
    rndkscreen1 = RNDK::SCREEN.new(curses_win)
    rndkscreen2 = RNDK::SCREEN.new(curses_win)
    rndkscreen3 = RNDK::SCREEN.new(curses_win)
    rndkscreen4 = RNDK::SCREEN.new(curses_win)
    rndkscreen5 = RNDK::SCREEN.new(curses_win)

    # Create the first screen.
    title1_mesg = [
        "<C><#HL(30)>",
        "<C></R>This is the first screen.",
        "<C>Hit space to go to the next screen",
        "<C><#HL(30)>"
    ]
    label1 = RNDK::LABEL.new(rndkscreen1, RNDK::CENTER, RNDK::TOP, title1_mesg,
        4, false, false)

    # Create the second screen.
    title2_mesg = [
        "<C><#HL(30)>",
        "<C></R>This is the second screen.",
        "<C>Hit space to go to the next screen",
        "<C><#HL(30)>"
    ]
    label2 = RNDK::LABEL.new(rndkscreen2, RNDK::RIGHT, RNDK::CENTER, title2_mesg,
        4, false, false)

    # Create the third screen.
    title3_mesg = [
        "<C><#HL(30)>",
        "<C></R>This is the third screen.",
        "<C>Hit space to go to the next screen",
        "<C><#HL(30)>"
    ]
    label3 = RNDK::LABEL.new(rndkscreen3, RNDK::CENTER, RNDK::BOTTOM, title3_mesg,
        4, false, false)

    # Create the fourth screen.
    title4_mesg = [
        "<C><#HL(30)>",
        "<C></R>This is the fourth screen.",
        "<C>Hit space to go to the next screen",
        "<C><#HL(30)>"
    ]
    label4 = RNDK::LABEL.new(rndkscreen4, RNDK::LEFT, RNDK::CENTER, title4_mesg,
        4, false, false)

    # Create the fifth screen.
    dialog_mesg = [
        "<C><#HL(30)>",
        "<C>Screen 5",
        "<C>This is the last of 5 screens. If you want",
        "<C>to continue press the 'Continue' button.",
        "<C>Otherwise press the 'Exit' button",
        "<C><#HL(30)>"
    ]
    dialog = RNDK::DIALOG.new(rndkscreen5, RNDK::CENTER, RNDK::CENTER, dialog_mesg,
        6, buttons, 2, Ncurses::A_REVERSE, true, true, false)

    # Do this forever... (almost)
    while true
      # Draw the first screen.
      rndkscreen1.draw
      label1.wait(' ')
      rndkscreen1.erase

      # Draw the second screen.
      rndkscreen2.draw
      label2.wait(' ')
      rndkscreen2.erase

      # Draw the third screen.
      rndkscreen3.draw
      label3.wait(' ')
      rndkscreen3.erase

      # Draw the fourth screen.
      rndkscreen4.draw
      label4.wait(' ')
      rndkscreen4.erase

      # Draw the fifth screen
      rndkscreen5.draw
      answer = dialog.activate('')

      # Check the user's answer.
      if answer == 1
        label1.destroy
        label2.destroy
        label3.destroy
        label4.destroy
        dialog.destroy
        rndkscreen1.destroy
        rndkscreen2.destroy
        rndkscreen3.destroy
        rndkscreen4.destroy
        rndkscreen5.destroy
        RNDK::SCREEN.endRNDK
        exit  # EXIT__SUCCESS
      end
    end
  end
end

RNDKScreenExample.main
