#!/usr/bin/env ruby
require_relative 'example'

class TraverseExample < Example
  MY_MAX = 3
  YES_NO = ['Yes', 'NO']
  MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
      'Oct', 'Nov', 'Dec']
  CHOICES = ['[ ]', '[*]']
  # Exercise all widgets except
  #     RNDKMENU
  #     RNDKTRAVERSE
  # The names in parentheses do not accept input, so they will never have
  # focus for traversal.  The names with leading '*' have some limitation
  # that makes them not useful in traversal.
  MENU_TABLE = [
    ['(RNDKGRAPH)',      :GRAPH],     # no traversal (not active)
    ['(RNDKHISTOGRAM)',  :HISTOGRAM], # no traversal (not active)
    ['(RNDKLABEL)',      :LABEL],     # no traversal (not active)
    ['(RNDKMARQUEE)',    :MARQUEE],   # hangs (leaves trash)
    ['*RNDKVIEWER',      :VIEWER],    # traversal out-only on OK
    ['ALPHALIST',       :ALPHALIST],
    ['BUTTON',          :BUTTON],
    ['BUTTONBOX',       :BUTTONBOX],
    ['CALENDAR',        :CALENDAR],
    ['DIALOG',          :DIALOG],
    ['DSCALE',          :DSCALE],
    ['ENTRY',           :ENTRY],
    ['FSCALE',          :FSCALE],
    ['FSELECT',         :FSELECT],
    ['FSLIDER',         :FSLIDER],
    ['ITEMLIST',        :ITEMLIST],
    ['MATRIX',          :MATRIX],
    ['MENTRY',          :MENTRY],
    ['RADIO',           :RADIO],
    ['SCALE',           :SCALE],
    ['SCROLL',          :SCROLL],
    ['SELECTION',       :SELECTION],
    ['SLIDER',          :SLIDER],
    ['SWINDOW',         :SWINDOW],
    ['TEMPLATE',        :TEMPLATE],
    ['USCALE',          :USCALE],
    ['USLIDER',         :USLIDER],
  ]
  @@all_objects = [nil] * MY_MAX

  def self.make_alphalist(rndkscreen, x, y)
    return RNDK::ALPHALIST.new(rndkscreen, x, y, 10, 15, 'AlphaList', '->',
        TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        '_'.ord, Ncurses::A_REVERSE, true, false)
  end

  def self.make_button(rndkscreen, x, y)
    return RNDK::BUTTON.new(rndkscreen, x, y, 'A Button!', nil, true, false)
  end

  def self.make_buttonbox(rndkscreen, x, y)
    return RNDK::BUTTONBOX.new(rndkscreen, x, y, 10, 16, 'ButtonBox', 6, 2,
        TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        Ncurses::A_REVERSE, true, false)
  end

  def self.make_calendar(rndkscreen, x, y)
    return RNDK::CALENDAR.new(rndkscreen, x, y, 'Calendar', 25, 1, 2000,
        Ncurses.COLOR_PAIR(16) | Ncurses::A_BOLD,
        Ncurses.COLOR_PAIR(24) | Ncurses::A_BOLD,
        Ncurses.COLOR_PAIR(32) | Ncurses::A_BOLD,
        Ncurses.COLOR_PAIR(40) | Ncurses::A_REVERSE,
        true, false)
  end

  def self.make_dialog(rndkscreen, x, y)
    mesg = [
        'This is a simple dialog box',
        'Is it simple enough?',
    ]

    return RNDK::DIALOG.new(rndkscreen, x,y, mesg, mesg.size,
        TraverseExample::YES_NO, TraverseExample::YES_NO.size,
        Ncurses.COLOR_PAIR(2) | Ncurses::A_REVERSE,
        true, true, false)
  end

  def self.make_dscale(rndkscreen, x, y)
    return RNDK::DSCALE.new(rndkscreen, x, y, 'DScale', 'Value',
        Ncurses::A_NORMAL, 15, 0.0, 0.0, 100.0, 1.0, (1.0 * 2.0), 1,
        true, false)
  end

  def self.make_entry(rndkscreen, x, y)
    return RNDK::ENTRY.new(rndkscreen, x, y, '', 'Entry:', Ncurses::A_NORMAL,
        '.'.ord, :MIXED, 40, 0, 256, true, false)
  end

  def self.make_fscale(rndkscreen, x, y)
    return RNDK::FSCALE.new(rndkscreen, x, y, 'FScale', 'Value',
        Ncurses::A_NORMAL, 15, 0.0, 0.0, 100.0, 1.0, (1.0 * 2.0), 1,
        true, false)
  end

  def self.make_fslider(rndkscreen, x, y)
    low = -32.0
    high = 64.0
    inc = 0.1
    return RNDK::FSLIDER.new(rndkscreen, x, y, 'FSlider', 'Label',
        Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(29) | ' '.ord,
        20, low, low, high, inc, (inc * 2), 3, true, false)
  end

  def self.make_fselect(rndkscreen, x, y)
    return RNDK::FSELECT.new(rndkscreen, x, y, 15, 25, 'FSelect', '->',
        Ncurses::A_NORMAL, '_'.ord, Ncurses::A_REVERSE, '</5>', '</48>',
        '</N>', '</N>', true, false)
  end

  def self.make_graph(rndkscreen, x, y)
    values = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
    graph_chars = '0123456789'
    widget = RNDK::GRAPH.new(rndkscreen, x, y, 10, 25, 'title', 'X-axis',
        'Y-axis')
    widget.set(values, values.size, graph_chars, true, :PLOT)
    return widget
  end

  def self.make_histogram(rndkscreen, x, y)
    widget = RNDK::HISTOGRAM.new(rndkscreen, x, y, 1, 20, RNDK::HORIZONTAL,
        'Histogram', true, false)
    widget.set(:PERCENT, RNDK::CENTER, Ncurses::A_BOLD, 0, 10, 6,
        ' '.ord | Ncurses::A_REVERSE, true)
    return widget
  end

  def self.make_itemlist(rndkscreen, x, y)
    return RNDK::ITEMLIST.new(rndkscreen, x, y, '', 'Month',
        TraverseExample::MONTHS, TraverseExample::MONTHS.size, 1, true, false)
  end

  def self.make_label(rndkscreen, x, y)
    mesg = [
        'This is a simple label.',
        'Is it simple enough?',
    ]
    return RNDK::LABEL.new(rndkscreen, x, y, mesg, mesg.size, true, true)
  end

  def self.make_marquee(rndkscreen, x, y)
    widget = RNDK::MARQUEE.new(rndkscreen, x, y, 30, true, true)
    widget.activate('This is a message', 5, 3, true)
    widget.destroy
    return nil
  end

  def self.make_matrix(rndkscreen, x, y)
    numrows = 8
    numcols = 5
    coltitle = []
    rowtitle = []
    cols = numcols
    colwidth = []
    coltypes = []
    maxwidth = 0
    rows = numrows
    vcols = 3
    vrows = 3

    (0..numrows).each do |n|
      rowtitle << 'row%d' % [n]
    end

    (0..numcols).each do |n|
      coltitle << 'col%d' % [n]
      colwidth << coltitle[n].size
      coltypes << :UCHAR
      if colwidth[n] > maxwidth
        maxwidth = colwidth[n]
      end
    end

    return RNDK::MATRIX.new(rndkscreen, x, y, rows, cols, vrows, vcols,
        'Matrix', rowtitle, coltitle, colwidth, coltypes, -1, -1, '.'.ord,
        RNDK::COL, true, true, false)
  end

  def self.make_mentry(rndkscreen, x, y)
    return RNDK::MENTRY.new(rndkscreen, x, y, 'MEntry', 'Label',
        Ncurses::A_BOLD, '.', :MIXED, 20, 5, 20, 0, true, false)
  end

  def self.make_radio(rndkscreen, x, y)
    return RNDK::RADIO.new(rndkscreen, x, y, RNDK::RIGHT, 10, 20, 'Radio',
        TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        '#'.ord | Ncurses::A_REVERSE, 1, Ncurses::A_REVERSE, true, false)
  end

  def self.make_scale(rndkscreen, x, y)
    low = 2
    high = 25
    inc = 2
    return RNDK::SCALE.new(rndkscreen, x, y, 'Scale', 'Label',
        Ncurses::A_NORMAL, 5, low, low, high, inc, (inc * 2), true, false)
  end

  def self.make_scroll(rndkscreen, x, y)
    return RNDK::SCROLL.new(rndkscreen, x, y, RNDK::RIGHT, 10, 20, 'Scroll',
        TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        true, Ncurses::A_REVERSE, true, false)
  end

  def self.make_slider(rndkscreen, x, y)
    low = 2
    high = 25
    inc = 1
    return RNDK::SLIDER.new(rndkscreen, x, y, 'Slider', 'Label',
        Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(29) | ' '.ord,
        20, low, low, high, inc, (inc * 2), true, false)
  end

  def self.make_selection(rndkscreen, x, y)
    return RNDK::SELECTION.new(rndkscreen, x, y, RNDK::NONE, 8, 20,
        'Selection', TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        TraverseExample::CHOICES, TraverseExample::CHOICES.size,
        Ncurses::A_REVERSE, true, false)
  end

  def self.make_swindow(rndkscreen, x, y)
    widget = RNDK::SWINDOW.new(rndkscreen, x, y, 6, 25,
        'SWindow', 100, true, false)
    (0...30).each do |n|
      widget.add('Line %d' % [n], RNDK::BOTTOM)
    end
    widget.activate([])
    return widget
  end

  def self.make_template(rndkscreen, x, y)
    overlay = '</B/6>(___)<!6> </5>___-____'
    plate = '(###) ###-####'
    widget = RNDK::TEMPLATE.new(rndkscreen, x, y, 'Template', 'Label',
        plate, overlay, true, false)
    widget.activate([])
    return widget
  end

  def self.make_uscale(rndkscreen, x, y)
    low = 0
    high = 65535
    inc = 1
    return RNDK::USCALE.new(rndkscreen, x, y, 'UScale', 'Label',
        Ncurses::A_NORMAL, 5, low, low, high, inc, (inc * 32), true, false)
  end

  def self.make_uslider(rndkscreen, x, y)
    low = 0
    high = 65535
    inc = 1
    return RNDK::USLIDER.new(rndkscreen, x, y, 'USlider', 'Label',
        Ncurses::A_REVERSE | Ncurses.COLOR_PAIR(29) | ' '.ord, 20,
        low, low, high, inc, (inc * 32), true, false)
  end

  def self.make_viewer(rndkscreen, x, y)
    button = ['Ok']
    widget = RNDK::VIEWER.new(rndkscreen, x, y, 10, 20, button, 1,
        Ncurses::A_REVERSE, true, false)

    widget.set('Viewer', TraverseExample::MONTHS, TraverseExample::MONTHS.size,
        Ncurses::A_REVERSE, false, true, true)
    widget.activate([])
    return widget
  end

  def self.rebind_esc(obj)
    obj.bind(obj.object_type, RNDK::KEY_F(1), :getc, RNDK::KEY_ESC)
  end

  def self.make_any(rndkscreen, menu, type)
    func = nil
    # setup positions, staggered a little
    case menu
    when 0
      x = RNDK::LEFT
      y = 2
    when 1
      x = RNDK::CENTER
      y = 4
    when 2
      x = RNDK::RIGHT
      y = 2
    else
      RNDK.Beep
      return
    end

    # Find the function to make a widget of the given type
    case type
    when :ALPHALIST
      func = :make_alphalist
    when :BUTTON
      func = :make_button
    when :BUTTONBOX
      func = :make_buttonbox
    when :CALENDAR
      func = :make_calendar
    when :DIALOG
      func = :make_dialog
    when :DSCALE
      func = :make_dscale
    when :ENTRY
      func = :make_entry
    when :FSCALE
      func = :make_fscale
    when :FSELECT
      func = :make_fselect
    when :FSLIDER
      func = :make_fslider
    when :GRAPH
      func = :make_graph
    when :HISTOGRAM
      func = :make_histogram
    when :ITEMLIST
      func = :make_itemlist
    when :LABEL
      func = :make_label
    when :MARQUEE
      func = :make_marquee
    when :MATRIX
      func = :make_matrix
    when :MENTRY
      func = :make_mentry
    when :RADIO
      func = :make_radio
    when :SCALE
      func = :make_scale
    when :SCROLL
      func = :make_scroll
    when :SELECTION
      func = :make_selection
    when :SLIDER
      func = :make_slider
    when :SWINDOW
      func = :make_swindow
    when :TEMPLATE
      func = :make_template
    when :USCALE
      func = :make_uscale
    when :USLIDER
      func = :make_uslider
    when :VIEWER
      func = :make_viewer
    when :MENU, :TRAVERSE, :NULL
      RNDK.Beep
      return
    end

    # erase the old widget
    unless (prior = @@all_objects[menu]).nil?
      prior.erase
      prior.destroy
      @@all_objects[menu] = nil
    end

    # Create the new widget
    if func.nil?
      RNDK.Beep
    else
      widget = self.send(func, rndkscreen, x, y)
      if widget.nil?
        Ncurses.flash
      else
        @@all_objects[menu] = widget
        self.rebind_esc(widget)
      end
    end
  end

  # Whenever we get a menu selection, create the selected widget.
  def self.preHandler(rndktype, object, client_data, input)
    screen = nil
    window = nil

    case input
    when Ncurses::KEY_ENTER, RNDK::KEY_RETURN
      mtmp = []
      stmp = []
      object.getCurrentItem(mtmp, stmp)
      mp = mtmp[0]
      sp = stmp[0]

      screen = object.screen
      window = screen.window

      Ncurses.mvwaddstr(window, (Ncurses.getmaxy(window) - 1), 0, ('selection %d/%d' % [mp, sp]))
      Ncurses.clrtoeol
      Ncurses.refresh
      if sp >= 0 && sp < TraverseExample::MENU_TABLE.size
        self.make_any(screen, mp, TraverseExample::MENU_TABLE[sp][1])
      end
    end
    return 1
  end

  # This demonstrates the Rndk widget-traversal
  def TraverseExample.main
    menulist = [['Left'], ['Center'], ['Right']]
    submenusize = [TraverseExample::MENU_TABLE.size + 1] * 3
    menuloc = [RNDK::LEFT, RNDK::LEFT, RNDK::RIGHT]

    (0...TraverseExample::MY_MAX).each do |j|
      (0...TraverseExample::MENU_TABLE.size).each do |k|
        menulist[j] << TraverseExample::MENU_TABLE[k][0]
      end
    end

    # Create the curses window.
    curses_win = Ncurses.initscr
    rndkscreen = RNDK::SCREEN.new(curses_win)

    # Start RNDK colours.
    RNDK::Draw.initRNDKColor

    menu = RNDK::MENU.new(rndkscreen, menulist, TraverseExample::MY_MAX,
        submenusize, menuloc, RNDK::TOP, Ncurses::A_UNDERLINE,
        Ncurses::A_REVERSE)

    if menu.nil?
      rndkscreen.destroy
      RNDK::SCREEN.endRNDK

      puts '? Cannot create menus'
      exit  # EXIT_FAILURE
    end
    TraverseExample.rebind_esc(menu)

    pre_handler = lambda do |rndktype, object, client_data, input|
      TraverseExample.preHandler(rndktype, object, client_data, input)
    end

    menu.setPreProcess(pre_handler, nil)

    # Set up the initial display
    TraverseExample.make_any(rndkscreen, 0, :ENTRY)
    if TraverseExample::MY_MAX > 1
      TraverseExample.make_any(rndkscreen, 1, :ITEMLIST)
    end
    if TraverseExample::MY_MAX > 2
      TraverseExample.make_any(rndkscreen, 2, :SELECTION)
    end

    # Draw the screen
    rndkscreen.refresh

    # Traverse the screen
    RNDK::Traverse.traverseRNDKScreen(rndkscreen)

    mesg = [
        'Done',
        '',
        '<C>Press any key to continue'
    ]
    rndkscreen.popupLabel(mesg, 3)

    # clean up and exit
    (0...TraverseExample::MY_MAX).each do |j|
      if j < @@all_objects.size && !(@@all_objects[j]).nil?
        @@all_objects[j].destroy
      end
    end
    menu.destroy
    rndkscreen.destroy
    RNDK::SCREEN.endRNDK

    exit  # EXIT_SUCCESS
  end
end

TraverseExample.main
