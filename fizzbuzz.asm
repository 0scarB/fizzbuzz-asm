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
    ; Exit with statux code "1" single "N" argument is not provided
    cmp     byte [rsp], 2
    mov     rdi, 1
    jnz     exit_with_rdi_exit_code

    ; Parse "N" argument and store the number in rax
    mov     rsi, [rsp+16]
    mov     rax, 0
    loop_store_cli_N_in_rax:
        mov     rbx, 10
        mul     rbx
        xor     byte [rsi], 30h
        add     al , byte [rsi]

        add     rsi, 1
        cmp     byte [rsi], 0
        jnz     loop_store_cli_N_in_rax
    push    rax

    ; r8 tracks the iteration number: r8=1..N
    mov     r8, 0
    main_loop:
        inc     r8

        ; We will store the string 'Fizz', 'Buzz', 'FizzBuzz' or
        ; the iteration number's string representation in the rbx word
        mov     rbx, 0
        ; rdx stores the length of the string in rbx
        mov     rdx, 1

        ; Store 'Buzz' in rbx if the iteration number / r8 is a multiple of 5
        mov     rax, r8
        mov     rsi, 5
        call    div_by_rsi_and_store_remainder_in_rsi
        cmp     rsi, 0
        jnz     skip_buzz
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

        ; Otherwise, if rbx is empty, store the iteration number's numeric
        ; representation in rbx
        cmp     rbx, 0
        jnz     skip_num
            mov     rax, r8
            print_num_loop:
                mov     rsi, 10
                call    div_by_rsi_and_store_remainder_in_rsi

                shl     rbx, 8
                or      rbx, rsi
                or      rbx, 30h

                inc     rdx

                cmp     rax, 0
                jnz     print_num_loop
        skip_num:

        ; Do a write syscall to output the string in rbx. To do so,
        ; we create a buffer containing a newline, followed by rbx on the stack
        ; and point the write syscall to the newline starting the buffer.
        ; We put the newline at the start because putting it at the end
        ; requires additional operations because of little-edianness
        mov     rax, 1
        mov     rdi, 1
        push    rbx
        mov     rbx, 0A00000000000000h
        push    rbx
        mov     rsi, rsp
        add     rsi, 7
        syscall
        add     rsp, 16

        ; Loop until r8==N
        cmp     r8, [rsp]
        jl      main_loop

    ; Do an exit syscall
    mov     rdi, 0
    exit_with_rdi_exit_code:
        mov     rax, 60
        syscall

