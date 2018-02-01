0 [if]   mw-ee.fs   Driver for the 93cX6 family of serial eeprom chips.
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

\ New code for the 93C56 Eeprom.    18SEP92alm
false value large?

0 [if]

large? = false
        The following parts take a 6 bit address:
        94C06 =  256 bits = 16 words
        94C46 = 1024 bits = 64 words

large? = true
        The following parts take an 8 bit address:
        94C56 = 2048 bits = 128 words
        94C66 = 4096 bits = 256 words

[then]

code eeCS-HI  (  - ) 5 .P4 setb  next c;
code eeCS-LO  (  - ) 5 .P4 clr   next c;

: TX-OPCODE  ( n n - )  1 ( start bit) 3 for  mwbitOUT  next ;

large? [if]
    : (tx-address)  ( a - ) 8 for  2*  next  8 mwbitsOUT ;
    : tx-address  ( a - ) $ff and (tx-address) ;
    : wen>address  (  - ) $c0 (tx-address) ;
[else]
    : (tx-address)  ( a - ) 10 for   2*   next   6 mwbitsOUT ;
    : tx-address  ( a - ) $3f and (tx-address) ;
    : wen>address  (  - ) $30 (tx-address) ;
[then]

m: 2constant  ( n1 n2 - )
    create  , ,
    does>  (  - n1 n2) dup 2+ @ swap @ ;

0 1 2constant @read-opcode
0 0 2constant @write-enable-opcode
0 0 2constant @write-disable-opcode
1 0 2constant @write-opcode

: !read-command  ( a - ) @read-opcode tx-opcode tx-address ;

: rx-word  (  - n) 16 mwbitsIN ;

: ee@  ( a - n)
    eeCS-HI
    !read-command MW>input rx-word
    eeCS-LO ;

: write-enable-command  (  - )
    eeCS-HI
    @write-enable-opcode tx-opcode wen>address
    eeCS-LO ;

: write-command  ( n a -)
    eeCS-HI
    @write-opcode tx-opcode tx-address 16 mwbitsOUT
    eeCS-LO ;

: write-disable-command  (  - )
    eeCS-HI
    @write-disable-opcode tx-opcode $00 (tx-address)
    eeCS-LO ;

: ee!  ( n a - )
    write-enable-command write-command write-disable-command
    mw>INPUT ;  \ Float lines.

: ee2!  ( n1 n2 a - ) swap over ee!  1+ ee! ;
: ee2@  ( a - n1 n2) dup 1+ ee@  swap ee@ ;
: ee+!  ( n a - ) swap over ee@ +  swap ee! ;

\ Avoids needless writes to eeprom.
: ?ee!  ( n a - ) over over ee@ = not if  ee! exit  then  2drop ;

