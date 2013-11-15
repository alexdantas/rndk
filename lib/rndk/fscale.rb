require 'rndk/scale'

module RNDK
  class FSCALE < SCALE
    def initialize(rndkscreen,
                   xplace,
                   yplace,
                   title,
                   label,
                   field_attr,
                   field_width,
                   start,
                   low,
                   high,
                   inc,
                   fast_inc,
                   digits,
                   box,
                   shadow)
      @digits = digits
      super(rndkscreen, xplace, yplace, title, label, field_attr, field_width, start, low, high, inc, fast_inc, box, shadow)
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

    def widget_type
      :FSCALE
    end
  end
end
