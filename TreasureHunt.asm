# Treasure Hunt: Killer Maze - MIPS game for MARS
#
# Bitmap Display settings:
#   Unit Width in Pixels:   4
#   Unit Height in Pixels:  4
#   Display Width:          256
#   Display Height:         256
#   Base address:           0x10008000 ($gp)
#
# The program randomly selects one of three mazes. Two red killer faces
# chase the blue happy player after each valid move. The exit is not placed
# until all three treasures are collected, then it appears at a random corner.

.data

title:              .asciiz "\nTREASURE HUNT: KILLER MAZE\n"
instructions:       .asciiz "Collect all 3 treasures, then reach the exit.\nTwo killers chase you after every valid move.\nUse W, A, S, and D to move. Press Q to quit.\n"
colorKey:           .asciiz "Map key: P=Player  K=Killer  T=Treasure  E=Exit  #=Wall\n"

inputModeMsg:       .asciiz "\nChoose input method (1 = Console, 2 = MMIO Keyboard): "
inputModeError:     .asciiz "Please enter only 1 or 2.\n"
consoleSelected:    .asciiz "Console input selected.\n"
mmioSelected:       .asciiz "MMIO selected. Type one letter without pressing Enter.\n"

mazeMessage:        .asciiz "\nRandom maze selected: "
movePrompt:         .asciiz "\nMove (W/A/S/D) or Q to quit: "
invalidInputMsg:    .asciiz "Invalid input. Please enter W, A, S, D, or Q.\n"
wallMessage:        .asciiz "A wall blocks that direction. Try another move.\n"
treasureMessage:    .asciiz "You collected a treasure!\n"
exitSpawnMessage:   .asciiz "All treasures collected! An exit appeared in a random corner.\n"
caughtMessage:      .asciiz "A killer caught you! You lost one life.\n"
resetMessage:       .asciiz "You and the killers returned to your starting positions.\n"

livesMessage:       .asciiz "Lives: "
scoreMessage:       .asciiz "   Score: "
movesMessage:       .asciiz "   Moves: "
treasureStatusMsg:  .asciiz "   Treasure: "
slashThree:         .asciiz "/3\n"

winMessage:         .asciiz "\nYou escaped the killer maze!\n"
loseMessage:        .asciiz "\nYou lost all three lives. Game over!\n"
quitMessage:        .asciiz "\nYou ended the game.\n"
bonusMessage:       .asciiz "Exit bonus: "
finalScoreMessage:  .asciiz "Final score: "
playAgainMessage:   .asciiz "\nPlay again? (Y/N): "
yesNoError:         .asciiz "Invalid input. Please enter Y or N.\n"
goodbyeMessage:     .asciiz "Thanks for playing Treasure Hunt!\n"
newline:            .asciiz "\n"

# Tile values: 0=empty, 1=wall, 2=treasure, 4=exit
# Every maze is 8 rows by 8 columns and contains exactly 3 treasures.
mazeTemplates:

# Maze 1
# ########
# #...T..#
# #.##.#.#
# #......#
# #.#.##.#
# #T.....#
# #..T...#
# ########
.byte 1,1,1,1,1,1,1,1
.byte 1,0,0,0,2,0,0,1
.byte 1,0,1,1,0,1,0,1
.byte 1,0,0,0,0,0,0,1
.byte 1,0,1,0,1,1,0,1
.byte 1,2,0,0,0,0,0,1
.byte 1,0,0,2,0,0,0,1
.byte 1,1,1,1,1,1,1,1

# Maze 2
# ########
# #..#...#
# #T.#.#.#
# #..#...#
# #......#
# #.##.#.#
# #T...T.#
# ########
.byte 1,1,1,1,1,1,1,1
.byte 1,0,0,1,0,0,0,1
.byte 1,2,0,1,0,1,0,1
.byte 1,0,0,1,0,0,0,1
.byte 1,0,0,0,0,0,0,1
.byte 1,0,1,1,0,1,0,1
.byte 1,2,0,0,0,2,0,1
.byte 1,1,1,1,1,1,1,1

# Maze 3
# ########
# #......#
# #.####.#
# #T....T#
# ###.##.#
# #......#
# #.T....#
# ########
.byte 1,1,1,1,1,1,1,1
.byte 1,0,0,0,0,0,0,1
.byte 1,0,1,1,1,1,0,1
.byte 1,2,0,0,0,0,2,1
.byte 1,1,1,0,1,1,0,1
.byte 1,0,0,0,0,0,0,1
.byte 1,0,2,0,0,0,0,1
.byte 1,1,1,1,1,1,1,1

# Possible exit positions are the four inner corners.
exitCornerRows:     .byte 1,1,6,6
exitCornerColumns:  .byte 1,6,1,6

.align 2
board:              .space 64
inputMode:          .word 1
selectedMaze:       .word 1
lastMazeIndex:      .word -1
playerRow:          .word 1
playerColumn:       .word 1
enemyRows:          .word 1,6
enemyColumns:       .word 6,6
lives:              .word 3
score:              .word 0
moveCount:          .word 0
treasuresFound:     .word 0
exitActive:         .word 0
exitBonus:          .word 0

# Colors use 0x00RRGGBB.
colorEmpty:         .word 0x00000000
colorWall:          .word 0x00404040
colorTreasure:      .word 0x00FFD700
colorExit:          .word 0x0000CC44
colorPlayer:        .word 0x002E86FF
colorKiller:        .word 0x00DD2020
colorWhite:         .word 0x00FFFFFF
colorBlack:         .word 0x00000000

.text
.globl main


# ------------------------------------------------------------
# Program entry and main game loop
# ------------------------------------------------------------
main:
    li $v0, 4
    la $a0, title
    syscall

    li $v0, 4
    la $a0, instructions
    syscall

    li $v0, 4
    la $a0, colorKey
    syscall

    jal choose_input_mode

game_start:
    jal initialize_game

    li $v0, 4
    la $a0, mazeMessage
    syscall

    lw $a0, selectedMaze
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    jal draw_graphics

game_loop:
    jal show_board
    jal print_statistics
    jal get_move

    li $t0, 113                # q
    beq $v0, $t0, player_quit

    move $a0, $v0
    jal process_move
    move $s0, $v0              # 0=continue, 1=win, 2=game over

    jal draw_graphics

    li $t0, 1
    beq $s0, $t0, player_won

    li $t0, 2
    beq $s0, $t0, player_lost

    j game_loop


# Add a speed bonus after the player reaches the exit.
player_won:
    lw $t0, moveCount
    li $t1, 5
    mul $t0, $t0, $t1

    li $t1, 300
    sub $t2, $t1, $t0          # bonus = 300 - moves * 5
    bgez $t2, win_bonus_ready
    move $t2, $zero

win_bonus_ready:
    sw $t2, exitBonus

    lw $t3, score
    add $t3, $t3, $t2
    sw $t3, score

    jal show_board
    jal print_statistics

    li $v0, 4
    la $a0, winMessage
    syscall

    li $v0, 4
    la $a0, bonusMessage
    syscall

    lw $a0, exitBonus
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $v0, 4
    la $a0, finalScoreMessage
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, newline
    syscall
    j game_finished

player_lost:
    jal show_board
    jal print_statistics

    li $v0, 4
    la $a0, loseMessage
    syscall
    j game_finished

player_quit:
    li $v0, 4
    la $a0, quitMessage
    syscall

game_finished:
    jal ask_play_again
    li $t0, 1
    beq $v0, $t0, game_start

    li $v0, 4
    la $a0, goodbyeMessage
    syscall

    li $v0, 10
    syscall


# ------------------------------------------------------------
# Input procedures
# ------------------------------------------------------------
choose_input_mode:
choose_input_loop:
    li $v0, 4
    la $a0, inputModeMsg
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    li $t1, 1
    beq $t0, $t1, input_console
    li $t1, 2
    beq $t0, $t1, input_mmio

    li $v0, 4
    la $a0, inputModeError
    syscall
    j choose_input_loop

input_console:
    li $t0, 1
    sw $t0, inputMode

    li $v0, 4
    la $a0, consoleSelected
    syscall
    jr $ra

input_mmio:
    li $t0, 2
    sw $t0, inputMode

    li $v0, 4
    la $a0, mmioSelected
    syscall
    jr $ra


# Return one lowercase character in $v0.
read_character:
    lw $t0, inputMode
    li $t1, 1
    beq $t0, $t1, read_console_character

read_mmio_character:
    li $t0, 0xffff0000
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beq $t1, $zero, read_mmio_character

    li $t0, 0xffff0004
    lw $t2, 0($t0)
    andi $t2, $t2, 0x00ff

    li $t3, 10
    beq $t2, $t3, read_mmio_character
    li $t3, 13
    beq $t2, $t3, read_mmio_character
    j normalize_character

read_console_character:
    li $v0, 12
    syscall
    move $t2, $v0

    li $t3, 10
    beq $t2, $t3, read_console_character
    li $t3, 13
    beq $t2, $t3, read_console_character

normalize_character:
    li $t3, 65
    blt $t2, $t3, character_ready
    li $t3, 90
    bgt $t2, $t3, character_ready
    addi $t2, $t2, 32

character_ready:
    move $v0, $t2
    jr $ra


get_move:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

get_move_loop:
    li $v0, 4
    la $a0, movePrompt
    syscall

    jal read_character
    move $t0, $v0

    li $t1, 119                # w
    beq $t0, $t1, valid_move_character
    li $t1, 97                 # a
    beq $t0, $t1, valid_move_character
    li $t1, 115                # s
    beq $t0, $t1, valid_move_character
    li $t1, 100                # d
    beq $t0, $t1, valid_move_character
    li $t1, 113                # q
    beq $t0, $t1, valid_move_character

    li $v0, 4
    la $a0, invalidInputMsg
    syscall
    j get_move_loop

valid_move_character:
    move $v0, $t0

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


ask_play_again:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

play_again_loop:
    li $v0, 4
    la $a0, playAgainMessage
    syscall

    jal read_character

    li $t0, 121                # y
    beq $v0, $t0, play_again_yes
    li $t0, 110                # n
    beq $v0, $t0, play_again_no

    li $v0, 4
    la $a0, yesNoError
    syscall
    j play_again_loop

play_again_yes:
    li $v0, 1
    j play_again_done

play_again_no:
    li $v0, 0

play_again_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# ------------------------------------------------------------
# Game initialization and random maze selection
# ------------------------------------------------------------
initialize_game:
choose_random_maze:
    li $v0, 42                 # random integer from 0 to 2
    li $a0, 0
    li $a1, 3
    syscall

    move $t0, $a0
    lw $t6, lastMazeIndex
    beq $t0, $t6, choose_random_maze
    sw $t0, lastMazeIndex

    addi $t1, $t0, 1
    sw $t1, selectedMaze

    sll $t0, $t0, 6           # selected maze * 64 bytes
    la $t1, mazeTemplates
    add $t1, $t1, $t0
    la $t2, board
    li $t3, 0

copy_maze_loop:
    li $t4, 64
    beq $t3, $t4, maze_copy_done

    lb $t5, 0($t1)
    sb $t5, 0($t2)
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    j copy_maze_loop

maze_copy_done:
    li $t0, 1
    sw $t0, playerRow
    sw $t0, playerColumn

    la $t1, enemyRows
    sw $t0, 0($t1)             # enemy 1 row = 1
    li $t2, 6
    sw $t2, 4($t1)             # enemy 2 row = 6

    la $t1, enemyColumns
    sw $t2, 0($t1)             # both enemy columns = 6
    sw $t2, 4($t1)

    li $t0, 3
    sw $t0, lives
    sw $zero, score
    sw $zero, moveCount
    sw $zero, treasuresFound
    sw $zero, exitActive
    sw $zero, exitBonus
    jr $ra


# ------------------------------------------------------------
# Player turn logic
# ------------------------------------------------------------
# $a0 = lowercase direction. Return 0=continue, 1=win, 2=loss.
process_move:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)

    move $s0, $a0
    lw $s1, playerRow
    lw $s2, playerColumn

    li $t0, 119                # w
    beq $s0, $t0, player_move_up
    li $t0, 97                 # a
    beq $s0, $t0, player_move_left
    li $t0, 115                # s
    beq $s0, $t0, player_move_down

    addi $s2, $s2, 1          # d
    j validate_player_position

player_move_up:
    addi $s1, $s1, -1
    j validate_player_position

player_move_left:
    addi $s2, $s2, -1
    j validate_player_position

player_move_down:
    addi $s1, $s1, 1

validate_player_position:
    move $a0, $s1
    move $a1, $s2
    jal is_open_position
    beq $v0, $zero, player_move_blocked

    sw $s1, playerRow
    sw $s2, playerColumn

    lw $t0, moveCount
    addi $t0, $t0, 1
    sw $t0, moveCount

    jal player_enemy_collision
    beq $v0, $zero, player_safe_before_tile

    jal handle_player_caught
    j process_move_done

player_safe_before_tile:
    jal check_current_tile
    li $t0, 1
    beq $v0, $t0, process_move_done

    jal move_enemies
    j process_move_done

player_move_blocked:
    li $v0, 4
    la $a0, wallMessage
    syscall
    li $v0, 0

process_move_done:
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra


# $a0=row and $a1=column. Return 1 if inside the maze and not a wall.
is_open_position:
    bltz $a0, position_not_open
    bltz $a1, position_not_open

    li $t0, 8
    bge $a0, $t0, position_not_open
    bge $a1, $t0, position_not_open

    sll $t1, $a0, 3
    add $t1, $t1, $a1
    la $t2, board
    add $t2, $t2, $t1
    lb $t3, 0($t2)

    li $t4, 1
    beq $t3, $t4, position_not_open

    li $v0, 1
    jr $ra

position_not_open:
    li $v0, 0
    jr $ra


# Collect treasure or win by stepping onto the active exit.
check_current_tile:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    lw $t0, playerRow
    lw $t1, playerColumn
    sll $t2, $t0, 3
    add $t2, $t2, $t1

    la $t3, board
    add $t3, $t3, $t2
    lb $t4, 0($t3)

    li $t5, 2
    beq $t4, $t5, player_found_treasure

    li $t5, 4
    beq $t4, $t5, player_found_exit

    li $v0, 0
    j current_tile_done

player_found_treasure:
    sb $zero, 0($t3)

    lw $t0, treasuresFound
    addi $t0, $t0, 1
    sw $t0, treasuresFound

    lw $t1, score
    addi $t1, $t1, 100
    sw $t1, score

    li $v0, 4
    la $a0, treasureMessage
    syscall

    li $t1, 3
    bne $t0, $t1, treasure_check_done
    jal spawn_random_exit

treasure_check_done:
    li $v0, 0
    j current_tile_done

player_found_exit:
    li $v0, 1

current_tile_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Spawn the exit at a random inner corner not occupied by a character.
spawn_random_exit:
choose_exit_corner:
    li $v0, 42
    li $a0, 1
    li $a1, 4
    syscall
    move $t0, $a0

    la $t1, exitCornerRows
    add $t1, $t1, $t0
    lb $t2, 0($t1)             # chosen row

    la $t1, exitCornerColumns
    add $t1, $t1, $t0
    lb $t3, 0($t1)             # chosen column

    lw $t4, playerRow
    bne $t2, $t4, exit_check_enemies
    lw $t4, playerColumn
    beq $t3, $t4, choose_exit_corner

exit_check_enemies:
    la $t4, enemyRows
    la $t5, enemyColumns
    li $t6, 0

exit_enemy_loop:
    li $t7, 2
    beq $t6, $t7, place_random_exit

    lw $t8, 0($t4)
    bne $t2, $t8, exit_next_enemy
    lw $t8, 0($t5)
    beq $t3, $t8, choose_exit_corner

exit_next_enemy:
    addi $t4, $t4, 4
    addi $t5, $t5, 4
    addi $t6, $t6, 1
    j exit_enemy_loop

place_random_exit:
    sll $t4, $t2, 3
    add $t4, $t4, $t3
    la $t5, board
    add $t5, $t5, $t4
    li $t6, 4
    sb $t6, 0($t5)

    li $t6, 1
    sw $t6, exitActive

    li $v0, 4
    la $a0, exitSpawnMessage
    syscall
    jr $ra


# ------------------------------------------------------------
# Killer movement and collision logic
# ------------------------------------------------------------
# Return 1 if the player currently occupies an enemy position.
player_enemy_collision:
    lw $t0, playerRow
    lw $t1, playerColumn
    la $t2, enemyRows
    la $t3, enemyColumns
    li $t4, 0

collision_loop:
    li $t5, 2
    beq $t4, $t5, no_player_enemy_collision

    lw $t6, 0($t2)
    bne $t0, $t6, collision_next_enemy
    lw $t6, 0($t3)
    beq $t1, $t6, player_enemy_collision_found

collision_next_enemy:
    addi $t2, $t2, 4
    addi $t3, $t3, 4
    addi $t4, $t4, 1
    j collision_loop

player_enemy_collision_found:
    li $v0, 1
    jr $ra

no_player_enemy_collision:
    li $v0, 0
    jr $ra


# Move both enemies. Return 0 to continue or 2 if the last life is lost.
move_enemies:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $a0, 0
    jal move_one_enemy
    bne $v0, $zero, enemy_caught_player

    li $a0, 1
    jal move_one_enemy
    bne $v0, $zero, enemy_caught_player

    li $v0, 0
    j move_enemies_done

enemy_caught_player:
    jal handle_player_caught

move_enemies_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Move one enemy toward the player.
# $a0 = enemy index (0 or 1). Return 1 if it reaches the player.
move_one_enemy:
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp)
    sw $s3, 16($sp)
    sw $s4, 12($sp)
    sw $s5, 8($sp)

    move $s0, $a0              # enemy index
    sll $t0, $s0, 2

    la $t1, enemyRows
    add $t1, $t1, $t0
    lw $s1, 0($t1)             # enemy row

    la $t1, enemyColumns
    add $t1, $t1, $t0
    lw $s2, 0($t1)             # enemy column

    li $s3, 0                  # desired row step
    lw $t2, playerRow
    blt $t2, $s1, enemy_wants_up
    bgt $t2, $s1, enemy_wants_down
    j find_enemy_column_step

enemy_wants_up:
    li $s3, -1
    j find_enemy_column_step

enemy_wants_down:
    li $s3, 1

find_enemy_column_step:
    li $s4, 0                  # desired column step
    lw $t2, playerColumn
    blt $t2, $s2, enemy_wants_left
    bgt $t2, $s2, enemy_wants_right
    j choose_enemy_axis

enemy_wants_left:
    li $s4, -1
    j choose_enemy_axis

enemy_wants_right:
    li $s4, 1

choose_enemy_axis:
    li $v0, 42                 # randomize vertical/horizontal priority
    li $a0, 2
    li $a1, 2
    syscall
    move $s5, $a0

    beq $s5, $zero, enemy_vertical_first
    j enemy_horizontal_first

enemy_vertical_first:
    beq $s3, $zero, vertical_first_try_horizontal

    add $a0, $s1, $s3
    move $a1, $s2
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

vertical_first_try_horizontal:
    beq $s4, $zero, enemy_fallback_moves

    move $a0, $s1
    add $a1, $s2, $s4
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position
    j enemy_fallback_moves

enemy_horizontal_first:
    beq $s4, $zero, horizontal_first_try_vertical

    move $a0, $s1
    add $a1, $s2, $s4
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

horizontal_first_try_vertical:
    beq $s3, $zero, enemy_fallback_moves

    add $a0, $s1, $s3
    move $a1, $s2
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

# If both direct chase moves are blocked, try all four directions.
enemy_fallback_moves:
    addi $a0, $s1, -1
    move $a1, $s2
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

    move $a0, $s1
    addi $a1, $s2, -1
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

    addi $a0, $s1, 1
    move $a1, $s2
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

    move $a0, $s1
    addi $a1, $s2, 1
    move $a2, $s0
    jal can_enemy_move
    bne $v0, $zero, accept_enemy_position

    move $a0, $s1              # stay in place if completely blocked
    move $a1, $s2

accept_enemy_position:
    sll $t0, $s0, 2
    la $t1, enemyRows
    add $t1, $t1, $t0
    sw $a0, 0($t1)

    la $t1, enemyColumns
    add $t1, $t1, $t0
    sw $a1, 0($t1)

    lw $t2, playerRow
    bne $a0, $t2, enemy_did_not_catch
    lw $t2, playerColumn
    bne $a1, $t2, enemy_did_not_catch

    li $v0, 1
    j move_one_enemy_done

enemy_did_not_catch:
    li $v0, 0

move_one_enemy_done:
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra


# $a0=row, $a1=column, $a2=current enemy index.
# Return 1 if open and not occupied by the other enemy.
can_enemy_move:
    bltz $a0, enemy_move_blocked
    bltz $a1, enemy_move_blocked

    li $t0, 8
    bge $a0, $t0, enemy_move_blocked
    bge $a1, $t0, enemy_move_blocked

    sll $t1, $a0, 3
    add $t1, $t1, $a1
    la $t2, board
    add $t2, $t2, $t1
    lb $t3, 0($t2)

    li $t4, 1
    beq $t3, $t4, enemy_move_blocked

    xori $t4, $a2, 1           # index of the other enemy
    sll $t4, $t4, 2

    la $t5, enemyRows
    add $t5, $t5, $t4
    lw $t6, 0($t5)
    bne $a0, $t6, enemy_move_allowed

    la $t5, enemyColumns
    add $t5, $t5, $t4
    lw $t6, 0($t5)
    beq $a1, $t6, enemy_move_blocked

enemy_move_allowed:
    li $v0, 1
    jr $ra

enemy_move_blocked:
    li $v0, 0
    jr $ra


# Remove one life and 50 points. Reset positions if lives remain.
handle_player_caught:
    lw $t0, lives
    addi $t0, $t0, -1
    sw $t0, lives

    lw $t1, score
    addi $t1, $t1, -50
    bgez $t1, caught_score_ready
    move $t1, $zero

caught_score_ready:
    sw $t1, score

    li $v0, 4
    la $a0, caughtMessage
    syscall

    blez $t0, caught_final_life

    li $t1, 1
    sw $t1, playerRow
    sw $t1, playerColumn

    la $t2, enemyRows
    sw $t1, 0($t2)
    li $t3, 6
    sw $t3, 4($t2)

    la $t2, enemyColumns
    sw $t3, 0($t2)
    sw $t3, 4($t2)

    li $v0, 4
    la $a0, resetMessage
    syscall

    li $v0, 0
    jr $ra

caught_final_life:
    li $v0, 2
    jr $ra


# ------------------------------------------------------------
# Text display procedures
# ------------------------------------------------------------
show_board:
    li $t0, 0

show_board_loop:
    li $t1, 64
    beq $t0, $t1, show_board_done

    srl $t2, $t0, 3            # row
    andi $t3, $t0, 7           # column

    # Enemies take priority so a capture displays K.
    la $t4, enemyRows
    la $t5, enemyColumns
    li $t6, 0

show_enemy_check_loop:
    li $t7, 2
    beq $t6, $t7, show_player_check

    lw $t8, 0($t4)
    bne $t2, $t8, show_next_enemy
    lw $t8, 0($t5)
    beq $t3, $t8, print_killer_tile

show_next_enemy:
    addi $t4, $t4, 4
    addi $t5, $t5, 4
    addi $t6, $t6, 1
    j show_enemy_check_loop

show_player_check:
    lw $t4, playerRow
    bne $t2, $t4, show_board_tile
    lw $t4, playerColumn
    bne $t3, $t4, show_board_tile

    li $a0, 80                 # P
    j print_board_character

print_killer_tile:
    li $a0, 75                 # K
    j print_board_character

show_board_tile:
    la $t4, board
    add $t4, $t4, $t0
    lb $t5, 0($t4)

    beq $t5, $zero, print_empty_tile
    li $t6, 1
    beq $t5, $t6, print_wall_tile
    li $t6, 2
    beq $t5, $t6, print_treasure_tile

    li $a0, 69                 # E
    j print_board_character

print_empty_tile:
    li $a0, 46                 # .
    j print_board_character

print_wall_tile:
    li $a0, 35                 # #
    j print_board_character

print_treasure_tile:
    li $a0, 84                 # T

print_board_character:
    li $v0, 11
    syscall

    li $a0, 32
    li $v0, 11
    syscall

    addi $t0, $t0, 1
    andi $t1, $t0, 7
    bne $t1, $zero, show_board_loop

    li $v0, 4
    la $a0, newline
    syscall
    j show_board_loop

show_board_done:
    jr $ra


print_statistics:
    li $v0, 4
    la $a0, livesMessage
    syscall

    lw $a0, lives
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, scoreMessage
    syscall

    lw $a0, score
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, movesMessage
    syscall

    lw $a0, moveCount
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, treasureStatusMsg
    syscall

    lw $a0, treasuresFound
    li $v0, 1
    syscall

    li $v0, 4
    la $a0, slashThree
    syscall
    jr $ra


# ------------------------------------------------------------
# Bitmap Display procedures
# ------------------------------------------------------------
# Redraw the maze, happy player face, and two killer faces.
draw_graphics:
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)

    li $s0, 0
    la $s1, board

draw_board_loop:
    li $t0, 64
    beq $s0, $t0, draw_player_face

    srl $s2, $s0, 3
    andi $t1, $s0, 7

    add $t2, $s1, $s0
    lb $t3, 0($t2)

    beq $t3, $zero, bitmap_empty
    li $t4, 1
    beq $t3, $t4, bitmap_wall
    li $t4, 2
    beq $t3, $t4, bitmap_treasure

    lw $a2, colorExit
    j draw_one_board_tile

bitmap_empty:
    lw $a2, colorEmpty
    j draw_one_board_tile

bitmap_wall:
    lw $a2, colorWall
    j draw_one_board_tile

bitmap_treasure:
    lw $a2, colorTreasure

draw_one_board_tile:
    move $a0, $s2
    move $a1, $t1
    jal draw_tile

    addi $s0, $s0, 1
    j draw_board_loop

draw_player_face:
    lw $a0, playerRow
    lw $a1, playerColumn
    jal draw_happy_face

    li $s0, 0

draw_killer_loop:
    li $t0, 2
    beq $s0, $t0, graphics_done

    sll $t1, $s0, 2
    la $t2, enemyRows
    add $t2, $t2, $t1
    lw $a0, 0($t2)

    la $t2, enemyColumns
    add $t2, $t2, $t1
    lw $a1, 0($t2)
    jal draw_killer_face

    addi $s0, $s0, 1
    j draw_killer_loop

graphics_done:
    lw $s2, 4($sp)
    lw $s1, 8($sp)
    lw $s0, 12($sp)
    lw $ra, 16($sp)
    addi $sp, $sp, 20
    jr $ra


# $a0=row, $a1=column, $a2=color. Fill one 8x8-unit tile.
draw_tile:
    sll $t0, $a0, 11           # row * 8 * 256 bytes
    sll $t1, $a1, 5            # column * 8 * 4 bytes
    add $t0, $t0, $t1

    li $t1, 0x10008000
    add $t1, $t1, $t0
    li $t2, 0

draw_tile_row:
    li $t3, 8
    beq $t2, $t3, draw_tile_done
    li $t4, 0
    move $t5, $t1

draw_tile_column:
    li $t3, 8
    beq $t4, $t3, next_tile_row

    sw $a2, 0($t5)
    addi $t5, $t5, 4
    addi $t4, $t4, 1
    j draw_tile_column

next_tile_row:
    addi $t1, $t1, 256
    addi $t2, $t2, 1
    j draw_tile_row

draw_tile_done:
    jr $ra


# Draw a blue 8x8 happy face with white eyes and smile.
draw_happy_face:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    move $s0, $a0
    move $s1, $a1

    lw $a2, colorPlayer
    jal draw_tile

    sll $t0, $s0, 11
    sll $t1, $s1, 5
    add $t0, $t0, $t1
    li $t1, 0x10008000
    add $t1, $t1, $t0
    lw $t2, colorWhite

    sw $t2, 520($t1)           # eyes: row 2, columns 2 and 5
    sw $t2, 532($t1)

    sw $t2, 1284($t1)          # smile endpoints: row 5
    sw $t2, 1304($t1)
    sw $t2, 1544($t1)          # smile bottom: row 6, columns 2-5
    sw $t2, 1548($t1)
    sw $t2, 1552($t1)
    sw $t2, 1556($t1)

    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra


# Draw a red 8x8 killer face with angry eyes, mouth, and fangs.
draw_killer_face:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    move $s0, $a0
    move $s1, $a1

    lw $a2, colorKiller
    jal draw_tile

    sll $t0, $s0, 11
    sll $t1, $s1, 5
    add $t0, $t0, $t1
    li $t1, 0x10008000
    add $t1, $t1, $t0
    lw $t2, colorBlack

    sw $t2, 516($t1)           # angry left eye
    sw $t2, 776($t1)
    sw $t2, 536($t1)           # angry right eye
    sw $t2, 788($t1)

    sw $t2, 1284($t1)          # mouth: row 5, columns 1-6
    sw $t2, 1288($t1)
    sw $t2, 1292($t1)
    sw $t2, 1296($t1)
    sw $t2, 1300($t1)
    sw $t2, 1304($t1)

    lw $t2, colorWhite
    sw $t2, 1288($t1)          # two white fangs
    sw $t2, 1300($t1)

    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra
