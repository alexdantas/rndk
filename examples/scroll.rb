#!/usr/bin/env ruby
#
# Displays a Scroll list with the current
# directory's files.
#
# You can also modify it at runtime with the keys:
#
# * 'a' adds item
# * 'i' inserts item
# * 'd' deletes item
#
require 'rndk/scroll'

# It creates new labels to add to the Scroll List.
#
# Ignore this for now, read the rest first.
$count = 0
def new_label(prefix)
  result = "%s%d" % [prefix, $count]
  $count += 1
  return result
end

begin
  # Set up RNDK and colors
  rndkscreen = RNDK::Screen.new
  RNDK::Draw.initRNDKColor

  # Use the current directory list to fill the radio list
  item  = []
  count = RNDK.getDirectoryContents(".", item)

  # Create the scrolling list.
  scroll_list = RNDK::SCROLL.new(rndkscreen,
                                 RNDK::CENTER, # x
                                 RNDK::CENTER, # y
                                 RNDK::RIGHT,  # scrollbar position
                                 10,           # height
                                 50,           # width
                                 "<C></5>Pick a file", # title
                                 item,
                                 count,
                                 true,
                                 Ncurses::A_REVERSE,
                                 true,         # box
                                 false)        # shadow

  if scroll_list.nil?
    RNDK::Screen.end_rndk

    puts "Cannot make scrolling list.  Is the window too small?"
    exit 1
  end

  # These are the functions that will modify the
  # Scroll List at runtime.

  addItemCB = lambda do |type, widget, client_data, input|
    widget.addItem(ScrollExample.newLabel("add"))
    widget.screen.refresh
    return true
  end

  insItemCB = lambda do |type, widget, client_data, input|
    widget.insertItem(ScrollExample.newLabel("insert"))
    widget.screen.refresh
    return true
  end

  delItemCB = lambda do |type, widget, client_data, input|
    widget.deleteItem(widget.getCurrentItem)
    widget.screen.refresh
    return true
  end

  # And this is how we bind keys to actions.
  #
  # It only accepts lambdas.

  scroll_list.bind(:SCROLL, 'a', addItemCB, nil)
  scroll_list.bind(:SCROLL, 'i', insItemCB, nil);
  scroll_list.bind(:SCROLL, 'd', delItemCB, nil);

  # Activate the scrolling list.
  selection = scroll_list.activate('')

  # Determine how the widget was exited
  msg = []
  if scroll_list.exit_type == :ESCAPE_HIT
    msg = ['<C>You hit escape. No file selected',
           '',
           '<C>Press any key to continue.']

  elsif scroll_list.exit_type == :NORMAL
    the_item = RNDK.chtype2Char scroll_list.item[selection]

    msg = ['<C>You selected the following file',
           "<C>%.*s" % [236, the_item],  # FIXME magic number
           "<C>Press any key to continue."]
  end
  rndkscreen.popup_label msg

  # Exit
  RNDK::Screen.end_rndk
end

