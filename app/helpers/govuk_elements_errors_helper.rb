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
      error_summary_messages(object)
    end
  end

  def self.errors_exist? object
    object.errors.present? ||
      object.instance_variables.any? do |var|
        field = var.to_s.sub('@','').to_sym
        object.send(field) &&
          object.send(field).respond_to?(:errors) &&
          object.send(field).errors.present?
      end
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

  def self.error_summary_messages object
    content_tag(:ul,
        class: 'error-summary-list') do
      prefix = object.class.name.underscore

      object.errors.keys.map do |attribute|
        error_summary_message object, prefix, attribute
      end.flatten.join('').html_safe
    end
  end

  def self.error_summary_message object, prefix, attribute
    messages = object.errors.full_messages_for attribute
    messages.map do |message|
      content_tag(:li, content_tag(:a, message, href: "#error_#{prefix}_#{attribute}"))
    end
  end

  private_class_method :error_summary_div
  private_class_method :error_summary_heading
  private_class_method :error_summary_description
  private_class_method :error_summary_messages

end
