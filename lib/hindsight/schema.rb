module Hindsight
  module Schema
    def self.version_table!(*table_names)
      table_names.flatten.each do |table_name|
        ActiveRecord::Schema.define do
          add_column table_name, :versioned_record_id, :integer
          add_column table_name, :version, :integer, :null => false, :default => 0
          add_column table_name, :version_type, :string, :null => false, :default => ''

          execute("UPDATE #{table_name} SET versioned_record_id = id")

          add_index table_name, [:versioned_record_id, :version], :unique => true
        end
      end
    end
  end
end
