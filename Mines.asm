.data

title:          .asciiz "\nMINES\n"
instructions:   .asciiz "Choose squares without finding a mine.\nEach safe square gives you 10 points.\nEnter 0 at any time to cash out.\n"

difficultyMsg:  .asciiz "\nChoose a difficulty from 1 to 10: "
difficultyErr:  .asciiz "Please enter a number from 1 to 10.\n"

choiceMsg:      .asciiz "\nChoose a square from 1 to 25, or 0 to cash out: "
choiceErr:      .asciiz "Please enter a number from 1 to 25.\n"
usedMessage:    .asciiz "You already chose that square.\n"

scoreMessage:   .asciiz "\nCurrent score: "
safeMessage:    .asciiz "\nSafe square! You earned 10 points.\n"
mineMessage:    .asciiz "\nYou found a mine!\nYou lost your points.\n"
cashoutMessage: .asciiz "\nYou cashed out with this many points: "
winMessage:     .asciiz "\nYou opened every safe square!\nYour final score is: "

space:          .asciiz "\t"
newline:        .asciiz "\n"
moneySymbol:    .asciiz "$"

.align 2

# 0 means no mine
# 1 means mine
mines:          .space 100

# 0 means hidden
# 1 means opened
opened:         .space 100

difficulty:     .word 0
score:          .word 0
openedCount:    .word 0
revealMines:    .word 0


.text
.globl main

main:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, instructions
    syscall

    jal get_difficulty
    jal place_mines
    jal draw_mines_display


game_loop:
    jal show_grid

    # Print current score
    li $v0, 4
    la $a0, scoreMessage
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    # Ask for a position
    li $v0, 4
    la $a0, choiceMsg
    syscall

    li $v0, 5
    syscall

    move $t0, $v0

    # Entering 0 cashes out
    beq $t0, $zero, cash_out

    # Check the range
    li $t1, 1
    blt $t0, $t1, invalid_choice

    li $t1, 25
    bgt $t0, $t1, invalid_choice

    # Change 1-25 into index 0-24
    addi $t0, $t0, -1

    # Find the position in the opened array
    sll $t1, $t0, 2
    la $t2, opened
    add $t2, $t2, $t1

    # Check if it was already opened
    lw $t3, 0($t2)
    bne $t3, $zero, already_opened

    # Mark the position as opened
    li $t3, 1
    sw $t3, 0($t2)

    # Check the mine array
    la $t4, mines
    add $t4, $t4, $t1
    lw $t5, 0($t4)

    # A value of 1 means mine
    li $t6, 1
    beq $t5, $t6, found_mine

    # Add 10 points for a safe square
    lw $t7, score
    addi $t7, $t7, 10
    sw $t7, score

    # Count the safe square
    lw $t7, openedCount
    addi $t7, $t7, 1
    sw $t7, openedCount

    # Update Bitmap Display
    jal draw_mines_display

    li $v0, 4
    la $a0, safeMessage
    syscall

    # Safe square count = 25 - difficulty
    li $t8, 25
    lw $t9, difficulty
    sub $t8, $t8, $t9

    # Check if all safe squares were opened
    lw $t7, openedCount
    beq $t7, $t8, player_wins

    j game_loop


invalid_choice:
    li $v0, 4
    la $a0, choiceErr
    syscall

    j game_loop


already_opened:
    li $v0, 4
    la $a0, usedMessage
    syscall

    j game_loop


found_mine:
    # Lose all points
    sw $zero, score

    # Reveal every mine
    li $t0, 1
    sw $t0, revealMines

    jal draw_mines_display

    li $v0, 4
    la $a0, mineMessage
    syscall

    j end_program


cash_out:
    # Reveal mines when the game ends
    li $t0, 1
    sw $t0, revealMines

    jal draw_mines_display

    li $v0, 4
    la $a0, cashoutMessage
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    j end_program


player_wins:
    # Reveal mine locations
    li $t0, 1
    sw $t0, revealMines

    jal draw_mines_display
    jal show_grid

    li $v0, 4
    la $a0, winMessage
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall


end_program:
    li $v0, 10
    syscall


# =========================================================
# GAME PROCEDURES
# =========================================================


# ---------------------------------------------------------
# Ask for difficulty from 1 to 10
# ---------------------------------------------------------

get_difficulty:
ask_difficulty:
    li $v0, 4
    la $a0, difficultyMsg
    syscall

    li $v0, 5
    syscall

    move $t0, $v0

    li $t1, 1
    blt $t0, $t1, bad_difficulty

    li $t1, 10
    bgt $t0, $t1, bad_difficulty

    sw $t0, difficulty
    jr $ra


bad_difficulty:
    li $v0, 4
    la $a0, difficultyErr
    syscall

    j ask_difficulty


# ---------------------------------------------------------
# Place random mines
# ---------------------------------------------------------

place_mines:
    lw $t0, difficulty
    li $t1, 0


place_mine_loop:
    beq $t1, $t0, mines_finished

    # Generate position from 0 to 24
    li $v0, 42
    li $a0, 0
    li $a1, 25
    syscall

    move $t2, $a0

    # Find position in mine array
    sll $t3, $t2, 2
    la $t4, mines
    add $t4, $t4, $t3

    # Do not use duplicate mine positions
    lw $t5, 0($t4)
    bne $t5, $zero, place_mine_loop

    li $t5, 1
    sw $t5, 0($t4)

    addi $t1, $t1, 1
    j place_mine_loop


mines_finished:
    jr $ra


# ---------------------------------------------------------
# Print the console grid
# ---------------------------------------------------------

show_grid:
    li $t0, 0
    la $t1, opened


show_grid_loop:
    li $t2, 25
    beq $t0, $t2, grid_finished

    lw $t3, 0($t1)

    # Print $ if the square was opened
    li $t4, 1
    beq $t3, $t4, print_money

    # Print the square number
    addi $a0, $t0, 1
    li $v0, 1
    syscall

    j after_grid_value


print_money:
    li $v0, 4
    la $a0, moneySymbol
    syscall


after_grid_value:
    addi $t5, $t0, 1

    # Start a new line after every five positions
    li $t6, 5
    div $t5, $t6
    mfhi $t7

    beq $t7, $zero, print_grid_newline

    li $v0, 4
    la $a0, space
    syscall

    j continue_grid


print_grid_newline:
    li $v0, 4
    la $a0, newline
    syscall


continue_grid:
    addi $t0, $t0, 1
    addi $t1, $t1, 4

    j show_grid_loop


grid_finished:
    jr $ra


# =========================================================
# BITMAP DISPLAY
#
# Unit Width: 8
# Unit Height: 8
# Display Width: 256
# Display Height: 256
# Base address: 0x10008000 ($gp)
# =========================================================


# ---------------------------------------------------------
# Draw the entire 5-by-5 grid
# ---------------------------------------------------------

draw_mines_display:
    addi $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    jal clear_mines_display

    li $s0, 0
    la $s1, opened
    la $s2, mines


draw_grid_square_loop:
    li $t0, 25
    beq $s0, $t0, mines_display_done

    # Default square color is gray
    li $s3, 0x00777777

    # Check if this position contains a mine
    lw $t1, 0($s2)

    # Check whether all mines should be revealed
    lw $t2, revealMines

    beq $t2, $zero, check_opened_square
    bne $t1, $zero, square_is_mine


check_opened_square:
    # Check if square was opened
    lw $t3, 0($s1)
    beq $t3, $zero, square_color_ready

    # Opened mine is red
    bne $t1, $zero, square_is_mine

    # Opened safe square is green
    li $s3, 0x0000cc44
    j square_color_ready


square_is_mine:
    li $s3, 0x00ff0000


square_color_ready:
    # Find row and column
    li $t0, 5
    div $s0, $t0

    mflo $t1                    # Row
    mfhi $t2                    # Column

    # x = 1 + column * 6
    li $t3, 6
    mul $a0, $t2, $t3
    addi $a0, $a0, 1

    # y = 1 + row * 6
    mul $a1, $t1, $t3
    addi $a1, $a1, 1

    move $a2, $s3
    jal draw_mine_square

    addi $s0, $s0, 1
    addi $s1, $s1, 4
    addi $s2, $s2, 4

    j draw_grid_square_loop


mines_display_done:
    lw $s3, 4($sp)
    lw $s2, 8($sp)
    lw $s1, 12($sp)
    lw $s0, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra


# ---------------------------------------------------------
# Clear the Bitmap Display
# ---------------------------------------------------------

clear_mines_display:
    move $t0, $gp
    li $t1, 1024
    li $t2, 0x00000000


clear_mines_loop:
    beq $t1, $zero, clear_mines_done

    sw $t2, 0($t0)

    addi $t0, $t0, 4
    addi $t1, $t1, -1

    j clear_mines_loop


clear_mines_done:
    jr $ra


# ---------------------------------------------------------
# Draw one 5-by-5 colored square
#
# $a0 = x position
# $a1 = y position
# $a2 = square color
# ---------------------------------------------------------

draw_mine_square:
    move $t0, $a0
    move $t1, $a1
    move $t2, $a2

    li $t3, 0


mine_square_row:
    li $t4, 5
    beq $t3, $t4, mine_square_done

    li $t5, 0


mine_square_column:
    li $t4, 5
    beq $t5, $t4, next_mine_square_row

    # Current x
    add $t6, $t0, $t5

    # Current y
    add $t7, $t1, $t3

    # Address = $gp + ((y * 32 + x) * 4)
    sll $t8, $t7, 5
    add $t8, $t8, $t6
    sll $t8, $t8, 2
    add $t8, $gp, $t8

    sw $t2, 0($t8)

    addi $t5, $t5, 1
    j mine_square_column


next_mine_square_row:
    addi $t3, $t3, 1
    j mine_square_row


mine_square_done:
    jr $ra