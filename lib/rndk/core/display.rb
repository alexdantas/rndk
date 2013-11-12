
module RNDK

  # ...I still don't know what this module does...
  #
  module Display

    # Given a string, returns the equivalent display type
    def Display.char_to_display_type string
      table = {
        "CHAR"     => :CHAR,
        "HCHAR"    => :HCHAR,
        "INT"      => :INT,
        "HINT"     => :HINT,
        "UCHAR"    => :UCHAR,
        "LCHAR"    => :LCHAR,
        "UHCHAR"   => :UHCHAR,
        "LHCHAR"   => :LHCHAR,
        "MIXED"    => :MIXED,
        "HMIXED"   => :HMIXED,
        "UMIXED"   => :UMIXED,
        "LMIXED"   => :LMIXED,
        "UHMIXED"  => :UHMIXED,
        "LHMIXED"  => :LHMIXED,
        "VIEWONLY" => :VIEWONLY,
        0          => :INVALID
      }

      if table.include?(string)
        table[string]
      else
        :INVALID
      end
    end

    # Tell if a display type is "hidden"
    def Display.is_hidden_display_type type
      case type
      when :HCHAR, :HINT, :HMIXED, :LHCHAR, :LHMIXED, :UHCHAR, :UHMIXED
        true
      when :CHAR, :INT, :INVALID, :LCHAR, :LMIXED, :MIXED, :UCHAR,
          :UMIXED, :VIEWONLY
        false
      end
    end

    # Given a character input, check if it is allowed by the
    # display type and return the character to apply to the display,
    # or ERR if not.
    def Display.filter_by_display_type(type, input)
      result = input
      if not RNDK.is_char? input
        result = Ncurses::ERR

      elsif ([:INT, :HINT].include? type) and (not RNDK.digit? result.chr)
        result = Ncurses::ERR

      elsif ([:CHAR, :UCHAR, :LCHAR, :UHCHAR, :LHCHAR].include? type) and (RNDK.digit? result.chr)
        result = Ncurses::ERR

      elsif type == :VIEWONLY
        result = ERR

      elsif ([:UCHAR, :UHCHAR, :UMIXED, :UHMIXED].include? type) and (RNDK.is_alpha? result.chr)
        result = result.chr.upcase.ord

      elsif ([:LCHAR, :LHCHAR, :LMIXED, :LHMIXED].include? type) and (RNDK.is_alpha? result.chr)
        result = result.chr.downcase.ord
      end
      result
    end

  end
end
