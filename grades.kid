# ============================================================
# KidLang Sample Program 08
# Topic: Full Grade Calculator Application
# ============================================================

SHOW "========================================"
SHOW "   STUDENT GRADE CALCULATOR"
SHOW "   KidLang Educational Demo"
SHOW "========================================"
SHOW ""

# ---- Define grade calculation function ----
FUNC getLetterGrade(percentage)
    IF percentage >= 90 THEN
        RETURN "A+"
    ELIF percentage >= 85 THEN
        RETURN "A"
    ELIF percentage >= 80 THEN
        RETURN "A-"
    ELIF percentage >= 75 THEN
        RETURN "B+"
    ELIF percentage >= 70 THEN
        RETURN "B"
    ELIF percentage >= 65 THEN
        RETURN "B-"
    ELIF percentage >= 60 THEN
        RETURN "C+"
    ELIF percentage >= 55 THEN
        RETURN "C"
    ELIF percentage >= 50 THEN
        RETURN "C-"
    ELIF percentage >= 45 THEN
        RETURN "D"
    ELSE
        RETURN "F"
    END
ENDFUNC

FUNC printResult(subject, marks, total)
    SET percent = marks * 100 / total
    SHOW subject
    SHOW marks
    SHOW "out of"
    SHOW total
    SHOW "  Percentage:"
    SHOW percent
ENDFUNC

# ---- Student 1 ----
SHOW "--- Student: Ali Raza ---"
SET math    = 88
SET english = 76
SET science = 91
SET urdu    = 82
SET islamiat = 95

SET totalObtained = math + english + science + urdu + islamiat
SET totalPossible = 500
SET overallPercent = totalObtained * 100 / totalPossible

SHOW "Marks Breakdown:"
CALL printResult("Mathematics:", math, 100)
CALL printResult("English:    ", english, 100)
CALL printResult("Science:    ", science, 100)
CALL printResult("Urdu:       ", urdu, 100)
CALL printResult("Islamiat:   ", islamiat, 100)

SHOW ""
SHOW "Total Marks Obtained:"
SHOW totalObtained
SHOW "Out of:"
SHOW totalPossible
SHOW "Overall Percentage:"
SHOW overallPercent

SET grade = CALL getLetterGrade(overallPercent)
SHOW "Final Grade:"
SHOW grade

IF overallPercent >= 50 THEN
    SHOW "Result: PASSED"
ELSE
    SHOW "Result: FAILED"
END

SHOW ""
SHOW "----------------------------------------"
SHOW ""

# ---- Student 2 ----
SHOW "--- Student: Sara Malik ---"
SET math    = 95
SET english = 89
SET science = 97
SET urdu    = 93
SET islamiat = 98

SET totalObtained = math + english + science + urdu + islamiat
SET overallPercent = totalObtained * 100 / totalPossible

SHOW "Marks Breakdown:"
CALL printResult("Mathematics:", math, 100)
CALL printResult("English:    ", english, 100)
CALL printResult("Science:    ", science, 100)
CALL printResult("Urdu:       ", urdu, 100)
CALL printResult("Islamiat:   ", islamiat, 100)

SHOW ""
SHOW "Total:"
SHOW totalObtained
SHOW "Percentage:"
SHOW overallPercent

SET grade = CALL getLetterGrade(overallPercent)
SHOW "Grade:"
SHOW grade
SHOW "Result: PASSED - Excellent!"

SHOW ""
SHOW "--- Class Summary ---"
SHOW "Ali Raza:   88% - B+"
SHOW "Sara Malik: 94% - A+"
SHOW ""
SHOW "Class Topper: Sara Malik"
SHOW ""
SHOW "Grade Calculator program complete!"
