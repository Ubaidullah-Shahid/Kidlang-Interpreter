# ============================================================
# KidLang Master Demo Program
# Topic: All KidLang Features in One Program
# ============================================================

SHOW "============================================"
SHOW "   KIDLANG COMPLETE FEATURE DEMONSTRATION"
SHOW "   All features in one program!"
SHOW "============================================"
SHOW ""

# ============================================================
# SECTION 1: DATA TYPES
# ============================================================
SHOW "=== SECTION 1: DATA TYPES ==="
SHOW ""

SET myInt    = 42
SET myFloat  = 3.14
SET myString = "Hello KidLang"
SET myChar   = 'K'
SET myBool   = TRUE
CONST VERSION = "1.0"

SHOW "Integer:"
SHOW myInt
SHOW "Float:"
SHOW myFloat
SHOW "String:"
SHOW myString
SHOW "Character:"
SHOW myChar
SHOW "Boolean:"
SHOW myBool
SHOW "Constant:"
SHOW VERSION
SHOW ""

# ============================================================
# SECTION 2: ARITHMETIC
# ============================================================
SHOW "=== SECTION 2: ARITHMETIC OPERATORS ==="
SHOW ""

SET a = 15
SET b = 4

SHOW "a = 15, b = 4"
SHOW "a + b ="
SHOW a + b
SHOW "a - b ="
SHOW a - b
SHOW "a * b ="
SHOW a * b
SHOW "a / b ="
SHOW a / b
SHOW "a % b ="
SHOW a % b
SHOW ""

# ============================================================
# SECTION 3: RELATIONAL & LOGICAL
# ============================================================
SHOW "=== SECTION 3: RELATIONAL & LOGICAL ==="
SHOW ""

SET x = 10
SET y = 20

IF x < y THEN
    SHOW "x is less than y - TRUE"
END

IF x != y THEN
    SHOW "x is not equal to y - TRUE"
END

IF x > 5 AND y > 5 THEN
    SHOW "Both x and y are greater than 5 - TRUE"
END

IF x > 50 OR y > 50 THEN
    SHOW "At least one is > 50"
ELSE
    SHOW "Neither x nor y is > 50"
END

SHOW ""

# ============================================================
# SECTION 4: CONDITIONAL STRUCTURES
# ============================================================
SHOW "=== SECTION 4: CONDITIONAL STRUCTURES ==="
SHOW ""

SET temperature = 28

SHOW "Temperature:"
SHOW temperature

IF temperature > 35 THEN
    SHOW "Very Hot - Stay hydrated!"
ELIF temperature > 28 THEN
    SHOW "Hot - Wear light clothes."
ELIF temperature > 20 THEN
    SHOW "Warm - Nice weather!"
ELIF temperature > 10 THEN
    SHOW "Cool - Wear a jacket."
ELSE
    SHOW "Cold - Wear a warm coat!"
END

SHOW ""

SET day = 5
SWITCH day
    CASE 1: SHOW "Monday"
    CASE 2: SHOW "Tuesday"
    CASE 3: SHOW "Wednesday"
    CASE 4: SHOW "Thursday"
    CASE 5: SHOW "Friday - Weekend starts!"
    CASE 6: SHOW "Saturday"
    CASE 7: SHOW "Sunday"
    DEFAULT: SHOW "Invalid"
ENDSWITCH

SHOW ""

# ============================================================
# SECTION 5: LOOPS
# ============================================================
SHOW "=== SECTION 5: LOOPS ==="
SHOW ""

SHOW "FOR loop (1 to 5):"
FOR i = 1 TO 5 DO
    SHOW i
END

SHOW ""
SHOW "WHILE loop (count down from 5):"
SET c = 5
WHILE c > 0 DO
    SHOW c
    c--
END

SHOW ""
SHOW "DO WHILE loop:"
SET n = 1
DO
    SHOW n
    n++
WHILE n <= 3

SHOW ""
SHOW "FOR with CONTINUE (skip 3):"
FOR i = 1 TO 6 DO
    IF i == 3 THEN
        CONTINUE
    END
    SHOW i
END

SHOW ""
SHOW "FOR with BREAK (stop at 4):"
FOR i = 1 TO 10 DO
    IF i == 5 THEN
        BREAK
    END
    SHOW i
END

SHOW ""

# ============================================================
# SECTION 6: FUNCTIONS
# ============================================================
SHOW "=== SECTION 6: FUNCTIONS ==="
SHOW ""

FUNC square(num)
    SET result = num * num
    RETURN result
ENDFUNC

FUNC cube(num)
    RETURN num * num * num
ENDFUNC

FUNC greetStudent(name, score)
    SHOW "Hello"
    SHOW name
    IF score >= 80 THEN
        SHOW "You have an excellent score of"
        SHOW score
    ELIF score >= 60 THEN
        SHOW "You have a good score of"
        SHOW score
    ELSE
        SHOW "Keep working hard! Score:"
        SHOW score
    END
ENDFUNC

FUNC sumTo(limit)
    SET total = 0
    FOR i = 1 TO limit DO
        SET total = total + i
    END
    RETURN total
ENDFUNC

SET sq = CALL square(9)
SHOW "Square of 9:"
SHOW sq

SET cu = CALL cube(4)
SHOW "Cube of 4:"
SHOW cu

CALL greetStudent("Ahmed", 88)
CALL greetStudent("Bilal", 55)

SET s = CALL sumTo(10)
SHOW "Sum 1 to 10:"
SHOW s

SHOW ""

# ============================================================
# SECTION 7: INPUT / OUTPUT
# ============================================================
SHOW "=== SECTION 7: INPUT / OUTPUT ==="
SHOW ""

SHOW "Enter your name:"
ASK userName

SHOW "Enter your age:"
ASK userAge

SHOW ""
SHOW "Hello!"
SHOW userName

SHOW "You are"
SHOW userAge
SHOW "years old."

IF userAge >= 13 AND userAge <= 19 THEN
    SHOW "You are a teenager!"
ELIF userAge < 13 THEN
    SHOW "You are still a child. Keep learning!"
ELSE
    SHOW "You are an adult. Keep growing!"
END

SHOW ""

# ============================================================
# SECTION 8: DEBUG TOOLS
# ============================================================
SHOW "=== SECTION 8: DEBUG TOOLS ==="
SHOW ""

SET debugVar1 = 100
SET debugVar2 = "Test String"
SET debugVar3 = 3.14

SHOW "All current variables:"
SHOW_VARIABLES

SHOW ""
SHOW "============================================"
SHOW "   DEMO COMPLETE!"
SHOW "   You have seen all KidLang features!"
SHOW "============================================"
