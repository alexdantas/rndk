# tawny-cdk

A Ruby version of Thomas Dickey version of the Curses Development Kit.

Why Tawny?  Because this is better than just a ruby port.  Or, rather, it
will be.  At the moment it's pretty much just a Ruby port but the plan is
a package that is easier to use and extend, with extra extensions to prove
it.

Currently requires ncurses-ruby (http://ncurses-ruby.berlios.de/).

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

Thomas Dickey's C project page: http://invisible-island.net/cdk/

## Examples

Crash course into `cdk`:

    require 'cdk'     # it automatically requires ncurses
    
    curses_win = Ncurses.initscr
    cdk_screen = CDK::SCREEN.new curses_win
    
    CDK::Draw.initCDKColor
    
    label = CDK::LABEL.new(cdk_screen,
                           1,                # x
                           1,                # y
                           "Hello, World!",  # text
                           1,                # text lines
                           true,             # border?
                           true)             # shadow?
    
    cdk_screen.refresh
    label.wait ' '                           # waits for space key
    
    label.destroy
    cdk_screen.destroy
    CDK::SCREEN.endCDK

The `examples` directory contains lots of sample usages for every widget
available.
