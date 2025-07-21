
.global _start

.text

# =========================
# Entry Point
# =========================
_start:

    pushq %rbp
    movq %rsp, %rbp

    call counter
    call counter

    popq %rbp
    movq $60, %rax      # syscall: exit
    xorq %rdi, %rdi     # status 0
    syscall

# =========================
# Counter fucntion
# =========================

counter:
    pushq %rbp          # Save the old base pointer
    mov %rsp, %rbp      # Set the new base pointer
    subq $8, %rsp       # Allocate space for a local variable (loop counter)

    movq $0, -8(%rbp)   # Initialize counter variable to 0 (at offset -8 from rbp)

.loop_start:
    movq -8(%rbp), %rdi # Move the current counter value into %rdi for print_number
    call print_number   # Call print_number to display the current number

    addq $1, -8(%rbp)   # Increment the counter
    cmpq $10, -8(%rbp)  # Compare the counter with 10
    jle .loop_start     # If counter <= 10, jump back to loop_start

    addq $8, %rsp       # Deallocate local variable space
    movq %rbp,%rsp      # Restore stack pointer
    popq %rbp           # Restore old base pointer
    ret                 # Return from the function

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

