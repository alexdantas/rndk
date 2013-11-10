#!/usr/bin/env ruby
#
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require 'optparse'
require 'rndk'

class FileView
  def FileView.main
    params = OptionParser.getopts('d:f:')
    filename = params['f'] || ''
    directory = params['d'] || '.'

    # Create the viewer buttons.
    button = [
        '</5><OK><!5>',
        '</5><Cancel><!5>',
    ]

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Get the filename
    if filename == ''
      title = '<C>Pick a file.'
      label = 'File: '
      fselect = RNDK::FSELECT.new(rndkscreen, RNDK::CENTER, RNDK::CENTER,
          20, 65, title, label, Ncurses::A_NORMAL, '_', Ncurses::A_REVERSE,
          '</5>', '</48>', '</N>', '</N>', true, false)

      # Set the starting directory.  This is not necessary because when
      # the file selector starts it uses the present directory as a default.
      fselect.set(directory, Ncurses::A_NORMAL, '.', Ncurses::A_REVERSE,
          '</5>', '</48>', '</N>', '</N>', fselect.box)

      # Activate the file selector.
      filename = fselect.activate([])

      # Check how the person exited from the widget.
      if fselect.exit_type == :ESCAPE_HIT
        # pop up a message for the user.
        mesg = [
            '<C>Escape hit. No file selected.',
            '',
            '<C>Press any key to continue.',
        ]
        rndkscreen.popupLabel(mesg, 3)

        fselect.destroy

        rndkscreen.destroy
        RNDK::SCREEN.endRNDK

        exit  # EXIT_SUCCESS
      end

      fselect.destroy
    end

    # Create the file viewer to view the file selected.
    example = RNDK::VIEWER.new(rndkscreen, RNDK::CENTER, RNDK::CENTER, 20, -2,
        button, 2, Ncurses::A_REVERSE, true, false)

    # Could we create the viewer widget?
    if example.nil?
      # Clean up the memory.
      rndkscreen.destroy

      # End curses...
      RNDK.endRNDK

      puts "Cannot create viewer. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    # Open the file and read the contents.

    info = []
    lines = RNDK.readFile(filename, info)
    if lines == -1
      puts "Could not open %s" % [filename]
      exit  # EXIT_FAILURE
    end

    # Set up the viewer title and the contents to the widget.
    title = '<C></B/22>%20s<!22!B>' % filename
    example.set(title, info, lines, Ncurses::A_REVERSE, true, true, true)

    # Activate the viewer widget.
    selected = example.activate([])

    # Check how the person exited from the widget.
    if example.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>Escape hit. No Button selected.',
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif example.exit_type == :NORMAL
      mesg = [
          '<C>You selected button %d' % [selected],
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up
    example.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

FileView.main
