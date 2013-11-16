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

begin
  # All widgets will be attached to this
  screen = RNDK::Screen.new
  RNDK::Color.init

  RNDK::Label.new(screen, :text => ["<C></77>Lots of Widgets",
                                    "</75>tab: <!75>circle  </75>F10: <!75>quit"])

  RNDK::Calendar.new(screen, {
                       :box   => true,
                       :y     => 4,
                       :title => "</77>calendar"
                     })

  RNDK::Entry.new(screen, {
                    :x => 24,
                    :field_width => -43,
                    :title => "</77>entry",
                    :label => "</75>type me something"
                  })

  RNDK::Scale.new(screen, {
                    :x => 24,
                    :y => 4,
                    :title => "</77>scale",
                    :label => "move me",
                    :field_width => 5
                  })

  RNDK::Dialog.new(screen, {
                     :x => 24,
                     :y => 8,
                     :text => "Nice dialog",
                     :buttons => ["Press me", "No, press me!"]
                   })

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
                     :items => (0..20).to_a
                   })

  RNDK::Slider.new(screen, {
                     :x => 58,
                     :y => 22,
                     :start => 50,
                     :title => "</77>slider",
                     :field_width => -58
                   })

  RNDK::Viewer.new(screen, {
                     :x => 0,
                     :y => 16,
                     :buttons => ["one", "two", "three"],
                     :width => 24,
                     :height => 15
                   })
  screen.refresh
  RNDK::Traverse.over screen
  RNDK::Screen.end_rndk

# Just in case something goes wrong.
rescue Exception => e
  RNDK::Screen.end_rndk
  puts e
  puts e.backtrace
end

