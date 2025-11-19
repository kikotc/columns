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
    sw $a0, curr_col_c0
    
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
    sw $a0, curr_col_c1
    
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
    sw $a0, curr_col_c2
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
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
        jal  board_set
        
        # set second pixel
        move $a0, $t6
        addi $a1, $t7, 1
        move $a2, $t4
        jal  board_set
        
        # set third pixel
        move $a0, $t6
        addi $a1, $t7, 2
        move $a2, $t5
        jal  board_set
        
        jal  init_col
    col_landed:
        lw $ra, 0($sp) # pop $ra from the stack
        addi $sp, $sp, 4 # move the stack pointer to the top stack element
        jr $ra
        

## get the color and store in v0
#
# a0 = x coodinate relative to board
# a1 = y coodinate relative to board
# 
# overwrites: t0, t1
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
    
## draws the board
#
# overwrites: 
draw_board:
    addi $sp, $sp, -4 # move the stack pointer to an empty location
    sw $ra, 0($sp) # push $ra onto the stack
    li $t1, 0 # y = 0
    board_down_loop:
        bge $t1, 14, board_done # finish loop if current y >= 14
        li $t0, 0
        board_row_loop:
            bge $t0, 6, board_row_done # finish loop if current x >= 6
            
            # get the color
            move $a0, $t0
            move $a1, $t1
            
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t1, 0($sp) # push $t1 onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t0, 0($sp) # push $t0 onto the stack
            
            jal board_get
            
            lw $t0, 0($sp) # pop $t0 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $t1, 0($sp) # pop $t1 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t0, 0($sp) # push $t0 onto the stack
            move $t0, $v0
            
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t1, 0($sp) # push $t1 onto the stack
            addi $sp, $sp, -4 # move the stack pointer to an empty location
            sw $t2, 0($sp) # push $t2 onto the stack
            
            jal  draw_board_pixel
            
            lw $t2, 0($sp) # pop $t2 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            lw $t1, 0($sp) # pop $t1 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            
            lw $t0, 0($sp) # pop $t0 from the stack
            addi $sp, $sp, 4 # move the stack pointer to the top stack element
            
            addi $t0, $t0, 1 # add 1 to the current x
            j board_row_loop
        board_row_done:
            addi $t1, $t1, 1 # add 1 to the current y
            j board_down_loop
    board_done:
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
    
    jal draw_board
    jal draw_curr_col
    
    lw $ra, 0($sp) # pop $ra from the stack
    addi $sp, $sp, 4 # move the stack pointer to the top stack element
    jr $ra
    
game_over:
    li $v0, 10
    syscall

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
