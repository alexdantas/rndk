#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class SwindowExample < CLIExample
  def SwindowExample.parse_opts(opts, params)
    opts.banner = 'Usage: swindow_ex.rb [options]'

    # default values
    params.box = true
    params.shadow = false
    params.x_value = RNDK::CENTER
    params.y_value = RNDK::CENTER
    params.h_value = 6
    params.w_value = 65

    super(opts, params)
  end

  # Demonstrate a scrolling-window.
  def SwindowExample.main
    title = '<C></5>Error Log'

    # Declare variables.
    params = parse(ARGV)

    # Start curses
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Start RNDK colors.
    RNDK::Draw.initRNDKColor

    # Create the scrolling window.
    swindow = RNDK::SWINDOW.new(rndkscreen, params.x_value, params.y_value,
        params.h_value, params.w_value, title, 100, params.box, params.shadow)

    # Is the window nil.
    if swindow.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot create the scrolling window. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    # Draw the scrolling window.
    swindow.draw(swindow.box)

    # Load up the scrolling window.
    swindow.add('<C></11>TOP: This is the first line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second.', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<L></11>1: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<C></11>2: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second.', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<R></11>3: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<C></11>4: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second.', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<L></11>5: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<C></11>6: This is another line.', RNDK::BOTTOM)
    swindow.add('<C>Sleeping for 1 second.', RNDK::BOTTOM)
    sleep(1)

    swindow.add('<C>Done. You can now play.', RNDK::BOTTOM)

    swindow.add('<C>This is being added to the top.', RNDK::TOP)

    # Activate the scrolling window.
    swindow.activate([])

    # Check how the user exited this widget.
    if swindow.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>You hit escape to leave this widget.',
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif swindow.exit_type == :NORMAL
      mesg = [
          '<C>You hit return to exit this widget.',
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up.
    swindow.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    exit # EXIT_SUCCESS
  end
end

SwindowExample.main
