#!/usr/bin/env ruby
#
# Shows all the color pairs available on RNDK.
# Also, how to use RNDK's color markup on strings.
#
# Colors on text are achieved by foreground/background
# color pairs.
# Stop reading, run the example now.
#
# As you just saw, they go from 1 to 80, going on the
# following order in sets of 8 and from background to
# foreground:
#
# 1. white
# 2. red
# 3. green
# 4. yellow
# 5. blue
# 6. magenta
# 7. cyan
# 8. black
#
# Which means that 4 is white on yellow, 11 is red on green
# and 44 is magenta on yellow.
#
# 65 to 72 are the default terminal's foreground over
# color backgrounds and 73 to 80 are the colors over
# the terminal's default background.

require 'rndk/label'

begin
  # Starting RNDK and Color support
  screen = RNDK::Screen.new
  RNDK::Color.init

  # Don't get scared, we're simply showing off all 80 color
  # pairs available.
  #
  # * To start a color, do `</XX>`, where XX is a color pair
  #   from 1 to 80.
  # * To stop it, do `<!XX>`, where XX is the same as above.
  # * To center the text, do `<C>`.

  msg = []
  msg << "</1>Pair01<!1> </2>Pair02<!2> </3>Pair03<!3> </4>Pair04<!4> </5>Pair05<!5> </6>Pair06<!6> </7>Pair07<!7> </8>Pair08<!8>"
  msg << "</9>Pair09<!9> </10>Pair10<!10> </11>Pair11<!11> </12>Pair12<!12> </13>Pair13<!13> </14>Pair14<!14> </15>Pair15<!15> </16>Pair16<!16>"
  msg << "</17>Pair17<!17> </18>Pair18<!18> </19>Pair19<!19> </20>Pair20<!20> </21>Pair21<!21> </22>Pair22<!22> </23>Pair23<!23> </24>Pair24<!24>"
  msg << "</25>Pair25<!25> </26>Pair26<!26> </27>Pair27<!27> </28>Pair28<!28> </29>Pair29<!29> </30>Pair30<!30> </31>Pair31<!31> </32>Pair32<!32>"
  msg << "</33>Pair33<!33> </34>Pair34<!34> </35>Pair35<!35> </36>Pair36<!36> </37>Pair37<!37> </38>Pair38<!38> </39>Pair39<!39> </40>Pair40<!40>"
  msg << "</41>Pair41<!41> </42>Pair42<!42> </43>Pair43<!43> </44>Pair44<!44> </45>Pair45<!45> </46>Pair46<!46> </47>Pair47<!47> </48>Pair48<!48>"
  msg << "</49>Pair49<!49> </50>Pair50<!50> </51>Pair51<!51> </52>Pair52<!52> </53>Pair53<!53> </54>Pair54<!54> </55>Pair55<!55> </56>Pair56<!56>"
  msg << "</57>Pair57<!57> </58>Pair58<!58> </59>Pair59<!59> </60>Pair60<!60> </61>Pair61<!61> </62>Pair62<!62> </63>Pair63<!63> </64>Pair64<!64>"
  msg << "</65>Pair65<!65> </66>Pair66<!66> </67>Pair67<!67> </68>Pair68<!68> </69>Pair69<!69> </70>Pair70<!70> </71>Pair71<!71> </72>Pair72<!72>"
  msg << "</73>Pair73<!73> </74>Pair74<!74> </75>Pair75<!75> </76>Pair76<!76> </77>Pair77<!77> </78>Pair78<!78> </79>Pair79<!79> </80>Pair80<!80>"
  msg << ""
  msg << "<C>All RNDK color pairs (press 'q' to quit)"

  # Show label with that huge message.
  label = RNDK::Label.new(screen,
                          RNDK::CENTER, # x
                          1,            # y
                          msg,          # message
                          true,         # has box?
                          true)         # has shadow?

  screen.refresh
  label.wait('q') # wait for key to be pressed

  RNDK::Screen.finish
end

