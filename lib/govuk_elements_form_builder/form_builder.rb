module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder

    ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
      add_error_to_html_tag! html_tag, instance
    end

    delegate :content_tag, :tag, :safe_join, :safe_concat, :capture, to: :@template
    delegate :errors, to: :@object

    # Used to propagate the fieldset outer element attribute to the inner elements
    attr_accessor :current_fieldset_attribute

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

          set_label_classes! options
          set_field_classes! options, attribute

          label = label(attribute, options[:label_options])

          add_hint :label, label, attribute

          (label + super(attribute, options.except(:label, :label_options))).html_safe
        end
      end
    end

    def radio_button_fieldset attribute, options={}, &block
      content_tag :div,
                  class: form_group_classes(attribute),
                  id: form_group_id(attribute) do
        content_tag :fieldset, fieldset_options(attribute, options) do
          safe_join([
                      fieldset_legend(attribute, options),
                      block_given? ? capture(self, &block) : radio_inputs(attribute, options)
                    ], "\n")
        end
      end
    end

    def check_box_fieldset legend_key, attributes, options={}, &block
      content_tag :div,
                  class: form_group_classes(attributes),
                  id: form_group_id(attributes) do
        content_tag :fieldset, fieldset_options(attributes, options) do
          safe_join([
                      fieldset_legend(legend_key, options),
                      block_given? ? capture(self, &block) : check_box_inputs(attributes, options)
                    ], "\n")
        end
      end
    end

    def collection_select method, collection, value_method, text_method, options = {}, *args

      content_tag :div, class: form_group_classes(method), id: form_group_id(method) do

        html_options = args.extract_options!
        set_field_classes! html_options, method

        label = label(method, class: "form-label")
        add_hint :label, label, method

        (label+ super(method, collection, value_method, text_method, options , html_options)).html_safe
      end
    end

    def collection_check_boxes  method, collection, value_method, text_method, options = {}, *args
      content_tag :div,
                  class: form_group_classes(method),
                  id: form_group_id(method) do
        content_tag :fieldset, fieldset_options(method, options) do
          legend_key = method
          legend = fieldset_legend(legend_key, options)

          collection =  super(method, collection, value_method, text_method, options) do |b|
                          content_tag :div, class: "multiple-choice" do
                            b.check_box + b.label
                          end
                        end

          (legend + collection).html_safe
        end
      end
    end

    def collection_radio_buttons method, collection, value_method, text_method, options = {}, *args
      content_tag :div,
                  class: form_group_classes(method),
                  id: form_group_id(method) do
        content_tag :fieldset, fieldset_options(method, options) do

          legend_key = method
          legend = fieldset_legend(legend_key, options)

          collection =  super(method, collection, value_method, text_method, options) do |b|
                          content_tag :div, class: "multiple-choice" do
                            b.radio_button + b.label
                          end
                        end

          (legend + collection).html_safe
        end
      end
    end

    # The following method will generate revealing panel markup and internally call the
    # `radio_inputs` private method. It is not intended to be used outside a
    # fieldset tag (at the moment, `radio_button_fieldset`).
    #
    def radio_input choice, options = {}, &block
      fieldset_attribute = self.current_fieldset_attribute

      panel = if block_given? || options.key?(:panel_id)
        panel_id = options.delete(:panel_id) { [fieldset_attribute, choice, 'panel'].join('_') }
        options.merge!('data-target': panel_id)
        revealing_panel(panel_id, flush: false, &block) if block_given?
      end

      option = radio_inputs(
        fieldset_attribute,
        options.merge(choices: [choice])
      ).first + "\n"

      safe_concat([option, panel].join)
    end

    # The following method will generate revealing panel markup and internally call the
    # `check_box_inputs` private method. It is not intended to be used outside a
    # fieldset tag (at the moment, `check_box_fieldset`).
    #
    def check_box_input attribute, options = {}, &block
      panel = if block_given? || options.key?(:panel_id)
                panel_id = options.delete(:panel_id) { [attribute, 'panel'].join('_') }
                options.merge!('data-target': panel_id)
                revealing_panel(panel_id, flush: false, &block) if block_given?
              end

      checkbox = check_box_inputs([attribute], options).first + "\n"

      safe_concat([checkbox, panel].join)
    end

    def revealing_panel panel_id, options = {}, &block
      panel = content_tag(
        :div, class: 'panel panel-border-narrow js-hidden', id: panel_id
      ) { block.call(BlockBuffer.new(self)) } + "\n"

      options.fetch(:flush, true) ? safe_concat(panel) : panel
    end

    private

    # Given an attributes hash that could include any number of arbitrary keys, this method
    # ensure we merge one or more 'default' attributes into the hash, creating the keys if
    # don't exist, or merging the defaults if the keys already exists.
    # It supports strings or arrays as values.
    #
    def merge_attributes attributes, default:
      hash = attributes || {}
      hash.merge(default) { |_key, oldval, newval| Array(newval) + Array(oldval) }
    end

    def set_field_classes! options, attribute
      default_classes = ['form-control']
      default_classes << 'form-control-error' if error_for?(attribute)

      options ||= {}
      options.merge!(
        merge_attributes(options, default: {class: default_classes})
      )
    end

    def set_label_classes! options
      options ||= {}
      options[:label_options] ||= {}
      options[:label_options].merge!(
        merge_attributes(options[:label_options], default: {class: 'form-label'})
      )
    end

    def check_box_inputs attributes, options
      attributes.map do |attribute|
        input = check_box(attribute)
        label = label(attribute) do |tag|
          localized_label("#{attribute}")
        end
        content_tag :div, {class: 'multiple-choice'}.merge(options.slice(:class, :'data-target')) do
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
        content_tag :div, {class: 'multiple-choice'}.merge(options.slice(:class, :'data-target')) do
          input + label
        end
      end
    end

    def fieldset_legend attribute, options
      legend_text = options.fetch(:legend_options, {}).delete(:text)

      legend = content_tag(:legend) do
        tags = [content_tag(
                  :span,
                  legend_text || fieldset_text(attribute),
                  merge_attributes(options[:legend_options], default: {class: 'form-label-bold'})
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

    def fieldset_options attribute, options
      self.current_fieldset_attribute = attribute

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
      classes += ' form-group-error' if attributes.find { |a| error_for? a }
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
