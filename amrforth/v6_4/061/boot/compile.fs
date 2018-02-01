0 [if]   compile.fs    Load file for amrForth for Linux, 8051 family.
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

\ ALL20030814   ROM used also in hex.

[then]

only forth also definitions

( *) constant romming
true constant extending

: has  (  - flag)  BL word find nip 0<> ; immediate

: warn  warnings on ;
: nowarn  warnings off ;

\ Not needed, current working directory is already in path.
\ fpath+ ~+/   \ Gforth for current working directory.
\ fpath+ ~/amrforth/v6/

\ Search current working directory, then amrforth/v6 home directory.
s" /amrforth/v6/compile.fs" file-status nip [if]
	fpath= .|~/amrforth/v6/
[else]
	fpath= .|/amrforth/v6/
[then]

include vtags.fs
include ~+/amrfconf.fs	\ ~+/ means current working directory to Gforth.
include metacomp.fs
include asm8051.fs
sfr-file included
include kernel8051.fs
include debug.fs
include ~+/job.fs
include end8051.fs
in-forth

include bin2hex.fs

: in-full-pages  ( n1 - n2)
	512 /mod swap if  1 +  then  512 * ;

\ The 552 starts at $8000 when developing, 0 when romming.
0
has 80c552 has 80c537 or has 80c31 or has 80c32 or
romming not and [if] $8000 + [then] constant rom-offset
: save-object-code  (  - )
	s" rom.bin" w/o create-file throw >r
	rom-offset there romHERE rom-offset -
	in-full-pages r@ write-file throw
	r> close-file throw
	save-rom.hex ;

' save-object-code catch [if]
	.( Problem saving object code.) cr
[then]

\ Disable target compiler, only compile once.
warnings off
in-forth  : _c ." disabled " ; : c _c ; : r _c ; in-meta
warnings on

cr .( Host Stack = ) .s
cr .( ROM used = ) romHERE dup u. hex.  \ ALL20030814i
iram.log close-file drop
s" immed.log" immed make-vocabulary.log
close-log-files
in-meta

\ QUIT here strands Gforth and Tclpip83 in Windows.  Must execute BYE.
\ quit  \ Avoid the Gforth prompt.

