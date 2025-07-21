# The program support max 10 coroutines
# only two are used however

.section .data
coroutine_finish_msg:
    .asciz "Coroutine finished\n"
coroutine_finish_msg_len = . - coroutine_finish_msg

.section .bss
.align 16
contexts_rsp:       .skip 8 * 10
contexts_rbp:       .skip 8 * 10
contexts_rip:       .skip 8 * 10
stacks:             .skip 4096 * 10
stacks_end:         .quad 0
contexts_count:     .quad 0
contexts_current:   .quad 0

.section .text
.global _start

_start:
    pushq %rbp
    movq %rsp, %rbp

    leaq stacks + 4096*10(%rip), %rax
    movq %rax, stacks_end(%rip)

    call coroutine_init

    movq $counter, %rdi
    call coroutine_go


    movq $counter, %rdi
    call coroutine_go

.forever:
    call coroutine_yield
    jmp .forever

# =========================
# Counter Function
# =========================

counter:
    pushq %rbp
    movq %rsp, %rbp
    subq $8, %rsp

    movq $0, -8(%rbp)

.loop:
    cmpq $10, -8(%rbp)
    jg .done

    movq -8(%rbp), %rdi
    call print_number
    call coroutine_yield

    addq $1, -8(%rbp)
    jmp .loop

.done:
    addq $8, %rsp
    popq %rbp
    ret

# =========================
# Print Number in %rdi
# =========================

print_number:
    movq $-3689348814741910323, %r9
    subq $40, %rsp
    movb $10, 31(%rsp)
    leaq 30(%rsp), %rcx

.L2:
    movq %rdi, %rax
    leaq 32(%rsp), %r8
    mulq %r9
    movq %rdi, %rax
    subq %rcx, %r8
    shrq $3, %rdx
    leaq (%rdx, %rdx, 4), %rsi
    addq %rsi, %rsi
    subq %rsi, %rax
    addl $48, %eax
    movb %al, (%rcx)
    movq %rdi, %rax
    movq %rdx, %rdi
    movq %rcx, %rdx
    subq $1, %rcx
    cmpq $9, %rax
    ja .L2

    leaq 32(%rsp), %rax
    movl $1, %edi
    subq %rax, %rdx
    xorl %eax, %eax
    leaq 32(%rsp, %rdx), %rsi
    movq %r8, %rdx
    movq $1, %rax
    syscall

    addq $40, %rsp
    ret


# =========================
# Coroutine Support
# =========================

coroutine_init:
    # FIX: Read the return address without pop, and do a normal ret
    # to keep the stack aligned and balanced.
    movq contexts_count(%rip), %rbx
    cmpq $10, %rbx
    jge overflow_fail

    incq contexts_count(%rip)
    
    movq (%rsp), %rax                       # Read return address from stack top
    movq %rsp, contexts_rsp(, %rbx, 8)      # Save current stack pointer
    movq %rbp, contexts_rbp(, %rbx, 8)      # Save current base pointer
    movq %rax, contexts_rip(, %rbx, 8)      # Save the return address as the RIP
    ret                                     # Return normally

coroutine_go:
    movq contexts_count(%rip), %rbx
    cmpq $10, %rbx
    jge overflow_fail

    incq contexts_count(%rip)

    movq stacks_end(%rip), %rax
    subq $4096, %rax
    movq %rax, stacks_end(%rip)

    # This setup is correct: when the new coroutine's function
    # eventually returns, it will jump to coroutine_finish.
    subq $8, %rax
    movq $coroutine_finish, (%rax)

    movq %rax, contexts_rsp(, %rbx, 8)
    movq %rax, contexts_rbp(, %rbx, 8) # Using stack top as base pointer is safer than 0
    movq %rdi, contexts_rip(, %rbx, 8)
    ret

coroutine_yield:
    # context switching implementation.
    
    # 1. Save the state of the current coroutine (the caller)
    movq contexts_current(%rip), %rbx
    movq %rbp, contexts_rbp(, %rbx, 8)      # Save base pointer
    movq (%rsp), %rax                       # Get return address from stack
    movq %rax, contexts_rip(, %rbx, 8)      # Save it as the instruction pointer
    leaq 8(%rsp), %rax                      # Get stack pointer below the return addr
    movq %rax, contexts_rsp(, %rbx, 8)      # Save it

    # 2. Select the next coroutine to run (round-robin)
    incq %rbx
    movq contexts_count(%rip), %rcx
    cmpq %rcx, %rbx
    jl .set_next
    xorq %rbx, %rbx                         # Wrap around to 0
.set_next:
    movq %rbx, contexts_current(%rip)

    # 3. Restore the state of the next coroutine
    movq contexts_rsp(, %rbx, 8), %rsp
    movq contexts_rbp(, %rbx, 8), %rbp

    # 4. Jump to the new coroutine's saved instruction pointer
    # We do this by pushing the target address onto the new stack and using 'ret'
    movq contexts_rip(, %rbx, 8), %rax
    pushq %rax
    ret

coroutine_finish:
    movq $1, %rax
    movq $1, %rdi
    leaq coroutine_finish_msg(%rip), %rsi
    movq $coroutine_finish_msg_len, %rdx
    syscall

    movq $60, %rax
    xorq %rdi, %rdi
    syscall


overflow_fail:
    movq $1, %rax
    movq $2, %rdi
    leaq err_msg(%rip), %rsi
    movq $err_len, %rdx
    syscall

    movq $60, %rax
    movq $69, %rdi
    syscall

.section .rodata
err_msg:
    .asciz "Too many coroutines\n"
err_len = . - err_msg
