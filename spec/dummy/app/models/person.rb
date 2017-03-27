class Person
  include ActiveModel::Model

  attr_accessor :address
  attr_accessor :email_work
  attr_accessor :email_home
  attr_accessor :has_user_account
  attr_accessor :location
  attr_accessor :name
  attr_accessor :ni_number
  attr_accessor :password
  attr_accessor :password_confirmation
  attr_accessor :waste_transport
  attr_accessor :gender
  attr_accessor :case_id

  validates_presence_of :name, :gender

  def address_attributes=(attributes)
    @address = Address.new(attributes)
  end

  def waste_transport_attributes=(attributes)
    @waste_transport = WasteTransport.new(attributes)
  end
end
