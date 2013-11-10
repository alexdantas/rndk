#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class DialogExample < Example
  def DialogExample.parse_opts(opts, param)
    opts.banner = 'Usage: dialog_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    super(opts, param)
  end
  # This program demonstrates the Rndk dialog widget.
  def DialogExample.main
    buttons = ["</B/24>Ok", "</B16>Cancel"]

    params = parse(ARGV)

    # Set up RNDK.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Start color.
    RNDK::Draw.initRNDKColor

    # Create the message within the dialog box.
    message = [
        "<C></U>Dialog Widget Demo",
        " ",
        "<C>The dialog widget allows the programmer to create",
        "<C>a popup dialog box with buttons. The dialog box",
        "<C>can contain </B/32>colours<!B!32>, </R>character attributes<!R>",
        "<R>and even be right justified.",
        "<L>and left."
    ]

    # Create the dialog box.
    question = RNDK::DIALOG.new(rndkscreen, params.x_value, params.y_value,
        message, 7, buttons, 2, Ncurses.COLOR_PAIR(2) | Ncurses::A_REVERSE,
        true, params.box, params.shadow)

    # Check if we got a nil value back
    if question.nil?
      # Shut down Rndk.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot create the dialog box. Is the window too small?"
      exit # EXIT_FAILURE
    end

    # Activate the dialog box.
    selection = question.activate('')

    # Tell them what was selected.
    if question.exit_type == :ESCAPE_HIT
      mesg = [
          "<C>You hit escape. No button selected.",
          "",
          "<C>Press any key to continue."
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif
      mesg = [
          "<C>You selected button #%d" % [selection],
          "",
          "<C>Press any key to continue."
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up.
    question.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    exit # EXIT_SUCCESS
  end
end

DialogExample.main
