# ============================================================
#  KidLang Sample Program 03
# Topic: Arithmetic Operators and Expressions
# For: 8th-10th Class Students
# ============================================================

SHOW "====== KidLang Calculator ======"
SHOW ""

SET a = 20
SET b = 6

SHOW "We have two numbers:"
SHOW "a ="
SHOW a
SHOW "b ="
SHOW b
SHOW ""

# Addition
SET result = a + b
SHOW "Addition (a + b):"
SHOW result

# Subtraction
SET result = a - b
SHOW "Subtraction (a - b):"
SHOW result

# Multiplication
SET result = a * b
SHOW "Multiplication (a * b):"
SHOW result

# Division
SET result = a / b
SHOW "Division (a / b):"
SHOW result

# Modulo (Remainder)
SET result = a % b
SHOW "Modulo / Remainder (a % b):"
SHOW result

SHOW ""
SHOW "====== Complex Expressions ======"
SHOW ""

# Operator precedence: * and / before + and -
SET expr1 = 2 + 3 * 4
SHOW "2 + 3 * 4 = (multiply first, then add)"
SHOW expr1

# Parentheses change precedence
SET expr2 = (2 + 3) * 4
SHOW "(2 + 3) * 4 = (add first, then multiply)"
SHOW expr2

# Multi-step expression
SET x = 10
SET y = 3
SET z = x * y + (x - y) * 2
SHOW "10 * 3 + (10 - 3) * 2 ="
SHOW z

SHOW ""
SHOW "====== Increment and Decrement ======"
SHOW ""

SET counter = 5
SHOW "Starting counter:"
SHOW counter

counter++
SHOW "After counter++ :"
SHOW counter

counter++
SHOW "After counter++ again:"
SHOW counter

counter--
SHOW "After counter-- :"
SHOW counter

SHOW ""
SHOW "====== Assignment Operators ======"
SHOW ""

SET num = 100
SHOW "num starts at 100"

num += 25
SHOW "After num += 25 :"
SHOW num

num -= 10
SHOW "After num -= 10 :"
SHOW num

num *= 2
SHOW "After num *= 2 :"
SHOW num

num /= 5
SHOW "After num /= 5 :"
SHOW num

SHOW ""
SHOW "Calculator program complete!"
