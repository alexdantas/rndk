require 'rndk/slider'

module RNDK
  class Fslider < Slider
    def initialize(screen, config={})
      x           = 0
      y           = 0
      title       = "fslider"
      label       = "label"
      filler      = ' '.ord | Ncurses::A_REVERSE
      field_width = 0
      start       = 0
      low         = 0
      high        = 100
      inc         = 1
      fast_inc    = 5
      digits      = 3
      box         = true
      shadow      = false

      config.each do |key, val|
        x           = val if key == :x
        y           = val if key == :y
        title       = val if key == :title
        label       = val if key == :label
        filler      = val if key == :filler
        field_width = val if key == :field_width
        start       = val if key == :start
        low         = val if key == :low
        high        = val if key == :high
        inc         = val if key == :inc
        fast_inc    = val if key == :fast_inc
        digits      = val if key == :digits
        box         = val if key == :box
        shadow      = val if key == :shadow
      end

      @digits = digits
      super(screen, x, y, title, label, filler, field_width, start, low, high, inc, fast_inc, box, shadow)
      @widget_type = :fslider
    end

    # This draws the widget.
    def draw_field
      step = 1.0 * @field_width / (@high - @low)

      # Determine how many filler characters need to be drawn.
      filler_characters = (@current - @low) * step

      Ncurses.werase(@field_win)

      # Add the character to the window.
      (0...filler_characters).each do |x|
        Ncurses.mvwaddch(@field_win, 0, x, @filler)
      end

      # Draw the value in the field.
      digits = [@digits, 30].min
      format = '%%.%if' % [digits]
      temp = format % [@current]

      Draw.writeCharAttrib(@field_win,
                           @field_width,
                           0,
                           temp,
                           Ncurses::A_NORMAL,
                           RNDK::HORIZONTAL,
                           0,
                           temp.size)

      self.moveToEditPosition(@field_edit)
      Ncurses.wrefresh(@field_win)
    end

    def formatted_size(value)
      digits = [@digits, 30].min
      format = '%%.%if' % [digits]
      temp = format % [value]
      return temp.size
    end

    def setDigits(digits)
      @digits = [0, digits].max
    end

    def getDigits
      return @digits
    end

    def SCAN_FMT
      '%g%c'
    end

  end
end
