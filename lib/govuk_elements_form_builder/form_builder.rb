module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder

    delegate :content_tag, :tag, :safe_join, to: :@template
    delegate :errors, to: :@object

    def initialize *args
      ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
        add_error_to_html_tag! html_tag
      end
      super
    end

    # Ensure fields_for yields a GovukElementsFormBuilder.
    def fields_for attribute, *args
      options = args.extract_options!
      super attribute, options.merge(builder: self.class)
    end

    %i[
      email_field
      password_field
      text_area
      text_field
    ].each do |method_name|
      define_method(method_name) do |attribute, *args|
        content_tag :div, class: form_group_classes(attribute), id: form_group_id(attribute) do
          options = args.extract_options!
          text_field_class = ["form-control"]
          options[:class] = text_field_class

          label = label(attribute, class: "form-label")
          add_hint :label, label, attribute
          (label + super(attribute, options.except(:label)) ).html_safe
        end
      end
    end

    def radio_button_fieldset attribute, options={}
      content_tag :fieldset, fieldset_options(options) do
        safe_join([
          fieldset_legend(attribute),
          radio_inputs(attribute, options)
        ], "\n")
      end
    end

    private

    def radio_inputs attribute, options
      choices = options[:choices] || [ :yes, :no ]
      choices.map do |choice|
        label(attribute, class: 'block-label', value: choice) do |tag|
          input = radio_button(attribute, choice)
          input + localized_label("#{attribute}.#{choice}")
        end
      end
    end

    def fieldset_legend attribute
      legend = content_tag(:legend, fieldset_text(attribute), class: 'heading-medium')
      add_hint :legend, legend, attribute
      legend.html_safe
    end

    def fieldset_options options
      fieldset_options = {}
      fieldset_options[:class] = 'inline' if options[:inline] == true
      fieldset_options
    end

    def add_error_to_html_tag! html_tag
      case html_tag
      when /^<label/
        add_error_to_label! html_tag
      when /^<input/
        add_error_to_input! html_tag
      else
        html_tag
      end
    end

    def attribute_prefix
      @object_name.to_s.tr('[]','_').squeeze('_').chomp('_')
    end

    def form_group_id attribute
      "error_#{attribute_prefix}_#{attribute}" if error_for? attribute
    end

    def add_error_to_label! html_tag
      field = html_tag[/for="([^"]+)"/, 1]
      object_attribute = object_attribute_for field
      message = error_full_message_for object_attribute
      html_tag.sub!('</label',
        %'<span class="error-message" id="error_message_#{field}">#{message}</span></label')
    end

    def add_error_to_input! html_tag
      field = html_tag[/id="([^"]+)"/, 1]
      html_tag.sub!('input', %'input aria-describedby="error_message_#{field}"')
    end

    def form_group_classes attribute
      classes = 'form-group'
      classes += ' error' if error_for? attribute
      classes
    end

    def error_full_message_for attribute
      message = errors.full_messages_for(attribute).first
      message.sub! default_label(attribute), localized_label(attribute)
      message
    end

    def error_for? attribute
      errors.messages.key?(attribute) && !errors.messages[attribute].empty?
    end

    def object_attribute_for field
      field.to_s.
        sub("#{attribute_prefix}_", '').
        to_sym
    end

    def add_hint tag, element, name
      if hint = hint_text(name)
        hint_span = content_tag(:span, hint, class: 'form-hint')
        element.sub!("</#{tag}>", "#{hint_span}</#{tag}>".html_safe)
      end
    end

    def fieldset_text attribute
      localized 'helpers.fieldset', attribute, default_label(attribute)
    end

    def hint_text attribute
      localized 'helpers.hint', attribute, ''
    end

    def default_label attribute
      attribute.to_s.split('.').last.humanize.capitalize
    end

    def localized_label attribute
      localized 'helpers.label', attribute, default_label(attribute)
    end

    def localized scope, attribute, default
      key = "#{object_name}.#{attribute}"
      I18n.t(key,
        default: default,
        scope: scope).presence
    end
  end
end
