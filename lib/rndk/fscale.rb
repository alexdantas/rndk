require 'rndk/scale'

module RNDK
  class Fscale < Scale
    def initialize(screen, config={})
      @widget_type = :Fscale

      x           = 0
      y           = 0
      title       = "fscale"
      label       = "label"
      field_attr  = RNDK::Color[:normal]
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
        field_attr  = val if key == :field_attr
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
      super(screen, x, y, title, label, field_attr, field_width, start, low, high, inc, fast_inc, box, shadow)
    end

    def drawField
      Ncurses.werase @field_win

      # Draw the value in the field.
      digits = [@digits, 30].min
      format = '%%.%if' % [digits]
      temp = format % [@current]

      Draw.writeCharAttrib(@field_win,
                           @field_width - temp.size - 1,
                           0,
                           temp,
                           @field_attr,
                           RNDK::HORIZONTAL,
                           0,
                           temp.size)

      self.moveToEditPosition(@field_edit)
      Ncurses.wrefresh(@field_win)
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

