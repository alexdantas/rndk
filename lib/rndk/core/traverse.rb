module RNDK

  module Traverse
    def Traverse.resetRNDKScreen(screen)
      refreshDataRNDKScreen(screen)
    end

    def Traverse.exitOKRNDKScreen(screen)
      screen.exit_status = RNDK::Screen::EXITOK
    end

    def Traverse.exitCancelRNDKScreen(screen)
      screen.exit_status = RNDK::Screen::EXITCANCEL
    end

    def Traverse.exitOKRNDKScreenOf(obj)
      exitOKRNDKScreen(obj.screen)
    end

    def Traverse.exitCancelRNDKScreenOf(obj)
      exitCancelRNDKScreen(obj.screen)
    end

    def Traverse.resetRNDKScreenOf(obj)
      resetRNDKScreen(obj.screen)
    end

    # Returns the object on which the focus lies.
    def Traverse.getRNDKFocusCurrent(screen)
      result = nil
      n = screen.object_focus

      if n >= 0 && n < screen.object_count
        result = screen.object[n]
      end

      return result
    end

    # Set focus to the next object, returning it.
    def Traverse.setRNDKFocusNext(screen)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n+= 1
        if n >= screen.object_count
          n = 0
        end
        curobj = screen.object[n]
        if !(curobj.nil?) && curobj.accepts_focus
          result = curobj
          break
        else
          if n == first
            break
          end
        end
      end

      setFocusIndex(screen, if !(result.nil?) then n else -1 end)
      return result
    end

    # Set focus to the previous object, returning it.
    def Traverse.setRNDKFocusPrevious(screen)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n -= 1
        if n < 0
          n = screen.object_count - 1
        end
        curobj = screen.object[n]
        if !(curobj.nil?) && curobj.accepts_focus
          result = curobj
          break
        elsif n == first
          break
        end
      end

      setFocusIndex(screen, if !(result.nil?) then n else -1 end)
      return result
    end

    # Set focus to a specific object, returning it.
    # If the object cannot be found, return nil.
    def Traverse.setRNDKFocusCurrent(screen, newobj)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n += 1
        if n >= screen.object_count
          n = 0
        end

        curobj = screen.object[n]
        if curobj == newobj
          result = curobj
          break
        elsif n == first
          break
        end
      end

      setFocusIndex(screen, if !(result.nil?) then n else -1 end)
      return result
    end

    # Set focus to the first object in the screen.
    def Traverse.setRNDKFocusFirst(screen)
      setFocusIndex(screen, screen.object_count - 1)
      return switchFocus(setRNDKFocusNext(screen), nil)
    end

    # Set focus to the last object in the screen.
    def Traverse.setRNDKFocusLast(screen)
      setFocusIndex(screen, 0)
      return switchFocus(setRNDKFocusPrevious(screen), nil)
    end

    def Traverse.traverseRNDKOnce(screen, curobj, key_code,
        function_key, func_menu_key)
      case key_code
      when Ncurses::KEY_BTAB
        switchFocus(setRNDKFocusPrevious(screen), curobj)
      when RNDK::KEY_TAB
        switchFocus(setRNDKFocusNext(screen), curobj)
      when RNDK.KEY_F(10)
        # save data and exit
        exitOKRNDKScreen(screen)
      when RNDK.CTRL('X')
        exitCancelRNDKScreen(screen)
      when RNDK.CTRL('R')
        # reset data to defaults
        resetRNDKScreen(screen)
        setFocus(curobj)
      when RNDK::REFRESH
        # redraw screen
        screen.refresh
        setFocus(curobj)
      else
        # not everyone wants menus, so we make them optional here
        if !(func_menu_key.nil?) &&
            (func_menu_key.call(key_code, function_key))
          # find and enable drop down menu
          screen.object.each do |object|
            if !(object.nil?) && object.object_type == :MENU
              Traverse.handleMenu(screen, object, curobj)
            end
          end
        else
          curobj.inject(key_code)
        end
      end
    end

    # Traverse the widgets on a screen.
    def Traverse.traverseRNDKScreen(screen)
      result = 0
      curobj = setRNDKFocusFirst(screen)

      unless curobj.nil?
        refreshDataRNDKScreen(screen)

        screen.exit_status = RNDK::Screen::NOEXIT

        while !((curobj = getRNDKFocusCurrent(screen)).nil?) &&
            screen.exit_status == RNDK::Screen::NOEXIT
          function = []
          key = curobj.getch(function)

          # TODO look at more direct way to do this
          check_menu_key = lambda do |key_code, function_key|
            Traverse.checkMenuKey(key_code, function_key)
          end


          Traverse.traverseRNDKOnce(screen, curobj, key,
              function[0], check_menu_key)
        end

        if screen.exit_status == RNDK::Screen::EXITOK
          saveDataRNDKScreen(screen)
          result = 1
        end
      end
      return result
    end

    private

    def Traverse.limitFocusIndex(screen, value)
      if value >= screen.object_count || value < 0
        0
      else
        value
      end
    end

    def Traverse.getFocusIndex(screen)
      return limitFocusIndex(screen, screen.object_focus)
    end

    def Traverse.setFocusIndex(screen, value)
      screen.object_focus = limitFocusIndex(screen, value)
    end

    def Traverse.unsetFocus(obj)
      Ncurses.curs_set(0)
      unless obj.nil?
        obj.has_focus = false
        obj.unfocus
      end
    end

    def Traverse.setFocus(obj)
      unless obj.nil?
        obj.has_focus = true
        obj.focus
      end
      Ncurses.curs_set(1)
    end

    def Traverse.switchFocus(newobj, oldobj)
      if oldobj != newobj
        Traverse.unsetFocus(oldobj)
        Traverse.setFocus(newobj)
      end
      return newobj
    end

    def Traverse.checkMenuKey(key_code, function_key)
      key_code == RNDK::KEY_ESC && !function_key
    end

    def Traverse.handleMenu(screen, menu, oldobj)
      done = false

      switchFocus(menu, oldobj)
      while !done
        key = menu.getch([])

        case key
        when RNDK::KEY_TAB
          done = true
        when RNDK::KEY_ESC
          # cleanup the menu
          menu.inject(key)
          done = true
        else
          done = (menu.inject(key) >= 0)
        end
      end

      if (newobj = Traverse.getRNDKFocusCurrent(screen)).nil?
        newobj = Traverse.setRNDKFocusNext(screen)
      end

      return switchFocus(newobj, menu)
    end

    # Save data in widgets on a screen
    def Traverse.saveDataRNDKScreen(screen)
      screen.object.each do |object|
        unless object.nil?
          object.saveData
        end
      end
    end

    # Refresh data in widgets on a screen
    def Traverse.refreshDataRNDKScreen(screen)
      screen.object.each do |object|
        unless object.nil?
          object.refreshData
        end
      end
    end

  end
end

