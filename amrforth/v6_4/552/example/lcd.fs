0 [if]   lcd.fs   Driver for the amr lcd.
Copyright (C) 2001-2004 by AM Research, Inc.

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

in-compiler decimal

\ ----- LCD interface.

0 [if]
LCD display.
   Uses bits 1-7 of IIC Serial Port 1, XP1, for the 552.
   Uses XP1@ and XP1!, but remember they are serial transfers.
   4 bits of data on bits 4-7.
        E Clock or strobe on bit 3.
        R/W Read /write on bit 2.
        RS Data /instruction on bit 1.
   For a 4 line display there is an additional clock on bit 0, for
   the bottom two lines.  Thus E1 = xp1.3 and E2 = xp1.0.
[then]

: lcd@  (  - C) xp1@ ;
: lcd!  ( C - ) xp1! ;

: lcd$!  ( C1 .. Cn n - ) iic-ok xp1 iic$! ;

00 constant L1
64 constant L2

: lcd-clk-hi  (  - ) lcd@ $08 or lcd! ;
: lcd-clk-lo  (  - ) lcd@ $f7 and lcd! ;

: lcd-strobe  (  - ) lcd-clk-hi lcd-clk-lo ;

: >busy  (  - n)
    lcd@ $f4 or lcd!   lcd-clk-hi lcd@ lcd-clk-lo ;

\ Not sure why ?not is required here.
: -busy@  (  - flag)
    >busy >busy drop $80 and ?not 0= ;

: lcd-wait  (  - ) noop ;

: lcd-answers?  (  - ?)
    $1000 begin  1- dup 0= -busy@ or until  0= not ;

\ Takes 5 bytes to clock in 2 nibbles.
code prep-lcd-inst   ( b0 - b1 b2 b3 b4 b5)
    ACC push  $f0 # A anl        
    A R7 mov  A R5 mov  08 # A orl  A R6 mov
    ACC pop  A rlc  A rlc  A rlc  A rlc  $f0 # A anl
    A R4 mov  08 # 'R4 orl  0 # R2 mov
    |dup  R4 A mov  |dup  R5 A mov  |dup  R6 A mov  |dup  R7 A mov
    next c;

\ Takes 5 bytes to clock in 2 nibbles.
code prep-lcd-emit   ( b0 - b1 b2 b3 b4 b5)
    ACC push   $f0 # A anl   02 # A orl
    A R7 mov   A R5 mov   $0a # A orl   A R6 mov
    ACC pop   A rlc   A rlc   A rlc   A rlc   $f0 # A anl
    A R4 mov   $0a # 'R4 orl   02 # A orl  0 # R2 mov
    |dup  R4 A mov  |dup  R5 A mov  |dup  R6 A mov  |dup  R7 A mov
    next c;

: (lcd-instruction)  ( c - ) $f0 and dup dup 8 or swap 3 lcd$! ;

: lcd-instruction  ( c - )  prep-lcd-inst 5 lcd$! lcd-wait ;

: lcd-emit  ( c - ) prep-lcd-emit 5 lcd$! ;

: lcd-digit  ( digit - )
    $0f and dup 9 > if  7 +  then  $30 + lcd-emit ;

: lcd-type  ( a l - ) ?dup if for  count lcd-emit  next then  drop ;

: lcd-space  (  - ) 32 lcd-emit ;
: lcd-spaces  ( n - ) ?dup if for  lcd-space  next then ;

0 constant invisible
1 constant blinking
2 constant underline

: cursor  ( c - ) $0c or lcd-instruction ;

: lcd-at  ( n - ) $80 or lcd-instruction ;

: (dark)  (  - )  $01 LCD-INSTRUCTION LCD-ANSWERS? DROP ;

: left  (  - ) $18 lcd-instruction ;

: do-loops   ( n - ) for next ;

: (init-lcd)  (  - )
    $20 $30 $30 $30
    4 for  (lcd-instruction) ( 100) 200 do-loops  next ;

: ?init-lcd  (  - flag)
    (init-lcd) $28 prep-lcd-inst 5 lcd$!
    lcd-answers?  dup if  invisible cursor (dark)  then ;

: lcd-dark  (  - ) ?init-lcd drop ;


\s *****
: (LCD.")  (  - )  R> COUNT 2DUP +   >R LCD-TYPE ;

I: LCD."   (  - )
    [T'] (LCD.") TOKEN,   34 WORD   DUP C@ 1+ S,-T ;I

