# coding: utf-8
require 'rails_helper'
require 'spec_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  include TranslationHelper

  it "should have a version" do
    expect(GovukElementsFormBuilder::VERSION).to eq("1.3.1")
  end

  let(:helper) {TestHelper.new}
  let(:resource) {Person.new}
  let(:resource_name) {:person}
  let(:builder) {described_class.new resource_name, resource, helper, {}}

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

    let(:element) {method.eql?(:text_area) ? "textarea" : "input"}

    let(:attribute) {:name}
    subject {builder.send(method, attribute)}

    specify 'outputs label and input wrapped in div' do
      expect(subject).to have_tag('div.form-group') do |fg|
        expect(fg).to have_tag(element, with: {name: "#{resource_name}[#{attribute}]"})
        expect(fg).to have_tag("label.form-label", with: {for: [resource_name, attribute].join('_')})
      end
    end

    context 'inputs' do

      context "one custom input class (passed as a string)" do
        let(:custom_class) {"blue-and-white-stripes"}
        subject { builder.send(method, :name, class: custom_class) }

        specify 'adds custom class to input when provided' do
          expect(subject).to have_tag("#{element}.#{custom_class}", with: {type: type}.compact)
        end
      end

      context "multiple custom input classes (passed as an array)" do
        let(:custom_classes) {["blue-and-white-stripes", "yellow-spots"]}
        subject { builder.send(method, :name, class: custom_classes) }

        specify 'adds multiple custom classes to input when provided' do
          expect(subject).to have_tag("#{element}.#{custom_classes.join(".")}", with: {type: type}.compact)
        end
      end

      context "custom html attributes" do

        let(:custom_attributes) {method.eql?(:text_area) ? {cols: '100'} : {size: '100'}}

        subject {builder.send(method, :name, nil, custom_attributes.dup)}

        specify 'adds all supplied html attributes' do
          expect(subject).to have_tag(element, with: custom_attributes)
        end

      end

    end

    context 'labels' do

      context "one custom label attributes" do
        let(:label_options) {{"data-some-value" => "XYZ", lang: "en"}}
        subject { builder.send(method, :name, label_options: label_options) }

        specify 'adds custom class to input when provided' do
          expect(subject).to have_tag("label", with: label_options)
        end
      end

    end

    context 'hints' do

      subject {builder.send(method, :ni_number)}
      let(:hint_text) {I18n.t('helpers.hint.person.ni_number')}

      specify 'should include hint text' do
        expect(subject).to have_tag('.form-group > label.form-label') do |label|
          expect(label).to have_tag("span.form-hint", text: hint_text)
        end
      end

    end

    context 'fields_for' do

      let(:attribute) {:postcode}

      subject do
        builder.fields_for(:address, Address.new) do |f|
          f.send method, attribute
        end
      end

      specify 'should output input with nested form attributes' do
        expect(subject).to have_tag("#{element}#person_address_attributes_#{attribute}", with: {
          name: "person[address_attributes][#{attribute}]"
        })
      end

      specify 'should display a label for the nested field' do
        expect(subject).to have_tag('label', with: {
          for: "person_address_attributes_#{attribute}"
        })
      end

    end

    context 'when resource is a not a persisted model' do
      let(:resource) {Report.new}
      subject {described_class.new(:report, resource, helper, {})}

      it "##{method} does not raise errors" do
        expect {subject.send method, :name}.not_to raise_error
      end
    end

    context 'validation errors' do

      let(:attribute) {:name}
      subject {builder.send method, attribute}
      before {resource.valid?}

      specify 'error message is displayed within the label' do

        expect(subject).to have_tag("#error_person_#{attribute}.form-group-error") do |fge|
          expect(fge).to have_tag('label', text: /Full name/, with: {for: "person_#{attribute}"}) do |label|
            expect(label).to have_tag('span', text: 'Full name is required')
          end
        end
      end

      context 'custom translations' do

        let(:custom_translations) do
          YAML.load(
            <<~TRANSLATION
              errors:
                format: "%{message}"
              activemodel:
                errors:
                  models:
                    person:
                      attributes:
                        name:
                          blank: "Enter your full name"
            TRANSLATION
          )
        end

        let(:message) {I18n.t('activemodel.errors.models.person.attributes.name.blank')}

        specify 'should use the appropriate error messages as defined by the translation' do
          with_translations(:en, custom_translations) do

            # we need to validate the resource *after* having
            # loaded the translationsk, so it can't be done in
            # a before block
            resource.valid?

            expect(builder.send(method, attribute)).to have_tag("#error_person_#{attribute}.form-group-error") do |fge|
              expect(fge).to have_tag('span', text: message)
            end

          end
        end
      end

      context 'nested objects (fields_for)' do

        context 'nested once' do

          let(:address) {Address.new.tap{|a| a.valid?}}

          subject do
            builder.fields_for(:address) do |a|
              a.send(method, :postcode)
            end
          end

          before {resource.address = address}

          specify 'error message should be in label-contained span' do
            expect(subject).to have_tag('label', text: 'Postcode is required', with: {
              for: 'person_address_attributes_postcode'
            })
          end

          specify 'input should have error attributes' do
            expect(subject).to have_tag(element, with: {
              name: "person[address_attributes][postcode]"
            })
          end

        end


        context 'nested twice' do
          let(:country) {Country.new.tap{|c| c.valid?}}
          let(:resource_address) do
            Address.new.tap do |address|
              address.country = country
              address.country.valid?
            end
          end

          subject do
            builder.fields_for(:address) do |address|
              address.fields_for(:country) do |country|
                country.send method, :name
              end
            end
          end

          before {resource.address = resource_address}

          specify 'outputs error message label-contained span' do
            expect(subject).to have_tag('label', text: 'Country is required', with: {
              for: 'person_address_attributes_country_attributes_name'
            })
          end

          specify 'input should have error attributes' do
            expect(subject).to have_tag(element, with: {
              name: "person[address_attributes][country_attributes][name]"
            })
          end

        end

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

    context 'when no choices specified' do

      subject {builder.radio_button_fieldset(:has_user_account)}

      specify 'outputs yes/no choices' do
        expect(subject).to have_tag('.form-group > fieldset') do |fieldset|
          expect(fieldset).to have_tag('div.multiple-choice > input', count: 2, with: {type: 'radio'})
          expect(fieldset).to have_tag('input', with: {value: 'no'})
          expect(fieldset).to have_tag('input', with: {value: 'yes'})
        end
      end

      specify 'yes/no choices have labels' do
        expect(subject).to have_tag('.form-group > fieldset') do |fieldset|
          expect(fieldset).to have_tag('label', text: 'Yes', with: {for: 'person_has_user_account_yes'})
          expect(fieldset).to have_tag('label', text: 'No', with: {for: 'person_has_user_account_no'})
        end
      end

    end

    context 'adds inline class to fieldset when inline option passed' do
      subject {builder.radio_button_fieldset(:has_user_account, inline: true)}

      specify "fieldset should have 'inline' class" do
        expect(subject).to have_tag('.form-group > fieldset.inline')
      end
    end

    context 'revealing panels' do

      let(:other_input) {:location_other}
      let(:other_input_panel) {:location_other_panel}
      let(:other_input_label) { I18n.t('label.location_other') }

      subject do
        builder.radio_button_fieldset(:location) do |fieldset|
          fieldset.radio_input(:england)
          fieldset.radio_input(:other) {
            fieldset.text_field other_input
          }
        end
      end

      specify "there should be an 'other' entry" do
        target_options = {'data-target' => other_input_panel}
        expect(subject).to have_tag('.multiple-choice', with: target_options) do
          expect(subject).to have_tag('input', with: {
            type: 'radio',
            value: 'other'
          })
        end
      end

      specify "there should be a hidden panel for the 'other' entry" do
        expect(subject).to have_tag(".panel.js-hidden", with: {id: other_input_panel})
      end

      specify 'the hidden panel should contain a text input' do
        expect(subject).to have_tag(".panel.js-hidden") do |panel|
          expect(panel).to have_tag('input.form-control', with: {
            type: 'text',
            name: "person[#{other_input}]"
          })
        end
      end

      specify "the hidden 'other' input should be labelled correctly" do
        expect(subject).to have_tag(".panel.js-hidden") do |panel|
          expect(panel).to have_tag('label.form-label', with: {
            for: "person_#{other_input}"
          })
        end
      end
    end

    context 'revealing panels with a specific id' do

      let(:custom_div) {"a-customisable-div"}

      subject do
        builder.radio_button_fieldset :location do |fieldset|
          fieldset.radio_input(:england)
          fieldset.radio_input(:other, panel_id: custom_div)
        end
      end

      specify 'outputs markup with support for revealing panels with specific id' do
        expect(subject).to have_tag('.multiple-choice', with: {"data-target" => custom_div})
      end

    end

    context 'legend options' do
      let(:custom_class) {"bright-pink"}
      let(:language) {"en"}

      subject do
        builder.radio_button_fieldset :has_user_account, inline: true, legend_options: {class: custom_class, lang: language}
      end

      specify 'should be propagated down to the inner legend when provided' do
        expect(subject).to have_tag("legend > span.form-label-bold.#{custom_class}", with: {lang: language})
      end

    end

    context 'custom names and values' do
      let(:cases) {[ Case.new(id: 18, name: 'Case One'), Case.new(id: 19, name: 'Case Two')]}
      subject {builder.radio_button_fieldset(:case_id, choices: cases, value_method: :id, text_method: :name)}

      specify 'name and value should match provided options' do
        cases.each do |kase|

          expect(subject).to have_tag("input#person_case_id_#{kase.id}", with: {
            value: kase.id,
            type: 'radio'
          })

          expect(subject).to have_tag('label', text: kase.name, with: {
            for: "person_case_id_#{kase.id}"
          })

        end
      end
    end

    context 'when the resource is invalid' do
      let(:resource) {Person.new}
      let(:error_message) {"Gender is required"}
      subject {builder.radio_button_fieldset :gender}

      before do
        resource.valid?
      end

      specify 'the form group should have error classes' do
        expect(subject).to have_tag('.form-group.form-group-error')
      end

      specify 'the form group should have error messages' do
        expect(subject).to have_tag('.form-group-error span.error-message', text: error_message)
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
