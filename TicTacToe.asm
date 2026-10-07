.data

welcome:        .asciiz "\nTIC-TAC-TOE\n"
modeMessage:    .asciiz "Enter 1 for one player or 2 for two players: "
modeError:      .asciiz "Please enter only 1 or 2.\n"

player1Message: .asciiz "\nPlayer X, enter a position from 1 to 9: "
player2Message: .asciiz "\nPlayer O, enter a position from 1 to 9: "
botMessage:     .asciiz "\nThe computer is choosing a position...\n"

rangeError:     .asciiz "Please enter a number from 1 to 9.\n"
usedError:      .asciiz "That position is already being used.\n"

xWins:          .asciiz "\nPlayer X wins!\n"
oWins:          .asciiz "\nPlayer O wins!\n"
botWins:        .asciiz "\nThe computer wins!\n"
tieMessage:     .asciiz "\nThe game is a tie!\n"

divider:        .asciiz "\n---+---+---\n"
space:          .asciiz " "
bar:            .asciiz " | "
newline:        .asciiz "\n"

# 0 = empty, 1 = X, 2 = O
board:          .word 0, 0, 0, 0, 0, 0, 0, 0, 0

gameMode:       .word 0
currentPlayer:  .word 1
moveCount:      .word 0

# Every possible winning line
winningLines:
.word 0, 1, 2
.word 3, 4, 5
.word 6, 7, 8
.word 0, 3, 6
.word 1, 4, 7
.word 2, 5, 8
.word 0, 4, 8
.word 2, 4, 6


.text
.globl main

main:
    # Print the game title
    li $v0, 4
    la $a0, welcome
    syscall

    # Ask for one player or two players
    jal get_game_mode

    # Draw the empty board
    jal draw_graphics


game_loop:
    # Show the board in the console
    jal show_board

    # Check if it is a human or computer turn
    lw $t0, gameMode
    lw $t1, currentPlayer

    # In one-player mode, player 2 is the computer
    li $t2, 1
    bne $t0, $t2, human_turn

    li $t2, 2
    beq $t1, $t2, bot_turn


human_turn:
    jal get_player_move
    j turn_finished


bot_turn:
    jal get_bot_move


turn_finished:
    # Update the Bitmap Display
    jal draw_graphics

    # Add one to the move counter
    lw $t0, moveCount
    addi $t0, $t0, 1
    sw $t0, moveCount

    # Check for a winner
    jal check_winner

    li $t0, 1
    beq $v0, $t0, player_x_won

    li $t0, 2
    beq $v0, $t0, player_o_won

    # Nine moves without a winner means a tie
    lw $t0, moveCount
    li $t1, 9
    beq $t0, $t1, game_tie

    # Change players
    jal change_player
    j game_loop


player_x_won:
    jal show_board

    li $v0, 4
    la $a0, xWins
    syscall

    j end_program


player_o_won:
    jal show_board

    # Check whether player O was the computer
    lw $t0, gameMode
    li $t1, 1
    beq $t0, $t1, computer_won

    li $v0, 4
    la $a0, oWins
    syscall

    j end_program


computer_won:
    li $v0, 4
    la $a0, botWins
    syscall

    j end_program


game_tie:
    jal show_board

    li $v0, 4
    la $a0, tieMessage
    syscall


end_program:
    li $v0, 10
    syscall


# ---------------------------------------------------------
# Ask whether the game has one player or two players
# ---------------------------------------------------------

get_game_mode:
ask_mode:
    li $v0, 4
    la $a0, modeMessage
    syscall

    li $v0, 5
    syscall

    li $t0, 1
    beq $v0, $t0, save_mode

    li $t0, 2
    beq $v0, $t0, save_mode

    li $v0, 4
    la $a0, modeError
    syscall

    j ask_mode

save_mode:
    sw $v0, gameMode
    jr $ra


# ---------------------------------------------------------
# Get a position from a human player
# ---------------------------------------------------------

get_player_move:
ask_for_position:
    lw $t0, currentPlayer

    li $t1, 1
    beq $t0, $t1, print_x_message

    li $v0, 4
    la $a0, player2Message
    syscall

    j read_position


print_x_message:
    li $v0, 4
    la $a0, player1Message
    syscall


read_position:
    li $v0, 5
    syscall

    move $t0, $v0

    # The smallest position is 1
    li $t1, 1
    blt $t0, $t1, invalid_position

    # The largest position is 9
    li $t1, 9
    bgt $t0, $t1, invalid_position

    # Change positions 1-9 into array indexes 0-8
    addi $t0, $t0, -1

    # Find the position in the board array
    sll $t1, $t0, 2
    la $t2, board
    add $t2, $t2, $t1

    # Make sure the position is empty
    lw $t3, 0($t2)
    bne $t3, $zero, position_used

    # Put the current player's value on the board
    lw $t4, currentPlayer
    sw $t4, 0($t2)

    jr $ra


invalid_position:
    li $v0, 4
    la $a0, rangeError
    syscall

    j ask_for_position


position_used:
    li $v0, 4
    la $a0, usedError
    syscall

    j ask_for_position


# ---------------------------------------------------------
# Choose a random empty position for the computer
# ---------------------------------------------------------

get_bot_move:
    li $v0, 4
    la $a0, botMessage
    syscall

choose_bot_position:
    # Generate a random number from 0 through 8
    li $v0, 42
    li $a0, 0
    li $a1, 9
    syscall

    move $t0, $a0

    # Find that position in the board
    sll $t1, $t0, 2
    la $t2, board
    add $t2, $t2, $t1

    # Try again if the position is already used
    lw $t3, 0($t2)
    bne $t3, $zero, choose_bot_position

    # Store O in the chosen position
    li $t4, 2
    sw $t4, 0($t2)

    jr $ra


# ---------------------------------------------------------
# Change between player 1 and player 2
# ---------------------------------------------------------

change_player:
    lw $t0, currentPlayer

    li $t1, 1
    beq $t0, $t1, change_to_o

    li $t0, 1
    sw $t0, currentPlayer
    jr $ra


change_to_o:
    li $t0, 2
    sw $t0, currentPlayer
    jr $ra


# ---------------------------------------------------------
# Check all eight possible winning lines
# Returns:
# $v0 = 0 for no winner
# $v0 = 1 if X wins
# $v0 = 2 if O wins
# ---------------------------------------------------------

check_winner:
    la $t0, winningLines
    li $t1, 0

check_line_loop:
    li $t2, 8
    beq $t1, $t2, no_winner

    # Get the three board indexes
    lw $t3, 0($t0)
    lw $t4, 4($t0)
    lw $t5, 8($t0)

    # Get the first board value
    sll $t6, $t3, 2
    la $t7, board
    add $t6, $t7, $t6
    lw $t3, 0($t6)

    # An empty position cannot win
    beq $t3, $zero, next_line

    # Get the second board value
    sll $t6, $t4, 2
    add $t6, $t7, $t6
    lw $t4, 0($t6)

    bne $t3, $t4, next_line

    # Get the third board value
    sll $t6, $t5, 2
    add $t6, $t7, $t6
    lw $t5, 0($t6)

    bne $t3, $t5, next_line

    # All three values match
    move $v0, $t3
    jr $ra


next_line:
    addi $t0, $t0, 12
    addi $t1, $t1, 1
    j check_line_loop


no_winner:
    li $v0, 0
    jr $ra


# ---------------------------------------------------------
# Show the board in the console
# ---------------------------------------------------------

show_board:
    li $t0, 0
    la $t1, board

show_board_loop:
    li $t2, 9
    beq $t0, $t2, show_board_done

    li $v0, 4
    la $a0, space
    syscall

    lw $t3, 0($t1)

    li $t4, 1
    beq $t3, $t4, print_x

    li $t4, 2
    beq $t3, $t4, print_o

    # Print the position number when it is empty
    addi $a0, $t0, 1
    li $v0, 1
    syscall

    j after_board_value


print_x:
    li $v0, 11
    li $a0, 88
    syscall

    j after_board_value


print_o:
    li $v0, 11
    li $a0, 79
    syscall


after_board_value:
    # Check if this is the last column
    addi $t5, $t0, 1
    li $t6, 3
    div $t5, $t6
    mfhi $t7

    beq $t7, $zero, end_board_row

    li $v0, 4
    la $a0, bar
    syscall

    j continue_board_loop


end_board_row:
    li $v0, 4
    la $a0, newline
    syscall

    # Do not print a divider after the last row
    li $t6, 9
    beq $t5, $t6, continue_board_loop

    li $v0, 4
    la $a0, divider
    syscall


continue_board_loop:
    addi $t0, $t0, 1
    addi $t1, $t1, 4
    j show_board_loop


show_board_done:
    jr $ra


# =========================================================
# BITMAP DISPLAY PROCEDURES
# =========================================================

# ---------------------------------------------------------
# Clear the display, draw the grid, and draw all pieces
# ---------------------------------------------------------

draw_graphics:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    jal clear_screen
    jal draw_grid

    li $s0, 0
    la $s1, board

draw_piece_loop:
    li $t0, 9
    beq $s0, $t0, graphics_done

    lw $t1, 0($s1)

    li $t2, 1
    beq $t1, $t2, graphics_x

    li $t2, 2
    beq $t1, $t2, graphics_o

    j next_graphic_piece


graphics_x:
    move $a0, $s0
    jal draw_x
    j next_graphic_piece


graphics_o:
    move $a0, $s0
    jal draw_o


next_graphic_piece:
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    j draw_piece_loop


graphics_done:
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra


# ---------------------------------------------------------
# Make the Bitmap Display background white
# ---------------------------------------------------------

clear_screen:
    move $t0, $gp
    li $t1, 256
    li $t2, 0x00ffffff

clear_loop:
    beq $t1, $zero, clear_done

    sw $t2, 0($t0)

    addi $t0, $t0, 4
    addi $t1, $t1, -1

    j clear_loop


clear_done:
    jr $ra


# ---------------------------------------------------------
# Draw the black Tic-Tac-Toe grid
# ---------------------------------------------------------

draw_grid:
    li $t0, 0
    li $t7, 0x00000000

draw_vertical_lines:
    li $t1, 16
    beq $t0, $t1, start_horizontal_lines

    # Pixel at x = 5
    sll $t2, $t0, 4
    addi $t2, $t2, 5
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    # Pixel at x = 10
    sll $t2, $t0, 4
    addi $t2, $t2, 10
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    addi $t0, $t0, 1
    j draw_vertical_lines


start_horizontal_lines:
    li $t0, 0


draw_horizontal_lines:
    li $t1, 16
    beq $t0, $t1, grid_done

    # Pixel at y = 5
    li $t2, 80
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    # Pixel at y = 10
    li $t2, 160
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    addi $t0, $t0, 1
    j draw_horizontal_lines


grid_done:
    jr $ra


# ---------------------------------------------------------
# Draw a red X
# $a0 contains the board position from 0 to 8
# ---------------------------------------------------------

draw_x:
    li $t0, 3
    div $a0, $t0

    # Row in $t1 and column in $t2
    mflo $t1
    mfhi $t2

    # Starting x position = column * 5 + 1
    li $t0, 5
    mul $t2, $t2, $t0
    addi $t2, $t2, 1

    # Starting y position = row * 5 + 1
    mul $t1, $t1, $t0
    addi $t1, $t1, 1

    li $t3, 0
    li $t7, 0x00ff0000


draw_x_loop:
    li $t0, 4
    beq $t3, $t0, draw_x_done

    # First diagonal
    add $t4, $t2, $t3
    add $t5, $t1, $t3

    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6

    sw $t7, 0($t6)

    # Second diagonal
    li $t0, 3
    sub $t0, $t0, $t3
    add $t4, $t2, $t0

    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6

    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j draw_x_loop


draw_x_done:
    jr $ra


# ---------------------------------------------------------
# Draw a blue O
# $a0 contains the board position from 0 to 8
# ---------------------------------------------------------

draw_o:
    li $t0, 3
    div $a0, $t0

    # Row in $t1 and column in $t2
    mflo $t1
    mfhi $t2

    # Starting x position = column * 5 + 1
    li $t0, 5
    mul $t2, $t2, $t0
    addi $t2, $t2, 1

    # Starting y position = row * 5 + 1
    mul $t1, $t1, $t0
    addi $t1, $t1, 1

    li $t3, 0
    li $t7, 0x000000ff


draw_o_top_bottom:
    li $t0, 4
    beq $t3, $t0, draw_o_sides

    add $t4, $t2, $t3

    # Top of O
    sll $t6, $t1, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    # Bottom of O
    addi $t5, $t1, 3
    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j draw_o_top_bottom


draw_o_sides:
    li $t3, 1


draw_o_side_loop:
    li $t0, 3
    beq $t3, $t0, draw_o_done

    add $t5, $t1, $t3

    # Left side of O
    sll $t6, $t5, 4
    add $t6, $t6, $t2
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    # Right side of O
    addi $t4, $t2, 3
    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j draw_o_side_loop


draw_o_done:
    jr $ra