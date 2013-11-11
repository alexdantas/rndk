#!/usr/bin/env ruby
#
# This shows you how easy it is to use the Quick Widgets --
# temporary pre-made Widgets with a single action.
#
# They're automatically included within `require 'rndk'`.
require 'rndk'

begin
  screen = RNDK::Screen.new

  # Popup label
  msg = ["Hello, there!",
         "Lemme show you some pre-made widgets",
         "This is the popup_label",
         "(press any key to continue)"
        ]
  screen.popup_label msg

  # Popup dialog
  msg = ["Now this is the popup_dialog",
         "It returns the index of which button",
         "you select"
        ]
  buttons = ["Press me",
             "No, press me",
             "No, me"
            ]
  choice = screen.popup_dialog(msg, buttons)

  screen.popup_label ["You selected button no #{choice}"]

  # View file
  title = "view_file (If something bad happens, press Ctrl+L)"
  buttons = ["I'm impressed",
             "Maybe impressed",
             "Not impressed"
             ]
  screen.view_file(title, __FILE__, buttons)

  # Get list index
  title = "get_list_index example"
  msg = ["Apples",
         "Oranges",
         "Avocados",
         "Watermelons"]

  screen.get_list_index(title, msg, true)

  # Get string
  title = "get_string example"
  msg = "Finally, the last example! What did you thing of it? "

  value = screen.get_string(title, msg, "great")

  screen.popup_label ["You just said '#{value}'"]

  # Finally, the end!
  RNDK::Screen.end_rndk

  puts "...and as always, thanks for watching!"

# Just in case something bad happens.
rescue Exception => e
  RNDK::Screen.end_rndk

  puts e
  puts e.inspect
  puts e.backtrace
  exit 1
end

