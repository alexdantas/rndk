#!/usr/bin/env ruby
#
# An example on  how you can make forms
require 'rndk/label'
require 'rndk/entry'
require 'rndk/button'
require 'rndk/template'
require 'rndk/radio'
require 'rndk/itemlist'

class Layout < RNDK::Screen

  def initialize
    super
    RNDK::Color.init

    # First we create the widgets, then we bind their actions
    y = 0
    @title = RNDK::Label.new(self,
                             :text => "</77>Sign Up",
                             :y => y,
                             :box => false)
    y += 2

    @name = RNDK::Entry.new(self,
                            :y => y,
                            :title => "",
                            :label => "Name     ",
                            :field_width => 30,
                            :box => false)
    y += 2

    @user = RNDK::Entry.new(self,
                            :y => y,
                            :title => "",
                            :label => "Login    ",
                            :field_width => 30,
                            :box => false)
    y += 1

    @pass1 = RNDK::Entry.new(self,
                             :y => y,
                             :title => "",
                             :field_width => 30,
                             :disp_type => :HMIXED,
                             :label => "Password ",
                             :box => false)
    y += 1

    @pass2 = RNDK::Entry.new(self,
                             :y => y,
                             :title => "",
                             :field_width => 30,
                             :disp_type => :HMIXED,
                             :label => "(again)  ",
                             :box => false)
    y += 2

    @date = RNDK::Template.new(self,
                               :y => y,
                               :title => '',
                               :label => "Date     ",
                               :plate => "##/##/####",
                               :overlay => "dd/mm/yyyy",
                               :box => false)
    y += 2

    items = ["Option 1",
             "Option 2",
             "Option 3",
             "Option 4"]
    @radio = RNDK::Radio.new(self,
                             :y => y,
                             :width => 33,
                             :height => 4,
                             :items => items,
                             :box => false)
    y += 6

    @sex = RNDK::Itemlist.new(self,
                              :y => y,
                              :title => '',
                              :label => "Sex      ",
                              :items => ["Male", "Female", "Other"],
                              :box => false)
    y += 2

    @clear = RNDK::Button.new(self,
                              :y => y,
                              :label => "Clear")

    @save = RNDK::Button.new(self,
                             :x => 33,
                             :y => y,
                             :label => "Save")

    @pass2.bind_signal(:after_leaving) do
      if not @pass2.empty?
        color = RNDK::Color[:red]
        color = RNDK::Color[:green] if @pass1.text == @pass2.text

        @pass2.set_field_color color
      end
    end

    @clear.bind_signal(:after_pressing) do
      [@name, @user, @pass1, @pass2, @date].each { |w| w.clean }
    end

    @save.bind_signal(:before_pressing) do
      keep_going = true
      [@name, @user, @pass1, @pass2, @date].each do |w|
        keep_going = false if w.empty?
      end

      keep_going
    end

    @save.bind_signal(:after_pressing) do
      self.popup_label "HELL YEAH"
      self.refresh
    end

  end

  def run
    draw
    RNDK::Traverse.over self
  end

  def end
    RNDK::Screen.finish
  end
end

begin
  layout = Layout.new

  layout.run
  layout.end

# In case something goes wrong
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
end

