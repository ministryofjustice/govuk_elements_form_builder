[![Stories in Ready](https://badge.waffle.io/ministryofjustice/govuk_elements_form_builder.png?label=ready&title=Ready)](https://waffle.io/ministryofjustice/govuk_elements_form_builder)
Build Status: [![Build Status](https://travis-ci.org/ministryofjustice/govuk_elements_form_builder.svg)](https://travis-ci.org/ministryofjustice/govuk_elements_form_builder)

Code Climate: <a href="https://codeclimate.com/github/ministryofjustice/govuk_elements_form_builder"><img src="https://codeclimate.com/github/ministryofjustice/govuk_elements_form_builder/badges/gpa.svg" /></a> <a href="https://codeclimate.com/github/ministryofjustice/govuk_elements_form_builder/coverage"><img src="https://codeclimate.com/github/ministryofjustice/govuk_elements_form_builder/badges/coverage.svg" /></a>
# GovukElementsFormBuilder

To build GOV.UK based services you need to use [govuk_elements](https://github.com/alphagov/govuk_elements) for presentation and [govuk_frontend_toolkit](https://github.com/alphagov/govuk_frontend_toolkit) for the interaction aspects.

This gem serves a form builder and other various helper methods to produces the markup required to leverage presentation and interaction without having to recreate the markup yourself.

## Installation

Add these lines to your application's Gemfile, form builder is the last gem in list:

```ruby
gem 'govuk_frontend_toolkit'
gem 'govuk_elements_rails'
gem 'govuk_elements_form_builder', git: 'https://github.com/ministryofjustice/govuk_elements_form_builder.git'
```

And then execute:

```sh
bundle
```

## Usage

In your application's `config/application.rb` file, configure the form builder to be the default like this:

```rb
  class Application < Rails::Application
    # ...
    ActionView::Base.default_form_builder = GovukElementsFormBuilder::FormBuilder
  end
```

You can see a visual guide to [using the form builder](https://govuk-elements-rails-guide.herokuapp.com/) here:
https://govuk-elements-rails-guide.herokuapp.com/

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/govuk_elements_form_builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
