module Hindsight
  module AssociationConditions
    # Returns a lambda that provides association conditions that filter out all but the latest version of the associated records
    def self.latest_version
      lambda do
        table_name = klass.table_name
        table_alias = "#{table_name}_right"

        joins("LEFT JOIN #{table_name} #{table_alias} ON #{table_name}.versioned_record_id = #{table_alias}.versioned_record_id AND #{table_name}.version < #{table_alias}.version")
          .where(table_alias => { :version => nil })
      end
    end
  end
end
