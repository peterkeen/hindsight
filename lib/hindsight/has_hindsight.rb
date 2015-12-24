module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Hindsight::ClassMethods
      include Hindsight::InstanceMethods

      has_many :versions, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id do
        def previous
          where('version < ?', proxy_association.owner.version).reorder('version DESC').first
        end
        def next
          where('version > ?', proxy_association.owner.version).reorder('version ASC').first
        end
      end

      after_create :init_versioned_record_id
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def new_version(&block)
      create_new_version(&block)
    end

    def create_or_update_with_versioning
      next_version = create_new_version
      self.id = next_version.id
      reload
      return true
    end

    def self.included(base)
      base.alias_method_chain :create_or_update, :versioning
    end

    private

    def create_new_version(&block)
      new_version = dup
      new_version.version += 1
      apply_has_many_associations(new_version)
      apply_has_many_through_associations(new_version)
      new_version.send(:create_or_update_without_versioning, &block)
      return new_version
    end

    def apply_has_many_associations(new_version)
      # TODO
    end

    def apply_has_many_through_associations(new_version)
      # TODO
    end

    def init_versioned_record_id
      update_column(:versioned_record_id, id) unless versioned_record_id.present?
    end
  end
end
