#-------------------------------------------------------------------------------
#author: Abel Niwiñski
#data : 2021.01.11
#description : Binary Turtle 3.20 
#-------------------------------------------------------------------------------
#https://github.com/TheThirdOne/rars/wiki
#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90122 #size
.eqv BYTES_PER_ROW 1800 #because 600*50*3
.eqv BTYTES_BETWEEN_PIXELS 3
.eqv PARAMETERS_SIZE 60

	.data
#space for the 600x50px 24-bits bmp image
.align 4 
res:	.space 2
image:	.space BMP_FILE_SIZE

parameters: .space PARAMETERS_SIZE

inname:		.asciz "input.bin"

outname:	.asciz "output.bmp"
mod_image:	.asciz "original.bmp"
err_msg_1:	.asciz "\nInput file not opened"
err_msg_2:	.asciz "\nOriginal file not opened"
err_msg_3:	.asciz "\nOutput file not created"
stop:		.asciz "\nProgram End" #Control 
	.text
main:
	jal	read_in
	jal 	read_og_image
	
	la s2, parameters
	li s3, 0 #counter, safety precaution to stop the program 
	li s4, PARAMETERS_SIZE
	lbu s5, (s2)
	
	#Default Parameters in case of unforseen parameter order
	li a0, 5 # x = 5
	li a7, 5 # y = 5
	li a2, 0x00FFFFFF #colour - white
	li a5, 0 # direction - up
	li a6, 1 # pen state - off
	
program_loop:
	beq s3, s4, exit #offset counter and safety
	li t0, 64
	blt s5,t0, call_move
	li t0, 128
	blt s5,t0, call_pen_state
	li t0, 192
	blt s5,t0, call_set_position
	li t0, 256
	blt s5,t0, call_set_direction

exit:	
	jal save_out
	li a7, 4	
        la a0, stop		
        ecall
	li a7,10		#Terminate the program
	ecall

#Program logic is handled here
#I tried to program return addresses manually to make it faster
#but I failed and decided that this approach is safer and more flexible
call_move:
	mv a3, s2
	jal move
	addi s3, s3, 2		
	addi s2, s2, 2
	lbu s5, (s2)
	j program_loop 
	#j exit # for testing
call_pen_state:
	mv a3, s2
	jal pen_state
	addi s3, s3, 2
	addi s2, s2, 2
	lbu s5, (s2)
	j program_loop
	#j exit # for testing
call_set_position:
	mv a3, s2
	jal set_position
	addi s3, s3, 4
	addi s2, s2, 4
	lbu s5, (s2)
	j program_loop
	#j exit # for testing
call_set_direction:
	mv a3, s2
	jal set_direction
	addi s3, s3, 2
	addi s2, s2, 2
	lbu s5, (s2)
	j program_loop
	#j exit # for testing

# ============================================================================
set_position:
#description: 
#	sets position of turtle
#arguments:
#	a3 - address of parameters
#return value:
#	a7 - y coordinate
#	a0 - x coordinate

	lbu t6, (a3)
	addi a7, t6, -128 #y coordinate
	#edge is 49
	li t5, 50 
	blt a7, t5, set_x
	li a7, 49
set_x:	  
	#if lhu, little endian is used which is undesirable 
	lbu t6, 2(a3)
	slli t6, t6, 2
	lbu t5, 3(a3)
	srai t5, t5, 6
	add a0, t6, t5 
	#edge is 599
	li t5, 600 
	ble a0, t5, end_set
	li a0, 599 
end_set:
	li t0, -1	#control
	
	jr ra
# ============================================================================
set_direction:
#description: 
#	sets direction of turtle
#arguments:
#	a3 - address of parameters
#return value:
#	a5 - direction  (3 - right, 2 - down, 1 - left, 0 - up)
 
	lbu a5, (a3)
	srai a5, a5, 2
	addi a5, a5, -48
	li t5, 4
	blt a5, t5, contiune
	li t5, 4
	addi a5, a5, -4
	blt a5, t5, contiune
	li t5, 4
	addi a5, a5, -4
	blt a5, t5, contiune	
	
contiune:
	li a4, 0	       
	beq a5, a4, end_direction

	li a4, 1       
	beq a5, a4, end_direction

	li a4, 2
	beq a5, a4, end_direction

	li a4, 3
	beq a5, a4, end_direction
	
end_direction:	
	li t0, -2	#control
	
	jr ra
# ============================================================================
move:
#description: 
#	moves in some direction from some postion
#arguments:
#	a3 - address of parameters
#	a7 - y coordinate
#	a0 - x corrdinate
#	a6 - pen state (1 on, 0 off)
#	a2 - colour
#	a5 - direction (3 - right, 2 - down, 1 - left, 0 - up)
#return value:
#	a0 - x coordinate
#	a7 - y coordinate
	
	# Read distance				
	lbu t5, (a3)
	slli t5, t5, 4
	lbu t6, 1(a3)
	srai t6, t6, 4	
	add a4, t5, t6 # a4 - distance 
	
	la t1, image		#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2		#adress of pixel[0,0] array in $t2
				# +3 to pixel [1,0] (which is the first x away from 0)
				# +1800 to pixel [0,1] (which is the first y away from 0)			
	mv t6, t2 # Store address of pixel array
	mv t0, a2 # Store colour
	
	#Sets direction
	li t4, 0
	beq a5, t4, up
	addi t4, t4, 1
	beq a5, t4, left
	addi t4, t4, 1
	beq a5, t4, down
	addi t4, t4, 1
	beq a5, t4, right	

up:
	add t3, a7, a4 #t3 = y + distance, t3 is new position
	li t4, 50
	ble t3, t4, con1
	sub t4, t3, t4
	sub a4, a4, t4 #a4 - distance to new position
	li t3, 49 #set new position as edge
con1:	
	li t4, 1
	mv t5, a0
	beq a6, t4, no_draw
	
	li t4, BYTES_PER_ROW
	li t3, BTYTES_BETWEEN_PIXELS
	mul t3, t3, a0
	add t6, t6, t3
movement_up:	

	beqz a4, done	
	
	mv t2, t6
	mv a2, t0			
	
	mul t5, a7, t4
	add t2, t2, t5
	
	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R
	
	addi a7, a7, 1
	addi a4, a4, -1
	j movement_up	
	
left:
	sub t5, a0, a4 #t5 = x - distance, t5 is new position
	li t4, 0
	bge t5, t4, con2
	add t4, t5, t4
	add a4, a4, t4 #a4 - distance to new position
	li t5, 0 #set new position as edge
	addi a4, a4, 1
con2:	
	li t4, 1
	mv t3, a7
	beq a6, t4, no_draw
	
	li t4, BYTES_PER_ROW
	li t3, BTYTES_BETWEEN_PIXELS
	mul t4, t4, a7
	add t6, t6, t4	
movement_left:	

	beqz a4, done	
			
	mv t2, t6
	mv a2, t0
	
	mul t5, a0, t3
	add t2, t2, t5			

	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R
	
	addi a0, a0, -1						
	addi a4, a4, -1
	j movement_left	
down:
	sub t3, a7, a4 #t3 = y - distance, t3 is new position
	li t4, 1
	bge t3, t4, con3
	add t4, t3, t4
	add a4, a4, t4 #a4 - distance to new position
	li t3, 0 #set new position as edge
con3:	
	li t4, 1
	mv t5, a0
	beq a6, t4, no_draw	
	
	li t4, BYTES_PER_ROW	
	li t3, BTYTES_BETWEEN_PIXELS
	mul t3, t3, a0
	add t6, t6, t3
movement_down:	
	
	beqz a4, done	
	
	mv t2, t6
	mv a2, t0			
	
	mul t5, a7, t4
	add t2, t2, t5
	
	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R
	
	addi a7, a7, -1
	addi a4, a4, -1
	j movement_down
	
right:
	add t5, a0, a4 #t5 = x + distance, t5 is new position
	li t4, 600
	ble t5, t4, con4
	sub t4, t5, t4
	sub a4, a4, t4 #a4 - distance to new position
	li t5, 599 #set new position as edge
con4:	
	li t4, 1
	mv t3, a7
	beq a6, t4, no_draw
		
	li t4, BYTES_PER_ROW
	li t3, BTYTES_BETWEEN_PIXELS
	mul t4, t4, a7
	add t6, t6, t4	
movement_right:	

	beqz a4, done	
	
	mv t2, t6
	mv a2, t0	

	mul t5, a0, t3
	add t2, t2, t5			

	#set new color
	sb a2,(t2)		#store B
	srli a2,a2,8
	sb a2,1(t2)		#store G
	srli a2,a2,8
	sb a2,2(t2)		#store R
	
	addi a0, a0, 1						
	addi a4, a4, -1
	j movement_right
	
no_draw:
#change position to new position
	mv a0, t5
	mv a7, t3
	
done:	

	li t0, -3	#control
	
	jr ra
# ============================================================================
pen_state: 
#description: 
#	sets state of pen and colour
#arguments:
#	a3 - address of parameters
#return value:
#	a2 - 3 bytes of colour
#	a6 - state of pen  

	lbu a4, (a3)
	addi a4, a4, -64
	andi a6, a4, 16 
	srai a6, a6, 4 # sets state of pen
	
	bnez a6, finish
	
	li t5, 8
	blt a4, t5, colours
	rem a4, a4, t5
	
colours:
	li t5, 0
	li a2, 0x00000000 #Black
	beqz a4, finish
	li a2, 0x00FF00FF #Purple
	addi t5, t5, 1
	beq a4, t5, finish
	li a2, 0x0000FFFF #Cyan
	addi t5, t5, 1
	beq a4, t5, finish	
	li a2, 0x00FFFF00 #Yellow
	addi t5, t5, 1
	beq a4, t5, finish
	li a2, 0x000000FF #Blue 
	addi t5, t5, 1
	beq a4, t5, finish
	li a2, 0x0000FF00 #Green
	addi t5, t5, 1
	beq a4, t5, finish
	li a2, 0x00FF0000 #Red
	addi t5, t5, 1
	beq a4, t5, finish
	li a2, 0x00FFFFFF #White
	addi t5, t5, 1
	beq a4, t5, finish
			
	
finish:	
	li t0, -4	#control
	jr ra
# ============================================================================





# Three functions below are handling file I/O
# ============================================================================
read_in:
#description: 
#	reads the contents of a input.bin file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, inname		#file name 
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
	bgez s1, read
	li a7, 4		
        la a0, err_msg_1		
        ecall
#if not opened then close file and return        
        li a7, 57
	mv a0, s1
        ecall
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra
        
#read file if file is opened
read:
	li a7, 63
	mv a0, s1
	la a1, parameters
	li a2, PARAMETERS_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra

# ============================================================================
read_og_image:
#description: 
#	reads the contents of a original.bmp file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, mod_image		#file name 
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
	bgez s1, open
	li a7, 4		
        la a0, err_msg_2		
        ecall
#if not opened then close file and return        
        li a7, 57
	mv a0, s1
        ecall
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra
#read file
open:
	li a7, 63
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra
# ============================================================================
save_out:
#description: 
#	saves modified original.bmp file stored in memory to a output.bmp file
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push s1
	sw s1, (sp)
#open file
	li a7, 1024
        la a0, outname		#file name 
        li a1, 1		#flags: 1-write file
        ecall
	mv s1, a0      		# save the file descriptor
	
#check for errors - if the file was opened
	bgez s1, save
	li a7, 4		
        la a0, err_msg_3		
        ecall
#if not opened then close file and return        
        li a7, 57
	mv a0, s1
        ecall
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	jr ra

#save file
save:
	li a7, 64
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, (sp)		#restore (pop) $s1
	addi sp, sp, 4
	jr ra


# ============================================================================
