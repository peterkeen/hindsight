# LIB
require 'hindsight/has_hindsight'
require 'hindsight/hindsight/association_conditions'

module Hindsight
end

# Load the act method
ActiveRecord::Base.send :extend, Hindsight::ActMethod
