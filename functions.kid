# ============================================================
#  KidLang Sample Program 06
# Topic: User-Defined Functions, Parameters, Return Values
# ============================================================

SHOW "====== Learning Functions ======"
SHOW ""

# ---- Simple Function (no parameters) ----
FUNC greet()
    SHOW "Hello! Welcome to KidLang!"
    SHOW "Functions help us reuse code."
ENDFUNC

# ---- Function with parameters ----
FUNC sayHello(personName)
    SHOWL "Hello, "
    SHOWL personName
    SHOW "!"
ENDFUNC

# ---- Function that adds two numbers ----
FUNC addNumbers(x, y)
    SET total = x + y
    RETURN total
ENDFUNC

# ---- Function: Calculate area of rectangle ----
FUNC rectangleArea(length, width)
    SET area = length * width
    RETURN area
ENDFUNC

# ---- Function: Check even or odd ----
FUNC isEven(number)
    IF number % 2 == 0 THEN
        RETURN TRUE
    ELSE
        RETURN FALSE
    END
ENDFUNC

# ---- Function: Factorial ----
FUNC factorial(n)
    SET result = 1
    FOR i = 1 TO n DO
        SET result = result * i
    END
    RETURN result
ENDFUNC

# ---- Function: Find maximum ----
FUNC maximum(a, b)
    IF a > b THEN
        RETURN a
    ELSE
        RETURN b
    END
ENDFUNC

# ---- Function: Print a line separator ----
FUNC printLine()
    SHOW "-------------------------------"
ENDFUNC


# ======================================================
# MAIN PROGRAM - Call our functions
# ======================================================

SHOW "--- Calling greet() ---"
CALL greet()
CALL printLine()

SHOW ""
SHOW "--- Calling sayHello() ---"
CALL sayHello("Ali")
CALL sayHello("Sara")
CALL sayHello("Ahmed")
CALL printLine()

SHOW ""
SHOW "--- Calling addNumbers() ---"
SET answer = CALL addNumbers(10, 25)
SHOWL "10 + 25 = "
SHOW answer

SET answer = CALL addNumbers(100, 250)
SHOWL "100 + 250 = "
SHOW answer
CALL printLine()

SHOW ""
SHOW "--- Calling rectangleArea() ---"
SET area = CALL rectangleArea(8, 5)
SHOWL "Rectangle 8 x 5, Area = "
SHOW area

SET area = CALL rectangleArea(12, 7)
SHOWL "Rectangle 12 x 7, Area = "
SHOW area
CALL printLine()

SHOW ""
SHOW "--- Calling isEven() ---"
SET num = 14
SET result = CALL isEven(num)
IF result == TRUE THEN
    SHOW "14 is EVEN"
ELSE
    SHOW "14 is ODD"
END

SET num = 7
SET result = CALL isEven(num)
IF result == TRUE THEN
    SHOW "7 is EVEN"
ELSE
    SHOW "7 is ODD"
END
CALL printLine()

SHOW ""
SHOW "--- Calling factorial() ---"
FOR n = 1 TO 8 DO
    SET fact = CALL factorial(n)
    SHOWL "Factorial of "
    SHOWL n
    SHOWL " = "
    SHOW fact
END
CALL printLine()

SHOW ""
SHOW "--- Calling maximum() ---"
SET m = CALL maximum(42, 87)
SHOWL "Maximum of 42 and 87 is: "
SHOW m

SET m = CALL maximum(100, 55)
SHOWL "Maximum of 100 and 55 is: "
SHOW m
CALL printLine()

SHOW ""
SHOW "Functions program complete!"
