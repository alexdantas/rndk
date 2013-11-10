#!/usr/bin/env ruby
# NOTE: This example/demo might be weird/bad-formatted/ugly.
#       I'm currently refactoring all demos/examples from the
#       original 'tawny-cdk' repository and THIS FILE wasn't
#       touched yet.
#       I suggest you go look for files without this notice.
#

require_relative 'example'

class LowerRNDKObjectExample < Example
  def LowerRNDKObjectExample.parse_opts(opts, param)
    opts.banner = 'Usage: lowerRNDKObject_ex.rb [options]'

    param.x_value = RNDK::CENTER
    param.y_value = RNDK::BOTTOM
    param.box = false
    param.shadow = false
    super(opts, param)
  end

  def LowerRNDKObjectExample.main
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
    label1 = RNDK::LABEL.new(rndkscreen, 8, 5, mesg1, 10, true, false)

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
    label2 = RNDK::LABEL.new(rndkscreen, 14, 9, mesg2, 10, true, false)

    mesg = ["</B>1<!B> - lower </U>label1<!U>, </B>2<!B> - lower "]
    mesg[0] << "</U>label2<!U>, </B>q<!B> - </U>quit<!U>"
    instruct = RNDK::LABEL.new(rndkscreen, params.x_value, params.y_value,
        mesg, 1, params.box, params.shadow)

    rndkscreen.refresh

    while (ch = STDIN.getc.chr) != 'q'
      case ch
      when '1'
        RNDK::SCREEN.lowerRNDKObject(:LABEL, label1)
      when '2'
        RNDK::SCREEN.lowerRNDKObject(:LABEL, label2)
      else
        next
      end
      rndkscreen.refresh
    end

    # Clean up
    label1.destroy
    label2.destroy
    instruct.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK
    #ExitProgram (EXIT_SUCCESS);
  end
end

LowerRNDKObjectExample.main
