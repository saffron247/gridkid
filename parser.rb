=begin
    GridKid Parser Class
    Author: Ethan Baldwin
    Date: March 8, 2023
=end

require_relative 'expressions'
require_relative 'error'

class Parser
    def parse(tokens)
        @tokens = tokens

        if @tokens.class == Error
            return @tokens
        end

        @i = -1;
        @tree = expression

        if (@tree.class == Error)
            return @tree
        elsif @i != @tokens.length - 1
            return Error.new("error: parse length error")
        else
            @tree
        end
    end

    def has(type)
        if !@tokens[@i + 1].nil?
            @tokens[@i + 1][:type] == type
        else
            false
        end
    end

    def has_ahead(type)
        output = false;
        j = @i
        while j < @tokens.length
            if @tokens[j][:type] == type
                return true
            end
            j += 1
        end
        false
    end

    def advance
        if @i < @tokens.length
            @i += 1
            @tokens[@i]
        else
            return error
        end
    end

    def expression
        return logical_or
    end

    def logical_or
        left = logical_and
        while has(LogicalOr) && left.class != Error
            operator = advance
            right = logical_and
            if right.class != Error
                left = LogicalOr.new(left, right)
            else
                return right
            end
        end
        return left
    end

    def logical_and
        left = relational_all
        while has(LogicalAnd) && left.class != Error
            operator = advance
            right = relational_all
            if right.class != Error
                left = LogicalAnd.new(left, right)
            else
                return right
            end
        end
        return left
    end

    def relational_all
        left = relational_num
        while (has(Equals) || has(NotEquals)) && left.class != Error
            operator = advance
            right = relational_num
            if right.class != Error
                if operator[:type] == Equals
                    left = Equals.new(left, right)
                else
                    left = NotEquals.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end

    def relational_num
        left = bitwise_or
        while (has(LessThan) || has(LessThanOrEqualTo) || has(GreaterThan) || has(GreaterThanOrEqualTo)) && left.class != Error
            operator = advance
            right = bitwise_or
            if right.class != Error
                if operator[:type] == LessThan
                    left = LessThan.new(left, right)
                elsif operator[:type] == LessThanOrEqualTo
                    left = LessThanOrEqualTo.new(left, right)
                elsif operator[:type] == GreaterThan
                    left = GreaterThan.new(left, right)
                else
                    left = GreaterThanOrEqualTo.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end

    def bitwise_or
        left = bitwise_and
        while (has(BitwiseOr) || has(BitwiseXor)) && left.class != Error
            operator = advance
            right = bitwise_and
            if right.class != Error
                if operator[:type] == BitwiseOr
                    left = BitwiseOr.new(left, right)
                else
                    left = BitwiseXor.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end

    def bitwise_and
        left = bitwise_shift
        while has(BitwiseAnd) && left.class != Error
            operator = advance
            right = bitwise_shift
            if right.class != Error
                left = BitwiseAnd.new(left, right)
            else
                return right
            end
        end
        return left
    end

    def bitwise_shift
        left = additive
        while (has(BitwiseLeftShift) || has(BitwiseRightShift)) && left.class != Error
            operator = advance
            right = additive
            if right.class != Error
                if operator[:type] == BitwiseLeftShift
                    left = BitwiseLeftShift.new(left, right)
                else
                    left = BitwiseRightShift.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end
    
    def additive
        left = multiplicative
        while (has(Add) || has(Subtract)) && left.class != Error
            operator = advance
            right = multiplicative
            if right.class != Error
                if operator[:type] == Add
                    left = Add.new(left, right)
                else
                    left = Subtract.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end

    def multiplicative
        left = expo
        while (has(Multiply) || has(Divide) || has(Modulo)) && left.class != Error
            operator = advance
            right = expo
            if right.class != Error
                if operator[:type] == Multiply
                    left = Multiply.new(left, right)
                elsif operator[:type] == Divide
                    left = Divide.new(left, right)
                else
                    left = Modulo.new(left, right)
                end
            else
                return right
            end
        end
        return left
    end

    def expo 
        right = unary
        once = false
        while has(Expo) && right.class != Error
            operator = advance
            if once == false
                new_right = unary
                if new_right.class != Error
                    right = Expo.new(right, new_right)
                    once = true
                else
                    return new_right
                end
            else
                new_right = unary
                if new_right.class != Error
                    right.rval = Expo.new(right.rval, new_right)
                else
                    return new_right
                end
            end
        end
        return right
    end

    def unary
        if !(has(LogicalNot) || has(BitwiseNot) || has(FloatToInt) || has(IntToFloat))
            return cell_ref
        else
            operator = advance
            only = unary
            if only.class != Error
                if operator[:type] == LogicalNot
                    return LogicalNot.new(only, operator[:starts_at])
                elsif operator[:type] == BitwiseNot
                    return BitwiseNot.new(only, operator[:starts_at])
                elsif operator[:type] == FloatToInt
                    return FloatToInt.new(only, operator[:starts_at])
                else
                    return IntToFloat.new(only, operator[:starts_at])
                end
            else
                return only
            end
        end
    end

    def cell_ref
        if has(:hashtag)
            advance
            return parse_reference
        elsif has(RectangularFunc)
            advance
            f_start = @tokens[@i]
            f_name = f_start[:text]
            if has(:paren_start)
                advance
                top_left = parse_reference
                if has(:comma)
                    advance
                    bottom_right = parse_reference
                    if has(:paren_end)
                        advance
                        f_end = @tokens[@i]
                        if top_left.class == Error
                            return top_left
                        elsif bottom_right.class == Error
                            return bottom_right
                        else
                            if f_name == "sum"
                                return FuncSum.new(top_left.row, top_left.col,
                                    bottom_right.row, bottom_right.col,
                                    f_start[:starts_at], f_end[:ends_at])
                            elsif f_name == "min"
                                return FuncMin.new(top_left.row, top_left.col,
                                    bottom_right.row, bottom_right.col,
                                    f_start[:starts_at], f_end[:ends_at])
                            elsif f_name == "max"
                                return FuncMax.new(top_left.row, top_left.col,
                                    bottom_right.row, bottom_right.col,
                                    f_start[:starts_at], f_end[:ends_at])
                            elsif f_name == "mean"
                                return FuncMean.new(top_left.row, top_left.col,
                                    bottom_right.row, bottom_right.col,
                                    f_start[:starts_at], f_end[:ends_at])
                            elsif f_name == "in"
                                return ForLoop.new(top_left.row, top_left.col,
                                    bottom_right.row, bottom_right.col,
                                    f_start[:starts_at], f_end[:ends_at])
                            else
                                return error
                            end
                        end
                    else
                        return error
                    end
                else
                    return error
                end
            else
                return error
            end
        else
            return atom
        end
    end

    # Helper function designed to parse cell references
    def parse_reference
        if has(:cell_ref_start)
            advance
            if has_ahead(:comma) && has_ahead(:cell_ref_end)
                ref_start = @tokens[@i]
                row = atom
                if has(:comma) && row.class != Error
                    advance
                    if has_ahead(:cell_ref_end)
                        col = atom
                        if has(:cell_ref_end) && col.class != Error
                            advance
                            ref_end = @tokens[@i]
                            return CellReference.new(row, col, ref_start[:starts_at], ref_end[:ends_at])
                        else
                            return col
                        end
                    else
                        return error
                    end
                else
                    return row
                end
            else
                return error
            end
        else
            return error
        end
    end

    def atom
        target = (@tokens[@i + 1])
        if has(IntPrimitive)
            advance
            return IntPrimitive.new((target[:text]).to_i, target[:starts_at], target[:ends_at])
        elsif has(FloatPrimitive)
            advance
            return FloatPrimitive.new((target[:text]).to_f, target[:starts_at], target[:ends_at])
        elsif has(BoolPrimitive)
            advance
            if target[:text] == "T"
                return BoolPrimitive.new(true, target[:starts_at], target[:ends_at])
            elsif target[:text] == "F"
                return BoolPrimitive.new(false, target[:starts_at], target[:ends_at])
            end
        elsif has(Variable)
            advance
            if has(VariableAssignment)
                advance
                value = expression
                if value.class != Error
                    return VariableAssignment.new((target[:text]), value,
                        target[:starts_at], value.end_loc)
                else
                    return value
                end
            else
                return Variable.new((target[:text]), target[:starts_at], target[:ends_at])
            end
        elsif has(:paren_start)
            advance
            if has_ahead(:paren_end)
                inner = expression
                if has(:paren_end) && inner.class != Error
                    advance
                    inner.start_loc = target[:starts_at]
                    inner.end_loc = @tokens[@i][:ends_at]
                    return inner
                else
                    return inner
                end
            else
                return error
            end
        elsif has(:colon)
            parse_block(target[:starts_at])
        elsif has(:if)
            advance
            condition = expression
            if condition.class == Error
                return condition
            end
            if has(:colon)
                if_block = parse_block(@tokens[@i][:starts_at])
                if if_block.class == Error
                    return if_block
                end
                if has(:else)
                    advance
                    if has(:colon)
                        else_block = parse_block(@tokens[@i][:starts_at])
                        if else_block.class == Error
                            return else_block
                        end
                        if has(:end)
                            advance
                            return IfElse.new(condition, if_block, else_block,
                                target[:starts_at], @tokens[@i][:ends_at])
                        else
                            return error
                        end
                    else
                        return error
                    end
                else
                    return error
                end
            else
                return error
            end
        elsif has(:for)
            advance
            variable = atom
            if variable.class == Error
                return variable
            elsif variable.class != Variable
                return error
            end
            if has(RectangularFunc)
                basis = cell_ref
                if basis.class == Error
                    return basis
                elsif basis.class != ForLoop
                    return error
                end
                if has(:colon)
                    inner = parse_block(@tokens[@i][:starts_at])
                    if inner.class == Error
                        return inner
                    end
                    if has(:end)
                        advance
                        basis.start_loc = target[:starts_at]
                        basis.end_loc = @tokens[@i][:ends_at]
                        basis.variable = variable
                        basis.inner = inner
                        return basis
                    else
                        return error
                    end
                else
                    return error
                end
            else
                return error
            end
        else
            return error
        end
    end

    # Helper function designed to parse blocks
    def parse_block(start_of_block)
        advance
        statements = [expression]
        index = 0
        while has(:semicolon)
            advance
            if statements[index].class == Error
                return statements[index]
            end
            statements.push(expression)
            index += 1;
        end
        if has(:colon)
            advance
            if statements[index].class != Error
                return Block.new(statements, start_of_block,
                    @tokens[@i][:ends_at])
            else
                return statements[index]
            end
        else
            return error
        end
    end

    def error
        if @tokens[@i].nil?
            Error.new("error: empty expression")
        else
            Error.new("error: parse error at location #{@tokens[@i][:starts_at]}-#{@tokens[@i][:ends_at]}")
        end
    end
end