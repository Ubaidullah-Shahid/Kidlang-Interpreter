# KidLang - Build Instructions & Bug Fix Notes

## Required Folder Structure

```
KidLang/
├── KidLang.sln
├── KidLang.vcxproj
├── src/
│   ├── main.asm
│   ├── runtime.asm
│   ├── lexer.asm
│   ├── parser.asm
│   ├── evaluator.asm
│   ├── symtable.asm
│   ├── executor.asm
│   ├── fileio.asm
│   ├── debugger.asm
│   └── shell.asm
├── include/
│   ├── defines.inc
│   └── globals.inc
├── programs/
│   ├── hello.kid
│   ├── variables.kid
│   ├── conditions.kid
│   └── ... (other .kid files)
└── docs/
    └── build_instructions.md  ← this file
```

> ⚠️ **IMPORTANT**: The `.asm` files MUST be inside the `src\` subfolder.
> They use `INCLUDE ..\include\defines.inc` which requires this structure.
> Do NOT put all files flat in one folder.

---

## Setup Steps in Visual Studio 2022

### 1. Install Irvine32
- Download Irvine32 from: http://asmirvine.com/
- Install to `C:\Irvine\` (default)
- Set the `IRVINE` environment variable:
  - Right-click My Computer → Properties → Advanced → Environment Variables
  - Add new System Variable: `IRVINE` = `C:\Irvine`

### 2. Open Project
- Open `KidLang.sln` in Visual Studio 2022
- Set platform to **Win32** (x86) — NOT x64

### 3. Configure MASM Build Customization
- Right-click Project → Build Dependencies → Build Customizations
- Check ✅ `masm(.targets, .props)`

### 4. Verify Include Paths
In project Properties → MASM → General → Include Paths, confirm:
```
$(IRVINE);$(ProjectDir)include;%(IncludePaths)
```

### 5. Build
- Build → Build Solution (Ctrl+Shift+B)
- Output: `build\Debug\KidLang.exe`

---

## Bugs Fixed in This Version

### Bug 1: `empty (null) string` MASM Error
**Files:** `executor.asm` line 66, `symtable.asm` line 29

**Cause:** MASM does not allow `BYTE "",0` — an empty string literal.

**Fix:** Changed to `BYTE 0` (just a null terminator).

---

### Bug 2: `WriteFloat` Linker Error
**Files:** `executor.asm`, `runtime.asm`

**Cause:** Irvine32 library does NOT have a `WriteFloat` procedure.

**Fix:** Replaced with `WriteInt` (displays the integer representation).

---

### Bug 3: Second `.data` Section After `.code`
**Files:** `executor.asm`, `shell.asm`, `main.asm`

**Cause:** MASM allows multiple `.data` sections but it can confuse the assembler
when a `.data` appears after `.code` at the end of a file.

**Fix:** Moved all data declarations into the first `.data` section at the top.

---

### Bug 4: Empty String Lines in `shell.asm` Multi-line BYTE
**File:** `shell.asm`

**Cause:** Lines like `"",13,10,\` inside a multi-line BYTE definition cause
the same `empty (null) string` error.

**Fix:** Replaced `"",13,10,\` with just `13,10,\` (the CRLF without the empty string).

---

### Bug 5: File Structure (Flat vs Subfolders)
**Cause:** Original zip had all files in one flat folder `kola\`, but the `.asm`
files use `INCLUDE ..\include\defines.inc` which only works if they are in a `src\` subfolder.

**Fix:** Proper folder structure with `src\`, `include\`, `programs\`, `docs\`.

---

## Running KidLang

```
KidLang.exe
```

When the menu appears:
1. Run File    — enter a .kid filename (e.g. `programs\hello.kid`)
2. Debug Mode  — shows tokens, variables, trace
3. Step Mode   — press ENTER for each line
4. Interactive — type KidLang commands directly
5. Help        — language syntax guide
6. Exit

---

## KidLang Syntax Quick Reference

```
# Comment
SET name = "Ali"
SET age  = 15
SHOW "Hello"
SHOW name
ASK age

IF age > 18 THEN
    SHOW "Adult"
ELSE
    SHOW "Young"
END

FOR i = 1 TO 5 DO
    SHOW i
END

WHILE x < 10 DO
    x++
END

FUNC add(a, b)
    RETURN a + b
ENDFUNC

SET result = CALL add(3, 4)
SHOW_VARIABLES
```
