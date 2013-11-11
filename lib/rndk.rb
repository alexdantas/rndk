# Welcome to the Ruby Ncurses Development Kit!

require 'ffi-ncurses'
require 'scanf'

require 'rndk/core/draw'
require 'rndk/core/display'
require 'rndk/core/traverse'
require 'rndk/core/widget'
require 'rndk/core/screen'
require 'rndk/core/markup'
require 'rndk/core/utils'

# Shortcut to avoid typing FFI::NCurses all the time.
# You can use it too!
Ncurses = FFI::NCurses

# The main RNDK module - contains everything we need.
#
# There's a lot of functionality inside RNDK. Besides
# each Widget having it's own file, some methods were
# splitted on several files:
#
# * rndk/core/draw::
# * rndk/core/display::
# * rndk/core/traverse::
# * rndk/core/widget::    Common functionality shared between widgets.
# * rndk/core/screen::
# * rndk/core/markup::    Functions to decode RNDK's markup language.
# * rndk/core/utils::     Utility functions, not urgent or anything.
#
# ## Developer Notes
#
# * Any questions on what a `Ncurses.*` function do, check it's man
#   page with `man lowercase_function_name`.
#
module RNDK

  # Some nice global constants.

  RNDK_PATHMAX = 256

  L_MARKER = '<'
  R_MARKER = '>'

  LEFT       = 9000
  RIGHT      = 9001
  CENTER     = 9002
  TOP        = 9003
  BOTTOM     = 9004
  HORIZONTAL = 9005
  VERTICAL   = 9006
  FULL       = 9007

  NONE = 0
  ROW  = 1
  COL  = 2

  MAX_BINDINGS = 300
  MAX_ITEMS    = 2000
  MAX_BUTTONS  = 200

  # Key value when pressing Ctrl+`char`.
  def RNDK.CTRL(char)
    char.ord & 0x1f
  end

  # Aliasing the default keybindings
  # for Widget interaction.
  #
  # Example:  `RNDK.CTRL('L')` is `Ctrl+L` or `C-l`
  REFRESH    = RNDK.CTRL('L')
  PASTE      = RNDK.CTRL('V')
  COPY       = RNDK.CTRL('Y')
  ERASE      = RNDK.CTRL('U')
  CUT        = RNDK.CTRL('X')
  BEGOFLINE  = RNDK.CTRL('A')
  ENDOFLINE  = RNDK.CTRL('E')
  BACKCHAR   = RNDK.CTRL('B')
  FORCHAR    = RNDK.CTRL('F')
  TRANSPOSE  = RNDK.CTRL('T')
  NEXT       = RNDK.CTRL('N')
  PREV       = RNDK.CTRL('P')
  DELETE     = "\177".ord
  KEY_ESC    = "\033".ord
  KEY_RETURN = "\012".ord
  KEY_TAB    = "\t".ord

  ALL_SCREENS = []
  ALL_OBJECTS = []

  # This beeps then flushes the stdout stream.
  #
  # Normally it emits an audible bell - if that's not
  # possible it flashes the screen.
  def RNDK.beep
    Ncurses.beep
    $stdout.flush
  end

  # This sets a blank string to be len of the given characer.
  def RNDK.cleanChar(s, len, character)
    s << character * len
  end

  def RNDK.cleanChtype(s, len, character)
    s.concat(character * len)
  end

  # This takes an x and y position and realigns the values iff they sent in
  # values like CENTER, LEFT, RIGHT
  #
  # window is an Ncurses::WINDOW object
  # xpos, ypos is an array with exactly one value, an integer
  # box_width, box_height is an integer
  def RNDK.alignxy (window, xpos, ypos, box_width, box_height)
    first = Ncurses.getbegx window
    last = Ncurses.getmaxx window
    if (gap = (last - box_width)) < 0
      gap = 0
    end
    last = first + gap

    case xpos[0]
    when LEFT
      xpos[0] = first
    when RIGHT
      xpos[0] = first + gap
    when CENTER
      xpos[0] = first + (gap / 2)
    else
      if xpos[0] > last
        xpos[0] = last
      elsif xpos[0] < first
        xpos[0] = first
      end
    end

    first = Ncurses.getbegy window
    last = Ncurses.getmaxy window
    if (gap = (last - box_height)) < 0
      gap = 0
    end
    last = first + gap

    case ypos[0]
    when TOP
      ypos[0] = first
    when BOTTOM
      ypos[0] = first + gap
    when CENTER
      ypos[0] = first + (gap / 2)
    else
      if ypos[0] > last
        ypos[0] = last
      elsif ypos[0] < first
        ypos[0] = first
      end
    end
  end

  # This reads a file and sticks it into the list provided.
  def RNDK.readFile(filename, array)
    begin
      fd = File.new(filename, "r")
    rescue
      return -1
    end

    lines = fd.readlines.map do |line|
      if line.size > 0 && line[-1] == "\n"
        line[0...-1]
      else
        line
      end
    end
    array.concat(lines)
    fd.close
    array.size
  end

  def RNDK.CharOf(chtype)
    (chtype.ord & 255).chr
  end

  # This safely erases a given window
  def RNDK.eraseCursesWindow (window)
    return if window.nil?

    Ncurses.werase window
    Ncurses.wrefresh window
  end

  # This safely deletes a given window.
  def RNDK.deleteCursesWindow (window)
    return if window.nil?

    RNDK.eraseCursesWindow(window)
    Ncurses.delwin window
  end

  # This moves a given window (if we're able to set the window's beginning).
  # We do not use mvwin(), because it does not (usually) move subwindows.
  def RNDK.moveCursesWindow (window, xdiff, ydiff)
    return if window.nil?

    xpos = []
    ypos = []
    Ncurses.getbegyx(window, ypos, xpos)
    if Ncurses.mvwin(window, ypos[0], xpos[0]) != Ncurses::ERR
      xpos[0] += xdiff
      ypos[0] += ydiff
      Ncurses.werase window
      Ncurses.mvwin(window, ypos[0], xpos[0])
    else
      RNDK.beep
    end
  end

  def RNDK.digit? character
    false if character.nil?
    !(character.match(/^[[:digit:]]$/).nil?)
  end

  def RNDK.alpha? character
    false if character.nil?
    !(character.match(/^[[:alpha:]]$/).nil?)
  end

  def RNDK.isChar c
    false if c.nil?
    c >= 0 && c < Ncurses::KEY_MIN
  end

  # Returns the function keys - F1, F2 ... F12 ...
  def RNDK.KEY_F(n)
    264 + n
  end

  def RNDK.getString(screen, title, label, init_value)
    # Create the widget.
    widget = RNDK::ENTRY.new(screen, RNDK::CENTER, RNDK::CENTER, title, label,
        Ncurses::A_NORMAL, '.', :MIXED, 40, 0, 5000, true, false)

    # Set the default value.
    widget.setValue(init_value)

    # Get the string.
    value = widget.activate([])

    # Make sure they exited normally.
    if widget.exit_type != :NORMAL
      widget.destroy
      return nil
    end

    # Return a copy of the string typed in.
    value = entry.getValue.clone
    widget.destroy
    return value
  end

  # This allows a person to select a file.
  def RNDK.selectFile(screen, title)
    # Create the file selector.
    fselect = RNDK::FSELECT.new(screen, RNDK::CENTER, RNDK::CENTER, -4, -20,
        title, 'File: ', Ncurses::A_NORMAL, '_', Ncurses::A_REVERSE,
        '</5>', '</48>', '</N>', '</N>', true, false)

    # Let the user play.
    filename = fselect.activate([])

    # Check the way the user exited the selector.
    if fselect.exit_type != :NORMAL
      fselect.destroy
      screen.refresh
      return nil
    end

    # Otherwise...
    fselect.destroy
    screen.refresh
    return filename
  end

  # This returns a selected value in a list
  def RNDK.getListindex(screen, title, list, list_size, numbers)
    selected = -1
    height = 10
    width = -1
    len = 0

    # Determine the height of the list.
    if list_size < 10
      height = list_size + if title.size == 0 then 2 else 3 end
    end

    # Determine the width of the list.
    list.each do |item|
      width = [width, item.size + 10].max
    end

    width = [width, title.size].max
    width += 5

    # Create the scrolling list.
    scrollp = RNDK::SCROLL.new(screen, RNDK::CENTER, RNDK::CENTER, RNDK::RIGHT,
        height, width, title, list, list_size, numbers, Ncurses::A_REVERSE,
        true, false)

    # Check if we made the lsit.
    if scrollp.nil?
      screen.refresh
      return -1
    end

    # Let the user play.
    selected = scrollp.activate([])

    # Check how they exited.
    if scrollp.exit_type != :NORMAL
      selected = -1
    end

    # Clean up.
    scrollp.destroy
    screen.refresh
    return selected
  end
end

# Why is this here?
#
# require 'rndk/alphalist'
# require 'rndk/button'
# require 'rndk/buttonbox'
# require 'rndk/calendar'
# require 'rndk/dialog'
# require 'rndk/dscale'
# require 'rndk/entry'
# require 'rndk/fscale'
# require 'rndk/fslider'
# require 'rndk/fselect'
# require 'rndk/graph'
# require 'rndk/histogram'
# require 'rndk/itemlist'
# require 'rndk/label'
# require 'rndk/marquee'
# require 'rndk/matrix'
# require 'rndk/mentry'
# require 'rndk/menu'
# require 'rndk/radio'
# require 'rndk/scale'
# require 'rndk/scroll'
# require 'rndk/selection'
# require 'rndk/slider'
# require 'rndk/swindow'
# require 'rndk/template'
# require 'rndk/uscale'
# require 'rndk/uslider'
# require 'rndk/viewer'

