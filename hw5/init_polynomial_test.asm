.data
pair: .word 2 -3
p: .word 0

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial

    #write test code
    move $a0, $v0
    li $v0, 1
    syscall

    li $v0, 10
    syscall

.include "hw5.asm"
