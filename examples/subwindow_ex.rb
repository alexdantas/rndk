#!/usr/bin/env ruby
require_relative 'example'

class SubwindowExample < CLIExample
  def SubwindowExample.parse_opts(opts, params)
    opts.banner = 'Usage: subwindow_ex.rb [options]'

    # default values
    params.box = true
    params.shadow = false
    params.x_value = RNDK::CENTER
    params.y_value = RNDK::CENTER
    params.h_value = 10
    params.w_value = 15
    params.spos = RNDK::RIGHT

    super(opts, params)

    opts.on('-s SCROLL_POS', OptionParser::DecimalInteger,
        'location for the scrollbar') do |spos|
      params.spos = spos
    end
  end

  # This demo displays the ability to put widgets within a curses subwindow.
  def SubwindowExample.main
    dow = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
        'Saturday', 'Sunday'
    ]

    # Declare variables.
    params = parse(ARGV)

    # Start curses
    curses_win = Ncurses.initscr
    Ncurses.curs_set(0)

    # Create a basic window.
    sub_window = Ncurses.newwin(Ncurses.LINES - 5, Ncurses.LINES - 10, 2, 5)

    # Start Rndk.
    rndkscreen = RNDK::SCREEN.new(sub_window)

    # Box our window.
    Ncurses.box(sub_window, Ncurses::ACS_VLINE, Ncurses::ACS_HLINE)
    Ncurses.wrefresh sub_window

    # Create a basic scrolling list inside the window.
    dow_list = RNDK::SCROLL.new(rndkscreen,
        params.x_value, params.y_value, params.spos,
        params.h_value, params.w_value, "<C></U>Pick a Day",
        dow, 7, false, Ncurses::A_REVERSE, params.box, params.shadow)

    # Put a title within the window.
    mesg = [
        "<C><#HL(30)>",
        "<C>This is a Rndk scrolling list",
        "<C>inside a curses window.",
        "<C><#HL(30)>"
    ]
    title = RNDK::LABEL.new(rndkscreen, RNDK::CENTER, 0, mesg, 4, false, false)

    # Refresh the screen.
    rndkscreen.refresh

    # Let the user play.
    pick = dow_list.activate('')

    # Clean up.
    dow_list.destroy
    title.destroy
    RNDK.eraseCursesWindow(sub_window)
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK

    # Tell them what they picked.
    puts "You picked %s" % [dow[pick]]
    exit # EXIT_SUCCESS
  end
end

SubwindowExample.main
