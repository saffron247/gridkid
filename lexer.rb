=begin
    GridKid Lexer Class
    Author: Ethan Baldwin
    Date: February 27, 2023
=end

require_relative 'error'

class Lexer
    def lex(source)
        @source = source
        @token_start = -1
        @i = 0
        @tokens = []
        @token_so_far = ''

        while @i < @source.length
            if has('|')
                capture
                if has('|')
                    capture
                    emit_token(LogicalOr)
                else
                    emit_token(BitwiseOr)
                end
            elsif has('&')
                capture
                if has('&')
                    capture
                    emit_token(LogicalAnd)
                else
                    emit_token(BitwiseAnd)
                end
            elsif has('=')
                capture
                if has('=')
                    capture
                    emit_token(Equals)
                else
                    emit_token(VariableAssignment)
                end
            elsif has('!')
                capture
                if has('=')
                    capture
                    emit_token(NotEquals)
                else
                    emit_token(LogicalNot)
                end
            elsif has('<')
                capture
                if has('=')
                    capture
                    emit_token(LessThanOrEqualTo)
                elsif has ('<')
                    capture
                    emit_token(BitwiseLeftShift)
                else
                    emit_token(LessThan)
                end
            elsif has('>')
                capture
                if has('=')
                    capture
                    emit_token(GreaterThanOrEqualTo)
                elsif has ('>')
                    capture
                    emit_token(BitwiseRightShift)
                else
                    emit_token(GreaterThan)
                end
            elsif has('^')
                capture
                emit_token(BitwiseXor)
            elsif has('+')
                capture
                emit_token(Add)
            elsif has('-')
                capture
                emit_token(Subtract)
            elsif has('*')
                capture
                if has('*')
                    capture
                    emit_token(Expo)
                else
                    emit_token(Multiply)
                end
            elsif has('/')
                capture
                emit_token(Divide)
            elsif has('%')
                capture
                emit_token(Modulo)
            elsif has('~')
                capture
                emit_token(BitwiseNot)
            elsif has('{')
                capture
                if has('i')
                    capture
                    if has('}')
                        capture
                        emit_token(FloatToInt)
                    else
                        @i -= 2;
                        return error
                    end
                elsif has('f')
                    capture
                    if has('}')
                        capture
                        emit_token(IntToFloat)
                    else
                        @i -= 2;
                        return error
                    end
                else
                    @i -= 1;
                    return error
                end
            elsif has('#')
                capture
                emit_token(:hashtag)
            elsif has('[')
                capture
                emit_token(:cell_ref_start)
            elsif has(',')
                capture
                emit_token(:comma)
            elsif has(']')
                capture
                emit_token(:cell_ref_end)
            elsif has('(')
                capture
                emit_token(:paren_start)
            elsif has(')')
                capture
                emit_token(:paren_end)
            elsif has(':')
                capture
                emit_token(:colon)
            elsif has(';')
                capture
                emit_token(:semicolon)             
            elsif has_let
                while has_let
                    capture
                end
                if @token_so_far == "T" || @token_so_far == "F"
                    emit_token(BoolPrimitive)
                elsif @token_so_far == "if"
                    emit_token(:if)
                elsif @token_so_far == "else"
                    emit_token(:else)
                elsif @token_so_far == "end"
                    emit_token(:end)
                elsif @token_so_far == "for"
                    emit_token(:for)
                elsif @token_so_far == "sum" || @token_so_far == "min" ||
                    @token_so_far == "max" || @token_so_far == "mean" ||
                    @token_so_far == "in"
                    emit_token(RectangularFunc)
                else
                    emit_token(Variable)
                end
            elsif has_num
                while has_num
                    capture
                end
                if has('.')
                    capture
                    if has_num
                        while has_num
                            capture
                        end
                        emit_token(FloatPrimitive)
                    else
                        @i -= 1;
                        return error
                    end
                else
                    emit_token(IntPrimitive)
                end
            elsif has(' ') || has('\n') || has('\t')
                skip
            else
                return error
            end
        end
        @tokens
    end

    def has(c)
        @i < @source.length && @source[@i] == c
    end

    def has_num
        @i < @source.length &&
        '0' <= @source[@i] && @source[@i] <= '9'
    end

    def has_let
        @i < @source.length &&
        (('A' <= @source[@i] && @source[@i] <= 'Z') ||
        ('a' <= @source[@i] && @source[@i] <= 'z'))
    end
    
    def capture
        if @token_start == -1
            @token_start = @i
        end
        @token_so_far += @source[@i]
        @i += 1
    end

    def skip
        @i += 1
        @token_so_far = ''
        @token_start = -1
    end

    def emit_token(type)
        @tokens.push({
            type: type,
            text: @token_so_far,
            starts_at: @token_start,
            ends_at: @i - 1
        })
        @token_so_far = ''
        @token_start = -1
    end

    def error
        Error.new("error: unexpected token at location #{@i}")
    end
end