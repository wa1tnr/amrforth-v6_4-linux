\ debug.fs
0 [if]
Copyright (C) 1991-2004 by AM Research, Inc.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

For LGPL information:   http://www.gnu.org/copyleft/lesser.txt
For application information:   http://www.amresearch.com

[then]
in-compiler

: cr  (  - ) 13 emit  10 emit ;
s" count" kernel-entry  \ For single stepper.
: count  ( a1 - a2 c) dup 1+ swap c@ ;
: type  ( a n - ) for  count emit  next  drop ;
i: ."  (  - ) [t'] (string) token,  34 string [t'] type token, ;i

\ emit ignores R2, uses only A.
code (.hex)  ( c1 - c2)
    $0f # A anl  $90 # A add  A da
    $40 # A addc  A da  ( 0 # R2 mov)  next c;
: .hex  ( digit - ) (.hex) emit ;
: (hb.)  ( c - ) dup 2/ 2/ 2/ 2/ .hex .hex ;
: h.  ( n - ) dup flip (hb.) -;
: hb.  ( c - ) (hb.) -;
: space  (  - ) $20 emit ;
\ : spaces  ( n - ) begin  space 1-dup0=until  drop ;

: dot  ( u - )
    -1 swap begin  10 /mod dup0=until  drop
    begin  .hex dup0<until  drop ;
: .  ( n - ) dup0<if  abs [char] - emit  then -;
: u.  ( u - ) dot space ;

: .nibble  ( n1 - n2)
	4 for  dup $8000 and 0= not 1 and $30 + emit  2*  next ;
: (bb.)  ( n - ) .nibble [char] : emit .nibble ;
: bb.  ( c - ) flip (bb.) drop space ;
: b.  ( n - ) (bb.) [char] : emit (bb.) drop space ;

\ Count uses c@ which reads from internal RAM if the address is 8 bits,
\ and from program memory if the address is $100 or greater.
: dump  ( addr len - )
    over [asm $0f #and ] if
        cr over h. over [asm $0f #and ] dup 2* +
        begin  space 1-dup0=until  drop
    then
    for
        dup [asm $0f #and ] 0= if  cr dup h.  then  count hb.
    next  drop ;

: countd  ( a - a+1 c) dup 1 + swap c@d ;

: dumpd  ( addr len - )
    over [asm $0f #and ] if
        cr over h. over [asm $0f #and ] dup 2* +
        begin  space 1-dup0=until  drop
    then
    for
        dup [asm $0f #and ] 0= if  cr dup h.  then
        countd hb.
    next  drop ;

has 8031 [if]
: .s?  ( addr - )
	push [char] < emit depth dot [char] > emit space
	depth dup0=if  r>drop drop exit  then  \ Stack empty.
    0< if  r>drop exit  then  \ Stack underflow.
    depth 1 > if  \ Show numbers on data stack in RAM.
        [ SP0 4 - ] literal depth 1- 1- for
            dup @ flip pop r@ swap push execute 1- 1-
        next  drop
    then
    dup pop execute  \ Show top of stack, in R2:A register pair.
    ;
[else]
: .s?  ( addr - )
	push [char] < emit depth dot [char] > emit space
	depth dup0=if  r>drop drop exit  then  \ Stack empty.
    0< if  r>drop exit  then  \ Stack underflow.
    depth 1 > if  \ Show numbers on data stack in RAM.
        [ $100 4 - ] literal depth 1- 1- for
            dup @ flip pop r@ swap push execute 1- 1-
        next  drop
    then
    dup pop execute  \ Show top of stack, in R2:A register pair.
    ;
[then]

: .s   (  - ) [']  . .s? ;
s" dots" kernel-entry  \ For single stepper.
: .sh  (  - ) ['] h. .s? ;
: .su  (  - ) ['] u. .s? ;

code clear  SP0 # SP mov  next c;

\ Mark stacks with character, watch the changes with dump.
code mark-stacks  ( n - )
	R2 A xch
	8 # R1 mov
	begin  A @R1 mov  R1 inc  RP0 1 + # R1 = until
	R2 A xch
	RP0 1 + # R1 mov
	begin  A @R1 mov  R1 inc  SP0 # R1 = until
	' abort jump c;

\s *****
\ Return Stack Dump.
code rdepth  (  - n)
	' dup call
	RP A mov  C clr  RP0 # A subb  A rrc
	0 # R2 mov
	next c;
: .rs  (  - )
	." RS: " [ RP0 1 + ] literal rdepth 1- for
		dup @ flip h. 2 +
	next  drop ;
