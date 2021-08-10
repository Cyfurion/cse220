.data
board_filename: .asciiz "gameE3lol.txt"
.align 2
state:        
    .byte 't'         # bot_mancala       	(byte #0)
    .byte 't'         # top_mancala       	(byte #1)
    .byte 't'         # bot_pockets       	(byte #2)
    .byte 't'         # top_pockets        	(byte #3)
    .byte 't'         # moves_executed		(byte #4)
    .byte 'B'    # player_turn        		(byte #5)
    # game_board                     		(bytes #6-end)
    .asciiz
    "x"
.text
.globl main
main:
la $a0, state
la $a1, board_filename
jal load_game
# You must write your own code here to check the correctness of the function implementation.

move $a0, $v0
li $v0, 1
syscall

li $a0, 10
li $v0, 11
syscall

move $a0, $v1
li $v0, 1
syscall

li $v0, 10
syscall

.include "hw3.asm"
