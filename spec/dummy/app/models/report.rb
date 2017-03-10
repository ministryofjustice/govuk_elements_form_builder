class Report

  attr_accessor :name, :problem, :email

  def persisted?
    false
  end
end
