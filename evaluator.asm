; ============================================================
; Expression Evaluator
; Implements: recursive descent expression parsing and evaluation
; Supports: +, -, *, /, %, ^ (power), ==, !=, <, >, <=, >=
;           AND, OR, NOT, ()
; Operator precedence (low to high):
;   OR
;   AND
;   NOT
;   ==, !=
;   <, >, <=, >=
;   +, -
;   *, /, %
;   Unary -, Unary +
;   ^ (power)
;   Primary (literal, ident, call, parens)
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
EXTERN tokenArray       : BYTE
EXTERN tokenIndex       : DWORD
EXTERN tokenCount       : DWORD
EXTERN g_debugMode      : DWORD
EXTERN g_traceMode      : DWORD
PrintDebug      PROTO
PrintTrace      PROTO
PrintError      PROTO
FindVariable    PROTO
SetVarInt       PROTO
ConsumeToken    PROTO
PeekTokenType   PROTO
SkipNewlines    PROTO
StrToInt_KL     PROTO
StrCopy_KL      PROTO
ExecFindFunction    PROTO
ExecCallFunction    PROTO
EXTERN callArgVals      : DWORD
EXTERN callArgTypes     : DWORD
EXTERN callArgCount     : DWORD
EXTERN savedFuncEntry   : DWORD
EXTERN returnValInt     : DWORD
EXTERN returnValType    : DWORD
EXTERN execNameBuf      : BYTE
 
.data
    str_eval_div0       BYTE "Division by zero!",0
    str_eval_undef      BYTE "Undefined variable in expression: ",0
    str_eval_expr       BYTE "Evaluating expression...",0
    str_eval_result     BYTE "Expression result: ",0
    
    ; FIX: local buffer to safely copy variable name before ConsumeToken
    evalVarNameBuf  BYTE MAX_TOKEN_LEN DUP(0)

    ; Buffer to save execNameBuf around function-call-in-expression
    ; (prevents _primFuncCall from overwriting the SET target variable name)
    savedExecName   BYTE 256 DUP(0)
    
    ; Evaluation result storage (also used for return from expr)
    ; These are per-evaluation call
    evalResultInt   DWORD 0
    evalResultType  DWORD VTYPE_INTEGER
    evalResultStr   BYTE MAX_STRING_LEN DUP(0)
    evalResultFloat REAL4 0.0
    
    ; Stack for expression evaluation (local)
    ; We use the x86 hardware stack via push/pop
 
.code
 
; ============================================================
; EvalExpression - Evaluate expression starting at current token
; Returns: EAX = integer result
; ============================================================
PUBLIC EvalExpression
EvalExpression PROC
    ; Parse at lowest precedence (OR)
    call    EvalOr
    ret
EvalExpression ENDP
 
; ============================================================
; EvalOr  a OR b
; ============================================================
EvalOr PROC
    push    ebx
    push    ecx
    
    call    EvalAnd     ; evaluate left side
    push    eax         ; save left result
    push    edx         ; save left type
    
_orLoop:
    call    PeekTokenType
    cmp     eax, TOK_OR
    jne     _orDone
    
    call    ConsumeToken    ; consume OR
    
    pop     edx             ; restore left type
    pop     eax             ; restore left
    push    eax             ; re-save
    push    edx
    
    push    eax             ; left value to compare
    call    EvalAnd
    
    pop     ecx             ; left value
    
    ; result = left OR right
    ; In KidLang: any non-zero = true
    cmp     ecx, 0
    jne     _orTrue
    cmp     eax, 0
    jne     _orTrue
    xor     eax, eax    ; false
    jmp     _orNext
_orTrue:
    mov     eax, 1
 
_orNext:
    pop     edx
    pop     ebx
    push    eax
    push    edx
    jmp     _orLoop
 
_orDone:
    pop     edx
    pop     eax
    
    pop     ecx
    pop     ebx
    ret
EvalOr ENDP
 
; ============================================================
; EvalAnd  a AND b
; ============================================================
EvalAnd PROC
    push    ebx
    push    ecx
    
    call    EvalNot
    push    eax
    push    edx
    
_andLoop:
    call    PeekTokenType
    cmp     eax, TOK_AND
    jne     _andDone
    
    call    ConsumeToken
    pop     edx
    pop     eax
    push    eax
    push    edx
    
    push    eax
    call    EvalNot
    pop     ecx
    
    ; result = left AND right
    cmp     ecx, 0
    je      _andFalse
    cmp     eax, 0
    je      _andFalse
    mov     eax, 1
    jmp     _andNext
_andFalse:
    xor     eax, eax
_andNext:
    pop     edx
    pop     ebx
    push    eax
    push    edx
    jmp     _andLoop
 
_andDone:
    pop     edx
    pop     eax
    pop     ecx
    pop     ebx
    ret
EvalAnd ENDP
 
; ============================================================
; EvalNot  NOT a
; ============================================================
EvalNot PROC
    push    ebx
    
    call    PeekTokenType
    cmp     eax, TOK_NOT
    jne     _notSkip
    
    call    ConsumeToken    ; consume NOT
    call    EvalComparison
    ; Invert result
    cmp     eax, 0
    je      _notTrue
    xor     eax, eax
    jmp     _notDone
_notTrue:
    mov     eax, 1
    jmp     _notDone
 
_notSkip:
    call    EvalComparison
 
_notDone:
    pop     ebx
    ret
EvalNot ENDP
 
; ============================================================
; EvalComparison  a <op> b  (==, !=, <, >, <=, >=)
; ============================================================
EvalComparison PROC
    push    ebx
    push    ecx
    
    call    EvalAddSub
    push    eax
    push    edx
    
_cmpCheck:
    call    PeekTokenType
    cmp     eax, TOK_EQ
    je      _cmpOp
    cmp     eax, TOK_NEQ
    je      _cmpOp
    cmp     eax, TOK_LT
    je      _cmpOp
    cmp     eax, TOK_GT
    je      _cmpOp
    cmp     eax, TOK_LTE
    je      _cmpOp
    cmp     eax, TOK_GTE
    je      _cmpOp
    jmp     _cmpDone
 
_cmpOp:
    push    eax             ; save operator type
    call    ConsumeToken    ; consume operator
    pop     ebx             ; ebx = operator type
    
    pop     edx             ; left type
    pop     ecx             ; left value
    
    call    EvalAddSub      ; right value in EAX
    
    ; Compare ECX (left) vs EAX (right)
    cmp     ebx, TOK_EQ
    je      _cmpEQ
    cmp     ebx, TOK_NEQ
    je      _cmpNEQ
    cmp     ebx, TOK_LT
    je      _cmpLT
    cmp     ebx, TOK_GT
    je      _cmpGT
    cmp     ebx, TOK_LTE
    je      _cmpLTE
    cmp     ebx, TOK_GTE
    je      _cmpGTE
    xor     eax, eax
    jmp     _cmpStore
 
_cmpEQ:
    ; If strings: compare content byte-by-byte, not pointer
    cmp     edx, VTYPE_STRING
    jne     _cmpEqInt
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
    mov     esi, ecx        ; left string ptr
    mov     edi, eax        ; right string ptr
_cmpEqStrLoop:
    mov     bl, [esi]
    mov     cl, [edi]
    cmp     bl, cl
    jne     _cmpEqStrDiff
    cmp     bl, 0
    je      _cmpEqStrMatch
    inc     esi
    inc     edi
    jmp     _cmpEqStrLoop
_cmpEqStrMatch:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    jmp     _cmpTrue
_cmpEqStrDiff:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    jmp     _cmpFalse
_cmpEqInt:
    cmp     ecx, eax
    je      _cmpTrue
    jmp     _cmpFalse
_cmpNEQ:
    cmp     edx, VTYPE_STRING
    jne     _cmpNeqInt
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
    mov     esi, ecx
    mov     edi, eax
_cmpNeqStrLoop:
    mov     bl, [esi]
    mov     cl, [edi]
    cmp     bl, cl
    jne     _cmpNeqStrDiff
    cmp     bl, 0
    je      _cmpNeqStrMatch
    inc     esi
    inc     edi
    jmp     _cmpNeqStrLoop
_cmpNeqStrMatch:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    jmp     _cmpFalse
_cmpNeqStrDiff:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    jmp     _cmpTrue
_cmpNeqInt:
    cmp     ecx, eax
    jne     _cmpTrue
    jmp     _cmpFalse
_cmpLT:
    cmp     ecx, eax
    jl      _cmpTrue
    jmp     _cmpFalse
_cmpGT:
    cmp     ecx, eax
    jg      _cmpTrue
    jmp     _cmpFalse
_cmpLTE:
    cmp     ecx, eax
    jle     _cmpTrue
    jmp     _cmpFalse
_cmpGTE:
    cmp     ecx, eax
    jge     _cmpTrue
    jmp     _cmpFalse
 
_cmpTrue:
    mov     eax, 1
    jmp     _cmpStore
_cmpFalse:
    xor     eax, eax
_cmpStore:
    mov     edx, VTYPE_INTEGER
    push    eax
    push    edx
    jmp     _cmpCheck
 
_cmpDone:
    pop     edx
    pop     eax
    pop     ecx
    pop     ebx
    ret
EvalComparison ENDP
 
; ============================================================
; EvalAddSub  a + b, a - b
; ============================================================
EvalAddSub PROC
    push    ebx
    push    ecx
    
    call    EvalMulDiv
    push    eax
    push    edx
    
_asLoop:
    call    PeekTokenType
    cmp     eax, TOK_PLUS
    je      _asOp
    cmp     eax, TOK_MINUS
    je      _asOp
    jmp     _asDone
 
_asOp:
    push    eax
    call    ConsumeToken
    pop     ebx             ; operator
    
    pop     edx
    pop     ecx             ; left value
    
    call    EvalMulDiv      ; right value
    
    cmp     ebx, TOK_PLUS
    je      _asAdd
    ; Subtract
    sub     ecx, eax
    mov     eax, ecx
    jmp     _asStore
_asAdd:
    add     eax, ecx
_asStore:
    mov     edx, VTYPE_INTEGER
    push    eax
    push    edx
    jmp     _asLoop
 
_asDone:
    pop     edx
    pop     eax
    pop     ecx
    pop     ebx
    ret
EvalAddSub ENDP
 
; ============================================================
; EvalMulDiv  a * b, a / b, a % b
; ============================================================
EvalMulDiv PROC
    push    ebx
    push    ecx
    
    call    EvalUnary
    push    eax
    push    edx
    
_mdLoop:
    call    PeekTokenType
    cmp     eax, TOK_MULTIPLY
    je      _mdOp
    cmp     eax, TOK_DIVIDE
    je      _mdOp
    cmp     eax, TOK_MODULO
    je      _mdOp
    jmp     _mdDone
 
_mdOp:
    push    eax
    call    ConsumeToken
    pop     ebx
    
    pop     edx
    pop     ecx             ; left value
    
    call    EvalUnary       ; right value
    
    cmp     ebx, TOK_MULTIPLY
    je      _mdMul
    cmp     ebx, TOK_DIVIDE
    je      _mdDiv
    ; Modulo: EAX = right (divisor), ECX = left (dividend)
    cmp     eax, 0
    je      _mdDivZero
    push    ebx
    mov     ebx, eax        ; EBX = divisor (right)
    mov     eax, ecx        ; EAX = dividend (left)
    cdq                     ; sign-extend EAX into EDX:EAX
    idiv    ebx             ; EDX = remainder
    mov     eax, edx        ; EAX = result (remainder)
    pop     ebx
    jmp     _mdStore

_mdMul:
    imul    eax, ecx
    jmp     _mdStore
    
_mdDiv:
    ; EAX = right (divisor), ECX = left (dividend)
    cmp     eax, 0
    je      _mdDivZero
    push    ebx
    mov     ebx, eax        ; EBX = divisor
    mov     eax, ecx        ; EAX = dividend
    cdq                     ; sign-extend EAX into EDX:EAX (handles negatives)
    idiv    ebx             ; EAX = quotient
    pop     ebx
    jmp     _mdStore
 
_mdDivZero:
    mov     edx, OFFSET str_eval_div0
    xor     ebx, ebx
    call    PrintError
    xor     eax, eax
    jmp     _mdStore
 
_mdStore:
    mov     edx, VTYPE_INTEGER
    push    eax
    push    edx
    jmp     _mdLoop
 
_mdDone:
    pop     edx
    pop     eax
    pop     ecx
    pop     ebx
    ret
EvalMulDiv ENDP
 
; ============================================================
; EvalUnary  Unary minus/plus
; ============================================================
EvalUnary PROC
    push    ebx
    
    call    PeekTokenType
    cmp     eax, TOK_MINUS
    je      _unaryMinus
    cmp     eax, TOK_PLUS
    je      _unaryPlus
    
    call    EvalPrimary
    jmp     _unaryDone
 
_unaryMinus:
    call    ConsumeToken
    call    EvalPrimary
    neg     eax
    jmp     _unaryDone
 
_unaryPlus:
    call    ConsumeToken
    call    EvalPrimary
 
_unaryDone:
    pop     ebx
    ret
EvalUnary ENDP
 
; ============================================================
; EvalPrimary  Literal, identifier, (expression)
; Returns: EAX = value, EDX = type
; ============================================================
PUBLIC EvalPrimary
EvalPrimary PROC
    push    ebx
    push    esi
    push    edi
    
_primRestart:
    call    PeekTokenType
    
    ; Integer literal
    cmp     eax, TOK_INTEGER
    je      _primInt
    
    ; String literal
    cmp     eax, TOK_STRING
    je      _primString
    
    ; Boolean true
    cmp     eax, TOK_BOOL_TRUE
    je      _primTrue
    
    ; Boolean false
    cmp     eax, TOK_BOOL_FALSE
    je      _primFalse
    
    ; Identifier (variable or function call)
    cmp     eax, TOK_IDENT
    je      _primIdent
    
    ; Parenthesized expression
    cmp     eax, TOK_LPAREN
    je      _primParen
    
    ; Char literal
    cmp     eax, TOK_CHAR
    je      _primChar

    ; Float literal - treat as integer (truncate decimal part)
    cmp     eax, TOK_FLOAT
    je      _primInt            ; reuse _primInt: StrToInt_KL stops at '.' giving integer part

    ; CALL keyword in expression: "SET x = CALL funcName(args)"
    ; Consume the CALL token, then fall through to _primIdent
    ; which will read the function name and detect the LPAREN
    cmp     eax, TOK_CALL
    jne     _primUnknown
    call    ConsumeToken        ; consume CALL keyword, then fall to normal ident path
    ; Now current token should be the function name (TOK_IDENT)
    ; Re-enter EvalPrimary logic for the ident
    jmp     _primRestart

_primUnknown:
    ; Unknown - return 0
    xor     eax, eax
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
; ============================================================
; This bypasses the corrupted TOKEN_OFF_IVAL.
; ============================================================
_primInt:
    call    EvalGetCurrentToken
    lea     esi, [esi + TOKEN_OFF_VALUE]   ; ESI = pointer to digit string
    call    StrToInt_KL                    ; EAX = integer value
    push    eax                            ; BUG FIX: save value BEFORE ConsumeToken
    call    ConsumeToken                   ; ConsumeToken overwrites EAX with token type!
    pop     eax                            ; BUG FIX: restore correct integer value
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
_primString:
    ; Get string value - return pointer in EAX as int (hack for now)
    ; For string output we use special path in executor
    call    EvalGetCurrentToken
    lea     eax, [esi + TOKEN_OFF_VALUE]    ; EAX = pointer to string data
    push    eax                             ; BUG FIX: save ptr before ConsumeToken
    call    ConsumeToken                    ; overwrites EAX with TOK_STRING = 12!
    pop     eax                             ; BUG FIX: restore correct string pointer
    mov     edx, VTYPE_STRING
    jmp     _primDone
 
_primTrue:
    call    ConsumeToken
    mov     eax, 1
    mov     edx, VTYPE_BOOL
    jmp     _primDone
 
_primFalse:
    call    ConsumeToken
    xor     eax, eax
    mov     edx, VTYPE_BOOL
    jmp     _primDone
 
_primChar:
    call    EvalGetCurrentToken
    movzx   eax, BYTE PTR [esi + TOKEN_OFF_VALUE]  ; EAX = char code (e.g. 65 for 'A')
    push    eax                 ; BUG FIX: save char value before ConsumeToken
    call    ConsumeToken        ; overwrites EAX with TOK_CHAR = 13!
    pop     eax                 ; BUG FIX: restore correct char value
    mov     edx, VTYPE_CHAR
    jmp     _primDone
 
_primIdent:
    ; Get token info
    call    EvalGetCurrentToken
    ; FIX: Copy variable name to safe local buffer BEFORE ConsumeToken
    ; because ConsumeToken changes tokenIndex and ESI-based pointer becomes stale
    push    esi
    push    edi
    push    ecx
    lea     esi, [esi + TOKEN_OFF_VALUE]    ; source: variable name in token
    mov     edi, OFFSET evalVarNameBuf      ; dest: safe local buffer
    mov     ecx, MAX_TOKEN_LEN - 1
    call    StrCopy_KL
    pop     ecx
    pop     edi
    pop     esi
    
    call    ConsumeToken    ; now safe to consume - name already saved
    
    ; Point ESI to our safe copy
    mov     esi, OFFSET evalVarNameBuf
    
    call    PeekTokenType
    cmp     eax, TOK_LPAREN
    je      _primFuncCall
    
    ; Regular variable lookup - ESI = safe copy of var name
    call    FindVariable
    cmp     eax, 0
    je      _primUndefVar
    
    mov     edi, eax        ; variable entry pointer
    mov     eax, [edi + VAR_OFF_TYPE]
    
    cmp     eax, VTYPE_INTEGER
    je      _primGetInt
    cmp     eax, VTYPE_BOOL
    je      _primGetBool
    cmp     eax, VTYPE_STRING
    je      _primGetStr
    cmp     eax, VTYPE_CHAR
    je      _primGetChar
    
    xor     eax, eax
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
_primGetInt:
    mov     eax, [edi + VAR_OFF_IVAL]
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
_primGetBool:
    movzx   eax, BYTE PTR [edi + VAR_OFF_BVAL]
    mov     edx, VTYPE_BOOL
    jmp     _primDone
 
_primGetStr:
    lea     eax, [edi + VAR_OFF_SVAL]
    mov     edx, VTYPE_STRING
    jmp     _primDone
 
_primGetChar:
    movzx   eax, BYTE PTR [edi + VAR_OFF_CVAL]
    mov     edx, VTYPE_CHAR
    jmp     _primDone
 
_primUndefVar:
    ; Variable not defined - print error
    ; FIX: ESI already = evalVarNameBuf (safe copy), no need to re-setup
    mov     eax, LIGHTRED_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_eval_undef
    call    WriteString
    ; esi points to variable name (safe buffer)
    mov     edx, esi
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    xor     eax, eax
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
_primFuncCall:
    ; Function call in expression: funcName(arg1, arg2, ...)
    ; evalVarNameBuf has the function name. execNameBuf has the SET target (e.g. "grade").
    ; We must SAVE execNameBuf before overwriting it, then RESTORE after the call.

    ; Step 1: Save execNameBuf -> savedExecName
    push    esi
    push    edi
    push    ecx
    mov     esi, OFFSET execNameBuf
    mov     edi, OFFSET savedExecName
    mov     ecx, 255
    call    StrCopy_KL
    pop     ecx
    pop     edi
    pop     esi

    ; Step 2: Copy function name (evalVarNameBuf) -> execNameBuf for ExecFindFunction
    push    esi
    push    edi
    push    ecx
    mov     esi, OFFSET evalVarNameBuf
    mov     edi, OFFSET execNameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     ecx
    pop     edi
    pop     esi

    ; Reset arg count
    mov     callArgCount, 0

    call    ConsumeToken            ; consume (

    ; Evaluate each argument
_fcArgLoop:
    call    PeekTokenType
    cmp     eax, TOK_RPAREN
    je      _fcArgsDone
    cmp     eax, TOK_EOF
    je      _fcArgsDone
    cmp     eax, TOK_NEWLINE
    je      _fcArgsDone

    call    EvalExpression          ; EAX = value, EDX = type
    mov     ecx, callArgCount
    cmp     ecx, 8
    jge     _fcArgSkip
    push    eax
    ; store value: callArgVals[ecx] = eax
    mov     eax, ecx
    shl     eax, 2
    push    edx
    mov     edx, [esp + 4]          ; get saved eax (value)
    mov     [OFFSET callArgVals + eax], edx
    pop     edx
    pop     eax
    ; store type: callArgTypes[ecx] = edx
    push    eax
    mov     eax, ecx
    shl     eax, 2
    mov     [OFFSET callArgTypes + eax], edx
    pop     eax
    inc     callArgCount
_fcArgSkip:
    call    PeekTokenType
    cmp     eax, TOK_COMMA
    jne     _fcArgLoop
    call    ConsumeToken            ; consume comma
    jmp     _fcArgLoop

_fcArgsDone:
    call    PeekTokenType
    cmp     eax, TOK_RPAREN
    jne     _fcCallNow
    call    ConsumeToken            ; consume )

_fcCallNow:
    ; Find and call the function
    call    ExecFindFunction
    cmp     eax, 0
    je      _fcNotFound
    mov     savedFuncEntry, eax
    call    ExecCallFunction
    ; Return value is in returnValInt / returnValType
    mov     eax, returnValInt
    mov     edx, returnValType

    ; Step 3: RESTORE execNameBuf (was overwritten with func name, need SET target back)
    push    eax
    push    edx
    push    esi
    push    edi
    push    ecx
    mov     esi, OFFSET savedExecName
    mov     edi, OFFSET execNameBuf
    mov     ecx, 255
    call    StrCopy_KL
    pop     ecx
    pop     edi
    pop     esi
    pop     edx
    pop     eax
    jmp     _primDone

_fcNotFound:
    ; Restore execNameBuf even on error
    push    esi
    push    edi
    push    ecx
    mov     esi, OFFSET savedExecName
    mov     edi, OFFSET execNameBuf
    mov     ecx, 255
    call    StrCopy_KL
    pop     ecx
    pop     edi
    pop     esi
    xor     eax, eax
    mov     edx, VTYPE_INTEGER
    jmp     _primDone
 
_primParen:
    call    ConsumeToken    ; consume (
    call    EvalExpression  ; recursive eval
    push    eax
    push    edx
    call    PeekTokenType
    cmp     eax, TOK_RPAREN
    jne     _primParenErr
    call    ConsumeToken    ; consume )
    pop     edx
    pop     eax
    jmp     _primDone
_primParenErr:
    pop     edx
    pop     eax
    jmp     _primDone
 
_primDone:
    pop     edi
    pop     esi
    pop     ebx
    ret
EvalPrimary ENDP
 
; ============================================================
; GetCurrentToken (local helper, same as parser version)
; Returns: ESI = token pointer, EAX = type
; ============================================================
EvalGetCurrentToken PROC
    push    ecx
    mov     eax, TOKEN_SIZE
    mov     ecx, tokenIndex
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    ret
EvalGetCurrentToken ENDP
 
END