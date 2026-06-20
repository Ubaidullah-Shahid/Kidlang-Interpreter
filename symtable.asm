; ============================================================
; Symbol Table Management
; Handles: variable creation, lookup, update, deletion
; Supports: integers, floats, strings, chars, booleans
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
EXTERN varTable         : BYTE
EXTERN varCount         : DWORD
EXTERN g_debugMode      : DWORD
PrintDebug      PROTO
PrintError      PROTO
PrintTrace      PROTO
ToLower_KL      PROTO
StrCopy_KL      PROTO
StrCompare_KL   PROTO
 
.data
    str_var_created     BYTE "Variable created: ",0
    str_var_updated     BYTE "Variable updated: ",0
    str_var_notfound    BYTE "Variable not found: ",0
    str_var_toomany     BYTE "Too many variables (max 256).",0
    str_const_write     BYTE "Cannot modify constant: ",0
    str_sym_eq          BYTE " = ",0
    str_sym_newline     BYTE 0
    
    ; Temp name buffer
    nameBuf         BYTE MAX_TOKEN_LEN DUP(0)
 
.code
 
; ============================================================
; FindVariable - Look up variable by name
; Parameters: ESI = variable name string (null-terminated)
; Returns: EAX = pointer to variable entry, 0 if not found
;          EDI = variable entry pointer (same as EAX)
; ============================================================
PUBLIC FindVariable
FindVariable PROC
    push    ebx
    push    ecx
    push    esi
    push    edi
    
    ; Normalize name to lowercase
    mov     edi, OFFSET nameBuf
    mov     ecx, MAX_TOKEN_LEN - 1
    ; Copy ESI to nameBuf
    push    esi
    push    edi
_fvCopy:
    cmp     ecx, 0
    je      _fvCopyDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _fvCopyDone
    inc     esi
    inc     edi
    dec     ecx
    jmp     _fvCopy
_fvCopyDone:
    mov     BYTE PTR [edi], 0
    pop     edi
    pop     esi
    
    ; Lowercase the name
    push    esi
    mov     esi, OFFSET nameBuf
    call    ToLower_KL
    pop     esi
    
    ; Search varTable
    mov     ecx, 0          ; index
    
_fvLoop:
    cmp     ecx, varCount
    jge     _fvNotFound
    
    ; Compute address of this entry
    push    ecx
    mov     eax, VAR_SIZE
    imul    eax, ecx
    mov     edi, OFFSET varTable
    add     edi, eax        ; edi = entry pointer
    
    ; Compare names (StrCompare_KL saves esi/edi internally)
    mov     esi, OFFSET nameBuf
    ; edi already points to name field (offset 0)
    call    StrCompare_KL
    
    cmp     eax, 0
    je      _fvFound
    
    pop     ecx
    inc     ecx
    jmp     _fvLoop
 
_fvFound:
    pop     ecx
    mov     eax, edi        ; return pointer to entry
    jmp     _fvDone
 
_fvNotFound:
    xor     eax, eax        ; return NULL
 
_fvDone:
    ; FIX: restore saved registers WITHOUT losing EAX return value
    ; Stack at this point has: [saved_edi, saved_esi, saved_ecx, saved_ebx]
    ; We saved edi/esi/ecx/ebx at entry, but we must NOT pop into edi
    ; because that would overwrite EAX indirectly (it doesn't - pop edi goes to EDI)
    ; The original bug: "mov edi, eax" then "pop edi" overwrites EDI with stack value
    ; Fix: just restore from stack normally; EAX is safe since we never push EAX
    pop     edi             ; restores caller's EDI (our local EDI is no longer needed)
    pop     esi
    pop     ecx
    pop     ebx
    ; EAX still holds return value - untouched by the pops above
    ret
FindVariable ENDP
 
; ============================================================
; CreateVariable - Create new variable entry
; Parameters: ESI = name string
;             EBX = type (VTYPE_xxx)
; Returns: EAX = pointer to new entry, 0 if table full
; ============================================================
PUBLIC CreateVariable
CreateVariable PROC
    push    ebx
    push    ecx
    push    esi
    push    edi
    
    ; Check if already exists
    push    ebx
    call    FindVariable
    pop     ebx
    cmp     eax, 0
    jne     _cvExists   ; already exists - return it
    
    ; Check if table full
    mov     eax, varCount
    cmp     eax, MAX_VARIABLES
    jge     _cvFull
    
    ; Compute new entry address
    mov     eax, VAR_SIZE
    imul    eax, varCount
    mov     edi, OFFSET varTable
    add     edi, eax
    
    ; Clear the entry
    push    edi
    push    ecx
    mov     ecx, VAR_SIZE
_cvClear:
    mov     BYTE PTR [edi], 0
    inc     edi
    loop    _cvClear
    pop     ecx
    pop     edi
    
    ; Copy name (normalized to lowercase) to entry
    push    esi
    push    edi
    
    ; First copy to nameBuf and lowercase
    push    esi
    push    edi
    mov     edi, OFFSET nameBuf
    mov     ecx, MAX_TOKEN_LEN - 1
_cvNameCopy:
    cmp     ecx, 0
    je      _cvNameDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _cvNameDone
    inc     esi
    inc     edi
    dec     ecx
    jmp     _cvNameCopy
_cvNameDone:
    mov     BYTE PTR [edi], 0
    pop     edi
    pop     esi
    
    push    esi
    mov     esi, OFFSET nameBuf
    call    ToLower_KL
    pop     esi
    
    ; Copy lowercased name to entry
    pop     edi
    push    edi
    mov     esi, OFFSET nameBuf
    mov     ecx, 127
    call    StrCopy_KL
    pop     edi
    pop     esi
    
    ; Set type
    mov     [edi + VAR_OFF_TYPE], ebx
    
    ; Initialize to zero
    mov     DWORD PTR [edi + VAR_OFF_IVAL], 0
    mov     BYTE PTR [edi + VAR_OFF_BVAL], 0
    
    ; Increment count
    inc     varCount
    
    ; Debug trace
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _cvNoDebug
    
    mov     eax, LIGHTGREEN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_var_created
    call    WriteString
    mov     edx, edi        ; point to name in entry
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_cvNoDebug:
    mov     eax, edi        ; return pointer
    jmp     _cvDone
 
_cvExists:
    ; Variable already exists - just return the existing entry
    ; EAX already = pointer
    jmp     _cvDone
 
_cvFull:
    mov     edx, OFFSET str_var_toomany
    xor     ebx, ebx
    call    PrintError
    xor     eax, eax
 
_cvDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    ret
CreateVariable ENDP
 
; ============================================================
; SetVarInt - Set variable to integer value
; Parameters: ESI = name string
;             EAX = integer value
; Returns: EDI = pointer to variable entry
; ============================================================
PUBLIC SetVarInt
SetVarInt PROC
    push    eax
    push    ebx
    push    ecx
    
    push    eax             ; save value
    
    ; Find or create variable
    mov     ebx, VTYPE_INTEGER
    call    FindVariable
    cmp     eax, 0
    jne     _sviFound
    
    ; Create new variable
    mov     ebx, VTYPE_INTEGER
    call    CreateVariable
    cmp     eax, 0
    je      _sviError
 
_sviFound:
    mov     edi, eax
    
    ; Check if constant
    movzx   ecx, BYTE PTR [edi + VAR_OFF_ISCONST]
    cmp     ecx, 1
    je      _sviConst
    
    ; Set type to integer
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_INTEGER
    
    ; Set value
    pop     eax             ; restore saved value
    mov     [edi + VAR_OFF_IVAL], eax
    
    ; Debug trace
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _sviDone
    
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_var_updated
    call    WriteString
    mov     edx, edi
    call    WriteString
    mov     edx, OFFSET str_sym_eq
    call    WriteString
    mov     eax, [edi + VAR_OFF_IVAL]
    call    WriteDec
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
    
    jmp     _sviDone
 
_sviConst:
    pop     eax
    mov     edx, OFFSET str_const_write
    xor     ebx, ebx
    call    PrintError
    jmp     _sviDone
 
_sviError:
    pop     eax
 
_sviDone:
    pop     ecx
    pop     ebx
    pop     eax
    ret
SetVarInt ENDP
 
; ============================================================
; SetVarFloat - Set variable to float value
; Parameters: ESI = name string
;             ST(0) = float value (on FPU stack)
; Returns: EDI = pointer to variable entry
; ============================================================
PUBLIC SetVarFloat
SetVarFloat PROC
    push    eax
    push    ebx
    
    mov     ebx, VTYPE_FLOAT
    call    FindVariable
    cmp     eax, 0
    jne     _svfFound
    
    call    CreateVariable
    cmp     eax, 0
    je      _svfError
 
_svfFound:
    mov     edi, eax
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_FLOAT
    fstp    DWORD PTR [edi + VAR_OFF_FVAL]  ; store float from FPU
    jmp     _svfDone
 
_svfError:
_svfDone:
    pop     ebx
    pop     eax
    ret
SetVarFloat ENDP
 
; ============================================================
; SetVarString - Set variable to string value
; Parameters: ESI = name string (variable name)
;             EDI = string value to store
; Note: After call, EDI is corrupted - save it before call
; ============================================================
PUBLIC SetVarString
SetVarString PROC
    push    eax
    push    ebx
    push    ecx
    push    esi
    push    edi
    
    ; Save string value pointer
    mov     ecx, edi        ; ecx = string value
    
    mov     ebx, VTYPE_STRING
    call    FindVariable
    cmp     eax, 0
    jne     _svsFound
    
    call    CreateVariable
    cmp     eax, 0
    je      _svsError
 
_svsFound:
    mov     edi, eax
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_STRING
    
    ; Copy string value to SVAL field
    push    esi
    lea     edi, [edi + VAR_OFF_SVAL]   ; edi = destination
    mov     esi, ecx                    ; esi = source (string value)
    mov     ecx, MAX_STRING_LEN - 1
_svsCopy:
    cmp     ecx, 0
    je      _svsCopyDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _svsCopyDone
    inc     esi
    inc     edi
    dec     ecx
    jmp     _svsCopy
_svsCopyDone:
    mov     BYTE PTR [edi], 0
    pop     esi
    
    jmp     _svsDone
 
_svsError:
_svsDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    pop     eax
    ret
SetVarString ENDP
 
; ============================================================
; SetVarBool - Set variable to boolean value
; Parameters: ESI = name string
;             EAX = 0 or 1
; ============================================================
PUBLIC SetVarBool
SetVarBool PROC
    push    eax
    push    ebx
    push    ecx
    
    push    eax
    mov     ebx, VTYPE_BOOL
    call    FindVariable
    cmp     eax, 0
    jne     _svbFound
    call    CreateVariable
    cmp     eax, 0
    je      _svbErr
 
_svbFound:
    mov     edi, eax
    mov     DWORD PTR [edi + VAR_OFF_TYPE], VTYPE_BOOL
    pop     eax
    mov     BYTE PTR [edi + VAR_OFF_BVAL], al
    jmp     _svbDone
 
_svbErr:
    pop     eax
_svbDone:
    pop     ecx
    pop     ebx
    pop     eax
    ret
SetVarBool ENDP
 
; ============================================================
; GetVarInt - Get integer value of variable
; Parameters: ESI = variable name
; Returns: EAX = integer value, EDX = 0 if ok / 1 if not found
; ============================================================
PUBLIC GetVarInt
GetVarInt PROC
    push    ebx
    push    esi
    
    call    FindVariable
    cmp     eax, 0
    je      _gviNotFound
    
    mov     edi, eax
    mov     eax, [edi + VAR_OFF_TYPE]
    
    ; If it's an integer, get ival
    cmp     eax, VTYPE_INTEGER
    je      _gviIsInt
    
    ; If bool, return bval as int
    cmp     eax, VTYPE_BOOL
    je      _gviIsBool
    
    ; Otherwise return 0
    xor     eax, eax
    xor     edx, edx
    jmp     _gviDone
 
_gviIsInt:
    mov     eax, [edi + VAR_OFF_IVAL]
    xor     edx, edx
    jmp     _gviDone
 
_gviIsBool:
    movzx   eax, BYTE PTR [edi + VAR_OFF_BVAL]
    xor     edx, edx
    jmp     _gviDone
 
_gviNotFound:
    xor     eax, eax
    mov     edx, 1          ; not found flag
 
_gviDone:
    pop     esi
    pop     ebx
    ret
GetVarInt ENDP
 
; ============================================================
; GetVarString - Get string value of variable
; Parameters: ESI = variable name
;             EDI = output buffer
;             ECX = max length
; Returns: EAX = 0 ok, 1 not found; EDI filled
; ============================================================
PUBLIC GetVarString
GetVarString PROC
    push    ebx
    push    ecx
    push    esi
    push    edi
    
    push    edi
    push    ecx
    
    call    FindVariable
    cmp     eax, 0
    je      _gvsNotFound
    
    mov     esi, eax
    pop     ecx
    pop     edi
    
    mov     eax, [esi + VAR_OFF_TYPE]
    
    cmp     eax, VTYPE_STRING
    je      _gvsIsString
    cmp     eax, VTYPE_INTEGER
    je      _gvsIsInt
    cmp     eax, VTYPE_BOOL
    je      _gvsIsBool
    cmp     eax, VTYPE_CHAR
    je      _gvsIsChar
    
    ; Float - just copy "float"
    mov     BYTE PTR [edi], '?'
    mov     BYTE PTR [edi+1], 0
    xor     eax, eax
    jmp     _gvsDone
 
_gvsIsString:
    ; Copy sval to output
    push    esi
    lea     esi, [esi + VAR_OFF_SVAL]
_gvsStrCopy:
    cmp     ecx, 1
    je      _gvsStrDone
    mov     al, [esi]
    mov     [edi], al
    cmp     al, 0
    je      _gvsStrDone
    inc     esi
    inc     edi
    dec     ecx
    jmp     _gvsStrCopy
_gvsStrDone:
    mov     BYTE PTR [edi], 0
    pop     esi
    xor     eax, eax
    jmp     _gvsDone
 
_gvsIsInt:
    ; Convert integer to string
    push    edi
    mov     eax, [esi + VAR_OFF_IVAL]
    ; Use WriteDec equivalent - simple conversion
    ; Store in buffer
    call    IntToStr_Simple
    pop     edi
    xor     eax, eax
    jmp     _gvsDone
 
_gvsIsBool:
    movzx   eax, BYTE PTR [esi + VAR_OFF_BVAL]
    cmp     al, 1
    je      _gvsTrueStr
    ; "false"
    mov     BYTE PTR [edi+0], 'f'
    mov     BYTE PTR [edi+1], 'a'
    mov     BYTE PTR [edi+2], 'l'
    mov     BYTE PTR [edi+3], 's'
    mov     BYTE PTR [edi+4], 'e'
    mov     BYTE PTR [edi+5], 0
    jmp     _gvsBoolDone
_gvsTrueStr:
    mov     BYTE PTR [edi+0], 't'
    mov     BYTE PTR [edi+1], 'r'
    mov     BYTE PTR [edi+2], 'u'
    mov     BYTE PTR [edi+3], 'e'
    mov     BYTE PTR [edi+4], 0
_gvsBoolDone:
    xor     eax, eax
    jmp     _gvsDone
 
_gvsIsChar:
    mov     al, [esi + VAR_OFF_CVAL]
    mov     [edi], al
    mov     BYTE PTR [edi+1], 0
    xor     eax, eax
    jmp     _gvsDone
 
_gvsNotFound:
    pop     ecx
    pop     edi
    ; Write empty string
    mov     BYTE PTR [edi], 0
    mov     eax, 1          ; not found
 
_gvsDone:
    pop     edi
    pop     esi
    pop     ecx
    pop     ebx
    ret
GetVarString ENDP
 
; Helper: convert EAX integer to string at EDI
IntToStr_Simple PROC
    push    eax
    push    ebx
    push    ecx
    push    edx
    
    cmp     eax, 0
    jge     _itsPos
    mov     BYTE PTR [edi], '-'
    inc     edi
    neg     eax
_itsPos:
    cmp     eax, 0
    jne     _itsNonZero
    mov     BYTE PTR [edi], '0'
    inc     edi
    mov     BYTE PTR [edi], 0
    jmp     _itsDone
_itsNonZero:
    mov     ecx, 0
    mov     ebx, 10
_itsDigit:
    cmp     eax, 0
    je      _itsFlush
    xor     edx, edx
    div     ebx
    push    edx
    inc     ecx
    jmp     _itsDigit
_itsFlush:
    cmp     ecx, 0
    je      _itsNull
    pop     eax
    add     al, '0'
    mov     [edi], al
    inc     edi
    dec     ecx
    jmp     _itsFlush
_itsNull:
    mov     BYTE PTR [edi], 0
_itsDone:
    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    ret
IntToStr_Simple ENDP
 
END