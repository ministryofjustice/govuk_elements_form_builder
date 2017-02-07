require 'rspec/expectations'

module FormGroupMatcherHelpers
  extend RSpec::Matchers::DSL

  class FormGroupObject
    attr_reader :options, :resource, :field,
      :label, :input_type, :input_class, :input_size,
      :fields_for

    def initialize(options)
      @options = options
      @resource = options[:resource]
      @field = options.fetch(:field)
      @label = options.fetch(:label) { @field.to_s.humanize }
      @input_type = options.fetch(:input_type)
      @input_class = options[:class]
      @input_size = options[:size]
      @fields_for = options[:fields_for]
    end

    def field_id
      [resource, fields_for_attributes, field].compact.join('_')
    end

    def field_name
      return "#{resource}[#{fields_for_attributes}][#{field}]" if resource && fields_for_attributes
      return "#{resource}[#{field}]" if resource
      field
    end

    def to_s
      ['<div class="form-group">', label_tag, field_tag, '</div>'].join("\n")
    end

    private

    def fields_for_attributes
      return unless fields_for
      "#{fields_for}_attributes"
    end

    def text_area_input?
      input_type.to_s == 'text_area'
    end

    def input_tag
      return '<textarea' if text_area_input?
      '<input'
    end

    def input_tag_type
      return if text_area_input?
      type = {
        text_field: 'text',
        email_field: 'email',
        number_field: 'number',
        password_field: 'password',
        phone_field: 'tel',
        range_field: 'range',
        search_field: 'search',
        telephone_field: 'tel',
        url_field: 'url'
      }[input_type.to_sym]
      %[type="#{type}"]
    end

    def input_tag_class
      classes = 'form-control'
      classes << ' ' << input_class if input_class
      %[class="#{classes}"]
    end

    def input_tag_size
      return if text_area_input?
      return unless input_size
      %[size="#{input_size}"]
    end

    def hint_tag
      localized_path = ['helpers', 'hint', resource, field].compact.join('.')
      localized_hint = I18n.t(localized_path, default: '')
      return unless localized_hint.present?
      ['<span class="form-hint">', localized_hint, '</span>'].join("\n")
    end

    def label_tag
      localized_path = ['helpers', 'label', resource, field].compact.join('.')
      localized_label = I18n.t(localized_path, default: field.to_s.humanize)
      [%[<label class="form-label" for="#{field_id}">], localized_label, hint_tag, '</label>'].compact.join("\n")
    end

    def field_tag
      [input_tag, input_tag_size, input_tag_class, input_tag_type, %[name="#{field_name}"], %[id="#{field_id}"], '/>'].compact.join(' ')
    end
  end

  matcher :match_form_group do |expected|
    define_method :formatted_expected do
      FormGroupObject.new(expected).to_s
    end

    define_method :formatted_actual do |actual|
      actual.gsub(">\n</textarea>", ' />').split("<").join("\n<").split(">").join(">\n").squeeze("\n").strip + '>'
    end

    match do |actual|
      formatted_actual(actual) == formatted_expected
		end

    failure_message do |actual|
      "expected\n#{formatted_actual(actual)}\nto match\n#{formatted_expected}"
    end
  end
end
