require 'rndk'

module RNDK
  class CALENDAR < RNDK::Widget
    attr_accessor :week_base
    attr_reader :day, :month, :year

    MONTHS_OF_THE_YEAR = [
        'NULL',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
    ]

    DAYS_OF_THE_MONTH = [
        -1,
        31,
        28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
    ]

    MAX_DAYS = 32
    MAX_MONTHS = 13
    MAX_YEARS = 140

    CALENDAR_LIMIT = MAX_DAYS * MAX_MONTHS * MAX_YEARS

    def self.CALENDAR_INDEX(d, m, y)
      (y * RNDK::CALENDAR::MAX_MONTHS + m) * RNDK::CALENDAR::MAX_DAYS + d
    end

    def setCalendarCell(d, m, y, value)
      @marker[RNDK::CALENDAR.CALENDAR_INDEX(d, m, y)] = value
    end

    def getCalendarCell(d, m, y)
      @marker[RNDK::CALENDAR.CALENDAR_INDEX(d, m, y)]
    end

    #
    #
    # @note If `day`, `month` or `year` are zero, it'll use the
    #       current date for it.
    #       If all of them are 0, will use the complete date
    #       of today.
    def initialize(rndkscreen,
                   xplace,
                   yplace,
                   title,
                   day,
                   month,
                   year,
                   day_attrib,
                   month_attrib,
                   year_attrib,
                   highlight,
                   box,
                   shadow)
      super()

      # If the user didn't supply enough arguments,
      # we'll set the current date as default
      date_info = Time.now.gmtime
      day   = date_info.day   if day   == 0
      month = date_info.month if month == 0
      year  = date_info.year  if year  == 0

      parent_width  = Ncurses.getmaxx(rndkscreen.window)
      parent_height = Ncurses.getmaxy(rndkscreen.window)
      box_width = 24
      box_height = 11
      dayname = 'Su Mo Tu We Th Fr Sa '
      bindings = {
          'T'            => Ncurses::KEY_HOME,
          't'            => Ncurses::KEY_HOME,
          'n'            => Ncurses::KEY_NPAGE,
          RNDK::FORCHAR  => Ncurses::KEY_NPAGE,
          'p'            => Ncurses::KEY_PPAGE,
          RNDK::BACKCHAR => Ncurses::KEY_PPAGE,
      }

      self.setBox box

      box_width = self.setTitle(title, box_width)
      box_height += @title_lines

      # Make sure we didn't extend beyond the dimensions
      # of the window.
      box_width = [box_width, parent_width].min
      box_height = [box_height, parent_height].min

      # Rejustify the x and y positions if we need to.
      xtmp = [xplace]
      ytmp = [yplace]
      RNDK.alignxy(rndkscreen.window, xtmp, ytmp, box_width, box_height)
      xpos = xtmp[0]
      ypos = ytmp[0]

      # Create the calendar window.
      @win = Ncurses.newwin(box_height, box_width, ypos, xpos)

      # Is the window nil?
      if @win.nil?
        self.destroy
        return nil
      end
      Ncurses.keypad(@win, true)

      # Set some variables.
      @x_offset = (box_width - 20) / 2
      @field_width = box_width - 2 * (1 + @border_size)

      # Set months and day names
      @month_name = RNDK::CALENDAR::MONTHS_OF_THE_YEAR.clone
      @day_name = dayname

      # Set the rest of the widget values.
      @screen = rndkscreen
      @parent = rndkscreen.window
      @shadow_win = nil
      @xpos = xpos
      @ypos = ypos
      @box_width = box_width
      @box_height = box_height
      @day = day
      @month = month
      @year = year
      @day_attrib = day_attrib
      @month_attrib = month_attrib
      @year_attrib = year_attrib
      @highlight = highlight
      @width = box_width
      @accepts_focus = true
      @input_window = @win
      @week_base = 0
      @shadow = shadow
      @label_win = Ncurses.subwin(@win, 1, @field_width,
          ypos + @title_lines + 1, xpos + 1 + @border_size)
      if @label_win.nil?
        self.destroy
        return nil
      end

      @field_win = Ncurses.subwin(@win, 7, 20,
          ypos + @title_lines + 3, xpos + @x_offset)
      if @field_win.nil?
        self.destroy
        return nil
      end
      self.setBox(box)

      @marker = [0] * RNDK::CALENDAR::CALENDAR_LIMIT

      # If the day/month/year values were 0, then use today's date.
      if @day == 0 && @month == 0 && @year == 0
        date_info = Time.new.gmtime
        @day = date_info.day
        @month = date_info.month
        @year = date_info
      end

      # Verify the dates provided.
      self.verifyCalendarDate

      # Determine which day the month starts on.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)

      # If a shadow was requested, then create the shadow window.
      if shadow
        @shadow_win = Ncurses.newwin(box_height, box_width,
            ypos + 1, xpos + 1)
      end

      # Setup the key bindings.
      bindings.each do |from, to|
        self.bind(:CALENDAR, from, :getc, to)
      end

      rndkscreen.register(:CALENDAR, self)
    end

    # This function lets the user play with this widget.
    def activate(actions)
      ret = -1
      self.draw(@box)

      if actions.nil? || actions.size == 0
        while true
          input = self.getch([])

          # Inject the character into the widget.
          ret = self.inject(input)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      else
        # Inject each character one at a time.
        actions.each do |action|
          ret = self.inject(action)
          if @exit_type != :EARLY_EXIT
            return ret
          end
        end
      end
      return ret
    end

    # This injects a single character into the widget.
    def inject(input)
      # Declare local variables
      pp_return = 1
      ret = -1
      complete = false

      # Set the exit type
      self.setExitType(0)

      # Refresh the widget field.
      self.drawField

      # Check if there is a pre-process function to be called.
      unless @pre_process_func.nil?
        pp_return = @pre_process_func.call(:CALENDAR, self,
            @pre_process_data, input)
      end

      # Should we continue?
      if pp_return != 0
        # Check a predefined binding
        if self.checkBind(:CALENDAR, input)

          ## FIXME What the heck? Missing method?
          #self.checkEarlyExit

          complete = true
        else
          case input
          when Ncurses::KEY_UP    then self.decrementCalendarDay 7
          when Ncurses::KEY_DOWN  then self.incrementCalendarDay 7
          when Ncurses::KEY_LEFT  then self.decrementCalendarDay 1
          when Ncurses::KEY_RIGHT then self.incrementCalendarDay 1
          when Ncurses::KEY_NPAGE then self.incrementCalendarMonth 1
          when Ncurses::KEY_PPAGE then self.decrementCalendarMonth 1
          when 'N'.ord then self.incrementCalendarMonth 6
          when 'P'.ord then self.decrementCalendarMonth 6
          when '-'.ord then self.decrementCalendarYear 1
          when '+'.ord then self.incrementCalendarYear 1

          when Ncurses::KEY_HOME then self.setDate(-1, -1, -1)

          when RNDK::KEY_ESC
            self.setExitType(input)
            complete = true
          when Ncurses::ERR
            self.setExitType(input)
            complete = true
          when RNDK::KEY_TAB, RNDK::KEY_RETURN, Ncurses::KEY_ENTER
            self.setExitType(input)
            ret = self.getCurrentTime
            complete = true
          when RNDK::REFRESH
            @screen.erase
            @screen.refresh
          end
        end

        # Should we do a post-process?
        if !complete && !(@post_process_func.nil?)
          @post_process_func.call(:CALENDAR, self, @post_process_data, input)
        end
      end

      if !complete
        self.setExitType(0)
      end

      @result_data = ret
      return ret
    end

    # This moves the calendar field to the given location.
    def move(xplace, yplace, relative, refresh_flag)
      windows = [@win, @field_win, @label_win, @shadow_win]

      self.move_specific(xplace, yplace, relative, refresh_flag, windows, [])
    end

    # This draws the calendar widget.
    def draw(box)
      header_len = @day_name.size
      col_len = (6 + header_len) / 7

      # Is there a shadow?
      unless @shadow_win.nil?
        Draw.drawShadow(@shadow_win)
      end

      # Box the widget if asked.
      if box
        Draw.drawObjBox(@win, self)
      end

      self.drawTitle(@win)

      # Draw in the day-of-the-week header.
      (0...7).each do |col|
        src = col_len * ((col + (@week_base % 7)) % 7)
        dst = col_len * col
        Draw.writeChar(@win,
                       @x_offset + dst,
                       @title_lines + 2,
                       @day_name[src..-1],
                       RNDK::HORIZONTAL,
                       0,
                       col_len)
      end

      Ncurses.wrefresh @win
      self.drawField
    end

    # This draws the month field.
    def drawField
      month_name = @month_name[@month]
      month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
      year_index = RNDK::CALENDAR.YEAR2INDEX(@year)
      year_len = 0
      save_y = -1
      save_x = -1

      day = (1 - @week_day + (@week_base % 7))
      if day > 0
        day -= 7
      end

      (1..6).each do |row|
        (0...7).each do |col|
          if day >= 1 && day <= month_length
            xpos = col * 3
            ypos = row

            marker = @day_attrib
            temp = '%02d' % day

            if @day == day
              marker = @highlight
              save_y = ypos + Ncurses.getbegy(@field_win) - Ncurses.getbegy(@input_window)
              save_x = 1
            else
              marker |= self.getMarker(day, @month, year_index)
            end
            Draw.writeCharAttrib(@field_win, xpos, ypos, temp, marker, RNDK::HORIZONTAL, 0, 2)
          end
          day += 1
        end
      end
      Ncurses.wrefresh @field_win

      # Draw the month in.
      if !(@label_win.nil?)
        temp = '%s %d,' % [month_name, @day]
        Draw.writeChar(@label_win, 0, 0, temp, RNDK::HORIZONTAL, 0, temp.size)
        Ncurses.wclrtoeol @label_win

        # Draw the year in.
        temp = '%d' % [@year]
        year_len = temp.size
        Draw.writeChar(@label_win, @field_width - year_len, 0, temp,
            RNDK::HORIZONTAL, 0, year_len)

        Ncurses.wmove(@label_win, 0, 0)
        Ncurses.wrefresh @label_win

      elsif save_y >= 0
        Ncurses.wmove(@input_window, save_y, save_x)
        Ncurses.wrefresh @input_window
      end
    end

    # This sets multiple attributes of the widget
    def set(day, month, year, day_attrib, month_attrib, year_attrib, highlight, box)
      self.setDate(day, month, yar)
      self.setDayAttribute(day_attrib)
      self.setMonthAttribute(month_attrib)
      self.setYearAttribute(year_attrib)
      self.setHighlight(highlight)
      self.setBox(box)
    end

    # This sets the date and some attributes.
    def setDate(day, month, year)
      # Get the current dates and set the default values for the
      # day/month/year values for the calendar
      date_info = Time.new.gmtime

      # Set the date elements if we need to.
      @day = if day == -1 then date_info.day else day end
      @month = if month == -1 then date_info.month else month end
      @year = if year == -1 then date_info.year else year end

      # Verify the date information.
      self.verifyCalendarDate

      # Get the start of the current month.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)
    end

    # This returns the current date on the calendar.
    def getDate(day, month, year)
      day << @day
      month << @month
      year << @year
    end

    # This sets the attribute of the days in the calendar.
    def setDayAttribute(attribute)
      @day_attrib = attribute
    end

    def getDayAttribute
      return @day_attrib
    end

    # This sets the attribute of the month names in the calendar.
    def setMonthAttribute(attribute)
      @month_attrib = attribute
    end

    def getMonthAttribute
      return @month_attrib
    end

    # This sets the attribute of the year in the calendar.
    def setYearAttribute(attribute)
      @year_attrib = attribute
    end

    def getYearAttribute
      return @year_attrib
    end

    # This sets the attribute of the highlight box.
    def setHighlight(highlight)
      @highlight = highlight
    end

    def getHighlight
      return @highlight
    end

    # This sets the background attribute of the widget.
    def setBKattr(attrib)
      Ncurses.wbkgd(@win, attrib)
      Ncurses.wbkgd(@field_win, attrib)
      Ncurses.wbkgd(@label_win, attrib) unless @label_win.nil?
    end

    # This erases the calendar widget.
    def erase
      if self.validRNDKObject
        RNDK.eraseCursesWindow @label_win
        RNDK.eraseCursesWindow @field_win
        RNDK.eraseCursesWindow @win
        RNDK.eraseCursesWindow @shadow_win
      end
    end

    # This destroys the calendar
    def destroy
      self.cleanTitle

      RNDK.deleteCursesWindow @label_win
      RNDK.deleteCursesWindow @field_win
      RNDK.deleteCursesWindow @shadow_win
      RNDK.deleteCursesWindow @win

      # Clean the key bindings.
      self.cleanBindings(:CALENDAR)

      # Unregister the object.
      RNDK::Screen.unregister(:CALENDAR, self)
    end

    # This sets a marker on the calendar.
    def setMarker(day, month, year, marker)
      year_index = RNDK::CALENDAR.YEAR2INDEX(year)
      oldmarker = self.getMarker(day, month, year)

      # Check to see if a marker has not already been set
      if oldmarker != 0
        self.setCalendarCell(day, month, year_index,
            oldmarker | Ncurses::A_BLINK)
      else
        self.setCalendarCell(day, month, year_index, marker)
      end
    end

    def getMarker(day, month, year)
      result = 0
      year = RNDK::CALENDAR.YEAR2INDEX(year)
      if @marker != 0
        result = self.getCalendarCell(day, month, year)
      end
      return result
    end

    # This sets a marker on the calendar.
    def removeMarker(day, month, year)
      year_index = RNDK::CALENDAR.YEAR2INDEX(year)
      self.setCalendarCell(day, month, year_index, 0)
    end

    # THis function sets the month name.
    def setMonthNames(months)
      (1...[months.size, @month_name.size].min).each do |x|
        @month_name[x] = months[x]
      end
    end

    # This function sets the day's name
    def setDaysNames(days)
      @day_name = days.clone
    end

    # This makes sure that the dates provided exist.
    def verifyCalendarDate
      # Make sure the given year is not less than 1900.
      if @year < 1900
        @year = 1900
      end

      # Make sure the month is within range.
      if @month > 12
        @month = 12
      end
      if @month < 1
        @month = 1
      end

      # Make sure the day given is within range of the month.
      month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
      if @day < 1
        @day = 1
      end
      if @day > month_length
        @day = month_length
      end
    end

    # This returns what day of the week the month starts on.
    def self.getMonthStartWeekday(year, month)
      return Time.mktime(year, month, 1, 10, 0, 0).wday
    end

    # This function returns a 1 if it's a leap year and 0 if not.
    def self.isLeapYear(year)
      result = false
      if year % 4 == 0
        if year % 100 == 0
          if year % 400 == 0
            result = true
          end
        else
          result = true
        end
      end
      return result
    end

    # This increments the current day by the given value.
    def incrementCalendarDay(adjust)
      month_length = RNDK::CALENDAR.getMonthLength(@year, @month)

      # Make sure we adjust the day correctly.
      if adjust + @day > month_length
        # Have to increment the month by one.
        @day = @day + adjust - month_length
        self.incrementCalendarMonth(1)
      else
        @day += adjust
        self.drawField
      end
    end

    # This decrements the current day by the given value.
    def decrementCalendarDay(adjust)
      # Make sure we adjust the day correctly.
      if @day - adjust < 1
        # Set the day according to the length of the month.
        if @month == 1
          # make sure we aren't going past the year limit.
          if @year == 1900
            mesg = [
                '<C></U>Error',
                'Can not go past the year 1900'
            ]
            RNDK.beep
            @screen.popup_label(mesg, 2)
            return
          end
          month_length = RNDK::CALENDAR.getMonthLength(@year - 1, 12)
        else
          month_length = RNDK::CALENDAR.getMonthLength(@year, @month - 1)
        end

        @day = month_length - (adjust - @day)

        # Have to decrement the month by one.
        self.decrementCalendarMonth(1)
      else
        @day -= adjust
        self.drawField
      end
    end

    # This increments the current month by the given value.
    def incrementCalendarMonth(adjust)
      # Are we at the end of the year.
      if @month + adjust > 12
        @month = @month + adjust - 12
        @year += 1
      else
        @month += adjust
      end

      # Get the length of the current month.
      month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
      if @day > month_length
        @day = month_length
      end

      # Get the start of the current month.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)

      # Redraw the calendar.
      self.erase
      self.draw(@box)
    end

    # This decrements the current month by the given value.
    def decrementCalendarMonth(adjust)
      # Are we at the end of the year.
      if @month <= adjust
        if @year == 1900
          mesg = [
              '<C></U>Error',
              'Can not go past the year 1900',
          ]
          RNDK.beep
          @screen.popup_label(mesg, 2)
          return
        else
          @month = 13 - adjust
          @year -= 1
        end
      else
        @month -= adjust
      end

      # Get the length of the current month.
      month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
      if @day > month_length
        @day = month_length
      end

      # Get the start o the current month.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)

      # Redraw the calendar.
      self.erase
      self.draw(@box)
    end

    # This increments the current year by the given value.
    def incrementCalendarYear(adjust)
      # Increment the year.
      @year += adjust

      # If we are in Feb make sure we don't trip into voidness.
      if @month == 2
        month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
        if @day > month_length
          @day = month_length
        end
      end

      # Get the start of the current month.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)

      # Redraw the calendar.
      self.erase
      self.draw(@box)
    end

    # This decrements the current year by the given value.
    def decrementCalendarYear(adjust)
      # Make sure we don't go out o bounds.
      if @year - adjust < 1900
        mesg = [
            '<C></U>Error',
            'Can not go past the year 1900',
        ]
        RNDK.beep
        @screen.popup_label(mesg, 2)
        return
      end

      # Decrement the year.
      @year -= adjust

      # If we are in Feb make sure we don't trip into voidness.
      if @month == 2
        month_length = RNDK::CALENDAR.getMonthLength(@year, @month)
        if @day > month_length
          @day = month_length
        end
      end

      # Get the start of the current month.
      @week_day = RNDK::CALENDAR.getMonthStartWeekday(@year, @month)

      # Redraw the calendar.
      self.erase
      self.draw(@box)
    end

    # This returns the length of the current month.
    def self.getMonthLength(year, month)
      month_length = DAYS_OF_THE_MONTH[month]

      if month == 2
        month_length += if RNDK::CALENDAR.isLeapYear(year)
                        then 1
                        else 0
                        end
      end

      return month_length
    end

    # This returns what day of the week the month starts on.
    def getCurrentTime
      # Determine the current time and determine if we are in DST.
      return Time.mktime(@year, @month, @day, 0, 0, 0).gmtime
    end

    def focus
      # Original: drawRNDKFscale(widget, ObjOf (widget)->box);
      self.draw(@box)
    end

    def unfocus
      # Original: drawRNDKFscale(widget, ObjOf (widget)->box);
      self.draw(@box)
    end

    def self.YEAR2INDEX(year)
      if year >= 1900
        year - 1900
      else
        year
      end
    end

    def position
      super(@win)
    end

    def object_type
      :CALENDAR
    end
  end
end
