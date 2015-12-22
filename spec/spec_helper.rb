# Configure Rails Environment
require 'active_record'
require 'hindsight'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database => "hindsight_test")

ActiveRecord::Schema.define(:version => 0) do
  create_table :documents, :force => true do |t|
    t.text :body
    t.integer :version, :null => false, :default => 0
    t.integer :versioned_record_id
  end

  create_table :people, :force => true do |t|
  end

  create_table :document_people, :force => true do |t|
    t.references :documents, :index => true
    t.references :people, :index => true
  end
end

class Document < ActiveRecord::Base
  has_many :people, :through => :document_people

  has_hindsight
end

class People < ActiveRecord::Base
  has_many :people, :through => :document_people
end

class DocumentPeople < ActiveRecord::Base
  belongs_to :document
  belongs_to :person
end

# Manually implement transactional examples because we're not using rspec_rails
RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# Make it easy to say expect(object).to not_have_any( be_sunday )
# The opposite of saying expect(object).to all( be_sunday )
RSpec::Matchers.define_negated_matcher :have_none, :include
