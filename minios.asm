;=============================================
;                 MiniOS(8060)
;                CSE341 Project                      
;=============================================
;
;Features:
;         1. User login 
;         2. File Manager
;         3. Calculator
;         4. Notepad
;         5. Task Manager
;         6. Command Prompt 
;         7. Command History
;         8. System Clock
;
;=============================================

.MODEL SMALL
 
.STACK 100H

.DATA    




; ================= DATA VARIABLES =================
; --- Login Data ---
ADMIN_USER   DB 'admin$'       ; Hardcoded Username
ADMIN_PASS   DB '1234$'        ; Hardcoded Password
INPUT_USER   DB 20 DUP('$')    ; Buffer for user input
INPUT_PASS   DB 20 DUP('$')    ; Buffer for password input

; --- File Manager Data ---
FILE_NAMES      DB 5 DUP('EMPTY   $') ; 5 slots, 9 bytes each (8 chars + '$')
FM_MENU_MSG     DB 0DH, 0AH, '--- File Manager ---', 0DH, 0AH
                DB '1. List Files', 0DH, 0AH
                DB '2. Create File', 0DH, 0AH
                DB '3. Delete File', 0DH, 0AH
                DB '4. Back to Main Menu', 0DH, 0AH
                DB 'Choice: $'
                
FILE_MSG_3      DB 0DH, 0AH, 'File List: $'              ; <--- THIS WAS MISSING
FILE_MSG_CREATE DB 0DH, 0AH, 'Enter filename (Max 8 chars): $'
FILE_MSG_DEL    DB 0DH, 0AH, 'Enter filename to delete: $'
FILE_CREATED    DB 0DH, 0AH, 'File Created!$'
FILE_DELETED    DB 0DH, 0AH, 'File Deleted!$'
FILE_NOT_FOUND  DB 0DH, 0AH, 'Error: File not found.$'
FILE_FULL_MSG   DB 0DH, 0AH, 'Error: Storage Full.$'

; --- Calculator Data ---
CALC_MSG_1   DB 0DH, 0AH, 'Enter first number: $'
CALC_MSG_2   DB 0DH, 0AH, 'Enter operator (+,-,*,/): $'
CALC_MSG_3   DB 0DH, 0AH, 'Enter second number: $'
RESULT_MSG   DB 0DH, 0AH, 'Result: $'

; --- Notepad Data ---
NOTE_BUFFER  DB 200 DUP('$')   ; 200 Char storage
NOTE_MSG     DB 0DH, 0AH, '--- Notepad (Press ESC to exit) ---', 0DH, 0AH, '$'

; --- System Clock Data ---
TIME_MSG     DB 0DH, 0AH, 'Current System Time: $'







        ;==================== System Messages =================
        stance_msg DB 0DH,0AH,'===================================',0DH,0AH ; ODH --> 13 CR, 0AH --> 10 LF
                   DB '      Welcome to MiniOS (8060)      ',0DH,0AH
                   DB '===================================',0DH,0AH,'$'

        login_msg  DB 0DH,0AH,'Enter Username: $'
        pass_msg   DB 0DH,0AH,'Enter Password: $'
        login_success_msg DB 0DH,0AH,'Login Successful! Welcome, $'
        login_fail_msg    DB 0DH,0AH,'Login Failed! Try Again.$'
        
        main_menu_msg DB 0DH,0AH,'-------------Main Menu:-------------',0DH,0AH
                      DB '1. File Manager',0DH,0AH
                      DB '2. Calculator',0DH,0AH
                      DB '3. Notepad',0DH,0AH
                      DB '4. Task Manager',0DH,0AH
                      DB '5. Command Prompt',0DH,0AH
                      DB '6. Command History',0DH,0AH
                      DB '7. System Clock',0DH,0AH
                      DB '8. Exit',0DH,0AH
                      DB '------------------------------------',0DH,0AH
                      DB 'Enter choice: $'
        ;======================================================







.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    CALL clear_screen
    
    ; --- 1. LOGIN SYSTEM ---
    LEA DX, stance_msg     ; Welcome Banner
    CALL print_string
    
LOGIN_RETRY:
    ; Get Username
    LEA DX, login_msg
    CALL print_string
    LEA DI, INPUT_USER     ; Point DI to buffer
    MOV CX, 10             ; Max length
    CALL read_string       

    ; Get Password (MASKED)
    LEA DX, pass_msg
    CALL print_string
    LEA DI, INPUT_PASS
    CALL read_password     

    ; Verify Credentials
    LEA SI, ADMIN_USER
    LEA DI, INPUT_USER
    CALL comp_strings      ; Your existing proc
    CMP AL, 0
    JNE LOGIN_FAIL
    
    LEA SI, ADMIN_PASS
    LEA DI, INPUT_PASS
    CALL comp_strings
    CMP AL, 0
    JNE LOGIN_FAIL
    
    LEA DX, login_success_msg
    CALL print_string
    JMP MAIN_MENU_LOOP

LOGIN_FAIL:
    LEA DX, login_fail_msg
    CALL print_string
    JMP LOGIN_RETRY

; --- 2. MAIN MENU LOOP ---
MAIN_MENU_LOOP:
    LEA DX, main_menu_msg
    CALL print_string
    
    CALL read_char        ; Read user choice
    
    CMP AL, '1'
    JE CALL_FILE_MANAGER
    ;CMP AL, '2'
;    JE CALL_CALCULATOR
;    CMP AL, '3'
;    JE CALL_NOTEPAD
;    CMP AL, '7'
;    JE CALL_CLOCK
    CMP AL, '8'
    JE EXIT_OS
    
    JMP MAIN_MENU_LOOP    ; Loop if invalid key



;================ Calling the features===============
CALL_FILE_MANAGER:
    CALL FILE_MANAGER_PROC
    JMP MAIN_MENU_LOOP
;CALL_CALCULATOR:
;    CALL CALCULATOR_PROC
;    JMP MAIN_MENU_LOOP
;CALL_NOTEPAD:
;    CALL NOTEPAD_PROC
;    JMP MAIN_MENU_LOOP
;CALL_CLOCK:
;    CALL CLOCK_PROC
;    JMP MAIN_MENU_LOOP
;
EXIT_OS:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP
    

; ============================== Mini OS utility calls ==============================
clear_screen PROC
; Clear Screen
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        
        MOV AX, 0600H ; Scroll Up function
        MOV BH, 02H   ; Attribute for blank lines
        ; 0 --> Black  1 --> Blue  2 --> Green 3 --> Aqua 4 --> Red 5 --> Purple 6 --> Yellow 7 --> Light Gray
        XOR CX, CX   ; Upper left corner (row=0, col=0)
        MOV DX, 184FH ; Lower right corner (row=24, col=79)
        INT 10H       ; BIOS video interrupt
        
        MOV AH, 02H  ; Set cursor position function
        MOV BH, 0    ; Page number
        XOR DX, DX   ; Row=0, Col=0
        int 10H       ; BIOS video interrupt
        
        POP DX
        POP CX
        POP BX
        POP DX
        RET
clear_screen ENDP

; Read Character from Keyboard
;Usage: CALL read_char
;Return: AL = ASCII code of the key pressed
read_char PROC
        MOV AH, 01H 
        INT 21H
        RET
read_char ENDP

; Print Character Procedure
print_char PROC
; Print Character in AL
        MOV AH, 02H
        INT 21H
        RET
print_char ENDP

; Read String Procedure
;Usage:
read_string PROC
        ;Read String to (DI == Buffer, CX == Max Length)
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        
        ;Clear BX
        XOR BX, BX
read_char_loop:
        CALL read_char

        CMP AL, 0DH ; Enter key
        JE input_done
        
        CMP Al, 08H ; Backspace key
        JE backspace_key
        
        CMP BX, CX
        JGE read_char_loop ; If max length reached, ignore further input
        
        ;Store character in buffer
        MOV [DI + BX], AL
        INC BX
        JMP read_char_loop
backspace_key:
        CMP BX, 0 ; If at beginning of buffer, ignore backspace
        JE read_char_loop
        
        DEC BX
        MOV BYTE PTR [DI + BX], 0 ; Optional: Clear the character visually

        ;Remove the character from Screen
        MOV AH, 02H
        MOV DL, ' ' ; Space character
        INT 21H
        MOV DL, 8 ; Move cursor back
        INT 21H
        
        JMP read_char_loop
input_done:
        MOV BYTE PTR [DI + BX], '$' ; End of string marker
       
        POP DX
        POP CX
        POP BX
        POP AX
        RET
read_string ENDP


;Pint String Procedure
;Usage:
;   LEA DX, string_to_print     
;   CALL print_string
print_string PROC
; Print String at DS:DX
        PUSH AX
        MOV AH, 09H
        INT 21H
        POP AX
        RET
print_string ENDP


comp_strings PROC 
        PUSH BX
        PUSH CX
        PUSH SI
        PUSH DI

compare_loop:
        MOV AL,[SI]
        MOV BL,[DI]
        
        CMP AL, BL
        JNE strings_not_equal
        
        CMP AL, '$' ; End of string
        JE strings_equal
        
        INC SI
        INC DI
        JMP compare_loop
strings_not_equal:
        MOV AL, 1 ; Not equal
        JMP compare_done
strings_equal:
        XOR AL, AL ; Equal
compare_done:    
        POP DI
        POP SI
        POP CX
        POP BX
        RET
comp_strings ENDP


;========================FEATURE 1: Password Masking =======================
read_password PROC   
    PUSH AX
    PUSH BX
    PUSH DX
    XOR BX, BX ; Index
PASS_LOOP:
    MOV AH, 07H    ; Input WITHOUT Echo
    INT 21H
    
    CMP AL, 0DH    ; Check Enter
    JE PASS_DONE
    
    MOV [DI + BX], AL ; Store char
    INC BX
    
    ; Print Asterisk
    MOV AH, 02H
    MOV DL, '*'
    INT 21H
    JMP PASS_LOOP
PASS_DONE:
    MOV BYTE PTR [DI + BX], '$' ; Terminate
    POP DX
    POP BX
    POP AX
    RET
read_password ENDP



; ======================== FEATURE 2: FILE MANAGER ========================
FILE_MANAGER_PROC PROC
FM_MAIN_LOOP:
    CALL clear_screen
    LEA DX, FM_MENU_MSG     ; Show Menu
    CALL print_string
    
    CALL read_char          ; Get user choice
    
    CMP AL, '1'
    JE FM_LIST_FILES
    CMP AL, '2'
    JE FM_CREATE_FILE
    CMP AL, '3'
    JE FM_DELETE_FILE
    CMP AL, '4'
    JE FM_EXIT
    JMP FM_MAIN_LOOP        ; Invalid input, retry

; ---------------- OPTION 1: LIST FILES ----------------
FM_LIST_FILES:
    CALL clear_screen
    LEA DX, FILE_MSG_3      ; "File List:"
    CALL print_string
    
    MOV CX, 5               ; Loop 5 times
    LEA SI, FILE_NAMES      ; Start of array
LIST_LOOP:
    PUSH CX                 ; Save counter
    
    ; Print the current filename at SI
    MOV DX, SI
    CALL print_string
    
    ; Print Newline
    MOV AH, 02H
    MOV DL, 0DH
    INT 21H
    MOV DL, 0AH
    INT 21H
    
    ADD SI, 9               ; Move to next slot (8 chars + '$')
    POP CX                  ; Restore counter
    LOOP LIST_LOOP
    
    CALL read_char          ; Pause so user can see list
    JMP FM_MAIN_LOOP

; ---------------- OPTION 2: CREATE FILE ----------------
FM_CREATE_FILE:
    LEA DX, FILE_MSG_CREATE
    CALL print_string
    
    ; Search for 'EMPTY' slot
    LEA DI, FILE_NAMES
    MOV CX, 5
FIND_FREE_LOOP:
    ; Check if first char is 'E' (ASCII 69 or 45h)
    CMP BYTE PTR [DI], 'E' 
    JE FOUND_FREE
    ADD DI, 9               ; Next slot
    LOOP FIND_FREE_LOOP
    
    ; If loop finishes, no space left
    LEA DX, FILE_FULL_MSG
    CALL print_string
    CALL read_char
    JMP FM_MAIN_LOOP

FOUND_FREE:
    PUSH DI                 ; Save the empty slot address
    
    ; Read input into temporary buffer
    LEA DI, INPUT_USER 
    MOV CX, 8               ; Max 8 chars
    CALL read_string
    
    ; Copy INPUT_USER into the File Slot
    LEA SI, INPUT_USER
    POP DI                  ; Restore the File Slot address
    MOV CX, 8
COPY_NAME:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP COPY_NAME
    
    LEA DX, FILE_CREATED
    CALL print_string
    CALL read_char
    JMP FM_MAIN_LOOP

; ---------------- OPTION 3: DELETE FILE ----------------
FM_DELETE_FILE:
    LEA DX, FILE_MSG_DEL
    CALL print_string
    
    ; Read filename to delete
    LEA DI, INPUT_USER
    MOV CX, 8
    CALL read_string
    
    ; Search for match
    LEA SI, FILE_NAMES
    MOV CX, 5
SEARCH_DEL_LOOP:
    PUSH CX
    PUSH SI
    
    LEA DI, INPUT_USER
    CALL comp_strings       ; Compare [SI] with Input
    
    CMP AL, 0
    JE FOUND_DELETE         ; Match found
    
    POP SI
    ADD SI, 9               ; Next slot
    POP CX
    LOOP SEARCH_DEL_LOOP
    
    ; Not found
    LEA DX, FILE_NOT_FOUND
    CALL print_string
    CALL read_char
    JMP FM_MAIN_LOOP

FOUND_DELETE:
    POP SI                  ; Restore slot address
    POP CX                  ; Clean stack
    
    ; Reset to "EMPTY   $" manually
    MOV BYTE PTR [SI],   'E'
    MOV BYTE PTR [SI+1], 'M'
    MOV BYTE PTR [SI+2], 'P'
    MOV BYTE PTR [SI+3], 'T'
    MOV BYTE PTR [SI+4], 'Y'
    MOV BYTE PTR [SI+5], ' '
    MOV BYTE PTR [SI+6], ' '
    MOV BYTE PTR [SI+7], ' '
    MOV BYTE PTR [SI+8], '$'
    
    LEA DX, FILE_DELETED
    CALL print_string
    CALL read_char
    JMP FM_MAIN_LOOP

FM_EXIT:
    RET
FILE_MANAGER_PROC ENDP
                           
                           
                           
                           


; ============================== End of Mini OS utility calls =======================

END MAIN
