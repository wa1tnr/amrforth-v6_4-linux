\ metacomp.fs
0 [if]   metacomp.fs   The amr8051 Forth metacompiler.
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

\ ALL20030706 hex nums also to iram.log

[then]

only forth also definitions

\ .( loading metacomp.fs ) cr

\ Gforth has a 'feature' which allows an expression like  'A  to return
\ the ascii code for A, 65.  Unfortunately the same feature also causes
\ 'anyword to return a number.  The characters $, %, &, and ' cause the
\ base to be temporarily changed to hex, binary, decimal, and 256 for
\ number conversion.  There is a table called bases that has the numbers
\ 16, 2, 10, 256 in order to implement this 'feature'.  The 256 is a
\ trick that allows 'A to return 65.  Having spent many hours debugging
\ broken code where a misspelled word like 'delax for 'delay returns
\ a number instead of aborting, I disable the ' part below by patching
\ the bases table.
0 bases 3 cells + !

\ Words we're used to from the DOS days and FPC.

: 2+   2 + ;

: flip   ( n1 - n2)  \ swap two lower bytes
        $FFFF and   dup $FF and 256 *
        swap $FF00 and 256 /   or ;

: not   ( n - flag)   0= ;

: exec:   ( n - )   cells r> + @ execute ;

\ Thanks to Wil Baden and Neil Bawd's ugly website.
: \s   (  - )   begin	-1 parse 2drop refill 0= until ;

\ This can be used to print a vocabulary to a file.
: make-vocabulary.log  ( addr len - )
    w/o create-file throw >r
    context @ wordlist-id 
    BEGIN
        @ dup  WHILE 
        dup name>string r@ write-file throw
        BL r@ emit-file throw
    REPEAT 
    r> close-file throw drop ;

\ All the vocabularies and ways to get at them.

root definitions

vocabulary meta		\ Defining words in transition from host to target.
vocabulary target	\ Words whose code resides on the target.
vocabulary asm		\ The target assembler.
vocabulary immed	\ Control structure words, similar to immediate words.

\ These need to be available even if forth is not in the search order.
: also   also ;
: definitions   definitions ;

only forth also definitions

: to-meta      (  - )   only forth also meta also definitions ;
: in-meta      (  - )   only forth also definitions meta also ;
: in-compiler  (  - )   in-meta ;

: in-forth     (  - )   only forth also definitions ;
: in-host      (  - )   in-forth ;
: in-assembler (  - )   only forth also meta also asm also definitions ;
: in-target (  - )   only forth also meta also target also definitions ;
: in-immed  (  - )   only forth also meta also immed also definitions ;

\ Add a word to the meta vocabulary.
: m:   (  - )   to-meta : ;
: ;m   (  - )   postpone ; in-meta ; immediate

\ Add a word to the forth vocabulary.
: f:   (  - )   in-meta : ;
' ;m alias ;f immediate

\ Add a word to the assembler vocabulary, an assembler macro.
: a:   (  - )   in-assembler : ;
' ;m alias ;a immediate

\ Add a word to the immed vocabulary, probably a compiler directive.
: i:   (  - )   in-immed use-tags : no-tags ;
' ;m alias ;i immediate

variable romDP

variable cpuDP   8 cpuDP !
has interrupts-kernel [if]
    $20 cpuDP !  \ Skip input buffer.
[then]

: write-crlf  ( fid - )
    >r 13 r@ emit-file throw 10 r> emit-file throw ;

: (.)  ( n - ) 0 <# #s #> ;

\ Assumes the fileid is for an open file.
: makelogger  ( variable fileid - )
    create  , ,
    does>
        dup @ >r  \ fid
        last @ name>string r@ write-file throw
        9 r@ emit-file throw
        \ cell+ @ @ 0 <# #s #> r@ write-file throw
        cell+ @ @ dup (.) r@ write-file throw
        ( -- aIRAM )    \ ALL20030706+
        base @ swap hex
        9 r@ emit-file throw
        0 <# # # [char] $ hold #> r@ write-file throw
        ( ai -- ) base !  \ ALL20030706-
        r@ write-crlf
        r> drop ;

create dash ," -"
create aspace ,"  "
create acolon ," :"
: (##)  ( n - ) 0 <# # # #> ;
: get-system-date  ( fid - )
    >r time&date (.) pad place dash count pad +place
    (.) pad +place dash count pad +place (.) pad +place
    aspace count pad +place (##) pad +place acolon count pad +place
    (##) pad +place acolon count pad +place (##) pad +place
    pad count r@ write-file throw  r> write-crlf ;

: createlog  ( addr len - )
    create
        w/o create-file throw dup >r ,
        r> get-system-date
    does>  (  - fid)
        @ ;

s" iram.log" createlog iram.log
cpuDP iram.log makelogger logIRAM

\ 8051 has three memory spaces, so do some other chips.
: romHERE   (  - a)   romDP @ ;
: cpuHERE   (  - a)   cpuDP @ ;

\ Building the symbol tables.
variable symbols-file  0 symbols-file !
variable hidden-symbols-file  0 hidden-symbols-file !
variable exits-file    0 exits-file !
variable stepper-source-file   0 stepper-source-file !
variable kernel-word-file   0 kernel-word-file !

: close-log-files  (  - )
    symbols-file @ close-file throw
    hidden-symbols-file @ close-file throw
    exits-file @ close-file throw
    stepper-source-file @ close-file throw
    kernel-word-file @ close-file throw ;

: symbols-id  (  - n)
	symbols-file @ ?dup if  exit  then
	s" symbols.log" w/o create-file throw
	dup symbols-file ! ;

: hidden-symbols-id  (  - n)
    hidden-symbols-file @ ?dup if  exit  then
    s" hiddensymbols.log" w/o create-file throw
    dup hidden-symbols-file ! ;

: exits-id  (  - n)
    exits-file @ ?dup if  exit  then
    s" exits.log" w/o create-file throw
    dup exits-file ! ;

: stepper-source-id  (  - n)
    stepper-source-file @ ?dup if  exit  then
    s" steppersource.log" w/o create-file throw
    dup stepper-source-file ! ;

: kernel-word-id  (  - n)
    kernel-word-file @ ?dup if  exit  then
    s" kernelwords.log" w/o create-file throw
    dup kernel-word-file ! ;

: symbols-entry  (  - )
	symbols-id >r
	[char] : r@ emit-file throw
	BL r@ emit-file throw
	last @ name>string r@ write-file throw
	( BL) 9 r@ emit-file throw
	base @ decimal
	romHERE 0 <# #s #> r@ write-file throw
	base !
	BL r@ emit-file throw
	[char] ; r@ emit-file throw
	newline r@ write-file throw
	r> flush-file throw ;

: hidden-symbols-entry  (  - )
    hidden-symbols-id >r
	[char] : r@ emit-file throw
	BL r@ emit-file throw
	last @ name>string r@ write-file throw
	( BL) 9 r@ emit-file throw
	base @ decimal
	romHERE 0 <# #s #> r@ write-file throw
	base !
	BL r@ emit-file throw
	[char] ; r@ emit-file throw
	newline r@ write-file throw
	r> flush-file throw ;

: exits-entry  ( addr - )
    exits-id >r
	[char] : r@ emit-file throw
	BL r@ emit-file throw
	base @ decimal swap
    0 <# #s #> r@ write-file throw
    base !
	( BL) 9 r@ emit-file throw
	last @ name>string r@ write-file throw
	BL r@ emit-file throw
	[char] ; r@ emit-file throw
	newline r@ write-file throw
	r> flush-file throw ;

0 value last-sourceline#
0 value last->in

: stepper-source-entry  (  - )
    stepper-source-id >r
	[char] : r@ emit-file throw
	BL r@ emit-file throw
	base @ decimal
    romHERE 0 <# #s #> r@ write-file throw
    base !
	( BL) 9 r@ emit-file throw
	sourceline# dup to last-sourceline# 0
    >in @ dup to last->in 0
    <# #s 2drop [char] . hold #s #>
    r@ write-file throw
    BL r@ emit-file throw
	[char] ; r@ emit-file throw
	newline r@ write-file throw
    r> flush-file throw ;

: stepper-source-last-entry  (  - )
    stepper-source-id >r
	[char] : r@ emit-file throw
	BL r@ emit-file throw
	base @ decimal
    romHERE 0 <# #s #> r@ write-file throw
    base !
	( BL) 9 r@ emit-file throw
	last-sourceline# 0 last->in 0
    <# #s 2drop [char] . hold #s #>
    r@ write-file throw
    BL r@ emit-file throw
	[char] ; r@ emit-file throw
	newline r@ write-file throw
    r> flush-file throw ;

\ This helps the single stepper get the address of a 
\ kernel word, even if the user has redefined the word.
: kernel-entry  ( addr len - )
    kernel-word-id >r
    s" set kernelword(" r@ write-file throw
    ( addr len) r@ write-file throw
    s" ) " r@ write-file throw
    romHERE 0 <# #s #> r@ write-file throw
    newline r@ write-file throw
    r> flush-file throw ;

\ --- Create a target image and ways to read and write it.

$10000 constant target-size

create target-image   target-size allot

\ Fill with all bits set, like an erased rom.
target-image target-size $ff fill

\ Gforth is 32 bits, target forth is 16 bits.
: w!   ( n a - )   2dup c!   >r 256 / r> 1+ c! ;
nowarn
: w@   ( a - n)   dup c@ swap 1+ c@ 256 * or ;
warn
: sw@   ( a - n)   w@ dup $8000 and if   $FFFF0000 or   then ;

target-image target-size erase

: org   ( n - )   romDP ! ;
: romALLOT   ( n - )   romDP +! ;

nowarn
128 value rp0   \ sort of a forward reference, resolved in begin.seq.
128 value sp0
warn

\ The 8051 family keeps bit variables right in the middle of the
\ byte variables.  Special care needs to be taken to allocate
\ byte variables around them.  Use   0 bit-variables   to declare
\ that you won't be using them and allow byte variables free reign.

create #bit-variables 1 c,

m: bit-variables   ( b  - )   #bit-variables c! ;m

f: overlapped?   ( a1 n1 a2 n2 - flag)
        over + >r >r   over +   r> > not
        swap r> < not   or not ;f

f: bit-collision?   ( n - flag)
        #bit-variables c@ 0= if   drop false exit   then
        cpudp @ swap $20 #bit-variables c@ overlapped? ;f

f: skip-bit-variables   (  - )
        $20 #bit-variables c@ + cpudp ! ;f

m: cpuhere    (  - a)   cpudp @ ;m

f: ?skip-bits   ( n - )
	bit-collision? if   skip-bit-variables   then ;f

m: cpuALLOT   ( n - )
	dup bit-collision?
	ABORT" Attempted to ALLOT into bit variables."
	cpuDP @ + 
	dup 128 < not ABORT" Variables out of range"
	DUP RP0 >
	ABORT" Variables and Return Stack have collided."
	cpuDP ! ;M

m: allot  ( n - )  cpuALLOT ;m

f: there  ( a1 - a2)  target-image + ;f

f: c@-t  ( a - c)  there c@ ;f
f: c!-t  ( c a - )  there c! ;f

f: @-t  ( a - n)  dup 1+ c@-t   swap c@-t   8 lshift or ;f
f: !-t  ( n a - )  >r dup 8 rshift r@ c!-t r> 1+ c!-t ;f
	
f: c,-t  ( c - )  romHERE c!-t   1 romALLOT ;f
f: ,-t  ( n - )  romHERE !-t   2 romALLOT ;f

\ Sometimes we need to store things in the host.
f: hostc,  ( c - )  c, ;f
f: host,   ( n - )  ,  ;f

\ By default now we store things in the target.
m: c,   ( c - )   c,-t ;m
m: ,   ( n - )   ,-t ;m

\ Generic assembly language words, the same for any processor family.

m: label   (  - )   romHERE constant in-assembler ;m
a: end-code   (  - )   in-meta ;a
a: c;   (  - )   in-meta ;a

\ Store a string in the target.
f: s,-t   ( a n - )   0 ?do   count c,-t   loop   drop ;m

nowarn
\ Optimization, suppress edge of word or control structure.
variable 'edge
: hide  (  - )  -1 'edge ! ; hide
: hint  (  - )  romHERE 'edge ! ;
: edge  (  - a)  'edge @ ;
warn

in-forth

\ A list of the names of target words, to allow the debugger to
\ get a name string from a target address, not otherwise available.
CREATE TARGET-NAMES   0 ,

: CFA-T   ( a - a' flag)
        TARGET-NAMES
        BEGIN   @ ?DUP WHILE
                2DUP CELL+ @ = IF
                        NIP 2 CELLS + @ TRUE EXIT
                THEN
        REPEAT  FALSE ;

nowarn
\ name>string is a Gforth specific word.	
: .id   ( a - )   name>string type space ;
warn

: .ID-T   ( a - )
        CFA-T IF
                .ID
        ELSE    DROP ." ?"
        THEN    ;

\ ***** FORGET is not yet implemented, either in Gforth or in amrForth. 
\ In order to implement FORGET you will have to prune this linked list
\ so as not to contain any names that have been forgotten.   *****
: REMEMBER-NAME   ( a-host a-target - )
        HERE TARGET-NAMES
        DUP @ , !   , , cpuHERE ,
        ;

: .target-names   (  - )
        base @ hex
        target-names
        begin   @ ?dup while
                cr
                dup 3 cells + @ >r
                dup cell+ @ u.
                dup 2 cells + @ dup u. r> u. .id
        repeat  base ! ;

in-meta

\ Create a header for a target word.
f: tcreate   (  - )
	use-tags
	in-target romHERE dup constant symbols-entry hide
	last @ swap remember-name
	in-meta no-tags ;f

\ Create a header, don't add it to the symbol table file.
f: -tcreate  (  - )
	use-tags
	in-target romHERE dup constant hidden-symbols-entry hide
	last @ swap remember-name
	in-meta no-tags ;f

f: precreate   (  - )   >in @ tcreate >in ! ;f

\ In order to be able to use target constants at compile time,
\ say for address calculations, we also define those constants
\ in the host.
f: mcreate   ( n - )  in-meta constant ;f

m: code   (  - )  tcreate in-assembler ;m
m: -code  (  - )  -tcreate in-assembler ;m

\ Sometimes we want the host version.
f: host-here   (  - a)   here ;f

\ Mostly we want the target version.
m: here   (  - a)   romHERE ;m

in-forth

: target-variable  ( n - )
	create  ,  does>  (  - a)  @ ;

in-meta

f: vcreate      ( n  - )   in-meta target-variable ;m

\ This is a search order trick to help search a single vocabulary,
\ without also looking in forth or root.
f: exclusively   ( a - cfa -1 | a 0)
    dup count context @ search-wordlist
    dup if   rot drop   then ;m

\ Is counted string a target immediate word?
f: IMMEDIATE?    ( a - cfa ? | a 0)
        DUP C@
        IF      ONLY PREVIOUS IMMED FIND IN-TARGET
        ELSE    0
        THEN ;m

\ Is counted string a normal target word?
f: TARGET?   ( a - cfa ? | a 0)
        ALSO TARGET EXCLUSIVELY PREVIOUS ;m

\ Is counted string a meta word?
f: META?  ( a - cfa ? | a 0)
        DUP C@
        IF      IN-META FIND IN-TARGET
        ELSE    0
        THEN ;m

m: ?missing   ( flag - )   abort" is undefined" ;

\ To look up the address of a host word.
f: host'   (  - a)   ' ;m

\ Get the target address of a target word.
m: '   (  - a)   bl word target? 0= ?missing execute ;m

\ Compile a target address literal into the host, not the target image.
m: [t']   (  - a)   ' [compile] literal ;m immediate

IN-META

\ Building strings on the target.
M: STRING   ( c - )   WORD COUNT DUP C,-T S,-T ;M
f: HOST,"   (  - )   ," ;M
M: ,"       (  - )   [CHAR] " STRING ;M
M: ,'       (  - )   [CHAR] ' STRING ;M

f: double?   (  - flag)   dpl @ 0< not ;

