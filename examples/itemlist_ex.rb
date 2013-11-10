#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class ItemlistExample < Example
  MONTHS = 12

  def ItemlistExample.parse_opts(opts, param)
    opts.banner = 'Usage: itemlist_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::CENTER
    param.box = true
    param.shadow = false
    param.c = false

    super(opts, param)

    opts.on('-c', 'create the data after the widget') do
      param.c = true
    end
  end

  # This program demonstrates the Rndk itemlist widget.
  #
  # Options (in addition to minimal CLI parameters):
  #      -c      create the data after the widget
  def ItemlistExample.main
    title = "<C>Pick A Month"
    label = "</U/5>Month:"
    params = parse(ARGV)

    # Get the current date and set the default month to the current month.
    start_month = Time.new.localtime.mon

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::Screen.new(curses_win)

    # Set up RNDK colors
    RNDK::Draw.initRNDKColor

    # Create the choice list.
    info = [
        "<C></5>January",
        "<C></5>February",
        "<C></B/19>March",
        "<C></5>April",
        "<C></5>May",
        "<C></K/5>June",
        "<C></12>July",
        "<C></5>August",
        "<C></5>September",
        "<C></32>October",
        "<C></5>November",
        "<C></11>December"
    ]

    # Create the itemlist widget.
    monthlist = RNDK::ITEMLIST.new(rndkscreen, params.x_value, params.y_value,
        title, label,
        if params.c then '' else info end,
        if params.c then 0 else ItemlistExample::MONTHS end,
        start_month, params.box, params.shadow)

    # Is the widget nil?
    if monthlist.nil?
      # Clean up.
      rndkscreen.destroy
      RNDK::Screen.end_rndk

      puts "Cannot create the itemlist box. Is the window too small?"
      exit  # EXIT_FAILURE
    end

    if params.c
      monthlist.setValues(info, ItemlistExample::MONTHS, 0)
    end

    # Activate the widget.
    choice = monthlist.activate('')

    # Check how they exited from the widget.
    if monthlist.exit_type == :ESCAPE_HIT
      mesg = [
          "<C>You hit escape. No item selected.",
          "",
          "<C>Press any key to continue."
      ]
      monthlist.screen.popupLabel(mesg, 3)
    elsif monthlist.exit_type == :NORMAL
      mesg = [
          "<C>You selected the %dth item which is" % [choice],
          info[choice],
          "",
          "<C>Press any key to continue."
      ]
          monthlist.screen.popupLabel(mesg, 4)
    end

    # Clean up
    monthlist.destroy
    rndkscreen.destroy
    RNDK::Screen.end_rndk
    #ExitProgram (EXIT_SUCCESS);
  end
end

ItemlistExample.main
