#!/usr/bin/env ruby
#
# Note: This is not for beginners! Check out the examples/
#       before adventuring into the demos/ realm!
#
# Shows a book where you can create appointments of different
# kinds, save and restore them on a file.
#
# The keybindings are:
#
# * 'm' create appointment at selected day
# * 'r' remove appointment at selected day
# * '?' displays appointment for selected day
# * 'enter' or 'tab' quits
#
# It automatically creates file `/tmp/appointments.dat` on the
# current directory
require 'ostruct'
require 'rndk/calendar'
require 'rndk/itemlist'
require 'rndk/entry'

class Appointment
  MAX_MARKERS = 2000
  GPAppointmentAttributes = [
    Ncurses::A_BLINK,
    Ncurses::A_BOLD,
    Ncurses::A_REVERSE,
    Ncurses::A_UNDERLINE,
  ]

  AppointmentType = [
    :BIRTHDAY,
    :ANNIVERSARY,
    :APPOINTMENT,
    :OTHER,
  ]

  # This reads a given appointment file.
  def Appointment.readAppointmentFile(filename, app_info)
    appointments = 0
    segments = 0
    lines = []

    # Read the appointment file.
    lines_read = RNDK.read_file(filename, lines)
    if lines_read == nil
      app_info.count = 0
      return
    end

    # Split each line up and create an appointment.
    (0...lines_read).each do |x|
      temp = lines[x].split(RNDK.CTRL('V').chr)
      segments =  temp.size

      # A valid line has 5 elements:
      #          Day, Month, Year, Type, Description.
      if segments == 5
        app_info.appointment << OpenStruct.new
        e_type = Appointment::AppointmentType[temp[3].to_i]

        app_info.appointment[appointments].day = temp[0].to_i
        app_info.appointment[appointments].month = temp[1].to_i
        app_info.appointment[appointments].year = temp[2].to_i
        app_info.appointment[appointments].type = e_type
        app_info.appointment[appointments].description = temp[4]
        appointments += 1
      end
    end

    # Keep the amount of appointments read.
    app_info.count = appointments
  end

  # This saves a given appointment file.
  def Appointment.saveAppointmentFile(filename, app_info)
    # TODO: error handling
    fd = File.new(filename, 'w')

    # Start writing.
    app_info.appointment.each do |appointment|
      if appointment.description != ''
        fd.puts '%d%c%d%c%d%c%d%c%s' % [
            appointment.day, RNDK.CTRL('V').chr,
            appointment.month, RNDK.CTRL('V').chr,
            appointment.year, RNDK.CTRL('V').chr,
            Appointment::AppointmentType.index(appointment.type),
            RNDK.CTRL('V').chr, appointment.description]
      end
    end
    fd.close
  end

  # This program demonstrates the Rndk calendar widget.
  def Appointment.main

    # Get the current dates and set the default values for
    # the day/month/year values for the calendar.
    date_info = Time.now.gmtime
    day = date_info.day
    month = date_info.mon
    year = date_info.year

    title = "<C></U>RNDK Appointment Book\nPress 'h' for help\n<C><#HL(30)>\n"

    filename = ''

    # Create the appointment book filename.
    filename = "/tmp/appointments.dat"

    appointment_info = OpenStruct.new
    appointment_info.count = 0
    appointment_info.appointment = []

    # Read the appointment book information.
    readAppointmentFile(filename, appointment_info)

    # Set up RNDK
    screen = RNDK::Screen.new

    # Set up RNDK colors
    RNDK::Color.init

    # Create the calendar widget.
    calendar = RNDK::Calendar.new(screen,
                                  RNDK::CENTER,
                                  RNDK::CENTER,
                                  title, day, month, year,
                                  Ncurses::A_NORMAL, Ncurses::A_NORMAL, Ncurses::A_NORMAL, Ncurses::A_REVERSE,
                                  true, false)

    # Is the widget nil?
    if calendar.nil?
      RNDK::Screen.end_rndk

      puts "Cannot create the calendar. Is the window too small?"
      exit 1
    end

    # This adds a marker to the calendar.
    create_calendar_mark_cb = lambda do |widget_type, calendar, info, key|
      items = [
          'Birthday',
          'Anniversary',
          'Appointment',
          'Other',
      ]

      # Create the itemlist widget.
      itemlist = RNDK::ITEMLIST.new(calendar.screen,
                                    RNDK::CENTER,
                                    RNDK::CENTER,
                                    '',
                                    'Select Appointment Type: ',
                                    items,
                                    items.size,
                                    0,
                                    true,
                                    false)

      # Get the appointment type from the user.
      selection = itemlist.activate([])

      # They hit escape, kill the itemlist widget and leave.
      if selection == -1
        itemlist.destroy
        calendar.draw(calendar.box)
        return false
      end

      # Destroy the itemlist and set the marker.
      itemlist.destroy
      calendar.draw(calendar.box)
      marker = Appointment::GPAppointmentAttributes[selection]

      # Create the entry field for the description.
      entry = RNDK::Entry.new(calendar.screen,
                              RNDK::CENTER,
                              RNDK::CENTER,
                              '<C>Enter a description of the appointment.',
                              'Description: ',
                              Ncurses::A_NORMAL,
                              '.'.ord,
                              :MIXED,
                              40,
                              1,
                              512,
                              true,
                              false)

      # Get the description.
      description = entry.activate([])
      if description == 0
        entry.destroy
        calendar.draw(calendar.box)
        return false
      end

      # Destroy the entry and set the marker.
      description = entry.info
      entry.destroy
      calendar.draw(calendar.box)

      # Set the marker.
      calendar.setMarker(calendar.day, calendar.month, calendar.year, marker)

      # Keep the marker.
      info.appointment << OpenStruct.new
      current = info.count

      info.appointment[current].day = calendar.day
      info.appointment[current].month = calendar.month
      info.appointment[current].year = calendar.year
      info.appointment[current].type = Appointment::AppointmentType[selection]
      info.appointment[current].description = description
      info.count += 1

      # Redraw the calendar.
      calendar.draw(calendar.box)
      return false
    end

    # This removes a marker from the calendar.
    remove_calendar_mark_cb = lambda do |widget_type, calendar, info, key|
      info.appointment.each do |appointment|
        if appointment.day == calendar.day &&
            appointment.month == calendar.month &&
            appointment.year == calendar.year
          appointment.description = ''
          break
        end
      end

      # Remove the marker from the calendar.
      calendar.removeMarker(calendar.day, calendar.month, calendar.year)

      # Redraw the calendar.
      calendar.draw(calendar.box)
      return false
    end

    # This displays the marker(s) on the given day.
    display_calendar_mark_cb = lambda do |widget_type, calendar, info, key|
      found = 0
      type = ''
      mesg = []

      # Look for the marker in the list.
      info.appointment.each do |appointment|
        # Get the day month year.
        day = appointment.day
        month = appointment.month
        year = appointment.year

        # Determine the appointment type.
        if appointment.type == :BIRTHDAY
          type = 'Birthday'
        elsif appointment.type == :ANNIVERSARY
          type = 'Anniversary'
        elsif appointment.type == :APPOINTMENT
          type = 'Appointment'
        else
          type = 'Other'
        end

        # Find the marker by the day/month/year.
        if day == calendar.day && month == calendar.month &&
            year == calendar.year && appointment.description != ''
          # Create the message for the label widget.
          mesg << '<C>Appointment Date: %02d/%02d/%d' % [
              day, month, year]
          mesg << ' '
          mesg << '<C><#HL(35)>'
          mesg << ' Appointment Type: %s' % [type]
          mesg << ' Description     :'
          mesg << '    %s' % [appointment.description]
          mesg << '<C><#HL(35)>'
          mesg << ' '
          mesg << '<C>Press space to continue.'

          found = 1
          break
        end
      end

      # If we didn't find the marker, create a different message.
      if found == 0
        mesg << '<C>There is no appointment for %02d/%02d/%d' % [calendar.day, calendar.month, calendar.year]
        mesg << '<C><#HL(30)>'
        mesg << '<C>Press space to continue.'
      end

      # Create the label widget
      label = RNDK::Label.new(calendar.screen, RNDK::CENTER, RNDK::CENTER, mesg, true, false)
      label.draw(label.box)
      label.wait(' ')
      label.destroy

      # Redraw the calendar
      calendar.draw(calendar.box)
      return false
    end

    # Shows a help popup with keybindings.
    show_help = lambda do |widget_type, calendar, info, key|
      msg = ["Keybindings:",
             " 'm' create appointment at selected day",
             " 'r' remove appointment at selected day",
             " '?' displays appointment for selected day",
             " 'enter' or 'tab' quits"]

      screen.popup_label msg
    end

    # Now we bind actions to the calendar.
    # Create a key binding to mark days on the calendar.
    calendar.bind('m', create_calendar_mark_cb, appointment_info)
    calendar.bind('M', create_calendar_mark_cb, appointment_info)
    calendar.bind('r', remove_calendar_mark_cb, appointment_info)
    calendar.bind('R', remove_calendar_mark_cb, appointment_info)
    calendar.bind('?', display_calendar_mark_cb, appointment_info)
    calendar.bind('h', show_help, nil)

    # Set all the appointments read from the file.
    appointment_info.appointment.each do |appointment|
      marker = Appointment::GPAppointmentAttributes[Appointment::AppointmentType.index(appointment.type)]

      calendar.setMarker(appointment.day,
                         appointment.month,
                         appointment.year,
                         marker)
    end

    # Draw the calendar widget.
    calendar.draw calendar.box

    # Let the user play with the widget.
    calendar.activate

    # Save the appointment information.
    Appointment.saveAppointmentFile(filename, appointment_info)

    # Clean up.
    RNDK::Screen.end_rndk
  end
end


begin
  Appointment.main

# In case something goes wrong
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
end

