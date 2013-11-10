#!/usr/bin/env ruby
require_relative 'example'

class TemplateExample < Example
  def TemplateExample.parse_opts(opts, param)
    opts.banner = 'Usage: template_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    super(opts, param)
  end

  # This program demonstrates the Rndk label widget.
  def TemplateExample.main
    title = '<C>Title'
    label = '</5>Phone Number:<!5>'
    overlay = '</B/6>(___)<!6> </5>___-____'
    plate = '(###) ###-####'

    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Declare the template.
    phone_number = RNDK::TEMPLATE.new(rndkscreen, params.x_value, params.y_value,
        title, label, plate, overlay, params.box, params.shadow)

    if phone_number.nil?
      # Exit RNDK.
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts 'Cannot create template. Is the window too small?'
      exit  # EXIT_FAILURE
    end

    # Activate the template.
    info = phone_number.activate([])

    # Tell them what they typed.
    if phone_number.exit_type == :ESCAPE_HIT
      mesg = [
          '<C>You hit escape. No information typed in.',
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif phone_number.exit_type == :NORMAL
      # Mix the plate and the number.
      mixed = phone_number.mix

      # Create the message to display.
      # FIXME magic numbers
      mesg = [
          'Phone Number with out plate mixing  : %.*s' % [206, info],
          'Phone Number with the plate mixed in: %.*s' % [206, mixed],
          '',
          '<C>Press any key to continue.'
      ]
      rndkscreen.popupLabel(mesg, 4)
    end

    # Clean up
    phone_number.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

TemplateExample.main
