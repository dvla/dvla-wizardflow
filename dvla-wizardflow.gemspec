$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "dvla/wizardflow/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dvla-wizardflow"
  s.version     = Dvla::Wizardflow::VERSION
  s.authors     = ["Neil Williams"]
  s.email       = ["neil.williams@dvla.gsi.gov.uk"]
  s.homepage    = ""
  s.summary     = "Summary of DvlaWizardflow."
  s.description = "Description of DvlaWizardflow."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.metadata['allowed_push_host'] = ''

  s.add_dependency "rails", "~> 5.2.0"
end
