; ============================================================
; KIDLANG - LEXER.ASM (FIXED)
; Complete Lexer / Tokenizer with correct integer values
; ============================================================

INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc

EXTERN sourceBuffer     : BYTE
EXTERN sourceSize       : DWORD
EXTERN tokenArray       : BYTE
EXTERN tokenCount       : DWORD
EXTERN g_debugMode      : DWORD
EXTERN g_traceMode      : DWORD
PrintDebug      PROTO
PrintInfo       PROTO
PrintError      PROTO
ToLower_KL      PROTO
StrCopy_KL      PROTO

.data

    dbg_str1 BYTE "StrToInt_KL called with: ",0
    dbg_str2 BYTE " -> result = ",0
    ; Lexer state
    lexPos          DWORD 0
    lexLine         DWORD 1
    lexCol          DWORD 1
    lexError        DWORD 0     ; 1 = lexer encountered an error

    ; Working token buffer
    tokBuf          BYTE MAX_TOKEN_LEN DUP(0)
    tokBufLen       DWORD 0

    ; Status strings
    str_lex_start   BYTE "Lexer started...",0
    str_lex_done    BYTE "Lexer complete.",0
    str_tok_count   BYTE "Total tokens: ",0
    str_tok_found   BYTE "Token: ",0
    str_lex_err_str BYTE "Unterminated string literal",0
    str_lex_err_chr BYTE "Unterminated character literal",0
    str_too_many_tok BYTE "Too many tokens (max 4096).",0

    ; Keyword lookup table
    KW_ENTRY_SIZE   EQU 36
    KW_STR_LEN      EQU 32

    kwTable LABEL BYTE
        ; keyword string (32 bytes)               token type (DWORD)
        BYTE "show",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_SHOW
        BYTE "showl",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_SHOWL
        BYTE "print",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_PRINT
        BYTE "ask",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ASK
        BYTE "input",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_INPUT
        BYTE "set",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_SET
        BYTE "let",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_LET
        BYTE "const",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_CONST
        BYTE "var",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_VAR
        BYTE "if",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_IF
        BYTE "then",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_THEN
        BYTE "else",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ELSE
        BYTE "elif",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ELIF
        BYTE "end",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_END
        BYTE "endif",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ENDIF
        BYTE "while",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_WHILE
        BYTE "do",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_DO
        BYTE "for",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_FOR
        BYTE "to",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_TO
        BYTE "step",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_STEP
        BYTE "break",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_BREAK
        BYTE "continue",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_CONTINUE
        BYTE "endwhile",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ENDWHILE
        BYTE "endfor",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ENDFOR
        BYTE "func",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_FUNC
        BYTE "endfunc",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ENDFUNC
        BYTE "return",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_RETURN
        BYTE "call",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_CALL
        BYTE "switch",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_SWITCH
        BYTE "case",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_CASE
        BYTE "default",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_DEFAULT
        BYTE "endswitch",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_ENDSWITCH
        BYTE "show_variables",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_SHOW_VARS
        BYTE "debug_on",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_DEBUG_ON
        BYTE "debug_off",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_DEBUG_OFF
        BYTE "trace_on",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_TRACE_ON
        BYTE "trace_off",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_TRACE_OFF
        BYTE "pause",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_PAUSE
        BYTE "clear",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_CLEAR
        BYTE "wait",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_WAIT
        BYTE "true",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_BOOL_TRUE
        BYTE "false",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_BOOL_FALSE
        BYTE "and",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_AND
        BYTE "or",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_OR
        BYTE "not",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        DWORD TOK_NOT
    KW_COUNT EQU ($ - kwTable) / KW_ENTRY_SIZE

.code

; ============================================================
; RunLexer - Main entry point
; ============================================================
PUBLIC RunLexer
RunLexer PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi

    mov     lexPos, 0
    mov     lexLine, 1
    mov     lexCol, 1
    mov     tokenCount, 0
    mov     lexError, 0

    mov     edx, OFFSET str_lex_start
    call    PrintDebug

_lexMainLoop:
    call    PeekChar
    cmp     eax, -1
    je      _lexDone

    movzx   eax, al

    mov     ecx, tokenCount
    cmp     ecx, MAX_TOKENS - 1
    jge     _lexTooManyTokens

    cmp     al, ' '
    je      _skipWS
    cmp     al, 9
    je      _skipWS
    cmp     al, 13
    je      _skipWS
    cmp     al, 10
    je      _lexNewline
    cmp     al, '#'
    je      _lexComment
    cmp     al, '"'
    je      _lexString
    cmp     al, 39
    je      _lexChar
    cmp     al, '0'
    jl      _notDigit
    cmp     al, '9'
    jg      _notDigit
    call    LexNumber
    jmp     _lexMainLoop
_notDigit:
    cmp     al, 'a'
    jl      _notAlpha1
    cmp     al, 'z'
    jle     _lexIdent
_notAlpha1:
    cmp     al, 'A'
    jl      _notAlpha2
    cmp     al, 'Z'
    jle     _lexIdent
_notAlpha2:
    cmp     al, '_'
    je      _lexIdent
    call    LexOperator
    jmp     _lexMainLoop

_skipWS:
    call    NextChar
    inc     lexCol
    jmp     _lexMainLoop

_lexNewline:
    call    NextChar
    inc     lexLine
    mov     lexCol, 1
    call    EmitNewlineToken
    jmp     _lexMainLoop

_lexComment:
    call    NextChar
_commentLoop:
    call    PeekChar
    cmp     eax, -1
    je      _lexMainLoop
    movzx   eax, al
    cmp     al, 10
    je      _lexMainLoop
    cmp     al, 13
    je      _lexMainLoop
    call    NextChar
    jmp     _commentLoop

_lexString:
    call    LexString
    jmp     _lexMainLoop

_lexChar:
    call    LexChar
    jmp     _lexMainLoop

_lexIdent:
    call    LexIdentOrKeyword
    jmp     _lexMainLoop

_lexDone:
    call    EmitEofToken

    mov     eax, g_debugMode
    cmp     eax, 0
    je      _skipCount

    mov     edx, OFFSET str_tok_count
    call    PrintDebug
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, tokenCount
    call    WriteDec
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor

    call    PrintAllTokens

_skipCount:
    mov     edx, OFFSET str_lex_done
    call    PrintDebug

    ; Check if any lexer error occurred during tokenization
    mov     eax, lexError
    cmp     eax, 0
    jne     _lexHadError
    xor     eax, eax
    jmp     _lexReturn
_lexHadError:
    mov     eax, ERR_SYNTAX
    jmp     _lexReturn

_lexTooManyTokens:
    mov     edx, OFFSET str_too_many_tok
    xor     ebx, ebx
    call    PrintError
    mov     eax, ERR_SYNTAX

_lexReturn:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
RunLexer ENDP

; ============================================================
; PeekChar
; ============================================================
PeekChar PROC
    push    esi
    mov     esi, OFFSET sourceBuffer
    add     esi, lexPos
    mov     eax, lexPos
    cmp     eax, sourceSize
    jge     _peekEOF
    movzx   eax, BYTE PTR [esi]
    pop     esi
    ret
_peekEOF:
    mov     eax, -1
    pop     esi
    ret
PeekChar ENDP

; ============================================================
; NextChar
; ============================================================
NextChar PROC
    push    esi
    mov     esi, OFFSET sourceBuffer
    add     esi, lexPos
    mov     eax, lexPos
    cmp     eax, sourceSize
    jge     _nextEOF
    movzx   eax, BYTE PTR [esi]
    inc     lexPos
    pop     esi
    ret
_nextEOF:
    mov     eax, 0
    pop     esi
    ret
NextChar ENDP

; ============================================================
; EmitToken - FULLY FIXED
; Preserves integer value correctly
; ============================================================
EmitToken PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
    push    eax            ; SAVE INTEGER VALUE

    ; Calculate token slot
    mov     edi, OFFSET tokenArray
    mov     ecx, TOKEN_SIZE
    imul    ecx, tokenCount
    add     edi, ecx

    ; Store token type
    mov     [edi + TOKEN_OFF_TYPE], ebx

    ; ------------------------------------------------
    ; Copy token text/value
    ; ------------------------------------------------
    push    edi
    add     edi, TOKEN_OFF_VALUE

    cmp     esi, 0
    je      _noValue

    push    ecx
    mov     ecx, MAX_TOKEN_LEN - 1

_copyVal:
    cmp     ecx, 0
    je      _forceNull

    mov     al, [esi]
    mov     [edi], al

    cmp     al, 0
    je      _doneCopy

    inc     esi
    inc     edi
    dec     ecx
    jmp     _copyVal

_doneCopy:
    pop     ecx
    jmp     _storeMeta

_forceNull:
    mov     BYTE PTR [edi], 0
    pop     ecx
    jmp     _storeMeta

_noValue:
    mov     BYTE PTR [edi], 0

_storeMeta:
    pop     edi

    ; ------------------------------------------------
    ; Store line and column
    ; ------------------------------------------------
    mov     ecx, lexLine
    mov     [edi + TOKEN_OFF_LINE], ecx

    mov     ecx, lexCol
    mov     [edi + TOKEN_OFF_COL], ecx

    ; ------------------------------------------------
    ; RESTORE REAL INTEGER VALUE
    ; ------------------------------------------------
    pop     eax
    mov     [edi + TOKEN_OFF_IVAL], eax

    ; Increment token count
    inc     tokenCount

    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret

EmitToken ENDP

; ============================================================
; EmitNewlineToken
; ============================================================
EmitNewlineToken PROC
    push    eax
    push    ebx
    push    esi
    mov     ebx, TOK_NEWLINE
    xor     eax, eax
    mov     esi, 0
    call    EmitToken
    pop     esi
    pop     ebx
    pop     eax
    ret
EmitNewlineToken ENDP

; ============================================================
; EmitEofToken
; ============================================================
EmitEofToken PROC
    push    eax
    push    ebx
    push    esi
    mov     ebx, TOK_EOF
    xor     eax, eax
    mov     esi, 0
    call    EmitToken
    pop     esi
    pop     ebx
    pop     eax
    ret
EmitEofToken ENDP

; ============================================================
; LexNumber - FIXED: integer value passed in EAX
; ============================================================
LexNumber PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi

    mov     edi, OFFSET tokBuf
    mov     ecx, 0
    mov     ebx, TOK_INTEGER

_numLoop:
    call    PeekChar
    cmp     eax, -1
    je      _numDone
    movzx   eax, al

    cmp     al, '0'
    jl      _numCheckDot
    cmp     al, '9'
    jg      _numCheckDot
    call    NextChar
    mov     [edi], al
    inc     edi
    inc     ecx
    jmp     _numLoop

_numCheckDot:
    cmp     al, '.'
    jne     _numDone
    cmp     ebx, TOK_FLOAT
    je      _numDone
    mov     ebx, TOK_FLOAT
    call    NextChar
    mov     [edi], al
    inc     edi
    inc     ecx
    jmp     _numLoop

_numDone:
    mov     BYTE PTR [edi], 0

    mov     esi, OFFSET tokBuf
    call    StrToInt_KL         ; EAX = integer value

    ; Emit token: EBX = type, ESI = string, EAX = integer value
    push    ebx
    mov     esi, OFFSET tokBuf
    call    EmitToken
    pop     ebx

    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
LexNumber ENDP

; ============================================================
; LexString
; ============================================================
LexString PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi

    call    NextChar        ; consume opening "

    mov     edi, OFFSET tokBuf
    mov     ecx, 0

_strLoop:
    call    PeekChar
    cmp     eax, -1
    je      _strUnterminated
    movzx   eax, al

    cmp     al, '"'
    je      _strClose
    cmp     al, 10
    je      _strUnterminated

    cmp     al, '\'
    je      _strEscape

    call    NextChar
    mov     [edi], al
    inc     edi
    inc     ecx
    cmp     ecx, MAX_TOKEN_LEN - 2
    jge     _strClose
    jmp     _strLoop

_strEscape:
    call    NextChar
    call    PeekChar
    movzx   eax, al
    call    NextChar

    cmp     al, 'n'
    je      _escNL
    cmp     al, 't'
    je      _escTab
    cmp     al, '"'
    je      _escQuote
    cmp     al, '\'
    je      _escBackslash
    mov     [edi], al
    inc     edi
    inc     ecx
    jmp     _strLoop
_escNL:
    mov     BYTE PTR [edi], 10
    inc     edi
    inc     ecx
    jmp     _strLoop
_escTab:
    mov     BYTE PTR [edi], 9
    inc     edi
    inc     ecx
    jmp     _strLoop
_escQuote:
    mov     BYTE PTR [edi], '"'
    inc     edi
    inc     ecx
    jmp     _strLoop
_escBackslash:
    mov     BYTE PTR [edi], '\'
    inc     edi
    inc     ecx
    jmp     _strLoop

_strClose:
    call    NextChar
    mov     BYTE PTR [edi], 0

    mov     ebx, TOK_STRING
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken
    jmp     _strDone

_strUnterminated:
    mov     BYTE PTR [edi], 0
    mov     edx, OFFSET str_lex_err_str
    mov     ebx, lexLine
    call    PrintError
    mov     lexError, 1

_strDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
LexString ENDP

; ============================================================
; LexChar
; ============================================================
LexChar PROC
    push    eax
    push    ebx
    push    esi

    call    NextChar
    call    PeekChar
    cmp     eax, -1
    je      _charError

    movzx   eax, al
    mov     tokBuf, al
    mov     BYTE PTR tokBuf+1, 0
    call    NextChar

    call    PeekChar
    movzx   eax, al
    cmp     al, 39
    jne     _charError
    call    NextChar

    mov     ebx, TOK_CHAR
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken
    jmp     _charDone

_charError:
    mov     edx, OFFSET str_lex_err_chr
    mov     ebx, lexLine
    call    PrintError
    mov     lexError, 1

_charDone:
    pop     esi
    pop     ebx
    pop     eax
    ret
LexChar ENDP

; ============================================================
; LexIdentOrKeyword
; ============================================================
LexIdentOrKeyword PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi

    mov     edi, OFFSET tokBuf
    mov     ecx, 0

_identLoop:
    call    PeekChar
    cmp     eax, -1
    je      _identDone
    movzx   eax, al

    cmp     al, 'a'
    jl      _identCheckUpper
    cmp     al, 'z'
    jle     _identAddChar
_identCheckUpper:
    cmp     al, 'A'
    jl      _identCheckDigit
    cmp     al, 'Z'
    jle     _identAddChar
_identCheckDigit:
    cmp     al, '0'
    jl      _identCheckUnderscore
    cmp     al, '9'
    jle     _identAddChar
_identCheckUnderscore:
    cmp     al, '_'
    je      _identAddChar
    jmp     _identDone

_identAddChar:
    call    NextChar
    mov     [edi], al
    inc     edi
    inc     ecx
    cmp     ecx, MAX_TOKEN_LEN - 2
    jge     _identDone
    jmp     _identLoop

_identDone:
    mov     BYTE PTR [edi], 0

    mov     esi, OFFSET tokBuf
    call    ToLower_KL

    call    LookupKeyword
    cmp     eax, 0
    je      _emitIdent

    mov     ebx, eax
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken
    jmp     _identReturnOK

_emitIdent:
    mov     ebx, TOK_IDENT
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken

_identReturnOK:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
LexIdentOrKeyword ENDP

; ============================================================
; LookupKeyword
; ============================================================
LookupKeyword PROC
    push    ebx
    push    ecx
    push    esi
    push    edi

    mov     ecx, KW_COUNT
    mov     esi, OFFSET kwTable

_kwLoop:
    cmp     ecx, 0
    jle     _kwNotFound

    push    esi
    mov     edi, OFFSET tokBuf

_kwCmp:
    mov     al, [esi]
    mov     bl, [edi]
    cmp     al, bl
    jne     _kwMismatch
    cmp     al, 0
    je      _kwMatch
    inc     esi
    inc     edi
    jmp     _kwCmp

_kwMatch:
    pop     esi
    mov     eax, [esi + KW_STR_LEN]
    jmp     _kwDone

_kwMismatch:
    pop     esi
    add     esi, KW_ENTRY_SIZE
    dec     ecx
    jmp     _kwLoop

_kwNotFound:
    xor     eax, eax

_kwDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    ret
LookupKeyword ENDP

; ============================================================
; LexOperator
; ============================================================
LexOperator PROC
    push    eax
    push    ebx
    push    ecx
    push    esi

    call    NextChar
    movzx   ecx, al

    mov     BYTE PTR tokBuf, al
    mov     BYTE PTR tokBuf+1, 0

    call    PeekChar
    cmp     eax, -1
    je      _singleOp
    movzx   eax, al

    cmp     cl, '='
    jne     _not_eq_start
    cmp     al, '='
    jne     _singleOp
    call    NextChar
    mov     ebx, TOK_EQ
    jmp     _opEmit2
_not_eq_start:

    cmp     cl, '!'
    jne     _not_neq
    cmp     al, '='
    jne     _singleOp
    call    NextChar
    mov     ebx, TOK_NEQ
    jmp     _opEmit2
_not_neq:

    cmp     cl, '<'
    jne     _not_lte
    cmp     al, '='
    jne     _chk_lt
    call    NextChar
    mov     ebx, TOK_LTE
    jmp     _opEmit2
_chk_lt:
    mov     ebx, TOK_LT
    jmp     _opEmit1
_not_lte:

    cmp     cl, '>'
    jne     _not_gte
    cmp     al, '='
    jne     _chk_gt
    call    NextChar
    mov     ebx, TOK_GTE
    jmp     _opEmit2
_chk_gt:
    mov     ebx, TOK_GT
    jmp     _opEmit1
_not_gte:

    cmp     cl, '+'
    jne     _not_plus_assign
    cmp     al, '='
    jne     _chk_incr
    call    NextChar
    mov     ebx, TOK_PLUS_ASSIGN
    jmp     _opEmit2
_chk_incr:
    cmp     al, '+'
    jne     _chk_plus
    call    NextChar
    mov     ebx, TOK_INCREMENT
    jmp     _opEmit2
_chk_plus:
    mov     ebx, TOK_PLUS
    jmp     _opEmit1
_not_plus_assign:

    cmp     cl, '-'
    jne     _not_minus
    cmp     al, '='
    jne     _chk_decr
    call    NextChar
    mov     ebx, TOK_MINUS_ASSIGN
    jmp     _opEmit2
_chk_decr:
    cmp     al, '-'
    jne     _chk_minus
    call    NextChar
    mov     ebx, TOK_DECREMENT
    jmp     _opEmit2
_chk_minus:
    mov     ebx, TOK_MINUS
    jmp     _opEmit1
_not_minus:

    cmp     cl, '*'
    jne     _not_mul
    cmp     al, '='
    jne     _chk_mul
    call    NextChar
    mov     ebx, TOK_MUL_ASSIGN
    jmp     _opEmit2
_chk_mul:
    mov     ebx, TOK_MULTIPLY
    jmp     _opEmit1
_not_mul:

    cmp     cl, '/'
    jne     _not_div
    cmp     al, '='
    jne     _chk_div
    call    NextChar
    mov     ebx, TOK_DIV_ASSIGN
    jmp     _opEmit2
_chk_div:
    mov     ebx, TOK_DIVIDE
    jmp     _opEmit1
_not_div:

_singleOp:
    mov     al, cl
    cmp     al, '='
    je      _op_assign
    cmp     al, '+'
    je      _op_plus
    cmp     al, '-'
    je      _op_minus
    cmp     al, '*'
    je      _op_mul
    cmp     al, '/'
    je      _op_div
    cmp     al, '%'
    je      _op_mod
    cmp     al, '^'
    je      _op_pow
    cmp     al, '<'
    je      _op_lt
    cmp     al, '>'
    je      _op_gt
    cmp     al, '('
    je      _op_lparen
    cmp     al, ')'
    je      _op_rparen
    cmp     al, '['
    je      _op_lbracket
    cmp     al, ']'
    je      _op_rbracket
    cmp     al, ','
    je      _op_comma
    cmp     al, ':'
    je      _op_colon
    cmp     al, ';'
    je      _op_semi
    cmp     al, '.'
    je      _op_dot
    jmp     _opReturn

_op_assign:     mov ebx, TOK_ASSIGN    ; jmp _opEmit1
    jmp     _opEmit1
_op_plus:       mov ebx, TOK_PLUS
    jmp     _opEmit1
_op_minus:      mov ebx, TOK_MINUS
    jmp     _opEmit1
_op_mul:        mov ebx, TOK_MULTIPLY
    jmp     _opEmit1
_op_div:        mov ebx, TOK_DIVIDE
    jmp     _opEmit1
_op_mod:        mov ebx, TOK_MODULO
    jmp     _opEmit1
_op_pow:        mov ebx, TOK_POWER
    jmp     _opEmit1
_op_lt:         mov ebx, TOK_LT
    jmp     _opEmit1
_op_gt:         mov ebx, TOK_GT
    jmp     _opEmit1
_op_lparen:     mov ebx, TOK_LPAREN
    jmp     _opEmit1
_op_rparen:     mov ebx, TOK_RPAREN
    jmp     _opEmit1
_op_lbracket:   mov ebx, TOK_LBRACKET
    jmp     _opEmit1
_op_rbracket:   mov ebx, TOK_RBRACKET
    jmp     _opEmit1
_op_comma:      mov ebx, TOK_COMMA
    jmp     _opEmit1
_op_colon:      mov ebx, TOK_COLON
    jmp     _opEmit1
_op_semi:       mov ebx, TOK_SEMICOLON
    jmp     _opEmit1
_op_dot:        mov ebx, TOK_DOT
    jmp     _opEmit1

_opEmit1:
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken
    jmp     _opReturn

_opEmit2:
    mov     BYTE PTR tokBuf+1, al
    mov     BYTE PTR tokBuf+2, 0
    xor     eax, eax
    mov     esi, OFFSET tokBuf
    call    EmitToken

_opReturn:
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
LexOperator ENDP

; ============================================================
; StrToInt_KL - FIXED: correctly converts multi-digit numbers
; ============================================================
PUBLIC StrToInt_KL
StrToInt_KL PROC
    ; BUG FIX: Do NOT push/pop EAX - EAX is the return value register!
    ; Old code: push eax at start, pop eax at end -> destroyed the result!
    push    ebx
    push    ecx
    push    edx
    push    esi

    xor     eax, eax        ; result = 0
    xor     ecx, ecx        ; sign = 0 (positive)
    mov     bl, [esi]
    cmp     bl, '-'
    jne     @F
    inc     esi
    mov     ecx, 1
@@:
    xor     ebx, ebx
_convertLoop:
    mov     bl, [esi]
    cmp     bl, 0
    je      _convDone
    cmp     bl, '0'
    jb      _convDone
    cmp     bl, '9'
    ja      _convDone
    sub     bl, '0'
    ; Multiply by 10 using addition (safe)
    push    edx
    mov     edx, eax        ; save original
    shl     eax, 1          ; *2
    add     eax, edx        ; *3
    add     eax, edx        ; *4
    add     eax, edx        ; *5
    add     eax, edx        ; *6
    add     eax, edx        ; *7
    add     eax, edx        ; *8
    add     eax, edx        ; *9
    add     eax, edx        ; *10
    pop     edx
    add     eax, ebx
    inc     esi
    jmp     _convertLoop
_convDone:
    cmp     ecx, 1
    jne     @F
    neg     eax
@@:
    ; result is in EAX, ready to return
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret                     ; EAX = correct integer result
StrToInt_KL ENDP


; ============================================================
; PrintAllTokens
; ============================================================
PrintAllTokens PROC
    push    eax
    push    ebx
    push    ecx
    push    edx
    push    esi

    mov     eax, g_debugMode
    cmp     eax, 0
    je      _paTDone

    mov     ecx, 0

_patLoop:
    cmp     ecx, tokenCount
    jge     _paTDone

    push    ecx
    mov     eax, TOKEN_SIZE
    imul    eax, ecx
    mov     esi, OFFSET tokenArray
    add     esi, eax

    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_tok_found
    call    WriteString

    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     eax, [esi + TOKEN_OFF_TYPE]
    call    WriteDec

    mov     al, ' '
    call    WriteChar

    mov     eax, YELLOW_C + (BLACK_C * 16)
    call    SetTextColor
    lea     edx, [esi + TOKEN_OFF_VALUE]
    cmp     BYTE PTR [edx], 0
    je      _skipVal
    mov     al, '"'
    call    WriteChar
    call    WriteString
    mov     al, '"'
    call    WriteChar
_skipVal:

    mov     eax, DARKGRAY_C + (BLACK_C * 16)
    call    SetTextColor
    mov     al, ' '
    call    WriteChar
    mov     al, 'L'
    call    WriteChar
    mov     eax, [esi + TOKEN_OFF_LINE]
    call    WriteDec
    call    Crlf

    pop     ecx
    inc     ecx
    jmp     _patLoop

_paTDone:
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    ret
PrintAllTokens ENDP

END