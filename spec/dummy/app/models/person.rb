class Person
  include ActiveModel::Model
  GENDER = %w{ female male }

  attr_accessor :name
  validates_presence_of :name

  attr_accessor :ni_number
  attr_accessor :email_work
  attr_accessor :email_home
  attr_accessor :password
  attr_accessor :password_confirmation
  attr_accessor :gender
  attr_accessor :has_user_account

  attr_accessor :address

  def address_attributes=(attributes)
    @address = Address.new(attributes)
  end
end
