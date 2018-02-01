0 [if]   iic552.fs   Driver for Inter Integrated Circuit devices.
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

0 [if]
\ The 80C552 has an onboard IIC interface.  We will use only the
\ master portion of the interface, since we don't plan on using
\ the 552 as an IIC slave device.

Registers:
S1CON control byte.
S1DAT data byte.
S1STA status byte.
S1ADR ignored by this application.
[then]

\ FALSE for the developer's system,
\ TRUE for the 552 kit board, which has inverters.
true constant INVERTED

\ In amrFORTH v6.3 the top of data stack is cached,
\ low byte in A, high byte in R2.

$81 constant speed   \ 100 Khz w/ 12Mhz crystal

\ Generic IIC interface words.

\ 'iic-ok will signal an incomplete iic operation.
\ For example see _wait-for-iic and XP0@.  The success flag is available
\ to the programmer, but there is no automatic error handling here.  If
\ you ignore the error flag the program uses bogus data and doesn't lock up.

cvariable 'iic-err
a: _iic-ok   0 # 'iic-err direct mov   ;a
code iic-ok   (  - )   _iic-ok   next c;
: iic-ok?   (  - flag)   'iic-err c@ 0= ;

a: _wait-for-iic
    $ff # R7 mov
    begin
        3 .S1CON set? if   1 # R7 mov   then
    R7 -zero until
    3 .S1CON clr? if   $ff # 'iic-err direct mov   then ;a

\ Wait-for-iic is waiting for the IIC interrupt bit to be set
\ by the IIC hardware.  We found that in some cases, the bit is
\ never set, so this becomes an infinite loop.  The remedy was
\ to include a timeout, setting a flag to false if the timeout
\ occurs, signaling higher level routines to retry the operation
\ or handle the error in some other way.

code iicSTART   (  - )
\ Takes about 12 uS at either speed.
\ Set data and clock pins high to allow IIC operation.
    $c0 # P1 orl
\ Tickle the START bit in S1CON, the IIC control register.
    $60 speed + # S1CON mov
\ Wait for interrupt flag, signalling completion of last
\ operation.
    _wait-for-iic
    ret c;

code slave-adr<  ( a - )
\ Takes about 106 uS at 100 KHz speed, 68 uS and 200 KHz speed.
\ Set the read bit in the slave address.
    1 # A orl
\ Send slave address
    A S1DAT mov  $40 speed + # s1con mov
\ Wait for interrupt flag to signal completion of the
\ send operation.
    |drop  _wait-for-iic
    ret c;

code slave-adr>  ( a - )
\ Send slave address byte
    A S1DAT mov  $40 speed + # S1CON mov
\ Wait for interrupt flag to signal completion of the
\ send operation.
    |drop  _wait-for-iic
    ret c;

code byte>iic  ( c - )
\ Move byte from B register into IIC serial data register.
    A S1DAT mov
\ Tell IIC hardware to send the byte by resetting the
\ interrupt flag.
    $40 speed + # S1CON mov
\ Wait for interrupt flag to indicate that the byte was sent.
    |drop  _wait-for-iic
    ret c;

code byte<iic  (  - c)
\ Takes about 100 uS at 100 KHz speed, 63 uS at 200 KHz speed.
\ Reset the interrupt flag to allow the slave to send a byte.
    $40 speed + # S1CON mov
\ Wait for interrupt flag to indicate that byte was sent.
    _wait-for-iic
\ Read byte from IIC data register and copy onto the stack.
    |dup  A clr  A R2 mov  S1DAT A mov
    ret c;

code iicSTOP  (  - ) \ Stop condition
\ Takes about 12 uS at either speed.
\ Tickle the STOP bit in the IIC control register.
    $50 speed + # S1CON mov
    next c;

code iicABORT?  ( error_code - flag)
\ Carry must be cleared before subtracting.
    S1STA A xrl  0= if  A clr  A R2 mov  ret  then
    S1STA 'iic-err direct mov  A clr  A dec  A R2 mov
    next c;

INVERTED [if]
    code invert-byte  ( c1 - c2) A cpl  next c;
    i: ?invert-byte  ( c1 - c2) [t'] invert-byte token, ;i
    i: ?not  ( n1 - n2) [t'] 0= token, ;i
[else]  \ Not inverted
    i: ?invert-byte  ( c - c)  ;i
    i: ?not  ( n1 - n2)  ;i
[then]

: iic@  ( a - c)
    iic-ok
    iicSTART    $08 iicABORT? if  iicSTOP exit  then
    slave-adr< $40 iicABORT? if  0 iicSTOP exit  then
    byte<iic    $58 iicABORT? drop
    iicSTOP
    ?invert-byte ;

: iic!  ( c a - )
    iic-ok
    iicSTART   $08 iicABORT? if  2drop iicSTOP exit  then
    slave-adr> $18 iicABORT? if  drop iicSTOP exit  then
    ?invert-byte
    byte>iic   $28 iicABORT? drop
    iicSTOP ;

: iic$!  ( b0 .. bn+1 n a - )
\ Some devices, such as LCD displays, like to get strings
\ of command characters.  This word sends the write command once,
\ then sends a string of bytes.
    iic-ok
    iicSTART $08 iicABORT? if
        drop for  drop  next iicSTOP exit
    then
    slave-adr> $18 iicABORT? if
        for  drop  next  iicSTOP exit
    then
    for
        ?invert-byte
        byte>iic $28 iicABORT? if
            pop for  drop  next  iicSTOP exit
        then
    next
    iicSTOP ;
 
\ IIC Port expander.
\ for the PCF8574P

2 constant #retries

: xp@   ( a - b)
    dup iic@ iic-ok? if  nip exit  then
    drop #retries
    begin
        push dup iic@ iic-ok? if  nip r>drop exit  then
        drop pop 1-
    0= until  nip ;

: xp!   ( b a - )
    2dup iic! iic-ok? if  2drop exit  then
    #retries
    begin
        push 2dup iic!
        iic-ok? if  pop drop 2drop exit  then
        pop 1- dup 
    0= until  drop ;

$40 CONSTANT XP0   \ Keypad
: xp0@  (  - b) xp0 xp@ ;
: xp0!  ( b - ) xp0 xp! ;

$42 CONSTANT XP1   \ LCD Display
: xp1@  (  - b) xp1 xp@ ;
: xp1!  ( b - ) xp1 xp! ;

0 [if]   \ Not used in this application.

$44 CONSTANT XP2
: xp2@  (  - b) xp2 xp@ ;
: xp2!  ( b - ) xp2 xp! ;

$46 CONSTANT XP3
: xp3@  (  - b) xp3 xp@ ;
: xp3!  ( b - ) xp3 xp! ;

$48 CONSTANT XP4
: xp4@  (  - b) xp4 xp@ ;
: xp4!  ( b - ) xp4 xp! ;

$4A CONSTANT XP5
: xp5@  (  - b) xp5 xp@ ;
: xp5!  ( b - ) xp5 xp! ;

$4C CONSTANT XP6
: xp6@  (  - b) xp6 xp@ ;
: xp6!  ( b - ) xp6 xp! ;

$4E CONSTANT XP7
: xp7@  (  - b) xp7 xp@ ;
: xp7!  ( b - ) xp7 xp! ;

$70 CONSTANT XP8
: xp8@  (  - b) xp8 xp@ ;
: xp8!  ( b - ) xp8 xp! ;

$72 CONSTANT XP9
: xp9@  (  - b) xp9 xp@ ;
: xp9!  ( b - ) xp9 xp! ;

$74 CONSTANT XP10
: xp10@  (  - b) xp10 xp@ ;
: xp10!  ( b - ) xp10 xp! ;

$76 CONSTANT XP11
: xp11@  (  - b) xp11 xp@ ;
: xp11!  ( b - ) xp11 xp! ;

[then]

