#!/usr/bin/env ruby
require_relative 'example'

class RaiseRNDKObjectExample < Example
  def RaiseRNDKObjectExample.MY_LABEL(obj)
    obj.screen_index | 0x30 | Ncurses::A_UNDERLINE | Ncurses::A_BOLD
  end

  def RaiseRNDKObjectExample.parse_opts(opts, param)
    opts.banner = 'Usage: raiseRNDKObject_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::BOTTOM
    param.box = true
    param.shadow = false
    super(opts, param)
  end

  def RaiseRNDKObjectExample.main
    # Declare variables.
    params = parse(ARGV)

    # Set up RNDK
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    mesg1 = [
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1",
        "label1 label1 label1 label1 label1 label1 label1"
    ]
    label1 = RNDK::LABEL.new(rndkscreen, 10, 4, mesg1, 10, true, false)
    label1.setULchar('1'.ord | Ncurses::A_BOLD)

    mesg2 = [
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2",
        "label2 label2 label2 label2 label2 label2 label2"
    ]
    label2 = RNDK::LABEL.new(rndkscreen, 8, 8, mesg2, 10, true, false)
    label2.setULchar('2'.ord | Ncurses::A_BOLD)

    mesg3 = [
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3",
        "label3 label3 label3 label3 label3 label3 label3"
    ]
    label3 = RNDK::LABEL.new(rndkscreen, 6, 12, mesg3, 10, true, false)
    label3.setULchar('3'.ord | Ncurses::A_BOLD)

    mesg4 = [
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4",
        "label4 label4 label4 label4 label4 label4 label4"
    ]
    label4 = RNDK::LABEL.new(rndkscreen, 4, 16, mesg4, 10, true, false)
    label4.setULchar('4'.ord | Ncurses::A_BOLD)

    mesg = ["</B>#<!B> - raise </U>label#<!U>, </B>r<!B> - </U>redraw<!U>, "]
    mesg[0] << "</B>q<!B> - </U>quit<!U>"
    instruct = RNDK::LABEL.new(rndkscreen, params.x_value, params.y_value,
        mesg, 1, params.box, params.shadow)

    instruct.setULchar(' '.ord | Ncurses::A_NORMAL)
    instruct.setURchar(' '.ord | Ncurses::A_NORMAL)
    instruct.setLLchar(' '.ord | Ncurses::A_NORMAL)
    instruct.setVTchar(' '.ord | Ncurses::A_NORMAL)
    instruct.setHZchar(' '.ord | Ncurses::A_NORMAL)

    label1.setLRchar(MY_LABEL(label1))
    label2.setLRchar(MY_LABEL(label2))
    label3.setLRchar(MY_LABEL(label3))
    label4.setLRchar(MY_LABEL(label4))
    instruct.setLRchar(MY_LABEL(instruct))

    rndkscreen.refresh

    while (ch = STDIN.getc.chr) != 'q'
      case ch
      when '1'
        RNDK::SCREEN.raiseRNDKObject(:LABEL, label1)
      when '2'
        RNDK::SCREEN.raiseRNDKObject(:LABEL, label2)
      when '3'
        RNDK::SCREEN.raiseRNDKObject(:LABEL, label3)
      when '4'
        RNDK::SCREEN.raiseRNDKObject(:LABEL, label4)
      when 'r'
        rndkscreen.refresh
      else
        next
      end

      label1.setLRchar(MY_LABEL(label1))
      label2.setLRchar(MY_LABEL(label2))
      label3.setLRchar(MY_LABEL(label3))
      label4.setLRchar(MY_LABEL(label4))
      instruct.setLRchar(MY_LABEL(instruct))
      rndkscreen.refresh
    end

    # Clean up
    label1.destroy
    label2.destroy
    label3.destroy
    label4.destroy
    instruct.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

RaiseRNDKObjectExample.main
