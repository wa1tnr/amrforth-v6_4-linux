\ timing.fs
\ An example application using a very accurate free running timer.

include basic.fs  \ For the ms timer interrupt.
\ See \amrforth\v6\basic.fs for definitions of:
\ ms-counter	A variable.
\ atomic-@	Disables interrupts while fetching.
\ add-timer	Adds to the ms-counter while interrupts are disabled.
\ set-mstimer	Starts the millisecond timer.

in-meta  \ Forth metacompiler vocabulary.

\ Fetch the milliseconds counter with interrupts disabled.
: timer  (  - n) ms-counter atomic-@ ;

\ Increment the seconds counter and display it.
: tick  ( n1 - n2) 1000 add-timer  1 +  dup . ;

: main  (  - )
	2000 set-mstimer  \ Start the millisecond timer.
	0  \ Seconds count rides on the data stack.
	begin	timer 1001 < if  tick  then  \ One second has passed.
		\ Do something here that doesn't take too long,
		\ it may delay the execution of tick.  Since the timer
		\ is free running, the delay won't affect the overall
		\ accuracy of the timer, just the individual display.
	again ;

