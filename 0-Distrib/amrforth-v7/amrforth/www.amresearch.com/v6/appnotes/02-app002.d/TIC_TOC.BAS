' Program: TIC_TOC.BAS (Increment a counter in response to a
' precision 2-Hz external clock.

' The 2-Hz input is connected to pin0.  Bit0 is the lowest bit of b0,
' so each time b0 is incremented (in tick), bit0 gets toggled.  This
' ensures that tick gets executed only once per transition of pin0.

Main:
	if pin0 = bit0 then tick
 	' Other program activities--
	' up to 250 ms worth --
	' go here.
	goto Main

' Tick maintains a 16-bit counter to accumulate the number of seconds.
' The maximum time interval w1 can hold is 65535 seconds--a bit over
' 18 hours.  If you want a minute count instead, change the second
' line of tick to read: "if b0 < 240 then Main".  There are 1440 minutes
' in a day, so w1 can hold up to 65535/1440 = 45.5 days worth of to-the-
' minute timing information.

tick:
	let b0 = b0 + 1		' Increment b0 counter.
	if b0 < 4 then Main	' if b0 hasn't reached 4, back to Main.
	let b0 = 0		' Else clear b0,
	let w1 = w1 + 1		' increment the seconds count,
	debug cls,#w1," sec."	' and display the seconds.
	goto Main		' Do it again.
