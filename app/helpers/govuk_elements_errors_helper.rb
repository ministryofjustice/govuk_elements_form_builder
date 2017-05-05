module GovukElementsErrorsHelper

  class << self
    include ActionView::Context
    include ActionView::Helpers::TagHelper
  end

  def self.error_summary object, heading, description
    return unless errors_exist? object
    error_summary_div do
      error_summary_heading(heading) +
      error_summary_description(description) +
      error_summary_list(object)
    end
  end

  def self.errors_exist? object
    errors_present?(object) || child_errors_present?(object)
  end

  def self.child_errors_present? object
    attributes(object).any? { |child| errors_exist?(child) }
  end

  def self.attributes object, parent_object=nil
    return [] if object == parent_object
    parent_object ||= object

    child_objects = attribute_objects object
    nested_child_objects = child_objects.map { |o| attributes(o, parent_object) }
    (child_objects + nested_child_objects).flatten - [object]
  end

  def self.attribute_objects object
    object.
      instance_variables.
      map { |var| instance_variable(object, var) }.
      compact
  end

  def self.array_to_parent list, object, child_to_parents={}, parent_object
    list.each do |child|
      child_to_parents[child] = object
      child_to_parent child, child_to_parents, parent_object
    end
  end

  def self.child_to_parent object, child_to_parents={}, parent_object=nil
    return child_to_parents if object == parent_object
    parent_object ||= object

    attribute_objects(object).each do |child|
      if child.is_a?(Array)
        array_to_parent(child, object, child_to_parents, parent_object)
      else
        child_to_parents[child] = object
        child_to_parent child, child_to_parents, parent_object
      end
    end

    child_to_parents
  end

  def self.instance_variable object, var
    field = var.to_s.sub('@','').to_sym
    if object.respond_to?(field)
      child = object.send(field)
      if respond_to_errors?(child) || child.is_a?(Array)
        child
      else
        nil
      end
    end
  end

  def self.respond_to_errors? object
    object && object.respond_to?(:errors)
  end

  def self.errors_present? object
    respond_to_errors?(object) && object.errors.present?
  end

  def self.children_with_errors object
    attributes(object).select { |child| errors_present?(child) }
  end

  def self.error_summary_div &block
    content_tag(:div,
        class: 'error-summary',
        role: 'group',
        aria: {
          labelledby: 'error-summary-heading'
        },
        tabindex: '-1') do
      yield block
    end
  end

  def self.error_summary_heading text
    content_tag :h1,
      text,
      id: 'error-summary-heading',
      class: 'heading-medium error-summary-heading'
  end

  def self.error_summary_description text
    content_tag :p, text
  end

  def self.error_summary_list object
    content_tag(:ul, class: 'error-summary-list') do
      child_to_parents = child_to_parent(object)
      messages = error_summary_messages(object, child_to_parents)

      messages << children_with_errors(object).map do |child|
        error_summary_messages(child, child_to_parents)
      end

      messages.flatten.join('').html_safe
    end
  end

  def self.error_summary_messages object, child_to_parents
    object.errors.keys.map do |attribute|
      error_summary_message object, attribute, child_to_parents
    end
  end

  def self.error_summary_message object, attribute, child_to_parents
    messages = object.errors.full_messages_for attribute
    messages.map do |message|
      object_prefixes = object_prefixes object, child_to_parents
      link = link_to_error(object_prefixes, attribute)
      message.sub! default_label(attribute), localized_label(object_prefixes, attribute)
      content_tag(:li, content_tag(:a, message, href: link))
    end
  end

  def self.link_to_error object_prefixes, attribute
    ['#error', *object_prefixes, attribute].join('_')
  end

  def self.default_label attribute
    attribute.to_s.humanize.capitalize
  end

  def self.localized_label object_prefixes, attribute
    object_key = object_prefixes.shift
    object_prefixes.each { |prefix| object_key += "[#{prefix}]" }
    key = "#{object_key}.#{attribute}"
    I18n.t(key,
      default: default_label(attribute),
      scope: 'helpers.label').presence
  end

  def self.parents_list object, child_to_parents
    if parent = child_to_parents[object]
      [].tap do |parents|
        while parent && !parents.include?(parent)
          parents.unshift parent # prepends parent to front of parents
          parent = child_to_parents[parent]
        end
      end
    end
  end

  def self.object_prefixes object, child_to_parents
    parents = parents_list object, child_to_parents

    if parents.present?
      root = parents.shift
      prefixes = [underscore_name(root)]
      parents.each { |p| prefixes << "#{underscore_name p}_attributes" }
      prefixes << "#{underscore_name object}_attributes"
    else
      prefixes = [underscore_name(object)]
    end
  end

  # `underscore` changes '::' to '/' to convert namespaces to paths
  def self.underscore_name object
    object.class.name.underscore.tr('/'.freeze, '_'.freeze)
  end

  private_class_method :error_summary_div
  private_class_method :error_summary_heading
  private_class_method :error_summary_description
  private_class_method :error_summary_messages

end
