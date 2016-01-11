require 'hindsight/has_hindsight/base'
require 'hindsight/has_hindsight/save'
require 'hindsight/has_hindsight/destroy'
require 'hindsight/has_hindsight/associations'
require 'hindsight/has_hindsight/errors'
require 'hindsight/has_hindsight/debug'

module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Base::ClassMethods
      extend Save::ClassMethods
      extend Destroy::ClassMethods
      extend Associations::ClassMethods

      include Base::InstanceMethods
      include Save::InstanceMethods
      include Destroy::InstanceMethods
      include Associations::InstanceMethods

      options.reverse_merge! :associations => {}

      ignore_association(options[:associations][:ignore])
      options[:associations].key?(:versioned) ? has_versioned_association(options[:associations][:versioned]) : detect_versioned_associations

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
