0 [if]   mw.fs   Driver for MicroWire devices.
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
\ Converted from version 5 to version 6.3, 1/9/04.

in-compiler decimal

A: mwCLK    6 .P4   ;A
A: mwDOUT   7 .P4   ;A   \ data in/out tied together.
A: mwDIN    7 .P4   ;A

\ ----- MicroWire interface.

code mwCLK-HI  (  - ) mwCLK setb  next c;
code mwCLK-LO  (  - ) mwCLK clr   next c;
code mwSTROBE  (  - ) mwCLK setb  mwCLK clr  next c;

code mw>INPUT  (  - ) mwDIN setb  next C;

code mwDATA-HI  (  - ) mwDOUT setb  next c;
code mwDATA-LO  (  - ) mwDOUT clr   next c;
code mwDATA?  (  - 0|1)
    |dup  A clr  A R2 mov  mwDIN C mov  C 0 .ACC mov  next c;

: mwbitOUT  ( flag - )
    if  mwDATA-HI  else  mwDATA-LO  then  mwSTROBE ;

: mwbitsOUT  ( data #bits - )
    for  dup 0< mwbitOUT 2*  next  drop ;

: mwbitIN  (  - 0|1) mw>INPUT mwCLK-HI mwDATA? mwCLK-LO ;

: mwbitsIN  ( n1 - n2) 0 swap for  2* mwbitIN or  next ;

: mwbitIN/OUT ( flag - 0|1)
    if  mwDATA-HI  else  mwDATA-LO  then
    mw>INPUT mwCLK-HI mwDATA? mwCLK-LO ;

: mwbitsIN/OUT  ( n1 n2 - n3)
    for  swap dup 0< mwbitIN/OUT >r 2* swap 2* r> or  next
    nip ;
