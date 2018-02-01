\ ledsf300.fs
in-meta decimal

code init-leds  (  - )
    $ce # P0MDOUT mov  \ 5 pins are push pull outputs.
	next c;

\ Useful for debugging, not in the application.
code P0@  (  - c) |dup  P0 A mov  0 # R2 mov  next c;
code P0!  ( c - ) A P0 mov  |drop  next c;

\ P0.4 and P0.5 are used by the UART.
\ P0.0 is used by the ADC.

\ code +P0.0  (  - ) 0 .P0 setb  next c;
code +P0.1  (  - ) 1 .P0 setb  next c;
code +P0.2  (  - ) 2 .P0 setb  next c;
code +P0.3  (  - ) 3 .P0 setb  next c;
code +P0.6  (  - ) 6 .P0 setb  next c;
code +P0.7  (  - ) 7 .P0 setb  next c;

\ code -P0.0  (  - ) 0 .P0 clr  next c;
code -P0.1  (  - ) 1 .P0 clr  next c;
code -P0.2  (  - ) 2 .P0 clr  next c;
code -P0.3  (  - ) 3 .P0 clr  next c;
code -P0.6  (  - ) 6 .P0 clr  next c;
code -P0.7  (  - ) 7 .P0 clr  next c;

