#!/usr/bin/env ruby
#
# Displays a colored "Hello, World!" Label on the screen.

# Widget we'll use
require 'rndk/label'

begin
  # Startup Ncurses and RNDK
  rndkscreen = RNDK::Screen.new

  # Set up RNDK colors
  RNDK::Draw.initRNDKColor

  # Set the labels' content.
  # (RNDK supports a "markup" string, with colors
  #  and attributes. Check out the other examples
  #  for more)
  mesg = [
          "</5><#UL><#HL(30)><#UR>",
          "</5><#VL(10)>Hello, World!<#VL(9)>",
          "</5><#LL><#HL(30)><#LR)",
          "(press space to exit)"
         ]

  # Declare the labels.
  label = RNDK::LABEL.new(rndkscreen,   # screen
                          RNDK::CENTER, # x
                          RNDK::CENTER, # y
                          mesg,         # message
                          4,            # lines count
                          true,         # box?
                          true)         # shadow?

  if label.nil?
    # Clean up the memory.
    rndkscreen.destroy

    # End curses...
    RNDK::Screen.end_rndk

    puts "Cannot create the label. Is the window too small?"
    exit 1
  end

  # Draw the RNDK screen and waits for space to be pressed.
  rndkscreen.refresh
  label.wait(' ')

  # Ending Ncurses and RNDK
  RNDK::Screen.end_rndk
end

# Note: Unlike C's CDK, there's no need to clean up
#       widgets/screens when finishing execution.

