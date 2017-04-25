module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder

    ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
      add_error_to_html_tag! html_tag, instance
    end

    delegate :content_tag, :tag, :safe_join, to: :@template
    delegate :errors, to: :@object

    # Ensure fields_for yields a GovukElementsFormBuilder.
    def fields_for record_name, record_object = nil, fields_options = {}, &block
      super record_name, record_object, fields_options.merge(builder: self.class), &block
    end

    %i[
      email_field
      password_field
      number_field
      phone_field
      range_field
      search_field
      telephone_field
      text_area
      text_field
      url_field
    ].each do |method_name|
      define_method(method_name) do |attribute, *args|
        content_tag :div, class: form_group_classes(attribute), id: form_group_id(attribute) do
          options = args.extract_options!
          set_field_classes! options

          label = label(attribute, class: "form-label")
          add_hint :label, label, attribute
          (label + super(attribute, options.except(:label)) ).html_safe
        end
      end
    end

    def radio_button_fieldset attribute, options={}
      content_tag :div,
                  class: form_group_classes(attribute),
                  id: form_group_id(attribute) do
        content_tag :fieldset, fieldset_options(attribute, options) do
          safe_join([
                      fieldset_legend(attribute),
                      radio_inputs(attribute, options)
                    ], "\n")
        end
      end
    end

    def check_box_fieldset legend_key, attributes, options={}
      content_tag :div,
                  class: form_group_classes(attributes),
                  id: form_group_id(attributes) do
        content_tag :fieldset, fieldset_options(attributes, options) do
          safe_join([
                      fieldset_legend(legend_key),
                      check_box_inputs(attributes)
                    ], "\n")
        end
      end
    end

    def collection_select method, collection, value_method, text_method, options = {}, *args

      content_tag :div, class: form_group_classes(method), id: form_group_id(method) do

        html_options = args.extract_options!
        set_field_classes! html_options

        label = label(method, class: "form-label")
        add_hint :label, label, method

        (label+ super(method, collection, value_method, text_method, options , html_options)).html_safe
      end

    end

    private

    def set_field_classes! options
      text_field_class = "form-control"
      options[:class] = case options[:class]
                        when String
                          [text_field_class, options[:class]]
                        when Array
                          options[:class].unshift text_field_class
                        else
                          options[:class] = text_field_class
                        end
    end

    def check_box_inputs attributes
      attributes.map do |attribute|
        input = check_box(attribute)
        label = label(attribute) do |tag|
          localized_label("#{attribute}")
        end
        content_tag :div, class: "multiple-choice" do
          input + label
        end
      end
    end

    def radio_inputs attribute, options
      choices = options[:choices] || [ :yes, :no ]
      choices.map do |choice|
        value = choice.send(options[:value_method] || :to_s)
        input = radio_button(attribute, value)
        label = label(attribute, value: value) do |tag|
                text = if options.has_key? :text_method
                        choice.send(options[:text_method])
                      else
                        localized_label("#{attribute}.#{choice}")
                      end
                text
        end
        content_tag :div, class: "multiple-choice" do
          input + label
        end
      end
    end

    def fieldset_legend attribute
      legend = content_tag(:legend) do
        tags = [content_tag(
                  :span,
                  fieldset_text(attribute),
                  class: 'form-label-bold'
                )]

        if error_for? attribute
          tags << content_tag(
            :span,
            error_full_message_for(attribute),
            class: 'error-message'
          )
        end

        hint = hint_text attribute
        tags << content_tag(:span, hint, class: 'form-hint') if hint

        safe_join tags
      end
      legend.html_safe
    end

    def fieldset_options attributes, options
      fieldset_options = {}
      fieldset_options[:class] = 'inline' if options[:inline] == true
      fieldset_options
    end

    private_class_method def self.add_error_to_html_tag! html_tag, instance
      object_name = instance.instance_variable_get(:@object_name)
      object = instance.instance_variable_get(:@object)

      case html_tag
      when /^<label/
        add_error_to_label! html_tag, object_name, object
      when /^<input/
        add_error_to_input! html_tag, 'input'
      when /^<textarea/
        add_error_to_input! html_tag, 'textarea'
      else
        html_tag
      end
    end

    def self.attribute_prefix object_name
      object_name.to_s.tr('[]','_').squeeze('_').chomp('_')
    end

    def attribute_prefix
      self.class.attribute_prefix(@object_name)
    end

    def form_group_id attribute
      "error_#{attribute_prefix}_#{attribute}" if error_for? attribute
    end

    private_class_method def self.add_error_to_label! html_tag, object_name, object
      field = html_tag[/for="([^"]+)"/, 1]
      object_attribute = object_attribute_for field, object_name
      message = error_full_message_for object_attribute, object_name, object
      if message
        html_tag.sub(
          '</label',
          %Q{<span class="error-message" id="error_message_#{field}">#{message}</span></label}
        ).html_safe # sub() returns a String, not a SafeBuffer
      else
        html_tag
      end
    end

    private_class_method def self.add_error_to_input! html_tag, element
      field = html_tag[/id="([^"]+)"/, 1]
      html_tag.sub(
        element,
        %Q{#{element} aria-describedby="error_message_#{field}"}
      ).html_safe # sub() returns a String, not a SafeBuffer
    end

    def form_group_classes attributes
      attributes = [attributes] if !attributes.respond_to? :count
      classes = 'form-group'
      classes += ' error' if attributes.find { |a| error_for? a }
      classes
    end

    def self.error_full_message_for attribute, object_name, object
      message = object.errors.full_messages_for(attribute).first
      message&.sub default_label(attribute), localized_label(attribute, object_name)
    end

    def error_full_message_for attribute
      self.class.error_full_message_for attribute, @object_name, @object
    end

    def error_for? attribute
      object.respond_to?(:errors) &&
      errors.messages.key?(attribute) &&
      !errors.messages[attribute].empty?
    end

    private_class_method def self.object_attribute_for field, object_name
      field.to_s.
        sub("#{attribute_prefix(object_name)}_", '').
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

    def self.default_label attribute
      attribute.to_s.split('.').last.humanize.capitalize
    end

    def default_label attribute
      self.class.default_label attribute
    end

    def self.localized_label attribute, object_name
      localized 'helpers.label', attribute, default_label(attribute), object_name
    end

    def localized_label attribute
      self.class.localized_label attribute, @object_name
    end

    def self.localized scope, attribute, default, object_name
      key = "#{object_name}.#{attribute}"
      translate key, default, scope
    end

    def self.translate key, default, scope
      # Passes blank String as default because nil is interpreted as no default
      I18n.translate(key, default: '', scope: scope).presence ||
      I18n.translate("#{key}_html", default: default, scope: scope).html_safe.presence
    end

    def localized scope, attribute, default
      self.class.localized scope, attribute, default, @object_name
    end

  end
end
