#!/usr/bin/env ruby
#
# Shows some colored lines within
# a Label widget.
require 'rndk/label'

begin
  # Starting things up
  rndkscreen = RNDK::Screen.new
  RNDK::Color.init

  # Set the labels with some nice markup
  mesg = [
          "</29/B>This line should have a yellow foreground and a blue background.",
          "</5/B>This line should have a white  foreground and a blue background.",
          "</26/B>This line should have a yellow foreground and a red  background.",
          "<C>This line should be set to whatever the screen default is."
         ]

  label = RNDK::Label.new(rndkscreen,
                          RNDK::CENTER,
                          RNDK::CENTER,
                          mesg,
                          true,
                          true)

  if label.nil?
    RNDK::Screen.end_rndk

    puts 'Cannot create the label. Is the window too small?'
    exit 1
  end

  # Draw the RNDK screen and waits for
  # space to be pressed.
  rndkscreen.refresh
  label.wait(' ')

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

