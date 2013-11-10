#!/usr/bin/env ruby
require_relative 'example'

class Radio1Example < CLIExample
  def Radio1Example.parse_opts(opts, params)
    opts.banner = 'Usage: radio1_ex.rb [options]'

    # default values
    params.box = true
    params.shadow = false
    params.x_value = RNDK::CENTER
    params.y_value = RNDK::CENTER
    params.h_value = 5
    params.w_value = 20
    params.spos = RNDK::NONE
    params.title = ""

    super(opts, params)

    opts.on('-s SCROLL_POS', OptionParser::DecimalInteger,
        'location for the scrollbar') do |spos|
      params.spos = spos
    end

    opts.on('-t TITLE', String, 'title for the widget') do |title|
      params.title = title
    end
  end

  # This program demonstrates the Rndk radio widget.
  #
  # Options (in addition to normal CLI parameters):
  #   -s SPOS location for the scrollbar
  #   -t TEXT title for the widget
  def Radio1Example.main
    params = parse(ARGV)

    # Use the current directory list to fill the radio list
    item = [
        "Choice A",
        "Choice B",
        "Choice C",
    ]

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the radio list.
    radio = RNDK::RADIO.new(rndkscreen,
        params.x_value, params.y_value, params.spos,
        params.h_value, params.w_value, params.title,
        item, 3, '#'.ord | Ncurses::A_REVERSE, true,
        Ncurses::A_REVERSE, params.box, params.shadow)

    if radio.nil?
      rndkscreen.destroyRNDKScreen
      RNDK::SCREEN.endRNDK

      puts "Cannot make radio widget.  Is the window too small?"
      exit #EXIT_FAILURE
    end

    # Activate the radio widget.
    selection = radio.activate([])

    # Check the exit status of the widget.
    if radio.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>You hit escape. No item selected',
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif radio.exit_type == :NORMAL
      mesg = [
          "<C> You selected the filename",
          "<C>%.*s" % [236, item[selection]],  # FIXME magic number
          "",
          "<C>Press any key to continue"
      ]
      rndkscreen.popupLabel(mesg, 4)
    end

    # Clean up.
    radio.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    exit #EXIT_SUCCESS
  end
end

Radio1Example.main
