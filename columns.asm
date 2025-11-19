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

# keys
.eqv KEY_A 0x61
.eqv KEY_D 0x64
.eqv KEY_S 0x73
.eqv KEY_W 0x77
.eqv KEY_Q 0x71

# board
board: .word 0:84

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main

j main

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

## initialize the column by setting position and randomizing colors
#
# overwrites: v0, a0, a1, t1
init_col:
    li $t1, 3
    sw $t1, curr_col_x
    li $t1, 0
    sw $t1, curr_col_y
    
    # randomize color 1
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 1
    la $t1, colors_list
    sll $a0, $a0, 2
    addu $t1, $t1, $a0
    lw $a0, 0($t1)
    
    # set color 1
    sw $a0, curr_col_c0
    
    # randomize color 2
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 2
    la $t1, colors_list
    sll $a0, $a0, 2
    addu $t1, $t1, $a0
    lw $a0, 0($t1)
    
    # set color 2
    sw $a0, curr_col_c1
    
    # randomize color 3
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall 
    
    # get color 3
    la $t1, colors_list
    sll $a0, $a0, 2
    addu $t1, $t1, $a0
    lw $a0, 0($t1)
    
    # set color 3
    sw $a0, curr_col_c2
    
    jr $ra

## handles input and calls corresponding functions for each key
#
# overwrites: t0, t1, t2
handle_input:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    lw $t0, ADDR_KBRD
    lw $t1, 0($t0) # t1 = is key pressed
    bne $t1, 1, input_done # if key not pressed, finish function
    
    lw $t2, 4($t0) # load second word from keyboard
    
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

move_col_l:
    lw $t3, curr_col_x # load current coluumn x
    ble $t3, $zero, move_l_done # if current x <= 0, don't do anything
    addi $t3, $t3, -1 # decrement current x
    sw $t3, curr_col_x # store
    move_l_done:
        jr $ra

move_col_r:
    lw $t3, curr_col_x # load current coluumn x
    bge $t3, 5, move_r_done # if current x >= 5, don't do anything
    addi $t3, $t3, 1 # increment current x
    sw $t3, curr_col_x # store
    move_r_done:
        jr $ra

move_col_d:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    jal init_col
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra

draw_screen:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    
    # draw board
    li $t0, BLACK
    li $a0, 1
    li $a1, 1
    li $a2, 6
    li $a3, 14
    jal draw_rectangle
    
    jal draw_curr_col
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra
    
main:
    # set background to brown
    li $t0, BROWN
    li $a0, 0
    li $a1, 0
    li $a2, 16
    li $a3, 16
    jal draw_rectangle

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    jal handle_input
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
    jal draw_screen
    
    
	# 4. Sleep
	li $v0, 32
    li $a0, 16
    syscall

    # 5. Go back to Step 1
    j game_loop
