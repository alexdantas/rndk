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
  # * Screen#end_rndk
  # * Screen#draw or #refresh
  # * Screen#erase
  #
  # ## Developer Notes
  #
  # If you want to create your own Widget, you'll need to
  # call some methods in here to register/unregister it
  # to a Screen.
  #
  class Screen
    attr_accessor :object_focus, :object_count, :object_limit, :object, :window
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
      if RNDK::ALL_SCREENS.size == 0 or ncurses_window.nil?

        ## Why is this here?
        # Set up basic curses settings.
        # #ifdef HAVE_SETLOCALE
        # setlocale (LC_ALL, "");
        # #endif

        ncurses_window = Ncurses.initscr
        Ncurses.noecho
        Ncurses.cbreak
      end

      RNDK::ALL_SCREENS << self
      @object_count = 0
      @object_limit = 2
      @object = Array.new(@object_limit, nil)
      @window = ncurses_window
      @object_focus = 0
    end

    # Shuts down RNDK and Ncurses.
    def self.end_rndk
      Ncurses.echo
      Ncurses.nocbreak
      Ncurses.endwin
    end

    # Adds a Widget to this Screen.
    #
    # @note This is called automatically when a widget is created.
    #
    # `rndktype` states what RNDK Widget type this object is.
    # `object` is a pointer to the Widget itself.
    #
    def register(rndktype, object)
      if @object_count + 1 >= @object_limit
        @object_limit += 2
        @object_limit *= 2
        @object.concat Array.new(@object_limit - @object.size, nil)
      end

      if object.valid_widget_type?(rndktype)
        self.setScreenIndex(@object_count, object)
        @object_count += 1
      end
    end

    # Removes a Widget from the Screen.
    #
    # @note This is called automatically when a widget is destroyed.
    #
    # This does NOT destroy the object, it removes the Widget
    # from any further refreshes by Screen#refresh.
    #
    # `rndktype` states what RNDK Widget type this object is.
    # `object` is a pointer to the Widget itself.
    #
    def self.unregister(rndktype, object)
      return if not (object.valid_widget_type?(rndktype) && object.screen_index >= 0)

      screen = object.screen
      return if screen.nil?

      index = object.screen_index
      object.screen_index = -1

      # Resequence the objects
      (index...screen.object_count - 1).each do |x|
        screen.setScreenIndex(x, screen.object[x+1])
      end

      if screen.object_count <= 1
        # if no more objects, remove the array
        screen.object = []
        screen.object_count = 0
        screen.object_limit = 0
      else
        screen.object[screen.object_count] = nil
        screen.object_count -= 1

        # Update the object-focus
        if screen.object_focus == index
          screen.object_focus -= 1
          Traverse.set_next_focus(screen)

        elsif screen.object_focus > index
          screen.object_focus -= 1
        end
      end
    end

    def setScreenIndex(number, obj)
      obj.screen_index = number
      obj.screen = self
      @object[number] = obj
    end

    def validIndex(n)
      n >= 0 && n < @object_count
    end

    def swapRNDKIndices(n1, n2)
      if n1 != n2 && self.validIndex(n1) && self.validIndex(n2)
        o1 = @object[n1]
        o2 = @object[n2]
        self.setScreenIndex(n1, o2)
        self.setScreenIndex(n2, o1)

        if @object_focus == n1
          @object_focus = n2
        elsif @object_focus == n2
          @object_focus = n1
        end
      end
    end

    # Raises the Widget to the top of the screen.
    # It will now overlap any other obstructing Widgets.
    #
    # `rndktype` states what RNDK Widget type this object is.
    # `object` is a pointer to the Widget itself.
    #
    def self.raise_widget(rndktype, object)
      if object.valid_widget_type?(rndktype)
        screen = object.screen
        screen.swapRNDKIndices(object.screen_index, screen.object_count - 1)
      end
    end

    # Has the opposite effect of #raise_widget.
    def self.lower_widget(rndktype, object)
      if object.valid_widget_type?(rndktype)
        object.screen.swapRNDKIndices(object.screen_index, 0)
      end
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

      # We erase all the invisible objects, then only draw it all back, so
      # that the objects can overlap, and the visible ones will always be
      # drawn after all the invisible ones are erased
      (0...@object_count).each do |x|
        obj = @object[x]
        if obj.valid_widget_type?(obj.object_type)
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

      (0...@object_count).each do |x|
        obj = @object[x]

        if obj.valid_widget_type?(obj.object_type)
          obj.has_focus = (x == focused)

          if obj.is_visible
            obj.draw(obj.box)
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
      (0...@object_count).each do |x|
        obj = @object[x]
        obj.erase if obj.valid_widget_type? obj.object_type
      end
      Ncurses.wrefresh(@window)
    end

    # Destroys all the Widgets inside this Screen.
    def destroy_widgets
      (0...@object_count).each do |x|
        obj    = @object[x]
        before = @object_count

        if obj.valid_widget_type?(obj.object_type)
          obj.erase
          obj.destroy
          x -= (@object_count - before)
        end
      end
    end

    # Destroys this Screen.
    # @note It does nothing to the widgets inside it.
    #       You must either destroy them separatedly
    #       or call #destroy_widgets before.
    def destroy
      RNDK::ALL_SCREENS.delete self
    end

  end
end

