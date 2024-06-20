=begin
    GridKid Test Runner (Milestone 1)
    Author: Ethan Baldwin
    Date: February 13, 2023
=end

require_relative 'expressions'
require_relative 'grid'
require_relative 'lexer'
require_relative 'parser'
require_relative 'error'

grid = Grid.new
$env = Environment.new(grid)

# Test that two expressions are equal
def test_equal_xprs(test_id, actual, expected)
    actual_val = actual.evaluate($env).val
    expected_val = expected.evaluate($env).val
    if actual_val != expected_val
        STDERR.puts "FAIL at Test #{test_id}: expected #{expected_val}, was #{actual_val}"
    end
end

# Test that an invalid expression provides the correct error message
def test_invalid_xpr(test_id, xpr, error)
    if xpr.evaluate($env) != error
        STDERR.puts "FAIL at Test #{test_id}: expected \"#{error}\", was \"#{xpr.evaluate($env)}\""
    end
end

# Test that the lexer's output is correct
def test_lexer(test_id, actual, expected)
    if actual != expected
        STDERR.puts "FAIL at Test #{test_id}: expected \"#{expected}\", was \"#{actual}\""
    end
end

# Test
def test_locations(test_id, actual, expected_start, expected_end)
    actual_start = actual.evaluate($env).start_loc
    actual_end = actual.evaluate($env).end_loc
    if (actual_start != expected_start) || (actual_end != expected_end)
        STDERR.puts "FAIL at Test #{test_id}: expected #{expected_start}, #{expected_end}, was #{actual_start}, #{actual_end}"
    end
end

=begin Milestone 1 Tests
    # test arithmetic operations
    a = IntPrimitive.new(3)
    b = IntPrimitive.new(5)
    c = FloatPrimitive.new(2.5)
    d = FloatPrimitive.new(1.5)
    test_equal_xprs(0.1, Add.new(a, b), IntPrimitive.new(8)) # 3 + 5
    test_equal_xprs(0.2, Subtract.new(d, c), FloatPrimitive.new(-1)) # 2.5 / 1.5
    test_equal_xprs(0.3, Multiply.new(a, b), IntPrimitive.new(15)) # 3 * 5
    test_equal_xprs(0.4, Divide.new(b, a), IntPrimitive.new(1)) # 5 / 3
    test_equal_xprs(0.5, Divide.new(d, c), FloatPrimitive.new(0.6)) # 1.5 / 2.5
    test_equal_xprs(0.6, Modulo.new(c, d), FloatPrimitive.new(1)) # 2.5 % 1.5
    test_equal_xprs(0.7, Expo.new(b, a), IntPrimitive.new(125)) # 3 ** 5
    test_invalid_xpr(0.8, Add.new(a, c), "arithmetic type mismatch error")
    test_invalid_xpr(0.9, Subtract.new(d, b), "arithmetic type mismatch error")

    # test logical operations
    t = BoolPrimitive.new(true)
    f = BoolPrimitive.new(false)
    test_equal_xprs(1.1, LogicalAnd.new(t, f), BoolPrimitive.new(false))
    test_equal_xprs(1.2, LogicalOr.new(t, f), BoolPrimitive.new(true))
    test_equal_xprs(1.3, LogicalNot.new(t), BoolPrimitive.new(false))
    test_invalid_xpr(1.4, LogicalAnd.new(a, b), "logical operation type error")
    test_invalid_xpr(1.5, LogicalNot.new(d), "logical operation type error")

    # test chained operations
    test_equal_xprs(2.1, Add.new(Multiply.new(b, a), a), IntPrimitive.new(18)) # (5 * 3) + 3
    test_equal_xprs(2.2, Divide.new(c, Subtract.new(c, Modulo.new(d, c))), 
    FloatPrimitive.new(2.5)) # 2.5 / (2.5 - (1.5 % 2.5))

    # test cell references
    grid.set(1, 3, a)
    test_equal_xprs(3.1, CellReference.new(1, 3), IntPrimitive.new(3))
    test_invalid_xpr(3.2, CellReference.new(1, 4), "empty cell reference")

    # test bitwise operations
    g = IntPrimitive.new(0b0110)
    h = IntPrimitive.new(0b0111)
    i = IntPrimitive.new(2)
    test_equal_xprs(4.1, BitwiseAnd.new(g, h), IntPrimitive.new(0b0110))
    test_equal_xprs(4.2, BitwiseOr.new(g, h), IntPrimitive.new(0b0111))
    test_equal_xprs(4.3, BitwiseXor.new(g, h), IntPrimitive.new(0b0001))
    test_equal_xprs(4.4, BitwiseNot.new(g), IntPrimitive.new(-7)) # bitwise inversion of b0110 (11...111001)
    test_equal_xprs(4.5, BitwiseLeftShift.new(g, i), IntPrimitive.new(0b11000))
    test_equal_xprs(4.6, BitwiseRightShift.new(h, i), IntPrimitive.new(0b0001))
    test_invalid_xpr(4.7, BitwiseOr.new(c, d), "bitwise operation type error")
    test_invalid_xpr(4.8, BitwiseNot.new(f), "bitwise operation type error")

    # test relational operations
    test_equal_xprs(5.1, Equals.new(g, h), BoolPrimitive.new(false))
    test_equal_xprs(5.2, NotEquals.new(c, d), BoolPrimitive.new(true))
    test_equal_xprs(5.3, NotEquals.new(t, f), BoolPrimitive.new(true))
    test_equal_xprs(5.4, LessThan.new(a, b), BoolPrimitive.new(true))
    test_equal_xprs(5.5, LessThanOrEqualTo.new(d, c), BoolPrimitive.new(true))
    test_equal_xprs(5.6, GreaterThan.new(b, a), BoolPrimitive.new(true))
    test_equal_xprs(5.7, GreaterThanOrEqualTo.new(c, d), BoolPrimitive.new(true))
    test_invalid_xpr(5.8, Equals.new(a, d), "relational operation type error")
    test_invalid_xpr(5.9, GreaterThan.new(f, g), "relational operation type error")
    test_invalid_xpr(5.10, LessThanOrEqualTo.new(t, f), "relational operation type error")

    # test casting operations
    test_equal_xprs(6.1, FloatToInt.new(d), IntPrimitive.new(1))
    test_equal_xprs(6.2, IntToFloat.new(a), FloatPrimitive.new(3))
    test_invalid_xpr(6.3, FloatToInt.new(b), "float-to-int casting type error")
    test_invalid_xpr(6.4, IntToFloat.new(c), "int-to-float casting type error")

    # comprehensive grid testing
    grid.set(1, 3, c)
    test_equal_xprs(7.1, CellReference.new(1, 3), FloatPrimitive.new(2.5))
    grid.set(2, 2, Expo.new(b, a))
    test_equal_xprs(7.2, CellReference.new(2, 2), IntPrimitive.new(125))
    grid.set(1, 1, LogicalOr.new(f, f))
    test_equal_xprs(7.3, CellReference.new(1, 1), BoolPrimitive.new(false))
    grid.set(1, 2, FloatToInt.new(CellReference.new(1, 3)))
    test_equal_xprs(7.4, CellReference.new(1, 2), IntPrimitive.new(2))
    grid.set(4, 4, Divide.new(c, Subtract.new(c, Modulo.new(d, c))))
    test_equal_xprs(7.5, CellReference.new(4, 4), FloatPrimitive.new(2.5))

# test lexer
lexer = Lexer.new
test_lexer(10.1, lexer.lex("|"), [{:type=>BitwiseOr, :text=>"|", :starts_at=>0, :ends_at=>0}])
test_lexer(10.2, lexer.lex("||"), [{:type=>LogicalOr, :text=>"||", :starts_at=>0, :ends_at=>1}])
test_lexer(10.3, lexer.lex("| |"), [{:type=>BitwiseOr, :text=>"|", :starts_at=>0, :ends_at=>0},
                                    {:type=>BitwiseOr, :text=>"|", :starts_at=>2, :ends_at=>2}])
test_lexer(10.4, lexer.lex("&"), [{:type=>BitwiseAnd, :text=>"&", :starts_at=>0, :ends_at=>0}])
test_lexer(10.5, lexer.lex("&&"), [{:type=>LogicalAnd, :text=>"&&", :starts_at=>0, :ends_at=>1}])
test_lexer(10.6, lexer.lex("q | &").evaluate($env), "error: unexpected token at location 0")
test_lexer(10.7, lexer.lex("=").evaluate($env), "error: unexpected token at location 0")
test_lexer(10.8, lexer.lex("=="), [{:type=>Equals, :text=>"==", :starts_at=>0, :ends_at=>1}])
test_lexer(10.9, lexer.lex("!="), [{:type=>NotEquals, :text=>"!=", :starts_at=>0, :ends_at=>1}])
test_lexer(10.10, lexer.lex("!"), [{:type=>LogicalNot, :text=>"!", :starts_at=>0, :ends_at=>0}])
test_lexer(10.11, lexer.lex("<"), [{:type=>LessThan, :text=>"<", :starts_at=>0, :ends_at=>0}])
test_lexer(10.12, lexer.lex("<="), [{:type=>LessThanOrEqualTo, :text=>"<=", :starts_at=>0, :ends_at=>1}])
test_lexer(10.13, lexer.lex(">"), [{:type=>GreaterThan, :text=>">", :starts_at=>0, :ends_at=>0}])
test_lexer(10.14, lexer.lex(">="), [{:type=>GreaterThanOrEqualTo, :text=>">=", :starts_at=>0, :ends_at=>1}])
test_lexer(10.15, lexer.lex("^"), [{:type=>BitwiseXor, :text=>"^", :starts_at=>0, :ends_at=>0}])
test_lexer(10.16, lexer.lex("<<"), [{:type=>BitwiseLeftShift, :text=>"<<", :starts_at=>0, :ends_at=>1}])
test_lexer(10.17, lexer.lex(">>"), [{:type=>BitwiseRightShift, :text=>">>", :starts_at=>0, :ends_at=>1}])
test_lexer(10.18, lexer.lex("+"), [{:type=>Add, :text=>"+", :starts_at=>0, :ends_at=>0}])
test_lexer(10.19, lexer.lex("-"), [{:type=>Subtract, :text=>"-", :starts_at=>0, :ends_at=>0}])
test_lexer(10.20, lexer.lex("*"), [{:type=>Multiply, :text=>"*", :starts_at=>0, :ends_at=>0}])
test_lexer(10.21, lexer.lex("/"), [{:type=>Divide, :text=>"/", :starts_at=>0, :ends_at=>0}])
test_lexer(10.22, lexer.lex("%"), [{:type=>Modulo, :text=>"%", :starts_at=>0, :ends_at=>0}])
test_lexer(10.23, lexer.lex("**"), [{:type=>Expo, :text=>"**", :starts_at=>0, :ends_at=>1}])
test_lexer(10.24, lexer.lex("~"), [{:type=>BitwiseNot, :text=>"~", :starts_at=>0, :ends_at=>0}])
test_lexer(10.25, lexer.lex("{i}"), [{:type=>FloatToInt, :text=>"{i}", :starts_at=>0, :ends_at=>2}])
test_lexer(10.26, lexer.lex("{f}"), [{:type=>IntToFloat, :text=>"{f}", :starts_at=>0, :ends_at=>2}])
test_lexer(10.27, lexer.lex("#[ , ]"), [{:type=>:cell_ref_start, :text=>"#[", :starts_at=>0, :ends_at=>1},
                                        {:type=>:comma, :text=>",", :starts_at=>3, :ends_at=>3},
                                        {:type=>:cell_ref_end, :text=>"]", :starts_at=>5, :ends_at=>5}])
test_lexer(10.28, lexer.lex("( )"), [{:type=>:paren_start, :text=>"(", :starts_at=>0, :ends_at=>0},
                                     {:type=>:paren_end, :text=>")", :starts_at=>2, :ends_at=>2}])
test_lexer(10.29, lexer.lex("T"), [{:type=>BoolPrimitive, :text=>"T", :starts_at=>0, :ends_at=>0}])
test_lexer(10.30, lexer.lex("F"), [{:type=>BoolPrimitive, :text=>"F", :starts_at=>0, :ends_at=>0}])
test_lexer(10.31, lexer.lex("6938"), [{:type=>IntPrimitive, :text=>"6938", :starts_at=>0, :ends_at=>3}])
test_lexer(10.32, lexer.lex("63.8932"), [{:type=>FloatPrimitive, :text=>"63.8932", :starts_at=>0, :ends_at=>6}])
test_lexer(10.33, lexer.lex("78.").evaluate($env), "error: unexpected token at location 2")

# test parser
lexer = Lexer.new
parser = Parser.new
test_equal_xprs(11.1, parser.parse(lexer.lex("6938")), IntPrimitive.new(6938, 0, 0))
test_equal_xprs(11.2, parser.parse(lexer.lex("63.8932")), FloatPrimitive.new(63.8932, 0, 0))
test_equal_xprs(11.3, parser.parse(lexer.lex("T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.4, parser.parse(lexer.lex("F")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.5, parser.parse(lexer.lex("F || F")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.6, parser.parse(lexer.lex("F || T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.7, parser.parse(lexer.lex("F || F || T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.8, parser.parse(lexer.lex("F || T || T || F")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.9, parser.parse(lexer.lex("T && F")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.10, parser.parse(lexer.lex("T && T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.11, parser.parse(lexer.lex("T && F || F || T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.12, parser.parse(lexer.lex("T == T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.13, parser.parse(lexer.lex("T != T")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.14, parser.parse(lexer.lex("T == F || F != T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.15, parser.parse(lexer.lex("10 > 8")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.16, parser.parse(lexer.lex("10.3 < 8.7")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.17, parser.parse(lexer.lex("8.9 >= 10.3")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.18, parser.parse(lexer.lex("8 <= 10")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.19, parser.parse(lexer.lex("10 == 9")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.20, parser.parse(lexer.lex("10 != 9")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.21, parser.parse(lexer.lex("10 | 9")), IntPrimitive.new(11, 0, 0))
test_equal_xprs(11.22, parser.parse(lexer.lex("10 ^ 9")), IntPrimitive.new(3, 0, 0))
test_equal_xprs(11.23, parser.parse(lexer.lex("10 & 9")), IntPrimitive.new(8, 0, 0))
test_equal_xprs(11.24, parser.parse(lexer.lex("3 ^ 9 & 10")), IntPrimitive.new(11, 0, 0))
test_equal_xprs(11.25, parser.parse(lexer.lex("32 >> 4")), IntPrimitive.new(2, 0, 0))
test_equal_xprs(11.26, parser.parse(lexer.lex("2 << 4")), IntPrimitive.new(32, 0, 0))
test_equal_xprs(11.27, parser.parse(lexer.lex("10 + 4")), IntPrimitive.new(14, 0, 0))
test_equal_xprs(11.28, parser.parse(lexer.lex("10 - 4")), IntPrimitive.new(6, 0, 0))
test_equal_xprs(11.29, parser.parse(lexer.lex("10 * 4")), IntPrimitive.new(40, 0, 0))
test_equal_xprs(11.30, parser.parse(lexer.lex("10 / 4")), IntPrimitive.new(2, 0, 0))
test_equal_xprs(11.31, parser.parse(lexer.lex("10.5 / 3.5")), FloatPrimitive.new(3, 0, 0))
test_equal_xprs(11.32, parser.parse(lexer.lex("10 % 4")), IntPrimitive.new(2, 0, 0))
test_equal_xprs(11.33, parser.parse(lexer.lex("1 + 3 * 4 - 5 / 2")), IntPrimitive.new(11, 0, 0))
test_equal_xprs(11.34, parser.parse(lexer.lex("10 ** 4")), IntPrimitive.new(10000, 0, 0))
test_equal_xprs(11.35, parser.parse(lexer.lex("2 ** 3 ** 2")), IntPrimitive.new(512, 0, 0))
test_equal_xprs(11.36, parser.parse(lexer.lex("!T")), BoolPrimitive.new(false, 0, 0))
test_equal_xprs(11.37, parser.parse(lexer.lex("!!T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.38, parser.parse(lexer.lex("!!!!T")), BoolPrimitive.new(true, 0, 0))
test_equal_xprs(11.39, parser.parse(lexer.lex("~10")), IntPrimitive.new(-11, 0, 0))
test_equal_xprs(11.40, parser.parse(lexer.lex("~~10")), IntPrimitive.new(10, 0, 0))
test_equal_xprs(11.41, parser.parse(lexer.lex("{i}4.5")), IntPrimitive.new(4, 0, 0))
test_equal_xprs(11.42, parser.parse(lexer.lex("{f}4")), FloatPrimitive.new(4, 0, 0))
test_equal_xprs(11.43, parser.parse(lexer.lex("{i}{f}4")), IntPrimitive.new(4, 0, 0))
test_equal_xprs(11.44, parser.parse(lexer.lex("(4)")), IntPrimitive.new(4, 0, 0))
test_equal_xprs(11.45, parser.parse(lexer.lex("3 + (4)")), IntPrimitive.new(7, 0, 0))
test_equal_xprs(11.46, parser.parse(lexer.lex("(3) + 4")), IntPrimitive.new(7, 0, 0))
test_equal_xprs(11.47, parser.parse(lexer.lex("(4 + 7) * 3")), IntPrimitive.new(33, 0, 0))
test_equal_xprs(11.48, parser.parse(lexer.lex("9 + ((4 + 7) * 3 / 11)")), IntPrimitive.new(12, 0, 0))

# test parser with cell references
grid.set(2, 2, Expo.new(IntPrimitive.new(5, 0, 2), IntPrimitive.new(2, 3, 5)))
test_equal_xprs(12.1, parser.parse(lexer.lex("#[2, 2]")), IntPrimitive.new(25, 0, 0))
test_equal_xprs(12.2, parser.parse(lexer.lex("#[(3 - 1), 2]")), IntPrimitive.new(25, 0, 0))

# test locations
test_locations(13.1, parser.parse(lexer.lex("T == F || F != T")), 0, 15)
test_locations(13.2, parser.parse(lexer.lex("1 + 3 * 4 - 5 / 2")), 0, 16)
test_locations(13.3, parser.parse(lexer.lex(" T")), 1, 1)
test_locations(13.4, parser.parse(lexer.lex("!T")), 0, 1)
test_locations(13.5, parser.parse(lexer.lex("!T == F")), 0, 6)
test_locations(13.6, parser.parse(lexer.lex("9 + ((4 + 7) * 3 / 11)")), 0, 21)
test_locations(13.7, parser.parse(lexer.lex("#[2, 2]")), 0, 5)
test_locations(13.8, parser.parse(lexer.lex("#[(3 - 1), 2]")), 0, 5)

# test errors
test_invalid_xpr(14.1, parser.parse(lexer.lex("1+a")), "error: unexpected token at location 2")
test_invalid_xpr(14.2, parser.parse(lexer.lex("1+ak")), "error: unexpected token at location 2")
test_invalid_xpr(14.3, parser.parse(lexer.lex(". .3 82u1.23")), "error: unexpected token at location 0")
test_invalid_xpr(14.4, parser.parse(lexer.lex("( ( )")), "error: parse error at location 2-2")
test_invalid_xpr(14.5, parser.parse(lexer.lex("+ 9")), "error: parse error at location 2-2")
test_invalid_xpr(14.6, parser.parse(lexer.lex("F ||  || T")), "error: parse error at location 2-3")
test_invalid_xpr(14.7, parser.parse(lexer.lex(",9 8]")), "error: parse error at location 4-4")
test_invalid_xpr(14.8, parser.parse(lexer.lex(", 38.38")), "error: parse error at location 2-6")
test_invalid_xpr(14.9, parser.parse(lexer.lex("{f}90.4 ** (21 ^)")), "error: parse error at location 15-15")
test_invalid_xpr(14.10, parser.parse(lexer.lex("4 + 5.8")), "error: arithmetic type mismatch at 0-6")
test_invalid_xpr(14.11, parser.parse(lexer.lex("T && 9")), "error: logical type mismatch at 0-5")
test_invalid_xpr(14.12, parser.parse(lexer.lex("(8 ^ 9.3) + 2")), "error: bitwise type mismatch at 0-8")
test_invalid_xpr(14.13, parser.parse(lexer.lex("F || (8 == T)")), "error: relational type mismatch at 5-12")
test_invalid_xpr(14.14, parser.parse(lexer.lex("{i}56")), "error: casting type mismatch at 0-4")
test_invalid_xpr(14.15, parser.parse(lexer.lex("{f}8.4")), "error: casting type mismatch at 0-5")
test_invalid_xpr(14.16, parser.parse(lexer.lex("#[6.5, 7]")), "error: invalid cell reference")
test_invalid_xpr(14.17, parser.parse(lexer.lex("#[6, 7]")), "error: empty cell reference")
=end

=begin
VariableAssignment.new("a", IntPrimitive.new(4, 0, 0), 0, 0).evaluate($env).val
puts Variable.new("a", 0, 0).evaluate($env).val
$env.reset_vars
puts Variable.new("a", 0, 0).evaluate($env)
=end

lexer = Lexer.new
parser = Parser.new
=begin
puts parser.parse(lexer.lex("a = 45 + 56 - 483")).evaluate($env).val
puts parser.parse(lexer.lex("a")).evaluate($env).val
$env.reset_vars

puts parser.parse(lexer.lex("a = 3 + 1")).evaluate($env).val
puts parser.parse(lexer.lex("b = 5")).evaluate($env).val
puts parser.parse(lexer.lex("a * b")).evaluate($env).val
$env.reset_vars

puts parser.parse(lexer.lex(":a = 3 + 1; b = 5; a * b:")).evaluate($env).val

puts parser.parse(lexer.lex("if T || F then :1: else :0: end")).evaluate($env).val

grid.set(4, 0, FloatPrimitive.new(4.5, 0, 0))
grid.set(4, 1, FloatPrimitive.new(3.0, 0, 0))
grid.set(4, 2, FloatPrimitive.new(2.0, 0, 0))
grid.set(4, 3, FloatPrimitive.new(1.5, 0, 0))
puts parser.parse(lexer.lex(":count = 0; for value in ([4,0],[4,3]):if value > 2.5 then:count = count + 1: else:count: end: end; count:")).evaluate($env).val
puts parser.parse(lexer.lex(":count = 0; value = 2.0; if value > 2.5 then:count = count + 1: else:count: end; count:")).evaluate($env).val
puts parser.parse(lexer.lex("value = 2.0")).evaluate($env).val
puts parser.parse(lexer.lex("value > 2.5")).evaluate($env).val
puts parser.parse(lexer.lex(":value = 2.0; if value > 2.5 then:1: else:0: end:")).evaluate($env).val
=end