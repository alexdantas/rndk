#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class ViewerExample < CLIExample
  def ViewerExample.parse_opts(opts, params)
    opts.banner = 'Usage: viewer_ex.rb [options]'

    # default values
    params.box = true
    params.shadow = false
    params.x_value = RNDK::CENTER
    params.y_value = RNDK::CENTER
    params.h_value = 20
    params.w_value = nil
    params.filename = ''
    params.directory = '.'
    params.interp = false
    params.link = false

    super(opts, params)

    opts.on('-f FILENAME', String, 'Filename to open') do |f|
      params.filename = f
    end

    opts.on('-d DIR', String, 'Default directory') do |d|
      params.directory = d
    end

    opts.on('-i', String, 'Interpret embedded markup') do
      params.interp = true
    end

    opts.on('-l', String, 'Load file via embedded link') do
      params.link = true
    end
  end

  # Demonstrate a scrolling-window.
  def ViewerExample.main
    title = "<C>Pick\n<C>A\n<C>File"
    label = 'File: '
    button = [
        '</5><OK><!5>',
        '</5><Cancel><!5>',
    ]

    # Declare variables.
    params = parse(ARGV)
    if params.w_value.nil?
      params.f_width = 65
      params.v_width = -2
    else
      params.f_width = params.w_value
      params.v_width = params.w_value
    end

    # Start curses
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Start RNDK colors.
    RNDK::Draw.initRNDKColor

    f_select = nil
    if params.filename == ''
      f_select = RNDK::FSELECT.new(rndkscreen, params.x_value, params.y_value,
          params.h_value, params.f_width, title, label, Ncurses::A_NORMAL,
          '_', Ncurses::A_REVERSE, '</5>', '</48>', '</N>', '</N',
          params.box, params.shadow)

      if f_select.nil?
        rndkscreen.destroy
        RNDK::Screen.end_rndk

        $stderr.puts 'Cannot create fselect-widget'
        exit  # EXIT_FAILURE
      end

      # Set the starting directory. This is not necessary because when
      # the file selector starts it uses the present directory as a default.
      f_select.set(params.directory, Ncurses::A_NORMAL, '.',
          Ncurses::A_REVERSE, '</5>', '</48>', '</N>', '</N>', @box)

      # Activate the file selector.
      params.filename = f_select.activate([])

      # Check how the person exited from the widget.
      if f_select.exit_type == :ESCAPE_HIT
        # Pop up a message for the user.
        mesg = [
            '<C>Escape hit. No file selected.',
            '',
            '<C>Press any key to continue.',
        ]
        rndkscreen.popupLabel(mesg, 3)

        # Exit RNDK.
        f_select.destroy
        rndkscreen.destroy
        RNDK::Screen.end_rndk
        exit  # EXIT_SUCCESS
      end
    end

    # Create the file viewer to view the file selected.
    example = RNDK::VIEWER.new(rndkscreen, params.x_value, params.y_value,
        params.h_value, params.v_width, button, 2, Ncurses::A_REVERSE,
        params.box, params.shadow)

    # Could we create the viewer widget?
    if example.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot create the viewer. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    info = []
    lines = -1
    # Load up the scrolling window.
    if params.link
      info = ['<F=%s>' % params.filename]
      params.interp = true
    else
      example.set('reading...', 0, 0, Ncurses::A_REVERSE, true, true, true)
      # Open the file and read the contents.
      lines = RNDK.readFile(params.filename, info)
      if lines == -1
        RNDK::Screen.end_rndk
        puts 'Could not open "%s"' % [params.filename]
        exit  # EXIT_FAILURE
      end
    end

    # Set up the viewer title and the contents to the widget.
    v_title = '<C></B/21>Filename:<!21></22>%20s<!22!B>' % [params.filename]
    example.set(v_title, info, lines, Ncurses::A_REVERSE, params.interp,
        true, true)

    # Destroy the file selector widget.
    unless f_select.nil?
      f_select.destroy
    end

    # Activate the viewer widget.
    selected = example.activate([])

    # Check how the person exited from the widget.
    if example.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>Escape hit. No Button selected..',
          '',
          '<C>Press any key to continue.',
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif example.exit_type == :NORMAL
      mesg = [
          '<C>You selected button %d' % [selected],
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up.
    example.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    exit  # EXIT_SUCCESS
  end
end

ViewerExample.main
