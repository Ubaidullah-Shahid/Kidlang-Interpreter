; ============================================================
; Runtime environment: global memory, init, shutdown, banner,
; menu, mode flags, info/error printing, symbol table display
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
OPTION LANGUAGE:STDCALL
 
.data
 
; ============================================================
; GLOBAL MEMORY - All shared state lives here
; ============================================================
 
; Source file storage
PUBLIC sourceBuffer
PUBLIC sourceSize
PUBLIC sourceFilename
PUBLIC currentLine
 
sourceBuffer        BYTE MAX_SOURCE_SIZE DUP(0)
sourceSize          DWORD 0
sourceFilename      BYTE MAX_FILENAME DUP(0)
currentLine         DWORD 1
 
; ---- TOKEN TABLE ----
PUBLIC tokenArray
PUBLIC tokenCount
PUBLIC tokenIndex
 
tokenArray          BYTE (MAX_TOKENS * TOKEN_SIZE) DUP(0)
tokenCount          DWORD 0
tokenIndex          DWORD 0
 
; ---- SYMBOL TABLE (Variables) ----
PUBLIC varTable
PUBLIC varCount
 
varTable            BYTE (MAX_VARIABLES * VAR_SIZE) DUP(0)
varCount            DWORD 0
 
; ---- FUNCTION TABLE ----
PUBLIC funcTable
PUBLIC funcCount
 
funcTable           BYTE (MAX_FUNCTIONS * FUNC_SIZE) DUP(0)
funcCount           DWORD 0
 
; ---- RUNTIME STATE ----
PUBLIC runtimeFlags
PUBLIC runtimeError
PUBLIC runtimeErrorLine
PUBLIC runtimeErrorMsg
 
runtimeFlags        DWORD 0
runtimeError        DWORD ERR_NONE
runtimeErrorLine    DWORD 0
runtimeErrorMsg     BYTE 256 DUP(0)
 
; ---- EXECUTION CONTROL ----
PUBLIC execControl
PUBLIC returnValInt
PUBLIC returnValFloat
PUBLIC returnValStr
PUBLIC returnValType
 
execControl         DWORD EXEC_NORMAL
returnValInt        DWORD 0
returnValFloat      REAL4 0.0
returnValStr        BYTE MAX_STRING_LEN DUP(0)
returnValType       DWORD VTYPE_UNDEFINED
 
; ---- CALL STACK ----
PUBLIC callDepth
PUBLIC callStack
 
callDepth           DWORD 0
callStack           DWORD MAX_CALL_STACK DUP(0)
 
; ---- MODE FLAGS ----
PUBLIC g_debugMode
PUBLIC g_stepMode
PUBLIC g_traceMode
PUBLIC g_menuChoice
 
g_debugMode         DWORD 0
g_stepMode          DWORD 0
g_traceMode         DWORD 0
g_menuChoice        DWORD 0
 
; ---- TEMP WORK BUFFERS ----
PUBLIC tempBuf
PUBLIC tempBuf2
PUBLIC printBuf
PUBLIC execNameBuf          ; <--- NEW: dedicated buffer for executor variable names
 
tempBuf             BYTE 512 DUP(0)
tempBuf2            BYTE 512 DUP(0)
printBuf            BYTE 1024 DUP(0)
execNameBuf         BYTE 256 DUP(0)      ; safe storage for variable names
 
; ============================================================
; UI Strings
; ============================================================
banner_line1    BYTE "==================================================",0
banner_line2    BYTE "  K I D L A N G  -  v1.0  Educational Language  ",0
banner_line3    BYTE "  For Students (8th - 10th Class)                ",0
banner_line4    BYTE "  Built with MASM x86 + Irvine32                 ",0
banner_line5    BYTE "==================================================",0
 
menu_title      BYTE "  SELECT EXECUTION MODE:",0
menu_opt1       BYTE "  [1] Run Program File",0
menu_opt2       BYTE "  [2] Debug Mode (show tokens + trace)",0
menu_opt3       BYTE "  [3] Step-by-Step Mode",0
menu_opt4       BYTE "  [4] Interactive Shell",0
menu_opt5       BYTE "  [5] Help / Language Guide",0
menu_opt6       BYTE "  [6] Exit",0
menu_prompt     BYTE "  Enter choice (1-6): ",0
menu_file_prompt BYTE "  Enter filename (e.g. loops.kid): ",0
; str_auto_path removed (was used for hardcoded path prepend)
 
str_info_pfx    BYTE "[INFO] ",0
str_debug_pfx   BYTE "[DEBUG] ",0
str_error_pfx   BYTE "[ERROR] ",0
str_trace_pfx   BYTE "[TRACE] ",0
str_warn_pfx    BYTE "[WARN] ",0
 
str_invalid     BYTE "  Invalid choice. Try again.",0
str_divzero     BYTE "Division by zero detected!",0
str_undef_var   BYTE "Undefined variable",0
str_sym_header  BYTE "====== VARIABLE TABLE ======",0
str_sym_footer  BYTE "============================",0
str_sym_int     BYTE " (integer) = ",0
str_sym_float   BYTE " (float)   = ",0
str_sym_string  BYTE " (string)  = ",0
str_sym_char    BYTE " (char)    = ",0
str_sym_bool    BYTE " (bool)    = ",0
str_sym_true    BYTE "true",0
str_sym_false   BYTE "false",0
str_sym_empty   BYTE "  (no variables defined)",0
 
str_step_prompt BYTE "[STEP] Press ENTER to execute next line...",0
str_line_exec   BYTE "[EXEC] Line: ",0
 
; filename buffer for UI input
inputFilename   BYTE MAX_FILENAME DUP(0)
 
.code
 
; ============================================================
; InitRuntime - Initialize all global memory to clean state
; ============================================================
PUBLIC InitRuntime
InitRuntime PROC
    push    edi
    push    ecx
 
    ; Zero out source buffer
    mov     edi, OFFSET sourceBuffer
    mov     ecx, MAX_SOURCE_SIZE
    xor     al, al
    rep     stosb
 
    ; Zero out token array
    mov     edi, OFFSET tokenArray
    mov     ecx, (MAX_TOKENS * TOKEN_SIZE)
    xor     al, al
    rep     stosb
 
    ; Zero out variable table
    mov     edi, OFFSET varTable
    mov     ecx, (MAX_VARIABLES * VAR_SIZE)
    xor     al, al
    rep     stosb
 
    ; Zero out function table
    mov     edi, OFFSET funcTable
    mov     ecx, (MAX_FUNCTIONS * FUNC_SIZE)
    xor     al, al
    rep     stosb
 
    ; Zero out execNameBuf (optional but safe)
    mov     edi, OFFSET execNameBuf
    mov     ecx, 256
    xor     al, al
    rep     stosb
 
    ; Reset counters
    mov     sourceSize, 0
    mov     tokenCount, 0
    mov     tokenIndex, 0
    mov     varCount, 0
    mov     funcCount, 0
    mov     currentLine, 1
 
    ; Reset runtime state
    mov     runtimeFlags, 0
    mov     runtimeError, ERR_NONE
    mov     runtimeErrorLine, 0
 
    ; Reset execution control
    mov     execControl, EXEC_NORMAL
    mov     returnValInt, 0
    mov     returnValType, VTYPE_UNDEFINED
 
    ; Reset call stack
    mov     callDepth, 0
 
    ; Reset modes
    mov     g_debugMode, 0
    mov     g_stepMode, 0
    mov     g_traceMode, 0
    mov     g_menuChoice, 0
 
    pop     ecx
    pop     edi
    ret
InitRuntime ENDP
 
; ============================================================
; ShutdownRuntime - Clean shutdown
; ============================================================
PUBLIC ShutdownRuntime
ShutdownRuntime PROC
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    ret
ShutdownRuntime ENDP
 
; ============================================================
; ShowBanner - Display KidLang startup banner
; ============================================================
PUBLIC ShowBanner
ShowBanner PROC
    call    Crlf
 
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET banner_line1
    call    WriteString
    call    Crlf
 
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET banner_line2
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET banner_line3
    call    WriteString
    call    Crlf
 
    mov     edx, OFFSET banner_line4
    call    WriteString
    call    Crlf
 
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET banner_line5
    call    WriteString
    call    Crlf
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    ret
ShowBanner ENDP
 
; ============================================================
; ShowMenu - Show the main menu and get user choice
; ============================================================
PUBLIC ShowMenu
ShowMenu PROC
    push    ebx
 
_menuLoop:
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET menu_title
    call    WriteString
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET menu_opt1
    call    WriteString
    call    Crlf
    mov     edx, OFFSET menu_opt2
    call    WriteString
    call    Crlf
    mov     edx, OFFSET menu_opt3
    call    WriteString
    call    Crlf
    mov     edx, OFFSET menu_opt4
    call    WriteString
    call    Crlf
    mov     edx, OFFSET menu_opt5
    call    WriteString
    call    Crlf
    mov     edx, OFFSET menu_opt6
    call    WriteString
    call    Crlf
    call    Crlf
 
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET menu_prompt
    call    WriteString
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    call    ReadChar
    call    WriteChar
    call    Crlf
 
    sub     al, '0'
    movzx   ebx, al
 
    cmp     ebx, 1
    jl      _badChoice
    cmp     ebx, 6
    jg      _badChoice
 
    mov     g_menuChoice, ebx
 
    cmp     ebx, MENU_RUN_FILE
    je      _needFile
    cmp     ebx, MENU_DEBUG_FILE
    je      _needFile
    cmp     ebx, MENU_STEP_FILE
    je      _needFile
    jmp     _menuDone
 
_needFile:
    call    Crlf
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET menu_file_prompt
    call    WriteString
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET inputFilename
    mov     ecx, MAX_FILENAME - 1
    call    ReadString
 
    mov     esi, OFFSET inputFilename
    add     esi, eax
    dec     esi
_stripTrail:
    cmp     esi, OFFSET inputFilename
    jl      _stripDone
    mov     bl, [esi]
    cmp     bl, 13
    je      _stripIt
    cmp     bl, 10
    je      _stripIt
    cmp     bl, ' '
    je      _stripIt
    jmp     _stripDone
_stripIt:
    mov     BYTE PTR [esi], 0
    dec     esi
    jmp     _stripTrail
_stripDone:
 
    ; Copy inputFilename directly into sourceFilename (no path prepend)
    mov     esi, OFFSET inputFilename
    mov     edi, OFFSET sourceFilename
_copyFilename:
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _copyFilenameDone
    inc     esi
    inc     edi
    jmp     _copyFilename
_copyFilenameDone:
 
    call    Crlf
    jmp     _menuDone
 
_badChoice:
    mov     eax, RED_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_invalid
    call    WriteString
    call    Crlf
    call    Crlf
    jmp     _menuLoop
 
_menuDone:
    mov     eax, g_menuChoice
    pop     ebx
    ret
ShowMenu ENDP
 
; ============================================================
; SetDebugMode
; ============================================================
PUBLIC SetDebugMode
SetDebugMode PROC
    mov     g_debugMode, eax
    ret
SetDebugMode ENDP
 
; ============================================================
; SetStepMode
; ============================================================
PUBLIC SetStepMode
SetStepMode PROC
    mov     g_stepMode, eax
    ret
SetStepMode ENDP
 
; ============================================================
; SetTraceMode
; ============================================================
PUBLIC SetTraceMode
SetTraceMode PROC
    mov     g_traceMode, eax
    ret
SetTraceMode ENDP
 
; ============================================================
; PrintInfo
; ============================================================
PUBLIC PrintInfo
PrintInfo PROC
    push    eax
    push    edx
 
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET str_info_pfx
    call    WriteString
 
    pop     edx
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     eax
    ret
PrintInfo ENDP
 
; ============================================================
; PrintDebug
; ============================================================
PUBLIC PrintDebug
PrintDebug PROC
    push    eax
    push    edx
 
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _skipDebug
 
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET str_debug_pfx
    call    WriteString
 
    pop     edx
    push    edx
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    jmp     _debugDone
 
_skipDebug:
    pop     edx
    push    edx
 
_debugDone:
    pop     edx
    pop     eax
    ret
PrintDebug ENDP
 
; ============================================================
; PrintError
; ============================================================
PUBLIC PrintError
PrintError PROC
    push    eax
    push    edx
    push    ebx
 
    mov     eax, LIGHTRED_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET str_error_pfx
    call    WriteString
 
    mov     eax, [esp]      ; EBX saved on stack = line number
    cmp     eax, 0
    je      _skipLine
 
    mov     esi, OFFSET tempBuf
    mov     BYTE PTR [esi], 'L'
    mov     BYTE PTR [esi+1], 'i'
    mov     BYTE PTR [esi+2], 'n'
    mov     BYTE PTR [esi+3], 'e'
    mov     BYTE PTR [esi+4], ' '
    mov     BYTE PTR [esi+5], 0
    mov     edx, OFFSET tempBuf
    call    WriteString
 
    call    WriteDec
 
    mov     al, ':'
    call    WriteChar
    mov     al, ' '
    call    WriteChar
 
_skipLine:
    mov     edx, [esp+4]    ; original EDX
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     ebx
    pop     edx
    pop     eax
    ret
PrintError ENDP
 
; ============================================================
; PrintTrace
; ============================================================
PUBLIC PrintTrace
PrintTrace PROC
    push    eax
    push    edx
 
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _skipTrace
 
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET str_trace_pfx
    call    WriteString
 
    pop     edx
    push    edx
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    jmp     _traceDone
 
_skipTrace:
    pop     edx
    push    edx
 
_traceDone:
    pop     edx
    pop     eax
    ret
PrintTrace ENDP
 
; ============================================================
; StepPause
; ============================================================
PUBLIC StepPause
StepPause PROC
    push    eax
    push    edx
 
    mov     eax, g_stepMode
    cmp     eax, 0
    je      _skipStep
 
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_step_prompt
    call    WriteString
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    call    ReadChar
    call    Crlf
 
_skipStep:
    pop     edx
    pop     eax
    ret
StepPause ENDP
 
; ============================================================
; ShowSymbolTable
; ============================================================
PUBLIC ShowSymbolTable
ShowSymbolTable PROC
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
 
    call    Crlf
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_header
    call    WriteString
    call    Crlf
 
    mov     ecx, varCount
    cmp     ecx, 0
    jne     _symLoop
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_empty
    call    WriteString
    call    Crlf
    jmp     _symDone
 
_symLoop:
    mov     ebx, 0
 
_symNext:
    cmp     ebx, varCount
    jge     _symDone
 
    push    ecx
    mov     ecx, VAR_SIZE
    imul    ecx, ebx
    mov     esi, OFFSET varTable
    add     esi, ecx
    pop     ecx
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, esi
    call    WriteString
 
    mov     eax, [esi + VAR_OFF_TYPE]
 
    cmp     eax, VTYPE_INTEGER
    je      _printInt
    cmp     eax, VTYPE_FLOAT
    je      _printFloat
    cmp     eax, VTYPE_STRING
    je      _printStr
    cmp     eax, VTYPE_CHAR
    je      _printChar
    cmp     eax, VTYPE_BOOL
    je      _printBool
    jmp     _nextVar
 
_printInt:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_int
    call    WriteString
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, [esi + VAR_OFF_IVAL]
    call    WriteInt
    call    Crlf
    jmp     _nextVar
 
_printFloat:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_float
    call    WriteString
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, [esi + VAR_OFF_IVAL]
    call    WriteInt
    call    Crlf
    jmp     _nextVar
 
_printStr:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_string
    call    WriteString
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     al, '"'
    call    WriteChar
    lea     edx, [esi + VAR_OFF_SVAL]
    call    WriteString
    mov     al, '"'
    call    WriteChar
    call    Crlf
    jmp     _nextVar
 
_printChar:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_char
    call    WriteString
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     al, "'"
    call    WriteChar
    mov     al, [esi + VAR_OFF_CVAL]
    call    WriteChar
    mov     al, "'"
    call    WriteChar
    call    Crlf
    jmp     _nextVar
 
_printBool:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_bool
    call    WriteString
    mov     eax, LIGHTMAGENTA_C + (BLACK_C * 16)
    call    SetTextColor
    movzx   eax, BYTE PTR [esi + VAR_OFF_BVAL]
    cmp     al, 1
    je      _boolTrue
    mov     edx, OFFSET str_sym_false
    call    WriteString
    call    Crlf
    jmp     _nextVar
_boolTrue:
    mov     edx, OFFSET str_sym_true
    call    WriteString
    call    Crlf
 
_nextVar:
    inc     ebx
    jmp     _symNext
 
_symDone:
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_sym_footer
    call    WriteString
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    ret
ShowSymbolTable ENDP
 
; ============================================================
; StrLen_KL
; ============================================================
PUBLIC StrLen_KL
StrLen_KL PROC
    push    esi
    xor     eax, eax
_lenLoop:
    cmp     BYTE PTR [esi], 0
    je      _lenDone
    inc     esi
    inc     eax
    jmp     _lenLoop
_lenDone:
    pop     esi
    ret
StrLen_KL ENDP
 
 
; ============================================================
; StrCopy_KL
; ============================================================
PUBLIC StrCopy_KL
StrCopy_KL PROC
    push    esi
    push    edi
    push    ecx
_copyLoop:
    cmp     ecx, 0
    je      _copyDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _copyDone
    inc     esi
    inc     edi
    dec     ecx
    jmp     _copyLoop
_copyDone:
    mov     BYTE PTR [edi], 0
    pop     ecx
    pop     edi
    pop     esi
    ret
StrCopy_KL ENDP
 
; ============================================================
; StrCompare_KL
; ============================================================
PUBLIC StrCompare_KL
StrCompare_KL PROC
    push    esi
    push    edi
_cmpLoop:
    mov     al, [esi]
    mov     bl, [edi]
    cmp     al, bl
    jne     _cmpNotEqual
    cmp     al, 0
    je      _cmpEqual
    inc     esi
    inc     edi
    jmp     _cmpLoop
_cmpEqual:
    xor     eax, eax
    jmp     _cmpDone
_cmpNotEqual:
    movzx   eax, al
    movzx   ebx, bl
    sub     eax, ebx
_cmpDone:
    pop     edi
    pop     esi
    ret
StrCompare_KL ENDP
 
; ============================================================
; ToLower_KL
; ============================================================
PUBLIC ToLower_KL
ToLower_KL PROC
    push    esi
    push    eax
_lowerLoop:
    mov     al, [esi]
    cmp     al, 0
    je      _lowerDone
    cmp     al, 'A'
    jl      _notUpper
    cmp     al, 'Z'
    jg      _notUpper
    add     al, 32
    mov     [esi], al
_notUpper:
    inc     esi
    jmp     _lowerLoop
_lowerDone:
    pop     eax
    pop     esi
    ret
ToLower_KL ENDP
 
; ============================================================
; IntToStr_KL
; ============================================================
PUBLIC IntToStr_KL
IntToStr_KL PROC
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    edi
 
    cmp     eax, 0
    jge     _posNum
    mov     BYTE PTR [edi], '-'
    inc     edi
    neg     eax
_posNum:
 
    cmp     eax, 0
    jne     _nonZero
    mov     BYTE PTR [edi], '0'
    inc     edi
    mov     BYTE PTR [edi], 0
    jmp     _intStrDone
 
_nonZero:
    mov     ecx, 0
    mov     ebx, 10
_digitLoop:
    cmp     eax, 0
    je      _digitsDone
    xor     edx, edx
    div     ebx
    push    edx
    inc     ecx
    jmp     _digitLoop
_digitsDone:
_popDigit:
    cmp     ecx, 0
    je      _intStrNull
    pop     eax
    add     al, '0'
    mov     [edi], al
    inc     edi
    dec     ecx
    jmp     _popDigit
_intStrNull:
    mov     BYTE PTR [edi], 0
 
_intStrDone:
    pop     edi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    ret
IntToStr_KL ENDP
 
END