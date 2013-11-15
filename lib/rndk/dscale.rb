require 'rndk/fscale'

module RNDK
  class DScale < Fscale
    # The original DScale handled unsigned values.
    # Since Ruby's typing is different this is really just Fscale
    # but is nice it's nice to have this for compatibility/completeness
    # sake.
    @widget_type = :DScale
  end
end
