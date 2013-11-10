#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class MatrixExample < Example
  def MatrixExample.parse_opts(opts, param)
    opts.banner = 'Usage: matrix_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = true
    param.title =
        "<C>This is the RNDK\n<C>matrix widget.\n<C><#LT><#HL(30)><#RT>"
    param.cancel_title = false
    param.cancel_row = false
    param.cancel_col = false

    super(opts, param)

    opts.on('-T TITLE', String, 'Matrix title') do |title|
      param.title = title
    end

    opts.on('-t', 'Turn off matrix title') do
      param.cancel_title = true
    end

    opts.on('-c', 'Turn off column titles') do
      param.cancel_col = true
    end

    opts.on('-r', 'Turn off row titles') do
      param.cancel_row = true
    end
  end

  # This program demonstrates the Rndk calendar widget.
  def MatrixExample.main
    rows = 8
    cols = 5
    vrows = 3
    vcols = 5

    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    coltitle = []
    unless params.cancel_col
      coltitle = ['', '</B/5>Course', '</B/33>Lec 1', '</B/33>Lec 2',
          '</B/33>Lec 3', '</B/7>Flag']
    end
    colwidth = [0, 7, 7, 7, 7, 1]
    colvalue = [:UMIXED, :UMIXED, :UMIXED, :UMIXED, :UMIXED, :UMIXED]

    rowtitle = []
    unless params.cancel_row
      rowtitle << ''
      (1..rows).each do |x|
        rowtitle << '<C></B/6>Course %d' % [x]
      end
    end

    # Create the matrix object
    course_list = RNDK::MATRIX.new(rndkscreen, params.x_value, params.y_value,
        rows, cols, vrows, vcols,
        if params.cancel_title then '' else params.title end,
        rowtitle, coltitle, colwidth, colvalue, -1, -1, '.',
        2, params.box, params.box, params.shadow)

    if course_list.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts 'Cannot create the matrix widget. Is the window too small?'
      exit  # EXIT_FAILURE
    end

    # Activate the matrix
    course_list.activate([])

    # Check if the user hit escape or not.
    if course_list.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>You hit escape. No information passed back.',
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif course_list.exit_type == :NORMAL
      mesg = [
          '<L>You exited the matrix normally',
          'Current cell (%d,%d)' % [course_list.crow, course_list.ccol],
          '<L>To get the contents of the matrix cell, you can',
          '<L>use getCell():',
          course_list.getCell(course_list.crow, course_list.ccol),
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 7)
    end

    # Clean up
    course_list.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

MatrixExample.main
