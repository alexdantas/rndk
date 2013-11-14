require 'rndk'

module RNDK

  # Common actions and functionality between
  # scrolling Widgets.
  #
  # @note Do **not** instantiate this class!
  #       Use it's subclasses.
  class SCROLLER < Widget

    def initialize
      super()
    end

    def KEY_UP
      if @list_size > 0
        if @current_item > 0
          if @current_high == 0
            if @current_top != 0
              @current_top -= 1
              @current_item -= 1
            else
              RNDK.beep
            end
          else
            @current_item -= 1
            @current_high -= 1
          end
        else
          RNDK.beep
        end
      else
        RNDK.beep
      end
    end

    def KEY_DOWN
      if @list_size > 0
        if @current_item < @list_size - 1
          if @current_high == @view_size - 1
            if @current_top < @max_top_item
              @current_top += 1
              @current_item += 1
            else
              RNDK.beep
            end
          else
            @current_item += 1
            @current_high += 1
          end
        else
          RNDK.beep
        end
      else
        RNDK.beep
      end
    end

    def KEY_LEFT
      if @list_size > 0
        if @left_char == 0
          RNDK.beep
        else
          @left_char -= 1
        end
      else
        RNDK.beep
      end
    end

    def KEY_RIGHT
      if @list_size > 0
        if @left_char >= @max_left_char
          RNDK.beep
        else
          @left_char += 1
        end
      else
        RNDK.beep
      end
    end

    def KEY_PPAGE
      if @list_size > 0
        if @current_top > 0
          if @current_top >= @view_size - 1
            @current_top -= @view_size - 1
            @current_item -= @view_size - 1
          else
            self.KEY_HOME
          end
        else
          RNDK.beep
        end
      else
        RNDK.beep
      end
    end

    def KEY_NPAGE
      if @list_size > 0
        if @current_top < @max_top_item
          if @current_top + @view_size - 1 <= @max_top_item
            @current_top += @view_size - 1
            @current_item += @view_size - 1
          else
            @current_top = @max_top_item
            @current_item = @last_item
            @current_high = @view_size - 1
          end
        else
          RNDK.beep
        end
      else
        RNDK.beep
      end
    end

    def KEY_HOME
      @current_top = 0
      @current_item = 0
      @current_high = 0
    end

    def KEY_END
      if @max_top_item == -1
        @current_top = 0
        @current_item = @last_item - 1
      else
        @current_top = @max_top_item
        @current_item = @last_item
      end
      @current_high = @view_size - 1
    end

    def max_view_size
      return @box_height - (2 * @border_size + @title_lines)
    end

    # Set variables that depend upon the list_size
    def set_view_size(list_size)
      @view_size = self.max_view_size
      @list_size = list_size
      @last_item = list_size - 1
      @max_top_item = list_size - @view_size

      if list_size < @view_size
        @view_size = list_size
        @max_top_item = 0
      end

      if @list_size > 0 && self.max_view_size > 0
        @step = 1.0 * self.max_view_size / @list_size
        @toggle_size = if @list_size > self.max_view_size
                       then 1
                       else @step.ceil
                       end
      else
        @step = 1
        @toggle_size = 1
      end
    end

    def set_position(item)
      if item <= 0
        self.KEY_HOME
      elsif item > @list_size - 1
        @current_top = @max_top_item
        @current_item = @list_size - 1
        @current_high = @view_size - 1
      elsif item >= @current_top && item < @current_top + @view_size
        @current_item = item
        @current_high = item - @current_top
      else
        @current_top = item - (@view_size - 1)
        @current_item = item
        @current_high = @view_size - 1
      end
    end

    # Get/Set the current item number of the scroller.
    def get_current_item
      @current_item
    end

    def set_current_item(item)
      self.set_position(item);
    end

  end
end

