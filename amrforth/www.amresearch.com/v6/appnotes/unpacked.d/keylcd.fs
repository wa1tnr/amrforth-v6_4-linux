\ - keylcd.fs:  Driving a serial port, an LCD, and 4 buttons.
in-meta

m: asm  in-assembler ;m

\ ----- Assembler macros ----- /

a: .E
\ - Give bit 2 of port 0 the name .E, for Enable.
	2 .P0 ;a

a: .RS
\ - Give bit 3 of port 0 the name .RS, for Register Select.
	3 .P0 ;a

a: pins
\ - Name port 0 pins, as in BASIC.
	P0 ;a

a: dirs
\ - Name the port 0 config register dirs, for direction.
	PRT0CF ;a

\ ----- Initializing the LCD ----- /

code instruction   (  - )
\ - Switch LCD to instruction mode by clearing its RS bit.
	.RS clr   next c;

code data  (  - )
\ - Switch LCD to data mode by setting its RS bit.
	.RS setb  next c;

\ Value of c can't exceed 255, since it is used as a byte variable.
\ This is approximate for a 24 MHz crystal.  Checked on the scope.
code us  ( c - )
    SP inc  Apop
    begin
        6 # R7 mov
        begin  R7 -zero until
        nop
    ACC -zero until
    next c;

: ms  ( n - )
    for
        250 us 250 us 250 us 250 us
    next ;

\ Use an oscilloscope to check the timing on P0.2.
: scope-us  (  - )
    begin
        [ asm  .E setb ] 100 us
        [ asm  .E clr  ] 400 us
    again -;

: scope-ms  (  - )
    begin
        [ asm  .E setb ] 2 ms
        [ asm  .E clr  ] 3 ms
    again -;

: pulseout-E-10  (  - )
    [ asm  .E cpl ] 100 us [ asm  .E cpl ] ;

: write-lcd  ( c - )
\ - Based on working BASIC code.
	[ in-assembler
	%00001011 # pins anl ]  \ instruction
	dup
	[ in-assembler
	SP inc  Apop
	%11110000 # A anl
	A pins orl ]
	pulseout-E-10
	16 *
	[ in-assembler
	SP inc  Apop
	%00001011 # pins anl
	A pins orl ]
	pulseout-E-10
	;

code no-pullups  (  - )
\ - Disable weak pullups.
	$80 # XBR2 orl
	next c;

: init-lcd  (  - )
\ - Also based on working BASIC code.
	[ in-assembler
	%00000011 # pins mov
	%11111100 # dirs orl ]
	200 ms
	[ in-assembler
	%00110000 # pins mov ]
	pulseout-E-10 100 ms
	pulseout-E-10 100 ms
	pulseout-E-10 100 ms
	[ in-assembler
	%00100000 # pins mov ]
	pulseout-E-10 100 ms
	$28 write-lcd 100 ms
	$0e write-lcd 10 ms
	$01 write-lcd 100 ms
	$02 write-lcd 10 ms
	data
	;

\ ----- Reading the Keypad ----- /

code pins@  (  - n)
\ - Read the pins register, actually port 0.
	pins A mov
	Apush  A clr  Apush
	next c;

: button  (  - n)
\ - Read the pins register until a button has been pressed.
\ - Return the button's ascii value.
	begin	pins@
		dup %00010000 and if  drop $30 exit  then
		dup %00100000 and if  drop $31 exit  then
		dup %01000000 and if  drop $32 exit  then
		dup %10000000 and if  drop $33 exit  then
		drop
	again -;

code reading  (  - )
\ - Configure the data pins for input.
	%00001100 # dirs mov
	%11111000 # pins orl
	next c;

code writing  (  - )
\ - Configure the data pins for output.
	%00001011 # pins mov
	%11111100 # dirs orl
	next c;

: read-button  (  - )
\ - Wait for a button press, then send result over serial link.	
	reading button emit cr 10 ms writing ; 

: clear-lcd  (  - )
\ - Erase all characters from the LCD.	
	instruction 1 write-lcd data 100 ms ;

: back  (  - )
\ - Move the LCD cursor back one space.
	instruction $10 write-lcd data ;

: backspace  (  - )
\ - Erase the character to left of cursor and move cursor back one.	
	back 32 write-lcd back ;

: handler  ( c - )
\ - Given the latest button press, 
	dup 31 > if  write-lcd        exit  then
	dup  3 = if  drop clear-lcd   exit  then  \ control-c
	dup 13 = if  drop read-button exit  then  \ cr
	dup  8 = if  drop backspace   exit  then  \ control-h, bs
	drop ;

: init  (  - )
\ - First disable weak pullups, then initialize the LCD.
	no-pullups init-lcd ;

: go  (  - )
\ - The main loop of the example program.
	init begin  key handler again -;

