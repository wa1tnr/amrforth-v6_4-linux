0 [if]   adc552.fs   The 552 onboard 8 or 10 bit analog to digital converter.
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
defined 80C552 NOT [if]
        CR .( adc552.fs is meant for an 80C552 only. ) abort
[THEN]

CODE ADC8@      ( channel - value)
        0 # ADCON MOV                   \ clear interrupt flag
        BEGIN   ADCON A MOV   3 .ACC CLR? UNTIL
        SP INC   APOP                   \ pop channel
        8 # A ORL   A ADCON MOV         \ start conversion
        BEGIN   ADCON A MOV   4 .ACC SET? UNTIL
        ADCH A MOV   APUSH   0PUSH
        NEXT C;

0 [if]   \ High level version.
: ADC8@   ( channel - value)
        0 ADCON!   ( clear interrupt flag )
        BEGIN   ADCON@ $08 AND NOT UNTIL
        $08 OR ADCON!
        BEGIN   ADCON@ $10 AND UNTIL   ADCH@ ;
[then]

CODE ADC10@   ( channel - value)
        0 # ADCON MOV                           \ Clear interrupt flag
        BEGIN   ADCON A MOV   3 .ACC CLR? UNTIL \ Wait for ADC not busy
        SP INC   APOP   7 # A ANL               \ Pop, mask off channel bits
        3 .ACC SETB   A ADCON MOV               \ ADCON.3 starts conversion
        BEGIN   ADCON A MOV   4 .ACC SET? UNTIL \ Wait for conversion
        ADCON B MOV   ADCH A MOV                \ Read ADC data
        7 .B C MOV   A RLC   C 1 .B MOV         \ Rotate bits into position
        6 .B C MOV   A RLC   C 0 .B MOV   3 # B ANL
        APUSH   B A MOV   APUSH
        NEXT C;

0 [if]   \ High level version.
: ADC10@   ( channel - value)
        ADC8@ 2* 2*   ADCON@ 2* 2* FLIP 3 AND OR ;
[then]


