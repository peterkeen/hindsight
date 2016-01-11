module Hindsight
  module Associations
    VERSIONING_CAPABILITIES = {
      ActiveRecord::Reflection::HasManyReflection => {:versionable => true, :new_version_on_copy => true },
      ActiveRecord::Reflection::ThroughReflection => {:versionable => true, :unversioned_history => true }
    }.freeze

    def self.is?(reflection, capability)
      VERSIONING_CAPABILITIES.fetch(reflection.class, {}).fetch(capability, false)
    end

    module ClassMethods
      def self.extended(base)
        base.class_attribute :versioned_associations, :ignored_associations
        base.versioned_associations ||= []
        base.ignored_associations ||= []
      end

      # Modify versioned associations so they return only the latest version of the associated record
      def has_versioned_association(*associations)
        associations = associations.flatten.compact.collect(&:to_sym)
        associations.each do |association|
          versioned_associations << association.to_sym

          # Duplicate reflection under as "#{association}_versions"
          all_versions_association = :"#{association}_versions"
          reflection = reflect_on_association(association)
          send(reflection.macro, all_versions_association, reflection.options.reverse_merge(:class_name => association.to_s.classify, :source => association.to_s.singularize))

          # Create an association that returns only the latest versions of associated records as appropriate
          send(reflection.macro, association, versioned_association_condition(all_versions_association), reflection.options)
        end
      end

      private

      def can_populate_new_version_association?(association)
        versionable_reflection?(reflect_on_association(association.to_sym)) &&
        !ignored_association?(association) &&
        !version_association?(association) &&
        !through_association?(association)
      end

      # Identify an association that should not be copied when making new_versions
      # e.g. it is a subset of another association, like :red_cars is to :all_cars
      def ignore_association(*associations)
        ignored_associations.concat associations.flatten.compact.collect(&:to_sym)
        ignored_associations.uniq!
      end

      def detect_versioned_associations
        reflections.each do |association, reflection|
          next if versioned_associations.include?(association.to_sym)
          next if !versionable_association?(association)

          has_versioned_association(association)
        end
      end

      # Returns true if the associated model is versioned
      def versionable_association?(association)
        reflection = reflect_on_association(association)
        versionable_reflection?(reflection) && reflection.klass.acts_like?(:hindsight)
      end

      # Returns true if the association is ignored and should not be copied to the new version
      def ignored_association?(association)
        ignored_associations.include? association.to_sym
      end

      # Returns true if the association exists only to keep track of previous versions of records
      def version_association?(association)
        association.to_s.end_with? 'versions'
      end

      # Returns true if the association is the :through association for another association on the model
      def through_association?(association)
        through_associations = reflections.values.collect{|r| r.options.symbolize_keys[:through].try(:to_sym) }.compact.uniq
        through_associations.include? association.to_sym
      end

      def versionable_reflection?(reflection)
        Associations.is?(reflection, :versionable)
      end

      # Returns a condition for use in a versioned has_many association
      # If the record is the latest version, return only the latest versions of associated records
      # Else, return the latest version of each associated record that is associated with this version
      # (avoids old versions not returning an associated record if the latest version has been attached to a different record)
      def versioned_association_condition(all_versions_association)
        lambda do |record|
          if record.latest_version?
            latest_versions
          else
            latest_versions record.send(all_versions_association)
          end
        end
      end
    end

    module InstanceMethods
      private

      def copy_associations_to(new_version)
        self.class.reflections.each do |association, reflection|
          next if !self.class.send(:can_populate_new_version_association?, association)
          next if new_version.association(association.to_sym).loaded?

          records = send(association).to_a
          if reflection.klass.acts_like?(:hindsight) && Associations.is?(reflection, :new_version_on_copy)
            records.collect! {|r| r.send(:build_new_version) }
          end
          new_version.send("#{association}=", records)
        end
      end
    end
  end
end
