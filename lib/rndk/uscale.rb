require 'rndk/scale'

module RNDK
  class UScale < Scale
    # The original UScale handled unsigned values.
    # Since Ruby's typing is different this is really just Scale
    # but is nice it's nice to have this for compatibility/completeness
    # sake.

    @widget_type = :UScale
  end
end
