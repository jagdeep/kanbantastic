module Kanbantastic

  class User
    include ActiveModel::Validations
    attr_reader :name, :email, :avatar
    validates_presence_of :name, :email, :avatar

    def initialize(name, email, avatar)
      @name = name
      @email = email
      @avatar = avatar
      self.valid?
    end
  end
end