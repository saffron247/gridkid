=begin
    GridKid Grid and Environment Classes
    Author: Ethan Baldwin
    Date: February 13, 2023
=end

require_relative 'expressions'

class Grid
    def initialize
        @data = Hash.new
    end

    def set(row, col, xpr)
        address = [row, col]
        @data.store(address, xpr)
    end

    def get(row, col)
        address = [row, col]
        if !@data.key?(address)
            nil
        else
            @data.fetch(address)
        end
    end

    def delete(row, col)
        address = [row, col]
        @data.delete(address)
    end
end

class Environment
    attr_accessor :grid

    def initialize(grid)
        @grid = grid
        reset_vars
    end

    def prepopulate
        @variables.store("pi", 3.14159)
        @variables.store("e", 2.71828)
        @variables.store("tau", 6.28318)
    end

    def get_var(key, start_loc, end_loc)
        if !@variables.key?(key)
            nil
        else
            value = @variables.fetch(key)
            if value.class == Integer
                IntPrimitive.new(value, start_loc, end_loc)
            elsif value.class == Float
                FloatPrimitive.new(value, start_loc, end_loc)
            else
                BoolPrimitive.new(value, start_loc, end_loc)
            end
        end
    end

    def set_var(key, value)
        @variables.store(key, value.val)
        value
    end

    def reset_vars
        @variables = Hash.new
        prepopulate
    end
end