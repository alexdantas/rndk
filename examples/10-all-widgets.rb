#!/usr/bin/env ruby
#
# All the widgets at once!
#
require 'rndk/calendar'
require 'rndk/label'
require 'rndk/entry'
require 'rndk/dialog'
require 'rndk/scale'
require 'rndk/graph'
require 'rndk/itemlist'
require 'rndk/radio'
require 'rndk/scroll'
require 'rndk/slider'
require 'rndk/viewer'
require 'rndk/button'
require 'rndk/buttonbox'
require 'rndk/alphalist'

begin
  # All widgets will be attached to this
  screen = RNDK::Screen.new
  RNDK::Color.init

  RNDK::Label.new(screen, :text => ["<C></66>Lots of Widgets",
                                    "</75>tab: <!75>circle  </75>F10: <!75>quit"])

  RNDK::Calendar.new(screen, {
                       :box   => true,
                       :y     => 4,
                       :title => "</77>calendar"
                     })

  RNDK::Entry.new(screen, {
                    :x => 24,
                    :field_width => -44,
                    :title => "</77>entry",
                    :label => "</75>type me something "
                  })

  RNDK::Scale.new(screen, {
                    :x => 24,
                    :y => 4,
                    :title => "</77>scale",
                    :label => "move me",
                    :field_width => 5
                  })

  d = RNDK::Dialog.new(screen, {
                     :x => 24,
                     :y => 8,
                     :text => "</77>dialog",
                     :highlight => RNDK::Color[:cyan] | RNDK::Color[:reverse],
                     :buttons => ["Press me", "No, press me!"]
                   })

  # A sample on how easy it is to customize stuff
  d.bind_signal(:before_pressing) do |button|
    message = ["Will press button no #{button}",
               "Are you sure?"]
    buttons = ["Yes", "No"]

    choice = screen.popup_dialog(message, buttons)

    # When we return false, we stop pressing the button.
    false if choice == 1
  end

  d.bind_signal(:after_pressing) do |button|
    screen.popup_label "Pressed button no #{button}"
  end

  RNDK::Graph.new(screen, {
                    :x => 26,
                    :y => 13,
                    :width => 20,
                    :height => 10
                  }).set_values([1, 2, 3, 4, 5, 2, 10, 7], true)


  RNDK::Itemlist.new(screen, {
                       :x => 39,
                       :y => 4,
                       :title => "</77>itemlist",
                       :label => "up, down: ",
                       :items => ["One", "Two", "Three", "Four"]
                     })

  RNDK::Radio.new(screen, {
                    :x => 58,
                    :y => 4,
                    :title => "</77>radio",
                    :width => 20,
                    :height => 8,
                    :items => ["Item1", "Item2", "Item3"]
                  })

  RNDK::Scroll.new(screen, {
                     :x => 58,
                     :y => 12,
                     :title => "</77>scroll",
                     :width => 30,
                     :height => 10,
                     :items => (100..120).to_a
                   })

  RNDK::Slider.new(screen, {
                     :x => 58,
                     :y => 22,
                     :start => 50,
                     :filler => ' '.ord | RNDK::Color[:cyan] | RNDK::Color[:reverse],
                     :title => "</77>slider",
                     :field_width => -58
                   })

  RNDK::Viewer.new(screen, {
                     :x => 0,
                     :y => 16,
                     :title => "</77>viewer",
                     :buttons => ["one", "two", "three"],
                     :width => 24,
                     :height => 15
                   }).set_items(`ls -l`.lines, false)

  RNDK::Button.new(screen, {
                     :x => 50,
                     :y => 8,
                     :label => "</77>button",
                   }).bind_signal(:pressed) { screen.popup_label "Button pressed" }

  RNDK::Alphalist.new(screen, {
                        :x => 58,
                        :y => 26,
                        :width => 40,
                        :height => 10,
                        :title => "</77>Alphalist",
                        :label => "</75>Type first letters here ",
                        :items => ["Here", "we", "have", "lots",
                                   "of", "words", "to", "show",
                                   "how", "awesome", "this", "is"]
                      })

  RNDK::Buttonbox.new(screen, {
                        :x => 84,
                        :y => 4,
                        :width => 14,
                        :height => 5,
                        :title => "</77>buttonbox",
                        :buttons => ["one", "two", "three", "four"],
                        :button_rows => 2,
                        :button_cols => 2,
                        :highlight => RNDK::Color[:blue] | RNDK::Color[:reverse]
                      })

  screen.refresh
  RNDK::Traverse.over screen
  RNDK::Screen.finish

# Just in case something goes wrong.
rescue Exception => e
  RNDK::Screen.finish
  puts e
  puts e.backtrace
end

