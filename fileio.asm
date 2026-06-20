; ============================================================
; File I/O subsystem  reads .kid source files from disk
; Uses Win32 API through Irvine32 for file operations
; ============================================================
 
INCLUDE Irvine32.inc
INCLUDE defines.inc
INCLUDE globals.inc
 
; Access globals
EXTERN sourceBuffer     : BYTE
EXTERN sourceSize       : DWORD
EXTERN sourceFilename   : BYTE
EXTERN g_debugMode      : DWORD
PrintInfo       PROTO
PrintDebug      PROTO
PrintError      PROTO
 
.data
    ; File handle storage
    fileHandle          DWORD 0
    bytesRead           DWORD 0
    
    ; Status messages
    str_reading         BYTE "Reading source file: ",0
    str_read_ok         BYTE "Source file loaded successfully.",0
    str_read_fail       BYTE "Cannot open source file.",0
    str_read_empty      BYTE "Source file is empty.",0
    str_read_toobig     BYTE "Source file too large (max 64KB).",0
    str_file_size       BYTE "File size (bytes): ",0
    str_file_lines      BYTE "Lines in source: ",0
    str_no_filename     BYTE "No filename provided.",0
    
    ; Line count result
    lineCount           DWORD 0
 
.code
 
; ============================================================
; ReadSourceFile - Read a .kid source file into sourceBuffer
; Returns: EAX = 0 on success, non-zero on error
; ============================================================
PUBLIC ReadSourceFile
ReadSourceFile PROC
    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
 
    ; Check if filename is provided
    mov     al, sourceFilename
    cmp     al, 0
    jne     _hasFilename
    
    ; No filename - try default "program.kid"
    mov     esi, OFFSET sourceFilename
    mov     BYTE PTR [esi+0], 'p'
    mov     BYTE PTR [esi+1], 'r'
    mov     BYTE PTR [esi+2], 'o'
    mov     BYTE PTR [esi+3], 'g'
    mov     BYTE PTR [esi+4], 'r'
    mov     BYTE PTR [esi+5], 'a'
    mov     BYTE PTR [esi+6], 'm'
    mov     BYTE PTR [esi+7], '.'
    mov     BYTE PTR [esi+8], 'k'
    mov     BYTE PTR [esi+9], 'i'
    mov     BYTE PTR [esi+10], 'd'
    mov     BYTE PTR [esi+11], 0
 
_hasFilename:
    ; Print info about what we are reading
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _skipReadInfo
    
    mov     edx, OFFSET str_reading
    call    PrintDebug
    
    ; Print filename
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET sourceFilename
    call    WriteString
    call    Crlf
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_skipReadInfo:
 
    ; Open file for reading
    mov     edx, OFFSET sourceFilename
    call    OpenInputFile
    cmp     eax, INVALID_HANDLE_VALUE
    je      _fileOpenError
    
    mov     fileHandle, eax
 
    ; Read file contents into sourceBuffer
    mov     eax, fileHandle
    mov     edx, OFFSET sourceBuffer
    mov     ecx, MAX_SOURCE_SIZE - 1    ; leave room for null
    call    ReadFromFile
    cmp     eax, 0
    je      _fileReadError
    
    ; Store actual bytes read
    mov     sourceSize, eax
    
    ; Null-terminate the buffer
    mov     esi, OFFSET sourceBuffer
    add     esi, eax
    mov     BYTE PTR [esi], 0
 
    ; Close file
    mov     eax, fileHandle
    call    CloseFile
 
    ; Check if empty
    cmp     sourceSize, 0
    je      _fileEmpty
 
    ; Debug: show file size and line count
    mov     eax, g_debugMode
    cmp     eax, 0
    je      _readSuccess
    
    mov     edx, OFFSET str_read_ok
    call    PrintInfo
    
    ; Count lines
    call    CountLines
    
    mov     eax, LIGHTCYAN_C + (BLACK_C * 16)
    call    SetTextColor
    mov     edx, OFFSET str_file_size
    call    WriteString
    mov     eax, sourceSize
    call    WriteDec
    call    Crlf
    
    mov     edx, OFFSET str_file_lines
    call    WriteString
    mov     eax, lineCount
    call    WriteDec
    call    Crlf
    
    mov     eax, WHITE_C + (BLACK_C * 16)
    call    SetTextColor
 
_readSuccess:
    xor     eax, eax            ; return 0 = success
    jmp     _readDone
 
_fileOpenError:
    mov     edx, OFFSET str_read_fail
    call    PrintError
    mov     eax, ERR_FILE_NOT_FOUND
    jmp     _readDone
 
_fileReadError:
    mov     eax, fileHandle
    call    CloseFile
    mov     edx, OFFSET str_read_fail
    call    PrintError
    mov     eax, ERR_FILE_READ
    jmp     _readDone
 
_fileEmpty:
    mov     edx, OFFSET str_read_empty
    call    PrintError
    mov     eax, ERR_FILE_READ
 
_readDone:
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
    ret
ReadSourceFile ENDP
 
; ============================================================
; CountLines - Count newlines in sourceBuffer
; Sets lineCount variable
; ============================================================
CountLines PROC
    push    eax
    push    esi
    push    ecx
    
    mov     esi, OFFSET sourceBuffer
    mov     ecx, sourceSize
    mov     lineCount, 1        ; start at line 1
    
_countLoop:
    cmp     ecx, 0
    je      _countDone
    
    mov     al, [esi]
    cmp     al, 10              ; LF newline
    jne     _notNL
    inc     lineCount
_notNL:
    inc     esi
    dec     ecx
    jmp     _countLoop
 
_countDone:
    pop     ecx
    pop     esi
    pop     eax
    ret
CountLines ENDP
 
; ============================================================
; GetSourceLine - Extract a specific line from sourceBuffer
; Parameters: EAX = line number (1-based)
;             EDI = output buffer
;             ECX = max output length
; Returns: EAX = length of line extracted
; ============================================================
PUBLIC GetSourceLine
GetSourceLine PROC
    push    ebx
    push    esi
    push    ecx
    push    edi
    
    mov     ebx, eax            ; ebx = target line number
    mov     esi, OFFSET sourceBuffer
    mov     eax, 1              ; current line counter
    
    ; Find the start of the target line
_findLineStart:
    cmp     eax, ebx
    je      _foundLine
    
    ; Scan to end of current line
_scanToNL:
    mov     dl, [esi]
    cmp     dl, 0
    je      _lineNotFound       ; EOF
    inc     esi
    cmp     dl, 10              ; LF
    je      _nextLine
    jmp     _scanToNL
_nextLine:
    inc     eax
    jmp     _findLineStart
 
_foundLine:
    ; Now copy characters until newline or EOF
    xor     eax, eax            ; length counter
_copyLine:
    cmp     ecx, 1
    je      _lineEnd            ; no more room
    mov     dl, [esi]
    cmp     dl, 0
    je      _lineEnd
    cmp     dl, 10
    je      _lineEnd
    cmp     dl, 13
    je      _lineEnd
    mov     [edi], dl
    inc     esi
    inc     edi
    inc     eax
    dec     ecx
    jmp     _copyLine
_lineEnd:
    mov     BYTE PTR [edi], 0
    jmp     _getLineDone
 
_lineNotFound:
    xor     eax, eax
    mov     BYTE PTR [edi], 0
 
_getLineDone:
    pop     edi
    pop     ecx
    pop     esi
    pop     ebx
    ret
GetSourceLine ENDP
 
END