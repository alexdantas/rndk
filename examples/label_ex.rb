#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class LabelExample < Example
  def LabelExample.parse_opts(opts, param)
    opts.banner = 'Usage: label_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = true
    super(opts, param)
  end

  # This program demonstrates the Rndk label widget.
  def LabelExample.main
    # Declare variables.
    mesg = []

    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Set the labels up.
    mesg = [
        "</29/B>This line should have a yellow foreground and a blue background.",
        "</5/B>This line should have a white  foreground and a blue background.",
        "</26/B>This line should have a yellow foreground and a red  background.",
        "<C>This line should be set to whatever the screen default is."
    ]

    # Declare the labels.
    demo = RNDK::LABEL.new(rndkscreen,
        params.x_value, params.y_value, mesg, 4,
        params.box, params.shadow)

    # if (demo == 0)
    # {
    #   /* Clean up the memory.
    #   destroyRNDKScreen (rndkscreen);
    #
    #   # End curses...
    #   end_rndk ();
    #
    #   printf ("Cannot create the label. Is the window too small?\n");
    #   ExitProgram (EXIT_FAILURE);
    # }

    # Draw the RNDK screen.
    rndkscreen.refresh
    demo.wait(' ')

    # Clean up
    demo.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    #ExitProgram (EXIT_SUCCESS);
  end
end

LabelExample.main
