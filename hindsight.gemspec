$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "hindsight/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "culturecode_hindsight"
  s.version     = Hindsight::VERSION
  s.authors     = ["Ryan Wallace", "Nicholas Jakobsen"]
  s.email       = ["contact@culturecode.ca"]
  s.homepage    = "https://github.com/culturecode/hindsight"
  s.summary     = "Versioning for your ActiveRecord models"
  s.description = "Versioning for your ActiveRecord models"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["rspec/**/*"]

  s.add_dependency "activerecord", '~> 4.1'

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec"
end
