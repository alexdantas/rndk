# Ruby Ncurses Development Kit (RNDK)

This project aims to be a powerful, well-documented and easy-to-use
Ncurses Development Kit in Ruby. Besides abstracting away Ncurses'
details, it provides some widgets for rapid console app development.

It means that you'll be able to master the dark arts of text-based
applications, easily creating nice apps for the console.

`RNDK` is a fork from `tawny-cdk`, a [Chris Sauro Ruby port][tawny]
of [Thomas Dickey's Curses Development Kit][cdk] (in C).

Currently implemented widgets:

 * Alphalist
 * Button
 * Buttonbox
 * Calendar
 * Dialog
 * Entry
 * File Selector
 * Graph
 * Histogram
 * Item List
 * Label
 * Matrix
 * Marquee
 * Menu
 * Multiple Line Entry
 * Radio List
 * Scale
 * Scrolling List
 * Scrolling Window
 * Selection List
 * Slider
 * Template
 * Viewer

## Requirements

`rndk` requires the gem `ffi-ncurses`.

## Installation

Add this line to your application's Gemfile:

    gem 'rndk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rndk

## Usage

The `examples` directory contains lots of sample usages for every
widget available. To execute them, go to the `rndk` root folder
and run:

    ruby -Ilib examples/YOUR_EXAMPLE_HERE

There's also some more comples demo applications under the `demos`
directory. Do the same:

    ruby -Ilib demos/YOUR_DEMO_HERE

Here's a sample that shows a colored "Hello, World!" on the screen:

    # Set up CDK
    curses_win = Ncurses.initscr
    cdkscreen = CDK::SCREEN.new(curses_win)

    # Set up CDK colors
    CDK::Draw.initCDKColor

    # Set the labels up.
	# They're easy ways to format text.
    mesg = [
        "</5><#UL><#HL(30)><#UR>",
        "</5><#VL(10)>Hello, World!<#VL(10)>",
        "</5><#LL><#HL(30)><#LR)"
    ]

    # Declare the labels.
    demo = CDK::LABEL.new(cdkscreen,
	                      1,    # x
						  1,    # y
						  mesg, # labels
						  3,    # lines no.
						  true, # box?
						  true) # shadow?

    # Draw the CDK screen.
    cdkscreen.refresh
    demo.wait(' ')

    # Clean up
    demo.destroy
    cdkscreen.destroy
    CDK::SCREEN.endCDK

## Contributing

Currently `rndk` has a C-like API, since it was directly taken
from `cdk`. The top priority is to make it more rubyish (maybe
studying [rbcurse]?).

Also, see the `TODO` file.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[tawny]:https://github.com/masterzora/tawny-cdk
[cdk]:http://invisible-island.net/cdk/
[rbcurse]:https://github.com/rkumar/rbcurse

