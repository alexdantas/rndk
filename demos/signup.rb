#!/usr/bin/env ruby
#
# An example on  how you can make forms
require 'rndk/label'
require 'rndk/entry'
require 'rndk/button'
require 'rndk/template'

class Layout < RNDK::Screen

  def initialize
    super
    RNDK::Color.init

    y = 0
    @title = RNDK::Label.new(self,
                             :text => "</77>Sign Up",
                             :y => y,
                             :box => false)
    y += 1

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

    @radio = RNDK::Radio.new(self,
                             :y => y,


    @clear = RNDK::Button.new(self,
                              :y => y,
                              :label => "Clear")

    @clear.bind_signal(:pressed) do
      [@name, @user, @pass1, @pass2].each { |w| w.clean }
    end

    @pass2.bind_signal(:after_leaving) do
      if not @pass2.empty?
        color = RNDK::Color[:red]
        color = RNDK::Color[:green] if @pass1.text == @pass2.text

        @pass2.set_field_color color
      end
    end

    @save = RNDK::Button.new(self,
                             :x => 33,
                             :y => y,
                             :label => "Save")
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
end

