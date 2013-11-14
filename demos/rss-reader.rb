#!/usr/bin/env ruby
#
# A simple RSS reader.
# It receives a feed address as an argument, defaulting to the
# Ruby Language feed if not provided.
#
# When an item is selected, it's content pops-up.
#
require 'rss'
require 'open-uri'
require 'rndk/label'
require 'rndk/scroll'

DEFAULT_URL = 'https://www.ruby-lang.org/en/feeds/news.rss'

begin
  # which feed
  url = DEFAULT_URL
  url = ARGV.first if ARGV.first

  # retrieving things
  puts 'Fetching feeds...'
  feed = RSS::Parser.parse (open url)

  # starting RNDK
  screen = RNDK::Screen.new
  RNDK::Color.init

  # building label
  title = ["<C></77>#{feed.channel.title}",
           "</76>Press ESC to quit"]
  label = RNDK::Label.new(screen,
                          RNDK::CENTER,                 # x
                          RNDK::TOP,                    # y
                          title,                        # title
                          true,                         # border?
                          false)                        # shadow?

  # will show the titles at scroll widget
  titles = []
  feed.items.each { |item| titles << item.title }

  # building scroll
  scroll = RNDK::Scroll.new(screen,
                            RNDK::CENTER,               # x
                            4,                          # y
                            RNDK::RIGHT,                # scroll bar
                            RNDK::Screen.width/2,       # width
                            RNDK::Screen.height/2 - 5,  # height
                            "<C></77>Items",            # title
                            titles,                     # items
                            true,                       # numbers?
                            RNDK::Color[:cyan],         # highlight
                            true,                       # border?
                            false)                      # shadow?
  screen.refresh

  loop do
    scroll.activate

    # user selected an item
    if scroll.exit_type == :NORMAL

      # Getting current item's content
      index = scroll.current_item
      raw_message = feed.items[index].description

      # Removing '\n' at the end of all the lines.
      message = []
      raw_message.lines.each { |line| message << line.chomp }

      # Show current item's content on a pop-up
      screen.popup_label message

    # user pressed ESC - wants to quit
    elsif scroll.exit_type == :ESCAPE_HIT

      # good bye!
      RNDK::Screen.end_rndk
      exit
    end
  end
end

