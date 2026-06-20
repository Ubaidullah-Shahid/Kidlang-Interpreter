; ============================================================
; Complete Parser - validates syntax, builds execution plan
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
EXTERN tokenArray       : BYTE
EXTERN tokenCount       : DWORD
EXTERN tokenIndex       : DWORD
EXTERN funcTable        : BYTE
EXTERN funcCount        : DWORD
EXTERN g_debugMode      : DWORD
PrintDebug      PROTO
PrintError      PROTO
PrintInfo       PROTO
StrCopy_KL      PROTO
StrCompare_KL   PROTO
ToLower_KL      PROTO
 
.data
    str_parse_start     BYTE "Parser started...",0
    str_parse_done      BYTE "Parser complete. No syntax errors.",0
    str_parse_err       BYTE "Syntax error in program.",0
    str_unexpected_tok  BYTE "Unexpected token",0
    str_expect_then     BYTE "Expected THEN after IF condition",0
    str_expect_end      BYTE "Expected END or ENDIF",0
    str_expect_do       BYTE "Expected DO after WHILE condition",0
    str_expect_endwhile BYTE "Expected ENDWHILE",0
    str_expect_endfor   BYTE "Expected ENDFOR",0
    str_expect_endfunc  BYTE "Expected ENDFUNC",0
    str_expect_lparen   BYTE "Expected '('",0
    str_expect_rparen   BYTE "Expected ')'",0
    str_expect_ident    BYTE "Expected identifier",0
    str_expect_assign   BYTE "Expected '='",0
    str_func_def        BYTE "Function defined: ",0
    str_parse_stmt      BYTE "Parsing statement...",0
    
    parseErrorCount     DWORD 0
    parseOK             DWORD 1     ; 1 = no errors so far
 
.code
 
; ============================================================
; RunParser - Main parser entry point
; Returns: EAX = 0 on success, non-zero on error
; ============================================================
PUBLIC RunParser
RunParser PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
    ; Reset parser state
    mov     tokenIndex, 0
    mov     parseErrorCount, 0
    mov     parseOK, 1
 
    mov     edx, OFFSET str_parse_start
    call    PrintDebug
 
    ; First pass: scan for function definitions
    call    FirstPassFunctions
    
    ; Reset token index for main parse
    mov     tokenIndex, 0
    
    ; Parse the program (top-level statement list)
    call    ParseProgram
    
    ; Check for errors
    mov     eax, parseOK
    cmp     eax, 1
    je      _parseSuccess
    
    mov     edx, OFFSET str_parse_err
    xor     ebx, ebx
    call    PrintError
    mov     eax, ERR_SYNTAX
    jmp     _parseDone
 
_parseSuccess:
    mov     edx, OFFSET str_parse_done
    call    PrintInfo
    xor     eax, eax
 
_parseDone:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
RunParser ENDP
 
; ============================================================
; GetCurrentToken - Get pointer to current token
; Returns: ESI = pointer to current token struct
;          EAX = token type
; ============================================================
GetCurrentToken PROC
    push    ecx
    mov     eax, TOKEN_SIZE
    mov     ecx, tokenIndex
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    ret
GetCurrentToken ENDP
 
; ============================================================
; PeekTokenType - Get type of current token without consuming
; Returns: EAX = token type
; ============================================================
PUBLIC PeekTokenType
PeekTokenType PROC
    push    esi             ; SAVE ESI - callers depend on ESI not being corrupted
    call    GetCurrentToken ; sets ESI = token ptr, EAX = type
    pop     esi             ; RESTORE ESI - caller's ESI is preserved
    ret     ; EAX = type only (ESI preserved for caller)
PeekTokenType ENDP
 
; ============================================================
; ConsumeToken - Advance tokenIndex, return consumed token type
; Returns: EAX = token type consumed
;          ESI = pointer to consumed token
; ============================================================
PUBLIC ConsumeToken
ConsumeToken PROC
    call    GetCurrentToken     ; EAX = type, ESI = ptr
    push    eax                 ; save type
    
    ; Skip newlines automatically (they're just whitespace for parser)
    ; Unless it's meaningful - we skip them here
    ; Actually keep newlines for statement separation
    
    ; Advance index if not EOF
    cmp     eax, TOK_EOF
    je      _atEOF
    inc     tokenIndex
_atEOF:
    pop     eax
    ret
ConsumeToken ENDP
 
; ============================================================
; SkipNewlines - Skip any NEWLINE tokens
; ============================================================
SkipNewlines PROC
_snLoop:
    call    PeekTokenType
    cmp     eax, TOK_NEWLINE
    jne     _snDone
    call    ConsumeToken
    jmp     _snLoop
_snDone:
    ret
SkipNewlines ENDP
 
; ============================================================
; ExpectToken - Consume token of expected type, error if not
; Parameters: EBX = expected token type
; Returns: EAX = 0 if ok, non-zero if error
;          ESI = pointer to consumed token
; ============================================================
ExpectToken PROC
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, ebx
    je      _expectOK
    
    ; Error: unexpected token
    call    GetCurrentToken
    mov     ecx, [esi + TOKEN_OFF_LINE]  ; line number
    
    ; Print error
    push    ecx
    mov     edx, OFFSET str_unexpected_tok
    mov     ebx, ecx
    call    PrintError
    pop     ecx
    
    mov     parseOK, 0
    inc     parseErrorCount
    mov     eax, 1
    ret
 
_expectOK:
    call    ConsumeToken
    xor     eax, eax
    ret
ExpectToken ENDP
 
; ============================================================
; FirstPassFunctions - Pre-scan to register function names
; This allows calling functions before their definition
; ============================================================
FirstPassFunctions PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi
    
    mov     ecx, 0          ; token index
    
_ffLoop:
    ; Get token type at index ecx
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    
    cmp     eax, TOK_EOF
    je      _ffDone
    
    cmp     eax, TOK_FUNC
    je      _foundFunc
    
    inc     ecx
    jmp     _ffLoop
 
_foundFunc:
    ; Next token should be function name
    inc     ecx
    
    ; Skip newlines
_skipNL:
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    cmp     eax, TOK_NEWLINE
    jne     _getFunc
    inc     ecx
    jmp     _skipNL
 
_getFunc:
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    
    cmp     eax, TOK_IDENT
    jne     _ffNextToken    ; not an ident, skip

    ; Bounds check
    mov     eax, funcCount
    cmp     eax, MAX_FUNCTIONS
    jge     _ffNextToken

    ; --- Register function ---
    push    ecx             ; [esp] = token index of func name

    ; Compute funcTable entry address
    mov     edi, OFFSET funcTable
    mov     eax, FUNC_SIZE
    imul    eax, funcCount
    add     edi, eax        ; edi = new funcTable entry

    ; Get function name ptr from tokenArray
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    lea     esi, [esi + TOKEN_OFF_VALUE]    ; esi = name string

    ; Copy name into funcTable entry (StrCopy_KL saves esi/edi/ecx)
    push    edi
    mov     ecx, 127
    call    StrCopy_KL
    pop     edi             ; edi = funcTable entry again

    ; --- Parse parameters ---
    ; token index is at [esp], func name token
    pop     ecx             ; ecx = func name token index
    inc     ecx             ; move past func name

    ; Skip optional ( 
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    cmp     eax, TOK_LPAREN
    jne     _ffStoreStart
    inc     ecx             ; skip (

    ; Parse parameter names until )
    mov     DWORD PTR [edi + FUNC_OFF_PARAMCOUNT], 0
_ffParamLoop:
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    cmp     eax, TOK_RPAREN
    je      _ffParamDone
    cmp     eax, TOK_EOF
    je      _ffParamDone
    cmp     eax, TOK_NEWLINE
    je      _ffParamDone
    cmp     eax, TOK_IDENT
    jne     _ffParamSkip
    ; Store param name
    push    ecx
    push    edi
    mov     eax, [edi + FUNC_OFF_PARAMCOUNT]
    cmp     eax, 8          ; max 8 params
    jge     _ffParamSkipStore
    ; param slot = FUNC_OFF_PARAMS + paramIndex * 16
    imul    eax, eax, 16
    lea     edi, [edi + FUNC_OFF_PARAMS + eax]
    ; get param name from token
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    lea     esi, [esi + TOKEN_OFF_VALUE]
    push    ecx
    mov     ecx, 15
    call    StrCopy_KL
    pop     ecx
_ffParamSkipStore:
    pop     edi
    ; increment paramCount
    mov     eax, [edi + FUNC_OFF_PARAMCOUNT]
    inc     eax
    mov     [edi + FUNC_OFF_PARAMCOUNT], eax
    pop     ecx
_ffParamSkip:
    inc     ecx
    jmp     _ffParamLoop
_ffParamDone:
    ; skip ) if present
    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax
    mov     eax, [esi + TOKEN_OFF_TYPE]
    pop     ecx
    cmp     eax, TOK_RPAREN
    jne     _ffStoreStart
    inc     ecx

_ffStoreStart:
    ; Store token start index (body starts after name+params line)
    mov     [edi + FUNC_OFF_TOKSTART], ecx
    dec     ecx             ; _ffNextToken will inc ecx

    ; Increment function count
    inc     funcCount
    
    ; Debug
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _ffNextToken
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_func_def
    call    WriteString
    call    WriteString     ; write the function name (edx still points to string via esi)
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_ffNextToken:
    inc     ecx
    jmp     _ffLoop
 
_ffDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
FirstPassFunctions ENDP
ecx_save DWORD 0    ; temp storage for ECX
 
; ============================================================
; ParseProgram - Parse top-level list of statements
; ============================================================
ParseProgram PROC
    push    eax
    push    ebx
 
_ppLoop:
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_EOF
    je      _ppDone
    
    ; Don't parse FUNC definitions at top level during exec
    ; (they're registered in first pass)
    cmp     eax, TOK_FUNC
    je      _skipFuncDef
    
    call    ParseStatement
    cmp     eax, 0
    jne     _ppError
    jmp     _ppLoop
 
_skipFuncDef:
    ; Skip the entire function definition
    call    SkipFuncDef
    jmp     _ppLoop
 
_ppError:
    ; Error already reported
    jmp     _ppDone
 
_ppDone:
    pop     ebx
    pop     eax
    ret
ParseProgram ENDP
 
; ============================================================
; SkipFuncDef - Skip a FUNC ... ENDFUNC block in parse pass
; ============================================================
SkipFuncDef PROC
    push    eax
    push    ecx
    
    ; Consume FUNC
    call    ConsumeToken
    mov     ecx, 1          ; nesting depth
    
_sfdLoop:
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_EOF
    je      _sfdDone
    
    cmp     eax, TOK_FUNC
    je      _sfdDeeper
    
    cmp     eax, TOK_ENDFUNC
    je      _sfdClose
    
    call    ConsumeToken
    jmp     _sfdLoop
 
_sfdDeeper:
    call    ConsumeToken
    inc     ecx
    jmp     _sfdLoop
 
_sfdClose:
    call    ConsumeToken
    dec     ecx
    jmp     _sfdLoop
 
_sfdDone:
    pop     ecx
    pop     eax
    ret
SkipFuncDef ENDP
 
; ============================================================
; ParseStatement - Parse a single statement
; Returns: EAX = 0 on success
; ============================================================
PUBLIC ParseStatement
ParseStatement PROC
    push    ebx
    push    ecx
    push    esi
    
    call    SkipNewlines
    call    PeekTokenType
    
    ; Dispatch based on token type
    cmp     eax, TOK_SHOW
    je      _pShow
    cmp     eax, TOK_PRINT
    je      _pShow
    cmp     eax, TOK_SHOWL
    je      _pShow
    cmp     eax, TOK_ASK
    je      _pAsk
    cmp     eax, TOK_INPUT
    je      _pAsk
    cmp     eax, TOK_SET
    je      _pSet
    cmp     eax, TOK_LET
    je      _pSet
    cmp     eax, TOK_VAR
    je      _pSet
    cmp     eax, TOK_CONST
    je      _pConst
    cmp     eax, TOK_IF
    je      _pIf
    cmp     eax, TOK_WHILE
    je      _pWhile
    cmp     eax, TOK_FOR
    je      _pFor
    cmp     eax, TOK_FUNC
    je      _pFunc
    cmp     eax, TOK_CALL
    je      _pCall
    cmp     eax, TOK_RETURN
    je      _pReturn
    cmp     eax, TOK_BREAK
    je      _pBreak
    cmp     eax, TOK_CONTINUE
    je      _pContinue
    cmp     eax, TOK_SWITCH
    je      _pSwitch
    cmp     eax, TOK_SHOW_VARS
    je      _pShowVars
    cmp     eax, TOK_DEBUG_ON
    je      _pDebugOn
    cmp     eax, TOK_DEBUG_OFF
    je      _pDebugOff
    cmp     eax, TOK_TRACE_ON
    je      _pTraceOn
    cmp     eax, TOK_TRACE_OFF
    je      _pTraceOff
    cmp     eax, TOK_PAUSE
    je      _pPause
    cmp     eax, TOK_CLEAR
    je      _pClear
    cmp     eax, TOK_WAIT
    je      _pWait
    ; Identifier followed by = (assignment without SET)
    cmp     eax, TOK_IDENT
    je      _pIdentAssign
    
    ; Unknown - skip token
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- SHOW / PRINT ---
_pShow:
    call    ConsumeToken        ; consume SHOW/PRINT
    ; Rest is expression or string until end of line
    xor     eax, eax
    jmp     _psDone
 
; --- ASK / INPUT ---
_pAsk:
    call    ConsumeToken        ; consume ASK/INPUT
    ; Expect identifier
    mov     ebx, TOK_IDENT
    call    ExpectToken
    xor     eax, eax
    jmp     _psDone
 
; --- SET / LET / VAR ---
_pSet:
    call    ConsumeToken        ; consume SET/LET/VAR
    ; Expect identifier
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_IDENT
    jne     _psExpectIdent
    call    ConsumeToken
    ; Expect =
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_ASSIGN
    jne     _psMaybeOK      ; allow SET x without = for declaration
    call    ConsumeToken    ; consume =
    ; Expression follows
    xor     eax, eax
    jmp     _psDone
_psMaybeOK:
    xor     eax, eax
    jmp     _psDone
 
; --- CONST ---
_pConst:
    call    ConsumeToken
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_IDENT
    jne     _psExpectIdent
    call    ConsumeToken
    call    SkipNewlines
    mov     ebx, TOK_ASSIGN
    call    ExpectToken
    xor     eax, eax
    jmp     _psDone
 
; --- IF ---
_pIf:
    call    ConsumeToken    ; consume IF
    ; Expression
    call    SkipNewlines
    ; (expression will be evaluated by executor)
    ; Scan for THEN
    call    FindThenOrNewline
    xor     eax, eax
    jmp     _psDone
 
; --- WHILE ---
_pWhile:
    call    ConsumeToken    ; consume WHILE
    xor     eax, eax
    jmp     _psDone
 
; --- FOR ---
_pFor:
    call    ConsumeToken    ; consume FOR
    xor     eax, eax
    jmp     _psDone
 
; --- FUNC ---
_pFunc:
    call    ConsumeToken    ; consume FUNC
    xor     eax, eax
    jmp     _psDone
 
; --- CALL ---
_pCall:
    call    ConsumeToken    ; consume CALL
    ; Expect function name
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_IDENT
    jne     _psExpectIdent
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- RETURN ---
_pReturn:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- BREAK ---
_pBreak:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- CONTINUE ---
_pContinue:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- SWITCH ---
_pSwitch:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- SHOW_VARIABLES ---
_pShowVars:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- DEBUG/TRACE controls ---
_pDebugOn:
_pDebugOff:
_pTraceOn:
_pTraceOff:
_pPause:
_pClear:
_pWait:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
; --- Identifier = expression ---
_pIdentAssign:
    call    ConsumeToken    ; consume identifier
    call    SkipNewlines
    call    PeekTokenType
    cmp     eax, TOK_ASSIGN
    je      _pDoAssign
    cmp     eax, TOK_PLUS_ASSIGN
    je      _pDoAssign
    cmp     eax, TOK_MINUS_ASSIGN
    je      _pDoAssign
    cmp     eax, TOK_MUL_ASSIGN
    je      _pDoAssign
    cmp     eax, TOK_DIV_ASSIGN
    je      _pDoAssign
    cmp     eax, TOK_INCREMENT
    je      _pDoIncDec
    cmp     eax, TOK_DECREMENT
    je      _pDoIncDec
    ; Could be function call: ident(
    cmp     eax, TOK_LPAREN
    je      _pDoFuncCall
    ; Otherwise just an expression statement
    xor     eax, eax
    jmp     _psDone
 
_pDoAssign:
    call    ConsumeToken    ; consume operator
    xor     eax, eax
    jmp     _psDone
 
_pDoIncDec:
    call    ConsumeToken
    xor     eax, eax
    jmp     _psDone
 
_pDoFuncCall:
    ; function call as statement: ident(args)
    call    ConsumeToken    ; consume (
    ; Skip until )
    call    SkipToRParen
    xor     eax, eax
    jmp     _psDone
 
_psExpectIdent:
    mov     edx, OFFSET str_expect_ident
    call    GetCurrentToken
    mov     ebx, [esi + TOKEN_OFF_LINE]
    call    PrintError
    mov     parseOK, 0
    mov     eax, ERR_SYNTAX
    jmp     _psDone
 
_psDone:
    pop     esi
    pop     ecx
    pop     ebx
    ret
ParseStatement ENDP
 
; ============================================================
; FindThenOrNewline - skip past THEN or to end of line
; ============================================================
FindThenOrNewline PROC
    push    eax
_ftnLoop:
    call    PeekTokenType
    cmp     eax, TOK_EOF
    je      _ftnDone
    cmp     eax, TOK_NEWLINE
    je      _ftnDone
    cmp     eax, TOK_THEN
    je      _ftnThen
    call    ConsumeToken
    jmp     _ftnLoop
_ftnThen:
    call    ConsumeToken    ; consume THEN
_ftnDone:
    pop     eax
    ret
FindThenOrNewline ENDP
 
; ============================================================
; SkipToRParen - skip until matching )
; ============================================================
SkipToRParen PROC
    push    eax
    push    ecx
    mov     ecx, 1          ; paren depth
_strpLoop:
    call    PeekTokenType
    cmp     eax, TOK_EOF
    je      _strpDone
    cmp     eax, TOK_LPAREN
    je      _strpDeeper
    cmp     eax, TOK_RPAREN
    je      _strpClose
    call    ConsumeToken
    jmp     _strpLoop
_strpDeeper:
    call    ConsumeToken
    inc     ecx
    jmp     _strpLoop
_strpClose:
    call    ConsumeToken
    dec     ecx
    cmp     ecx, 0
    jg      _strpLoop
_strpDone:
    pop     ecx
    pop     eax
    ret
SkipToRParen ENDP
 
END