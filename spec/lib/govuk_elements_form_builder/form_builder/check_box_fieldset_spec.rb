# coding: utf-8
require 'rails_helper'
require 'spec_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  include TranslationHelper

  let(:helper) { TestHelper.new }
  let(:resource)  { Person.new }
  let(:builder) { described_class.new :person, resource, helper, {} }
  describe '#check_box_fieldset' do
    it 'outputs checkboxes wrapped in labels' do
      resource.waste_transport = WasteTransport.new
      output = builder.fields_for(:waste_transport) do |f|
        f.check_box_fieldset :waste_transport, [:animal_carcasses, :mines_quarries, :farm_agricultural]
      end

      expect(output).to have_tag('div.form-group > fieldset') do
      end
    end
  end
end
