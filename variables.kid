# ============================================================
#  KidLang Sample Program 02
# Topic: Variables, Data Types, Assignment
# ============================================================

SHOW "====== Learning Variables ======"
SHOW ""

# Integer variable
SET age = 15
SHOW "My age is:"
SHOW age

# String variable
SET name = "Ali Ahmed"
SHOW "My name is:"
SHOW name

# Boolean variable
SET isStudent = TRUE
SHOW "Am I a student?"
SHOW isStudent

# Float variable
SET marks = 92.5
SHOW "My marks are:"
SHOW marks

# Character variable
SET grade = 'A'
SHOW "My grade is:"
SHOW grade

SHOW ""
SHOW "====== Updating Variables ======"
SHOW ""

# Updating a variable
SET age = 16
SHOW "Next year my age will be:"
SHOW age

# Using a variable in a calculation
SET totalMarks = marks + 7.5
SHOW "If I get 7.5 more marks:"
SHOW totalMarks

SHOW ""
SHOW "====== Constant Values ======"

# Constants cannot be changed after declaration
CONST PI = 3.14159
CONST MAX_STUDENTS = 40
CONST SCHOOL_NAME = "Bright Future School"

SHOW "Value of PI:"
SHOW PI
SHOW "Max students per class:"
SHOW MAX_STUDENTS
SHOW "School name:"
SHOW SCHOOL_NAME

SHOW ""
SHOW "====== Show All Variables ======"
SHOW_VARIABLES

SHOW ""
SHOW "Program complete!"
