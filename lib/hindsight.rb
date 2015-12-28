# LIB
require 'hindsight/has_hindsight'
require 'hindsight/schema'

module Hindsight
end

# Load the act method
ActiveRecord::Base.send :extend, Hindsight::ActMethod
