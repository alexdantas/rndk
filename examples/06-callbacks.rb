#!/usr/bin/env ruby
#
# Shows a scrollbar with your files and keep
# asking to interrupt scrolling.
#
# It means you can set custom functions to
# execute right before and right after processing
# input on the widget.
#
# To exit press ENTER or TAB.
#
require 'rndk/scroll'

begin
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Creating scroll based on your current dir's files.
  # Nothing should be new here
  title = "<C></77>Your files"
  list = `ls -l`.lines

  scroll = RNDK::Scroll.new(screen, {
                              :x => RNDK::CENTER,
                              :y => RNDK::CENTER,
                              :scroll_bar => RNDK::LEFT,
                              :width => RNDK::Screen.width/2,
                              :height => RNDK::Screen.height/2,
                              :title => title,
                              :items => list,
                              :highlight => RNDK::Color[:green]
                            })

  # Here comes the good stuff.
  # We're assigning blocks to run before and after
  # the widget processes your input.
  #
  # Right before processing input, it'll create
  # this popup dialog.
  # Based on your answer it will stop scrolling or not.
  #
  # That's because a if a `before_processing` block
  # return false, it aborts processing the current
  # char.
  # If it returns true, it keeps going.
  #
  scroll.bind_signal(:before_input) do |key|
    message = "</73>Skip current action? #{key}"
    buttons = ["Yes", "No"]

    choice  = screen.popup_dialog(message, buttons)

    if choice == 0 then false else true end
  end

  # This is run after the widget processes your
  # input.
  # It's commented to avoid annoyance.
  # Uncomment for awesomeness

  #scroll.bind_signal(:after_input) { screen.popup_label "</75>You did it!" }


  # Finally, we activate the widget!
  scroll.activate

  RNDK::Screen.finish

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish
  puts e
  puts e.inspect
  puts e.backtrace
end

