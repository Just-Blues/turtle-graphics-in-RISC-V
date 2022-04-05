# turtle-graphics-in-RISC-V

Program reads 600x50 pixels .bmp file and using parameters given in .bin file, creates a new .bmp file, using turtle graphics logic

- input.bin - contains parameters neccessary to draw a small square
- output.bmp - contains output of program operation with input.bin parameters
- original.bmp - is just an empty 50x600 .bmp file            
------------------------
              
             
             
Below are instructions that will allow for correct .bin file creation.

In order for the program to work properly, input .bin file has to follow the following format:

1. Set position command (2 word), first two bits must be 1 and 0           
The set position command sets the new coordinates of the turtle. It consists of two words. The
first word defines the command (bits 15-14) and Y (bits y5-y0, bits no. 13 - 8) coordinate of the new
position. The second word contains the X (bits x9-x0, bits no. 15 - 6) coordinate. The point (0,0) is located in
the bottom left corner of the image.

2. Set direction command (1 word), first two bits must be 1 and 1        
The set direction command sets the direction in which the turtle will move, when a move
command is issued. The direction is defined by the bits no 11 and 10. 
Each of 4 combinations of bits no. 11 and 10 set's direction:
- 00 - up
- 01 - left
- 10 - down
- 11 - right

3. Move command (1 word), first two bits must be 0 and 0       
The move command moves the turtle in direction specified by the previous command. The movement
distance is defined by the bits no 13. - 6. . If the destination point is located beyond the drawing
area the turtle should stop at the edge of the drawing. It can’t leave the drawing area. 
The turtle leaves a visible trail when the pen is lowered. The color of the trail is defined by the next command. 

4. The pen state command (1 word), first two bits must be 0 and 1           
Defines whether the pen is raised or lowered (bit no. 12) and the color of
the trail. Bits no. 10 - 8 select one of the predefined colors from the color table:
- 000 - black
- 001 - purple
- 010 - cyan 
- 011 - yellow
- 100 - blue
- 101 - green
- 110 - red
- 111 - white



