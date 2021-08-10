.data
pair: .word 4 3
terms: .word 2 2 5 0 0 -1
p: .word 0
N: .word 2
N1: .word 6

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial

    la $a0, p
    la $a1, terms
    lw $a2, N
    jal add_N_terms_to_polynomial

    la $a0, p
    lw $a1, N1
    jal get_Nth_term

    #write test code
    move $a0, $v0
    li $v0, 1
    syscall
    move $a0, $v1
    syscall

    li $v0, 10
    syscall

.include "hw5.asm"
