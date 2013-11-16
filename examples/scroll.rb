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
  Ncurses.curs_set 0

  # Use the current directory list to fill the radio list
  item = RNDK.get_directory_contents '.'

  # Pay attention to the markup:
  # * <C> centers the text,
  # * </XX> is a color pair
  # See example 'markup.rb' for more details.
  title = <<END
<C></77>Pick a file
</77>Press 'a' to append an item
</77>Press 'i' to insert an item
</77>Press 'd' to delete current item
</77>(don't worry, won't delete your files)
</77>Press 'enter' or 'tab' to select item
------------------------------------------------
END

  # Create the scrolling list.
  scroll_list = RNDK::Scroll.new(screen,
                                 RNDK::CENTER,      # x
                                 RNDK::CENTER,      # y
                                 RNDK::RIGHT,       # scrollbar position
                                 50,                # width
                                 24,                # height
                                 title,             # title
                                 item,              # items on the list
                                 true,              # show numbers
                                 RNDK::Color[:red], # highlight color
                                 true,              # box
                                 false)             # shadow

  if scroll_list.nil?
    RNDK::Screen.finish

    puts "Cannot make scrolling list.  Is the window too small?"
    exit 1
  end

  # These are the functions that will modify the
  # Scroll List at runtime.
  #
  # The arguments to the block are provided by
  # default, you can ignore them right now.
  #
  # The only thing you need to know is that `widget` is
  # the scroll - widget that we attach the callback to.
  $counter = 0

  add_item_callback = lambda do |type, widget, client_data, input|
    widget.addItem "add_#{$counter}"
    $counter += 1
    widget.screen.refresh
    return true
  end

  insert_item_callback = lambda do |type, widget, client_data, input|
    widget.insertItem "insert_#{$counter}"
    $counter += 1
    widget.screen.refresh
    return true
  end

  delete_item_callback = lambda do |type, widget, client_data, input|
    widget.deleteItem widget.getCurrentItem
    widget.screen.refresh
    return true
  end

  # And this is how we bind keys to actions.
  #
  # It only accepts lambdas.

  scroll_list.bind('a', add_item_callback, nil)
  scroll_list.bind('i', insert_item_callback, nil)
  scroll_list.bind('d', delete_item_callback, nil)

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

