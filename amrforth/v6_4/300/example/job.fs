\ job.fs
\ include adc300.fs
\ include ledsf300.fs
\ include main.fs

\ Improved code for u<, no conditionals.
code .u<.  ( u1 u2 - flag)
	C clr  @SP A xch  @SP A subb  R2 A mov  SP inc
	@SP A xch  @SP A subb  SP inc
	ACC A subb  A R2 mov
	next c;

code .<.  ( n1 n2 - flag)
	C clr  @SP A xch  @SP A subb  R2 A mov  SP inc
	$80 # A xrl  @SP A xch  $80 # A xrl
	@SP A subb  SP inc
	ACC A subb  A R2 mov
	next c;

\ Test this.
code u<=  ( u1 u2 - flag)
	C clr  @SP A subb  R2 A mov  SP inc
	@SP A subb  C cpl  SP inc
	ACC A subb  A R2 mov
	next c;

code .u>.  ( u1 u2 - flag)
	C clr  @SP A subb  R2 A mov  SP inc
	@SP A subb  SP inc
	ACC A subb  A R2 mov
	next c;
