#!/usr/bin/env ruby
#
# Displays a Scroll list with the current directory's files.
#
# You can also modify it at runtime with the keys:
#
# * 'a' adds item
# * 'i' inserts item
# * 'd' deletes item
#
# After selecting an item, we pop-up the user with it's name.
#
require 'rndk/scroll'

begin
  # Set up RNDK and colors
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Turning off the blinking cursor
  RNDK::blink_cursor false

  # Use the current directory list to fill the radio list
  item = RNDK.get_directory_contents '.'

  # Pay attention to the markup:
  # * <C> centers the text,
  # * </XX> is a color pair
  # See example 'markup.rb' for more details.
  title = <<END
<C></77>Pick a file
</77>Press 'enter' or 'tab' to select item
------------------------------------------------
END

  # Create the scrolling list.
  scroll_list = RNDK::Scroll.new(screen, {
                                   :x => RNDK::CENTER,
                                   :y => RNDK::CENTER,
                                   :width => 50,
                                   :height => 24,
                                   :title => title,
                                   :items => item,
                                   :numbers => true,
                                   :highlight => RNDK::Color[:red]
                                 })

  if scroll_list.nil?
    RNDK::Screen.finish

    puts "Cannot make scrolling list.  Is the window too small?"
    exit 1
  end

  # Activate the scrolling list.
  selection = scroll_list.activate

  # Now, we'll determine how the widget was exited
  # and pop-up the user with it's choice

  msg = []
  if scroll_list.exit_type == :ESCAPE_HIT
    msg = ['<C>You hit escape. No file selected',
           '<C>Press any key to continue.']

  elsif scroll_list.exit_type == :NORMAL
    the_item = RNDK.chtype2Char scroll_list.item[selection]

    msg = ['<C>You selected the following file',
           "<C></77>#{the_item}",
           "<C>Press any key to continue."]
  end

  # A quick widget - see example 'quick-widgets.rb'
  screen.popup_label msg

  RNDK::Screen.finish

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

