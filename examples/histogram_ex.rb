#!/usr/bin/env ruby
require_relative 'example'

class HistogramExample < CLIExample
  def HistogramExample.parse_opts(opts, params)
    opts.banner = 'Usage: histogram_ex.rb [options]'

    # default values
    params.box = true
    params.shadow = false
    params.x_value = 10
    params.y_value = false
    params.y_vol = 10
    params.y_bass = 14
    params.y_treb = 18
    params.h_value = 1
    params.w_value = -2

    super(opts, params)

    if params.y_value != false
      params.y_vol = params.y_value
      params.y_bass = params.y_value
      params.y_treb = params.y_value
    end
  end

  def HistogramExample.main
    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the histogram objects.
    volume_title = "<C></5>Volume<!5>"
    bass_title = "<C></5>Bass  <!5>"
    treble_title = "<C></5>Treble<!5>"
    box = params.box

    volume = RNDK::HISTOGRAM.new(rndkscreen, params.x_value, params.y_vol,
        params.h_value, params.w_value, RNDK::HORIZONTAL, volume_title,
        box, params.shadow)

    # Is the volume null?
    if volume.nil?
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot make volume histogram.  Is the window big enough?"
      exit #EXIT_FAILURE
    end

    bass = RNDK::HISTOGRAM.new(rndkscreen, params.x_value, params.y_bass,
        params.h_value, params.w_value, RNDK::HORIZONTAL, bass_title,
        box, params.shadow)

    if bass.nil?
      volume.destroy
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot make bass histogram.  Is the window big enough?"
      exit  # EXIT_FAILURE
    end


    treble = RNDK::HISTOGRAM.new(rndkscreen, params.x_value, params.y_treb,
        params.h_value, params.w_value, RNDK::HORIZONTAL, treble_title,
        box, params.shadow)

    if treble.nil?
      volume.destroy
      bass.destroy
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot make treble histogram.  Is the window big enough?"
      exit  # EXIT_FAILURE
    end

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 6,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 3,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 7,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 8,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 1,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 9,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 10,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 7,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 10,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 1,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 8,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 3,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 3,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 3,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 3,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Set the histogram values.
    volume.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 10,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    bass.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 10,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    treble.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 10,
        ' '.ord | Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(3), box)
    rndkscreen.refresh
    sleep(4)

    # Clean up
    volume.destroy
    bass.destroy
    treble.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    exit  # EXIT_SUCCESS
  end
end

HistogramExample.main
