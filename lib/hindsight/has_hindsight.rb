require 'hindsight/has_hindsight/debug'
require 'hindsight/has_hindsight/associations'
require 'hindsight/has_hindsight/errors'

module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Hindsight::ClassMethods
      include Hindsight::InstanceMethods

      class_attribute :hindsight_options
      self.hindsight_options = options

      has_many :versions, lambda { extending(VersionAssociationExtensions) }, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id
      has_versioned_association hindsight_options[:versioned_associations]

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

  module ClassMethods
    def acts_like_hindsight?
      true
    end

    # Scope to return only the latest versions of records
    # version_scope can be overridden to limit the scope of the lateset version calculation,
    # e.g. if only the latest version that was attached to a particular record is desired,
    # pass Document.where(:id => 3)
    def latest_versions(version_scope = self)
      joins("LEFT JOIN (#{version_scope.all.to_sql}) versions
                    ON #{table_name}.versioned_record_id = versions.versioned_record_id
                   AND #{table_name}.version < versions.version")
      .where('versions' => { :version => nil })
    end
  end

  module InstanceMethods
    def self.included(base)
      base.alias_method_chain :create_or_update, :versioning
    end

    def acts_like_hindsight?
      true
    end

    # Returns a new instance of this record at this version
    # Makes it easy to compare versions as they change
    def snapshot
      self.class.find(id)
    end

    def new_version(attributes = nil, &block)
      create_new_version(attributes, &block)
    end

    def create_or_update_with_versioning
      become_version(create_new_version)
      return true
    end

    def become_current
      become_version(versions.last)
    end

    def latest_version?
      self.class.latest_versions.exists?(id)
    end

    private

    def become_version(version)
      self.id = version.id
      init_internals
      reload
    end

    def create_new_version(attributes = nil, &block)
      new_version_check!
      new_version = dup
      new_version.version += 1
      copy_associations_to(new_version)
      Hindsight.debug "Saving #{self.inspect}" do
        new_version.assign_attributes(attributes) if attributes
        new_version.send(:create_or_update_without_versioning, &block)
      end
      return new_version
    end

    def new_version_check!
      raise Hindsight::ReadOnlyVersion, "#{self.class.name} is not the latest version" unless latest_version? || new_record?
    end

    def has_hindsight?(other)
      other.acts_like? :hindsight
    end

    def init_versioned_record_id
      update_column(:versioned_record_id, id) unless versioned_record_id.present?
    end
  end
end
