; ============================================================
; Interactive REPL (Read-Eval-Print Loop) Shell
; Allows children to type KidLang commands interactively
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
EXTERN sourceBuffer     : BYTE
EXTERN sourceSize       : DWORD
EXTERN tokenArray       : BYTE
EXTERN tokenCount       : DWORD
EXTERN tokenIndex       : DWORD
EXTERN g_debugMode      : DWORD
EXTERN g_traceMode      : DWORD
EXTERN g_stepMode       : DWORD
EXTERN varCount         : DWORD
InitRuntime     PROTO
RunLexer        PROTO
RunParser       PROTO
RunExecutor     PROTO
ShowSymbolTable PROTO
PrintInfo       PROTO
PrintDebug      PROTO
PrintError      PROTO
 
.data
 
; ---- Shell UI strings ----
shell_banner1   BYTE "  ===================================",0
shell_banner2   BYTE "  KIDLANG INTERACTIVE SHELL v1.0",0
shell_banner3   BYTE "  Type KidLang commands directly!",0
shell_banner4   BYTE "  Type 'exit' or 'quit' to leave.",0
shell_banner5   BYTE "  Type 'help' for language guide.",0
shell_banner6   BYTE "  Type 'clear' to clear screen.",0
shell_banner7   BYTE "  Type 'vars' to show variables.",0
shell_banner8   BYTE "  ===================================",0
 
shell_prompt    BYTE "KidLang> ",0
str_debug_on_msg    BYTE "Debug mode ON. All messages will be shown.",0
str_debug_off_msg   BYTE "Debug mode OFF. Clean output mode.",0
shell_empty     BYTE "  (empty - type something!)",0
shell_bye       BYTE "[INFO] Leaving interactive shell. Goodbye!",0
shell_ready     BYTE "[INFO] Shell is ready. Type your code!",0
shell_exec_ok   BYTE "[OK] Line executed.",0
shell_multi     BYTE "  (use 'run' to execute multi-line block)",0
shell_sep       BYTE "-----------------------------------------",0
 
str_exit1       BYTE "exit",0
str_exit2       BYTE "quit",0
str_exit3       BYTE "bye",0
str_cmd_help    BYTE "help",0
str_cmd_clear   BYTE "clear",0
str_cmd_vars    BYTE "vars",0
str_cmd_debug   BYTE "debug",0
str_cmd_nodebug BYTE "nodebug",0
str_cmd_run     BYTE "run",0
 
; Shell input buffer - single line
shell_input     BYTE 512 DUP(0)
shell_inputLen  DWORD 0
 
; Multi-line input buffer (for block execution)
; Accumulates lines until 'run' is typed
multi_buf       BYTE 4096 DUP(0)
multi_len       DWORD 0
multi_mode      DWORD 0     ; 1 = in multi-line mode
 
; Temp buffer for comparison
shell_tmp       BYTE 128 DUP(0)
 
; Help text for interactive shell
shell_help BYTE 13,10
    BYTE "  ======== KIDLANG QUICK REFERENCE ========",13,10
    BYTE 13,10
    BYTE "  VARIABLES:",13,10
    BYTE "    SET name = value",13,10
    BYTE "    SET name = ",34,"text",34,13,10
    BYTE "    LET x = 5 + 3",13,10
    BYTE "    CONST PI = 3",13,10
    BYTE 13,10
    BYTE "  OUTPUT:",13,10
    BYTE "    SHOW ",34,"Hello World",34,13,10
    BYTE "    SHOW variable",13,10
    BYTE "    SHOW 5 * 4 + 1",13,10
    BYTE 13,10
    BYTE "  INPUT:",13,10
    BYTE "    ASK name",13,10
    BYTE "    ASK ",34,"Enter age: ",34," age",13,10
    BYTE 13,10
    BYTE "  MATH:",13,10
    BYTE "    +  -  *  /  %  (add,sub,mul,div,mod)",13,10
    BYTE "    ==  !=  <  >  <=  >= (compare)",13,10
    BYTE 13,10
    BYTE "  IF STATEMENT:",13,10
    BYTE "    IF x > 5 THEN",13,10
    BYTE "      SHOW ",34,"Big!",34,13,10
    BYTE "    ELSE",13,10
    BYTE "      SHOW ",34,"Small",34,13,10
    BYTE "    END",13,10
    BYTE 13,10
    BYTE "  WHILE LOOP:",13,10
    BYTE "    WHILE x < 10 DO",13,10
    BYTE "      SHOW x",13,10
    BYTE "      x = x + 1",13,10
    BYTE "    ENDWHILE",13,10
    BYTE 13,10
    BYTE "  FOR LOOP:",13,10
    BYTE "    FOR i = 1 TO 5 DO",13,10
    BYTE "      SHOW i",13,10
    BYTE "    ENDFOR",13,10
    BYTE 13,10
    BYTE "  FUNCTIONS:",13,10
    BYTE "    FUNC greet()",13,10
    BYTE "      SHOW ",34,"Hello!",34,13,10
    BYTE "    ENDFUNC",13,10
    BYTE "    CALL greet()",13,10
    BYTE 13,10
    BYTE "  DEBUG:",13,10
    BYTE "    SHOW_VARIABLES",13,10
    BYTE "    DEBUG_ON  / DEBUG_OFF",13,10
    BYTE "    TRACE_ON  / TRACE_OFF",13,10
    BYTE "    PAUSE",13,10
    BYTE "  ==========================================",13,10
    BYTE 0
 
.code
 
; ============================================================
; RunInteractiveShell - Main REPL loop
; ============================================================
PUBLIC RunInteractiveShell
RunInteractiveShell PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
    ; Show shell banner
    call    ShowShellBanner
 
    mov     edx, OFFSET shell_ready
    call    PrintInfo
 
_shellLoop:
    ; Print prompt
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_prompt
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    ; Read input line
    mov     edx, OFFSET shell_input
    mov     ecx, 511
    call    ReadString
    mov     shell_inputLen, eax
    call    Crlf
 
    ; Skip if empty
    cmp     eax, 0
    je      _shellLoop
 
    ; Check for built-in shell commands
    call    CheckShellCommand
    cmp     eax, 1
    je      _shellLoop      ; handled internally
    cmp     eax, -1
    je      _shellExit
 
    ; Execute the typed line as KidLang code
    call    ExecShellLine
 
    jmp     _shellLoop
 
_shellExit:
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_bye
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
RunInteractiveShell ENDP
 
; ============================================================
; ShowShellBanner
; ============================================================
ShowShellBanner PROC
    push    eax
    push    edx
 
    call    Crlf
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    
    mov     edx, OFFSET shell_banner1
    call    WriteString
    call    Crlf
    
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_banner2
    call    WriteString
    call    Crlf
    
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_banner3
    call    WriteString
    call    Crlf
    
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_banner4
    call    WriteString
    call    Crlf
    mov     edx, OFFSET shell_banner5
    call    WriteString
    call    Crlf
    mov     edx, OFFSET shell_banner6
    call    WriteString
    call    Crlf
    mov     edx, OFFSET shell_banner7
    call    WriteString
    call    Crlf
    
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_banner8
    call    WriteString
    call    Crlf
    call    Crlf
    
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     edx
    pop     eax
    ret
ShowShellBanner ENDP
 
; ============================================================
; CheckShellCommand - Check if input is a shell command
; Returns: EAX = 1 if handled, -1 if exit, 0 if not a shell cmd
; ============================================================
CheckShellCommand PROC
    push    ebx
    push    ecx
    push    esi
    push    edi
 
    ; Copy input to lowercase temp buffer
    mov     esi, OFFSET shell_input
    mov     edi, OFFSET shell_tmp
    mov     ecx, 127
_cscCopy:
    cmp     ecx, 0
    je      _cscCopyDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _cscCopyDone
    ; Lowercase
    cmp     al, 'A'
    jl      _cscLowerNext
    cmp     al, 'Z'
    jg      _cscLowerNext
    add     al, 32
    mov     [edi], al
_cscLowerNext:
    inc     esi
    inc     edi
    dec     ecx
    jmp     _cscCopy
_cscCopyDone:
    mov     BYTE PTR [edi], 0
 
    ; Check: exit / quit / bye
    mov     esi, OFFSET shell_tmp
    mov     edi, OFFSET str_exit1
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscExit
 
    mov     edi, OFFSET str_exit2
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscExit
 
    mov     edi, OFFSET str_exit3
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscExit
 
    ; Check: help
    mov     edi, OFFSET str_cmd_help
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscHelp
 
    ; Check: clear
    mov     edi, OFFSET str_cmd_clear
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscClear
 
    ; Check: vars
    mov     edi, OFFSET str_cmd_vars
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscVars
 
    ; Check: debug
    mov     edi, OFFSET str_cmd_debug
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscDebug
 
    ; Check: nodebug
    mov     edi, OFFSET str_cmd_nodebug
    call    ShellStrCmp
    cmp     eax, 0
    je      _cscNoDebug
 
    ; Not a shell command
    xor     eax, eax
    jmp     _cscDone
 
_cscExit:
    mov     eax, -1
    jmp     _cscDone
 
_cscHelp:
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET shell_help
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, 1
    jmp     _cscDone
 
_cscClear:
    call    Clrscr
    call    ShowShellBanner
    mov     eax, 1
    jmp     _cscDone
 
_cscVars:
    call    ShowSymbolTable
    mov     eax, 1
    jmp     _cscDone
 
_cscDebug:
    mov     g_debugMode, 1
    mov     g_traceMode, 1
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_debug_on_msg
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, 1
    jmp     _cscDone
 
_cscNoDebug:
    mov     g_debugMode, 0
    mov     g_traceMode, 0
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_debug_off_msg
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, 1
    jmp     _cscDone
 
_cscDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    ret
CheckShellCommand ENDP
 
; ============================================================
; ExecShellLine - Execute a single typed line
; Copies input to sourceBuffer, runs lexer+parser+executor
; ============================================================
ExecShellLine PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi
 
    ; Copy shell_input to sourceBuffer
    ; Append a newline for proper lexing
    mov     esi, OFFSET shell_input
    mov     edi, OFFSET sourceBuffer
    mov     ecx, MAX_SOURCE_SIZE - 4
 
_eslCopy:
    cmp     ecx, 0
    je      _eslCopyDone
    mov     al, [esi]
    cmp     al, 0
    je      _eslCopyDone
    mov     [edi], al
    inc     esi
    inc     edi
    dec     ecx
    jmp     _eslCopy
 
_eslCopyDone:
    ; Add newline + null terminator
    mov     BYTE PTR [edi], 10  ; LF
    inc     edi
    mov     BYTE PTR [edi], 0
 
    ; Set source size
    mov     eax, edi
    sub     eax, OFFSET sourceBuffer
    mov     sourceSize, eax
 
    ; Reset token system
    mov     tokenCount, 0
    mov     tokenIndex, 0
 
    ; Run lexer
    call    RunLexer
    cmp     eax, 0
    jne     _eslError
 
    ; Run parser
    call    RunParser
    cmp     eax, 0
    jne     _eslError
 
    ; Run executor
    call    RunExecutor
    cmp     eax, 0
    jne     _eslError
 
    jmp     _eslDone
 
_eslError:
    ; Error already printed by subsystem
 
_eslDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
ExecShellLine ENDP
 
; ============================================================
; ShellStrCmp - Compare ESI string with EDI string
; Returns: EAX = 0 if equal
; ============================================================
ShellStrCmp PROC
_sscLoop:
    mov     al, [esi]
    mov     bl, [edi]
    cmp     al, bl
    jne     _sscNotEq
    cmp     al, 0
    je      _sscEqual
    inc     esi
    inc     edi
    jmp     _sscLoop
_sscEqual:
    xor     eax, eax
    ret
_sscNotEq:
    mov     eax, 1
    ret
ShellStrCmp ENDP
 
END