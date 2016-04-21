class Person
  include ActiveModel::Model
  GENDER = %w{ female male }

  attr_accessor :address
  attr_accessor :email_work
  attr_accessor :email_home
  attr_accessor :has_user_account
  attr_accessor :location
  attr_accessor :name
  attr_accessor :ni_number
  attr_accessor :password
  attr_accessor :password_confirmation

  validates_presence_of :name

  def address_attributes=(attributes)
    @address = Address.new(attributes)
  end
end
