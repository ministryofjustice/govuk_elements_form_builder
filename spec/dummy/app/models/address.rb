class Address
  include ActiveModel::Model

  attr_accessor :address
  attr_accessor :postcode
  validates_presence_of :postcode

  attr_accessor :country

  def country_attributes=(attributes)
    @country = Country.new(attributes)
  end
end
