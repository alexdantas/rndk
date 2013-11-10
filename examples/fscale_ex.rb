#!/usr/bin/env ruby
require_relative 'example'

class FScaleExample < Example
  def FScaleExample.parse_opts(opts, param)
    opts.banner = 'Usage: fscale_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    param.high = 2.4
    param.low = -1.2
    param.inc = 0.2
    param.width = 10
    super(opts, param)

    opts.on('-h HIGH', OptionParser::DecimalNumeric, 'High value') do |h|
      param.high = h
    end

    opts.on('-l LOW', OptionParser::DecimalNumeric, 'Low value') do |l|
      param.low = l
    end

    opts.on('-i INC', OptionParser::DecimalNumeric, 'Increment amount') do |i|
      param.inc = i
    end

    opts.on('-w WIDTH', OptionParser::DecimalInteger, 'Widget width') do |w|
      param.width = w
    end
  end

  # This program demonstrates the Rndk label widget.
  def FScaleExample.main
    # Declare variables.
    title = '<C>Select a value'
    label = '</5>Current value'
    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the widget
    widget = RNDK::FSCALE.new(rndkscreen, params.x_value, params.y_value,
        title, label, Ncurses::A_NORMAL, params.width, params.low, params.low,
        params.high, params.inc, (params.inc * 2), 1, params.box, params.shadow)

    # Is the widget nll?
    if widget.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot make the scale widget. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    # Activate the widget.
    selection = widget.activate([])

    # Check the exit value of the widget.
    if widget.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>You hit escape. No value selected.',
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif widget.exit_type == :NORMAL
      mesg = [
          '<C>You selected %f' % selection,
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up
    widget.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

FScaleExample.main
