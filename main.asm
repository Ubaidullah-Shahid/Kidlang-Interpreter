; ============================================================
; Description: Main entry point for KidLang educational
;              programming language interpreter
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
; External procedures from other modules
InitRuntime     PROTO
ShutdownRuntime PROTO
ShowBanner      PROTO
ShowMenu        PROTO
ReadSourceFile  PROTO
RunLexer        PROTO
RunParser       PROTO
RunExecutor     PROTO
ShowSymbolTable PROTO
SetDebugMode    PROTO
SetStepMode     PROTO
SetTraceMode    PROTO
PrintInfo       PROTO
PrintDebug      PROTO
PrintError      PROTO
PrintTrace      PROTO
 
.data
    ; Command line / menu selection
    menuChoice      BYTE 0
    
    ; Mode flags
    debugMode       BYTE 0      ; 1 = debug on
    stepMode        BYTE 0      ; 1 = step mode on
    traceMode       BYTE 0      ; 1 = trace mode on
    
    ; Program result
    programResult   DWORD 0
    
    ; Strings
    str_welcome     BYTE "[KIDLANG] Welcome to KidLang v1.0 - Educational Programming Language",0
    str_starting    BYTE "[INFO] Interpreter Starting...",0
    str_done        BYTE "[INFO] Program Execution Complete.",0
    str_goodbye     BYTE "[INFO] Goodbye! Keep Learning!",0
    str_nofile      BYTE "[ERROR] No source file specified.",0
    str_running     BYTE "[INFO] Program Started",0
    str_finished    BYTE "[INFO] Program Finished",0
    str_press_enter BYTE 13,10,"Press ENTER to return to main menu...",0
 
    ; Help screen strings
    help_title  BYTE "====== KIDLANG LANGUAGE GUIDE ======",0
    help_text   BYTE "Variables:  SET name = value",13,10
                BYTE "Output:     SHOW variable",13,10
                BYTE "Input:      ASK name",13,10
                BYTE "If:         IF x > 5 THEN ... END",13,10
                BYTE "While:      WHILE x < 10 DO ... END",13,10
                BYTE "For:        FOR i = 1 TO 10 DO ... END",13,10
                BYTE "Function:   FUNC name() ... ENDFUNC",13,10
                BYTE "Call:       CALL name()",13,10
                BYTE "Comment:    # This is a comment",13,10
                BYTE "Debug:      SHOW_VARIABLES",13,10,0
 
.code
 
; ============================================================
; MAIN PROCEDURE
; Entry point of the entire KidLang interpreter
; ============================================================
main PROC
    ; Setup stack frame
    push    ebp
    mov     ebp, esp
    sub     esp, 64             ; Local space

    ; Initialize Irvine32
    call    Clrscr

    ; Initialize runtime subsystems
    call    InitRuntime

; ============================================================
; MAIN MENU LOOP - keeps running until user picks Exit
; ============================================================
_mainMenuLoop:
    ; Display startup banner
    call    ShowBanner

    ; Print startup message
    mov     edx, OFFSET str_starting
    call    WriteString
    call    Crlf

    ; Show main menu and get user choice
    call    ShowMenu
    mov     menuChoice, al

    ; Check what user wants to do
    movzx   eax, menuChoice

    cmp     al, MENU_RUN_FILE
    je      _doRunFile

    cmp     al, MENU_DEBUG_FILE
    je      _doDebugFile

    cmp     al, MENU_STEP_FILE
    je      _doStepFile

    cmp     al, MENU_INTERACTIVE
    je      _doInteractive

    cmp     al, MENU_HELP
    je      _doHelp

    cmp     al, MENU_EXIT
    je      _doExit

    jmp     _doExit

_doRunFile:
    ; Normal execution mode
    mov     debugMode, 0
    mov     stepMode, 0
    mov     traceMode, 0
    jmp     _executeProgram

_doDebugFile:
    ; Debug mode - show tokens, parser, variables
    mov     debugMode, 1
    mov     stepMode, 0
    mov     traceMode, 1
    jmp     _executeProgram

_doStepFile:
    ; Step-by-step execution mode
    mov     debugMode, 1
    mov     stepMode, 1
    mov     traceMode, 1
    jmp     _executeProgram

_executeProgram:
    ; Set mode flags in runtime
    movzx   eax, debugMode
    call    SetDebugMode

    movzx   eax, stepMode
    call    SetStepMode

    movzx   eax, traceMode
    call    SetTraceMode

    ; Read source file from disk
    call    ReadSourceFile
    cmp     eax, 0
    jne     _fileError

    ; Print info: program started
    mov     edx, OFFSET str_running
    call    WriteString
    call    Crlf

    ; Phase 1: Run Lexer / Tokenizer
    call    RunLexer
    cmp     eax, 0
    jne     _lexerError

    ; Phase 2: Run Parser
    call    RunParser
    cmp     eax, 0
    jne     _parserError

    ; Phase 3: Run Executor (actual execution engine)
    call    RunExecutor
    cmp     eax, 0
    jne     _runtimeError

    ; Show final symbol table if debug mode
    movzx   eax, debugMode
    cmp     al, 1
    jne     _skipSymTable
    call    ShowSymbolTable
_skipSymTable:

    ; Print finish
    mov     edx, OFFSET str_finished
    call    WriteString
    call    Crlf
    jmp     _backToMenu

_fileError:
    mov     edx, OFFSET str_nofile
    call    WriteString
    call    Crlf
    jmp     _backToMenu

_lexerError:
    jmp     _backToMenu

_parserError:
    jmp     _backToMenu

_runtimeError:
    jmp     _backToMenu

_doInteractive:
    jmp     _doHelp

_doHelp:
    call    ShowHelp
    jmp     _backToMenu

_backToMenu:
    ; Pause: Press ENTER to return to menu
    mov     edx, OFFSET str_press_enter
    call    WriteString
    call    ReadChar            ; wait for any key
    call    Clrscr              ; clear screen
    jmp     _mainMenuLoop       ; loop back to menu

_doExit:
_programEnd:
    ; Goodbye message
    mov     edx, OFFSET str_goodbye
    call    WriteString
    call    Crlf

    ; Cleanup runtime
    call    ShutdownRuntime

    ; Exit
    mov     esp, ebp
    pop     ebp

    invoke  ExitProcess, 0
main ENDP
 
; ============================================================
; ShowHelp - Display language help / syntax guide
; ============================================================
ShowHelp PROC
    call    Crlf
    mov     eax, YELLOW
    call    SetTextColor
    
    mov     edx, OFFSET help_title
    call    WriteString
    call    Crlf
    
    mov     eax, WHITE
    call    SetTextColor
    
    mov     edx, OFFSET help_text
    call    WriteString
    call    Crlf
    
    ret
ShowHelp ENDP
 
END main