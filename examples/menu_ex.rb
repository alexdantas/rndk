#!/usr/bin/env ruby
require_relative 'example'

class MenuExample < Example
  # This program demonstrates the Rndk menu widget.
  def MenuExample.main
    menu_list = (0...RNDK::MENU::MAX_MENU_ITEMS).map {
        [nil] * RNDK::MENU::MAX_SUB_ITEMS}.compact
    menu_info = [
        [
            "",
            "This saves the current info.",
            "This exits the program.",
            ""
        ],
        [
            "",
            "This cuts text",
            "This copies text",
            "This pastes text"
        ],
        [
            "",
            "Help for editing",
            "Help for file management",
            "Info about the program"
        ]
    ]

    # Set up RNDK.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Start color.
    RNDK::Draw.initRNDKColor

    # Set up the menu.
    menu_list[0][0] = "</B>File<!B>"
    menu_list[0][1] = "</B>Save<!B>"
    menu_list[0][2] = "</B>Exit<!B>"

    menu_list[1][0] = "</B>Edit<!B>"
    menu_list[1][1] = "</B>Cut<!B>"
    menu_list[1][2] = "</B>Copy<!B>"
    menu_list[1][3] = "</B>Paste<!B>"

    menu_list[2][0] = "</B>Help<!B>"
    menu_list[2][1] = "</B>On Edit <!B>"
    menu_list[2][2] = "</B>On File <!B>"
    menu_list[2][3] = "</B>About...<!B>"

    submenusize = [3, 4, 4]

    menuloc = [RNDK::LEFT, RNDK::LEFT, RNDK::RIGHT]

    # Create the label window.
    mesg = [
        "                                          ",
        "                                          ",
        "                                          ",
        "                                          "
    ]

    info_box = RNDK::LABEL.new(rndkscreen, RNDK::CENTER, RNDK::CENTER,
        mesg, 4, true, true)

    # Create the menu.
    menu = RNDK::MENU.new(rndkscreen, menu_list, 3, submenusize, menuloc,
        RNDK::TOP, Ncurses::A_UNDERLINE, Ncurses::A_REVERSE)

    # Create the post process function
    display_callback = lambda do |rndktype, menu, info_box, key|
      # Recreate the label message
      # FIXME magic numbers
      mesg = [
          "Title: %.*s" % [236, menu_list[menu.current_title][0]],
          "Sub-Title: %.*s" %
              [236, menu_list[menu.current_title][menu.current_subtitle + 1]],
          "",
          "<C>%.*s" %
              [236, menu_info[menu.current_title][menu.current_subtitle + 1]]
      ]

      # Set the message of the label.
      info_box.set(mesg, 4, true)
      info_box.draw(true)

      return 0
    end

    # Create the post process function.
    menu.setPostProcess(display_callback, info_box)

    # Draw the RNDK screen.
    rndkscreen.refresh

    # Activate the menu.
    selection = menu.activate('')

    # Determine how the user exited from the widget.
    if menu.exit_type == :EARLY_EXIT
      mesg = [
          "<C>You hit escape. No menu item was selected.",
          "",
          "<C>Press any key to continue."
      ]
      rndkscreen.popupLabel(mesg, 3)
    elsif menu.exit_type == :NORMAL
      mesg = [
          "<C>You selected menu #%d, submenu #%d" %
              [selection / 100, selection % 100],
          "",
          "<C>Press any key to continue."
      ]
          rndkscreen.popupLabel(mesg, 3)
    end

    # Clean up.
    menu.destroy
    info_box.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK

    exit # EXIT_SUCCESS
  end
end

MenuExample.main
