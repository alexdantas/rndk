#!/usr/bin/env ruby
#
# Shows the content of this file with the Viewer widget.
# See file `lib/rndk/viewer.rb` for keybindings.
#
require 'rndk/viewer'

begin
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Oh yeah, gimme this file
  lines = RNDK.read_file(__FILE__)
  buttons = ["These", "Don't", "do", "a", "thing"]

  viewer = RNDK::Viewer.new(screen, {
                              :x => RNDK::CENTER,
                              :y => RNDK::CENTER,
                              :title => "</77>Awesome Viewer",
                              :buttons => buttons,
                              :button_highlight => RNDK::Color[:white_red],
                              :shadow => true
                            })

  # To set the lines of Viewer we must use Viewer#set.
  # No way to do it on the constructor :(
  viewer.set :items => lines

  if viewer.nil?
    RNDK::Screen.finish

    puts "Cannot create the viewer. Is the window too small?"
    exit 1
  end

  selected = viewer.activate

  # Check how the person exited from the widget.
  mesg = []

  if viewer.exit_type == :ESCAPE_HIT
    mesg = ["<C>Escape hit. No Button selected..",
            "",
            "<C>Press any key to continue."]

  elsif viewer.exit_type == :NORMAL
    mesg = ["<C>You selected button #{selected}",
            "<C>Press any key to continue."]

  end
  # Quickly show message
  screen.popup_label mesg

  RNDK::Screen.finish

  # Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

