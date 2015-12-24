# Configure Rails Environment
require 'pry'
require 'active_record'
require 'hindsight'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database => "hindsight_test")

ActiveRecord::Schema.define(:version => 0) do
  create_table :companies, :force => true do |t|
    t.string :name
    t.integer :version, :null => false, :default => 0
    t.integer :versioned_record_id
  end

  create_table :projects, :force => true do |t|
    t.string :name
    t.integer :version, :null => false, :default => 0
    t.integer :versioned_record_id
  end

  create_table :documents, :force => true do |t|
    t.references :project, :index => true
    t.text :body
    t.integer :version, :null => false, :default => 0
    t.integer :versioned_record_id
  end

  create_table :authors, :force => true do |t|
  end

  create_table :document_authors, :force => true do |t|
    t.references :document, :index => true
    t.references :author, :index => true
  end

  create_table :project_companies, :force => true do |t|
    t.references :project, :index => true
    t.references :company, :index => true
  end
end

class Company < ActiveRecord::Base
  has_many :projects, :through => :project_companies # versioned has_many :through
  # has_hindsight
end

class Project < ActiveRecord::Base
  has_many :documents # versioned has_many
  has_many :project_companies
  has_many :companies, :through => :project_companies # versioned has_many :through
  has_hindsight
end

class Document < ActiveRecord::Base
  has_many :authors, :through => :document_authors # non-versioned has_many :through
  has_many :comments # non-versioned has_many
  has_hindsight
end

class Authors < ActiveRecord::Base
  has_many :documents, :through => :document_authors
end

class Comments < ActiveRecord::Base
  belongs_to :document
end

class ProjectCompany < ActiveRecord::Base
  belongs_to :project
  belongs_to :company
end

class DocumentAuthors < ActiveRecord::Base
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
