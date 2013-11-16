# The main RNDK module - contains everything we need.
#
# There's a lot of functionality inside RNDK. Besides
# each Widget having it's own file, some methods were
# splitted on several files:
#
# rndk/core/draw::      Common draw functions between Widgets.
# rndk/core/draw::      Color initialization and handling.
# rndk/core/display::   (??)
# rndk/core/traverse::
# rndk/core/widget::    Common functionality shared between widgets.
# rndk/core/screen::
# rndk/core/markup::    Functions to decode RNDK's markup language.
# rndk/core/utils::     Utility functions, not urgent or anything.
#
# ## Developer Notes
#
# * Any questions on what a `Ncurses.*` function do, check it's man
#   page with `man lowercase_function_name`.
#
require 'ffi-ncurses'
require 'scanf'

require 'rndk/core/draw'
require 'rndk/core/color'
require 'rndk/core/display'
require 'rndk/core/traverse'
require 'rndk/core/widget'
require 'rndk/core/screen'
require 'rndk/core/markup'
require 'rndk/core/utils'

# Shortcut to avoid typing FFI::NCurses all the time.
# You can use it too!
Ncurses = FFI::NCurses

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
  MAX_ButtonS  = 200

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

  # All the screens eventually created.
  ALL_SCREENS = []

  # All the widgets eventually created.
  ALL_WIDGETS = []

  # Beeps then flushes the stdout stream.
  #
  # Normally it emits an audible bell - if that's not
  # possible it flashes the screen.
  def RNDK.beep
    Ncurses.beep
    $stdout.flush
  end

  def RNDK.digit? character
    return false if character.nil?

    not character.match(/^[[:digit:]]$/).nil?
  end

  def RNDK.is_alpha? character
    return false if character.nil?

    not character.match(/^[[:alpha:]]$/).nil?
  end

  def RNDK.is_char? character
    return false if character.nil?

    (character >= 0) and (character < Ncurses::KEY_MIN)
  end

  # Returns the function keys - F1, F2 ... F12 ...
  def RNDK.KEY_F(n)
    264 + n
  end

  # This sets a blank string to be len of the given character.
  def RNDK.cleanChar(s, len, character)
    s << character * len
  end

  def RNDK.cleanChtype(s, len, character)
    s.concat(character * len)
  end

  # Functions that handle raw Ncurses windows.
  # TODO perhaps change them when I create my dedicated
  #      Window class.

  # Safely erases a raw Ncurses window.
  def RNDK.window_erase window
    return if window.nil?

    Ncurses.werase window
    Ncurses.wrefresh window
  end

  # Safely deletes a raw Ncurses window.
  def RNDK.window_delete window
    return if window.nil?

    RNDK.window_erase window
    Ncurses.delwin window
    window = nil
  end

  # Safely moves a raw Ncurses window.
  #
  # ## Developer Note:
  #
  # Moves a given window if we're able to set the window's beginning.
  # We do not use mvwin(), because it does not (usually) move subwindows.
  def RNDK.window_move(window, xdiff, ydiff)
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

  # Refreshes a raw Ncurses window.
  #
  # ## Developer Notes
  #
  # FIXME(original): this should be rewritten to use the panel library, so
  # it would not be necessary to touch the window to ensure that it covers
  # other windows.
  def RNDK.window_refresh win
    Ncurses.touchwin win
    Ncurses.wrefresh win
  end

  # Aligns a box on the given `window` with the width and height given.
  #
  # x and y position values are like `RNDK::CENTER`, `RNDK::LEFT`,
  # `RNDK::RIGHT`.
  #
  # `xpos`, `ypos` is an Array with exactly one value, an integer.
  #
  # `box_width`, `box_height` is an integer.
  #
  def RNDK.alignxy (window, xpos, ypos, box_width, box_height)

    # Handling xpos
    first = Ncurses.getbegx window
    last  = Ncurses.getmaxx window

    gap = 0 if (gap = (last - box_width)) < 0

    last = first + gap

    case xpos[0]
    when LEFT   then xpos[0] = first
    when RIGHT  then xpos[0] = first +  gap
    when CENTER then xpos[0] = first + (gap / 2)
    else
      xpos[0] = last  if xpos[0] > last
      xpos[0] = first if xpos[0] < first
    end

    # Handling ypos
    first = Ncurses.getbegy window
    last  = Ncurses.getmaxy window

    gap = 0 if (gap = (last - box_height)) < 0

    last = first + gap

    case ypos[0]
    when TOP    then ypos[0] = first
    when BOTTOM then ypos[0] = first +  gap
    when CENTER then ypos[0] = first + (gap / 2)
    else
      ypos[0] = last  if ypos[0] > last
      ypos[0] = first if ypos[0] < first
    end
  end

  # Sets on/off the blinking cursor.
  # @return The cursor's previous state.
  def RNDK.blink_cursor option
    ret = false
    if option
      ret = Ncurses.curs_set 1
    else
      ret = Ncurses.curs_set 0
    end

    if ret == 1 then true else false end
  end

end

