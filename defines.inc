; ============================================================
; All constants, token type codes, error codes, limits
; ============================================================

; ---- Buffer / Size Limits ----
MAX_SOURCE_SIZE     EQU 65536       ; 64KB max source file
MAX_TOKEN_LEN       EQU 128         ; max token string length
MAX_TOKENS          EQU 2048        ; max tokens per program
MAX_VARIABLES       EQU 256         ; max variables in symbol table
MAX_FUNCTIONS       EQU 64          ; max user-defined functions
MAX_CALL_STACK      EQU 32          ; max call stack depth
MAX_STRING_LEN      EQU 512         ; max string value length
MAX_LINE_LEN        EQU 1024        ; max source line length
MAX_LINES           EQU 2048        ; max lines in source
MAX_FILENAME        EQU 260         ; max filename length
MAX_ERRORS          EQU 64          ; max errors to collect

; ---- Token Types ----
; Special
TOK_EOF             EQU 0
TOK_NEWLINE         EQU 1
TOK_ERROR           EQU 2

; Literals
TOK_INTEGER         EQU 10
TOK_FLOAT           EQU 11
TOK_STRING          EQU 12
TOK_CHAR            EQU 13
TOK_BOOL_TRUE       EQU 14
TOK_BOOL_FALSE      EQU 15

; Identifiers
TOK_IDENT           EQU 20

; Keywords - Output/Input
TOK_SHOW            EQU 30
TOK_PRINT           EQU 31
TOK_ASK             EQU 32
TOK_INPUT           EQU 33
TOK_SHOWL           EQU 34      ; SHOWL = SHOW without newline (inline)

; Keywords - Variables
TOK_SET             EQU 40
TOK_LET             EQU 41
TOK_CONST           EQU 42
TOK_VAR             EQU 43

; Keywords - Control Flow
TOK_IF              EQU 50
TOK_THEN            EQU 51
TOK_ELSE            EQU 52
TOK_ELIF            EQU 53
TOK_END             EQU 54
TOK_ENDIF           EQU 55

; Keywords - Loops
TOK_WHILE           EQU 60
TOK_DO              EQU 61
TOK_FOR             EQU 62
TOK_TO              EQU 63
TOK_STEP            EQU 64
TOK_BREAK           EQU 65
TOK_CONTINUE        EQU 66
TOK_ENDWHILE        EQU 67
TOK_ENDFOR          EQU 68

; Keywords - Functions
TOK_FUNC            EQU 70
TOK_ENDFUNC         EQU 71
TOK_RETURN          EQU 72
TOK_CALL            EQU 73

; Keywords - Switch
TOK_SWITCH          EQU 80
TOK_CASE            EQU 81
TOK_DEFAULT         EQU 82
TOK_ENDSWITCH       EQU 83

; Keywords - Debug/Info
TOK_SHOW_VARS       EQU 90
TOK_DEBUG_ON        EQU 91
TOK_DEBUG_OFF       EQU 92
TOK_TRACE_ON        EQU 93
TOK_TRACE_OFF       EQU 94
TOK_PAUSE           EQU 95
TOK_CLEAR           EQU 96
TOK_WAIT            EQU 97

; Keywords - Type Declarations
TOK_INTEGER_TYPE    EQU 100
TOK_FLOAT_TYPE      EQU 101
TOK_STRING_TYPE     EQU 102
TOK_CHAR_TYPE       EQU 103
TOK_BOOL_TYPE       EQU 104

; Arithmetic Operators
TOK_PLUS            EQU 110
TOK_MINUS           EQU 111
TOK_MULTIPLY        EQU 112
TOK_DIVIDE          EQU 113
TOK_MODULO          EQU 114
TOK_POWER           EQU 115

; Relational Operators
TOK_EQ              EQU 120     ; ==
TOK_NEQ             EQU 121     ; !=
TOK_LT              EQU 122     ; <
TOK_GT              EQU 123     ; >
TOK_LTE             EQU 124     ; <=
TOK_GTE             EQU 125     ; >=

; Logical Operators
TOK_AND             EQU 130
TOK_OR              EQU 131
TOK_NOT             EQU 132

; Assignment
TOK_ASSIGN          EQU 140     ; =
TOK_PLUS_ASSIGN     EQU 141     ; +=
TOK_MINUS_ASSIGN    EQU 142     ; -=
TOK_MUL_ASSIGN      EQU 143     ; *=
TOK_DIV_ASSIGN      EQU 144     ; /=

; Increment/Decrement
TOK_INCREMENT       EQU 150     ; ++
TOK_DECREMENT       EQU 151     ; --

; Punctuation
TOK_LPAREN          EQU 160     ; (
TOK_RPAREN          EQU 161     ; )
TOK_LBRACKET        EQU 162     ; [
TOK_RBRACKET        EQU 163     ; ]
TOK_COMMA           EQU 164     ; ,
TOK_COLON           EQU 165     ; :
TOK_SEMICOLON       EQU 166     ; ;
TOK_DOT             EQU 167     ; .
TOK_QUOTE           EQU 168     ; "
TOK_HASH            EQU 169     ; # (comment)

; ---- Variable / Value Types ----
VTYPE_INTEGER       EQU 1
VTYPE_FLOAT         EQU 2
VTYPE_STRING        EQU 3
VTYPE_CHAR          EQU 4
VTYPE_BOOL          EQU 5
VTYPE_UNDEFINED     EQU 0

; ---- Menu Choices ----
MENU_RUN_FILE       EQU 1
MENU_DEBUG_FILE     EQU 2
MENU_STEP_FILE      EQU 3
MENU_INTERACTIVE    EQU 4
MENU_HELP           EQU 5
MENU_EXIT           EQU 6

; ---- Error Codes ----
ERR_NONE            EQU 0
ERR_FILE_NOT_FOUND  EQU 1
ERR_FILE_READ       EQU 2
ERR_SYNTAX          EQU 3
ERR_UNDEFINED_VAR   EQU 4
ERR_DIV_BY_ZERO     EQU 5
ERR_TYPE_MISMATCH   EQU 6
ERR_STACK_OVERFLOW  EQU 7
ERR_INVALID_OP      EQU 8
ERR_TOO_MANY_VARS   EQU 9
ERR_FUNC_NOT_FOUND  EQU 10
ERR_INVALID_ARGS    EQU 11
ERR_UNEXPECTED_TOK  EQU 12
ERR_MISSING_END     EQU 13
ERR_RETURN_OUTSIDE  EQU 14
ERR_BREAK_OUTSIDE   EQU 15

; ---- Runtime Control Codes ----
EXEC_NORMAL         EQU 0
EXEC_BREAK          EQU 1
EXEC_CONTINUE       EQU 2
EXEC_RETURN         EQU 3
EXEC_ERROR          EQU 4

; ---- Colors (Irvine32) ----
; Already defined in Irvine32 but redefined for clarity
BLACK_C             EQU 0
BLUE_C              EQU 1
GREEN_C             EQU 2
CYAN_C              EQU 3
RED_C               EQU 4
MAGENTA_C           EQU 5
BROWN_C             EQU 6
LIGHTGRAY_C         EQU 7
DARKGRAY_C          EQU 8
LIGHTBLUE_C         EQU 9
LIGHTGREEN_C        EQU 10
LIGHTCYAN_C         EQU 11
LIGHTRED_C          EQU 12
LIGHTMAGENTA_C      EQU 13
YELLOW_C            EQU 14
WHITE_C             EQU 15

; ---- Display prefix codes ----
PREFIX_INFO         EQU 1
PREFIX_DEBUG        EQU 2
PREFIX_ERROR        EQU 3
PREFIX_TRACE        EQU 4
PREFIX_WARN         EQU 5

; ---- Execution Flags ----
FLAG_IN_LOOP        EQU 01h
FLAG_IN_FUNC        EQU 02h
FLAG_IN_IF          EQU 04h
FLAG_DEBUG          EQU 08h
FLAG_STEP           EQU 10h
FLAG_TRACE          EQU 20h
FLAG_SKIP_BLOCK     EQU 40h     ; skipping false IF block
