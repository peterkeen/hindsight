module Hindsight
  module Associations
    module ClassMethods
      def self.extended(base)
        base.class_attribute :versioned_associations
        base.versioned_associations = []
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

      def detect_versioned_associations
        reflections.each do |association, reflection|
          next if versioned_associations.include?(association.to_sym)

          case reflection
          when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::ThroughReflection
            has_versioned_association(association) if versioned_association?(association)
          end
        end
      end

      # Returns true if the associated model is versioned
      def versioned_association?(association)
        reflect_on_association(association).klass.acts_like?(:hindsight)
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
          next if version_association?(association)
          next if through_association?(association)
          next if new_version.association(association.to_sym).loaded?

          case reflection
          when ActiveRecord::Reflection::HasManyReflection
            records = send(association).to_a
            records.collect! {|r| r.send(:build_new_version) } if reflection.klass.acts_like?(:hindsight)
            new_version.send("#{association}=", records)
          when ActiveRecord::Reflection::ThroughReflection
            new_version.send("#{association}=", send(association))
          end
        end
      end

      # Returns true if the association exists only to keep track of previous versions of records
      def version_association?(association)
        association.to_s.end_with? 'versions'
      end

      # Returns true if the association is the :through association for another association on the model
      def through_association?(association)
        through_associations = self.class.reflections.values.collect{|r| r.options.symbolize_keys[:through].try(:to_sym) }.compact.uniq
        through_associations.include? association.to_sym
      end
    end
  end
end
