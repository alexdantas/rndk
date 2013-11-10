#!/usr/bin/env ruby
require_relative 'example'

class HelloExample < Example
  def HelloExample.parse_opts(opts, param)
    opts.banner = 'Usage: hello_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = true
    super(opts, param)
  end

  # This program demonstrates the Rndk label widget.
  def HelloExample.main
    # Declare variables.
    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Set the labels up.
    mesg = [
        "</5><#UL><#HL(30)><#UR>",
        "</5><#VL(10)>Hello World!<#VL(10)>",
        "</5><#LL><#HL(30)><#LR)"
    ]

    # Declare the labels.
    demo = RNDK::LABEL.new(rndkscreen,
        params.x_value, params.y_value, mesg, 3,
        params.box, params.shadow)

    # Is the label nll?
    if demo.nil?
      # Clean up the memory.
      rndkscreen.destroy

      # End curses...
      RNDK::SCREEN.endRNDK

      puts "Cannot create the label. Is the window too small?"
      exit #  EXIT_FAILURE
    end

    # Draw the RNDK screen.
    rndkscreen.refresh
    demo.wait(' ')

    # Clean up
    demo.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

HelloExample.main
