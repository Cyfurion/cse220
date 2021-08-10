.data
pair: .word 6 10
terms: .word 2 12 4 -14 5 11 0 -1
p: .word 0
N: .word 2

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial

    la $a0, p
    la $a1, terms
    lw $a2, N
    jal add_N_terms_to_polynomial

    #write test code
    li $v0, 1
    la $s0, p
    lw $s0, 0($s0)
    lw $a0, 0($s0)
    syscall
    lw $a0, 4($s0)
    syscall
    lw $s0, 8($s0)
    lw $a0, 0($s0)
    syscall
    lw $a0, 4($s0)
    syscall

    li $v0, 10
    syscall

.include "hw5.asm"
