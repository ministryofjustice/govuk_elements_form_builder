class Case
  include ActiveModel::Model

  attr_accessor :id
  attr_accessor :name
  attr_accessor :state_machine
  attr_accessor :subcases

  validates_presence_of :name
  validate :validate_subcases

  def validate_subcases
    subcases.each {|x| x.valid?} if subcases
  end
end
