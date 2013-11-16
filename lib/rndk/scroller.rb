require 'rndk'

module RNDK

  # Common actions and functionality between
  # scrolling Widgets.
  #
  # @note Do **not** instantiate this class!
  #       Use it's subclasses.
  class Scroller < Widget

    def initialize
      super()
    end

    def scroll_up
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

    def scroll_down
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

    def scroll_left
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

    def scroll_right
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

    def scroll_page_up
      if @list_size > 0
        if @current_top > 0
          if @current_top >= @view_size - 1
            @current_top -= @view_size - 1
            @current_item -= @view_size - 1
          else
            self.scroll_begin
          end
        else
          RNDK.beep
        end
      else
        RNDK.beep
      end
    end

    def scroll_page_down
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

    def scroll_begin
      @current_top = 0
      @current_item = 0
      @current_high = 0
    end

    def scroll_end
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
        self.scroll_begin
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

