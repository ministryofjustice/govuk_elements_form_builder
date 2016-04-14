require 'rails_helper'

RSpec.describe GovukElementsErrorsHelper, type: :helper do

  let(:resource)  { Person.new }
  let(:error_summary_heading) { 'Message to alert the user to a problem goes here' }
  let(:error_summary_description) { 'Optional description of the errors and how to correct them' }

  def split_html output
    output.split('>').join(">\n")
  end

  describe '#error_summary when object has validation errors' do
    it 'outputs error full messages' do
      resource.valid?
      output = described_class.error_summary resource, error_summary_heading, error_summary_description
      expect(split_html(output)).to eq split_html('<div ' +
          'class="error-summary" role="group" aria-labelledby="error-summary-heading" tabindex="-1">' +
        '<h1 id="error-summary-heading" class="heading-medium error-summary-heading">' +
          error_summary_heading +
        '</h1>' +
        '<p>' +
          error_summary_description +
        '</p>' +
        '<ul class="error-summary-list">' +
          '<li><a href="#error_person_name">Full name can&#39;t be blank</a></li>' +
        '</ul>' +
      '</div>')
    end
  end

  describe '#error_summary when child object has validation errors' do
    it 'outputs error full messages of child object' do
      resource.address = Address.new
      resource.address.valid?

      output = described_class.error_summary resource, error_summary_heading, error_summary_description
      expect(output).to_not be_nil
      expect(split_html(output)).to eq split_html('<div ' +
          'class="error-summary" role="group" aria-labelledby="error-summary-heading" tabindex="-1">' +
        '<h1 id="error-summary-heading" class="heading-medium error-summary-heading">' +
          error_summary_heading +
        '</h1>' +
        '<p>' +
          error_summary_description +
        '</p>' +
        '<ul class="error-summary-list">' +
          '<li><a href="#error_person_address_attributes_postcode">Postcode can&#39;t be blank</a></li>' +
        '</ul>' +
      '</div>')
    end
  end

  describe '#error_summary when twice nested child object has validation errors' do
    it 'outputs error full messages of child object' do
      resource.address = Address.new
      resource.address.country = Country.new
      resource.address.country.valid?

      output = described_class.error_summary resource, error_summary_heading, error_summary_description
      expect(output).to_not be_nil
      expect(split_html(output)).to eq split_html('<div ' +
          'class="error-summary" role="group" aria-labelledby="error-summary-heading" tabindex="-1">' +
        '<h1 id="error-summary-heading" class="heading-medium error-summary-heading">' +
          error_summary_heading +
        '</h1>' +
        '<p>' +
          error_summary_description +
        '</p>' +
        '<ul class="error-summary-list">' +
          '<li><a href="#error_person_address_attributes_country_attributes_name">Country can&#39;t be blank</a></li>' +
        '</ul>' +
      '</div>')
    end
  end

  describe '#error_summary when object does not have validation errors' do
    it 'outputs nil' do
      output = described_class.error_summary resource, error_summary_heading, error_summary_description
      expect(output).to eq nil
    end
  end

end
