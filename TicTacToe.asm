.data

welcome:        .asciiz "\nTIC-TAC-TOE\n"

inputModeMsg:   .asciiz "Choose input method (1 = Console, 2 = MMIO Keyboard): "
inputModeError: .asciiz "Please enter only 1 or 2.\n"
consoleMsg:     .asciiz "Console input selected.\n"
mmioMsg:        .asciiz "MMIO keyboard selected. Type one number without pressing Enter.\n"

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

.align 2

inputMode:      .word 1
board:          .word 0, 0, 0, 0, 0, 0, 0, 0, 0
gameMode:       .word 0
currentPlayer:  .word 1
moveCount:      .word 0

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


# Start the game
main:
    li $v0, 4
    la $a0, welcome
    syscall

    jal choose_input_mode
    jal get_game_mode
    jal draw_graphics


# Run one turn
game_loop:
    jal show_board

    lw $t0, gameMode
    lw $t1, currentPlayer

    li $t2, 1
    bne $t0, $t2, human_turn

    li $t2, 2
    beq $t1, $t2, bot_turn


# Run a human player's turn
human_turn:
    jal get_player_move
    j turn_finished


# Run the computer's turn
bot_turn:
    jal get_bot_move


# Finish the current turn
turn_finished:
    jal draw_graphics

    lw $t0, moveCount
    addi $t0, $t0, 1
    sw $t0, moveCount

    jal check_winner

    li $t0, 1
    beq $v0, $t0, player_x_won

    li $t0, 2
    beq $v0, $t0, player_o_won

    lw $t0, moveCount
    li $t1, 9
    beq $t0, $t1, game_tie

    jal change_player
    j game_loop


# Display the X winner message
player_x_won:
    jal show_board

    li $v0, 4
    la $a0, xWins
    syscall

    j end_program


# Display the O winner message
player_o_won:
    jal show_board

    lw $t0, gameMode
    li $t1, 1
    beq $t0, $t1, computer_won

    li $v0, 4
    la $a0, oWins
    syscall

    j end_program


# Display the computer winner message
computer_won:
    li $v0, 4
    la $a0, botWins
    syscall

    j end_program


# Display the tie message
game_tie:
    jal show_board

    li $v0, 4
    la $a0, tieMessage
    syscall


# Finish the program
end_program:
    li $v0, 10
    syscall


# Let the user choose console or MMIO input
choose_input_mode:

ask_input_mode:
    li $v0, 4
    la $a0, inputModeMsg
    syscall

    li $v0, 5
    syscall

    move $t0, $v0

    li $t1, 1
    beq $t0, $t1, console_selected

    li $t1, 2
    beq $t0, $t1, mmio_selected

    li $v0, 4
    la $a0, inputModeError
    syscall

    j ask_input_mode


# Save normal console input
console_selected:
    li $t0, 1
    sw $t0, inputMode

    li $v0, 4
    la $a0, consoleMsg
    syscall

    jr $ra


# Save MMIO keyboard input
mmio_selected:
    li $t0, 2
    sw $t0, inputMode

    li $v0, 4
    la $a0, mmioMsg
    syscall

    jr $ra


# Read one number from the selected input
read_number:
    lw $t0, inputMode

    li $t1, 1
    beq $t0, $t1, read_console_number


# Wait for a number from the MMIO keyboard
mmio_wait:
    li $t0, 0xffff0000
    lw $t1, 0($t0)

    andi $t1, $t1, 1
    beq $t1, $zero, mmio_wait

    li $t0, 0xffff0004
    lw $t2, 0($t0)
    andi $t2, $t2, 0x00ff

    li $t3, 48
    blt $t2, $t3, mmio_wait

    li $t3, 57
    bgt $t2, $t3, mmio_wait

    addi $t3, $t2, -48

    move $a0, $t2
    li $v0, 11
    syscall

    li $a0, 10
    li $v0, 11
    syscall

    move $v0, $t3
    jr $ra


# Read a number from the normal console
read_console_number:
    li $v0, 5
    syscall

    jr $ra


# Let the user choose one or two players
get_game_mode:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


ask_mode:
    li $v0, 4
    la $a0, modeMessage
    syscall

    jal read_number

    li $t0, 1
    beq $v0, $t0, save_mode

    li $t0, 2
    beq $v0, $t0, save_mode

    li $v0, 4
    la $a0, modeError
    syscall

    j ask_mode


# Save the selected game mode
save_mode:
    sw $v0, gameMode

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Read and check a player's move
get_player_move:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


ask_for_position:
    lw $t0, currentPlayer

    li $t1, 1
    beq $t0, $t1, print_x_message

    li $v0, 4
    la $a0, player2Message
    syscall

    j read_position


# Display the Player X prompt
print_x_message:
    li $v0, 4
    la $a0, player1Message
    syscall


# Read the selected position
read_position:
    jal read_number

    move $t0, $v0

    li $t1, 1
    blt $t0, $t1, invalid_position

    li $t1, 9
    bgt $t0, $t1, invalid_position

    addi $t0, $t0, -1

    sll $t1, $t0, 2
    la $t2, board
    add $t2, $t2, $t1

    lw $t3, 0($t2)
    bne $t3, $zero, position_used

    lw $t4, currentPlayer
    sw $t4, 0($t2)

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Handle a position outside 1 through 9
invalid_position:
    li $v0, 4
    la $a0, rangeError
    syscall

    j ask_for_position


# Handle a position that is already used
position_used:
    li $v0, 4
    la $a0, usedError
    syscall

    j ask_for_position


# Let the computer choose an empty position
get_bot_move:
    li $v0, 4
    la $a0, botMessage
    syscall


choose_bot_position:
    li $v0, 42
    li $a0, 0
    li $a1, 9
    syscall

    move $t0, $a0

    sll $t1, $t0, 2
    la $t2, board
    add $t2, $t2, $t1

    lw $t3, 0($t2)
    bne $t3, $zero, choose_bot_position

    li $t4, 2
    sw $t4, 0($t2)

    jr $ra


# Change between player X and player O
change_player:
    lw $t0, currentPlayer

    li $t1, 1
    beq $t0, $t1, change_to_o

    li $t0, 1
    sw $t0, currentPlayer
    jr $ra


# Change the current player to O
change_to_o:
    li $t0, 2
    sw $t0, currentPlayer
    jr $ra


# Check all possible winning lines
check_winner:
    la $t0, winningLines
    li $t1, 0


check_line_loop:
    li $t2, 8
    beq $t1, $t2, no_winner

    lw $t3, 0($t0)
    lw $t4, 4($t0)
    lw $t5, 8($t0)

    sll $t6, $t3, 2
    la $t7, board
    add $t6, $t7, $t6
    lw $t3, 0($t6)

    beq $t3, $zero, next_line

    sll $t6, $t4, 2
    add $t6, $t7, $t6
    lw $t4, 0($t6)

    bne $t3, $t4, next_line

    sll $t6, $t5, 2
    add $t6, $t7, $t6
    lw $t5, 0($t6)

    bne $t3, $t5, next_line

    move $v0, $t3
    jr $ra


# Move to the next possible winning line
next_line:
    addi $t0, $t0, 12
    addi $t1, $t1, 1
    j check_line_loop


# Return zero when there is no winner
no_winner:
    li $v0, 0
    jr $ra


# Print the board in the console
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

    addi $a0, $t0, 1
    li $v0, 1
    syscall

    j after_board_value


# Print an X
print_x:
    li $v0, 11
    li $a0, 88
    syscall

    j after_board_value


# Print an O
print_o:
    li $v0, 11
    li $a0, 79
    syscall


# Add the correct board spacing
after_board_value:
    addi $t5, $t0, 1

    li $t6, 3
    div $t5, $t6
    mfhi $t7

    beq $t7, $zero, end_board_row

    li $v0, 4
    la $a0, bar
    syscall

    j continue_board_loop


# Finish one row of the console board
end_board_row:
    li $v0, 4
    la $a0, newline
    syscall

    li $t6, 9
    beq $t5, $t6, continue_board_loop

    li $v0, 4
    la $a0, divider
    syscall


continue_board_loop:
    addi $t0, $t0, 1
    addi $t1, $t1, 4
    j show_board_loop


# Finish printing the board
show_board_done:
    jr $ra


# Redraw the complete Bitmap Display
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


# Draw an X for this board position
graphics_x:
    move $a0, $s0
    jal draw_x
    j next_graphic_piece


# Draw an O for this board position
graphics_o:
    move $a0, $s0
    jal draw_o


# Continue through the board array
next_graphic_piece:
    addi $s0, $s0, 1
    addi $s1, $s1, 4
    j draw_piece_loop


# Finish drawing the board
graphics_done:
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra


# Clear the Bitmap Display
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


# Draw the Tic-Tac-Toe grid
draw_grid:
    li $t0, 0
    li $t7, 0x00000000


draw_vertical_lines:
    li $t1, 16
    beq $t0, $t1, start_horizontal_lines

    sll $t2, $t0, 4
    addi $t2, $t2, 5
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    sll $t2, $t0, 4
    addi $t2, $t2, 10
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    addi $t0, $t0, 1
    j draw_vertical_lines


# Start drawing the horizontal lines
start_horizontal_lines:
    li $t0, 0


draw_horizontal_lines:
    li $t1, 16
    beq $t0, $t1, grid_done

    li $t2, 80
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    li $t2, 160
    add $t2, $t2, $t0
    sll $t2, $t2, 2
    add $t2, $gp, $t2
    sw $t7, 0($t2)

    addi $t0, $t0, 1
    j draw_horizontal_lines


# Finish drawing the grid
grid_done:
    jr $ra


# Draw a red X in one position
draw_x:
    li $t0, 3
    div $a0, $t0

    mflo $t1
    mfhi $t2

    li $t0, 5
    mul $t2, $t2, $t0
    addi $t2, $t2, 1

    mul $t1, $t1, $t0
    addi $t1, $t1, 1

    li $t3, 0
    li $t7, 0x00ff0000


draw_x_loop:
    li $t0, 4
    beq $t3, $t0, draw_x_done

    add $t4, $t2, $t3
    add $t5, $t1, $t3

    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

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


# Finish drawing X
draw_x_done:
    jr $ra


# Draw a blue O in one position
draw_o:
    li $t0, 3
    div $a0, $t0

    mflo $t1
    mfhi $t2

    li $t0, 5
    mul $t2, $t2, $t0
    addi $t2, $t2, 1

    mul $t1, $t1, $t0
    addi $t1, $t1, 1

    li $t3, 0
    li $t7, 0x000000ff


# Draw the top and bottom of O
draw_o_top_bottom:
    li $t0, 4
    beq $t3, $t0, draw_o_sides

    add $t4, $t2, $t3

    sll $t6, $t1, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t5, $t1, 3
    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j draw_o_top_bottom


# Start drawing the sides of O
draw_o_sides:
    li $t3, 1


draw_o_side_loop:
    li $t0, 3
    beq $t3, $t0, draw_o_done

    add $t5, $t1, $t3

    sll $t6, $t5, 4
    add $t6, $t6, $t2
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t4, $t2, 3
    sll $t6, $t5, 4
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t6, $gp, $t6
    sw $t7, 0($t6)

    addi $t3, $t3, 1
    j draw_o_side_loop


# Finish drawing O
draw_o_done:
    jr $ra