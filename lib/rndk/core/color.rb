
module RNDK

  # The colors that we can print text with.
  #
  # Internally we call Colors attributes - or attribs.
  #
  # ## Usage
  #
  # First of all, you should call Color#init. If your terminal
  # doesn't support colors (come on, at 2010s?) Colors#has_colors?
  # will tell.
  #
  # All Widgets that have an `attrib` argument can use a Color.
  # You call them like this:
  #
  #     color = RNDK::Color[:foreground_background]
  #
  # If you want to use your terminal's current default
  # background/foreground, use:
  #
  #     color = RNDK::Color[:default_background]
  #     color = RNDK::Color[:foreground]
  #
  # Also, there are special color modifiers. They change how
  # the color appears and can make some interesting effects:
  #
  # * RNDK::Color[:normal]
  # * RNDK::Color[:bold]
  # * RNDK::Color[:reverse]
  # * RNDK::Color[:underline]
  # * RNDK::Color[:blink]
  # * RNDK::Color[:dim]
  # * RNDK::Color[:invisible]
  # * RNDK::Color[:standout]
  #
  # To apply them, "add" to the regular colors with the
  # pipe ('|'):
  #
  #     color = RNDK::Color[:red] | RNDK::Color[:bold]
  #
  # ## Examples
  #
  #```
  # wb  = Color[:white_black]
  # gm  = Color[:green_magenta]
  # red = Color[:red]
  # bl  = Color[:default_black]
  # x   = RNDK::Color[:blue_yellow] | RNDK::Color[:reverse] # guess what?
  # y   = RNDK::Color[:cyan] | RNDK::Color[:invisible] # opps
  #```
  #
  # ## Developer Notes
  #
  # Color#init creates 80 color pairs. Neat!
  #
  # Also, to extract attributes from a chtype (mix between
  # characters and ncurses colors) use
  #
  #     chtype & RNDK::Color[:extract]
  #
  module Color

    # All possible colors on format `:foreground_background`.
    #
    # When `background` is not specified, it's the current
    # terminal's default.
    #
    # They're defined on Color#init.
    @@colors = {}

    # These special attributes exist even if no color
    # were initialized.
    #
    # They modify the way colors show on the screen.

    @@attributes = {
      :normal    => Ncurses::A_NORMAL,
      :bold      => Ncurses::A_BOLD,
      :reverse   => Ncurses::A_REVERSE,
      :underline => Ncurses::A_UNDERLINE,
      :blink     => Ncurses::A_BLINK,
      :dim       => Ncurses::A_DIM,
      :invisible => Ncurses::A_INVIS,
      :standout  => Ncurses::A_STANDOUT,

      # To extract attributes from a chtype (mix between
      # characters and ncurses colors) use
      # `chtype & RNDK::Color[:extract]
      :extract   => Ncurses::A_ATTRIBUTES
    }

    # Start support for colors, initializing all color pairs.
    def self.init
      return unless self.has_colors?

      Ncurses.start_color

      # Will be able to use current terminal's
      # background color (value -1)
      Ncurses.use_default_colors

      # We will initialize 80 color pairs with all
      # combinations from the current Array.
      #
      # They'll have symbols with their names.
      # For example:
      #     Color[:white_black]
      #     Color[:green_magenta]
      color = [[Ncurses::COLOR_WHITE,   :white],
               [Ncurses::COLOR_RED,     :red],
               [Ncurses::COLOR_GREEN,   :green],
               [Ncurses::COLOR_YELLOW,  :yellow],
               [Ncurses::COLOR_BLUE,    :blue],
               [Ncurses::COLOR_MAGENTA, :magenta],
               [Ncurses::COLOR_CYAN,    :cyan],
               [Ncurses::COLOR_BLACK,   :black]]

      limit = if Ncurses.COLORS < 8
              then Ncurses.COLORS
              else 8
              end

      pair = 1
      # Create the color pairs
      (0...limit).each do |fg|
        (0...limit).each do |bg|
          Ncurses.init_pair(pair, color[fg][0], color[bg][0])

          label = "#{color[fg][1]}_#{color[bg][1]}".to_sym
          @@colors[label] = pair
          pair += 1
        end
      end

      # The color pairs with default background and foreground.
      #
      # They'll have symbols with their names and 'default'
      # where the default color is.
      # For example:
      #     Color[:default_black]
      #     Color[:magenta]
      color.each do |bg|
        Ncurses.init_pair(pair, -1, bg[0])

        label = "default_#{bg[1]}".to_sym
        @@colors[label] = pair
        pair += 1
      end
      color.each do |fg|
        Ncurses.init_pair(pair, fg[0], -1)

        label = "#{fg[1]}".to_sym
        @@colors[label] = pair
        pair += 1
      end
    end

    # Tells if the current terminal supports colors.
    #
    # Unless you've been living under a rock, this
    # shouldn't be of any concern.
    def self.has_colors?
      Ncurses.has_colors
    end

    # Access individual color pairs or attributes.
    #
    # If colors were not initialized and user request colors,
    # returns **white foreground over default background**.
    #
    def self.[] label
      if @@attributes.include? label
        @@attributes[label]

      elsif @@colors.include? label
        Ncurses.COLOR_PAIR @@colors[label]

      else
        Ncurses.COLOR_PAIR 0
      end
    end

  end
end

