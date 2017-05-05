require 'rails_helper'

RSpec.describe GovukElementsErrorsHelper, type: :helper do
  include TranslationHelper

  let(:summary_title) { 'Message to alert the user to a problem goes here' }
  let(:summary_description) do
    'Optional description of the errors and how to correct them'
  end
  let(:translations) do
    YAML.load(%'
      errors:
        format: "%{message}"
      activemodel:
        errors:
          models:
            person:
              attributes:
                name:
                  blank: "Mae angen enw llawn"
            address:
              attributes:
                postcode:
                  blank: "Mae angen cod post"
            country:
              attributes:
                name:
                  blank: "Mae angen Gwlad"
    ')
  end

  let(:output) do
    described_class.error_summary(
      resource,
      summary_title,
      summary_description
    )
  end

  # Pretty up the HTML purely for the sake of clearer error messages.
  # HtmlBeautifier doesn't change or correct the HTML structure so it should be
  # safe to use.
  let(:pretty_output) { HtmlBeautifier.beautify output }

  describe '#error_summary when object has validation errors' do
    let(:resource) do
      Person.new.tap { |p| p.valid? }
    end

    it 'produces some output' do
      expect(output).to_not be_nil
    end

    it 'outputs title and description' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'h1#error-summary-heading', summary_title
        with_tag 'p', summary_description
      end
    end

    it 'outputs the specific error message' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'ul.error-summary-list' do
          with_tag 'a[href="#error_person_name"]', 'Full name is required'
        end
      end
    end

    it 'uses translation for specific error message' do
      with_translations(:cy, translations) do
        expect(pretty_output).to have_tag('div.error-summary') do
          with_tag 'ul.error-summary-list' do
            with_tag 'a[href="#error_person_name"]', 'Mae angen enw llawn'
          end
        end
      end
    end

    context 'for a namespaced resource' do
      let(:resource) { Steps::Appeal::Penalty.new.tap { |p| p.valid? } }

      it 'outputs the specific error message with correct anchoring' do
        expect(pretty_output).to have_tag('div.error-summary') do
          with_tag 'ul.error-summary-list' do
            with_tag 'a[href="#error_steps_appeal_penalty_amount"]', 'Amount is required'
          end
        end
      end
    end
  end

  describe '#error_summary when child object has validation errors' do
    let(:resource) do
      Person.new(address: Address.new).tap { |p| p.address.valid? }
    end

    it 'produces some output' do
      expect(output).to_not be_nil
    end

    it 'outputs title and description' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'h1#error-summary-heading', summary_title
        with_tag 'p', summary_description
      end
    end

    it 'outputs the specific error message' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'ul.error-summary-list' do
          with_tag(
            'a[href="#error_person_address_attributes_postcode"]',
            'Postcode is required'
          )
        end
      end
    end

    it 'uses translation for specific error message' do
      with_translations(:cy, translations) do
        expect(pretty_output).to have_tag('div.error-summary') do
          with_tag 'ul.error-summary-list' do
            with_tag(
              'a[href="#error_person_address_attributes_postcode"]',
              'Mae angen cod post'
            )
          end
        end
      end
    end
  end

  describe '#error_summary when twice nested child object has validation errors' do
    let(:resource)  do
      Person.new(address: Address.new(country: Country.new)).tap do |p|
        p.address.country.valid?
      end
    end

    it 'produces some output' do
      expect(output).to_not be_nil
    end

    it 'outputs title and description' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'h1#error-summary-heading', summary_title
        with_tag 'p', summary_description
      end
    end

    it 'outputs the specific error message' do
      expect(pretty_output).to have_tag('div.error-summary') do
        with_tag 'ul.error-summary-list' do
          with_tag(
            'a[href="#error_person_address_attributes_country_attributes_name"]',
            'Country is required'
          )
        end
      end
    end

    it 'uses translation for specific error message' do
      with_translations(:cy, translations) do
        expect(pretty_output).to have_tag('div.error-summary') do
          with_tag 'ul.error-summary-list' do
            with_tag(
              'a[href="#error_person_address_attributes_country_attributes_name"]',
              'Mae angen Gwlad'
            )
          end
        end
      end
    end
  end

  describe '#error_summary when object does not have validation errors' do
    it 'outputs nil' do
      output = described_class.error_summary(
        Person.new,
        summary_title,
        summary_description
      )
      expect(output).to eq nil
    end
  end

  context 'resource contains object with circular reference back to resource' do
    let(:resource) do
      kase = Case.new()
      kase.state_machine = StateMachine.new(object: kase)
      kase.valid?
      kase
    end

    it 'produces error message, and does not get stuck in infinite loop' do
      expect(pretty_output).to include('<a href="#error_case_name">Name is required</a>')
    end
  end

  context 'resource contains array of resources with errors' do
    let(:resource) do
      Case.new(subcases: [Case.new, Case.new]).tap { |c| c.valid? }
    end

    it 'creates separate error messages for resources in array' do
      expect(pretty_output).to include('<a href="#error_case_name">Name is required</a>')
      expect(pretty_output).to include('<a href="#error_case_case_attributes_name">Name is required</a>')
    end
  end

end
