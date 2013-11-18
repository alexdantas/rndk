module RNDK

  #
  #
  module Traverse
    module_function

    # Traverses the screen just one time.
    def once(screen,
                      curobj,
                      key_code,
                      function_key,
                      func_menu_key)

      case key_code
      when Ncurses::KEY_BTAB
        switch_focus(set_previous_focus(screen), curobj)

      when RNDK::KEY_TAB
        switch_focus(set_next_focus(screen), curobj)

      when RNDK.KEY_F(10)
        # save data and exit
        exit_ok(screen)

      when RNDK.CTRL('X')
        exit_cancel screen

      when RNDK.CTRL('R')
        # reset data to defaults
        reset(screen)
        set_focus(curobj)

      when RNDK::REFRESH
        # redraw screen
        screen.refresh
        set_focus(curobj)

      else
        # not everyone wants menus, so we make them optional here
        if !(func_menu_key.nil?) &&
            (func_menu_key.call(key_code, function_key))
          # find and enable drop down menu
          screen.widget.each do |widget|
            if !(widget.nil?) && widget.widget_type == :MENU
              handleMenu(screen, widget, curobj)
            end
          end

        else
          curobj.inject(key_code)
        end
      end
    end

    # Traverses continuously the widgets on a screen.
    def over screen
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
            checkMenuKey(key_code, function_key)
          end


          once(screen, curobj, key,
              function[0], check_menu_key)
        end

        if screen.exit_status == RNDK::Screen::EXITOK
          save_data(screen)
          result = 1
        end
      end
      return result
    end

    def reset screen
      refresh_data(screen)
    end

    def exit_ok screen
      screen.exit_status = RNDK::Screen::EXITOK
    end

    def exit_cancel screen
      screen.exit_status = RNDK::Screen::EXITCANCEL
    end

    def exit_ok_of(obj)
      exit_ok obj.screen
    end

    def exit_cancel_of(obj)
      exit_cancel obj.screen
    end

    def reset_of(obj)
      reset(obj.screen)
    end

    # Returns the widget on which the focus lies.
    def get_current_focus(screen)
      result = nil
      n = screen.widget_focus

      if n >= 0 && n < screen.widget_count
        result = screen.widget[n]
      end

      return result
    end

    # Set focus to the next widget, returning it.
    def set_next_focus(screen)
      result = nil
      curobj = nil
      n = get_focus_index(screen)
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
          break if n == first
        end
      end

      set_focus_index(screen, if !(result.nil?) then n else -1 end)
      result
    end

    # Set focus to the previous widget, returning it.
    def set_previous_focus(screen)
      result = nil
      curobj = nil
      n = get_focus_index(screen)
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

      set_focus_index(screen, if !(result.nil?) then n else -1 end)
      return result
    end

    # Set focus to a specific widget, returning it.
    # If the widget cannot be found, return nil.
    def set_current_focus(screen, newobj)
      result = nil
      curobj = nil
      n = get_focus_index(screen)
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

      set_focus_index(screen, if !(result.nil?) then n else -1 end)
      return result
    end

    # Set focus to the first widget in the screen.
    def set_first_focus(screen)
      set_focus_index(screen, screen.widget_count - 1)

      switch_focus(set_next_focus(screen), nil)
    end

    # Set focus to the last widget in the screen.
    def set_last_focus(screen)
      set_focus_index(screen, 0)

      switch_focus(set_previous_focus(screen), nil)
    end

#    private

    def limit_focus_index(screen, value)
      if value >= screen.widget_count || value < 0
        0
      else
        value
      end
    end

    def get_focus_index(screen)
      return limit_focus_index(screen, screen.widget_focus)
    end

    def set_focus_index(screen, value)
      screen.widget_focus = limit_focus_index(screen, value)
    end

    def unset_focus(obj)
      RNDK::blink_cursor false
      unless obj.nil?
        obj.has_focus = false
        obj.unfocus
      end
    end

    def set_focus(obj)
      unless obj.nil?
        obj.has_focus = true
        obj.focus
      end
      RNDK::blink_cursor true
    end

    def switch_focus(newobj, oldobj)
      if oldobj != newobj

        if !oldobj.nil?
          keep_going = oldobj.run_signal_binding(:before_leaving)
          return oldobj unless keep_going

          oldobj.run_signal_binding(:after_leaving)
        end

        unset_focus oldobj
        set_focus newobj
      end
      newobj
    end

    def checkMenuKey(key_code, function_key)
      key_code == RNDK::KEY_ESC && !function_key
    end

    def handleMenu(screen, menu, oldobj)
      done = false

      switch_focus(menu, oldobj)
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

      if (newobj = get_current_focus(screen)).nil?
        newobj = set_next_focus(screen)
      end

      return switch_focus(newobj, menu)
    end

    # Calls Widget#save_data on all widgets of `screen`.
    def save_data screen
      screen.widget.each do |widget|
        widget.save_data unless widget.nil?
      end
    end

    # Calls Widget#refresh_data on all widgets of `screen`.
    def refresh_data screen
      screen.widget.each do |widget|
        widget.refresh_data unless widget.nil?
      end
    end

  end
end

