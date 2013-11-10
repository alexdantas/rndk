module RNDK
  class SCREEN
    attr_accessor :object_focus, :object_count, :object_limit, :object, :window
    attr_accessor :exit_status

    NOEXIT = 0
    EXITOK = 1
    EXITCANCEL = 2

    def initialize (window)
      # initialization for the first time
      if RNDK::ALL_SCREENS.size == 0
        # Set up basic curses settings.
        # #ifdef HAVE_SETLOCALE
        # setlocale (LC_ALL, "");
        # #endif

        Ncurses.noecho
        Ncurses.cbreak
      end

      RNDK::ALL_SCREENS << self
      @object_count = 0
      @object_limit = 2
      @object = Array.new(@object_limit, nil)
      @window = window
      @object_focus = 0
    end

    # This registers a RNDK object with a screen.
    def register(rndktype, object)
      if @object_count + 1 >= @object_limit
        @object_limit += 2
        @object_limit *= 2
        @object.concat(Array.new(@object_limit - @object.size, nil))
      end

      if object.validObjType(rndktype)
        self.setScreenIndex(@object_count, object)
        @object_count += 1
      end
    end

    # This removes an object from the RNDK screen.
    def self.unregister(rndktype, object)
      if object.validObjType(rndktype) && object.screen_index >= 0
        screen = object.screen

        unless screen.nil?
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
              Traverse.setRNDKFocusNext(screen)
            elsif screen.object_focus > index
              screen.object_focus -= 1
            end
          end
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

    # This 'brings' a RNDK object to the top of the stack.
    def self.raiseRNDKObject(rndktype, object)
      if object.validObjType(rndktype)
        screen = object.screen
        screen.swapRNDKIndices(object.screen_index, screen.object_count - 1)
      end
    end

    # This 'lowers' an object.
    def self.lowerRNDKObject(rndktype, object)
      if object.validObjType(rndktype)
        object.screen.swapRNDKIndices(object.screen_index, 0)
      end
    end

    # Quickly pops up a `message` with `count` lines.
    def popupLabel(message, count)
      prev_state = Ncurses.curs_set 0

      popup = RNDK::LABEL.new(self, CENTER, CENTER, message, count, true, false)
      popup.draw(true)

      # Wait for some input.
      Ncurses.keypad(popup.win, true)
      popup.getch([])
      popup.destroy

      # Clean the screen.
      Ncurses.curs_set prev_state
      self.erase
      self.refresh
    end

    # This pops up a message
    def popupLabelAttrib(mesg, count, attrib)
      # Create the label.
      popup = RNDK::LABEL.new(self, CENTER, CENTER, mesg, count, true, false)
      popup.setBackgroundAttrib

      old_state = Ncurses.curs_set(0)
      # Draw it on the screen)
      popup.draw(true)

      # Wait for some input
      Ncurses.keypad(popup.win, true)
      popup.getch([])

      # Kill it.
      popup.destroy

      # Clean the screen.
      Ncurses.curs_set(old_state)
      screen.erase
      screen.refresh
    end

    # This pops up a dialog box.
    def popupDialog(mesg, mesg_count, buttons, button_count)
      # Create the dialog box.
      popup = RNDK::DIALOG.new(self, RNDK::CENTER, RNDK::CENTER,
          mesg, mesg_count, buttons, button_count, Ncurses::A_REVERSE,
          true, true, false)

      # Activate the dialog box
      popup.draw(true)

      # Get the choice
      choice = popup.activate('')

      # Destroy the dialog box
      popup.destroy

      # Clean the screen.
      self.erase
      self.refresh

      return choice
    end

    # This calls SCREEN.refresh, (made consistent with widgets)
    def draw
      self.refresh
    end

    # Refresh one RNDK window.
    # FIXME(original): this should be rewritten to use the panel library, so
    # it would not be necessary to touch the window to ensure that it covers
    # other windows.
    def SCREEN.refreshRNDKWindow(win)
      Ncurses.touchwin win
      Ncurses.wrefresh win
    end

    # This refreshes all the objects in the screen.
    def refresh
      focused = -1
      visible = -1

      RNDK::SCREEN.refreshRNDKWindow(@window)

      # We erase all the invisible objects, then only draw it all back, so
      # that the objects can overlap, and the visible ones will always be
      # drawn after all the invisible ones are erased
      (0...@object_count).each do |x|
        obj = @object[x]
        if obj.validObjType(obj.object_type)
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

        if obj.validObjType(obj.object_type)
          obj.has_focus = (x == focused)

          if obj.is_visible
            obj.draw(obj.box)
          end
        end
      end
    end

    # This clears all the objects in the screen
    def erase
      # We just call the object erase function
      (0...@object_count).each do |x|
        obj = @object[x]
        if obj.validObjType(obj.object_type)
          obj.erase
        end
      end

      # Refresh the screen.
      Ncurses.wrefresh(@window)
    end

    # Destroy all the objects on a screen
    def destroyRNDKScreenObjects
      (0...@object_count).each do |x|
        obj = @object[x]
        before = @object_count

        if obj.validObjType(obj.object_type)
          obj.erase
          obj.destroy
          x -= (@object_count - before)
        end
      end
    end

    # This destroys a RNDK screen.
    def destroy
      RNDK::ALL_SCREENS.delete(self)
    end

    # This is added to remain consistent
    def self.endRNDK
      Ncurses.echo
      Ncurses.nocbreak
      Ncurses.endwin
    end
  end
end
