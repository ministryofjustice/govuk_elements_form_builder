# coding: utf-8
require 'rails_helper'
require 'spec_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  include TranslationHelper

  it "should have a version" do
    expect(GovukElementsFormBuilder::VERSION).to eq("0.0.1")
  end

  let(:helper) { TestHelper.new }
  let(:resource)  { Person.new }
  let(:builder) { described_class.new :person, resource, helper, {} }

  def expect_equal output, expected
    split_output = output.gsub(">\n</textarea>", ' />').split("<").join("\n<").split(">").join(">\n").squeeze("\n").strip + '>'
    split_expected = expected.join("\n")
    expect(split_output).to eq split_expected
  end

  def element_for(method)
    method == :text_area ? 'textarea' : 'input'
  end

  def type_for(method, type)
    method == :text_area ? '' : %'type="#{type}" '
  end

  shared_examples_for 'input field' do |method, type|

    def size(method, size)
      method == :text_area ? '' : %'size="#{size}" '
    end

    it 'outputs label and input wrapped in div' do
      output = builder.send method, :name

      expect_equal output, [
        '<div class="form-group">',
        '<label class="form-label" for="person_name">',
        'Full name',
        '</label>',
        %'<#{element_for(method)} class="form-control" #{type_for(method, type)}name="person[name]" id="person_name" />',
        '</div>'
      ]
    end

    it 'adds custom class to input when passed class: "custom-class"' do
      output = builder.send method, :name, class: 'custom-class'

      expect_equal output, [
        '<div class="form-group">',
        '<label class="form-label" for="person_name">',
        'Full name',
        '</label>',
        %'<#{element_for(method)} class="form-control custom-class" #{type_for(method, type)}name="person[name]" id="person_name" />',
        '</div>'
      ]
    end

    it 'adds custom classes to input when passed class: ["custom-class", "another-class"]' do
      output = builder.send method, :name, class: ['custom-class', 'another-class']

      expect_equal output, [
        '<div class="form-group">',
        '<label class="form-label" for="person_name">',
        'Full name',
        '</label>',
        %'<#{element_for(method)} class="form-control custom-class another-class" #{type_for(method, type)}name="person[name]" id="person_name" />',
        '</div>'
      ]
    end

    it 'passes options passed to text_field onto super text_field implementation' do
      output = builder.send method, :name, size: 100
      expect_equal output, [
        '<div class="form-group">',
        '<label class="form-label" for="person_name">',
        'Full name',
        '</label>',
        %'<#{element_for(method)} #{size(method, 100)}class="form-control" #{type_for(method, type)}name="person[name]" id="person_name" />',
        '</div>'
      ]
    end

    context 'when hint text provided' do
      it 'outputs hint text in span inside label' do
        output = builder.send method, :ni_number
        expect_equal output, [
          '<div class="form-group">',
          '<label class="form-label" for="person_ni_number">',
          'National Insurance number',
          '<span class="form-hint">',
          'It’ll be on your last payslip. For example, JH 21 90 0A.',
          '</span>',
          '</label>',
          %'<#{element_for(method)} class="form-control" #{type_for(method, type)}name="person[ni_number]" id="person_ni_number" />',
          '</div>'
        ]
      end
    end

    context 'when fields_for used' do
      it 'outputs label and input with correct ids' do
        output = builder.fields_for(:address, Address.new) do |f|
          f.send method, :postcode
        end
        expect_equal output, [
          '<div class="form-group">',
          '<label class="form-label" for="person_address_attributes_postcode">',
          'Postcode',
          '</label>',
          %'<#{element_for(method)} class="form-control" #{type_for(method, type)}name="person[address_attributes][postcode]" id="person_address_attributes_postcode" />',
          '</div>'
        ]
      end
    end

    context 'when validation error on object' do
      it 'outputs error message in span inside label' do
        resource.valid?
        output = builder.send method, :name
        expected = expected_error_html method, type, 'person_name',
          'person[name]', 'Full name', 'Full name is required'
        expect_equal output, expected
      end

      it 'outputs custom error message format in span inside label' do
        translations = YAML.load(%'
            errors:
              format: "%{message}"
            activemodel:
              errors:
                models:
                  person:
                    attributes:
                      name:
                        blank: "Enter your full name"
        ')
        with_translations(:en, translations) do
          resource.valid?
          output = builder.send method, :name
          expected = expected_error_html method, type, 'person_name',
            'person[name]', 'Name', 'Enter your full name'
          expect_equal output, expected
        end
      end
    end

    context 'when validation error on child object' do
      it 'outputs error message in span inside label' do
        resource.address = Address.new
        resource.address.valid?

        output = builder.fields_for(:address) do |f|
          f.send method, :postcode
        end

        expected = expected_error_html method, type, 'person_address_attributes_postcode',
          'person[address_attributes][postcode]', 'Postcode', 'Postcode is required'
        expect_equal output, expected
      end
    end

    context 'when validation error on twice nested child object' do
      it 'outputs error message in span inside label' do
        resource.address = Address.new
        resource.address.country = Country.new
        resource.address.country.valid?

        output = builder.fields_for(:address) do |address|
          address.fields_for(:country) do |country|
            country.send method, :name
          end
        end

        expected = expected_error_html method, type, 'person_address_attributes_country_attributes_name',
          'person[address_attributes][country_attributes][name]', 'Country', 'Country is required'
        expect_equal output, expected
      end
    end

  end

  context 'when mixing the rendering order of nested builders' do
    let(:method) { :text_field }
    let(:type) { :text }
    it 'outputs error messages in span inside label' do
      resource.address = Address.new
      resource.address.valid?
      resource.valid?

      # Render the postcode first
      builder.fields_for(:address) do |address|
        address.text_field :postcode
      end
      output = builder.text_field :name

      expected = expected_error_html :text_field, :text, 'person_name',
        'person[name]', 'Full name', 'Full name is required'
      expect_equal output, expected
    end
  end

  def expected_error_html method, type, attribute, name_value, label, error
    [
      %'<div class="form-group error" id="error_#{attribute}">',
      %'<label class="form-label" for="#{attribute}">',
      label,
      %'<span class="error-message" id="error_message_#{attribute}">',
      error,
      '</span>',
      '</label>',
      %'<#{element_for(method)} aria-describedby="error_message_#{attribute}" class="form-control" #{type_for(method, type)}name="#{name_value}" id="#{attribute}" />',
      '</div>'
    ]
  end

  describe '#text_field' do
    include_examples 'input field', :text_field, :text
  end

  describe '#text_area' do
    include_examples 'input field', :text_area, nil
  end

  describe '#email_field' do
    include_examples 'input field', :email_field, :email
  end

  describe "#number_field" do
    include_examples 'input field', :number_field, :number
  end

  describe '#password_field' do
    include_examples 'input field', :password_field, :password
  end

  describe '#phone_field' do
    include_examples 'input field', :phone_field, :tel
  end

  describe '#range_field' do
    include_examples 'input field', :range_field, :range
  end

  describe '#search_field' do
    include_examples 'input field', :search_field, :search
  end

  describe '#telephone_field' do
    include_examples 'input field', :telephone_field, :tel
  end

  describe '#url_field' do
    include_examples 'input field', :url_field, :url
  end
end
