module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Hindsight::ClassMethods
      include Hindsight::InstanceMethods

      has_many :versions, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id

      before_save :prepare_version
      after_create :init_versioned_record_id
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    private

    def prepare_version
      new_record!
      increment_version
    end

    def new_record!
      self.id = nil
      @new_record = true
    end

    def increment_version
      self.version += 1
    end

    def init_versioned_record_id
      update_column(:versioned_record_id, id) unless versioned_record_id?
    end
  end
end
