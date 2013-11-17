#!/usr/bin/env ruby
#
# Note: This is not for beginners! Check out the examples/
#       before adventuring into the demos/ realm!
#
# Shows a colored clock on the screen according to
# current system time.
# Press any key to exit.

require 'rndk/label'

begin
  # Set up RNDK
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Initial time string
  mesg = ['</1/B>HH:MM:SS']

  # Declare the labels.
  label = RNDK::Label.new(screen, {
                            :x => RNDK::CENTER,
                            :y => RNDK::CENTER,
                            :text => mesg,
                            :shadow => true
                          })

  # Woops, something bad happened
  if label.nil?
    screen.destroy
    RNDK::Screen.finish

    puts "Cannot create the label. Is the window too small?"
    exit 1
  end

  # hiding cursor
  Ncurses.curs_set 0

  # Will wait 50ms before getting input
  Ncurses.wtimeout(label.screen.window, 50)

  loop do
    # Will go on until the user presses something
    char = Ncurses.wgetch label.screen.window
    break unless (char == Ncurses::ERR)

    current_time = Time.now.getlocal

    # Formatting time string.
    str = "<C></B/29>%02d:%02d:%02d" % [current_time.hour, current_time.min, current_time.sec]
    mesg = [str]

    # Set the label contents
    label.set(:text => mesg)

    # Draw the label and sleep
    label.draw
    Ncurses.napms(500)
  end

  RNDK::Screen.finish

# In case something goes wrong
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
end

