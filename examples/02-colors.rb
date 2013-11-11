#!/usr/bin/env ruby
#
# Shows how to use colors on your daily life,
# plus this beautiful Calendar Widget!
#
require 'rndk/calendar'

begin
  # Always initialize and save the scren
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Disabling the blinking cursor
  Ncurses.curs_set 0

  # Welcome to our Calendar Widget!
  #
  # We call Colors attributes - or attrib.
  # We use them as:
  #
  #     RNDK::Color[:foreground_background]
  #
  # If you want to use your terminal's default
  # background, simply do:
  #
  #     RNDK::Color[:foreground]
  #
  # On the calendar, if we supply 0 as the
  # day/month/year it'll use the current day/month/year.
  cal = RNDK::CALENDAR.new(screen,
                           RNDK::CENTER,             # x
                           RNDK::CENTER,             # y
                           "Colored calendar",       # title
                           0,                        # day
                           0,                        # month
                           0,                        # year
                           RNDK::Color[:red_yellow], # day attrib
                           RNDK::Color[:cyan_white], # month attrib
                           RNDK::Color[:black_cyan], # year attrib
                           RNDK::Color[:red],        # highlight
                           true,                     # has box?
                           false)                    # has shadow?
  cal.activate []

  RNDK::Screen.end_rndk

# Assuring we end RNDK in case something
# bad happens.
# You'll see this a lot on the examples.
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

