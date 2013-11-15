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
  widget = RNDK::Slider.new(screen,
                            RNDK::CENTER,
                            RNDK::CENTER,
                            title,
                            label,
                            Ncurses::A_REVERSE | RNDK::Color[:white_blue] | ' '.ord,
                            50,
                            1,
                            1,
                            100,
                            1,
                            2,
                            true,
                            false)

  if widget.nil?
    RNDK::Screen.end_rndk

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
  RNDK::Screen.end_rndk

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

