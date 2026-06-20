# ============================================================
#  KidLang Sample Program 09
# Topic: Fibonacci Series - Loops and Math
# ============================================================

SHOW "====== Fibonacci Series ======"
SHOW ""
SHOW "The Fibonacci series starts with 0 and 1."
SHOW "Each next number = previous two numbers added together."
SHOW "Example: 0, 1, 1, 2, 3, 5, 8, 13, 21 ..."
SHOW ""

# ---- Generate Fibonacci using loop ----
SHOW "--- First 15 Fibonacci Numbers ---"

SET prev = 0
SET curr = 1
SET next = 0
SET count = 15

SHOW prev
SHOW curr

FOR i = 3 TO count DO
    SET next = prev + curr
    SHOW next
    SET prev = curr
    SET curr = next
END

SHOW ""

# ---- Fibonacci using function (recursive style using loop) ----
FUNC fibonacciNth(n)
    IF n == 1 THEN
        RETURN 0
    END
    IF n == 2 THEN
        RETURN 1
    END
    
    SET a = 0
    SET b = 1
    SET result = 0
    
    FOR i = 3 TO n DO
        SET result = a + b
        SET a = b
        SET b = result
    END
    
    RETURN result
ENDFUNC

SHOW "--- Specific Fibonacci numbers ---"
SET f5  = CALL fibonacciNth(5)
SET f10 = CALL fibonacciNth(10)
SET f15 = CALL fibonacciNth(15)
SET f20 = CALL fibonacciNth(20)

SHOW "5th Fibonacci number:"
SHOW f5

SHOW "10th Fibonacci number:"
SHOW f10

SHOW "15th Fibonacci number:"
SHOW f15

SHOW "20th Fibonacci number:"
SHOW f20

SHOW ""

# ---- Show which Fibonacci numbers are even ----
SHOW "--- Even Fibonacci numbers in first 20 ---"

SET a = 0
SET b = 1
SET count = 20

FOR i = 1 TO count DO
    IF a % 2 == 0 THEN
        SHOW a
    END
    SET temp = a + b
    SET a = b
    SET b = temp
END

SHOW ""
SHOW "Fibonacci program complete!"
