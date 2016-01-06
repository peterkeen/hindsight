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
  end

  create_table :projects, :force => true do |t|
    t.string :name
  end

  create_table :documents, :force => true do |t|
    t.references :project, :index => true
    t.string :title
    t.text :body
  end

  create_table :authors, :force => true do |t|
  end

  create_table :comments, :force => true do |t|
    t.references :document, :index => true
  end

  create_table :document_authors, :force => true do |t|
    t.references :document, :index => true
    t.references :author, :index => true
  end

  create_table :project_companies, :force => true do |t|
    t.references :project, :index => true
    t.references :company, :index => true
  end

  Hindsight::Schema.version_table(:companies, :projects, :documents)
end

class Company < ActiveRecord::Base
  has_many :project_companies
  has_many :projects, :through => :project_companies

  has_hindsight :versioned_associations => :projects
end

class Project < ActiveRecord::Base
  has_many :documents
  has_many :project_companies
  has_many :companies, :through => :project_companies

  has_hindsight :versioned_associations => [:documents, :companies]
end

class Document < ActiveRecord::Base
  belongs_to :project
  has_many :document_authors
  has_many :authors, :through => :document_authors
  has_many :comments

  has_hindsight :versioned_associations => []
end

class Author < ActiveRecord::Base
  has_many :documents, :through => :document_authors
end

class Comment < ActiveRecord::Base
  belongs_to :document
end

class ProjectCompany < ActiveRecord::Base
  belongs_to :project
  belongs_to :company
end

class DocumentAuthor < ActiveRecord::Base
  belongs_to :document
  belongs_to :author
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
