.data
p_pair: .word 5 2
p_terms: .word 7 2 0 -1
q_pair: .word 1 3
q_terms: .word 1 2 0 -1
p: .word 0
q: .word 0
r: .word 0
N: .word 1

.text:
main:
    la $a0, p
    la $a1, p_pair
    jal init_polynomial

    la $a0, p
    la $a1, p_terms
    lw $a2, N
    jal add_N_terms_to_polynomial

    la $a0, q
    la $a1, q_pair
    jal init_polynomial

    la $a0, q
    la $a1, q_terms
    lw $a2, N
    jal add_N_terms_to_polynomial

    la $a0, p
    li $a1, 0
    la $a2, r
    jal add_poly

    #write test code
    move $a0, $v0
    li $v0, 1
    syscall

    li $v0, 10
    syscall

.include "hw5.asm"
