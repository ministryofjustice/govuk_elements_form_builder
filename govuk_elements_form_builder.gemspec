$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "govuk_elements_form_builder/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "govuk_elements_form_builder"
  s.version     = GovukElementsFormBuilder::VERSION
  s.authors     = ["Alistair Laing","Rob McKinnon"]
  s.email       = ["Alistair.Laing@Digital.Justice.gov.uk"]
  s.homepage    = "https://github.com/ministryofjustice/govuk_elements_form_builder"
  s.summary     = "Ruby on Rails form builder that generates GOV.UK elements styled markup for forms."
  s.description = "Custom Ruby on Rails form builder that generates GOV.UK elements styled markup for form inputs, including error validation messages."
  s.license     = "MIT"

  s.files = Dir["{app,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", ">= 4.2"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency 'rspec-html-matchers'
  s.add_development_dependency 'htmlbeautifier'
  s.add_development_dependency 'codeclimate-test-reporter'

  s.add_development_dependency "byebug"
end
