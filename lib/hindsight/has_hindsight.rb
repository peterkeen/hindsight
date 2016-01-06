require 'hindsight/has_hindsight/base'
require 'hindsight/has_hindsight/save'
require 'hindsight/has_hindsight/associations'
require 'hindsight/has_hindsight/errors'
require 'hindsight/has_hindsight/debug'

module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Base::ClassMethods
      extend Save::ClassMethods
      extend Associations::ClassMethods

      include Base::InstanceMethods
      include Save::InstanceMethods
      include Associations::InstanceMethods

      if options[:versioned_associations]
        has_versioned_association(options[:versioned_associations])
      else
        detect_versioned_associations
      end

      has_many :versions, lambda { extending(VersionAssociationExtensions) }, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id

      after_create :init_versioned_record_id
    end
  end

  module VersionAssociationExtensions
    def previous
      where('version < ?', proxy_association.owner.version).reorder('version DESC').first
    end

    def next
      where('version > ?', proxy_association.owner.version).reorder('version ASC').first
    end
  end
end
