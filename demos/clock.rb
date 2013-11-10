#!/usr/bin/env ruby
#
# Shows a colored clock on the screen according to
# current system time.
# Press any key to exit.

require 'rndk'

begin
  # Set up RNDK
  curses_win = Ncurses.initscr
  rndkscreen = RNDK::Screen.new curses_win
  RNDK::Draw.initRNDKColor

  # Initial time string
  mesg = ['</1/B>HH:MM:SS']

  # Declare the labels.
  label = RNDK::LABEL.new(rndkscreen, RNDK::CENTER, RNDK::CENTER, mesg, 1, true, true)

  # Woops, something bad happened
  if label.nil?
    rndkscreen.destroy
    RNDK.end_rndk

    puts "Cannot create the label. Is the window too small?"
    exit 1
  end

  # hiding cursor
  Ncurses.curs_set 0

  # Will wait 50ms before getting input
  Ncurses.wtimeout(label.screen.window, 50)

  begin
    current_time = Time.now.getlocal

    # Formatting time string.
    str = "<C></B/29>%02d:%02d:%02d" % [current_time.hour, current_time.min, current_time.sec]
    mesg = [str]

    # Set the label contents
    label.set(mesg, 1, label.box)

    # Draw the label and sleep
    label.draw(label.box)
    Ncurses.napms(500)
  end while (Ncurses.wgetch(label.screen.window)) == Ncurses::ERR

  # Clean up
  label.destroy
  rndkscreen.destroy
  RNDK::Screen.end_rndk
end

