#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class MentryExample < Example
  def MentryExample.parse_opts(opts, param)
    opts.banner = 'Usage: mentry_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    param.w = 20
    param.h = 5
    param.rows = 20

    super(opts, param)

    opts.on('-w WIDTH', OptionParser::DecimalInteger, 'Field width') do |w|
      param.w = w
    end

    opts.on('-h HEIGHT', OptionParser::DecimalInteger, 'Field height') do |h|
      param.h = h
    end

    opts.on('-l ROWS', OptionParser::DecimalInteger, 'Logical rows') do |rows|
      param.rows = rows
    end
  end

  # This demonstrates the positioning of a Rndk multiple-line entry
  # field widget.
  def MentryExample.main
    label = "</R>Message"
    title = "<C></5>Enter a message.<!5>"

    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    widget = RNDK::MENTRY.new(rndkscreen, params.x_value, params.y_value,
        title, label, Ncurses::A_BOLD, '.', :MIXED, params.w, params.h,
        params.rows, 0, params.box, params.shadow)

    # Is the widget nil?
    if widget.nil?
      # Clean up.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot create RNDK object. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    # Draw the RNDK screen.
    rndkscreen.refresh

    # Set whatever was given from the command line.
    arg = if ARGV.size > 0 then ARGV[0] else '' end
    widget.set(arg, 0, true)

    # Activate the entry field.
    widget.activate('')
    info = widget.info.clone

    # Clean up.
    widget.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk

    puts "\n\n"
    puts "Your message was : <%s>" % [info]
    #ExitProgram (EXIT_SUCCESS);
  end
end

MentryExample.main
