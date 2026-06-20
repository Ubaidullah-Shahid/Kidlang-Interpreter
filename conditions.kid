# ============================================================
# KidLang Sample Program 04
# Topic: IF / ELSE IF / ELSE / SWITCH conditions
# For: 8th-10th Class Students
# ============================================================

SHOW "====== Learning Conditions ======"
SHOW ""

# ---- Basic IF ----
SHOW "--- Basic IF ---"
SET score = 85

IF score >= 50 THEN
    SHOW "You passed the exam!"
END

SHOW ""

# ---- IF ELSE ----
SHOW "--- IF ELSE ---"
SET temperature = 35

IF temperature > 30 THEN
    SHOW "It is very hot today!"
ELSE
    SHOW "The weather is nice today."
END

SHOW ""

# ---- IF ELSE IF ELSE ----
SHOW "--- Grade System ---"
SET marks = 78

IF marks >= 90 THEN
    SHOW "Grade: A+ - Excellent!"
ELIF marks >= 80 THEN
    SHOW "Grade: A  - Very Good!"
ELIF marks >= 70 THEN
    SHOW "Grade: B  - Good!"
ELIF marks >= 60 THEN
    SHOW "Grade: C  - Satisfactory"
ELIF marks >= 50 THEN
    SHOW "Grade: D  - Needs Improvement"
ELSE
    SHOW "Grade: F  - Failed. Please study harder!"
END

SHOW ""

# ---- Logical Operators ----
SHOW "--- Logical Operators ---"
SET age = 17
SET hasPermission = TRUE

IF age >= 16 AND hasPermission == TRUE THEN
    SHOW "You are allowed to participate!"
ELSE
    SHOW "Sorry, you cannot participate yet."
END

SET isRaining = FALSE
SET isCold = TRUE

IF isRaining OR isCold THEN
    SHOW "Take a jacket today."
END

SET isHoliday = FALSE

IF NOT isHoliday THEN
    SHOW "Today is a school day. Time to study!"
END

SHOW ""

# ---- Nested IF ----
SHOW "--- Nested IF ---"
SET number = 15
 
IF number > 0 THEN
    SHOW "Number is positive."
    IF number > 10 THEN
        SHOW "And it is greater than 10!"
        IF number > 20 THEN
            SHOW "Actually greater than 20!"
        ELSE
            SHOW "But not greater than 20."
        END
    ELSE
        SHOW "And it is 10 or less."
    END
ELSE
    SHOW "Number is zero or negative."
END

SHOW ""

# ---- SWITCH CASE ----
SHOW "--- SWITCH CASE: Day of the Week ---"
SET dayNum = 3

SWITCH dayNum
    CASE 1:
        SHOW "Monday - Start of school week!"
    CASE 2:
        SHOW "Tuesday - Keep going!"
    CASE 3:
        SHOW "Wednesday - Half way there!"
    CASE 4:
        SHOW "Thursday - Almost done!"
    CASE 5:
        SHOW "Friday - Last school day!"
    CASE 6:
        SHOW "Saturday - Weekend!"
    CASE 7:
        SHOW "Sunday - Rest day!"
    DEFAULT:
        SHOW "Invalid day number."
ENDSWITCH

SHOW ""
SHOW "Conditions program complete!"
