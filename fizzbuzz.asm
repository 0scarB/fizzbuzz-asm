; (c) 2024 Oscar Butler-Aldridge
;
; For public use, this code can be used for educational purposes. If used in
; full, please provide attribution. Parts can be freely copied and used in
; original works or for other creative use cases. You can use this code in full
; for benchmarks, to test hardware, or other tests. I wavy my copyright for
; these use cases.
;
; For private use, you have my full permission to interact with this code in
; any way: download, run/execute, modify, etc.
;
; Don't plagarise this code for public use or display, such as: your personal
; portfolio, homework/coursework submissions, etc; if you don't write your own
; code, you won't learn anything.

SECTION .text
global  _start

div_by_rsi_and_store_remainder_in_rsi:
    push    rdx
    xor     rdx, rdx
    div     rsi
    mov     rsi, rdx
    pop     rdx
    ret

_start:
    ; Exit with status code "1" if the single "N" argument is not provided
    cmp     byte [rsp], 2
    mov     rdi, 1
    jnz     exit_with_rdi_exit_code

    ; Parse the "N" argument and store the number in rax
    mov     rsi, [rsp+16]
    mov     rax, 0
    loop_store_cli_N_in_rax:
        ; Multiply rax by 10 and add the current digit character's number to rax
        mov     rbx, 10
        mul     rbx
        ; We convert the character to a number by unsetting the 0x30 bit --
        ; see ASCII table
        xor     byte [rsi], 30h
        add     al , byte [rsi]

        ; Break out of the loop when the null-byte string terminator is reached
        add     rsi, 1
        cmp     byte [rsi], 0
        jnz     loop_store_cli_N_in_rax
    ; We push rax on the stack so we can compare against the stack's top value
    ; at the end of each loop iteration and reuse rax for other purposes --
    ; division, etc.
    push    rax

    ; r8 tracks the iteration number: r8=1..N
    mov     r8, 1
    main_loop:
        ; We will store the string 'Fizz', 'Buzz', 'FizzBuzz' or
        ; the iteration number's string representation in the rbx word.
        ; We initialise rbx as an empty line, with a single newline character.
        mov     rbx, 0Ah
        ; rdx stores the length of the string in rbx
        mov     rdx, 1

        ; Prepend 'Buzz' in rbx if the iteration number / r8 is a multiple of 5
        mov     rax, r8
        mov     rsi, 5
        call    div_by_rsi_and_store_remainder_in_rsi
        cmp     rsi, 0
        jnz     skip_buzz
            shl     rbx, 32
            or      rbx, 'Buzz'
            add     rdx, 4
        skip_buzz:

        ; Prepend 'Fizz' to rbx if the iteration number / r8 is a multiple of 3
        mov     rax, r8
        mov     rsi, 3
        call    div_by_rsi_and_store_remainder_in_rsi
        cmp     rsi, 0
        jnz     skip_fizz
            shl     rbx, 32
            or      rbx, 'Fizz'
            add     rdx, 4
        skip_fizz:

        ; Otherwise, if rbx is an empty line, store the iteration number's
        ; numeric representation in rbx
        cmp     rbx, 0Ah
        jnz     skip_num
            mov     rax, r8
            copy_num_to_rbx_loop:
                ; Divide rax by 10, convert the remainder to a digit character
                ; and store the digit in rbx
                mov     rsi, 10
                call    div_by_rsi_and_store_remainder_in_rsi
                shl     rbx, 8
                ; We convert the remainder to a character by setting the 0x30
                ; bit -- see ASCII table
                or      rbx, rsi
                or      rbx, 30h

                inc     rdx

                ; Break out of the loop when rax reaches 0
                cmp     rax, 0
                jnz     copy_num_to_rbx_loop
        skip_num:

        ; Do a write syscall to output the string in rbx.
        ; We push rbx followed by another word containing a newline (0x0A)
        ; on top of the stack and then use the stack as the buffer to write
        ; from. The second word, containing the newline is required when
        ; 'FizzBuzz' (8-bytes long) is stored in the first because the newline
        ; that rbx was initialised with will have been shifted out.
        mov     rax, 1
        mov     rdi, 1
        push    0Ah
        push    rbx
        mov     rsi, rsp
        syscall
        add     rsp, 16

        inc     r8

        ; Loop until r8==N
        cmp     r8, [rsp]
        jle     main_loop

    ; Do an exit syscall
    mov     rdi, 0
    exit_with_rdi_exit_code:
        mov     rax, 60
        syscall

