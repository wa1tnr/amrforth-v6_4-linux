\ adc.fs
\ An example application using the 10 bit A/D on the 017.

: ?dup  ( n - n n | 0)  dup if  dup  then ;

: um/round   ( ud u1 - u2)
        ?dup if
                >r r@ um/mod   swap 2*   r> < not   1 and +  exit 
        then  drop ;

code d+  ( d1 d2 - d3)
        Apop   A R7 mov   Apop   A R6 mov
        Apop   A R5 mov   Apop   A R4 mov
        SP inc   SP inc   SP inc   SP inc
        @SP->A   r4 A add    A->@SP   SP dec
        @SP->A   r5 A addc   A->@SP   SP dec
        @SP->A   r6 A addc   A->@SP   SP dec
        @SP->A   r7 A addc   A->@SP   SP dec
        next c;

code init-adc  (  - )
	0 # AMX0CF mov
	0 # AMX0SL mov
	$80 # ADC0CF mov
	$c0 # ADC0CN mov
	$03 # REF0CN mov
	next c;

code adc@  (  - n)
	4 .ADC0CN setb
	begin  4 .ADC0CN clr? until
	ADC0L A mov  Apush
	ADC0H A mov  Apush
	next c;

: adc12@  (  - n)
	0 15 for  adc@ +  next  2/ 2/ ;

: adc14@  (  - n)
	8 0 255 for  adc@ 0 d+  next  16 um/mod nip ;

: adc14x@  (  - n)
	0 0 255 for  adc@ 0 d+  next  16 um/round ;

code a/d14@  (  - n)
	A clr  A R5 mov  A R6 mov  A R7 mov
\	0 # A mov  A R4 mov  \ Start with 0.5, for rounding later.
	8 # A mov  A R4 mov  \ Start with 0.5, for rounding later.
	begin	4 .ADC0CN setb  begin  4 .ADC0CN clr? until
		ADC0L A mov  R4 A add  A R4 mov
		ADC0H A mov  R5 A addc  A R5 mov
		A clr  R6 A addc  A R6 mov
	R7 -zero until
	4 # R7 mov
	begin	C clr
		R6 A mov  A rrc  A R6 mov
		R5 A mov  A rrc  A R5 mov
		R4 A mov  A rrc  A R4 mov
	R7 -zero until
	R4 A mov  Apush
	R5 A mov  Apush
	next c;

code a/d14x@  (  - n)
	A clr  A R5 mov  A R6 mov  A R7 mov
\	0 # A mov  A R4 mov  \ Start with 0.5, for rounding later.
	8 # A mov  A R4 mov  \ Start with 0.5, for rounding later.
	begin	4 .ADC0CN setb  begin  4 .ADC0CN clr? until
		ADC0L A mov  R4 A add  A R4 mov
		ADC0H A mov  R5 A addc  A R5 mov
		A clr  R6 A addc  A R6 mov
		64 # R3 mov  begin  R3 -zero until  \ kill some time.
	R7 -zero until
	4 # R7 mov
	begin	C clr
		R6 A mov  A rrc  A R6 mov
		R5 A mov  A rrc  A R5 mov
		R4 A mov  A rrc  A R4 mov
	R7 -zero until
	R4 A mov  Apush
	R5 A mov  Apush
	next c;

: adc16@  (  - n)
	0 0 4095 for  adc@ 0 d+  next  64 um/round ;

: test10  (  - ) 1000 for 10000 for  adc@ drop  next next ;
: test12  (  - ) 10000 for  adc12@ drop  next ;
: test14  (  - ) 1000 for  adc14@ drop  next ;
: test14code     1000 for  a/d14@ drop  next ;
: test16  (  - ) 100 for  adc16@ drop  next ;

