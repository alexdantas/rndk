#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class PositionExample < Example
  def PositionExample.parse_opts(opts, param)
    opts.banner = 'Usage: position_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    param.w_value = 40

    super(opts, param)

    opts.on('-w WIDTH', OptionParser::DecimalInteger, 'Field width') do |w|
      param.w_value = w
    end
  end

  # This demonstrates the positioning of a Rndk entry field widget.
  def PositionExample.main
    label = "</U/5>Directory:<!U!5> "
    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the entry field widget.
    directory = RNDK::ENTRY.new(rndkscreen, params.x_value, params.y_value,
        '', label, Ncurses::A_NORMAL, '.', :MIXED, params.w_value, 0, 256,
        params.box, params.shadow)

    # Is the widget nil?
    if directory.nil?
      # Clean up.
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts "Cannot create the entry box. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    # Let the user move the widget around the window.
    directory.draw(directory.box)
    directory.position

    # Activate the entry field.
    info = directory.activate('')

    # Tell them what they typed.
    if directory.exit_type == :ESCAPE_HIT
      mesg = [
          "<C>You hit escape. No information passed back.",
          "",
          "<C>Press any key to continue."
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif directory.exit_type == :NORMAL
      mesg = [
          "<C>You typed in the following",
          "<C>%.*s" % [236, info],  # FIXME magic number
          "",
          "<C>Press any key to continue."
      ]
          rndkscreen.popupLabel(mesg, 4)
    end

    # Clean up
    directory.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

PositionExample.main
