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
  RNDK::blink_cursor true

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
  cal = RNDK::Calendar.new(screen, {
                             :x => RNDK::CENTER,
                             :y => RNDK::CENTER,
                             :title => "Colored calendar",
                             :day_color => RNDK::Color[:red_yellow],
                             :highlight => RNDK::Color[:red],
                           })
  # Oh yeah
  cal.activate

  RNDK::Screen.finish

  # Assuring we end RNDK in case something
  # bad happens.
  # You'll see this a lot on the examples.
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

