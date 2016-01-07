module Hindsight
  module Save
    module ClassMethods end

    module InstanceMethods
      def new_version(attributes = nil, save_options = {}, &block)
        new_version_using(:save, attributes, save_options, &block)
      end

      def new_version!(attributes = nil, save_options = {}, &block)
        new_version_using(:save!, attributes, save_options, &block)
      end

      def save(options = {})
        options.delete(:new_version) == false ? super(options) : save_using(:new_version, options)
      end

      def save!(options = {})
        options.delete(:new_version) == false ? super(options) : save_using(:new_version!, options)
      end

      def become_current
        become_version(versions.last)
      end

      private

      def save_using(new_version_method, options)
        record = send(new_version_method, nil, options)
        record ? become_version(record) : false
      end

      def new_version_using(save_method, attributes, save_options, &block)
        new_version = build_new_version(attributes, &block)
        success = new_version.send(save_method, save_options.merge(:new_version => false))
        return success ? new_version : false
      end

      def become_version(version)
        self.id = version.id
        init_internals
        reload
      end

      def build_new_version(attributes = nil, &block)
        new_version_check!
        new_version = dup
        new_version.version += 1

        copy_associations_to(new_version)
        new_version.assign_attributes(attributes) if attributes
        block.call(new_version) if block_given?

        return new_version
      end

      def new_version_check!
        raise Hindsight::ReadOnlyVersion, "#{self.class.name} is not the latest version" unless latest_version? || new_record?
      end

      def init_versioned_record_id
        update_column(:versioned_record_id, id) unless versioned_record_id.present?
      end
    end
  end
end
