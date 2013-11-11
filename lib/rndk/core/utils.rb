# Utility functions.
#
#

module RNDK

  # Number of digits `value` has when represented as a String.
  def RNDK.intlen value
    value.to_str.size
  end

  # Opens the current directory and reads the contents.
  def RNDK.getDirectoryContents(directory, list)
    counter = 0

    Dir.foreach(directory) do |filename|
      next if filename == '.'
      list << filename
    end

    list.sort!
    return list.size
  end

  # This looks for a subset of a word in the given list
  def RNDK.searchList(list, list_size, pattern)
    index = -1

    if pattern.size > 0
      (0...list_size).each do |x|
        len = [list[x].size, pattern.size].min
        ret = (list[x][0...len] <=> pattern)

        # If 'ret' is less than 0 then the current word is alphabetically
        # less than the provided word.  At this point we will set the index
        # to the current position.  If 'ret' is greater than 0, then the
        # current word is alphabetically greater than the given word. We
        # should return with index, which might contain the last best match.
        # If they are equal then we've found it.
        if ret < 0
          index = ret
        else
          if ret == 0
            index = x
          end
          break
        end
      end
    end
    return index
  end

  # This function checks to see if a link has been requested
  def RNDK.checkForLink (line, filename)
    f_pos = 0
    x = 3
    if line.nil?
      return -1
    end

    # Strip out the filename.
    if line[0] == L_MARKER && line[1] == 'F' && line[2] == '='
      while x < line.size
        if line[x] == R_MARKER
          break
        end
        if f_pos < RNDK_PATHMAX
          filename << line[x]
          f_pos += 1
        end
        x += 1
      end
    end
    return f_pos != 0
  end

  # Returns the filename portion of the given pathname, i.e. after the last
  # slash
  # For now this function is just a wrapper for File.basename kept for ease of
  # porting and will be completely replaced in the future
  def RNDK.baseName (pathname)
    File.basename(pathname)
  end

  # Returns the directory for the given pathname, i.e. the part before the
  # last slash
  # For now this function is just a wrapper for File.dirname kept for ease of
  # porting and will be completely replaced in the future
  def RNDK.dirName (pathname)
    File.dirname(pathname)
  end

  # If the dimension is a negative value, the dimension will be the full
  # height/width of the parent window - the value of the dimension. Otherwise,
  # the dimension will be the given value.
  def RNDK.setWidgetDimension (parent_dim, proposed_dim, adjustment)
    # If the user passed in FULL, return the parents size
    if proposed_dim == FULL or proposed_dim == 0
      parent_dim
    elsif proposed_dim >= 0
      # if they gave a positive value, return it

      if proposed_dim >= parent_dim
        parent_dim
      else
        proposed_dim + adjustment
      end
    else
      # if they gave a negative value then return the dimension
      # of the parent plus the value given
      #
      if parent_dim + proposed_dim < 0
        parent_dim
      else
        parent_dim + proposed_dim
      end
    end
  end

  # Reads a file and concatenate it's lines into `array`.
  #
  # @note The lines don't end with '\n'.
  def RNDK.read_file(filename, array)
    begin
      fd = File.new(filename, "r")
    rescue
      return nil
    end

    lines = fd.readlines.map do |line|
      if line.size > 0 && line[-1] == "\n"
        line[0...-1]
      else
        line
      end
    end

    array.concat lines
    fd.close
    array.size
  end

end

