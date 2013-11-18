#!/usr/bin/env ruby
#
# An example on  how you can make forms
require 'rndk/label'
require 'rndk/entry'

class Layout < RNDK::Screen

  def initialize
    super
    RNDK::Color.init

    @title = RNDK::Label.new(self,
                             :text => "</77>Sign Up",
                             :y => 0,
                             :box => false)

    @name = RNDK::Entry.new(self,
                            :y => 1,
                            :title => "",
                            :label => "Name     ",
                            :field_width => 30,
                            :box => false)

    @user = RNDK::Entry.new(self,
                            :y => 3,
                            :title => "",
                            :label => "Login    ",
                            :field_width => 30,
                            :box => false)

    @pass1 = RNDK::Entry.new(self,
                             :y => 4,
                             :title => "",
                             :field_width => 30,
                             :disp_type => :HMIXED,
                             :label => "Password ",
                             :box => false)

    @pass2 = RNDK::Entry.new(self,
                             :y => 5,
                             :title => "",
                             :field_width => 30,
                             :disp_type => :HMIXED,
                             :label => "Again    ",
                             :box => false)

    @pass2.bind_signal(:after_leaving) do
      if @pass1.text == @pass2.text
        @pass2.set_field_color RNDK::Color[:green]
      else
        @pass2.set_field_color RNDK::Color[:red]
      end
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
end

