#!/usr/bin/env ruby
#
# Shows off the Calendar Widget, binding some keys to actions.
#
# Note: This example is quite complex.
#       See file '02-colors.rb' for a better introduction
#       to the calendar widget.
#
require 'rndk/calendar'

begin
  # Start RNDK and Colors
  screen = RNDK::Screen.new
  RNDK::Color.init

  title = "<C></U>RNDK Calendar Widget\n<C>Demo"

  # Declare the calendar widget.
  calendar = RNDK::Calendar.new(screen, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :title => title,
                                  :day_color => RNDK::Color[:red_black] | RNDK::Color[:bold],
                                  :month_color => RNDK::Color[:green_black] | RNDK::Color[:bold],
                                  :yeah_color => RNDK::Color[:yellow_black] | RNDK::Color[:bold],
                                  :highlight => RNDK::Color[:blue_black] | RNDK::Color[:reverse],
                                })

  if calendar.nil?
    RNDK::Screen.finish

    puts 'Cannot create the calendar. Is the window too small?'
    exit 1
  end

  # Here we define the functions that will be
  # executed when the user presses a key.
  # Also, binding the keys to actions.

  # This adds a marker ot the calendar.
  calendar.bind_key('m') do |widget_type, calendar, client_data, key|
    calendar.set_marker(calendar.day, calendar.month, calendar.year)
    calendar.draw(calendar.box)
    return false
  end

  # This removes a marker from the calendar.
  calendar.bind_key('r') do |widget_type, calendar, client_data, key|
    calendar.removeMarker(calendar.day, calendar.month, calendar.year)
    calendar.draw(calendar.box)
    return false
  end

  calendar.week_base = 0

  # Let the user play with the widget.
  ret_val = calendar.activate

  # Check which day they selected.
  if calendar.exit_type == :ESCAPE_HIT
    mesg = [
            '<C>You hit escape. No date selected.',
            '',
            '<C>Press any key to continue.'
           ]
    screen.popup_label mesg

  elsif calendar.exit_type == :NORMAL
    mesg = [
            'You selected the following date',
            '<C></B/16>%02d/%02d/%d (dd/mm/yyyy)' % [
                                                     calendar.day, calendar.month, calendar.year],
            '<C>Press any key to continue.'
           ]
    screen.popup_label mesg
  end

  # Finishing up and printing message
  RNDK::Screen.finish

  puts 'Selected Time: %s' % ret_val.ctime unless ret_val.nil?

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

