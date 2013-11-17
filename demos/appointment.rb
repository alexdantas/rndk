#!/usr/bin/env ruby
#
# Warning: This is not for beginners! Check out the examples/
#          before adventuring into the demos/ realm!
#
# Warning2: This is not well-written! Handle with care.
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
#
require 'ostruct'
require 'rndk/calendar'
require 'rndk/itemlist'
require 'rndk/entry'

# I really doubt you're gonna put
# that many markers
MAX_MARKERS = 2000

AppointmentAttributes = [
                           RNDK::Color[:blink],
                           RNDK::Color[:bold],
                           RNDK::Color[:reverse],
                           RNDK::Color[:underline],
                          ]

AppointmentType = [
                   :BIRTHDAY,
                   :ANNIVERSARY,
                   :APPOINTMENT,
                   :OTHER,
                  ]

# This reads a given appointment file into `app_info`.
def readAppointmentFile(filename, app_info)
  appointments = 0
  segments = 0

  # Read the appointment file.
  lines = RNDK.read_file filename

  if lines.nil?
    app_info.count = 0
    return
  end

  # Split each line up and create an appointment.
  (0...lines.size).each do |x|
    temp = lines[x].split(RNDK.CTRL('V').chr)
    segments =  temp.size

    # A valid line has 5 elements:
    #          Day, Month, Year, Type, Description.
    if segments == 5
      app_info.appointment << OpenStruct.new
      e_type = AppointmentType[temp[3].to_i]

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
def saveAppointmentFile(filename, app_info)
  # TODO: error handling
  fd = File.new(filename, 'w')

  # Start writing.
  app_info.appointment.each do |appointment|
    if appointment.description != ''
      fd.puts '%d%c%d%c%d%c%d%c%s' % [
                                      appointment.day, RNDK.CTRL('V').chr,
                                      appointment.month, RNDK.CTRL('V').chr,
                                      appointment.year, RNDK.CTRL('V').chr,
                                      AppointmentType.index(appointment.type),
                                      RNDK.CTRL('V').chr, appointment.description]
    end
  end
  fd.close
end

# This adds a marker to the calendar.
def create_calendar_mark(calendar, info)

  items = [
           'Birthday',
           'Anniversary',
           'Appointment',
           'Other',
          ]

  # Create the itemlist widget.
  itemlist = RNDK::Itemlist.new(calendar.screen, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :title => '',
                                  :label => 'Select Appointment Type: ',
                                  :items => items
                                })

  # Get the appointment type from the user.
  selection = itemlist.activate

  # They hit escape, kill the itemlist widget and leave.
  if selection == -1
    itemlist.destroy
    calendar.draw
    return false
  end

  # Destroy the itemlist and set the marker.
  itemlist.destroy
  calendar.draw
  marker = AppointmentAttributes[selection]

  # Create the entry field for the description.
  entry = RNDK::Entry.new(calendar.screen, {
                            :x => RNDK::CENTER,
                            :y => RNDK::CENTER,
                            :title => '<C>Enter a description of the appointment.',
                            :label => 'Description: ',
                            :field_width => 40,
                          })
  # Get the description.
  description = entry.activate
  if description == 0
    entry.destroy
    calendar.draw
    return false
  end

  # Destroy the entry and set the marker.
  description = entry.info
  entry.destroy
  calendar.draw

  # Set the marker.
  calendar.set_marker(calendar.day, calendar.month, calendar.year, marker)

  # Keep the marker.
  info.appointment << OpenStruct.new
  current = info.count

  info.appointment[current].day = calendar.day
  info.appointment[current].month = calendar.month
  info.appointment[current].year = calendar.year
  info.appointment[current].type = AppointmentType[selection]
  info.appointment[current].description = description
  info.count += 1

  # Redraw the calendar.
  calendar.draw
  return false
end

  # This removes a marker from the calendar.
def remove_calendar_mark(calendar, info)

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
  calendar.draw
  return false
end

# This displays the marker(s) on the given day.
def display_calendar_mark(calendar, info)
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
  label = RNDK::Label.new(calendar.screen, {
                            :x => RNDK::CENTER,
                            :y => RNDK::CENTER,
                            :text => mesg
                          })
  label.draw
  label.wait(' ')
  label.destroy

  # Redraw the calendar
  calendar.draw
  return false
end

# Shows a help popup with keybindings.
def show_help(screen)
  msg = ["Keybindings:",
         " 'm' create appointment at selected day",
         " 'r' remove appointment at selected day",
         " '?' displays appointment for selected day",
         " 'enter' or 'tab' quits"]

  screen.popup_label msg
end

begin
  # Set up RNDK and colors
  screen = RNDK::Screen.new
  RNDK::Color.init

  title = "<C></U>RNDK Appointment Book\nPress 'h' for help\n<C><#HL(30)>\n"
  filename = "/tmp/appointments.dat"

  appointment_info = OpenStruct.new
  appointment_info.count = 0
  appointment_info.appointment = []

  readAppointmentFile(filename, appointment_info)

  # Create the calendar widget.
  calendar = RNDK::Calendar.new(screen, {
                                  :x => RNDK::CENTER,
                                  :y => RNDK::CENTER,
                                  :title => title
                                })

  if calendar.nil?
    RNDK::Screen.finish

    puts "Cannot create the calendar. Is the window too small?"
    exit 1
  end

  # Now we bind actions to the calendar.
  # Create a key binding to mark days on the calendar.
  calendar.bind_key('m') do
    create_calendar_mark(calendar, appointment_info)
  end

  calendar.bind_key('r') do
    remove_calendar_mark(calendar, appointment_info)
  end

  calendar.bind_key('?') do
    display_calendar_mark(calendar, appointment_info)
  end

  calendar.bind_key('h') { show_help screen }

  # Set all the appointments read from the file.
  appointment_info.appointment.each do |appointment|
    marker = AppointmentAttributes[AppointmentType.index(appointment.type)]

    calendar.set_marker(appointment.day,
                        appointment.month,
                        appointment.year,
                        marker)
  end

  calendar.draw
  calendar.activate

  # Save the appointment information.
  Appointment.saveAppointmentFile(filename, appointment_info)

  RNDK::Screen.finish

# In case something goes wrong
rescue Exception => e
  RNDK::Screen.finish

  puts e
  puts e.inspect
  puts e.backtrace
end

