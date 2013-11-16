#!/usr/bin/env ruby
#
# Note: This is not for beginners! Check out the examples/
#       before adventuring into the demos/ realm!
#
# Shows a FSelect Widget, asking you to pick a file.
# Then, a Viewer Widget, showing that file's contents.
#
require 'optparse'
require 'rndk/fselect'

begin
  filename  = ''
  directory = '.'

  # Create the viewer buttons.
  button = [
            '</5><OK><!5>',
            '</5><Cancel><!5>',
           ]

  # Set up RNDK and Colors
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Get the filename
  if filename == ''
    title = '<C>Pick a file.'
    label = 'File: '
    fselect = RNDK::FSELECT.new(screen,
                                RNDK::CENTER,
                                RNDK::CENTER,
                                20,
                                65,
                                title,
                                label,
                                Ncurses::A_NORMAL,
                                '_',
                                Ncurses::A_REVERSE,
                                '</5>', '</48>', '</N>', '</N>',
                                true,
                                false)

    # Set the starting directory.  This is not necessary because when
    # the file selector starts it uses the present directory as a default.
    fselect.set(directory,
                Ncurses::A_NORMAL,
                '.',
                Ncurses::A_REVERSE,
                '</5>', '</48>',
                '</N>', '</N>',
                fselect.box)

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
      screen.popup_label(mesg, 3)

      fselect.destroy

      RNDK::Screen.end_rndk
      exit
    end
    fselect.destroy
  end

  # Create the file viewer to view the file selected.
  example = RNDK::Viewer.new(screen,
                             RNDK::CENTER,
                             RNDK::CENTER,
                             20,
                             -2,
                             button,
                             2,
                             Ncurses::A_REVERSE,
                             true,
                             false)

  # Could we create the viewer widget?
  if example.nil?
    RNDK::Screen.end_rndk

    puts "Cannot create viewer. Is the window too small?"
    exit 1
  end

  # Open the file and read the contents.

  info = []
  lines = RNDK.read_file(filename, info)
  if lines == -1
    puts "Could not open %s" % [filename]
    exit 1
  end

  # Set up the viewer title and the contents to the widget.
  title = '<C></B/22>%20s<!22!B> (If screen is messed up, press Ctrl+L)' % filename
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
    screen.popup_label mesg

  elsif example.exit_type == :NORMAL
    mesg = [
            '<C>You selected button %d' % [selected],
            '',
            '<C>Press any key to continue.',
           ]
    screen.popup_label mesg
  end

  # Clean up
  RNDK::Screen.end_rndk

# In case something goes wrong
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
end


