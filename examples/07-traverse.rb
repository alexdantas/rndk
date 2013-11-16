#!/usr/bin/env ruby
#
# This example shows both callbacks and traverse.
#
# We show you two scroll bars, each having related
# items.
# When you scroll on the first, it shows it's results
# on the second one.
#
require 'rndk/scroll'
require 'rndk/label'

begin
  screen = RNDK::Screen.new
  RNDK::Color.init

  # For each item we have a description
  items = ["First",
           "Second",
           "Third"]
  descriptions = [["Contents", "of", "first", "item"],
                  ["here", "we", "have", "the", "second", "one"],
                  ["Finally", "the", "third"]]

  # Creating the two scroll bars.
  # Pay attention to their positioning.
  scroll_1 = RNDK::Scroll.new(screen, {
                                :x => RNDK::LEFT,
                                :y => RNDK::CENTER,
                                :width => RNDK::Screen.width/2 - 1,
                                :height => 20,
                                :title => "<C>Items",  # centered
                                :items => items,
                                :highlight => RNDK::Color[:red],
                              })

  scroll_2 = RNDK::Scroll.new(screen, {
                                :x => RNDK::RIGHT,
                                :y => RNDK::CENTER,
                                :width => RNDK::Screen.width/2 - 1,
                                :height => 20,
                                :title => "<C>Descriptions", # centered
                                :items => descriptions.first,
                                :highlight => RNDK::Color[:cyan]
                              })

  # Here we define what will happen after we scroll the
  # first list.
  # `Scroll#after_processing` makes a block of code
  # execute right after we process the user input.
  #
  # On this case, we're showing the description of the
  # current item.

  scroll_1.after_processing do

    desc = descriptions[scroll_1.current_item]

    scroll_2.set_items(desc, false) # numbering
    screen.refresh
  end

  # Simple label to tell the user how to quit the example
  msg = "</77>Press F10 to quit"
  label = RNDK::Label.new(screen, {
                            :x => RNDK::CENTER,
                            :y => RNDK::TOP,
                            :text => msg
                          })

  # Finally, activating the widgets and setting them
  # up for traversal.
  #
  # By traversal we mean that we'll be able to jump
  # from one widget to another with TAB and Shitf+TAB
  #
  # The default key to exit traversal is F10

  screen.refresh
  RNDK::Traverse.over screen

  RNDK::Screen.finish

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.finish
  puts e
  puts e.inspect
  puts e.backtrace
end

