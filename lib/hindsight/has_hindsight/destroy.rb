module Hindsight
  module Destroy
    module ClassMethods
      def destroyed
        where(:version_type => 'destroy')
      end

      def not_destroyed
        where.not(:version_type => 'destroy')
      end
    end

    module InstanceMethods
      def self.included(base)
        base.alias_method_chain :destroy_row, :versioning
      end

      def destroy_row_with_versioning
        update_attributes(:version_type => 'destroy') and return 1 unless soft_destroyed?
      end

      def soft_destroyed?
        versions.destroyed.exists?
      end
    end
  end
end
