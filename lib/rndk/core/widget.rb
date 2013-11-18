require 'rndk'
require 'rndk/core/widget_bind'

module RNDK

  # Wrapper on common functionality between all RNDK Widgets.
  #
  class Widget
    # Which widget this is.
    # It's the name of the widget lowercased.
    # Example: `:label`, `:calendar`, `:alphalist`
    attr_reader :widget_type

    attr_accessor :screen_index, :screen, :has_focus, :is_visible, :box
    attr_accessor :ULChar, :URChar, :LLChar, :LRChar, :HZChar, :VTChar, :BXAttr
    attr_reader :binding_list, :accepts_focus, :exit_type, :border_size

    # All the signals the current widget supports.
    # Use them on Widget#bind_signal
    attr_reader :supported_signals

    @@g_paste_buffer = ''

    def initialize
      @has_focus  = true
      @is_visible = true

      RNDK::ALL_WIDGETS << self

      # set default line-drawing characters
      @ULChar = Ncurses::ACS_ULCORNER
      @URChar = Ncurses::ACS_URCORNER
      @LLChar = Ncurses::ACS_LLCORNER
      @LRChar = Ncurses::ACS_LRCORNER
      @HZChar = Ncurses::ACS_HLINE
      @VTChar = Ncurses::ACS_VLINE
      @BXAttr = RNDK::Color[:normal]

      # set default exit-types
      @exit_type  = :NEVER_ACTIVATED
      @early_exit = :NEVER_ACTIVATED

      @accepts_focus = false

      # Bound functions
      @binding_list = {}

      # Actions to be executed at certain signals
      @actions = {}

      @supported_signals = [:destroy,
                            :before_leaving,
                            :after_leaving]
    end

    # Makes `block` execute right before processing input
    # on the Widget.
    #
    # `block` is called with the following arguments:
    #
    # * The Widget type (`:scroll`, `:calendar`, etc)
    # * The Widget itself (`self`)
    # * That `data` you send as an argument to `before_processing`.
    # * The input character the Widget just received.
    #
    # Make good use of them when making your callback.
    def before_processing(data=nil, &block)
      @pre_process_data = data
      @pre_process_func = block
    end

    # Makes `block` execute right after processing input
    # on the Widget.
    #
    # `block` is called with the following arguments:
    #
    # * The Widget type (`:scroll`, `:calendar`, etc)
    # * The Widget itself (`self`)
    # * That `data` you send as an argument to `after_processing`.
    # * The input character the Widget just received.
    #
    # Make good use of them when making your callback.
    def after_processing(data=nil, &block)
      @post_process_data = data
      @post_process_func = block
    end

    def widget_type
      # no type by default
      :NULL
    end

    def Screen_XPOS(n)
      n + @border_size
    end

    def Screen_YPOS(n)
      n + @border_size + @title_lines
    end

    def draw(a)
    end

    # Erases the Widget from the Screen.
    # @note It does not destroy the Widget.
    def erase
    end

    # Moves the Widget to the given position.
    #
    # * `x` and `y` are the new position of the Widget.
    #
    # * `x` may be an integer or one of the pre-defined
    #   values `RNDK::TOP`, `RNDK::BOTTOM`, and `RNDK::CENTER`.
    #
    # * `y` may be an integer or one of the pre-defined
    #   values `RNDK::LEFT`, `RNDK::RIGHT`, and `RNDK::CENTER`.
    #
    # * `relative` states whether the `x`/`y` pair is a
    #   relative move over it's current position or an absolute move
    #   over the Screen's top.
    #
    # For example, if `x = 1` and `y = 2` and `relative = true`,
    # the Widget would move one row down and two columns right.
    #
    # If the value of relative was `false` then the widget would move to
    # the position `(1,2)`.
    #
    # Do not use the values `TOP`, `BOTTOM`, `LEFT`, `RIGHT`, or `CENTER`
    # when `relative = true` - weird things may happen.
    #
    # * `refresh_flag` is a boolean value which states whether the
    #   Widget will get refreshed after the move.
    #
    def move(x, y, relative, refresh_flag)
      self.move_specific(x, y, relative, refresh_flag, [@win, @shadow_win], [])
    end

    # Set the widget's title.
    def set_title(title, box_width)
      return if title.nil?

      temp = title.split "\n"
      @title_lines = temp.size

      if box_width >= 0
        max_width = 0
        temp.each do |line|
          len = []
          align = []
          holder = RNDK.char2Chtype(line, len, align)
          max_width = [len[0], max_width].max
        end
        box_width = [box_width, max_width + 2 * @border_size].max
      else
        box_width = -(box_width - 1)
      end

      # For each line in the title convert from string to chtype array
      title_width = box_width - (2 * @border_size)
      @title = []
      @title_pos = []
      @title_len = []
      (0...@title_lines).each do |x|
        len_x = []
        pos_x = []
        @title << RNDK.char2Chtype(temp[x], len_x, pos_x)
        @title_len.concat(len_x)
        @title_pos << RNDK.justifyString(title_width, len_x[0], pos_x[0])
      end
      box_width
    end

    # Draw the widget's title
    def draw_title(win)
      (0...@title_lines).each do |x|
        Draw.writeChtype(@win, @title_pos[x] + @border_size,
            x + @border_size, @title[x], RNDK::HORIZONTAL, 0,
            @title_len[x])
      end
    end

    # Makes the Widget react to `char` just as if the user
    # had pressed it.
    #
    # Nice to simulate batch actions on a Widget.
    #
    # Besides normal keybindings (arrow keys and such), see
    # Widget#set_exit_type to see how the Widget exits.
    #
    def inject input
    end

    # Makes the widget have a border if `box` is true,
    # otherwise, cancel it.
    def set_box box
      @box = box
      @border_size = if @box then 1 else 0 end
    end

    # Tells if the widget has borders.
    def get_box
      return @box
    end

    def focus
    end

    def unfocus
    end

    # Somehow saves all data within this Widget.
    #
    # @note This method isn't called whatsoever!
    #       It only exists at Traverse module.
    #
    # TODO Find out how can I insert this on Widgets.
    def save_data
    end


    # Somehow refreshes all data within this Widget.
    #
    # @note This method isn't called whatsoever!
    #       It only exists at Traverse module.
    #
    # TODO Find out how can I insert this on Widgets.
    def refresh_data
    end

    # Destroys all windows inside the Widget and
    # removes it from the Screen.
    def destroy
    end

    # Set the widget's upper-left-corner line-drawing character.
    def setULchar(ch)
      @ULChar = ch
    end

    # Set the widget's upper-right-corner line-drawing character.
    def setURchar(ch)
      @URChar = ch
    end

    # Set the widget's lower-left-corner line-drawing character.
    def setLLchar(ch)
      @LLChar = ch
    end

    # Set the widget's upper-right-corner line-drawing character.
    def setLRchar(ch)
      @LRChar = ch
    end

    # Set the widget's horizontal line-drawing character
    def setHZchar(ch)
      @HZChar = ch
    end

    # Set the widget's vertical line-drawing character
    def setVTchar(ch)
      @VTChar = ch
    end

    # Set the widget's box-attributes.
    def setBXattr(ch)
      @BXAttr = ch
    end

    # This sets the background color of the widget.
    #
    # FIXME BUG
    def set_bg_color color
      return if color.nil? || color == ''

      junk1 = []
      junk2 = []

      # Convert the value of the environment variable to a chtype
      holder = RNDK.char2Chtype(color, junk1, junk2)

      # Set the widget's background color

      ## FIXME BUG WTF
      ## What does this function do?
      ## Couldn't find anything on it
      self.SetBackAttrObj(holder[0])
    end

    # Remove storage for the widget's title.
    def clean_title
      @title_lines = ''
    end

    # Set the Widget#exit_type based on the input `char`.
    #
    # According to default keybindings, if `char` is:
    #
    # RETURN or TAB:: Sets `:NORMAL`.
    # ESCAPE::        Sets `:ESCAPE_HIT`.
    # Otherwise::     Unless treated specifically by the
    #                 Widget, sets `:EARLY_EXIT`.
    #
    def set_exit_type char
      case char
      when Ncurses::ERR  then @exit_type = :ERROR
      when RNDK::KEY_ESC then @exit_type = :ESCAPE_HIT
      when 0             then @exit_type = :EARLY_EXIT
      when RNDK::KEY_TAB, Ncurses::KEY_ENTER, RNDK::KEY_RETURN
        @exit_type = :NORMAL
      end
    end

    # FIXME TODO What does `function_key` does?
    def getch(function_key=[])
      key = self.getc
      function_key << (key >= Ncurses::KEY_MIN && key <= Ncurses::KEY_MAX)

      key
    end

    # Allows the user to move the Widget around
    # the screen via the cursor/keypad keys.
    #
    # `win` is the main window of the Widget - from which
    # subwins derive.
    #
    # The following key bindings can be used to move the
    # Widget around the screen:
    #
    # Up Arrow::    Moves the widget up one row.
    # Down Arrow::  Moves the widget down one row.
    # Left Arrow::  Moves the widget left one column
    # Right Arrow:: Moves the widget right one column
    # 1::           Moves the widget down one row and left one column.
    # 2::           Moves the widget down one row.
    # 3::           Moves the widget down one row and right one column.
    # 4::           Moves the widget left one column.
    # 5::           Centers the widget both vertically and horizontally.
    # 6::           Moves the widget right one column
    # 7::           Moves the widget up one row and left one column.
    # 8::           Moves the widget up one row.
    # 9::           Moves the widget up one row and right one column.
    # t::           Moves the widget to the top of the screen.
    # b::           Moves the widget to the bottom of the screen.
    # l::           Moves the widget to the left of the screen.
    # r::           Moves the widget to the right of the screen.
    # c::           Centers the widget between the left and right of the window.
    # C::           Centers the widget between the top and bottom of the window.
    # Escape::      Returns the widget to its original position.
    # Return::      Exits the function and leaves the Widget where it was.
    #
    def position win
      parent = @screen.window
      orig_x = Ncurses.getbegx win
      orig_y = Ncurses.getbegy win
      beg_x = Ncurses.getbegx parent
      beg_y = Ncurses.getbegy parent
      end_x = beg_x + Ncurses.getmaxx(@screen.window)
      end_y = beg_y + Ncurses.getmaxy(@screen.window)

      loop do
        key = self.getch

        # Let them move the widget around until they hit return.
        break if [RNDK::KEY_RETURN, Ncurses::KEY_ENTER].include? key

        case key
        when Ncurses::KEY_UP, '8'.ord
          if Ncurses.getbegy(win) > beg_y
            self.move(0, -1, true, true)
          else
            RNDK.beep
          end
        when Ncurses::KEY_DOWN, '2'.ord
          if (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(0, 1, true, true)
          else
            RNDK.beep
          end
        when Ncurses::KEY_LEFT, '4'.ord
          if Ncurses.getbegx(win) > beg_x
            self.move(-1, 0, true, true)
          else
            RNDK.beep
          end
        when Ncurses::KEY_RIGHT, '6'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x
            self.move(1, 0, true, true)
          else
            RNDK.beep
          end
        when '7'.ord
          if Ncurses.getbegy(win) > beg_y && Ncurses.getbegx(win) > beg_x
            self.move(-1, -1, true, true)
          else
            RNDK.beep
          end
        when '9'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x && Ncurses.getbegy(win) > beg_y
            self.move(1, -1, true, true)
          else
            RNDK.beep
          end
        when '1'.ord
          if Ncurses.getbegx(win) > beg_x && (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(-1, 1, true, true)
          else
            RNDK.beep
          end
        when '3'.ord
          if (Ncurses.getbegx(win) + Ncurses.getmaxx(win)) < end_x &&
              (Ncurses.getbegy(win) + Ncurses.getmaxy(win)) < end_y
            self.move(1, 1, true, true)
          else
            RNDK.beep
          end

        when '5'.ord
          self.move(RNDK::CENTER, RNDK::CENTER, false, true)

        when 't'.ord
          self.move(Ncurses.getbegx(win), RNDK::TOP, false, true)

        when 'b'.ord
          self.move(Ncurses.getbegx(win), RNDK::BOTTOM, false, true)

        when 'l'.ord
          self.move(RNDK::LEFT, Ncurses.getbegy(win), false, true)

        when 'r'.ord
          self.move(RNDK::RIGHT, Ncurses.getbegy(win), false, true)

        when 'c'.ord
          self.move(RNDK::CENTER, Ncurses.getbegy(win), false, true)

        when 'C'.ord
          self.move(Ncurses.getbegx(win), RNDK::CENTER, false, true)

        when RNDK::REFRESH
          @screen.erase
          @screen.refresh

        when RNDK::KEY_ESC
          self.move(orig_x, orig_y, false, true)
        else
          RNDK.beep
        end
      end
    end

    # Tells if a widget is valid.
    def valid?
      RNDK::ALL_WIDGETS.include?(self) and self.valid_type?
    end

    # Tells if current widget's type is the
    # type of an existing Widget.
    def valid_type?
      [:graph,
       :histogram,
       :label,
       :marquee,
       :viewer,
       :alphalist,
       :button,
       :buttonbox,
       :calendar,
       :dialog,
       :dscale,
       :entry,
       :fscale,
       :fselect,
       :fslider,
       :itemlist,
       :matrix,
       :mentry,
       :radio,
       :scale,
       :scroll,
       :selection,
       :slider,
       :swindow,
       :template,
       :uscale,
       :uslider].include? @widget_type
    end

    protected

    # Actually moves the widget.
    def move_specific(x, y, relative, refresh_flag, windows, subwidgets)
      current_x = Ncurses.getbegx @win
      current_y = Ncurses.getbegy @win
      xpos = x
      ypos = y

      # If this is a relative move, then we will adjust where we want
      # to move to.
      if relative
        xpos = Ncurses.getbegx(@win) + x
        ypos = Ncurses.getbegy(@win) + y
      end

      # Adjust the window if we need to
      xtmp = [xpos]
      ytmp = [ypos]
      RNDK.alignxy(@screen.window, xtmp, ytmp, @box_width, @box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Get the difference
      xdiff = current_x - xpos
      ydiff = current_y - ypos

      # Move the window to the new location.
      windows.each do |window|
        RNDK.window_move(window, -xdiff, -ydiff)
      end

      subwidgets.each do |subwidget|
        subwidget.move(x, y, relative, false)
      end

      # Touch the windows so they 'move'
      RNDK.window_refresh @screen.window

      # Redraw the window, if they asked for it
      if refresh_flag
        self.draw
      end
    end

    # Gets a raw character from internal Ncurses window
    # and returns the result, capped to sane values.
    def getc
      rndktype = self.widget_type
      test   = self.bindable_widget rndktype
      result = Ncurses.wgetch @input_window

      if (result >= 0) and
          (not test.nil?) and
          (test.binding_list.include? result) and
          (test.binding_list[result][0] == :getc)

        result = test.binding_list[result][1]

      elsif (test.nil?) or
          (not test.binding_list.include? result) or
          (test.binding_list[result][0].nil?)

        case result
        when "\r".ord, "\n".ord then result = Ncurses::KEY_ENTER
        when "\t".ord           then result = RNDK::KEY_TAB
        when RNDK::DELETE       then result = Ncurses::KEY_DC
        when "\b".ord           then result = Ncurses::KEY_BACKSPACE
        when RNDK::BEGOFLINE    then result = Ncurses::KEY_HOME
        when RNDK::ENDOFLINE    then result = Ncurses::KEY_END
        when RNDK::FORCHAR      then result = Ncurses::KEY_RIGHT
        when RNDK::BACKCHAR     then result = Ncurses::KEY_LEFT
        when RNDK::NEXT         then result = RNDK::KEY_TAB
        when RNDK::PREV         then result = Ncurses::KEY_BTAB
        end
      end

      return result
    end

  end
end

