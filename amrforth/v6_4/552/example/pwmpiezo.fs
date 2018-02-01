0 [if]   pwmpiezo.fs   Driver for the PWM output of an 80c552.
Copyright (C) 2001 by AM Research, Inc.

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

IN-META DECIMAL

defined 80C552 NOT [IF]
        CR .( PWMPIEZO.SEQ is meant only for the 80C552.) \S
[THEN]

0 [if]
Pulse width modulators on the 552, driving a piezo transducer.
PWMP sets the frequency.
PWM0! and PWM1! set the duty cycle, modulo 255.
A zero in PWM0 or PWM1 causes constant zero volts at the pin.
An FFh in PWM0 or PWM1 causes constant five volts at the pin.
[then]

\ PWM outputs, piezo transducer.
: TONE    ( n b - )   $80 PWM0!   PWMP!   0 DO LOOP   0 PWM0! ;
: BEEP    (  - )    $300 $25 TONE ;
: CLICK   (  - )    $200 $10 TONE ;
: BLIP    (  - )     $10 $18 TONE ;
: BLAT    (  - )   $3000 $FE TONE ;

: (alarm)   ( n1 n2 - )
    2 FOR   2DUP $45 UM* $60 UM/MOD NIP TONE   2DUP TONE
    NEXT    2DROP ;

: ALARM   (  - )   $1200 $50 (alarm) ;

: DOWNSCALE   (  - )   $21 $10 DO   $300 I TONE   LOOP ;

: UPSCALE   (  - )   $10 $21 DO   $300 I TONE   -1 +LOOP ;

: HIT   (  - )   ( $80 PWMP! ) PWM0@ 0= PWM0! ;

