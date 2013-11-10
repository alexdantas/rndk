#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class USliderExample < Example
  def USliderExample.parse_opts(opts, param)
    opts.banner = 'Usage: uslider_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    param.high = 100
    param.low = 1
    param.inc = 1
    param.width = 50
    super(opts, param)

    opts.on('-h HIGH', OptionParser::DecimalInteger, 'High value') do |h|
      param.high = h
    end

    opts.on('-l LOW', OptionParser::DecimalInteger, 'Low value') do |l|
      param.low = l
    end

    opts.on('-i INC', OptionParser::DecimalInteger, 'Increment amount') do |i|
      param.inc = i
    end

    opts.on('-w WIDTH', OptionParser::DecimalInteger, 'Widget width') do |w|
      param.width = w
    end
  end

  # This program demonstrates the Rndk slider widget.
  def USliderExample.main
    # Declare variables.
    label = '</B>Current Value:'
    params = parse(ARGV)
    title = "<C></U>Enter a value:\nLow  %#x\nHigh%#x" %
        [params.low, params.high]

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the widget
    widget = RNDK::USLIDER.new(rndkscreen, params.x_value, params.y_value,
        title, label,
        Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(29) | ' '.ord,
        params.width, params.low, params.low, params.high, params.inc,
        (params.inc * 2), params.box, params.shadow)

    # Is the widget nll?
    if widget.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot make the widget. Is the window too small?"
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
          '<C>You selected %d' % selection,
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up
    widget.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    #ExitProgram (EXIT_SUCCESS);
  end
end

USliderExample.main
