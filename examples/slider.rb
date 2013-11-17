#!/usr/bin/env ruby
#
# Shows a slider bar that goes from 1 to 100.

require 'rndk/slider'

begin
  # Markup-happy labels
  title = '<C></U>Enter a value'
  label = '</B>Current Value:'

  # Set up RNDK
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Create the widget
  widget = RNDK::Slider.new(screen, {
                              :x => RNDK::CENTER,
                              :y => RNDK::CENTER,
                              :title => title,
                              :label => label,
                              :filler => RNDK::Color[:reverse] | RNDK::Color[:white_blue] | ' '.ord,
                              :field_width => 50,
                              :start => 50,
                              :mininum => 1,
                              :maximum => 100,
                              :increment => 1,
                              :fast_increment => 2
                            })

  if widget.nil?
    RNDK::Screen.finish

    puts "Cannot make the widget. Is the window too small?"
    exit 1
  end

  # Activate the widget.
  selection = widget.activate

  # Check the exit value of the widget.
  mesg = []

  if widget.exit_type == :ESCAPE_HIT
    mesg = ["<C>You hit escape. No value selected.",
            "<C>Press any key to continue."]

  elsif widget.exit_type == :NORMAL
    mesg = ["<C>You selected #{selection}",
            "<C>Press any key to continue."]
  end

  # A quick popup widget! Check out the
  # example file 'quick-widgets.rb'
  screen.popup_label mesg

  # Clean up
  RNDK::Screen.finish

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

