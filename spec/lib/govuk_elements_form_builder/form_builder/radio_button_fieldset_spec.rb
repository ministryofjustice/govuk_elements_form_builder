# coding: utf-8
require 'rails_helper'
require 'spec_helper'

class TestHelper < ActionView::Base; end

RSpec.describe GovukElementsFormBuilder::FormBuilder do
  include TranslationHelper

  let(:helper) { TestHelper.new }
  let(:resource)  { Person.new }
  let(:builder) { described_class.new :person, resource, helper, {} }

  describe '#radio_button_fieldset' do
    let(:pretty_output) { HtmlBeautifier.beautify output }
    let(:output) do
      builder.radio_button_fieldset :location,
                                    choices: [
                                      :ni,
                                      :isle_of_man_channel_islands,
                                      :british_abroad
                                    ]
    end

    it 'adds a legend' do
      expect(pretty_output).to have_tag('div.form-group > fieldset') do |div|
        expect(div).to have_tag('legend') do |legend|
          with_text I18n.t 'helpers.fieldset.person.location'
          expect(legend).to have_tag('span.form-hint') do
            with_text I18n.t 'helpers.hint.person.location'
          end
        end
      end
    end

    it 'outputs radio buttons wrapped in labels' do
      expect(pretty_output).to have_tag('div.form-group > fieldset') do |div|
        expect(div).to have_tag('label[for=person_location_ni].block-label') do |label|
          with_text I18n.t 'helpers.label.person.location.ni'
          expect(label).to have_tag('input', with: {
                                      type: 'radio',
                                      name: 'person[location]',
                                      value: 'ni'
                                    })
        end
        expect(div).to have_tag 'label.block-label', with: {
                   for: 'person_location_isle_of_man_channel_islands'
                 } do |label|
          with_text I18n.t 'helpers.label.person.location.isle_of_man_channel_islands'
          expect(label).to have_tag 'input', with: {
                     id: 'person_location_isle_of_man_channel_islands',
                     type: 'radio',
                     name: 'person[location]',
                     value: 'isle_of_man_channel_islands'
                   }
        end
        expect(div).to have_tag 'label.block-label', with: {
                   for: 'person_location_british_abroad'
                 } do |label|
          with_text I18n.t 'helpers.label.person.location.british_abroad'
          expect(label).to have_tag 'input', with: {
                     id: 'person_location_british_abroad',
                     type: 'radio',
                     name: 'person[location]',
                     value: 'british_abroad'
                   }
        end
      end
    end

    context 'no choices passed in' do
      let(:output) { builder.radio_button_fieldset :has_user_account }

      it 'outputs yes/no choices' do
        expect(output).to have_tag('div.form-group > fieldset') do |div|
          expect(div).to have_tag('label.block-label', with: {
                                    for: 'person_has_user_account_yes'
                                  }) do |label|
            expect(label).to have_tag('input', with: {
                                        id: 'person_has_user_account_yes',
                                        name: 'person[has_user_account]',
                                        value: 'yes'
                                      })
          end
        end
      end
    end

    context 'inline radio buttons' do
      let(:output) do
        builder.radio_button_fieldset :has_user_account, inline: true
      end

      it 'displays options inline' do
        expect(output).to have_tag('div.form-group > fieldset.inline')
      end
    end

    context 'the resource is invalid' do
      let(:resource) { Person.new.tap { |p| p.valid? } }
      let(:output) { builder.radio_button_fieldset :gender }

      it 'outputs error messages' do
        expect(pretty_output).to have_tag('div.form-group.error > fieldset') do |div|
          expect(div).to have_tag('legend') do |legend|
            expect(legend).to have_tag('span.form-label-bold', 'Gender')
            expect(legend).to have_tag('span.error-message', 'Gender is required')
          end
        end
      end
    end
  end
end
