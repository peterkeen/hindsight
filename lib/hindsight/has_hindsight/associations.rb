module Hindsight
  module ClassMethods
    # Modify versioned associations so they return only the latest version of the associated record
    def has_versioned_association(*associations)
      associations = associations.flatten.compact.collect(&:to_sym)
      associations.each do |association|
        # Duplicate reflection under as "#{association}_versions"
        all_versions_association = :"#{association}_versions"
        reflection = reflect_on_association(association)
        send(reflection.macro, all_versions_association, reflection.options.reverse_merge(:class_name => association.to_s.classify, :source => association.to_s.singularize))

        # Create an association that returns only the latest versions of associated records as appropriate
        send(reflection.macro, association, versioned_association_condition(all_versions_association), reflection.options)
      end
    end

    private

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

    # Copy associations with a foreign_key to this record, onto the new version
    def copy_associations_to(new_version)
      versioned_associations.each do |association|
        Hindsight.debug "Copying #{association} from #{self.inspect} to #{new_version.inspect}" if send(association).present?
        new_version.send("#{association}=", send(association))
      end
    end

    def versioned_associations
      Array.wrap(hindsight_options[:versioned_associations])
    end
  end
end
