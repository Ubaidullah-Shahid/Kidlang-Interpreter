# ============================================================
# case_insensitive.kid  -  KidLang Case Insensitivity Test
# Topic: Keywords work in any UPPER/lower/Mixed case
# For: 8th-10th Class Students
# ============================================================

SHOW "====== Case Insensitivity Demo ======"
SHOW ""

# ---- SET in different cases ----
SHOW "--- Variables ---"
SET name    = "Ali Ahmed"
set city    = "Lahore"
Set marks   = 92

SHOW name
SHOW city
SHOW marks
SHOW ""

# ---- SHOW in different cases ----
show "--- SHOW in all cases ---"
Show "This works too!"
SHOW "And this as well!"
SHOW ""

# ---- IF / THEN / ELSE / END in mixed case ----
SHOW "--- IF ELSE mixed case ---"
set score = 75

if score >= 50 then
    show "You PASSED!"
else
    show "You failed."
end

If score >= 70 Then
    Show "Good marks!"
End
SHOW ""

# ---- ELIF mixed case ----
SHOW "--- ELIF mixed case ---"
SET grade = 85

IF grade >= 90 THEN
    SHOW "A+ Grade"
elif grade >= 80 THEN
    SHOW "A Grade"
Elif grade >= 70 then
    SHOW "B Grade"
else
    SHOW "Below B"
END
SHOW ""

# ---- WHILE / DO / ENDWHILE mixed case ----
SHOW "--- WHILE loop mixed case ---"
Set counter = 1

while counter <= 3 do
    Show counter
    SET counter = counter + 1
endwhile

WHILE counter <= 6 DO
    SHOW counter
    set counter = counter + 1
ENDWHILE
SHOW ""

# ---- REPEAT / UNTIL mixed case ----
SHOW "--- REPEAT loop mixed case ---"
set n = 1

repeat
    show n
    Set n = n + 1
until n > 3

Repeat
    Show n
    SET n = n + 1
Until n > 6
SHOW ""

# ---- FOR / TO / STEP / ENDFOR mixed case ----
SHOW "--- FOR loop mixed case ---"
for i = 1 to 5 step 1
    show i
endfor

FOR j = 10 TO 12 STEP 1
    SHOW j
ENDFOR
SHOW ""

# ---- CONST mixed case ----
SHOW "--- CONST mixed case ---"
CONST MAX = 100
const MIN = 0
Const PI  = 3.14159

SHOW MAX
SHOW MIN
SHOW PI
SHOW ""

# ---- TRUE / FALSE mixed case ----
SHOW "--- Boolean literals ---"
set isStudent  = TRUE
set isTeacher  = false
set isPassing  = True
set isFailing  = False

SHOW isStudent
SHOW isTeacher
SHOW isPassing
SHOW isFailing
SHOW ""

# ---- SWITCH / CASE / DEFAULT / ENDSWITCH mixed case ----
SHOW "--- SWITCH mixed case ---"
SET day = 2

switch day
    case 1:
        SHOW "Monday"
    CASE 2:
        show "Tuesday"
    Case 3:
        Show "Wednesday"
    default:
        SHOW "Other day"
endswitch
SHOW ""

# ---- INPUT mixed case ----
SHOW "--- INPUT mixed case ---"
SHOW "Enter a number:"
INPUT userNum
show "You entered:"
Show userNum
SHOW ""

# ---- FUNC / CALL / RETURN / ENDFUNC mixed case ----
SHOW "--- FUNCTION mixed case ---"

func SayHello
    show "Hello from function!"
endfunc

FUNC Add(a, b)
    RETURN a + b
ENDFUNC

call SayHello
CALL SayHello

SET result = CALL Add(3, 7)
SHOW "3 + 7 ="
SHOW result
SHOW ""

SHOW "====== All Case Tests Passed! ======"
