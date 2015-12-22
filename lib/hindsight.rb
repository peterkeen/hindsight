# LIB
require 'hindsight/has_hindsight'

module Hindsight
end

# Load the act method
ActiveRecord::Base.send :extend, Hindsight::ActMethod
