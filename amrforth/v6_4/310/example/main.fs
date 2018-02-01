\ main.fs

code init
	$40 invert # PCA0MD anl  \ Clear watchdog enable bit.
\ ----- initialization code goes here, before MAIN.
\	$14 # P0MDOUT orl  \ P0.2 and P0.4 are outputs, push pull.
\	$15 # P0MDOUT orl  \ P0.2 and P0.4 are outputs, push pull, P0.0 too.
    $ff # P0MDOUT orl  \ 
    $ff # P1MDOUT orl   \ 
    $ff # P2MDOUT orl    \ 
    $ff # P3MDOUT orl     \ all push,pull outputs.
	$ff # P0MDIN orl  \ No analog, all digital.
	$01 # XBR0 mov  \ Enable TX and RX on P0.4, P0.5.
\	$09 # XBR0 mov  \ Enable TX and RX on P0.4, P0.5, also sysclk on P0.0
	$40 # XBR1 mov  \ Enable crossbar and weak pull-ups.
\ Setup serial port.
	$c3 # OSCICN mov  \ Full speed internal, 24.5 MHz.
	$00 # CKCON mov  \ T1 uses SYSCLK/12.
	$12 # SCON0 mov  \ 8 bit UART mode, TX ready.
	$20 # TMOD mov  \ Mode 2, 8 bit auto-reload.
	$96 # TH1 mov  \ 9600 baud, at 24.5MHz.
	6 .TCON setb  \ Enable Timer 1.
	next c;

\ code wink  (  - ) 2 .P0 cpl  next c;

\ : blink  (  - ) wink blink ;

code zeroes  (  - )
    0 # P0 mov  0 # P1 mov  0 # P2 mov  0 # P3 mov
    next c;

code P0++  (  - ) P0 inc  next c;
code P1++  (  - ) P1 inc  next c;
code P2++  (  - ) P2 inc  next c;
code P3++  (  - ) P3 inc  next c;

: blink  (  - )
    zeroes
    begin
        P0++  P1++  P2++  P3++  10 for next
    again -;

code p00+  0 .P0 setb  next c;
code p15+  5 .P1 setb  next c;
code p17+  7 .P1 setb  next c;

code p00-  0 .P0 clr  next c;
code p15-  5 .P1 clr  next c;
code p17-  7 .P1 clr  next c;

: go  (  - ) init 65 emit blink ;

