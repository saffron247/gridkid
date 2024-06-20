=begin
    GridKid Error Class
    Author: Ethan Baldwin
    Date: March 10, 2023
=end

class Error
    attr_accessor :message

    def initialize(message)
        @message = message
    end

    def evaluate(env)
        @message
    end
end