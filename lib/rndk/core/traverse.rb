module RNDK

  #
  #
  module Traverse

    # Traverse the screen just one time.
    def Traverse.once(screen,
                      curobj,
                      key_code,
                      function_key,
                      func_menu_key)

      case key_code
      when Ncurses::KEY_BTAB
        switchFocus(set_previous_focus(screen), curobj)

      when RNDK::KEY_TAB
        switchFocus(set_next_focus(screen), curobj)

      when RNDK.KEY_F(10)
        # save data and exit
        exit_ok(screen)

      when RNDK.CTRL('X')
        exit_cancel screen

      when RNDK.CTRL('R')
        # reset data to defaults
        reset(screen)
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
          screen.widget.each do |widget|
            if !(widget.nil?) && widget.widget_type == :MENU
              Traverse.handleMenu(screen, widget, curobj)
            end
          end

        else
          curobj.inject(key_code)
        end
      end
    end

    # Traverse continuously the widgets on a screen.
    def Traverse.over screen
      result = 0
      curobj = set_first_focus(screen)

      unless curobj.nil?
        refresh_data(screen)

        screen.exit_status = RNDK::Screen::NOEXIT

        while !((curobj = get_current_focus(screen)).nil?) &&
            screen.exit_status == RNDK::Screen::NOEXIT
          function = []
          key = curobj.getch(function)

          # TODO look at more direct way to do this
          check_menu_key = lambda do |key_code, function_key|
            Traverse.checkMenuKey(key_code, function_key)
          end


          Traverse.once(screen, curobj, key,
              function[0], check_menu_key)
        end

        if screen.exit_status == RNDK::Screen::EXITOK
          save_data(screen)
          result = 1
        end
      end
      return result
    end

    def Traverse.reset screen
      refresh_data(screen)
    end

    def Traverse.exit_ok screen
      screen.exit_status = RNDK::Screen::EXITOK
    end

    def Traverse.exit_cancel screen
      screen.exit_status = RNDK::Screen::EXITCANCEL
    end

    def Traverse.exit_ok_of(obj)
      exit_ok obj.screen
    end

    def Traverse.exit_cancel_of(obj)
      exit_cancel obj.screen
    end

    def Traverse.reset_of(obj)
      reset(obj.screen)
    end

    # Returns the widget on which the focus lies.
    def Traverse.get_current_focus(screen)
      result = nil
      n = screen.widget_focus

      if n >= 0 && n < screen.widget_count
        result = screen.widget[n]
      end

      return result
    end

    # Set focus to the next widget, returning it.
    def Traverse.set_next_focus(screen)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n+= 1
        if n >= screen.widget_count
          n = 0
        end
        curobj = screen.widget[n]
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

    # Set focus to the previous widget, returning it.
    def Traverse.set_previous_focus(screen)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n -= 1
        if n < 0
          n = screen.widget_count - 1
        end
        curobj = screen.widget[n]
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

    # Set focus to a specific widget, returning it.
    # If the widget cannot be found, return nil.
    def Traverse.set_current_focus(screen, newobj)
      result = nil
      curobj = nil
      n = getFocusIndex(screen)
      first = n

      while true
        n += 1
        if n >= screen.widget_count
          n = 0
        end

        curobj = screen.widget[n]
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

    # Set focus to the first widget in the screen.
    def Traverse.set_first_focus(screen)
      setFocusIndex(screen, screen.widget_count - 1)
      return switchFocus(set_next_focus(screen), nil)
    end

    # Set focus to the last widget in the screen.
    def Traverse.set_last_focus(screen)
      setFocusIndex(screen, 0)
      return switchFocus(set_previous_focus(screen), nil)
    end

    private

    def Traverse.limitFocusIndex(screen, value)
      if value >= screen.widget_count || value < 0
        0
      else
        value
      end
    end

    def Traverse.getFocusIndex(screen)
      return limitFocusIndex(screen, screen.widget_focus)
    end

    def Traverse.setFocusIndex(screen, value)
      screen.widget_focus = limitFocusIndex(screen, value)
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
        key = menu.getch

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

      if (newobj = Traverse.get_current_focus(screen)).nil?
        newobj = Traverse.set_next_focus(screen)
      end

      return switchFocus(newobj, menu)
    end

    # Calls Widget#save_data on all widgets of `screen`.
    def Traverse.save_data screen
      screen.widget.each do |widget|
        widget.save_data unless widget.nil?
      end
    end

    # Calls Widget#refresh_data on all widgets of `screen`.
    def Traverse.refresh_data screen
      screen.widget.each do |widget|
        widget.refresh_data unless widget.nil?
      end
    end

  end
end

