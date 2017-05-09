module Steps::Appeal
  class Penalty
    include ActiveModel::Model

    attr_accessor :amount

    validates_presence_of :amount
  end
end
