module Hindsight
  module Base
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
      def acts_like_hindsight?
        true
      end

      # Returns a new instance of this record at this version
      # Makes it easy to compare versions as they change
      def snapshot
        self.class.find(id)
      end

      def latest_version?
        self.class.latest_versions.exists?(id)
      end
    end
  end
end
