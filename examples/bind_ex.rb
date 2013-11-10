#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require 'etc'
require_relative './example'

class BindExample < Example
  def BindExample.parse_opts(opts, param)
    opts.banner = 'Usage: dialog_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    super(opts, param)
  end

  def BindExample.main
    title = "<C>Enter a\n<C>directory name."
    label = "</U/5>Directory:<!U!5>"

    params = parse(ARGV)

    # Set up RNDK.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Start color.
    RNDK::Draw.initRNDKColor

    # Set up the dialog box.
    message = [
        "<C></U>Simple Command Interface",
        "Pick the command you wish to run.",
        "<C>Press </R>?<!R> for help."
    ]

    buttons = ["Who", "Time", "Date", "Quit"]

    # Create the dialog box
    question = RNDK::DIALOG.new(rndkscreen, params.x_value, params.y_value,
        message, 3, buttons, 4, Ncurses::A_REVERSE, true,
        params.box, params.shadow)

    # Check if we got a nil value back.
    if question.nil?
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot create the dialog box. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    dialog_help_cb = lambda do |rndktype, dialog, client_data, key|
      mesg = []
      # Check which button we are on
      if dialog.current_button == 0
        mesg = [
            "<C></U>Help for </U>Who<!U>.",
            "<C>When this button is picked the name of the current",
            "<C>user is displayed on the screen in a popup window.",
        ]
        dialog.screen.popupLabel(mesg, 3)
      elsif dialog.current_button == 1
        mesg = [
            "<C></U>Help for </U>Time<!U>.",
            "<C>When this button is picked the current time is",
            "<C>displayed on the screen in a popup window."
        ]
        dialog.screen.popupLabel(mesg, 3)
      elsif dialog.current_button == 2
        mesg = [
            "<C></U>Help for </U>Date<!U>.",
            "<C>When this button is picked the current date is",
            "<C>displayed on the screen in a popup window."
        ]
        dialog.screen.popupLabel(mesg, 3)
      elsif dialog.current_button == 3
        mesg = [
            "<C></U>Help for </U>Quit<!U>.",
            "<C>When this button is picked the dialog box is exited."
        ]
        dialog.screen.popupLabel(mesg, 2)
      end
      return false
    end

    # Create the key binding.
    question.bind(:DIALOG, '?', dialog_help_cb, 0)

    # Activate the dialog box.
    selection = 0
    while selection != 3
      # Get the users button selection
      selection = question.activate('')

      # Check the results.
      if selection == 0
        # Get the users login name.
        info = ["<C>     </U>Login Name<!U>     "]
        login_name = Etc.getlogin
        info << if login_name.nil?
                then "<C></R>Unknown"
                else "<C><%.*s>" % [246, login_name]  # FIXME magic number
                end

        question.screen.popupLabel(info, 2)
      elsif selection == 1
        info = [
            "<C>   </U>Current Time<!U>   ",
            Time.new.getlocal.strftime('<C>%H:%M:%S')
        ]
        question.screen.popupLabel(info, 2)
      elsif selection == 2
        info = [
            "<C>   </U>Current Date<!U>   ",
            Time.new.getlocal.strftime('<C>%d/%m/%y')
        ]
        question.screen.popupLabel(info, 2)
      end
    end

    # Clean up and exit.
    question.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    exit  # EXIT_SUCCESS
  end
end

BindExample.main
