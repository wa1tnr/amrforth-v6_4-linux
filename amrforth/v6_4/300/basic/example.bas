\ Example basic program.
in-compiler create starter
BASIC
start:
	let b0 = 1  ' This is a comment.
	let b1 = 2  REM This is also a comment.
	let b2 = 3  rem This is a comment.
	let b3 = 4
	goto start  ' Comment after goto
	print b0  ' Comment after print
	if b0 = 5 then start  ' Comment after if
endofprog:
' RUN program
END

