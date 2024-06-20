=begin
    GridKid Expression Abstractions Classes
    Author: Ethan Baldwin
    Date: February 13, 2023
=end

require_relative 'error'

# Parent class
class Expression
end

# Primitives
class Primitive < Expression
    attr_accessor :val, :start_loc, :end_loc
    
    def initialize(val, start_loc, end_loc)
        @val = val
        @start_loc = start_loc
        @end_loc = end_loc
    end
    
    def evaluate(env)
        self
    end
end

class IntPrimitive < Primitive
end

class FloatPrimitive < Primitive
end

class BoolPrimitive < Primitive
end

class StringPrimitive < Primitive
end

# Arithmetic operations
class BinaryArithmeticOp < Expression
    attr_accessor :lval, :rval, :start_loc, :end_loc

    def initialize(lval, rval)
        @lval = lval
        @rval = rval
        @start_loc = lval.start_loc
        @end_loc = rval.end_loc
    end

    def evaluate(env)
        left = lval.evaluate(env)
        right = rval.evaluate(env)
        if left.class == IntPrimitive && right.class == IntPrimitive
            IntPrimitive.new(compute(left, right), start_loc, end_loc)
        elsif left.class == FloatPrimitive && right.class == FloatPrimitive
            FloatPrimitive.new(compute(left, right), start_loc, end_loc)
        elsif left.class == String
            left
        elsif right.class == String
            right
        else
            "error: arithmetic type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

class Add < BinaryArithmeticOp
    private
    def compute(left, right)
        left.val + right.val
    end
end

class Subtract < BinaryArithmeticOp
    private
    def compute(left, right)
        left.val - right.val
    end
end

class Multiply < BinaryArithmeticOp
    private
    def compute(left, right)
        left.val * right.val
    end
end

class Divide < BinaryArithmeticOp
    private
    def compute(left, right)
        if left.class == FloatPrimitive
            left.val.to_f / right.val.to_f
        else
            left.val / right.val
        end
    end
end

class Modulo < BinaryArithmeticOp
    private
    def compute(left, right)
        left.val % right.val
    end
end

class Expo < BinaryArithmeticOp
    private
    def compute(left, right)
        left.val ** right.val
    end
end

# Logical operations
class BinaryLogicalOp < Expression
    attr_accessor :lval, :rval, :start_loc, :end_loc

    def initialize(lval, rval)
        @lval = lval
        @rval = rval
        @start_loc = lval.start_loc
        @end_loc = rval.end_loc
    end

    def evaluate(env)
        left = lval.evaluate(env)
        # For bypassing checking the second operand
        if left.class == BoolPrimitive && checkLeft(left)
            BoolPrimitive.new(left.val, start_loc, end_loc)
        else
            right = rval.evaluate(env)
            if left.class == BoolPrimitive && right.class == BoolPrimitive
                BoolPrimitive.new(compute(left, right), start_loc, end_loc)
            elsif left.class == String
                left
            elsif right.class == String
                right
            else
                "error: logical type mismatch at #{start_loc}-#{end_loc}"
            end
        end
    end
end

class LogicalAnd < BinaryLogicalOp
    private
    def checkLeft(left)
        !(left.val)
    end

    def compute(left, right)
        left.val && right.val
    end
end

class LogicalOr < BinaryLogicalOp
    private
    def checkLeft(left)
        left.val
    end

    def compute(left, right)
        left.val || right.val
    end
end

class LogicalNot < Expression
    attr_accessor :only, :start_loc, :end_loc

    def initialize(only, start_loc)
        @only = only
        @start_loc = start_loc
        @end_loc = only.end_loc
    end

    def evaluate(env)
        evalue = only.evaluate(env)
        if evalue.class == BoolPrimitive
            BoolPrimitive.new(!(evalue.val), start_loc, end_loc)
        elsif evalue.class == String
            evalue
        else
            "error: logical type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

# Bitwise operations
class BinaryBitwiseOp < Expression
    attr_accessor :lval, :rval, :start_loc, :end_loc

    def initialize(lval, rval)
        @lval = lval
        @rval = rval
        @start_loc = lval.start_loc
        @end_loc = rval.end_loc
    end

    def evaluate(env)
        left = lval.evaluate(env)
        right = rval.evaluate(env)
        if left.class == IntPrimitive && right.class == IntPrimitive
            IntPrimitive.new(compute(left, right), start_loc, end_loc)
        elsif left.class == String
            left
        elsif right.class == String
            right
        else
            "error: bitwise type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

class BitwiseAnd < BinaryBitwiseOp
    private
    def compute(left, right)
        left.val & right.val
    end
end

class BitwiseOr < BinaryBitwiseOp
    private
    def compute(left, right)
        left.val | right.val
    end
end

class BitwiseXor < BinaryBitwiseOp
    private
    def compute(left, right)
        left.val ^ right.val
    end
end

class BitwiseLeftShift < BinaryBitwiseOp
    private
    def compute(left, right)
        left.val << right.val
    end
end

class BitwiseRightShift < BinaryBitwiseOp
    private
    def compute(left, right)
        left.val >> right.val
    end
end

class BitwiseNot < Expression
    attr_accessor :only, :start_loc, :end_loc

    def initialize(only, start_loc)
        @only = only
        @start_loc = start_loc
        @end_loc = only.end_loc
    end

    def evaluate(env)
        evalue = only.evaluate(env)
        if evalue.class == IntPrimitive
            IntPrimitive.new(~(evalue.val), start_loc, end_loc)
        elsif evalue.class == String
            evalue
        else
            "error: bitwise type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

# Relational operations
class RelationalWithBool < Expression
    attr_accessor :lval, :rval, :start_loc, :end_loc

    def initialize(lval, rval)
        @lval = lval
        @rval = rval
        @start_loc = lval.start_loc
        @end_loc = rval.end_loc
    end

    def evaluate(env)
        left = lval.evaluate(env)
        right = rval.evaluate(env)
        if (left.class == IntPrimitive && right.class == IntPrimitive) ||
            (left.class == FloatPrimitive && right.class == FloatPrimitive) ||
            (left.class == BoolPrimitive && right.class == BoolPrimitive)
            BoolPrimitive.new(compute(left, right), start_loc, end_loc)
        elsif left.class == String
            left
        elsif right.class == String
            right
        else
            "error: relational type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

class Equals < RelationalWithBool
    private
    def compute(left, right)
        left.val == right.val
    end
end

class NotEquals < RelationalWithBool
    private
    def compute(left, right)
        left.val != right.val
    end
end

class RelationalWithoutBool < Expression
    attr_accessor :lval, :rval, :start_loc, :end_loc

    def initialize(lval, rval)
        @lval = lval
        @rval = rval
        @start_loc = lval.start_loc
        @end_loc = rval.end_loc
    end

    def evaluate(env)
        left = lval.evaluate(env)
        right = rval.evaluate(env)
        if (left.class == IntPrimitive && right.class == IntPrimitive) ||
            (left.class == FloatPrimitive && right.class == FloatPrimitive)
            BoolPrimitive.new(compute(left, right), start_loc, end_loc)
        elsif left.class == String
            left
        elsif right.class == String
            right
        else
            "error: relational type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

class LessThan < RelationalWithoutBool
    private
    def compute(left, right)
        left.val < right.val
    end
end

class LessThanOrEqualTo < RelationalWithoutBool
    private
    def compute(left, right)
        left.val <= right.val
    end
end

class GreaterThan < RelationalWithoutBool
    private
    def compute(left, right)
        left.val > right.val
    end
end

class GreaterThanOrEqualTo < RelationalWithoutBool
    private
    def compute(left, right)
        left.val >= right.val
    end
end

# Casting operators
class FloatToInt < Expression
    attr_accessor :only, :start_loc, :end_loc

    def initialize(only, start_loc)
        @only = only
        @start_loc = start_loc
        @end_loc = only.end_loc
    end

    def evaluate(env)
        evalue = only.evaluate(env)
        if evalue.class == FloatPrimitive
            IntPrimitive.new(evalue.val.to_int, start_loc, end_loc)
        elsif evalue.class == String
            evalue
        else
            "error: casting type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

class IntToFloat < Expression
    attr_accessor :only, :start_loc, :end_loc

    def initialize(only, start_loc)
        @only = only
        @start_loc = start_loc
        @end_loc = only.end_loc
    end

    def evaluate(env)
        evalue = only.evaluate(env)
        if evalue.class == IntPrimitive
            FloatPrimitive.new(evalue.val.to_f, start_loc, end_loc)
        elsif evalue.class == String
            evalue
        else
            "error: casting type mismatch at #{start_loc}-#{end_loc}"
        end
    end
end

# Cell reference
class CellReference < Expression
    attr_accessor :row, :col, :start_loc, :end_loc

    def initialize(row, col, start_loc, end_loc)
        @row = row
        @col = col
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        r = row.evaluate(env)
        c = col.evaluate(env)
        if r.class != IntPrimitive || c.class != IntPrimitive
            "error: invalid cell reference at #{start_loc}-#{end_loc}"
        else
            output = env.grid.get(r.val, c.val)
            if output == nil
                "error: cell [#{r.val}, #{c.val}] is empty"
            elsif caller.length >= 100   # catch stack depth at 100
                "error: cyclical cell reference to [#{r.val}, #{c.val}]"
            elsif output.evaluate(env).class == String
                "error: cell [#{r.val}, #{c.val}] yields an error"
            else
                output.evaluate(env)
            end
        end
    end
end

# Variable lookup
class Variable < Expression
    attr_accessor :key, :start_loc, :end_loc

    def initialize(key, start_loc, end_loc)
        @key = key
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        value = env.get_var(@key, @start_loc, @end_loc)
        if value == nil
            "error: variable at #{start_loc}-#{end_loc} is never initialized"
        else
            value
        end
    end
end

# Variable assignment
class VariableAssignment < Expression
    attr_accessor :key, :val, :start_loc, :end_loc

    def initialize(key, val, start_loc, end_loc)
        @key = key
        @val = val
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        value = @val.evaluate(env)
        if value.class == String
            value
        else
            env.set_var(key, value)
        end
    end
end

# Builtin functions
class RectangularFunc < Expression
    attr_accessor :tl_row, :tl_col, :br_row, :br_col, :start_loc, :end_loc
    
    def initialize(tl_row, tl_col, br_row, br_col, start_loc, end_loc)
        @tl_row = tl_row
        @tl_col = tl_col
        @br_row = br_row
        @br_col = br_col
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        output = nil;
        target_type = nil;
        tl_r = @tl_row.evaluate(env)
        tl_c = @tl_col.evaluate(env)
        br_r = @br_row.evaluate(env)
        br_c = @br_col.evaluate(env)
        if tl_r.class != IntPrimitive || tl_c.class != IntPrimitive ||
            br_r.class != IntPrimitive || br_c.class != IntPrimitive
            return "error: invalid cell reference at #{start_loc}-#{end_loc}"
        else
            (tl_r.val..br_r.val).each do |r|
                (tl_c.val..br_c.val).each do |c|
                    current = CellReference.new(IntPrimitive.new(r, 0, 0),
                        IntPrimitive.new(c, 0, 0), @start_loc, @end_loc).evaluate(env)
                    if target_type == nil
                        target_type = current.class
                    end
                    output = run_checks(target_type, output, current, env, r, c)
                    if output.class == String
                        return output
                    end
                end
            end
        end
        if target_type == nil
            "error: invalid bounds"
        else
            send_output(target_type, output)
        end
    end

    def run_checks(target_type, output, current, env, r, c)
        if current.class == String
            current
        elsif current.class != IntPrimitive && current.class != FloatPrimitive
            "error: cell [#{r}, #{c}] holds an invalid type for functions"
        elsif current.class != target_type
            "error: cell [#{r}, #{c}] holds a mismatched type"
        else
            output = compute(output, current, env)
        end
    end

    def send_output(target_type, output)
        target_type.new(output, @start_loc, @end_loc)
    end
end

class FuncSum < RectangularFunc
    def compute(old_val, new_val, env)
        if old_val == nil
            new_val.val
        else
            old_val + new_val.val
        end
    end
end

class FuncMin < RectangularFunc
    def compute(old_val, new_val, env)
        if old_val == nil
            new_val.val
        else
            [old_val, new_val.val].min
        end
    end
end

class FuncMax < RectangularFunc
    def compute(old_val, new_val, env)
        if old_val == nil
            new_val.val
        else
            [old_val, new_val.val].max
        end
    end
end

class FuncMean < RectangularFunc
    def compute(old_val, new_val, env)
        size = (@br_row.evaluate(env).val - @tl_row.evaluate(env).val + 1) *
            (@br_col.evaluate(env).val - @tl_col.evaluate(env).val + 1)
        if old_val == nil
            new_val.val.to_f * (1.0 / size)
        else
            old_val + (new_val.val.to_f * (1.0 / size))
        end
    end

    def send_output(target_type, output)
        FloatPrimitive.new(output, start_loc, end_loc)
    end
end

# Loop statement
class ForLoop < RectangularFunc
    attr_accessor :variable, :inner

    def initialize(tl_row, tl_col, br_row, br_col, start_loc, end_loc)
        super
        @variable = Error.new("error: failed for loop") # should never happen
        @inner = Error.new("error: failed for loop") # should never happen
    end

    def evaluate(env)
        if @variable.class == Error
            return @variable.evaluate(env)
        elsif @inner.class == Error
            return @inner.evaluate(env)
        else
            super
        end
    end
    
    def run_checks(target_type, output, current, env, r, c)
        if current.class == String
            current
        else
            output = compute(output, current, env)
        end
    end

    def compute(old_val, new_val, env)
        var = VariableAssignment.new(@variable.key, new_val, @start_loc, @end_loc)
        var.evaluate(env)
        @inner.evaluate(env)
    end

    def send_output(target_type, output)
        output
    end
end

# Multi-statement block
class Block < Expression
    attr_accessor :statements, :start_loc, :end_loc

    def initialize(statements, start_loc, end_loc)
        @statements = statements
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        if @statements.class == Error
            return @statements.evaluate(env)
        elsif @statements.length == 0
            return "error: empty block at #{start_loc}-#{end_loc}"
        end
        current = nil
        (0..(@statements.length - 1)).each do |i|
            current = @statements[i].evaluate(env)
            if current.class == String
                return current
            end
        end
        current
    end
end

# Conditional statement
class IfElse < Expression
    attr_accessor :condition, :if_block, :else_block, :start_loc, :end_loc

    def initialize(condition, if_block, else_block, start_loc, end_loc)
        @condition = condition
        @if_block = if_block
        @else_block = else_block
        @start_loc = start_loc
        @end_loc = end_loc
    end

    def evaluate(env)
        cnd = @condition.evaluate(env)
        if cnd.class == String
            cnd
        elsif cnd.class != BoolPrimitive
            "error: condition at #{cnd.start_loc}-#{cnd.end_loc} is not a boolean"
        elsif @if_block.class == Error
            @if_block.evaluate(env)
        elsif @else_block.class == Error
            @else_block.evaluate(env)
        else
            if cnd.val
                @if_block.evaluate(env)
            else
                @else_block.evaluate(env)
            end
        end
    end
end