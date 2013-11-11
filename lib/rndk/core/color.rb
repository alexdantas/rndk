
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
  # ## Examples
  #
  #     wb  = Color[:white_black]
  #     gm  = Color[:green_magenta]
  #     red = Color[:red]
  #     bl  = Color[:default_black]
  #
  # ## Developer Notes
  #
  # Color#init creates 80 color pairs.
  #
  module Color

    # All possible colors on format `:foreground_background`.
    #
    # When `background` is not specified, it's the current
    # terminal's default.
    #
    # They're defined on Color#init.
    @@colors = {}

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

    # Access individual color pairs.
    #
    # If colors were not initialized, returns white foreground
    # over default background.
    #
    # @return Ncurses `COLOR_PAIR` over `label` color.
    def self.[] label
      unless @@colors.include? label
        return Ncurses.COLOR_PAIR(0)
      end

      Ncurses.COLOR_PAIR @@colors[label]
    end

  end
end

