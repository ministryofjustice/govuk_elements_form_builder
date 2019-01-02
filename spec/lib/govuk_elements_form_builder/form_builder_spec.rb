# coding: utf-8
require 'rails_helper'
require 'spec_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  include TranslationHelper

  it "should have a version" do
    expect(GovukElementsFormBuilder::VERSION).to eq("1.3.1")
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

  def html_attributes(hash)
    if  hash.present?
      hash.map{|k,v| %'#{k}="#{v}" '}.join(' ')
    end
  end

  shared_examples_for 'input field' do |method, type|

    def size(method, size)
      (size.nil? || method == :text_area) ? '' : %'size="#{size}" '
    end

    def expected_name_input_html method, type, classes=nil, size=nil, label_options=nil
      label_options ||= {}
      label_options[:class] ||= nil
      [
        '<div class="form-group">',
        %'<label #{html_attributes(label_options.except(:class, :for))}class="form-label#{label_options[:class]}" for="person_name">',
        'Full name',
        '</label>',
        %'<#{element_for(method)} #{size(method, size)}class="form-control#{classes}" #{type_for(method, type)}name="person[name]" id="person_name" />',
        '</div>'
      ]
    end

    it 'outputs label and input wrapped in div' do
      output = builder.send method, :name

      expect_equal output, expected_name_input_html(method, type)
    end

    it 'adds custom class to input when passed class: "custom-class"' do
      output = builder.send method, :name, class: 'custom-class'

      expect_equal output, expected_name_input_html(method, type, ' custom-class')
    end

    it 'adds custom classes to input when passed class: ["custom-class", "another-class"]' do
      output = builder.send method, :name, class: ['custom-class', 'another-class']

      expect_equal output, expected_name_input_html(method, type, ' custom-class another-class')
    end

    it 'adds custom classes to label when passed class: ["custom-class", "another-class"]' do
      label_class_options = { class: ' custom-label-class another-label-class' }
      output = builder.send method, :name, {label_options: {class: ['custom-label-class', 'another-label-class']}}

      expect_equal output, expected_name_input_html( method, type, nil, nil, label_class_options)
    end

    it 'passes other html attribute to the label if they are provided' do
      label_attr_options = { style: 'color:red;'}
      output = builder.send method, :name, {label_options: {style: 'color:red;'}}

      expect_equal output, expected_name_input_html( method, type, nil, nil, label_attr_options)
    end

    it 'passes options passed to text_field onto super text_field implementation' do
      output = builder.send method, :name, size: 100

      expect_equal output, expected_name_input_html(method, type, nil, 100)
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

    context 'when resource is a not a persisted model' do
      let(:resource) { Report.new }
      let(:builder) { described_class.new :report, resource, helper, {} }
      it "##{method} does not fail" do
        expect { builder.send method, :name }.not_to raise_error
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
      %'<div class="form-group form-group-error" id="error_#{attribute}">',
      %'<label class="form-label" for="#{attribute}">',
      label,
      %'<span class="error-message" id="error_message_#{attribute}">',
      error,
      '</span>',
      '</label>',
      %'<#{element_for(method)} aria-describedby="error_message_#{attribute}" class="form-control form-control-error" #{type_for(method, type)}name="#{name_value}" id="#{attribute}" />',
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

  describe '#revealing_panel' do
    let(:pretty_output) { HtmlBeautifier.beautify output }

    it 'outputs revealing panel markup' do
      output = builder.radio_button_fieldset :location do |fieldset|
        fieldset.revealing_panel(:location_panel) do |panel|
          panel.text_field :location_other
          panel.text_field :address
        end
      end

      expect_equal output, [
        '<div class="form-group">',
        '<fieldset>',
        '<legend>',
        '<span class="form-label-bold">',
        'Where do you live?',
        '</span>',
        '<span class="form-hint">',
        'Select from these options because you answered you do not reside in England, Wales, or Scotland',
        '</span>',
        '</legend>',
        '<div class="panel panel-border-narrow js-hidden" id="location_panel">',
        '<div class="form-group">',
        '<label class="form-label" for="person_location_other">',
        'Please enter your location',
        '</label>',
        '<input class="form-control" type="text" name="person[location_other]" id="person_location_other" />',
        '</div>',
        '<div class="form-group">',
        '<label class="form-label" for="person_address">',
        'Address',
        '</label>',
        '<input class="form-control" type="text" name="person[address]" id="person_address" />',
        '</div>',
        '</div>',
        '</fieldset>',
        '</div>'
      ]
    end
  end

  describe '#radio_button_fieldset' do

    let(:pretty_output) { HtmlBeautifier.beautify output }

    context 'outputs radio buttons in a stacked layout' do
      let(:locations) {[:ni, :isle_of_man_channel_islands, :british_abroad]}
      subject {builder.radio_button_fieldset :location, choices: locations}

      specify 'outputs a form group containing the correct number of radio buttons' do
        expect(subject).to have_tag("div.form-group")
      end

      specify 'includes the appropriate hint in the form' do
        expect(subject).to have_tag("span.form-hint", text: I18n.t('helpers.hint.person.location'))
      end

      specify 'radio buttons exist for each of the relevant options' do
        locations.each do |location|
          attributes = {type: 'radio', name: 'person[location]'}
          selector = "input#person_location_#{location}"
          expect(subject).to have_tag(selector, with: attributes)
        end
      end

      specify 'each radio button should have an appropriate label' do

        # :other isn't specified in :locations so won't appear, don't
        # check for it
        I18n
          .t('helpers.label.person.location')
          .reject{|k,v| k == :other}
          .each do |k,v|
          attributes = {for: "person_location_#{k}"}
          expect(subject).to have_tag('label', with: attributes, text: v)
        end

      end

    end

    it 'outputs yes/no choices when no choices specified, and adds "inline" class to fieldset when passed "inline: true"' do
      output = builder.radio_button_fieldset :has_user_account, inline: true
      expect_equal output, [
        '<div class="form-group">',
        '<fieldset class="inline">',
        '<legend>',
        '<span class="form-label-bold">',
        'Do you already have a personal user account?',
        '</span>',
        '</legend>',
        '<div class="multiple-choice">',
        '<input type="radio" value="yes" name="person[has_user_account]" id="person_has_user_account_yes" />',
        '<label for="person_has_user_account_yes">',
        'Yes',
        '</label>',
        '</div>',
        '<div class="multiple-choice">',
        '<input type="radio" value="no" name="person[has_user_account]" id="person_has_user_account_no" />',
        '<label for="person_has_user_account_no">',
        'No',
        '</label>',
        '</div>',
        '</fieldset>',
        '</div>'
      ]
    end

    it 'outputs markup with support for revealing panels' do
      output = builder.radio_button_fieldset :location do |fieldset|
        fieldset.radio_input(:england)
        fieldset.radio_input(:other) {
          fieldset.text_field :location_other
        }
      end

      expect_equal output, [
      '<div class="form-group">',
        '<fieldset>',
        '<legend>',
        '<span class="form-label-bold">',
        'Where do you live?',
        '</span>',
        '<span class="form-hint">',
        'Select from these options because you answered you do not reside in England, Wales, or Scotland',
        '</span>',
        '</legend>',
        '<div class="multiple-choice">',
        '<input type="radio" value="england" name="person[location]" id="person_location_england" />',
        '<label for="person_location_england">',
        'England',
        '</label>',
        '</div>',
        '<div class="multiple-choice" data-target="location_other_panel">',
        '<input type="radio" value="other" name="person[location]" id="person_location_other" />',
        '<label for="person_location_other">',
        'Other location',
        '</label>',
        '</div>',
        '<div class="panel panel-border-narrow js-hidden" id="location_other_panel">',
        '<div class="form-group">',
        '<label class="form-label" for="person_location_other">',
        'Please enter your location',
        '</label>',
        '<input class="form-control" type="text" name="person[location_other]" id="person_location_other" />',
        '</div>',
        '</div>',
        '</fieldset>',
        '</div>'
      ]
    end

    it 'outputs markup with support for revealing panels with specific ID' do
      output = builder.radio_button_fieldset :location do |fieldset|
        fieldset.radio_input(:england)
        fieldset.radio_input(:other, panel_id: 'another_location_input')
      end

      expect(output).to match(/<div class="multiple-choice" data-target="another_location_input">/)
    end

    it 'propagates html attributes down to the legend inner span if any provided, appending to the defaults' do
      output = builder.radio_button_fieldset :has_user_account, inline: true, legend_options: {class: 'visuallyhidden', lang: 'en'}
      expect(output).to match(/<legend><span class="form-label-bold visuallyhidden" lang="en">/)
    end

    it 'can override the legend text' do
      output = builder.radio_button_fieldset :has_user_account, inline: true, legend_options: { text: 'A custom legend' }
      expect(output).to match(/<legend><span class="form-label-bold">A custom legend<\/span>/)
    end

    context 'with a couple associated cases' do
      let(:case_1) { Case.new(id: 1, name: 'Case One')  }
      let(:case_2) { Case.new(id: 2, name: 'Case Two')  }
      let(:cases) { [case_1, case_2] }

      it 'accepts value_method and text_method to better control generated HTML' do
        output = builder.radio_button_fieldset :case_id, choices: cases, value_method: :id, text_method: :name, inline: true
        expect_equal output, [
                       '<div class="form-group">',
                       '<fieldset class="inline">',
                       '<legend>',
                       '<span class="form-label-bold">',
                       'Case',
                       '</span>',
                       '</legend>',
                       '<div class="multiple-choice">',
                       '<input type="radio" value="1" name="person[case_id]" id="person_case_id_1" />',
                       '<label for="person_case_id_1">',
                       'Case One',
                       '</label>',
                       '</div>',
                       '<div class="multiple-choice">',
                       '<input type="radio" value="2" name="person[case_id]" id="person_case_id_2" />',
                       '<label for="person_case_id_2">',
                       'Case Two',
                       '</label>',
                       '</div>',
                       '</fieldset>',
                       '</div>'
                     ]

      end
    end

    context 'the resource is invalid' do
      let(:resource) { Person.new.tap { |p| p.valid? } }

      it 'outputs error messages' do
        output = builder.radio_button_fieldset :gender
        expect_equal output, [
                       '<div class="form-group form-group-error" id="error_person_gender">',
                       '<fieldset>',
                       '<legend>',
                       '<span class="form-label-bold">',
                       'Gender',
                       '</span>',
                       '<span class="error-message">',
                       'Gender is required',
                       '</span>',
                       '<span class="form-hint">',
                       'Select from these options',
                       '</span>',
                       '</legend>',
                       '<div class="multiple-choice">',
                       '<input aria-describedby="error_message_person_gender_yes" type="radio" value="yes" name="person[gender]" id="person_gender_yes" />',
                       '<label for="person_gender_yes">',
                       'Yes',
                       '</label>',
                       '</div>',
                       '<div class="multiple-choice">',
                       '<input aria-describedby="error_message_person_gender_no" type="radio" value="no" name="person[gender]" id="person_gender_no" />',
                       '<label for="person_gender_no">',
                       'No',
                       '</label>',
                       '</div>',
                       '</fieldset>',
                       '</div>'
                     ]
      end
    end
  end

  describe '#check_box_fieldset' do
    before {resource.waste_transport = WasteTransport.new}

    let(:waste_categories) {[:animal_carcasses, :mines_quarries, :farm_agricultural]}
    subject do
      builder.fields_for(:waste_transport) {|f| f.check_box_fieldset(:waste_transport, waste_categories)}
    end

    specify 'fieldset has the correct heading' do
      text = I18n.t('helpers.fieldset.person[waste_transport_attributes].waste_transport')
      expect(subject).to have_tag('fieldset > legend > span.form-label-bold', text)
    end

    specify 'outputs checkboxes with labels' do
      expect(subject).to have_tag('div.form-group') do |form_group|
        expect(form_group).to have_tag('input', with: {type: 'checkbox'}, count: waste_categories.size)
        expect(form_group).to have_tag('label', count: waste_categories.size)
      end
    end

    specify 'checkboxes have correct attributes' do

      waste_categories.each do |wc|

        selector = ['person', 'waste_transport_attributes', wc].join('_')

        expect(subject).to have_tag(
          "input##{selector}",
          with: {
            type: 'checkbox',
            name: "person[waste_transport_attributes][#{wc}]"
          }
        )

      end
    end

    specify 'labels have correct content' do
      I18n.t('helpers.label.person[waste_transport_attributes]').each do |k,v|

        # this isn't straightforward because Rails's I18n allows for HTML snippets
        # to be added to the translations, so we need to strip the `_html` suffix
        # from the key and parse the HTML to extract only the text.
        target = "person_waste_transport_attributes_#{k}".gsub(/_html$/, "")
        text = Nokogiri::HTML(v).text

        expect(subject).to have_tag('label', with: {for: target}, text: text)
      end
    end


    context 'revealing panels' do

      subject do
        builder.fields_for(:waste_transport) do |f|
          f.check_box_fieldset :waste_transport, [:animal_carcasses, :mines_quarries, :farm_agricultural] do |fieldset|
            fieldset.check_box_input(:animal_carcasses)
            fieldset.check_box_input(:mines_quarries) { f.text_field :mines_quarries_details }
            fieldset.check_box_input(:farm_agricultural) { f.text_field :farm_agricultural_details }
          end
        end
      end

      let(:fields_with_hidden_panels) {[:mines_quarries, :farm_agricultural]}
      let(:field_without_hidden_panel) {:animal_carcasses}

      specify 'inputs are marked as multiple choice' do
        count = fields_with_hidden_panels.push(field_without_hidden_panel).size
        expect(subject).to have_tag('div.multiple-choice', count: count)
      end

      specify 'should not add a text field to checkboxes without associated text fields' do
        expect(subject).not_to have_tag("div##{field_without_hidden_panel}_panel")
      end

      specify 'should add a text field to checkboxes with associated text fields' do
        fields_with_hidden_panels.each do |fwhp|
          expect(subject).to have_tag("div##{fwhp}_panel") do |panel|

            attributes = {
              type: 'text',
              name: "person[waste_transport_attributes][#{fwhp}_details]"
            }

            expect(panel).to have_tag('div.panel.js-hidden input', with: attributes)
          end
        end
      end

    end

    it 'outputs markup with support for revealing panels with specific ID' do
      resource.waste_transport = WasteTransport.new
      output = builder.fields_for(:waste_transport) do |f|
        f.check_box_fieldset :waste_transport, [:animal_carcasses, :mines_quarries] do |fieldset|
          fieldset.check_box_input(:animal_carcasses)
          fieldset.check_box_input(:mines_quarries, panel_id: 'mines_quarries_details_text_field_input')
        end
      end

      expect(output).to match(/<div class="multiple-choice" data-target="mines_quarries_details_text_field_input">/)
    end

    it 'propagates html attributes down to the legend inner span if any provided, appending to the defaults' do
      output = builder.fields_for(:waste_transport) do |f|
        f.check_box_fieldset :waste_transport, [:animal_carcasses, :mines_quarries, :farm_agricultural], legend_options: {class: 'visuallyhidden', lang: 'en'}
      end
      expect(output).to match(/<legend><span class="form-label-bold visuallyhidden" lang="en">/)
    end
  end

  describe '#collection_radio_buttons' do
    let(:input_type) {'radio'}
    let(:person) {Person.new}
    let(:gender_collection) {
      [
        OpenStruct.new(code: 'M', name: 'Masculine'),
        OpenStruct.new(code: 'F', name: 'Feminine'),
        OpenStruct.new(code: 'N', name: 'Neuter')
      ]
    }

    subject {
      builder.collection_radio_buttons :gender, gender_collection, :code, :name, {id: 'gender-radio-id'}
    }

    let(:input_container) {'div.form-group > fieldset > div.multiple-choice'}

    specify 'builds the legend, form label and hint correctly' do
      expect(subject).to have_tag('div.form-group > fieldset > legend') do |legend|
        expect(legend).to have_tag('span.form-label-bold', text: 'Gender')
        expect(legend).to have_tag('span.form-hint', text: 'Select from these options')
      end
    end

    specify 'adds the correct number of radio buttons' do
      expect(subject).to have_tag(input_container, count: gender_collection.size)
    end

    specify 'correctly builds the entries' do
      gender_collection.each do |gc|
        attributes = {type: input_type, value: gc.code, name: "person[gender]"}
        expect(subject).to have_tag("#{input_container} > input#person_gender_#{gc.code.downcase}", with: attributes)
      end
    end

    specify 'correctly labels each radio button' do
      gender_collection.each do |gc|
        attributes = {for: "person_gender_#{gc.code.downcase}"}
        expect(subject).to have_tag("#{input_container} > label", text: gc.name, with: attributes)
      end
    end
  end

  describe '#collection_check_boxes' do
    let(:input_type) {'checkbox'}
    let(:person) {Person.new}
    let(:gender_collection) {
      [
        OpenStruct.new(code: 'M', name: 'Masculine'),
        OpenStruct.new(code: 'F', name: 'Feminine'),
        OpenStruct.new(code: 'N', name: 'Neuter')
      ]
    }

    subject {
      builder.collection_check_boxes :gender, gender_collection, :code, :name, {id: 'gender-radio-id'}
    }

    let(:input_container) {'div.form-group > fieldset > div.multiple-choice'}

    specify 'builds the legend, form label and hint correctly' do
      expect(subject).to have_tag('div.form-group > fieldset > legend') do |legend|
        expect(legend).to have_tag('span.form-label-bold', text: 'Gender')
        expect(legend).to have_tag('span.form-hint', text: 'Select from these options')
      end
    end

    specify 'adds the correct number of check boxes' do
      expect(subject).to have_tag(input_container, count: gender_collection.size)
    end

    specify 'correctly builds the entries' do
      gender_collection.each do |gc|
        attributes = {type: input_type, value: gc.code, name: "person[gender][]"}
        expect(subject).to have_tag("#{input_container} > input#person_gender_#{gc.code.downcase}", with: attributes)
      end
    end

    specify 'correctly labels each check box' do
      gender_collection.each do |gc|
        attributes = {for: "person_gender_#{gc.code.downcase}"}
        expect(subject).to have_tag("#{input_container} > label", text: gc.name, with: attributes)
      end
    end

  end


  describe '#collection_select' do

    let(:genders) {[:male, :female]}

    context 'select element and labels' do

      subject {builder.collection_select(:gender, genders, :to_s, :to_s)}

      specify 'outputs a div containing select and label elements' do

        expect(subject).to have_tag('div.form-group') do |div|
          expect(div).to have_tag('label.form-label')
          expect(div).to have_tag('select.form-control')
        end

      end

      specify 'the label has the correct text and attributes' do
        selector = 'div.form-group > label.form-label'
        expect(subject).to have_tag(selector, text: /Gender/, options: {for: 'person_gender'})
      end

      specify 'the select box has the correct contents' do
        selector = 'div.form-group > select#person_gender.form-control'
        attributes = {name: 'person[gender]'}

        expect(subject).to have_tag(selector, with: attributes) do |select|
          genders.each do |gender|
            expect(select).to have_tag('option', with: {value: gender}, text: gender)
          end
        end

      end
    end

    context 'outputs select lists with labels and hints' do
      let(:locations) {[:ni, :isle_of_man_channel_islands]}
      let(:hint) {I18n.t('helpers.hint.person.location')}

      subject {builder.collection_select(:location, locations, :to_s, :to_s, {})}

      specify 'should display the correct hints if they are defined' do
        selector = 'div.form-group > label.form-label'
        expect(subject).to have_tag(selector, text: hint, options: {for: 'person_location'})
      end

    end

    context 'custom classes' do
      let(:custom_class) {"my-custom-style"}
      subject {builder.collection_select :gender, genders, :to_s, :to_s, {}, class: custom_class}

      specify 'it should add a custom class when one is supplied' do
        expect(subject).to have_tag("select.#{custom_class}")
      end

    end

    context 'blanks' do
      let(:blank_text) {"Please select an option"}
      subject {builder.collection_select :gender, genders, :to_s, :to_s, {include_blank: blank_text}}

      specify 'it should add a insert a blank entry when include_blank is supplied' do
        expect(subject).to have_tag("select > option", text: blank_text, with: {value: ""})
      end

    end

  end
end
