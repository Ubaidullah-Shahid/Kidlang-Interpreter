# ============================================================
#  KidLang Sample Program 05
# Topic: FOR / WHILE / DO-WHILE / BREAK / CONTINUE
# ============================================================

SHOW "====== Learning Loops ======"
SHOW ""

# ---- FOR Loop ----
SHOW "--- FOR Loop: Count 1 to 5 ---"

FOR i = 1 TO 5 DO
    SHOW i
END

SHOW ""

# ---- FOR Loop with STEP ----
SHOW "--- FOR Loop: Even numbers 2 to 10 ---"

FOR i = 2 TO 10 STEP 2 DO
    SHOW i
END

SHOW ""

# ---- FOR Loop: Countdown ----
SHOW "--- FOR Loop: Countdown 5 to 1 ---"

FOR i = 5 TO 1 STEP -1 DO
    SHOW i
END
SHOW "Blast off!"

SHOW ""

# ---- FOR Loop: Multiplication Table ----
SHOW "--- Multiplication Table of 5 ---"

FOR i = 1 TO 10 DO
    SET result = 5 * i
    SHOW "5 x "
    SHOW i
    SHOW " = "
    SHOW result
END

SHOW ""

# ---- WHILE Loop ----
SHOW "--- WHILE Loop: Sum 1 to 10 ---"

SET sum = 0
SET i = 1

WHILE i <= 10 DO
    SET sum = sum + i
    i++
END

SHOW "Sum of 1 to 10 is:"
SHOW sum

SHOW ""

# ---- WHILE with BREAK ----
SHOW "--- WHILE with BREAK ---"

SET num = 1
WHILE num <= 100 DO
    IF num == 6 THEN
        SHOW "Found 6! Breaking out of loop."
        BREAK
    END
    SHOW num
    num++
END

SHOW ""

# ---- WHILE with CONTINUE ----
SHOW "--- WHILE: Skip odd numbers ---"

SET i = 0
WHILE i < 10 DO
    i++
    IF i % 2 != 0 THEN
        CONTINUE
    END
    SHOW i
END

SHOW ""

# ---- DO WHILE Loop ----
SHOW "--- DO WHILE Loop ---"
SHOW "This loop always runs at least once."

SET x = 10
DO
    SHOW "x = "
    SHOW x
    x--
WHILE x > 7

SHOW ""

# ---- Nested Loops ----
SHOW "--- Nested Loops: Simple Pattern ---"

FOR row = 1 TO 4 DO
    FOR col = 1 TO row DO
        SHOW "* "
    END
    SHOW ""
END

SHOW ""
SHOW "Loops program complete!"
