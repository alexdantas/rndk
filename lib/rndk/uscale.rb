require 'rndk/scale'

module RNDK
  class USCALE < SCALE
    # The original UScale handled unsigned values.
    # Since Ruby's typing is different this is really just SCALE
    # but is nice it's nice to have this for compatibility/completeness
    # sake.

    @widget_type = :USCALE
  end
end
