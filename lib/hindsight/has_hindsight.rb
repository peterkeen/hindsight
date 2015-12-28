module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Hindsight::ClassMethods
      include Hindsight::InstanceMethods

      class_attribute :hindsight_options
      self.hindsight_options = options

      has_many :versions, lambda { extending(AssociationExtensions) }, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id
      has_versioned_association hindsight_options[:versioned_associations]

      after_create :init_versioned_record_id
    end
  end

  module AssociationExtensions
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

    def latest_versions(version_table = table_name)
      joins("LEFT JOIN #{version_table} versions
                    ON #{table_name}.versioned_record_id = versions.versioned_record_id
                   AND #{table_name}.version < versions.version")
      .where('versions' => { :version => nil })
    end

    # Modify versioned associations so they return only the latest version of the associated record
    def has_versioned_association(*association_names)
      association_names = association_names.flatten.compact
      association_names.each do |association_name|
        # Duplicate reflection under as "#{association_name}_versions"
        all_versions_association_name = :"#{association_name}_versions"
        reflection = reflect_on_association(association_name)
        send(reflection.macro, all_versions_association_name, reflection.options.reverse_merge(:class_name => reflection.class_name))

        # Create an association that returns only the latest versions of associated records as appropriate
        send(reflection.macro, association_name, latest_version_association_lambda(all_versions_association_name), reflection.options)
      end
    end

    private

    # Returns a condition for use in a versioned has_many association
    # If the record is the latest version, return only the latest versions of associated records
    # Else, return the latest version of each associated record that is associated with this version
    def latest_version_association_lambda(all_versions_association_name)
      lambda do |record|
        if record.latest_version?
          latest_versions
        else
          latest_versions "(#{record.send(all_versions_association_name).to_sql})"
        end
      end
    end
  end

  module InstanceMethods
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

    def self.included(base)
      base.alias_method_chain :create_or_update, :versioning
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
      new_version = dup
      new_version.version += 1
      copy_associations_to(new_version)
      Hindsight.debug "Saving #{self.inspect}" do
        new_version.assign_attributes(attributes) if attributes
        new_version.send(:create_or_update_without_versioning, &block)
      end
      return new_version
    end

    # Copy associations with a foreign_key to this record, onto the new version
    def copy_associations_to(new_version)
      self.class.reflections.each do |association_name, reflection|
        next if association_name.end_with? 'versions' # Don't try to copy versions
        case reflection
        when ActiveRecord::Reflection::HasManyReflection
          Hindsight.debug "Copying #{association_name} from #{self.inspect} to #{new_version.inspect}" if send(association_name).present?
          new_version.send("#{association_name}=", send(association_name))
        end
      end
    end

    def has_hindsight?(other)
      other.acts_like? :hindsight
    end

    def init_versioned_record_id
      update_column(:versioned_record_id, id) unless versioned_record_id.present?
    end
  end

  # DEBUG

  def self.debug(message, &block)
    @indent ||= 0
    indent = '  ' * @indent
    # puts indent + message
    @indent += 1
    block.call if block_given?
  ensure
    @indent -= 1
  end
end
