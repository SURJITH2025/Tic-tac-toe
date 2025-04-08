org 100h

section .data
board db '1','2','3','4','5','6','7','8','9'
player db 'X'
win_msg db 0x0D,0x0A,"Player ",0,' wins!",0x0D,0x0A,"$"
msg_menu db 0x0D,0x0A,"Press R to restart, E to exit (auto exit in 10 sec)...$"

section .text
start:
    call clear_screen
game_loop:
    call draw_board
    call player_move
    call check_win
    call switch_player
    jmp game_loop

; === Draw board ===
draw_board:
    mov si, board
    mov cx, 9
    mov bx, 0
draw_loop:
    mov ah, 0x0E
    lodsb
    int 0x10
    inc bx
    cmp bx, 3
    jne skip_newline
    mov ah, 0x0E
    mov al, 0x0A
    int 0x10
    xor bx, bx
skip_newline:
    loop draw_loop
    ret

; === Clear screen ===
clear_screen:
    mov cx, 25
print_newline:
    mov ah, 0x0E
    mov al, 0x0A
    int 0x10
    loop print_newline
    ret

; === Get player's move ===
player_move:
    mov ah, 0x01
    int 0x21
    sub al, '1'
    cmp al, 8
    ja player_move
    mov si, ax
    mov bl, board[si]
    cmp bl, 'X'
    je player_move
    cmp bl, 'O'
    je player_move
    mov bl, [player]
    mov board[si], bl
    ret

; === Switch player ===
switch_player:
    cmp byte [player], 'X'
    je set_o
    mov byte [player], 'X'
    ret
set_o:
    mov byte [player], 'O'
    ret

; === Check Win Conditions ===
check_win:
    mov al, [player]

    ; Rows
    cmp board[0], al
    jne next1
    cmp board[1], al
    jne next1
    cmp board[2], al
    je win

next1:
    cmp board[3], al
    jne next2
    cmp board[4], al
    jne next2
    cmp board[5], al
    je win

next2:
    cmp board[6], al
    jne next3
    cmp board[7], al
    jne next3
    cmp board[8], al
    je win

next3:
    ; Columns
    cmp board[0], al
    jne next4
    cmp board[3], al
    jne next4
    cmp board[6], al
    je win

next4:
    cmp board[1], al
    jne next5
    cmp board[4], al
    jne next5
    cmp board[7], al
    je win

next5:
    cmp board[2], al
    jne next6
    cmp board[5], al
    jne next6
    cmp board[8], al
    je win

next6:
    ; Diagonals
    cmp board[0], al
    jne next7
    cmp board[4], al
    jne next7
    cmp board[8], al
    je win

next7:
    cmp board[2], al
    jne no_win
    cmp board[4], al
    jne no_win
    cmp board[6], al
    je win

no_win:
    ret

; === Win Detected ===
win:
    call draw_board
    mov ah, 09h
    mov win_msg+7, al
    mov dx, win_msg
    int 21h

    ; Show Play Again Menu
    mov dx, msg_menu
    int 21h

    call get_time      ; Get current time
    add dl, 10         ; 10 seconds from now
    cmp dl, 60
    jb skip_wrap
    sub dl, 60         ; wrap around if > 60
skip_wrap:
    mov dh, dl         ; store target time in dh

wait_input:
    mov ah, 1
    int 16h
    jz check_timeout   ; if no key pressed, check time
    mov ah, 0
    int 16h
    cmp al, 'r'
    je reset_game
    cmp al, 'R'
    je reset_game
    cmp al, 'e'
    je exit_game
    cmp al, 'E'
    je exit_game
    jmp wait_input

check_timeout:
    call get_time
    cmp dl, dh
    jne wait_input

; === Exit Game ===
exit_game:
    mov ax, 4C00h
    int 21h

; === Reset the game ===
reset_game:
    mov si, board
    mov cx, 9
    mov al, '1'
reset_loop:
    mov [si], al
    inc si
    inc al
    loop reset_loop
    mov byte [player], 'X'
    call clear_screen
    jmp game_loop

; === Get current seconds (DL) ===
get_time:
    mov ah, 2Ch
    int 21h
    ret
