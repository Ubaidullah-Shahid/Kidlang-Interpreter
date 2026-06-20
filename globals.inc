; ============================================================
; Global shared data structures used across all modules
; ============================================================

; ---- TOKEN STRUCTURE ----
; Each token is 200 bytes total:
;   type   DWORD  (4 bytes)  - token type code
;   value  BYTE[128]         - token string value (null-terminated)
;   line   DWORD  (4 bytes)  - source line number
;   col    DWORD  (4 bytes)  - source column number
;   ival   DWORD  (4 bytes)  - integer value (if numeric token)
;   fval   REAL4  (4 bytes)  - float value (if float token)
;   pad    BYTE[52]          - padding to 200 bytes
TOKEN_SIZE          EQU 200
TOKEN_OFF_TYPE      EQU 0
TOKEN_OFF_VALUE     EQU 4
TOKEN_OFF_LINE      EQU 132
TOKEN_OFF_COL       EQU 136
TOKEN_OFF_IVAL      EQU 140
TOKEN_OFF_FVAL      EQU 144
TOKEN_OFF_PAD       EQU 148

; ---- VARIABLE STRUCTURE ----
; Each variable entry is 600 bytes:
;   name   BYTE[128]         - variable name (normalized lowercase)
;   type   DWORD  (4 bytes)  - VTYPE_xxx
;   ival   DWORD  (4 bytes)  - integer value
;   fval   REAL4  (4 bytes)  - float value
;   sval   BYTE[256]         - string value
;   cval   BYTE   (1 byte)   - char value
;   bval   BYTE   (1 byte)   - bool value (0=false,1=true)
;   isConst BYTE  (1 byte)   - 1 if constant
;   pad    BYTE[201]         - padding to 600 bytes
VAR_SIZE            EQU 600
VAR_OFF_NAME        EQU 0
VAR_OFF_TYPE        EQU 128
VAR_OFF_IVAL        EQU 132
VAR_OFF_FVAL        EQU 136
VAR_OFF_SVAL        EQU 140
VAR_OFF_CVAL        EQU 396
VAR_OFF_BVAL        EQU 397
VAR_OFF_ISCONST     EQU 398
VAR_OFF_PAD         EQU 399

; ---- FUNCTION STRUCTURE ----
; Each function entry is 400 bytes:
;   name      BYTE[128]      - function name (lowercase)
;   tokenStart DWORD         - index of first token in function body
;   tokenEnd   DWORD         - index of last token in function body
;   paramCount DWORD         - number of parameters
;   params    BYTE[128]      - param names (each 16 bytes, max 8 params)
;   pad       BYTE[128]      - padding
FUNC_SIZE           EQU 400
FUNC_OFF_NAME       EQU 0
FUNC_OFF_TOKSTART   EQU 128
FUNC_OFF_TOKEND     EQU 132
FUNC_OFF_PARAMCOUNT EQU 136
FUNC_OFF_PARAMS     EQU 140
FUNC_OFF_PAD        EQU 268

; ---- SHARED GLOBAL MEMORY LAYOUT ----
; All modules access these through EXTERN declarations
; Defined once in runtime.asm

; Source file buffer:       sourceBuffer[MAX_SOURCE_SIZE]
; Source file size:         sourceSize DWORD
; Source filename:          sourceFilename[MAX_FILENAME]
; Current source line:      currentLine DWORD

; Token array:              tokenArray[MAX_TOKENS * TOKEN_SIZE]
; Token count:              tokenCount DWORD
; Current token index:      tokenIndex DWORD

; Symbol table (variables):  varTable[MAX_VARIABLES * VAR_SIZE]
; Variable count:            varCount DWORD

; Function table:            funcTable[MAX_FUNCTIONS * FUNC_SIZE]
; Function count:            funcCount DWORD

; Runtime flags:             runtimeFlags DWORD
; Runtime error code:        runtimeError DWORD
; Runtime error line:        runtimeErrorLine DWORD
; Runtime error message:     runtimeErrorMsg[256]

; Execution control:         execControl DWORD  (EXEC_NORMAL etc)
; Return value integer:      returnValInt DWORD
; Return value float:        returnValFloat REAL4
; Return value string:       returnValStr[MAX_STRING_LEN]
; Return value type:         returnValType DWORD

; Call stack depth:          callDepth DWORD
; Call stack return indices: callStack[MAX_CALL_STACK * 4]

; Debug mode flag:           g_debugMode DWORD
; Step mode flag:            g_stepMode DWORD
; Trace mode flag:           g_traceMode DWORD

; ---- MACROS for common operations ----

; Print a string literal in debug color
DBGPRINT MACRO strAddr
    LOCAL skip
    push    eax
    push    edx
    mov     eax, g_debugMode
    cmp     eax, 0
    je      skip
    mov     eax, LIGHTCYAN_C
    call    SetTextColor
    mov     edx, strAddr
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C
    call    SetTextColor
skip:
    pop     edx
    pop     eax
ENDM

; Print a trace message
TRACEPRINT MACRO strAddr
    LOCAL skip
    push    eax
    push    edx
    mov     eax, g_traceMode
    cmp     eax, 0
    je      skip
    mov     eax, LIGHTGREEN_C
    call    SetTextColor
    mov     edx, strAddr
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C
    call    SetTextColor
skip:
    pop     edx
    pop     eax
ENDM
