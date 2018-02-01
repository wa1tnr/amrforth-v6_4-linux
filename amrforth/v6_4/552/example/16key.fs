0 [if]   16key.fs   Driver for AM Research 16 button keypad.
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

\ Requires iic552.fs

: keypad!  ( c - ) xp0! ;
: keypad@  (  - c) xp0@ ;

\ Leave the column bits clear, set the row bits.
$f0 constant column-key
\ Return with the column bit set.
: column  (  - c) column-key keypad! keypad@ column-key xor ;

\ Leave the row bits clear, set the column bits.
$0f constant row-key
\ Return with the row bit set.
: row  (  - c) row-key keypad! keypad@ row-key xor ;

\ Return with both the row and column bits set.
: raw-button  (  - c)
    0 begin  drop row dup until  column +
    begin  row not until ;

hex
create key-table   10 c, ( number of possible buttons )
88 c, char 1 c,   84 c, char 2 c,   82 c, char 3 c,   81 c, char C c,
48 c, char 4 c,   44 c, char 5 c,   42 c, char 6 c,   41 c, char D c,
28 c, char 7 c,   24 c, char 8 c,   22 c, char 9 c,   21 c, char E c,
18 c, char A c,   14 c, char 0 c,   12 c, char B c,   11 c, char F c,
decimal

: raw>ascii  ( c1 - c2)
    key-table count for
        2dup c@ = if  nip 1+ c@ r>drop exit  then  2+
    next  2drop 0 ;

: button  (  - c) raw-button raw>ascii ;

