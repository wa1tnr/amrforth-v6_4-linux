\ bootf061.fs   Based on:
\ SMALL.FS   Assembling a small program for the TINY members of the family.

\ Host downloader repeatedly sends $a5 to the target system until it
\ gets a $5a in response. Then host sends "amr". The target responds
\ with $a5. The host sends a byte containing the number of 512 byte
\ pages to be sent. The target erases those pages and responds with $5a.
\ Then the host sends pages beginning with page 1, at address $200 or
\ 512. The target responds after each page is received with a byte
\ containing the loop counter, i.e. number of pages remaining, including
\ the one just received. In other words it counts down from the total
\ number of pages to 1.

\ Flash program memory can't be written unless PSCTL.0 is set. This bit
\ is clear during normal operation. It is only set in the bootloader
\ immediately before DPTR is loaded with $200. Even if a rogue program
\ jumps into the middle of the bootloader it can't overwrite the
\ bootloader because DPTR is loaded with $200 in the bootloader right
\ after PSCTL.0 is set. The only way the bootloader might be ruined is
\ by having PSCTL.0 set in the user's code and then accidentally jumping
\ into the bootloader at the point where DPTR was just loaded with $200.
\ Not very likely.

\ The bootloader sets up the crossbar such that:
\	TX= P0.0
\	RX= P0.1

in-meta decimal

in-forth   \ Signal compiler to leave out FORTH system.
        create tiny-program
0 [if]
The phrase:     HAS tiny-program [IF]  \S  [THEN]
must be added to the beginning of the file END8051.FS for this to work.
The idea is to avoid loading END8051.FS when we want a TINY program;
[then]

in-meta
\ ----- Use only LABELS, RET rather than CODE, NEXT,
\ -----    since FORTH won't exist on the Target.
\ ----- If the target part is a 750, 751, or 752,
\ -----    unsupported instructions are LJMP, LCALL, MOVX.

\ Vector the interrupts into page 2.
	0 there $b3 erase  \ Clear interrupt vectors.

label INTERRUPT-VECTORS
	$03 org  $203 ljmp
	$0b org  $20b ljmp
	$13 org  $213 ljmp
	$1b org  $21b ljmp
	$23 org  $223 ljmp
	$2b org  $22b ljmp
	$33 org  $233 ljmp
	$3b org  $23b ljmp
	$43 org  $243 ljmp
	$4b org  $24b ljmp
	$53 org  $253 ljmp
	$5b org  $25b ljmp
	$63 org  $263 ljmp
	$6b org  $26b ljmp
	$73 org  $273 ljmp
	$7b org  $27b ljmp
	$83 org  $283 ljmp
	$8b org  $28b ljmp
	$93 org  $293 ljmp
	$9b org  $29b ljmp
	$a3 org  $2a3 ljmp
	$ab org  $2ab ljmp

	$b3 org  \ Code starts here, after interrupts.

\ ------------------------------------------------------

\ Entry point of the main program if not bootloading.
$200 constant main

label 'EMIT
	begin  1 .SCON0 set? until  1 .SCON0 clr  A SBUF0 mov  ret
label 'KEY
	begin  0 .SCON0 set? until  0 .SCON0 clr  SBUF0 A mov	ret
label 'KEY-OR-TIMEOUT
	$f1 # TMOD anl  $01 # TMOD orl  \ 16 bit timer 0.
	0 # TH0 mov  0 # TL0 mov  \ Timeout period.
	5 .TCON clr  4 .TCON setb  \ Start Timer0.
	begin
		0 .SCON0 set? if
			0 .SCON0 clr  SBUF0 A mov  ret
		then
		5 .TCON set? if  \ Timer0 overflow.
			4 .TCON clr  \ Stop Timer0.
			main jump  \ Run normal program.
		then
	again

label ENTRY
	$de # WDTCN mov  $ad # WDTCN mov  \ Disable Watchdog.
\ ----- initialization code goes here, before MAIN.
    $0f # SFRPAGE mov
	$04 # XBR0 mov  \ Enable UART only.
	$40 # XBR2 mov  \ Enable crossbar and weak pull-ups.
    $c3 # OSCICN mov  \ Internal 24.5MHz oscillator.
\ Setup serial port.
    0 # SFRPAGE mov  \ This holds for rest of program.
    $10 # CKCON mov  \ T1 uses SYSCLK, no prescaler.
	$52 # SCON0 mov
	$20 # TMOD mov
    97 # TH1 mov  \ 9600 baud, 24.5 MHz
    $10 # SSTA0 mov  \ SMOD0=1
	6 .TCON setb
\ Only bootload if the password is received in time.
	'KEY-OR-TIMEOUT call
	$a5 # A xrl  0<> if  64 # A mov  main jump  then
	$5a # A mov  'EMIT call  \ Signal host we're ready.
	'KEY-OR-TIMEOUT call
	char a # A xrl  0<> if  64 # A mov  main jump  then
	'KEY-OR-TIMEOUT call
	char m # A xrl  0<> if  64 # A mov  main jump  then
	'KEY-OR-TIMEOUT call
	char r # A xrl  0<> if  85 # A mov  main jump  then
\ Setup the download.
	$a5 # A mov  'EMIT call  \ Signal readiness to host.
	'KEY call  \ Get number of pages.
	0= if  main jump  then  \ Don't download 0 pages.
	63 # A = if else -C if  62 # A mov  then then  \ Clip.
	A R7 mov  \ Save number of pages in A.
\ Erase pages.
	$89 # FLSCL mov  \ For <25.6 MHz crystal.
	3 # PSCTL mov    \ Enable Writing and Erasing.
	$200 # DPTR mov  \ First page to erase.
	begin
		A @DPTR movx  DPH inc  DPH inc
	R7 -zero until
	A R7 mov  \ Restore page counter.
	$5a # A mov  'EMIT call  \ Signal readiness to host.
\ Accept bytes and write them into flash. Always start at address $200,
\   The program downloaded must have its entry point at $200!
	1 # PSCTL mov  \ Disable erasing, but leave writing enabled.
	$200 # DPTR mov  \ Start at page 1, address 512.
	begin
		0 # R6 mov
		begin
			'KEY call  A @DPTR movx  DPTR inc
			'KEY call  A @DPTR movx  DPTR inc
		R6 -zero until
		R7 A mov  'EMIT call
	R7 -zero until
	0 # PSCTL mov  \ Disable further writing to flash.
	'KEY call  \ Wait for signal to start running program.
	main jump c;

romming [if]
    HERE ( *)        \ Remember dictionary pointer
    0 ORG            \ Reset vector at address 0
label COLD
    ENTRY ljmp c;    \ Reset jumps to ENTRY point
    ( *) ORG         \ Restore dictionary pointer
[else]
    CODE GO   (  - ) \ To run the program under development
        ENTRY JUMP C;
[then]

