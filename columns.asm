################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Kiko Chen, 1010874733
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       2
# - Unit height in pixels:      2
# - Display width in pixels:    32
# - Display height in pixels:   32
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data/Constants
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

# Learned about .eqv on Stack Overflow so using it here
.eqv BOARD_WIDTH 6 # Width of the playing board
.eqv BOARD_HEIGHT 14 # Height of the playing board
.eqv BOARD_X 2 # x coordinate of top left of the playing board
.eqv BOARD_Y 2 # y coordinate of top left of the playing board

# colors
.eqv RED 0xff0000
.eqv ORANGE 0xffa500
.eqv YELLOW 0xffff00
.eqv GREEN 0x00ff00
.eqv BLUE 0x0000ff
.eqv PURPLE 0xa020f0
.eqv BROWN 0x964b00
.eqv GRAY 0x808080
.eqv WHITE 0xffffff
.eqv BLACK 0x000000
colors_list:
    .word RED, ORANGE, YELLOW, GREEN, BLUE, PURPLE

# current column
curr_col_x: .word 3
curr_col_y: .word 0
curr_col_c0: .word RED
curr_col_c1: .word GREEN
curr_col_c2: .word BLUE

# next column
next_col_c0: .word RED
next_col_c1: .word GREEN
next_col_c2: .word BLUE

# saved column
saved_col_c0: .word 0
saved_col_c1: .word 0
saved_col_c2: .word 0
saved_exists: .word 0

# keys
.eqv KEY_A 0x61
.eqv KEY_D 0x64
.eqv KEY_S 0x73
.eqv KEY_W 0x77
.eqv KEY_Q 0x71
.eqv KEY_P 0x70
.eqv KEY_R 0x72
.eqv KEY_E 0x65

# board
board: .word 0:84
clear: .word 0:84 # marks whether to clear (1) or not (0) a specific pixel

paused: .word 0

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

j main

##############################################################################
# Basic helpers
##############################################################################

## draws a rectangle
#
# t0 = the color of the rectangle
# a0 = the x coordinate of the rectangle
# a1 = the y coordinate of the rectangle
# a2 = the width of the rectangle
# a3 = the height of the rectangle
#
# overwrites: t1, t2, t3, t4
draw_rectangle:
    move $t1, $a0 # t1 = current x coordinate
    move $t2, $a1 # t2 = current y coordinate
    addu $t3, $a0, $a2 # t3 = stopping x coordinate
    addu $t4, $a1, $a3 # t4 = stopping y coordinate
    rect_down_loop:
        beq $t2, $t4, rect_done # finish loop if current y = stopping y
        move $t1, $a0 # move current x to the start of row
        rect_row_loop:
            beq $t1, $t3, rect_row_done # finish loop if current x = stopping x
            
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $ra, 0($sp) # push $ra onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $a0, 0($sp) # push $a0 onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $a1, 0($sp) # push $a1 onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t1, 0($sp) # push $t1 onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t2, 0($sp) # push $t2 onto the stack
            
            move $a0, $t1 # give draw_pixel current x
            move $a1, $t2 # give draw_pixel current y
            jal draw_pixel
            
            lw $t2, 0($sp) # pop $t2 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $t1, 0($sp) # pop $t1 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $a1, 0($sp) # pop $a1 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $a0, 0($sp) # pop $a0 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $ra, 0($sp) # pop $ra from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            
            addi $t1, $t1, 1 # add 1 to the current x
            j rect_row_loop
        rect_row_done:
            addi $t2, $t2, 1 # add 1 to the current y
            j rect_down_loop
    rect_done:
        jr $ra
        
## draws a pixel
#
# t0 = the color of the pixel
# a0 = the x coordinate of the pixel
# a1 = the y coordinate of the pixel
#
# modifies: t1, t2
draw_pixel:
    lw $t1, ADDR_DSPL
    sll $t2, $a1, 4 # calculate address for (1, y)
    addu $t2, $t2, $a0 # calculate address for (x, y)
    sll $t2, $t2, 2 # multiply by 4 for the byte offset
    addu $t2, $t1, $t2 # compute final address
    sw $t0, 0($t2)
    jr $ra

## draws a pixel relative to board
#
# t0 = the color of the pixel
# a0 = the x coordinate of the pixel relative to the board
# a1 = the y coordinate of the pixel relative to the board
#
# overwrites: t1, t2
draw_board_pixel:
    # TODO: maybe implement checks to not draw pixels outside of board
    lw $t1, ADDR_DSPL
    sll $t2, $a1, 4 # calculate address for (1, y)
    addu $t2, $t2, $a0 # calculate address for (x, y)
    addu $t2, $t2, 17 # make (x,y) relative to the board
    sll $t2, $t2, 2 # multiply by 4 for the byte offset
    addu $t2, $t1, $t2 # compute final address
    sw $t0, 0($t2)
    jr $ra

## get the color and store in v0
#
# a0 = x coodinate relative to board
# a1 = y coodinate relative to board
# 
# overwrites: t0, t1, v0
board_get:
    la $t0, board # get the address of the board
    
    mul $t1, $a1, 6 # 6y
    addu $t1, $t1, $a0 # 6y + x
    sll $t1, $t1, 2 # multiply by 4 for the byte offset
    addu $t0, $t0, $t1 # compute final address
    lw $v0, 0($t0) # load color into v0
    
    jr $ra

## set a color
#
# a0 = x coodinate relative to board
# a1 = y coodinate relative to board
# a2 = color
#
# overwrites: t0, t1
board_set:
    la $t0, board # get the address of the board

    mul $t1, $a1, 6 # 6y
    addu $t1, $t1, $a0 # 6y + x
    sll $t1, $t1, 2 # multiply by 4 for the byte offset
    addu $t0, $t0, $t1 # compute final address
    sw $a2, 0($t0) # set color
    
    jr $ra

## get whether to clear pixel and store in v0
#
# a0 = x coodinate relative to board
# a1 = y coodinate relative to board
# 
# overwrites: t0, t1, v0
clear_get:
    la $t0, clear # get the address of the board
    
    mul $t1, $a1, 6 # 6y
    addu $t1, $t1, $a0 # 6y + x
    sll $t1, $t1, 2 # multiply by 4 for the byte offset
    addu $t0, $t0, $t1 # compute final address
    lw $v0, 0($t0) # load number
    
    jr $ra

## set the pixel to clear
#
# a0 = x coodinate relative to board
# a1 = y coodinate relative to board
#
# overwrites: t0, t1
clear_set:
    la $t0, clear # get the address of the board

    mul $t1, $a1, 6 # 6y
    addu $t1, $t1, $a0 # 6y + x
    sll $t1, $t1, 2 # multiply by 4 for the byte offset
    addu $t0, $t0, $t1 # compute final address
    li $t1, 1
    sw $t1, 0($t0) # set pixel to 1 (clear)
    
    jr $ra
    
## reset pixel in clear
#
# a0 = x coordinate relative to board
# a1 = y coordinate relative to board
# 
# overwrites: t0, t1
clear_reset:
    la $t0, clear # get the address of the board

    mul $t1, $a1, 6 # 6y
    addu $t1, $t1, $a0 # 6y + x
    sll $t1, $t1, 2 # multiply by 4 for the byte offset
    addu $t0, $t0, $t1 # compute final address
    li $t1, 0
    sw $t1, 0($t0) # set pixel to 0 (clear)
    
    jr $ra

## handles input and calls corresponding functions for each key
#
# overwrites: t0, t1, t2, t3, t4
handle_input:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    lw $t0, ADDR_KBRD
    lw $t1, 0($t0) # t1 = is key pressed
    bne $t1, 1, input_done # if key not pressed, finish function
    
    lw $t2, 4($t0) # load second word from keyboard
    
    # check if p pressed
    li $t1, KEY_P
    beq $t1, $t2, input_P
    
    # if paused, skip all other keys
    la $t3, paused
    lw $t4, 0($t3)
    bne $t4, $zero, input_done
    
    # check if e pressed
    li $t1, KEY_E
    beq $t1, $t2, input_E
    
    # check if w pressed
    li $t1, KEY_W
    beq $t1, $t2, input_W

    # check if a pressed
    li $t1, KEY_A
    beq $t1, $t2, input_A

    # check if s pressed
    li $t1, KEY_S
    beq $t1, $t2, input_S

    # check if d pressed
    li $t1, KEY_D
    beq $t1, $t2, input_D

    # check if q pressed
    li $t1, KEY_Q
    beq $t1, $t2, input_Q
    
    j input_done # if other keys are pressed
    
    input_P:
        la $t3, paused # load address of paused
        lw $t4, 0($t3) # load paused
        nor $t4, $t4, $zero
        sw $t4, 0($t3)
        j input_done
    
    input_E:
        jal save_col
        j input_done
    
    input_W:
        jal rotate_col
        j input_done
    
    input_A:
        jal move_col_l
        j input_done
    
    input_S:
        jal move_col_d
        j input_done
    
    input_D:
        jal move_col_r
        j input_done
    
    # quit game
    input_Q:
        li $v0, 10
        syscall
    
    input_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

##############################################################################
# Other helpers
##############################################################################

## reset the game state in order for retries
#
# overwrites: t0, t1, t2, t3, s0, s1, s2
reset_game_state:
    # clear board and clear
    la $t1, board
    la $t2, clear
    li $t0, 84
    clear_board_loop:
        beq $t0, $zero, clear_board_done # finish when 84 pixels all cleared
        sw $zero, 0($t1)
        addi $t1, $t1, 4
        sw $zero, 0($t2)
        addi $t2, $t2, 4
        addi $t0, $t0, -1
        j clear_board_loop
    clear_board_done:
        li $s0, 0 # game timer
        li $s1, 0 # time reduction timer
        li $s2, 0 # time reduction
        la $t3, paused # unpause
        sw $zero, 0($t3)
        la $t4, saved_exists # reset saved column - no saved column
        sw $zero, 0($t4)
        jr $ra

## initialize the column by setting position and randomizing colors
#
# overwrites: v0, a0, a1, t0, t1, t2
init_col:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # set starting position
    li $t2, 3
    sw $t2, curr_col_x
    li $t2, 0
    sw $t2, curr_col_y
    
    # check if no space to place column
    li $a0, 3
    li $a1, 2
    jal board_get
    bne $v0, $zero, game_over
    
    # move next column to current
    lw $t0, next_col_c0
    sw $t0, curr_col_c0
    lw $t0, next_col_c1
    sw $t0, curr_col_c1
    lw $t0, next_col_c2
    sw $t0, curr_col_c2
    
    # generate new next column
    jal randomize_next_col
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra
    
## draws the current column
#
# overwrites: a0, a1, t0, t3, t4
draw_curr_col:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    lw $t3, curr_col_x
    lw $t4, curr_col_y
    move $a0, $t3
    move $a1, $t4
    
    # draw first pixel
    lw $t0, curr_col_c0
    jal draw_board_pixel
    
    # draw second pixel
    lw $t0, curr_col_c1
    addi $a1, $a1, 1
    jal draw_board_pixel
    
    # draw second pixel
    lw $t0, curr_col_c2
    addi $a1, $a1, 1
    jal draw_board_pixel
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra
    
## draws the next column
#
# overwrites: 
draw_next_col:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    li $t3, 8 # x position of preview
    li $t4, 1 # y position of preview
    move $a0, $t3
    move $a1, $t4
    
    # draw first pixel
    lw $t0, next_col_c0
    jal draw_pixel
    
    # draw second pixel
    lw $t0, next_col_c1
    addi $a1, $a1, 1
    jal draw_pixel
    
    # draw second pixel
    lw $t0, next_col_c2
    addi $a1, $a1, 1
    jal draw_pixel
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra

## randomize colors for the next column
#
# overwrites: v0, a0, a1, t0, t1, t2
randomize_next_col:
    # randomize color 1
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 1
    la $t2, colors_list
    sll $a0, $a0, 2
    addu $t2, $t2, $a0
    lw $a0, 0($t2)
    
    # set color 1
    sw $a0, next_col_c0
    
    # randomize color 2
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 2
    la $t2, colors_list
    sll $a0, $a0, 2
    addu $t2, $t2, $a0
    lw $a0, 0($t2)
    
    # set color 2
    sw $a0, next_col_c1
    
    # randomize color 3
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 3
    la $t2, colors_list
    sll $a0, $a0, 2
    addu $t2, $t2, $a0
    lw $a0, 0($t2)
    
    # set color 3
    sw $a0, next_col_c2
    
    jr $ra

## save the curr column if e is pressed
#
# overwrites: t0, t1, t2, t3
save_col:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    la $t0, saved_exists
    lw $t1, 0($t0)
    beq $t1, $zero, save_new # if no saved right now, go to save_new
    
    # else:
    
    # swap c0
    lw $t2, curr_col_c0
    lw $t3, saved_col_c0
    sw $t3, curr_col_c0
    sw $t2, saved_col_c0

    # swap c1
    lw $t2, curr_col_c1
    lw $t3, saved_col_c1
    sw $t3, curr_col_c1
    sw $t2, saved_col_c1

    # swap c2
    lw $t2, curr_col_c2
    lw $t3, saved_col_c2
    sw $t3, curr_col_c2
    sw $t2, saved_col_c2
    
    j save_done
    
    save_new:
        # save current column
        lw $t2, curr_col_c0
        sw $t2, saved_col_c0
        lw $t2, curr_col_c1
        sw $t2, saved_col_c1
        lw $t2, curr_col_c2
        sw $t2, saved_col_c2
        
        # set saved_exists to 1
        li $t1, 1
        sw $t1, 0($t0)
        
        jal init_col
    
    save_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## draws the save column
#
# overwrites: t0, t1, t2, t3, t4, a0, a1, a2, a3
draw_saved_col:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    li $t0, BLACK
    li $a0, 8
    li $a1, 5
    li $a2, 1
    li $a3, 3
    jal draw_rectangle
    
    # don't draw if no saved column
    la $t1, saved_exists
    lw $t2, 0($t1)
    beq $t2, $zero, draw_saved_done
    
    li $t3, 8 # x position of preview
    li $t4, 5 # y position of preview
    move $a0, $t3
    move $a1, $t4
    
    # draw first pixel
    lw $t0, saved_col_c0
    jal draw_pixel
    
    # draw second pixel
    lw $t0, saved_col_c1
    addi $a1, $a1, 1
    jal draw_pixel
    
    # draw second pixel
    lw $t0, saved_col_c2
    addi $a1, $a1, 1
    jal draw_pixel
    
    draw_saved_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## draws the paused screen
#
# overwrites: t0, t1, t2, t3, t4, a0, a1, a2, a3

## draws a rectangle
#
# t0 = the color of the rectangle
# a0 = the x coordinate of the rectangle
# a1 = the y coordinate of the rectangle
# a2 = the width of the rectangle
# a3 = the height of the rectangle
draw_pause_screen:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # draw pause background
    li $t0, BROWN
    li $a0, 0
    li $a1, 0
    li $a2, 16
    li $a3, 16
    jal draw_rectangle
    
    # draw pause symbol
    li $t0, BLACK
    li $a0, 6
    li $a1, 6
    li $a2, 1
    li $a3, 4
    jal draw_rectangle
    
    li $t0, BLACK
    li $a0, 9
    li $a1, 6
    li $a2, 1
    li $a3, 4
    jal draw_rectangle
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra

## rotates the column
#
# overwrites: t3, t4, t5
rotate_col:
    # loads the current colors
    lw $t3, curr_col_c0 
    lw $t4, curr_col_c1
    lw $t5, curr_col_c2
    
    # shift and store
    sw $t5, curr_col_c0
    sw $t3, curr_col_c1
    sw $t4, curr_col_c2
    
    jr $ra

## move the column left if possible
#
# overwrites: t1, t2, t3, t4, t5
move_col_l:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    lw $t3, curr_col_x # load current column x
    lw $t4, curr_col_y # load current column y
    addi $t5, $t3, -1 # t5 = new x
    
    ble $t3, $zero, move_l_done # if current x <= 0, don't do anything
    
    # check first pixel on the left
    move $a0, $t5
    move $a1, $t4
    jal board_get
    bne $v0, $zero, move_l_done
    
    # check second pixel on the left
    move $a0, $t5
    addi $a1, $t4, 1
    jal board_get
    bne $v0, $zero, move_l_done
    
    # check third pixel on the left
    move $a0, $t5
    addi $a1, $t4, 2
    jal board_get
    bne $v0, $zero, move_l_done
    
    addi $t3, $t3, -1 # decrement current x
    sw $t3, curr_col_x # store
    move_l_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## move the column right if possible
#
# overwrites: t1, t2, t3, t4, t5
move_col_r:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    lw $t3, curr_col_x # load current column x
    lw $t4, curr_col_y # load current column y
    addi $t5, $t3, 1 # t5 = new x
    
    bge $t3, 5, move_r_done # if current x >= 5, don't do anything
    
    # check first pixel on the right
    move $a0, $t5
    move $a1, $t4
    jal board_get
    bne $v0, $zero, move_r_done
    
    # check second pixel on the right
    move $a0, $t5
    addi $a1, $t4, 1
    jal board_get
    bne $v0, $zero, move_r_done
    
    # check third pixel on the right
    move $a0, $t5
    addi $a1, $t4, 2
    jal board_get
    bne $v0, $zero, move_r_done
    
    addi $t3, $t3, 1 # increment current x
    sw $t3, curr_col_x # store
    move_r_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## move the column down if possible
#
# overwrites: a0, a1, t0, t1, t2, t3, t4, t5, t6, t7
move_col_d:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # load current column position
    lw $t6, curr_col_x
    lw $t7, curr_col_y
    
    addi $t2, $t7, 3 # t2 = pixel just below column
    bge $t2, 14, col_land # land column if ground is reached
    
    # check color below column
    move $a0, $t6
    move $a1, $t2
    
    jal board_get
    
    bne $v0, $zero, col_land # land column if pixel below isnt black
    
    # else move down
    addi $t7, $t7, 1
    sw $t7, curr_col_y
    j col_landed
    
    col_land:
        # load gem colors
        lw $t3, curr_col_c0
        lw $t4, curr_col_c1
        lw $t5, curr_col_c2
        
        # set first pixel
        move $a0, $t6
        move $a1, $t7
        move $a2, $t3
        jal board_set
        
        # set second pixel
        move $a0, $t6
        addi $a1, $t7, 1
        move $a2, $t4
        jal board_set
        
        # set third pixel
        move $a0, $t6
        addi $a1, $t7, 2
        move $a2, $t5
        jal board_set
        
        jal clear_multiple_matches
        
        jal init_col
    col_landed:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra
      
## loops clear matches and gravity until no more matches to clear
# 
# overwrites: ..
clear_multiple_matches:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    clear_loop:
        jal write_clear_matches # write down the immediate matches
        beq $v1, $zero, clear_loop_done # if no matches found (indicated by v1), then finish
        jal clear_matches # clear the matches
        jal gravity # apply gravity
        j clear_loop # loop
    clear_loop_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra
    
## clear the immediate matches and set v1 = 1 if pixel clearned
# 
# overwrites: t0, t1, t2, t3, t4, t5, a0, a1, v0, v1
write_clear_matches:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    move $v1, $zero # set v1 = 0 (no pixel cleared)
    li $t3, 0 # y = 0
    write_down_loop:
        bge $t3, 14, write_done # finish loop if current y >= 14
        li $t2, 0 # x = 0
        write_row_loop:
            bge $t2, 6, write_row_done # finish loop if current x >= 6
            
            move $a0, $t2
            move $a1, $t3
            
            jal board_get # v0 = color of current pixel
            move $t4, $v0 # t4 = color of current pixel
            beq $t4, 0, left_down_done # skip all checks if current pixel is black
            
                move $a0, $t2 # a0 = x in the loop
                move $a1, $t3 # a1 = y in the loop
                li $t5, 1 # match length
                right_loop:
                    beq $a0, 5, right_loop_done # don't check right if x = 5
                    
                    addi $a0, $a0, 1 # next pixel
                    
                    jal board_get # v0 = color of next pixel
                    bne $t4, $v0, right_loop_done # finish loop if curr pixel doesn't equal to next pixel
                    
                    # else (match):
                    addi $t5, $t5, 1 # add one to match length 
                    
                    j right_loop
                right_loop_done:
                    blt $t5, 3, right_done # if match length < 3, then finish this direction
                
                    # else (match length >= 3):
                    li $v1, 1 # set v1 = 1 to indicate something has been cleared
                    move $a0, $t2 # a0 = x
                    move $a1, $t3 # a1 = y
                    right_loop_write:
                        beq $t5, 0, right_done
                        jal clear_set
                        
                        addi $a0, $a0, 1
                        addi $t5, $t5, -1
                        j right_loop_write
                    right_done:
                
                move $a0, $t2 # a0 = x in the loop
                move $a1, $t3 # a1 = y in the loop
                li $t5, 1 # match length
                right_down_loop:
                    beq $a0, 5, right_down_loop_done # don't check right if x = 5
                    beq $a1, 13, right_down_loop_done # don't check right if y = 13
                    
                    # next pixel
                    addi $a0, $a0, 1
                    addi $a1, $a1, 1
                    
                    jal board_get # v0 = color of next pixel
                    bne $t4, $v0, right_down_loop_done # finish loop if curr pixel doesn't equal to next pixel
                    
                    # else (match):
                    addi $t5, $t5, 1 # add one to match length 
                    
                    j right_down_loop
                right_down_loop_done:
                    blt $t5, 3, right_down_done # if match length < 3, then finish this direction
                
                    # else (match length >= 3):
                    li $v1, 1 # set v1 = 1 to indicate something has been cleared
                    move $a0, $t2 # a0 = x
                    move $a1, $t3 # a1 = y
                    right_down_loop_write:
                        beq $t5, 0, right_down_done
                        jal clear_set
                        
                        addi $a0, $a0, 1
                        addi $a1, $a1, 1
                        addi $t5, $t5, -1
                        j right_down_loop_write
                    right_down_done:
                
                move $a0, $t2 # a0 = x in the loop
                move $a1, $t3 # a1 = y in the loop
                li $t5, 1 # match length
                down_loop:
                    beq $a1, 13, down_loop_done # don't check right if y = 13
                    
                    addi $a1, $a1, 1 # next pixel
                    
                    jal board_get # v0 = color of next pixel
                    bne $t4, $v0, down_loop_done # finish loop if curr pixel doesn't equal to next pixel
                    
                    # else (match):
                    addi $t5, $t5, 1 # add one to match length 
                    
                    j down_loop
                down_loop_done:
                    blt $t5, 3, down_done # if match length < 3, then finish this direction
                
                    # else (match length >= 3):
                    li $v1, 1 # set v1 = 1 to indicate something has been cleared
                    move $a0, $t2 # a0 = x
                    move $a1, $t3 # a1 = y
                    down_loop_write:
                        beq $t5, 0, down_done
                        jal clear_set
                        
                        addi $a1, $a1, 1
                        addi $t5, $t5, -1
                        j down_loop_write
                    down_done:
            
                move $a0, $t2 # a0 = x in the loop
                move $a1, $t3 # a1 = y in the loop
                li $t5, 1 # match length
                left_down_loop:
                    beq $a0, 0, left_down_loop_done # don't check right if x = 0
                    beq $a1, 13, left_down_loop_done # don't check right if y = 13
                    
                    # next pixel
                    addi $a0, $a0, -1
                    addi $a1, $a1, 1
                    
                    jal board_get # v0 = color of next pixel
                    bne $t4, $v0, left_down_loop_done # finish loop if curr pixel doesn't equal to next pixel
                    
                    # else (match):
                    addi $t5, $t5, 1 # add one to match length 
                    
                    j left_down_loop
                left_down_loop_done:
                    blt $t5, 3, left_down_done # if match length < 3, then finish this direction
                
                    # else (match length >= 3):
                    li $v1, 1 # set v1 = 1 to indicate something has been cleared
                    move $a0, $t2 # a0 = x
                    move $a1, $t3 # a1 = y
                    left_down_loop_write:
                        beq $t5, 0, left_down_done
                        jal clear_set
                        
                        addi $a0, $a0, -1
                        addi $a1, $a1, 1
                        addi $t5, $t5, -1
                        j left_down_loop_write
                    left_down_done:
            
            addi $t2, $t2, 1 # add 1 to the current x
            j write_row_loop
        write_row_done:
            addi $t3, $t3, 1 # add 1 to the current y
            j write_down_loop
    write_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## clear the matches as stated in clear, then, reset clear
#
# overwrites: t0, t1, t2, t3, t4, t5, a0, a1, a2
clear_matches:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # animate clear
    li $a2, WHITE
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $a2, GRAY
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $a2, BLACK
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $a2, GRAY
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $a2, WHITE
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $a2, GRAY
    jal color_matches
    
    # sleep
	li $v0, 32
    li $a0, 48
    syscall
    
    li $t3, 0 # y = 0
    clear_down_loop:
        bge $t3, 14, clear_done # finish loop if current y >= 14
        li $t2, 0 # x = 0
        clear_row_loop:
            bge $t2, 6, clear_row_done # finish loop if current x >= 6
    
            move $a0, $t2 # set a0 = curr x
            move $a1, $t3 # set a1 = curr y
            jal clear_get # get clear value
            beq $v0, 0, clear_pixel_done # if not clear, skip pixel
            clear_pixel: # else clear pixel and reset clear value
            li $a2, BLACK
            jal board_set
            jal clear_reset
            clear_pixel_done:
            
            addi $t2, $t2, 1 # add 1 to the current x
            j clear_row_loop
        clear_row_done:
            addi $t3, $t3, 1 # add 1 to the current y
            j clear_down_loop
    clear_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## color the matches as stated in clear
#
# a2 = color
#
# overwrites: t0, t1, t2, t3, t4, t5, a0, a1
color_matches:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    li $t3, 0 # y = 0
    color_down_loop:
        bge $t3, 14, color_done # finish loop if current y >= 14
        li $t2, 0 # x = 0
        color_row_loop:
            bge $t2, 6, color_row_done # finish loop if current x >= 6
    
            move $a0, $t2 # set a0 = curr x
            move $a1, $t3 # set a1 = curr y
            jal clear_get # get clear value
            beq $v0, 0, color_pixel_done # if not clear, skip pixel
            color_pixel: # else clear pixel and reset clear value
            jal board_set
            color_pixel_done:
            
            addi $t2, $t2, 1 # add 1 to the current x
            j color_row_loop
        color_row_done:
            addi $t3, $t3, 1 # add 1 to the current y
            j color_down_loop
    color_done:
        jal draw_board
        
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

## apply gravity
# 
# overwrites: t0, t1, t2, t3, t4, t5, v0, a0, a1, a2
gravity:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    li $t2, 0 # x = 0
    gravity_col_loop:
        bge $t2, 6, gravity_col_loop_done # finish loop if current x >= 6
        li $t3, 13 # y = 13
        col_read_loop:
            blt $t3, 0, col_read_done # finish loop if current y < 0
            
            li $t5, 0
            move $a0, $t2
            move $a1, $t3
            jal board_get
            bne $v0, 0, shift_done # skip if pixel is not black (no need to apply gravity)
            
            # else
            move $t4, $t3 # t4 = curr shift y
            shift_down:
                # finish shift loop when curr shift y <= 0
                # (last value of y = 1 in order to check pixel above)
                ble $t4, 0, clear_top
                
                # get color of pixel above (v0)
                move $a0, $t2
                addi $a1, $t4, -1
                jal board_get
                
                beq $v0, 0, skip_marking
                li $t5, 1
                skip_marking:
                # set the color (v0) it to current pixel
                move $a1, $t4
                move $a2, $v0
                jal board_set
                
                addi $t4, $t4, -1 # subtract 1 to the curr shift y
                j shift_down
                clear_top:
                    move $a1, $t4
                    li $a2, 0
                    jal board_set
            shift_done:
            beq $t5, 1, col_read_loop # shift again without subtracting curr y if pixels has been shifted
            
            addi $t3, $t3, -1 # subtract 1 to the current y
            j col_read_loop
        col_read_done:
            addi $t2, $t2, 1 # add 1 to the current x
            j gravity_col_loop
    gravity_col_loop_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra
    
## draws the board
#
# overwrites: t0, t1, t2, t3...
draw_board:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    li $t4, 0 # y = 0
    board_down_loop:
        bge $t4, 14, board_done # finish loop if current y >= 14
        li $t3, 0 # x = 0
        board_row_loop:
            bge $t3, 6, board_row_done # finish loop if current x >= 6
            
            # get the color
            move $a0, $t3
            move $a1, $t4
            jal board_get
            
            move $t0, $v0
            jal draw_board_pixel
            
            addi $t3, $t3, 1 # add 1 to the current x
            j board_row_loop
        board_row_done:
            addi $t4, $t4, 1 # add 1 to the current y
            j board_down_loop
    board_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

draw_screen:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # set background to brown
    li $t0, BROWN
    li $a0, 9
    li $a1, 6
    li $a2, 1
    li $a3, 4
    jal draw_rectangle
    
    jal draw_board
    jal draw_curr_col
    jal draw_next_col
    jal draw_saved_col
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra

## draws the game over screen and reset if retry
#
# overwrites: t0, t1, t2, t3, a0, a1, a2, a3
game_over:
    lw $ra, 0($sp) # pop unpopped ra from init_col
    addi $sp, $sp, 4
    
    jal game_over_animation
    
    # draw retry word
    li $t0, BLACK
    
    # letter R
    li $a0, 2
    li $a1, 2
    li $a2, 1
    li $a3, 5
    jal draw_rectangle
    li $a0, 3
    li $a1, 2
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    li $a0, 4
    li $a1, 2
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    li $a0, 3
    li $a1, 4
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    li $a0, 4
    li $a1, 5
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    
    # letter E
    li $a0, 6
    li $a1, 2
    li $a2, 1
    li $a3, 5
    jal draw_rectangle
    li $a0, 7
    li $a1, 2
    li $a2, 2
    li $a3, 1
    jal draw_rectangle
    li $a0, 7
    li $a1, 4
    li $a2, 2
    li $a3, 1
    jal draw_rectangle
    li $a0, 7
    li $a1, 6
    li $a2, 2
    li $a3, 1
    jal draw_rectangle
    
    # dash
    li $a0, 10
    li $a1, 4
    li $a2, 3
    li $a3, 1
    jal draw_rectangle
    
    # letter T
    li $a0, 0
    li $a1, 9
    li $a2, 3
    li $a3, 1
    jal draw_rectangle
    li $a0, 1
    li $a1, 10
    li $a2, 1
    li $a3, 4
    jal draw_rectangle
    
    # letter R
    li $a0, 4
    li $a1, 9
    li $a2, 1
    li $a3, 5
    jal draw_rectangle
    li $a0, 5
    li $a1, 9
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    li $a0, 6
    li $a1, 9
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    li $a0, 5
    li $a1, 11
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    li $a0, 6
    li $a1, 12
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    
    # letter Y
    li $a0, 8
    li $a1, 9
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    li $a0, 10
    li $a1, 9
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    li $a0, 9
    li $a1, 11
    li $a2, 1
    li $a3, 3
    jal draw_rectangle
    
    # question mark
    li $a0, 12
    li $a1, 9
    li $a2, 3
    li $a3, 1
    jal draw_rectangle
    li $a0, 14
    li $a1, 10
    li $a2, 1
    li $a3, 2
    jal draw_rectangle
    li $a0, 13
    li $a1, 11
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    li $a0, 13
    li $a1, 13
    li $a2, 1
    li $a3, 1
    jal draw_rectangle
    
    check_retry:
    lw $t3, ADDR_KBRD
    lw $t1, 0($t3) # t1 = is key pressed
    bne $t1, 1, check_retry # if key not pressed, check again
    
    lw $t2, 4($t3) # load second word from keyboard
    
    li $t1, KEY_R
    bne $t1, $t2, check_retry # if key is not r, check again
    
    j main

## animates the game over screen
#
# overwrites: t0, t3, t4, a0, a1
game_over_animation:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    li $t4, 0 # y = 0
    over_down_loop:
        bge $t4, 16, over_done # finish loop if current y >= 16
        li $t3, 0 # x = 0
        over_row_loop:
            bge $t3, 16, over_row_done # finish loop if current x >= 16
            
            li $t0, GRAY
            move $a0, $t3
            move $a1, $t4
            jal draw_pixel
            
            # sleep
        	li $v0, 32
            li $a0, 16
            syscall
            
            addi $t3, $t3, 1 # add 1 to the current x
            j over_row_loop
        over_row_done:
            addi $t4, $t4, 1 # add 1 to the current y
            j over_down_loop
    over_done:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra

main:
    jal reset_game_state
    
    # set background to brown
    li $t0, BROWN
    li $a0, 0
    li $a1, 0
    li $a2, 16
    li $a3, 16
    jal draw_rectangle
    
    jal randomize_next_col
    jal init_col
    
game_loop:
    # check and handle key press
    jal handle_input
 
    # check if paused
    la $t0, paused
    lw $t1, 0($t0)
    bne $t1, $zero, game_paused
    
    # auto gravity
    addi $s0, $s0, 1 # increment game timer
    addi $s1, $s1, 1 # increment time reduction timer
    blt $s1, 240, calc_down # if time reduction timer < 4 sec, move on
    
    # else:
        li $s1, 0
        ble $s2, -48, calc_down # don't reduce time past 0.2 seconds/down (1 - 0.8)
        addi $s2, $s2, -1
    calc_down:
        addi $t9, $s2, 60 # t9 = 1 sec + time reduction (negative)
        blt $s0, $t9, skip_down # if timer <= break, no down movement
    # else:
        li $s0, 0 # reset game timer
        jal move_col_d
    skip_down:

	# draw the screen
    jal draw_screen
    j game_unpaused
    
    game_paused:
    # when paused: no gravity, no movement, just draw pause screen
    jal draw_pause_screen
    
    game_unpaused:
    
	# sleep
	li $v0, 32
    li $a0, 16
    syscall

    # loop
    j game_loop
