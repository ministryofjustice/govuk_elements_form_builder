class Country
  include ActiveModel::Model

  attr_accessor :name
  validates_presence_of :name

end
