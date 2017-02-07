require_relative 'matchers/form_group_matcher_helpers'

module MatcherHelpers
  def self.included(base)
    base.send(:include, FormGroupMatcherHelpers)
  end
end
