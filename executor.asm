; ============================================================
; KIDLANG  EXECUTOR
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
EXTERN tokenArray       : BYTE
EXTERN tokenCount       : DWORD
EXTERN tokenIndex       : DWORD
EXTERN varTable         : BYTE
EXTERN varCount         : DWORD
EXTERN funcTable        : BYTE
EXTERN funcCount        : DWORD
EXTERN execControl      : DWORD
EXTERN returnValInt     : DWORD
EXTERN returnValStr     : BYTE
EXTERN returnValType    : DWORD
EXTERN callDepth        : DWORD
EXTERN callStack        : DWORD
EXTERN g_debugMode      : DWORD
EXTERN g_stepMode       : DWORD
EXTERN g_traceMode      : DWORD
EXTERN runtimeError     : DWORD
EXTERN runtimeErrorLine : DWORD
EXTERN currentLine      : DWORD
EXTERN tempBuf          : BYTE
EXTERN tempBuf2         : BYTE
EXTERN printBuf         : BYTE
EXTERN execNameBuf      : BYTE
 
PrintInfo       PROTO
PrintDebug      PROTO
PrintTrace      PROTO
PrintError      PROTO
ShowSymbolTable PROTO
FindVariable    PROTO
CreateVariable  PROTO
SetVarInt       PROTO
SetVarString    PROTO
SetVarBool      PROTO
GetVarInt       PROTO
GetVarString    PROTO
EvalExpression  PROTO
ConsumeToken    PROTO
PeekTokenType   PROTO
StrCopy_KL      PROTO
StrCompare_KL   PROTO
ToLower_KL      PROTO
IntToStr_KL     PROTO
StrLen_KL       PROTO
StrToInt_KL     PROTO
 
.data
 
str_exec_start      BYTE "[INFO] Execution started.",0
str_exec_done       BYTE "[INFO] Execution finished.",0
str_exec_line       BYTE "[EXEC] Line ",0
str_exec_colon      BYTE ": ",0
str_step_prompt     BYTE "[STEP] Press ENTER for next line...",0
str_ask_prompt      BYTE "? ",0
str_ask_prompt2     BYTE ": ",0
str_func_call       BYTE "[TRACE] Calling function: ",0
str_func_ret        BYTE "[TRACE] Function returned.",0
str_func_notfound   BYTE "Function not found: ",0
str_too_deep        BYTE "Call stack overflow (max 32).",0
str_break_out       BYTE "BREAK outside loop.",0
str_cont_out        BYTE "CONTINUE outside loop.",0
str_ret_out         BYTE "RETURN outside function.",0
str_div_zero        BYTE "Division by zero!",0
str_undef_var       BYTE "Undefined variable: ",0
str_loop_iter       BYTE "[TRACE] Loop iteration ",0
str_if_true         BYTE "[TRACE] IF condition: TRUE",0
str_if_false        BYTE "[TRACE] IF condition: FALSE",0
str_for_range       BYTE "[TRACE] FOR loop started.",0
str_while_check     BYTE "[TRACE] WHILE condition checked.",0
 
inputBuf            BYTE 256 DUP(0)
inputBufLen         DWORD 0
loopDepth           DWORD 0
funcDepth           DWORD 0
skipDepth           DWORD 0
str_true_kl         BYTE "true",0
str_false_kl        BYTE "false",0
dispBuf             BYTE 512 DUP(0)
; forVarName removed - now use varEntryPtr on stack (nested-loop safe)
numBuf              BYTE 32 DUP(0)
PUBLIC callArgVals
callArgVals         DWORD 8 DUP(0)
PUBLIC callArgTypes
callArgTypes        DWORD 8 DUP(0)
PUBLIC callArgCount
callArgCount        DWORD 0
PUBLIC savedFuncEntry
savedFuncEntry      DWORD 0
 
.code
 
PUBLIC RunExecutor
RunExecutor PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
    mov     tokenIndex, 0
    mov     execControl, EXEC_NORMAL
    mov     loopDepth, 0
    mov     funcDepth, 0
    mov     callDepth, 0
 
    mov     edx, OFFSET str_exec_start
    call    PrintInfo
 
    call    ExecStatementList
 
    mov     edx, OFFSET str_exec_done
    call    PrintInfo
 
    mov     eax, runtimeError
 
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
RunExecutor ENDP
 
PUBLIC ExecStatementList
ExecStatementList PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
_eslLoop:
    mov     eax, execControl
    cmp     eax, EXEC_NORMAL
    jne     _eslDone
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _eslDone
    cmp     eax, TOK_END
    je      _eslDone
    cmp     eax, TOK_ENDIF
    je      _eslDone
    cmp     eax, TOK_ENDWHILE
    je      _eslDone
    cmp     eax, TOK_ENDFOR
    je      _eslDone
    cmp     eax, TOK_ENDFUNC
    je      _eslDone
    cmp     eax, TOK_ELSE
    je      _eslDone
    cmp     eax, TOK_ELIF
    je      _eslDone
    cmp     eax, TOK_CASE
    je      _eslDone
    cmp     eax, TOK_DEFAULT
    je      _eslDone
    cmp     eax, TOK_ENDSWITCH
    je      _eslDone
 
    mov     eax, g_stepMode
    cmp     eax, 0
    je      _noStep
    call    ExecStepPause
_noStep:
    call    ExecStatement
    jmp     _eslLoop
 
_eslDone:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    xor     eax, eax
    ret
ExecStatementList ENDP
 
PUBLIC ExecStatement
ExecStatement PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
    call    ExecSkipNewlines
    call    ExecPeekType
 
    cmp     eax, TOK_SHOW
    je      _execShow
    cmp     eax, TOK_PRINT
    je      _execShow
    cmp     eax, TOK_SHOWL
    je      _execShowL
    cmp     eax, TOK_ASK
    je      _execAsk
    cmp     eax, TOK_INPUT
    je      _execAsk
    cmp     eax, TOK_SET
    je      _execSet
    cmp     eax, TOK_LET
    je      _execSet
    cmp     eax, TOK_VAR
    je      _execSet
    cmp     eax, TOK_CONST
    je      _execConst
    cmp     eax, TOK_IF
    je      _execIf
    cmp     eax, TOK_WHILE
    je      _execWhile
    cmp     eax, TOK_DO
    je      _execDoWhile
    cmp     eax, TOK_FOR
    je      _execFor
    cmp     eax, TOK_FUNC
    je      _execFuncDef
    cmp     eax, TOK_CALL
    je      _execCall
    cmp     eax, TOK_RETURN
    je      _execReturn
    cmp     eax, TOK_BREAK
    je      _execBreak
    cmp     eax, TOK_CONTINUE
    je      _execContinue
    cmp     eax, TOK_SWITCH
    je      _execSwitch
    cmp     eax, TOK_SHOW_VARS
    je      _execShowVars
    cmp     eax, TOK_DEBUG_ON
    je      _execDebugOn
    cmp     eax, TOK_DEBUG_OFF
    je      _execDebugOff
    cmp     eax, TOK_TRACE_ON
    je      _execTraceOn
    cmp     eax, TOK_TRACE_OFF
    je      _execTraceOff
    cmp     eax, TOK_PAUSE
    je      _execPause
    cmp     eax, TOK_CLEAR
    je      _execClear
    cmp     eax, TOK_WAIT
    je      _execWait
    cmp     eax, TOK_IDENT
    je      _execIdentStmt
 
    call    ExecConsumeToken
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; SHOW / PRINT (using WriteDec to avoid plus sign)
; ----------------------------------------------------------------------
_execShow:
    call    ExecConsumeToken
    call    ExecGetCurrentLine
    mov     currentLine, eax
 
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _showNoTrace
    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_exec_line
    call    WriteString
    mov     eax, currentLine
    call    WriteDec
    mov     edx, OFFSET str_exec_colon
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
_showNoTrace:
 
    call    ExecSkipNewlines
    call    ExecPeekType
 
    cmp     eax, TOK_INTEGER
    je      _showIntegerLiteral
    cmp     eax, TOK_STRING
    je      _showString
    cmp     eax, TOK_NEWLINE
    je      _showBlank
    cmp     eax, TOK_EOF
    je      _showBlank
 
    call    EvalExpression          ; EAX = value, EDX = type
 
    cmp     edx, VTYPE_STRING
    je      _showStrResult
    cmp     edx, VTYPE_BOOL
    je      _showBoolResult
    cmp     edx, VTYPE_CHAR
    je      _showCharResult
    cmp     edx, VTYPE_FLOAT
    je      _showFloatResult
 
    ; INTEGER
    push    eax
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    pop     eax
    call    WriteDec           ; no sign
    call    Crlf
    jmp     _execStmtDone
 
_showIntegerLiteral:
    call    ExecGetCurrentTokenPtr
    mov     eax, [esi + TOKEN_OFF_IVAL]
    push    eax
    call    ExecConsumeToken
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    pop     eax
    call    WriteDec
    call    Crlf
    jmp     _execStmtDone
 
_showString:
    call    ExecGetCurrentTokenPtr
    lea     edx, [esi + TOKEN_OFF_VALUE]
    call    ExecConsumeToken
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
    call    Crlf
    jmp     _execStmtDone
 
_showBlank:
    call    Crlf
    jmp     _execStmtDone

; ----------------------------------------------------------------------
; SHOWL - SHOW without newline (inline output)
; Usage: SHOWL "text"  or  SHOWL variable  or  SHOWL expression
; ----------------------------------------------------------------------
_execShowL:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType

    cmp     eax, TOK_INTEGER
    je      _showLIntLit
    cmp     eax, TOK_STRING
    je      _showLString
    cmp     eax, TOK_NEWLINE
    je      _showLBlank
    cmp     eax, TOK_EOF
    je      _showLBlank

    call    EvalExpression          ; EAX = value, EDX = type

    cmp     edx, VTYPE_STRING
    je      _showLStrResult
    cmp     edx, VTYPE_BOOL
    je      _showLBoolResult
    cmp     edx, VTYPE_CHAR
    je      _showLCharResult

    ; INTEGER - no newline
    push    eax
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    pop     eax
    call    WriteDec
    jmp     _execStmtDone

_showLIntLit:
    call    ExecGetCurrentTokenPtr
    mov     eax, [esi + TOKEN_OFF_IVAL]
    push    eax
    call    ExecConsumeToken
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    pop     eax
    call    WriteDec
    jmp     _execStmtDone

_showLString:
    call    ExecGetCurrentTokenPtr
    lea     edx, [esi + TOKEN_OFF_VALUE]
    call    ExecConsumeToken
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
    jmp     _execStmtDone

_showLBlank:
    jmp     _execStmtDone

_showLStrResult:
    mov     edx, eax
    call    WriteString
    jmp     _execStmtDone

_showLBoolResult:
    cmp     eax, 0
    je      _showLFalse
    mov     edx, OFFSET str_true_kl
    call    WriteString
    jmp     _execStmtDone
_showLFalse:
    mov     edx, OFFSET str_false_kl
    call    WriteString
    jmp     _execStmtDone

_showLCharResult:
    call    WriteChar
    jmp     _execStmtDone
 
_showStrResult:
    mov     edx, eax
    call    WriteString
    call    Crlf
    jmp     _execStmtDone
 
_showBoolResult:
    cmp     eax, 0
    je      _showFalse
    mov     edx, OFFSET str_true_kl
    call    WriteString
    call    Crlf
    jmp     _execStmtDone
_showFalse:
    mov     edx, OFFSET str_false_kl
    call    WriteString
    call    Crlf
    jmp     _execStmtDone
 
_showCharResult:
    call    WriteChar
    call    Crlf
    jmp     _execStmtDone
 
_showFloatResult:
    call    WriteDec
    call    Crlf
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; ASK / INPUT - now tries to convert input to integer
; ----------------------------------------------------------------------
_execAsk:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
 
    cmp     eax, TOK_STRING
    jne     _askNoPrompt
 
    call    ExecGetCurrentTokenPtr
    lea     edx, [esi + TOKEN_OFF_VALUE]
    call    ExecConsumeToken
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    call    WriteString
    mov     edx, OFFSET str_ask_prompt2
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    jmp     _askGetVar
 
_askNoPrompt:
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_ask_prompt
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_askGetVar:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_IDENT
    jne     _execStmtDone
 
    ; Copy variable name to execNameBuf (safe)
    call    ExecGetCurrentTokenPtr
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    call    ExecConsumeToken
 
    ; Trim trailing spaces
    mov     edi, OFFSET execNameBuf
    push    edi
    call    StrLen_KL
    pop     edi
    cmp     eax, 0
    je      _askTrimDone
    mov     ecx, eax
    add     edi, eax
    dec     edi
_askTrimLoop:
    cmp     ecx, 0
    je      _askTrimDone
    mov     al, [edi]
    cmp     al, ' '
    je      _askTrimChar
    cmp     al, 13
    je      _askTrimChar
    cmp     al, 10
    je      _askTrimChar
    cmp     al, 9
    je      _askTrimChar
    jmp     _askTrimDone
_askTrimChar:
    mov     BYTE PTR [edi], 0
    dec     edi
    dec     ecx
    jmp     _askTrimLoop
_askTrimDone:
 
    ; Read input
    mov     edx, OFFSET inputBuf
    mov     ecx, 255
    call    ReadString
    mov     inputBufLen, eax
 
    ; Try to convert input to integer
    mov     esi, OFFSET inputBuf
    call    StrToInt_KL       ; EAX = integer value, CF? Not using CF, assume conversion works
    cmp     eax, 0
    je      _checkIfZero
    ; Non-zero => probably an integer, but could be "0"
    ; For now, store as integer
    mov     esi, OFFSET execNameBuf
    call    SetVarInt
    jmp     _askStoreDone
_checkIfZero:
    ; Could be actual "0" or non-numeric string. Check first char
    mov     al, inputBuf
    cmp     al, '0'
    je      _storeAsIntZero
    ; Otherwise store as string
    mov     esi, OFFSET execNameBuf
    mov     edi, OFFSET inputBuf
    call    SetVarString
    jmp     _askStoreDone
_storeAsIntZero:
    mov     esi, OFFSET execNameBuf
    xor     eax, eax
    call    SetVarInt
 
_askStoreDone:
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; SET / LET / VAR (unchanged but uses execNameBuf)
; ----------------------------------------------------------------------
_execSet:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_IDENT
    jne     _execStmtDone
 
    call    ExecGetCurrentTokenPtr
    push    esi
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     esi
    call    ExecConsumeToken
 
    call    ExecSkipNewlines
    call    ExecPeekType
 
    cmp     eax, TOK_ASSIGN
    je      _setDoAssign
    cmp     eax, TOK_PLUS_ASSIGN
    je      _setCompound
    cmp     eax, TOK_MINUS_ASSIGN
    je      _setCompound
    cmp     eax, TOK_MUL_ASSIGN
    je      _setCompound
    cmp     eax, TOK_DIV_ASSIGN
    je      _setCompound
 
    mov     esi, OFFSET execNameBuf
    xor     eax, eax
    call    SetVarInt
    jmp     _execStmtDone
 
_setDoAssign:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_STRING
    je      _setString
 
    call    EvalExpression
 
    cmp     edx, VTYPE_STRING
    je      _setStrResult
    cmp     edx, VTYPE_BOOL
    je      _setBoolResult
    cmp     edx, VTYPE_CHAR
    je      _setCharResult
 
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt
    jmp     _execStmtDone
 
_setCharResult:
    ; Store char as integer (char code) so SHOW prints it correctly
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt
    jmp     _execStmtDone
 
_setBoolResult:
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarBool
    jmp     _execStmtDone
 
_setStrResult:
    mov     esi, OFFSET execNameBuf
    mov     edi, eax
    call    SetVarString
    jmp     _execStmtDone
 
_setString:
    call    ExecGetCurrentTokenPtr
    lea     ecx, [esi + TOKEN_OFF_VALUE]
    call    ExecConsumeToken
    mov     esi, OFFSET execNameBuf
    mov     edi, ecx
    call    SetVarString
    jmp     _execStmtDone
 
_setCompound:
    push    eax
    call    ExecConsumeToken
    pop     ebx
    push    ebx
    mov     esi, OFFSET execNameBuf
    call    GetVarInt
    pop     ebx
    push    eax
    call    EvalExpression
    pop     ecx
    cmp     ebx, TOK_PLUS_ASSIGN
    je      _compAdd
    cmp     ebx, TOK_MINUS_ASSIGN
    je      _compSub
    cmp     ebx, TOK_MUL_ASSIGN
    je      _compMul
    cmp     ebx, TOK_DIV_ASSIGN
    je      _compDiv
    jmp     _execStmtDone
_compAdd: add eax, ecx
    jmp _compStore
_compSub: sub ecx, eax
    mov eax, ecx
    jmp _compStore
_compMul: imul eax, ecx
    jmp _compStore
_compDiv:
    cmp eax, 0
    je  _compDivZero
    push edx
    push eax
    xor edx, edx
    mov eax, ecx
    pop ecx
    idiv ecx
    pop edx
    jmp _compStore
_compDivZero:
    mov edx, OFFSET str_div_zero
    xor ebx, ebx
    call PrintError
    jmp _execStmtDone
_compStore:
    push eax
    mov esi, OFFSET execNameBuf
    pop eax
    call SetVarInt
    jmp _execStmtDone
 
; ----------------------------------------------------------------------
; CONST
; ----------------------------------------------------------------------
_execConst:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_IDENT
    jne     _execStmtDone
    call    ExecGetCurrentTokenPtr
    push    esi
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     esi
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ASSIGN
    jne     _execStmtDone
    call    ExecConsumeToken
    call    EvalExpression          ; EAX = value, EDX = type
    push    eax                     ; save value  (push 1)
    push    edx                     ; save type   (push 2)
    mov     esi, OFFSET execNameBuf
    mov     ebx, VTYPE_INTEGER
    call    FindVariable
    cmp     eax, 0
    jne     _constFound
    mov     ebx, VTYPE_INTEGER
    call    CreateVariable
_constFound:
    ; BUG FIX: EAX = pointer from FindVariable/CreateVariable
    ; Save pointer NOW before popping the stack!
    mov     edi, eax                ; EDI = entry pointer (CORRECT!)
    cmp     edi, 0
    je      _execStmtDone           ; safety: NULL pointer guard
    pop     edx                     ; restore type  (pop push 2)
    pop     eax                     ; restore value (pop push 1)
    mov     BYTE PTR [edi + VAR_OFF_ISCONST], 1
    ; Check type: string vs integer/bool
    cmp     edx, VTYPE_STRING
    je      _constStoreStr
    cmp     edx, VTYPE_BOOL
    je      _constStoreBool
    ; Integer path
    mov     [edi + VAR_OFF_IVAL], eax
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_INTEGER
    jmp     _execStmtDone
_constStoreBool:
    mov     BYTE PTR [edi + VAR_OFF_BVAL], al
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_BOOL
    jmp     _execStmtDone
_constStoreStr:
    ; EAX = pointer to string (from EvalExpression -> _primString)
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_STRING
    ; Copy string into sval field
    push    esi
    push    edi
    push    ecx
    mov     esi, eax                    ; src = string pointer from eval
    lea     edi, [edi + VAR_OFF_SVAL]  ; dst = sval field
    mov     ecx, MAX_STRING_LEN - 1
_constStrCopy:
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _constStrDone
    inc     esi
    inc     edi
    dec     ecx
    jnz     _constStrCopy
_constStrDone:
    mov     BYTE PTR [edi], 0
    pop     ecx
    pop     edi
    pop     esi
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; IF / ELIF / ELSE / END
; ----------------------------------------------------------------------
_execIf:
    call    ExecConsumeToken
    call    EvalExpression
    push    eax
    call    ExecSkipToThen
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _ifNoTrace
    pop     eax
    push    eax
    cmp     eax, 0
    je      _ifTraceF
    mov     edx, OFFSET str_if_true
    call    PrintTrace
    jmp     _ifNoTrace
_ifTraceF:
    mov     edx, OFFSET str_if_false
    call    PrintTrace
_ifNoTrace:
    pop     eax
    cmp     eax, 0
    je      _ifFalse
_ifTrue:
    call    ExecStatementList
    call    ExecSkipElseBlocks
    jmp     _execStmtDone
_ifFalse:
    call    ExecSkipBlock
_checkElifElse:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ELIF
    je      _doElif
    cmp     eax, TOK_ELSE
    je      _doElse
    cmp     eax, TOK_END
    je      _consumeEnd
    cmp     eax, TOK_ENDIF
    je      _consumeEnd
    jmp     _execStmtDone
_doElif:
    call    ExecConsumeToken
    call    EvalExpression
    push    eax
    call    ExecSkipToThen
    pop     eax
    cmp     eax, 0
    je      _elifFalse
    call    ExecStatementList
    call    ExecSkipElseBlocks
    jmp     _execStmtDone
_elifFalse:
    call    ExecSkipBlock
    jmp     _checkElifElse
_doElse:
    call    ExecConsumeToken
    call    ExecStatementList
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_END
    je      _consumeEnd
    cmp     eax, TOK_ENDIF
    je      _consumeEnd
    jmp     _execStmtDone
_consumeEnd:
    call    ExecConsumeToken
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; WHILE loop
; ----------------------------------------------------------------------
_execWhile:
    mov     eax, tokenIndex
    push    eax
    call    ExecConsumeToken
    inc     loopDepth
_whileCheck:
    mov     eax, tokenIndex
    push    eax
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _whileNoTrace
    mov     edx, OFFSET str_while_check
    call    PrintTrace
_whileNoTrace:
    call    EvalExpression
    push    eax
    call    ExecSkipToDo
    pop     eax
    pop     ecx
    cmp     eax, 0
    je      _whileExit
    call    ExecStatementList
    mov     eax, execControl
    cmp     eax, EXEC_BREAK
    je      _whileBreak
    cmp     eax, EXEC_RETURN
    je      _whileReturn
    cmp     eax, EXEC_CONTINUE
    je      _whileContinue
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ENDWHILE
    je      _whileEndConsume
    cmp     eax, TOK_END
    je      _whileEndConsume
    jmp     _whileLoop
_whileEndConsume:
    call    ExecConsumeToken
_whileContinue:
    mov     execControl, EXEC_NORMAL
_whileLoop:
    pop     ecx
    mov     tokenIndex, ecx
    call    ExecConsumeToken
    push    ecx
    jmp     _whileCheck
_whileBreak:
    mov     execControl, EXEC_NORMAL
    call    ExecSkipToEndWhile
    jmp     _whileDone
_whileReturn:
    jmp     _whileDone
_whileExit:
    call    ExecSkipToEndWhile
_whileDone:
    dec     loopDepth
    pop     eax
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; DO ... WHILE loop
; Syntax: DO <newline> <body statements> <newline> WHILE <condition>
;
; KEY INSIGHT: We cannot use ExecStatementList for the body because
; ExecStatementList does NOT stop on TOK_WHILE - it would dispatch
; WHILE as a new nested WHILE loop, eating the rest of the program!
;
; Solution: scan tokens manually. On each iteration:
;   1. Save bodyStart (token after DO)
;   2. Call ExecDoWhileBody which runs statements one-by-one,
;      stopping as soon as it peeks TOK_WHILE (without consuming it)
;   3. Consume WHILE, evaluate condition
;   4. If true -> restore tokenIndex = bodyStart, repeat
;   5. If false -> skip condition tokens, done
; ----------------------------------------------------------------------
_execDoWhile:
    call    ExecConsumeToken            ; consume DO keyword
    inc     loopDepth
    call    ExecSkipNewlines            ; skip newline(s) after DO
    mov     eax, tokenIndex
    push    eax                         ; [esp] = bodyStart (first stmt token)
 
_doWhileIteration:
    ; Reset to body start
    mov     eax, [esp]
    mov     tokenIndex, eax
 
_doWhileRunStmt:
    ; Run statements one at a time, checking for WHILE before each
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _doWhileExit
    cmp     eax, TOK_WHILE
    je      _doWhileCheckCond           ; body done, check condition
    ; Not WHILE - run one statement
    call    ExecStatement
    ; Check control flow after each statement
    mov     eax, execControl
    cmp     eax, EXEC_BREAK
    je      _doWhileBreak
    cmp     eax, EXEC_RETURN
    je      _doWhileReturn
    cmp     eax, EXEC_CONTINUE
    je      _doWhileContinue
    jmp     _doWhileRunStmt
 
_doWhileCheckCond:
    ; Current token = WHILE, consume it and evaluate condition
    call    ExecConsumeToken            ; consume WHILE
    call    EvalExpression              ; EAX = condition result
    cmp     eax, 0
    jne     _doWhileIteration           ; true -> loop again from bodyStart
    jmp     _doWhileExit                ; false -> done
 
_doWhileContinue:
    mov     execControl, EXEC_NORMAL
    ; Scan forward to WHILE (skip rest of body)
_doWhileContScan:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _doWhileExit
    cmp     eax, TOK_WHILE
    je      _doWhileCheckCond
    call    ExecConsumeToken
    jmp     _doWhileContScan
 
_doWhileBreak:
    mov     execControl, EXEC_NORMAL
    ; Scan forward past WHILE and its condition
_doWhileBreakScan:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _doWhileExit
    cmp     eax, TOK_WHILE
    je      _doWhileBreakCond
    call    ExecConsumeToken
    jmp     _doWhileBreakScan
_doWhileBreakCond:
    call    ExecConsumeToken            ; consume WHILE
    ; skip condition tokens until newline/EOF
_doWhileBreakSkipCond:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _doWhileExit
    cmp     eax, TOK_NEWLINE
    je      _doWhileExit
    call    ExecConsumeToken
    jmp     _doWhileBreakSkipCond
 
_doWhileReturn:
_doWhileExit:
    dec     loopDepth
    pop     eax                         ; discard bodyStart
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; FOR loop (simplified but works)
; ----------------------------------------------------------------------
_execFor:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_IDENT
    jne     _execStmtDone
    call    ExecGetCurrentTokenPtr
    push    esi
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     esi
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ASSIGN
    jne     _execStmtDone
    call    ExecConsumeToken
    call    EvalExpression
    push    eax                         ; save startVal temporarily
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt                   ; set loop var = startVal
    ; Get entry pointer for loop var (avoids global forVarName being clobbered
    ; by nested loops or SET statements inside the body)
    push    ecx
    mov     ebx, VTYPE_INTEGER
    mov     esi, OFFSET execNameBuf
    call    FindVariable
    pop     ecx
    ; EAX = var entry ptr (or 0 if not found, but SetVarInt just created it)
    pop     ecx                         ; discard startVal - replace with entryPtr
    push    eax                         ; [stack base] = varEntryPtr
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_TO
    jne     _execStmtDone
    call    ExecConsumeToken
    call    EvalExpression
    push    eax                         ; push limit
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_STEP
    je      _forHasStep
    mov     eax, 1
    jmp     _forGotStep
_forHasStep:
    call    ExecConsumeToken
    call    EvalExpression
_forGotStep:
    push    eax                         ; push step
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_DO
    jne     _forSkipDo
    call    ExecConsumeToken
_forSkipDo:
    mov     eax, tokenIndex
    push    eax                         ; push bodyStart
    inc     loopDepth
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _forNoTrace
    mov     edx, OFFSET str_for_range
    call    PrintTrace
_forNoTrace:
_forLoopBody:
    ; BUGFIX: use varEntryPtr from stack (nested-loop safe, not clobbered by body)
    ; Stack: [esp+0]=bodyStart [esp+4]=step [esp+8]=limit [esp+12]=varEntryPtr
    mov     esi, [esp + 12]             ; esi = varEntryPtr
    mov     eax, [esi + VAR_OFF_IVAL]  ; eax = current loop var value
    push    eax                         ; push curVal
    ; Stack: [esp+0]=curVal [esp+4]=bodyStart [esp+8]=step [esp+12]=limit [esp+16]=varEntryPtr
    mov     ecx, [esp + 12]             ; limit
    mov     ebx, [esp + 8]              ; step
    cmp     ebx, 0
    jge     _forPosStep
    cmp     eax, ecx
    jl      _forLoopDone
    jmp     _forRunBody
_forPosStep:
    cmp     eax, ecx
    jg      _forLoopDone
_forRunBody:
    pop     eax
    call    ExecStatementList
    mov     eax, execControl
    cmp     eax, EXEC_BREAK
    je      _forBreak
    cmp     eax, EXEC_RETURN
    je      _forReturn
    cmp     eax, EXEC_CONTINUE
    je      _forContinue
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ENDFOR
    je      _forEndConsume
    cmp     eax, TOK_END
    je      _forEndConsume
    jmp     _forIncrement
_forEndConsume:
    call    ExecConsumeToken
_forContinue:
    mov     execControl, EXEC_NORMAL
_forIncrement:
    ; Stack: [esp+0]=bodyStart [esp+4]=step [esp+8]=limit [esp+12]=varEntryPtr
    ; BUGFIX: use varEntryPtr directly (nested-loop safe)
    mov     esi, [esp + 12]             ; esi = varEntryPtr
    mov     eax, [esi + VAR_OFF_IVAL]  ; read current value
    mov     ecx, [esp + 4]              ; step
    add     eax, ecx                    ; new value = current + step
    mov     [esi + VAR_OFF_IVAL], eax  ; write directly to symtable entry
    mov     eax, [esp]                  ; bodyStart
    mov     tokenIndex, eax
    jmp     _forLoopBody
_forLoopDone:
    pop     eax
    call    ExecSkipToEndFor
    jmp     _forDone
_forBreak:
    mov     execControl, EXEC_NORMAL
    call    ExecSkipToEndFor
    jmp     _forDone
_forReturn:
    jmp     _forDone
_forDone:
    dec     loopDepth
    add     esp, 16
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; FUNC definition (skip)
; ----------------------------------------------------------------------
_execFuncDef:
    call    ExecSkipFuncDef
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; CALL
; ----------------------------------------------------------------------
_execCall:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_IDENT
    jne     _execStmtDone
    call    ExecGetCurrentTokenPtr
    push    esi
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     esi
    call    ExecConsumeToken
 
    ; Reset arg count
    mov     callArgCount, 0
 
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_LPAREN
    jne     _callNoParens
    call    ExecConsumeToken    ; consume (
 
    ; Evaluate each argument
_callArgLoop:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_RPAREN
    je      _callArgsDone
    cmp     eax, TOK_EOF
    je      _callArgsDone
    cmp     eax, TOK_NEWLINE
    je      _callArgsDone
 
    ; Evaluate argument expression
    call    EvalExpression      ; EAX = value, EDX = type
 
    ; Store in callArgVals/Types
    mov     ecx, callArgCount
    cmp     ecx, 8
    jge     _callArgSkip
    mov     [OFFSET callArgVals + ecx*4], eax
    mov     [OFFSET callArgTypes + ecx*4], edx
    inc     callArgCount
_callArgSkip:
    ; Skip comma if present
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_COMMA
    jne     _callArgLoop
    call    ExecConsumeToken
    jmp     _callArgLoop
 
_callArgsDone:
    call    ExecPeekType
    cmp     eax, TOK_RPAREN
    jne     _callNoParens
    call    ExecConsumeToken    ; consume )
 
_callNoParens:
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _callNoTrace
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_func_call
    call    WriteString
    mov     edx, OFFSET execNameBuf
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
_callNoTrace:
    call    ExecFindFunction
    cmp     eax, 0
    je      _callNotFound
    mov     savedFuncEntry, eax     ; save funcTable entry ptr
    call    ExecCallFunction
    jmp     _execStmtDone
_callNotFound:
    mov     eax, LIGHTRED_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_func_notfound
    call    WriteString
    mov     edx, OFFSET execNameBuf
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; RETURN, BREAK, CONTINUE, SWITCH etc.
; ----------------------------------------------------------------------
_execReturn:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_NEWLINE
    je      _retNoVal
    cmp     eax, TOK_EOF
    je      _retNoVal
    cmp     eax, TOK_ENDFUNC
    je      _retNoVal
    call    EvalExpression
    mov     returnValInt, eax
    mov     returnValType, edx
    jmp     _retDone
_retNoVal:
    mov     returnValInt, 0
    mov     returnValType, VTYPE_INTEGER
_retDone:
    mov     execControl, EXEC_RETURN
    jmp     _execStmtDone
 
_execBreak:
    call    ExecConsumeToken
    mov     eax, loopDepth
    cmp     eax, 0
    je      _breakOutside
    mov     execControl, EXEC_BREAK
    jmp     _execStmtDone
_breakOutside:
    mov     edx, OFFSET str_break_out
    xor     ebx, ebx
    call    PrintError
    jmp     _execStmtDone
 
_execContinue:
    call    ExecConsumeToken
    mov     eax, loopDepth
    cmp     eax, 0
    je      _contOutside
    mov     execControl, EXEC_CONTINUE
    jmp     _execStmtDone
_contOutside:
    mov     edx, OFFSET str_cont_out
    xor     ebx, ebx
    call    PrintError
    jmp     _execStmtDone
 
_execSwitch:
    call    ExecConsumeToken
    call    EvalExpression
    push    eax
    call    ExecSkipNewlines
_switchLoop:
    call    ExecPeekType
    cmp     eax, TOK_CASE
    je      _doCase
    cmp     eax, TOK_DEFAULT
    je      _doDefault
    cmp     eax, TOK_ENDSWITCH
    je      _switchEnd
    cmp     eax, TOK_END
    je      _switchEnd
    cmp     eax, TOK_EOF
    je      _switchEnd
    call    ExecConsumeToken
    jmp     _switchLoop
_doCase:
    call    ExecConsumeToken
    call    EvalExpression
    push    eax
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_COLON
    jne     _caseNoColon
    call    ExecConsumeToken
_caseNoColon:
    pop     eax
    mov     ecx, [esp]
    cmp     eax, ecx
    je      _caseMatch
    call    ExecSkipCaseBlock
    jmp     _switchLoop
_caseMatch:
    call    ExecStatementList
    call    ExecSkipToEndSwitch
    jmp     _switchDone
_doDefault:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_COLON
    jne     _defNoColon
    call    ExecConsumeToken
_defNoColon:
    call    ExecStatementList
    jmp     _switchDone
_switchEnd:
    call    ExecConsumeToken
_switchDone:
    pop     eax
    jmp     _execStmtDone
 
_execShowVars:
    call    ExecConsumeToken
    call    ShowSymbolTable
    jmp     _execStmtDone
 
_execDebugOn:
    call    ExecConsumeToken
    mov     g_debugMode, 1
    jmp     _execStmtDone
_execDebugOff:
    call    ExecConsumeToken
    mov     g_debugMode, 0
    jmp     _execStmtDone
_execTraceOn:
    call    ExecConsumeToken
    mov     g_traceMode, 1
    jmp     _execStmtDone
_execTraceOff:
    call    ExecConsumeToken
    mov     g_traceMode, 0
    jmp     _execStmtDone
_execPause:
    call    ExecConsumeToken
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_step_prompt
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    call    ReadChar
    call    Crlf
    jmp     _execStmtDone
_execClear:
    call    ExecConsumeToken
    call    Clrscr
    jmp     _execStmtDone
_execWait:
    call    ExecConsumeToken
    call    EvalExpression
    call    Delay
    jmp     _execStmtDone
 
; ----------------------------------------------------------------------
; Identifier statement (assignment without SET)
; ----------------------------------------------------------------------
_execIdentStmt:
    call    ExecGetCurrentTokenPtr
    push    esi
    lea     esi, [esi + TOKEN_OFF_VALUE]
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     esi
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ASSIGN
    je      _identAssign
    cmp     eax, TOK_PLUS_ASSIGN
    je      _identCompound
    cmp     eax, TOK_MINUS_ASSIGN
    je      _identCompound
    cmp     eax, TOK_MUL_ASSIGN
    je      _identCompound
    cmp     eax, TOK_DIV_ASSIGN
    je      _identCompound
    cmp     eax, TOK_INCREMENT
    je      _identIncr
    cmp     eax, TOK_DECREMENT
    je      _identDecr
    cmp     eax, TOK_LPAREN
    je      _identFuncCall
    jmp     _execStmtDone
 
_identAssign:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_STRING
    je      _identStrAssign
    call    EvalExpression
    cmp     edx, VTYPE_STRING
    je      _identSetStr
    cmp     edx, VTYPE_BOOL
    je      _identSetBool
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt
    jmp     _execStmtDone
_identSetStr:
    mov     esi, OFFSET execNameBuf
    mov     edi, eax
    call    SetVarString
    jmp     _execStmtDone
_identSetBool:
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarBool
    jmp     _execStmtDone
_identStrAssign:
    call    ExecGetCurrentTokenPtr
    lea     ecx, [esi + TOKEN_OFF_VALUE]
    call    ExecConsumeToken
    mov     esi, OFFSET execNameBuf
    mov     edi, ecx
    call    SetVarString
    jmp     _execStmtDone
 
_identCompound:
    push    eax
    call    ExecConsumeToken
    pop     ebx
    push    ebx
    mov     esi, OFFSET execNameBuf
    call    GetVarInt
    pop     ebx
    push    eax
    call    EvalExpression
    pop     ecx
    cmp     ebx, TOK_PLUS_ASSIGN
    je      _icAdd
    cmp     ebx, TOK_MINUS_ASSIGN
    je      _icSub
    cmp     ebx, TOK_MUL_ASSIGN
    je      _icMul
    cmp     ebx, TOK_DIV_ASSIGN
    je      _icDiv
    jmp     _execStmtDone
_icAdd: add eax, ecx
    jmp _icStore
_icSub: sub ecx, eax
    mov eax, ecx
    jmp _icStore
_icMul: imul eax, ecx
    jmp _icStore
_icDiv:
    cmp eax, 0
    je  _execStmtDone
    push edx
    push eax
    xor edx, edx
    mov eax, ecx
    pop ecx
    idiv ecx
    pop edx
_icStore:
    push eax
    mov esi, OFFSET execNameBuf
    pop eax
    call SetVarInt
    jmp _execStmtDone
 
_identIncr:
    call    ExecConsumeToken
    mov     esi, OFFSET execNameBuf
    call    GetVarInt
    inc     eax
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt
    jmp     _execStmtDone
 
_identDecr:
    call    ExecConsumeToken
    mov     esi, OFFSET execNameBuf
    call    GetVarInt
    dec     eax
    push    eax
    mov     esi, OFFSET execNameBuf
    pop     eax
    call    SetVarInt
    jmp     _execStmtDone
 
_identFuncCall:
    call    ExecFindFunction
    cmp     eax, 0
    je      _ifcSkip
    call    ExecCallFunction
    jmp     _execStmtDone
_ifcSkip:
    call    ExecConsumeToken
    call    ExecSkipToRParen
    jmp     _execStmtDone
 
_execStmtDone:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    xor     eax, eax
    ret
ExecStatement ENDP
 
; ============================================================
; Helper functions
; ============================================================
 
PUBLIC ExecFindFunction
ExecFindFunction PROC
    push    ecx
    push    esi
    push    edi
    mov     ecx, 0
_fffLoop:
    cmp     ecx, funcCount
    jge     _fffNotFound
    push    ecx
    mov     eax, FUNC_SIZE
    imul    eax, ecx
    mov     edi, OFFSET funcTable
    add     edi, eax
    mov     esi, OFFSET execNameBuf
    call    StrCompare_KL
    pop     ecx
    cmp     eax, 0
    je      _fffFound
    inc     ecx
    jmp     _fffLoop
_fffFound:
    mov     eax, FUNC_SIZE
    imul    eax, ecx
    mov     edi, OFFSET funcTable
    add     edi, eax
    mov     eax, edi
    jmp     _fffDone
_fffNotFound:
    xor     eax, eax
_fffDone:
    pop     edi
    pop     esi
    pop     ecx
    ret
ExecFindFunction ENDP
 
PUBLIC ExecCallFunction
ExecCallFunction PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
    mov     ecx, callDepth
    cmp     ecx, MAX_CALL_STACK
    jge     _ecfTooDeep
 
    ; Save current token index
    mov     eax, tokenIndex
    mov     ebx, callDepth
    mov     [OFFSET callStack + ebx*4], eax
    inc     callDepth
    inc     funcDepth
    inc     loopDepth
 
    ; Jump to function body
    mov     esi, savedFuncEntry     ; esi = funcTable entry
    mov     eax, [esi + FUNC_OFF_TOKSTART]
    mov     tokenIndex, eax
 
    ; Bind parameters to argument values
    ; esi = funcTable entry, FUNC_OFF_PARAMCOUNT = param count
    ; FUNC_OFF_PARAMS = param names (16 bytes each)
    ; callArgVals/callArgTypes = evaluated argument values
    mov     ecx, [esi + FUNC_OFF_PARAMCOUNT]
    cmp     ecx, 0
    je      _ecfNoParams
    mov     ebx, 0          ; arg index
_ecfParamLoop:
    cmp     ebx, ecx
    jge     _ecfNoParams
    cmp     ebx, callArgCount
    jge     _ecfNoParams
 
    ; Get param name: FUNC_OFF_PARAMS + ebx*16
    push    ecx
    push    ebx
    push    esi                     ; save funcTable entry
    mov     eax, ebx
    imul    eax, 16
    ; param name ptr = funcTable + FUNC_OFF_PARAMS + eax
    mov     edi, esi                ; edi = funcTable entry
    add     edi, FUNC_OFF_PARAMS
    add     edi, eax                ; edi = param name string
 
    ; Get arg value and type
    mov     eax, [OFFSET callArgVals + ebx*4]
    mov     edx, [OFFSET callArgTypes + ebx*4]
 
    ; esi = param name, eax = value, edx = type
    mov     esi, edi
 
    cmp     edx, VTYPE_STRING
    je      _ecfParamStr
    call    SetVarInt
    jmp     _ecfParamNext
_ecfParamStr:
    mov     edi, eax
    call    SetVarString
_ecfParamNext:
    pop     esi                     ; restore funcTable entry
    pop     ebx
    pop     ecx
    inc     ebx
    jmp     _ecfParamLoop
_ecfNoParams:
 
    mov     execControl, EXEC_NORMAL
    call    ExecStatementList
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ENDFUNC
    jne     _ecfNoEnd
    call    ExecConsumeToken
_ecfNoEnd:
    mov     eax, execControl
    cmp     eax, EXEC_RETURN
    jne     _ecfNoReturn
    mov     execControl, EXEC_NORMAL
_ecfNoReturn:
    dec     callDepth
    dec     funcDepth
    dec     loopDepth
    mov     ebx, callDepth
    mov     eax, [OFFSET callStack + ebx*4]
    mov     tokenIndex, eax
    mov     eax, g_traceMode
    cmp     eax, 0
    je      _ecfDone
    mov     edx, OFFSET str_func_ret
    call    PrintTrace
_ecfDone:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
_ecfTooDeep:
    mov     edx, OFFSET str_too_deep
    xor     ebx, ebx
    call    PrintError
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
ExecCallFunction ENDP
 
; Navigation helpers
ExecPeekType PROC
    push    esi             ; SAVE ESI - callers depend on ESI not being corrupted
    push    ecx
    mov     eax, TOKEN_SIZE
    mov     ecx, tokenIndex
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    pop     esi             ; RESTORE ESI - caller's ESI is preserved
    ret
ExecPeekType ENDP
 
PUBLIC ExecConsumeToken
ExecConsumeToken PROC
    push    eax
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _ectEOF
    inc     tokenIndex
_ectEOF:
    pop     eax
    ret
ExecConsumeToken ENDP
 
ExecGetCurrentTokenPtr PROC
    push    ecx
    mov     eax, TOKEN_SIZE
    mov     ecx, tokenIndex
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    pop     ecx
    ret
ExecGetCurrentTokenPtr ENDP
 
ExecSkipNewlines PROC
_esnLoop:
    call    ExecPeekType
    cmp     eax, TOK_NEWLINE
    jne     _esnDone
    call    ExecConsumeToken
    jmp     _esnLoop
_esnDone:
    ret
ExecSkipNewlines ENDP
 
ExecGetCurrentLine PROC
    push    ecx
    mov     eax, TOKEN_SIZE
    mov     ecx, tokenIndex
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_LINE]
    pop     ecx
    ret
ExecGetCurrentLine ENDP
 
ExecSkipToThen PROC
    push    eax
_sttLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _sttDone
    cmp     eax, TOK_NEWLINE
    je      _sttDone
    cmp     eax, TOK_THEN
    je      _sttConsumeThen
    call    ExecConsumeToken
    jmp     _sttLoop
_sttConsumeThen:
    call    ExecConsumeToken
_sttDone:
    pop     eax
    ret
ExecSkipToThen ENDP
 
ExecSkipToDo PROC
    push    eax
_stdLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _stdDone
    cmp     eax, TOK_NEWLINE
    je      _stdDone
    cmp     eax, TOK_DO
    je      _stdConsume
    call    ExecConsumeToken
    jmp     _stdLoop
_stdConsume:
    call    ExecConsumeToken
_stdDone:
    pop     eax
    ret
ExecSkipToDo ENDP
 
ExecSkipBlock PROC
    push    eax
    push    ecx
    mov     ecx, 0
_sbLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _sbDone
    cmp     eax, TOK_IF
    je      _sbNest
    cmp     eax, TOK_WHILE
    je      _sbNest
    cmp     eax, TOK_FOR
    je      _sbNest
    cmp     eax, TOK_FUNC
    je      _sbNest
    cmp     eax, TOK_END
    je      _sbUnNest
    cmp     eax, TOK_ENDIF
    je      _sbUnNest
    cmp     eax, TOK_ENDWHILE
    je      _sbUnNest
    cmp     eax, TOK_ENDFOR
    je      _sbUnNest
    cmp     eax, TOK_ENDFUNC
    je      _sbUnNest
    cmp     ecx, 0
    jne     _sbContinue
    cmp     eax, TOK_ELSE
    je      _sbDone
    cmp     eax, TOK_ELIF
    je      _sbDone
_sbContinue:
    call    ExecConsumeToken
    jmp     _sbLoop
_sbNest:
    inc     ecx
    call    ExecConsumeToken
    jmp     _sbLoop
_sbUnNest:
    cmp     ecx, 0
    je      _sbDone
    dec     ecx
    call    ExecConsumeToken
    jmp     _sbLoop
_sbDone:
    pop     ecx
    pop     eax
    ret
ExecSkipBlock ENDP
 
ExecSkipElseBlocks PROC
    push    eax
    push    ecx
_sebLoop:
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_ELIF
    je      _sebSkipBlock
    cmp     eax, TOK_ELSE
    je      _sebSkipBlock
    cmp     eax, TOK_END
    je      _sebConsume
    cmp     eax, TOK_ENDIF
    je      _sebConsume
    jmp     _sebDone
_sebSkipBlock:
    call    ExecConsumeToken
    call    ExecSkipNewlines
    call    ExecPeekType
    cmp     eax, TOK_THEN
    jne     _sebSkipBody
    call    ExecConsumeToken
_sebSkipBody:
    call    ExecSkipBlock
    jmp     _sebLoop
_sebConsume:
    call    ExecConsumeToken
_sebDone:
    pop     ecx
    pop     eax
    ret
ExecSkipElseBlocks ENDP
 
ExecSkipToEndWhile PROC
    push    eax
    push    ecx
    mov     ecx, 0
_stewLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _stewDone
    cmp     eax, TOK_WHILE
    je      _stewNest
    cmp     eax, TOK_FOR
    je      _stewNest
    cmp     eax, TOK_IF
    je      _stewNest
    cmp     eax, TOK_FUNC
    je      _stewNest
    cmp     eax, TOK_ENDWHILE
    je      _stewEnd
    cmp     eax, TOK_ENDFOR
    je      _stewUnNest
    cmp     eax, TOK_ENDIF
    je      _stewUnNest
    cmp     eax, TOK_ENDFUNC
    je      _stewUnNest
    cmp     eax, TOK_END
    je      _stewMaybeEnd
    call    ExecConsumeToken
    jmp     _stewLoop
_stewNest:
    inc     ecx
    call    ExecConsumeToken
    jmp     _stewLoop
_stewUnNest:
    cmp     ecx, 0
    je      _stewDone
    dec     ecx
    call    ExecConsumeToken
    jmp     _stewLoop
_stewEnd:
    cmp     ecx, 0
    jne     _stewUnNestCont
    call    ExecConsumeToken
    jmp     _stewDone
_stewUnNestCont:
    dec     ecx
    call    ExecConsumeToken
    jmp     _stewLoop
_stewMaybeEnd:
    cmp     ecx, 0
    jne     _stewUnNest
    call    ExecConsumeToken
    jmp     _stewDone
_stewDone:
    pop     ecx
    pop     eax
    ret
ExecSkipToEndWhile ENDP
 
ExecSkipToEndFor PROC
    push    eax
    push    ecx
    mov     ecx, 0
_stefLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _stefDone
    cmp     eax, TOK_FOR
    je      _stefNest
    cmp     eax, TOK_WHILE
    je      _stefNest
    cmp     eax, TOK_IF
    je      _stefNest
    cmp     eax, TOK_FUNC
    je      _stefNest
    cmp     eax, TOK_ENDFOR
    je      _stefEnd
    cmp     eax, TOK_ENDWHILE
    je      _stefUnNest
    cmp     eax, TOK_ENDIF
    je      _stefUnNest
    cmp     eax, TOK_ENDFUNC
    je      _stefUnNest
    cmp     eax, TOK_END
    je      _stefMaybeEnd
    call    ExecConsumeToken
    jmp     _stefLoop
_stefNest:
    inc     ecx
    call    ExecConsumeToken
    jmp     _stefLoop
_stefUnNest:
    cmp     ecx, 0
    je      _stefDone
    dec     ecx
    call    ExecConsumeToken
    jmp     _stefLoop
_stefEnd:
    cmp     ecx, 0
    jne     _stefUnNestCont
    call    ExecConsumeToken
    jmp     _stefDone
_stefUnNestCont:
    dec     ecx
    call    ExecConsumeToken
    jmp     _stefLoop
_stefMaybeEnd:
    cmp     ecx, 0
    jne     _stefUnNest
    call    ExecConsumeToken
    jmp     _stefDone
_stefDone:
    pop     ecx
    pop     eax
    ret
ExecSkipToEndFor ENDP
 
ExecSkipFuncDef PROC
    push    eax
    push    ecx
    mov     ecx, 0
    call    ExecConsumeToken
_sfdLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _sfdDone
    cmp     eax, TOK_FUNC
    je      _sfdNest
    cmp     eax, TOK_ENDFUNC
    je      _sfdEnd
    call    ExecConsumeToken
    jmp     _sfdLoop
_sfdNest:
    inc     ecx
    call    ExecConsumeToken
    jmp     _sfdLoop
_sfdEnd:
    cmp     ecx, 0
    jne     _sfdUnNest
    call    ExecConsumeToken
    jmp     _sfdDone
_sfdUnNest:
    dec     ecx
    call    ExecConsumeToken
    jmp     _sfdLoop
_sfdDone:
    pop     ecx
    pop     eax
    ret
ExecSkipFuncDef ENDP
 
ExecSkipToRParen PROC
    push    eax
    push    ecx
    mov     ecx, 1
_strpLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _strpDone
    cmp     eax, TOK_LPAREN
    je      _strpNest
    cmp     eax, TOK_RPAREN
    je      _strpClose
    call    ExecConsumeToken
    jmp     _strpLoop
_strpNest:
    inc     ecx
    call    ExecConsumeToken
    jmp     _strpLoop
_strpClose:
    call    ExecConsumeToken
    dec     ecx
    cmp     ecx, 0
    jg      _strpLoop
_strpDone:
    pop     ecx
    pop     eax
    ret
ExecSkipToRParen ENDP
 
ExecSkipCaseBlock PROC
    push    eax
_scbLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _scbDone
    cmp     eax, TOK_CASE
    je      _scbDone
    cmp     eax, TOK_DEFAULT
    je      _scbDone
    cmp     eax, TOK_ENDSWITCH
    je      _scbDone
    cmp     eax, TOK_END
    je      _scbDone
    call    ExecConsumeToken
    jmp     _scbLoop
_scbDone:
    pop     eax
    ret
ExecSkipCaseBlock ENDP
 
ExecSkipToEndSwitch PROC
    push    eax
_stesLoop:
    call    ExecPeekType
    cmp     eax, TOK_EOF
    je      _stesDone
    cmp     eax, TOK_ENDSWITCH
    je      _stesConsume
    cmp     eax, TOK_END
    je      _stesConsume
    call    ExecConsumeToken
    jmp     _stesLoop
_stesConsume:
    call    ExecConsumeToken
_stesDone:
    pop     eax
    ret
ExecSkipToEndSwitch ENDP
 
ExecStepPause PROC
    push    eax
    push    edx
    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_step_prompt
    call    WriteString
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    call    ReadChar
    call    Crlf
    pop     edx
    pop     eax
    ret
ExecStepPause ENDP
 
END