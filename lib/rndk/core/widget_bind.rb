
module RNDK
  class Widget

    # Returns the internal Widget that accepts key bindings.
    #
    # Some widgets are made of others.
    # So when we bind keys to those complex widgets,
    # we can specify which internal Widget accepts keybindings.
    #
    # For example, on an Alphalist (which is composed of Scroll
    # and Entry), we bind keys to the Entry, not Scroll.
    #
    def bindable_widget rndktype
      return nil if rndktype != self.widget_type


      if [:Fselect, :alphalist].include? self.widget_type
        return @entry_field

      else
        return self
      end
    end

    # Binds a `function` to a `key`.
    #
    def bind(key, function, data)
      obj = self.bindable_widget @widget_type

      return if (key.ord >= Ncurses::KEY_MAX) or (key.ord.zero?) or (obj.nil?)

      obj.binding_list[key.ord] = [function, data]
    end

    def unbind key
      obj = self.bindable_widget @widget_type

      obj.binding_list.delete(key) unless obj.nil?
    end

    def clean_bindings
      obj = self.bindable_widget @widget_type

      if (not obj.nil?) and (not obj.binding_list.nil?)
        obj.binding_list.clear
      end
    end

    # Checks to see if some binding for `key` exists and runs it.
    #
    # * If binding for `key` exists, runs the command it is bound
    #   to and returns it's value (normally `true`)
    # * If binding for `key` doesn't exist, returns `false`.
    #
    # This functions is used to see if there's a predefined
    # default keybinding for `key`.
    # If not, then we run our customs. See the widgets for details.
    #
    def check_bind key
      obj = self.bindable_widget @widget_type

      return false if obj.nil? or (not obj.binding_list.include? key)

      function = obj.binding_list[key][0]
      data     = obj.binding_list[key][1]

      if function == :getc
        return data
      else
        return function.call(obj, data, key)
      end
    end

    # Tells if the key binding for the key exists.
    def is_bound? key
      result = false

      obj = self.bindable_widget @widget_type

      unless obj.nil?
        result = obj.binding_list.include? key
      end
      result
    end

    def when(signal, &action)
      @actions[signal] << action
    end

    def run_actions(signal)
      @actions[signal].each { |action| action.call }
    end
  end
end

