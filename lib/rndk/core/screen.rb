require 'rndk/core/quick_widgets'

module RNDK

  # Placeholder for RNDK Widgets.
  #
  # Since all Widgets are bonded to a Screen, you pretty much
  # won't need to call any of the methods here.
  #
  # The only methods you should worry about are:
  #
  # * Screen#initialize
  # * Screen#finish
  # * Screen#draw or #refresh
  # * Screen#erase
  #
  # ## Developer Notes
  #
  # When a Widget is created, it calls Screen#register with it's
  # type and self pointer.
  #
  # That adds the widget pointer to an Array `@widget` that
  # contains all the widgets inside this screen.
  #
  # During it's lifetime, most widgets would call only Screen#erase
  # and Screen#refresh.
  #
  # When Widget#destroy is called, we call Screen#unregister to
  # remove it from the `@widget` array.
  #
  # Now, what happens when the Ruby garbage collector kills the
  # widget?
  #
  class Screen
    # Index of the current focused widget
    attr_accessor :widget_focus

    # How many widgets we currently have
    attr_accessor :widget_count

    # Maximum widget capacity of the screen (always expands)
    attr_accessor :widget_limit

    # Array with all the widgets currently on the screen
    attr_accessor :widget

    # Raw Ncurses window that represents this Screen
    attr_accessor :window

    # Nothing... for now
    attr_accessor :exit_status

    NOEXIT     = 0
    EXITOK     = 1
    EXITCANCEL = 2

    # Returns the whole terminal screen width.
    def self.width
      Ncurses.COLS
    end

    # Returns the whole terminal screen height.
    def self.height
      Ncurses.LINES
    end

    # Takes a Ncurses `WINDOW*` pointer and creates a CDKScreen.
    #
    # This also starts Ncurses, if it wasn't started before or
    # no `WINDOW*` were provided
    #
    def initialize(ncurses_window=nil)

      # If the user didn't start Ncurses for us,
      # we'll do it anyway.
      if RNDK::ALL_SCREENS.empty? or ncurses_window.nil?

        ## Why is this here?
        # Set up basic curses settings.
        # #ifdef HAVE_SETLOCALE
        # setlocale (LC_ALL, "");
        # #endif

        ncurses_window = Ncurses.initscr
        Ncurses.noecho
        Ncurses.cbreak
        Ncurses.keypad(ncurses_window, true)
      end

      RNDK::ALL_SCREENS << self
      @widget_count = 0
      @widget_limit = 2
      @widget = Array.new(@widget_limit, nil)
      @window = ncurses_window
      @widget_focus = 0
    end

    # Shuts down RNDK and Ncurses, plus destroying all the
    # widgets ever created.
    def self.finish

      ## If I do this it gives me a segmentation fault.
      ## I guess that would happen because of the
      ## ruby garbage collector.
      ##
      ## What should I do instead?
      #
      # RNDK::ALL_WIDGETS.each { |obj| obj.destroy }
      # RNDK::ALL_SCREENS.each { |scr| scr.destroy }

      Ncurses.echo
      Ncurses.nocbreak
      Ncurses.endwin
    end

    # Adds a Widget to this Screen.
    #
    # @note This is called automatically when a widget is created.
    #
    # * `rndktype` states what RNDK Widget type this widget is.
    # * `widget` is a pointer to the Widget itself.
    #
    def register(rndktype, widget)

      # Expanding the limit by 2
      if (@widget_count + 1) >= @widget_limit
        @widget_limit += 2
        @widget_limit *= 2
        @widget.concat Array.new(@widget_limit - @widget.size, nil)
      end

      if widget.valid_type?
        self.set_screen_index(@widget_count, widget)
        @widget_count += 1
      end
    end

    # Removes a Widget from this Screen.
    #
    # @note This is called automatically when a widget is destroyed.
    #
    # This does NOT destroy the widget, it removes the Widget
    # from any further refreshes by Screen#refresh.
    #
    # `rndktype` states what RNDK Widget type this widget is.
    # `widget` is a pointer to the Widget itself.
    #
    def unregister widget
      return unless (widget.valid_type? and (widget.screen_index >= 0))

      index = widget.screen_index
      widget.screen_index = -1

      # Resequence the widgets
      (index...self.widget_count - 1).each do |x|
        self.set_screen_index(x, self.widget[x+1])
      end

      if self.widget_count <= 1
        # if no more widgets, remove the array
        self.widget = []
        self.widget_count = 0
        self.widget_limit = 0

      else
        self.widget[self.widget_count] = nil
        self.widget_count -= 1

        # Update the widget-focus
        if self.widget_focus == index
          self.widget_focus -= 1
          Traverse.set_next_focus(screen)

        elsif self.widget_focus > index
          self.widget_focus -= 1
        end
      end
    end

    # Raises the Widget to the top of the screen.
    # It will now overlap any other obstructing Widgets.
    #
    # `rndktype` states what RNDK Widget type this widget is.
    # `widget` is a pointer to the Widget itself.
    #
    def self.raise_widget widget
      return unless widget.valid_type?

      screen = widget.screen
      screen.swap_indexes(widget.screen_index, screen.widget_count - 1)
    end

    # Has the opposite effect of #raise_widget.
    def self.lower_widget widget
      return unless widget.valid_type?

      widget.screen.swap_indexes(widget.screen_index, 0)
    end

    # Redraws all Widgets inside this Screen.
    def draw
      self.refresh
    end

    # Redraws all Widgets inside this Screen.
    def refresh
      focused = -1
      visible = -1

      RNDK.window_refresh(@window)

      # We erase all the invisible widgets, then only draw it all back, so
      # that the widgets can overlap, and the visible ones will always be
      # drawn after all the invisible ones are erased
      (0...@widget_count).each do |x|
        obj = @widget[x]
        if obj.valid_type?
          if obj.is_visible
            if visible < 0
              visible = x
            end
            if obj.has_focus && focused < 0
              focused = x
            end
          else
            obj.erase
          end
        end
      end

      (0...@widget_count).each do |x|
        obj = @widget[x]

        if obj.valid_type?
          obj.has_focus = (x == focused)

          if obj.is_visible
            obj.draw
          end
        end
      end
    end

    # Erases all Widgets inside this Screen.
    #
    # @note Erase in the sense of clearing the actual
    #       characters on the terminal screen.
    #       This does NOT destroy any widgets.
    def erase
      (0...@widget_count).each do |x|
        obj = @widget[x]
        obj.erase if obj.valid_type?
      end
      Ncurses.wrefresh(@window)
    end

    # Destroys all the Widgets inside this Screen.
    def destroy_widgets
      (0...@widget_count).each do |x|
        obj    = @widget[x]
        before = @widget_count

        if obj.valid_type?
          obj.erase
          obj.destroy
          x -= (@widget_count - before)
        end
      end
    end

    # Destroys this Screen.
    #
    # @note It does nothing to the widgets inside it.
    #       You must either destroy them separatedly
    #       or call #destroy_widgets before.
    def destroy
      RNDK::ALL_SCREENS.delete self
    end

    protected

    def set_screen_index(number, obj)
      obj.screen_index = number
      obj.screen = self
      @widget[number] = obj
    end

    def valid_index? n
      (n >= 0) and (n < @widget_count)
    end

    # Swap positions of widgets with indexes `n1` and `n2`.
    def swap_indexes(n1, n2)
      return unless (n1 != n2) and (self.valid_index? n1) and (self.valid_index? n2)

      o1 = @widget[n1]
      o2 = @widget[n2]
      self.set_screen_index(n1, o2)
      self.set_screen_index(n2, o1)

      if @widget_focus == n1
        @widget_focus = n2

      elsif @widget_focus == n2
        @widget_focus = n1
      end
    end

  end
end

