; ============================================================
; Educational Debugging, Tracing, and Step-Mode System
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
PrintInfo       PROTO
PrintDebug      PROTO
PrintError      PROTO
PrintTrace      PROTO
EXTERN g_debugMode      : DWORD
EXTERN g_stepMode       : DWORD
EXTERN g_traceMode      : DWORD
EXTERN tokenArray       : BYTE
EXTERN tokenCount       : DWORD
EXTERN tokenIndex       : DWORD
EXTERN varCount         : DWORD
EXTERN funcCount        : DWORD
EXTERN currentLine      : DWORD
EXTERN runtimeError     : DWORD
EXTERN runtimeErrorLine : DWORD
EXTERN runtimeErrorMsg  : BYTE
EXTERN callDepth        : DWORD
EXTERN execControl      : DWORD
EXTERN sourceFilename   : BYTE
EXTERN sourceSize       : DWORD
 
.data
 
; ---- Prefix strings ----
str_info_pfx        BYTE "[INFO] ",0
str_debug_pfx       BYTE "[DEBUG] ",0
str_error_pfx       BYTE "[ERROR] ",0
str_trace_pfx       BYTE "[TRACE] ",0
str_warn_pfx        BYTE "[WARN] ",0
 
; ---- Token type name table ----
; Array of (type, name) pairs for display
str_tok_eof         BYTE "EOF",0
str_tok_newline     BYTE "NEWLINE",0
str_tok_error_t     BYTE "ERROR",0
str_tok_integer     BYTE "INTEGER",0
str_tok_float_t     BYTE "FLOAT",0
str_tok_string_t    BYTE "STRING",0
str_tok_char_t      BYTE "CHAR",0
str_tok_btrue       BYTE "BOOL_TRUE",0
str_tok_bfalse      BYTE "BOOL_FALSE",0
str_tok_ident       BYTE "IDENT",0
str_tok_show        BYTE "SHOW",0
str_tok_print       BYTE "PRINT",0
str_tok_ask         BYTE "ASK",0
str_tok_input       BYTE "INPUT",0
str_tok_set         BYTE "SET",0
str_tok_let         BYTE "LET",0
str_tok_const       BYTE "CONST",0
str_tok_var         BYTE "VAR",0
str_tok_if          BYTE "IF",0
str_tok_then        BYTE "THEN",0
str_tok_else        BYTE "ELSE",0
str_tok_elif        BYTE "ELIF",0
str_tok_end         BYTE "END",0
str_tok_endif       BYTE "ENDIF",0
str_tok_while       BYTE "WHILE",0
str_tok_do          BYTE "DO",0
str_tok_for         BYTE "FOR",0
str_tok_to          BYTE "TO",0
str_tok_step        BYTE "STEP",0
str_tok_break       BYTE "BREAK",0
str_tok_continue    BYTE "CONTINUE",0
str_tok_endwhile    BYTE "ENDWHILE",0
str_tok_endfor      BYTE "ENDFOR",0
str_tok_func        BYTE "FUNC",0
str_tok_endfunc     BYTE "ENDFUNC",0
str_tok_return      BYTE "RETURN",0
str_tok_call        BYTE "CALL",0
str_tok_switch      BYTE "SWITCH",0
str_tok_case        BYTE "CASE",0
str_tok_default     BYTE "DEFAULT",0
str_tok_endswitch   BYTE "ENDSWITCH",0
str_tok_showvars    BYTE "SHOW_VARIABLES",0
str_tok_plus        BYTE "+",0
str_tok_minus       BYTE "-",0
str_tok_mul         BYTE "*",0
str_tok_div         BYTE "/",0
str_tok_mod         BYTE "%",0
str_tok_pow         BYTE "^",0
str_tok_eq          BYTE "==",0
str_tok_neq         BYTE "!=",0
str_tok_lt          BYTE "<",0
str_tok_gt          BYTE ">",0
str_tok_lte         BYTE "<=",0
str_tok_gte         BYTE ">=",0
str_tok_and         BYTE "AND",0
str_tok_or          BYTE "OR",0
str_tok_not         BYTE "NOT",0
str_tok_assign      BYTE "=",0
str_tok_plusassign  BYTE "+=",0
str_tok_minassign   BYTE "-=",0
str_tok_mulassign   BYTE "*=",0
str_tok_divassign   BYTE "/=",0
str_tok_incr        BYTE "++",0
str_tok_decr        BYTE "--",0
str_tok_lparen      BYTE "(",0
str_tok_rparen      BYTE ")",0
str_tok_comma       BYTE ",",0
str_tok_colon       BYTE ":",0
str_tok_semi        BYTE ";",0
str_tok_unknown     BYTE "???",0
 
; ---- Debug header strings ----
str_dbg_sep         BYTE "--------------------------------------------",0
str_dbg_tokdump     BYTE "====== TOKEN DUMP ======",0
str_dbg_tokfmt      BYTE "  L",0
str_dbg_col         BYTE " C",0
str_dbg_toktype     BYTE " | ",0
str_dbg_tokval      BYTE " | ",0
str_dbg_stats_hdr   BYTE "====== RUNTIME STATISTICS ======",0
str_dbg_tokens_n    BYTE "  Total tokens   : ",0
str_dbg_vars_n      BYTE "  Variables      : ",0
str_dbg_funcs_n     BYTE "  Functions      : ",0
str_dbg_calldepth   BYTE "  Call depth     : ",0
str_dbg_execctrl    BYTE "  Exec control   : ",0
str_dbg_curline     BYTE "  Current line   : ",0
str_dbg_file        BYTE "  Source file    : ",0
str_dbg_filesize    BYTE "  Source size    : ",0
str_dbg_bytes       BYTE " bytes",0
str_dbg_execnorm    BYTE "NORMAL",0
str_dbg_execbrk     BYTE "BREAK",0
str_dbg_execcnt     BYTE "CONTINUE",0
str_dbg_execret     BYTE "RETURN",0
str_dbg_execerr     BYTE "ERROR",0
 
str_err_line        BYTE "[ERROR] Line ",0
str_err_colon       BYTE ": ",0
str_err_hint        BYTE "  Hint: ",0
 
; ---- Friendly error hints ----
hint_undef_var      BYTE "Make sure you spelled the variable name correctly and used SET before using it.",0
hint_div_zero       BYTE "You cannot divide a number by zero. Check your divisor!",0
hint_syntax         BYTE "Check your spelling of keywords and make sure all blocks are closed with END.",0
hint_func_not       BYTE "Make sure the function is defined with FUNC before calling it.",0
hint_stack_over     BYTE "Your function is calling itself too many times! Check for infinite recursion.",0
hint_missing_end    BYTE "Every IF/WHILE/FOR/FUNC block needs a matching END or ENDXXX.",0
 
; ---- Statistics counters ----
PUBLIC dbg_stmtCount
PUBLIC dbg_loopCount
PUBLIC dbg_funcCallCount
PUBLIC dbg_errorCount
 
dbg_stmtCount       DWORD 0
dbg_loopCount       DWORD 0
dbg_funcCallCount   DWORD 0
dbg_errorCount      DWORD 0
 
.code
 
; ============================================================
; SetDebugMode - Set debug mode flag
; Parameters: [esp+4] = mode (0=off, 1=on)
; ============================================================
 
; ============================================================
; SetStepMode - Set step mode flag
; ============================================================
 
; ============================================================
; SetTraceMode - Set trace mode flag
; ============================================================
 
; ============================================================
; PrintInfo - Print [INFO] message (always shown)
; Parameters: EDX = message string address
; ============================================================
 
; ============================================================
; PrintDebug - Print [DEBUG] message (only in debug mode)
; Parameters: EDX = message string address
; ============================================================
 
; ============================================================
; PrintError - Print [ERROR] message with line number
; Parameters: EDX = message string address
;             EBX = line number (0 = unknown)
; ============================================================
 
; ============================================================
; PrintErrorHint - Print educational hint based on error code
; ============================================================
PrintErrorHint PROC
    push    eax
    push    edx
 
    mov     eax, runtimeError
 
    cmp     eax, ERR_UNDEFINED_VAR
    je      _hintUndef
    cmp     eax, ERR_DIV_BY_ZERO
    je      _hintDiv
    cmp     eax, ERR_SYNTAX
    je      _hintSyntax
    cmp     eax, ERR_FUNC_NOT_FOUND
    je      _hintFunc
    cmp     eax, ERR_STACK_OVERFLOW
    je      _hintStack
    cmp     eax, ERR_MISSING_END
    je      _hintEnd
    jmp     _hintDone
 
_hintUndef:
    mov     edx, OFFSET hint_undef_var
    jmp     _printHint
_hintDiv:
    mov     edx, OFFSET hint_div_zero
    jmp     _printHint
_hintSyntax:
    mov     edx, OFFSET hint_syntax
    jmp     _printHint
_hintFunc:
    mov     edx, OFFSET hint_func_not
    jmp     _printHint
_hintStack:
    mov     edx, OFFSET hint_stack_over
    jmp     _printHint
_hintEnd:
    mov     edx, OFFSET hint_missing_end
    jmp     _printHint
 
_printHint:
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    push    edx
    mov     edx, OFFSET str_err_hint
    call    WriteString
    pop     edx
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
    call    Crlf
 
_hintDone:
    pop     edx
    pop     eax
    ret
PrintErrorHint ENDP
 
; ============================================================
; PrintTrace - Print [TRACE] message (only in trace mode)
; Parameters: EDX = message string address
; ============================================================
 
; ============================================================
; PrintWarn - Print [WARN] message
; Parameters: EDX = message string
; ============================================================
PUBLIC PrintWarn
PrintWarn PROC
    push    eax
    push    edx
 
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    
    mov     edx, OFFSET str_warn_pfx
    call    WriteString
    
    pop     edx
    push    edx
    
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
    call    Crlf
    
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     edx
    pop     eax
    ret
PrintWarn ENDP
 
; ============================================================
; ShowTokenDump - Display all tokens (debug mode)
; Called after lexer completes in debug mode
; ============================================================
PUBLIC ShowTokenDump
ShowTokenDump PROC
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi
 
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _stdDone
 
    call    Crlf
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_tokdump
    call    WriteString
    call    Crlf
    
    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_sep
    call    WriteString
    call    Crlf
 
    mov     ecx, 0          ; token index
 
_stdLoop:
    cmp     ecx, tokenCount
    jge     _stdDone2
 
    ; Get token pointer
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
 
    ; Print line number
    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_tokfmt
    call    WriteString
    mov     eax, [esi + TOKEN_OFF_LINE]
    call    WriteDec
 
    ; Print column
    mov     edx, OFFSET str_dbg_col
    call    WriteString
    mov     eax, [esi + TOKEN_OFF_COL]
    call    WriteDec
 
    ; Print separator
    mov     edx, OFFSET str_dbg_toktype
    call    WriteString
 
    ; Print token type name
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, [esi + TOKEN_OFF_TYPE]
    call    GetTokenTypeName    ; EDX = name string
    call    WriteString
 
    ; Print value if non-empty
    lea     edx, [esi + TOKEN_OFF_VALUE]
    cmp     BYTE PTR [edx], 0
    je      _stdNoVal
 
    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    push    edx
    mov     edx, OFFSET str_dbg_tokval
    call    WriteString
    pop     edx
 
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
 
_stdNoVal:
    ; If integer, print value
    mov     eax, [esi + TOKEN_OFF_TYPE]
    cmp     eax, TOK_INTEGER
    jne     _stdNotInt
 
    mov     eax, LIGHTMAGENTA_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, ' '
    call    WriteChar
    mov     eax, [esi + TOKEN_OFF_IVAL]
    call    WriteInt
 
_stdNotInt:
    call    Crlf
    pop     ecx
    inc     ecx
    jmp     _stdLoop
 
_stdDone2:
    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_sep
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_stdDone:
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    ret
ShowTokenDump ENDP
 
; ============================================================
; GetTokenTypeName - Return EDX = pointer to token type name
; Parameters: EAX = token type code
; ============================================================
GetTokenTypeName PROC
    cmp     eax, TOK_EOF          ; 0
    je      _gtnEOF
    cmp     eax, TOK_NEWLINE      ; 1
    je      _gtnNL
    cmp     eax, TOK_INTEGER      ; 10
    je      _gtnInt
    cmp     eax, TOK_FLOAT        ; 11
    je      _gtnFloat
    cmp     eax, TOK_STRING       ; 12
    je      _gtnStr
    cmp     eax, TOK_CHAR         ; 13
    je      _gtnChar
    cmp     eax, TOK_BOOL_TRUE    ; 14
    je      _gtnBTrue
    cmp     eax, TOK_BOOL_FALSE   ; 15
    je      _gtnBFalse
    cmp     eax, TOK_IDENT        ; 20
    je      _gtnIdent
    cmp     eax, TOK_SHOW         ; 30
    je      _gtnShow
    cmp     eax, TOK_PRINT        ; 31
    je      _gtnPrint
    cmp     eax, TOK_ASK          ; 32
    je      _gtnAsk
    cmp     eax, TOK_INPUT        ; 33
    je      _gtnInput
    cmp     eax, TOK_SET          ; 40
    je      _gtnSet
    cmp     eax, TOK_LET          ; 41
    je      _gtnLet
    cmp     eax, TOK_CONST        ; 42
    je      _gtnConst
    cmp     eax, TOK_VAR          ; 43
    je      _gtnVar
    cmp     eax, TOK_IF           ; 50
    je      _gtnIf
    cmp     eax, TOK_THEN         ; 51
    je      _gtnThen
    cmp     eax, TOK_ELSE         ; 52
    je      _gtnElse
    cmp     eax, TOK_ELIF         ; 53
    je      _gtnElif
    cmp     eax, TOK_END          ; 54
    je      _gtnEnd
    cmp     eax, TOK_ENDIF        ; 55
    je      _gtnEndif
    cmp     eax, TOK_WHILE        ; 60
    je      _gtnWhile
    cmp     eax, TOK_DO           ; 61
    je      _gtnDo
    cmp     eax, TOK_FOR          ; 62
    je      _gtnFor
    cmp     eax, TOK_TO           ; 63
    je      _gtnTo
    cmp     eax, TOK_STEP         ; 64
    je      _gtnStep
    cmp     eax, TOK_BREAK        ; 65
    je      _gtnBreak
    cmp     eax, TOK_CONTINUE     ; 66
    je      _gtnCont
    cmp     eax, TOK_ENDWHILE     ; 67
    je      _gtnEndWhile
    cmp     eax, TOK_ENDFOR       ; 68
    je      _gtnEndFor
    cmp     eax, TOK_FUNC         ; 70
    je      _gtnFunc
    cmp     eax, TOK_ENDFUNC      ; 71
    je      _gtnEndFunc
    cmp     eax, TOK_RETURN       ; 72
    je      _gtnReturn
    cmp     eax, TOK_CALL         ; 73
    je      _gtnCall
    cmp     eax, TOK_SWITCH       ; 80
    je      _gtnSwitch
    cmp     eax, TOK_CASE         ; 81
    je      _gtnCase
    cmp     eax, TOK_DEFAULT      ; 82
    je      _gtnDefault
    cmp     eax, TOK_ENDSWITCH    ; 83
    je      _gtnEndSwitch
    cmp     eax, TOK_SHOW_VARS    ; 90
    je      _gtnShowVars
    cmp     eax, TOK_PLUS         ; 110
    je      _gtnPlus
    cmp     eax, TOK_MINUS        ; 111
    je      _gtnMinus
    cmp     eax, TOK_MULTIPLY     ; 112
    je      _gtnMul
    cmp     eax, TOK_DIVIDE       ; 113
    je      _gtnDiv
    cmp     eax, TOK_MODULO       ; 114
    je      _gtnMod
    cmp     eax, TOK_EQ           ; 120
    je      _gtnEQ
    cmp     eax, TOK_NEQ          ; 121
    je      _gtnNEQ
    cmp     eax, TOK_LT           ; 122
    je      _gtnLT
    cmp     eax, TOK_GT           ; 123
    je      _gtnGT
    cmp     eax, TOK_LTE          ; 124
    je      _gtnLTE
    cmp     eax, TOK_GTE          ; 125
    je      _gtnGTE
    cmp     eax, TOK_AND          ; 130
    je      _gtnAnd
    cmp     eax, TOK_OR           ; 131
    je      _gtnOr
    cmp     eax, TOK_NOT          ; 132
    je      _gtnNot
    cmp     eax, TOK_ASSIGN       ; 140
    je      _gtnAssign
    cmp     eax, TOK_PLUS_ASSIGN  ; 141
    je      _gtnPlusAssign
    cmp     eax, TOK_MINUS_ASSIGN ; 142
    je      _gtnMinAssign
    cmp     eax, TOK_MUL_ASSIGN   ; 143
    je      _gtnMulAssign
    cmp     eax, TOK_DIV_ASSIGN   ; 144
    je      _gtnDivAssign
    cmp     eax, TOK_INCREMENT    ; 150
    je      _gtnIncr
    cmp     eax, TOK_DECREMENT    ; 151
    je      _gtnDecr
    cmp     eax, TOK_LPAREN       ; 160
    je      _gtnLParen
    cmp     eax, TOK_RPAREN       ; 161
    je      _gtnRParen
    cmp     eax, TOK_COMMA        ; 164
    je      _gtnComma
    cmp     eax, TOK_COLON        ; 165
    je      _gtnColon
    ; Default
    mov     edx, OFFSET str_tok_unknown
    ret
 
_gtnEOF:         mov edx, OFFSET str_tok_eof        
    ret
_gtnNL:          mov edx, OFFSET str_tok_newline     
    ret
_gtnInt:         mov edx, OFFSET str_tok_integer     
    ret
_gtnFloat:       mov edx, OFFSET str_tok_float_t     
    ret
_gtnStr:         mov edx, OFFSET str_tok_string_t    
    ret
_gtnChar:        mov edx, OFFSET str_tok_char_t      
    ret
_gtnBTrue:       mov edx, OFFSET str_tok_btrue       
    ret
_gtnBFalse:      mov edx, OFFSET str_tok_bfalse      
    ret
_gtnIdent:       mov edx, OFFSET str_tok_ident       
    ret
_gtnShow:        mov edx, OFFSET str_tok_show        
    ret
_gtnPrint:       mov edx, OFFSET str_tok_print       
    ret
_gtnAsk:         mov edx, OFFSET str_tok_ask         
    ret
_gtnInput:       mov edx, OFFSET str_tok_input       
    ret
_gtnSet:         mov edx, OFFSET str_tok_set         
    ret
_gtnLet:         mov edx, OFFSET str_tok_let         
    ret
_gtnConst:       mov edx, OFFSET str_tok_const       
    ret
_gtnVar:         mov edx, OFFSET str_tok_var         
    ret
_gtnIf:          mov edx, OFFSET str_tok_if          
    ret
_gtnThen:        mov edx, OFFSET str_tok_then        
    ret
_gtnElse:        mov edx, OFFSET str_tok_else        
    ret
_gtnElif:        mov edx, OFFSET str_tok_elif        
    ret
_gtnEnd:         mov edx, OFFSET str_tok_end         
    ret
_gtnEndif:       mov edx, OFFSET str_tok_endif       
    ret
_gtnWhile:       mov edx, OFFSET str_tok_while       
    ret
_gtnDo:          mov edx, OFFSET str_tok_do          
    ret
_gtnFor:         mov edx, OFFSET str_tok_for         
    ret
_gtnTo:          mov edx, OFFSET str_tok_to          
    ret
_gtnStep:        mov edx, OFFSET str_tok_step        
    ret
_gtnBreak:       mov edx, OFFSET str_tok_break       
    ret
_gtnCont:        mov edx, OFFSET str_tok_continue    
    ret
_gtnEndWhile:    mov edx, OFFSET str_tok_endwhile    
    ret
_gtnEndFor:      mov edx, OFFSET str_tok_endfor      
    ret
_gtnFunc:        mov edx, OFFSET str_tok_func        
    ret
_gtnEndFunc:     mov edx, OFFSET str_tok_endfunc     
    ret
_gtnReturn:      mov edx, OFFSET str_tok_return      
    ret
_gtnCall:        mov edx, OFFSET str_tok_call        
    ret
_gtnSwitch:      mov edx, OFFSET str_tok_switch      
    ret
_gtnCase:        mov edx, OFFSET str_tok_case        
    ret
_gtnDefault:     mov edx, OFFSET str_tok_default     
    ret
_gtnEndSwitch:   mov edx, OFFSET str_tok_endswitch   
    ret
_gtnShowVars:    mov edx, OFFSET str_tok_showvars    
    ret
_gtnPlus:        mov edx, OFFSET str_tok_plus        
    ret
_gtnMinus:       mov edx, OFFSET str_tok_minus       
    ret
_gtnMul:         mov edx, OFFSET str_tok_mul         
    ret
_gtnDiv:         mov edx, OFFSET str_tok_div         
    ret
_gtnMod:         mov edx, OFFSET str_tok_mod         
    ret
_gtnEQ:          mov edx, OFFSET str_tok_eq          
    ret
_gtnNEQ:         mov edx, OFFSET str_tok_neq         
    ret
_gtnLT:          mov edx, OFFSET str_tok_lt          
    ret
_gtnGT:          mov edx, OFFSET str_tok_gt          
    ret
_gtnLTE:         mov edx, OFFSET str_tok_lte         
    ret
_gtnGTE:         mov edx, OFFSET str_tok_gte         
    ret
_gtnAnd:         mov edx, OFFSET str_tok_and         
    ret
_gtnOr:          mov edx, OFFSET str_tok_or          
    ret
_gtnNot:         mov edx, OFFSET str_tok_not         
    ret
_gtnAssign:      mov edx, OFFSET str_tok_assign      
    ret
_gtnPlusAssign:  mov edx, OFFSET str_tok_plusassign  
    ret
_gtnMinAssign:   mov edx, OFFSET str_tok_minassign   
    ret
_gtnMulAssign:   mov edx, OFFSET str_tok_mulassign   
    ret
_gtnDivAssign:   mov edx, OFFSET str_tok_divassign   
    ret
_gtnIncr:        mov edx, OFFSET str_tok_incr        
    ret
_gtnDecr:        mov edx, OFFSET str_tok_decr        
    ret
_gtnLParen:      mov edx, OFFSET str_tok_lparen      
    ret
_gtnRParen:      mov edx, OFFSET str_tok_rparen      
    ret
_gtnComma:       mov edx, OFFSET str_tok_comma       
    ret
_gtnColon:       mov edx, OFFSET str_tok_colon       
    ret
 
GetTokenTypeName ENDP
 
; ============================================================
; ShowRuntimeStats - Display execution statistics summary
; ============================================================
PUBLIC ShowRuntimeStats
ShowRuntimeStats PROC
    push    eax
    push    edx
 
    call    Crlf
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_stats_hdr
    call    WriteString
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
 
    mov     edx, OFFSET str_dbg_file
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET sourceFilename
    call    WriteString
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_filesize
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, sourceSize
    call    WriteDec
    mov     edx, OFFSET str_dbg_bytes
    call    WriteString
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_tokens_n
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, tokenCount
    call    WriteDec
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_vars_n
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, varCount
    call    WriteDec
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_funcs_n
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, funcCount
    call    WriteDec
    call    Crlf
 
    mov     eax, LIGHTGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_dbg_curline
    call    WriteString
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, currentLine
    call    WriteDec
    call    Crlf
 
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
    pop     edx
    pop     eax
    ret
ShowRuntimeStats ENDP
 
END