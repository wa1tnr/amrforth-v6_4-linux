BASIC
' example.bas  An example application for amrBASIC.
' LCD and Keypad for an RS232 terminal.
' R/W is tied high, we always write, never read the LCD.

Symbol En = 2		' Enable pin, 1 = enabled.
Symbol RS = 3		' Register Select pin, 0 = instruction.
Symbol keys = b0	' Number of key pressed.
' Symbol buttons = b1	' Last read of pins.
Symbol nibble = b2	' Partial character.
Symbol char = b3	' Character sent to LCD.

Symbol Sw_0 = pin4	' User input switches.
Symbol Sw_1 = pin5	' Multiplexed with LCD data lines.
Symbol Sw_2 = pin6
Symbol Sw_3 = pin7

' Set up the i/o's and initialize the LCD.
begin:	let pins = %00000011 		' Clear all but rs232 pins.
	let dirs = dirs | %11111100	' 6 output pins.
	pause 200			' Wait 200 ms for LCD to reset.

' Initialize the LCD for a 4 bit interface.
	let pins = %00110000
	pulseout En 10
	pause 100
	pulseout En 10
	pause 100
	pulseout En 10
	pause 100
	let pins = %00100000	' 4 bits.
	pulseout En 10
	pause 100
	let char = $28		' 40 chars, 2 lines, 5x7 font.
	gosub wr_LCD
	pause 100
	let char = $0e		' Underline cursor.
	gosub wr_LCD
	pause 10
	let char = $01		' Clear display.
	gosub wr_LCD
	pause 100
	let char = $02		' Set output mode.
	gosub wr_LCD
	pause 10
	high RS

' Main program loop:  receive data, check for backspace, and display
' data on LCD.
main:	serin char
	goto bksp
out:	gosub wr_LCD
	goto main

' Write the ASCII character in b3 (char) to LCD.
wr_LCD:	let pins = pins & %00001011
	let nibble = char & %11110000	' High nibble
	let pins = pins | nibble	' Or contents of nibble onto pins.
	PULSEOUT En 10			' Blip enable pin.
	let nibble = char * 16		' Low nibble	
	let pins = pins & %00001011	' Clear 4 bit data bus.
	let pins = pins | nibble	' Or contents of nibble onto pins.
	PULSEOUT En 10			' Blip enable pin.
	return

' Backspace, rub out character by printing a blank.
bksp:	if char > 31 then out	' Output if not a control character.
	if char = 3 then clear	' Ctrl-C clears LCD screen.
	if char = 13 then cret	' Carriage return, wait for button.
	if char <> 8 then main	' Reject other control characters.
	gosub back		' Move cursor back once.
	let char = 32		' Send a blank to the display.
	gosub wr_LCD
	gosub back		' Move cursor back once more.
	goto main		' Get ready for another transmission.

back:	low RS			' Change to instruction register.
	let char = $10		' Move cursor left.
	gosub wr_LCD		' Write instruction to LCD.
	high RS			' Back to character mode.
	return

clear:	low RS			' Change to instruction register.
	let char = 1		' Clear the display.
	gosub wr_LCD		' Write instruction to LCD.
	high RS			' Back to character mode.
	pause 100		' Wait for display.
	goto main

cret:
	let dirs = %00001100	' Change LCD data lines to inputs.
	let pins = pins | %11111000	' ????
'	let dirs = %00000000	' No outputs.
'	let pins = %11110000
loop:	let keys = $30		' ascii zero.
	if Sw_0 = 1 then xmit
	let keys = keys + 1
	if Sw_1 = 1 then xmit
	let keys = keys + 1
	if Sw_2 = 1 then xmit
	let keys = keys + 1
	if Sw_3 = 1 then xmit
	goto loop

xmit:	serout keys 13 10
	pause 10
	let pins = pins & %00001011
	let dirs = %11111100
	goto main

RUN begin

END

