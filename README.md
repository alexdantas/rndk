# Ruby Ncurses Development Kit (RNDK)
[![Gem Version](https://badge.fury.io/rb/rndk.png)](http://badge.fury.io/rb/rndk)

`rndk` aims to be a powerful, well-documented and easy-to-use
Ncurses Development Kit in Ruby. Besides abstracting away Ncurses'
details, it provides some widgets for rapid console app development.

It means that you'll be able to master the dark arts of text-based
applications, easily creating nice apps for the console.

`RNDK` is a fork from `tawny-cdk`, a [Chris Sauro Ruby port][tawny]
of [Thomas Dickey's Curses Development Kit][cdk] (in C).

Here's the list of currently implemented widgets:

| Widget                | Description                                     | Has examples? |
| --------------------- | ----------------------------------------------- | ------------- |
| Alphalist             | Scrolling list of alphabetically sorted words   | not yet       |
| Button                | Message attached to a callback                  | not yet       |
| Buttonbox             | Labeled set of buttons                          | not yet       |
| Calendar              | Pop-up traversable calendar                     | yes!          |
| Dialog                | Dialog box with a message and some buttons      | not yet       |
| Entry                 | Text-entry box with a label                     | yes!          |
| File Selector         | Interact graphically with the file system       | not yet       |
| Graph                 | Plots a graph with x/y coordinates              | not yet       |
| Histogram             | Vertical/horizontal histogram                   | not yet       |
| Item List             | Select from a preset item list                  | not yet       |
| Label                 | Pop-up label window                             | yes!          |
| Matrix                | Matrix widget                                   | not yet       |
| Marquee               | Movable text                                    | not yet       |
| Menu                  | Pull-down menu list                             | not yet       |
| Multiple Line Entry   | Multiple-line entry box with a label            | not yet       |
| Radio List            | Radio item list                                 | not yet       |
| Scale                 | Draggable scale box with a label                | not yet       |
| Scrolling List        | Scrolling item list                             | yes!          |
| Scrolling Window      | Display scrollable long messages                | not yet       |
| Selection List        | Selection list widget                           | not yet       |
| Slider                | Visual slider box                               | yes!          |
| Template              | Insert info on a field with a pre-set format    | not yet       |
| Viewer                | View contents of a file on a scrollable box     | not yet       |

The ones with examples (on the root `examples` directory) are ready to use.
The others are kinda unstable, since the API is being completely rewritten.
Also, [click here for screenshots][widgets]!

## WARNING

This is a very unstable Work-in-Progress library. I'm currently reviewing
`tawny-cdk`'s API, so a lot of things are changing real fast.

Be sure to know that whenever I remove this notice, things will be nicer. For
now, I recommend you to **not** use `rndk` for production programs!

## Installation

`rndk` requires the gem `ffi-ncurses`.

Add this line to your application's Gemfile:

    gem 'rndk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rndk

## Usage

[Take a look at the Wiki][wiki]! There's some tutorials and
resources there.

The `examples` directory contains lots of sample usages for every
widget available. To execute them, go to the `rndk` root folder
and run:

    ruby -Ilib examples/YOUR_EXAMPLE_HERE

There's also some more complex demo applications under the `demos`
directory. Do the same:

    ruby -Ilib demos/YOUR_DEMO_HERE

## Contributing

Any help would be largely appreciated! For a list of things
to do, see the `TODO` file.

Currently `rndk` has a C-like API, since it was directly taken
from `cdk`. The top priority is to make it more rubyish.

I'm getting inspiration from [rbcurse] and some non-ruby Widget
sets.

Step-by-step guide to contribute:

1. Fork this repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[tawny]:https://github.com/masterzora/tawny-cdk
[cdk]:http://invisible-island.net/cdk/
[rbcurse]:https://github.com/rkumar/rbcurse
[wiki]:https://github.com/alexdantas/rndk/wiki
[widgets]:https://github.com/alexdantas/rndk/wiki/widgets

## Contact

Hi, I'm Alexandre Dantas! Thanks for having interest in this project. Please
take the time to visit any of the links below.

* `rndk` homepage: http://www.alexdantas.net/projects/rndk
* Contact: `eu @ alexdantas.net`
* My homepage: http://www.alexdantas.net

