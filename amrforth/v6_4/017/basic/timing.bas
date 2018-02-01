BASIC
' timing.bas  An example application using a very accurate free running
' timer.

entry:	timing 2000	' Start timer and set to 2000 ms.
	let w0 = 0	' Initialize seconds counter.
Main:	if timer <= 1000 then tick	' One second has passed.
	' Do something that takes less than 1 second, if you like.
	goto Main

tick:	add-timer 1000	' Add one second to the timer.
	let w0 = w0 + 1		' Add one to the seconds count.
	print w0		' Show the second count.
	goto Main

RUN entry

END
