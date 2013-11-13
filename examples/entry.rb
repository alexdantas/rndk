#!/usr/bin/env ruby
#
# Shows off the Entry widget by asking you to
# type anything.
# Then it tells you what you sent to it.
#
require 'rndk/entry'

begin
  # Startup RNDK and Colors
  rndkscreen = RNDK::Screen.new
  RNDK::Color.init

  # Watch out for that markup
  # See example 'markup.rb' for details
  title = "<C></77>Tell me something"
  label = "</U/5>Oh yeah<!U!5>:"

  # Create the entry field widget.
  entry = RNDK::Entry.new(rndkscreen,
                          RNDK::CENTER,
                          RNDK::CENTER,
                          title,
                          label,
                          Ncurses::A_NORMAL,
                          '.',
                          :MIXED,   # behavior
                          40,
                          0,
                          256,
                          true,
                          false)

  # Is the widget nil?
  if entry.nil?
    RNDK::Screen.end_rndk

    puts "Cannot create the entry box. Is the window too small?"
    exit 1
  end

  # Draw the screen.
  rndkscreen.refresh

  # Activate the entry field.
  info = entry.activate

  mesg = []
  # Tell them what they typed.
  if entry.exit_type == :ESCAPE_HIT
    mesg = ["<C>You hit escape. No information passed back.",
            "<C>Press any key to continue."]

  elsif entry.exit_type == :NORMAL
    mesg = ["<C>You typed in the following",
            "<C>(#{info})",
            "",
            "<C>Press any key to continue."]
  end

  # Quick widget - see example 'quick-widgets.rb' for details
  rndkscreen.popup_label mesg

  # Quitting
  RNDK::Screen.end_rndk

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

