#!/usr/bin/env ruby
#
# Shows an Entry Widget, allowing you to move it around
# the screen via the Widget#position method.
# After positioning, you can interact with it normally.
# At the end, it shows you what you've typed.
#
# The following key bindings can be used to move the
# Widget around the screen:
#
# Up Arrow::    Moves the widget up one row.
# Down Arrow::  Moves the widget down one row.
# Left Arrow::  Moves the widget left one column
# Right Arrow:: Moves the widget right one column
# 1::           Moves the widget down one row and left one column.
# 2::           Moves the widget down one row.
# 3::           Moves the widget down one row and right one column.
# 4::           Moves the widget left one column.
# 5::           Centers the widget both vertically and horizontally.
# 6::           Moves the widget right one column
# 7::           Moves the widget up one row and left one column.
# 8::           Moves the widget up one row.
# 9::           Moves the widget up one row and right one column.
# t::           Moves the widget to the top of the screen.
# b::           Moves the widget to the bottom of the screen.
# l::           Moves the widget to the left of the screen.
# r::           Moves the widget to the right of the screen.
# c::           Centers the widget between the left and right of the window.
# C::           Centers the widget between the top and bottom of the window.
# Escape::      Returns the widget to its original position.
# Return::      Exits the function and leaves the Widget where it was.
#
require 'rndk/entry'

begin
  label = "</U/5>Position me:<!U!5> "

  # Set up RNDK
  curses_win = Ncurses.initscr
  rndkscreen = RNDK::Screen.new(curses_win)

  # Set up RNDK colors
  RNDK::Color.init

  # Create the entry field widget.
  entry = RNDK::ENTRY.new(rndkscreen,
                          RNDK::CENTER, # x
                          RNDK::CENTER, # y
                          '',
                          label,
                          Ncurses::A_NORMAL,
                          '.',
                          :MIXED,
                          30, # w
                          0,
                          256,
                          true,
                          false)

  if entry.nil?
    rndkscreen.destroy
    RNDK::Screen.end_rndk

    puts "Cannot create the entry box. Is the window too small?"
    exit 1
  end

  # Let the user move the widget around the window.
  entry.draw(entry.box)
  entry.position

  # Activate the entry field.
  info = entry.activate('')

  # Tell them what they typed.
  if entry.exit_type == :ESCAPE_HIT
    mesg = [
            "<C>You hit escape. No information passed back.",
            "",
            "<C>Press any key to continue."
           ]
    rndkscreen.popup_label mesg

  elsif entry.exit_type == :NORMAL
    mesg = [
            "<C>You typed in the following",
            "<C>%.*s" % [236, info],  # FIXME magic number
            "",
            "<C>Press any key to continue."
           ]
    rndkscreen.popup_label mesg
  end

  RNDK::Screen.end_rndk

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

