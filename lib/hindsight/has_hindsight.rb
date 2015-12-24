module Hindsight
  module ActMethod
    def has_hindsight(options = {})
      extend Hindsight::ClassMethods
      include Hindsight::InstanceMethods

      has_many :versions, :class_name => name, :primary_key => :versioned_record_id, :foreign_key => :versioned_record_id do
        def previous
          where('version < ?', proxy_association.owner.version).reorder('version DESC').first
        end
        def next
          where('version > ?', proxy_association.owner.version).reorder('version ASC').first
        end
      end

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

      # Ensure all attributes are saved
      self.attributes.each do |attribute, value|
        send("#{attribute}_will_change!")
      end
    end

    def increment_version
      self.version += 1
    end

    def init_versioned_record_id
      update_column(:versioned_record_id, id) unless versioned_record_id.present?
    end
  end
end
