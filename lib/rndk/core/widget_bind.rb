
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
      return nil if rndktype != @widget_type


      if [:Fselect, :alphalist].include? @widget_type
        return @entry_field

      else
        return self
      end
    end

    # Binds a `function` to a `key`.
    #
    def bind_key(key, data=nil, &action)
      obj = self.bindable_widget @widget_type

      if (key.ord >= Ncurses::KEY_MAX) or (key.ord.zero?) or (obj.nil?)
        return
      end

      obj.binding_list[key.ord] = [action, data]
    end

    def unbind_key key
      obj = self.bindable_widget @widget_type

      obj.binding_list.delete(key) unless obj.nil?
    end

    def clean_bindings
      obj = self.bindable_widget @widget_type

      if (not obj.nil?) and (not obj.binding_list.nil?)
        obj.binding_list.clear
      end
    end

    # Runs any binding that's set for `key`.
    #
    # @return The binding's return value or `false`, if no
    #         keybinding for `key` exists.

    def run_binding key
      obj = self.bindable_widget @widget_type

      return false if obj.nil? or (not obj.binding_list.include? key)

      function = obj.binding_list[key][0]
      data     = obj.binding_list[key][1]

      # What the heck is this?
      return data if function == :getc

      function.call data
    end

    # Tells if the key binding for the key exists.
    def is_bound? key
      obj = self.bindable_widget @widget_type
      return false if obj.nil?

      obj.binding_list.include? key
    end

    def when(signal, &action)
      @actions[signal] << action
    end

    def run_actions(signal)
      @actions[signal].each { |action| action.call }
    end
  end
end

