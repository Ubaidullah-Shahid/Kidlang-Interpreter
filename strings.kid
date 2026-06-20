# ============================================================
#  KidLang Sample Program 07
# Topic: Strings, String Operations, Text Handling
# ============================================================

SHOW "====== Learning Strings ======"
SHOW ""

# ---- String variables ----
SET firstName = "Ahmed"
SET lastName  = "Khan"
SET city      = "Lahore"
SET country   = "Pakistan"

SHOW "First Name:"
SHOW firstName

SHOW "Last Name:"
SHOW lastName

SHOW "City:"
SHOW city

SHOW "Country:"
SHOW country

SHOW ""

# ---- Show full introduction ----
SHOW "--- Introduction ---"
SHOW "My name is:"
SHOW firstName
SHOW lastName

SHOW "I live in:"
SHOW city
SHOW country

SHOW ""

# ---- String inside conditions ----
SHOW "--- Checking String Values ---"

SET weather = "sunny"

IF weather == "sunny" THEN
    SHOW "It is a sunny day! Go outside and play."
ELIF weather == "rainy" THEN
    SHOW "It is raining. Stay inside and read."
ELIF weather == "cloudy" THEN
    SHOW "Cloudy day. Maybe it will rain later."
ELSE
    SHOW "Unknown weather condition."
END

SHOW ""

# ---- Strings in loops ----
SHOW "--- Print Name 3 Times ---"

FOR i = 1 TO 3 DO
    SHOW "Hello, "
    SHOW firstName
END

SHOW ""

# ---- String with function ----
FUNC introduce(name, age)
    SHOW "Hi! My name is "
    SHOW name
    SHOW "and I am "
    SHOW age
    SHOW "years old."
ENDFUNC

CALL introduce("Sara", 14)
CALL introduce("Bilal", 16)
CALL introduce("Zara", 15)

SHOW ""

# ---- Multi-line output messages ----
SHOW "--- School Report ---"
SET studentName = "Ali Hassan"
SET subject1 = "Mathematics"
SET subject2 = "Science"
SET subject3 = "English"
SET score1 = 92
SET score2 = 87
SET score3 = 95

SHOW "Student:"
SHOW studentName
SHOW ""
SHOW subject1
SHOW score1
SHOW subject2
SHOW score2
SHOW subject3
SHOW score3

SET totalScore = score1 + score2 + score3
SET average = totalScore / 3

SHOW ""
SHOW "Total Score:"
SHOW totalScore
SHOW "Average:"
SHOW average

IF average >= 90 THEN
    SHOW "Remarks: Outstanding Performance!"
ELIF average >= 75 THEN
    SHOW "Remarks: Very Good Performance!"
ELIF average >= 60 THEN
    SHOW "Remarks: Good Performance!"
ELSE
    SHOW "Remarks: Needs Improvement"
END

SHOW ""
SHOW "Strings program complete!"
