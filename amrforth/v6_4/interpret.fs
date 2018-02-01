\ interpret.fs
\ This is a command line for forth and GNU/Linux only, not windows.

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


include serial_ports.fs open-comm
warnings off
include ansi.fs

only forth also root definitions
vocabulary symbols

only forth also symbols definitions also forth
include ~+/symbols.log  \ Read the symbol table.
only forth also definitions

: handle-key  ( c - )
    dup  1 = if  key  emit-s exit  then
    dup  2 = if  key? emit-s exit  then
    dup  7 = if  r> 2drop    exit  then  \ Ok.
    dup 13 = if  drop        exit  then  \ Linux EOL.
    emit ;

: listen  (  - )
    Red >f attr!
    begin  key-s handle-key  again ;

\ Host sends byte commands to target.
: sputter   ( n - )   dup emit-s 8 rshift emit-s ;
: >put       ( n - )   clear-sbuf 1 emit-s sputter listen Black >f attr! ;
: >execute   ( a - )   clear-sbuf 2 emit-s sputter listen Black >f attr! ;

\ This is a search order trick to help search a single vocabulary,
\ without also looking in forth or root.
: exclusively   ( a - cfa -1 | a 0)
    dup count context @ search-wordlist
    dup if   rot drop   then ;

\ Is counted string a symbol?
: symbol?  ( a - cfa ? | a 0)
        also symbols exclusively previous ;

\ Is counted, BL delimited string a literal?
: literal?  ( a - n flag)
	['] number catch if  false dup exit  then
	drop true ;

: bye?  ( a - a flag)
	dup count s" bye" compare 0= ;

: interpret-word  ( a - )
	bye? if  cr bye  then
	symbol? if  execute >execute exit  then
	literal? if  >put exit  then
	." ?" abort ;

: please  (  - )
	begin	bl word dup c@ while
		interpret-word
	repeat drop ;

: interpret  (  - )
	pad 128 blank  s" please " pad place
	pad count + 80 accept >r  pad count r> +
	utime ( **) 2>r
	evaluate ." Ok   "
	utime 2r> ( **) d-
	<# # # # # # # [char] . hold #s #> 3 - type
	[char] s emit ;

: go  (  - )
	begin  ['] interpret catch drop cr again ;

