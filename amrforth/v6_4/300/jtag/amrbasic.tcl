# BASIC additions to amrforth.tcl
if 0 {
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

}

proc read-basic-symbol-table {} {
	global forth basic bytevariables wordvariables \
		operators sfrreaders sfrwriters aliases \
		bitio got-symbols input
	if {[info exists basic]} {unset basic}
	if {[info exists bytevariables]} {unset bytevariables}
	if {[info exists wordvariables]} {unset wordvariables}
	if {[info exists operators]} {unset operators}
	if {[info exists sfrreaders]} {unset sfrreaders}
	if {[info exists sfrwriters]} {unset sfrwriters}
	if {[info exists aliases]} {unset aliases}
	if {[info exists bitio]} {unset bitio}
# Load the BASIC subroutine table.
	if {![catch {open basicsymbols.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readbasicsymbol
		tkwait variable got-symbols
	}
# Load the BASIC byte variables table.
	if {![catch {open bytevariables.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readbytevariable
		tkwait variable got-symbols
	}
# Load the BASIC word variables table.
	if {![catch {open wordvariables.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readwordvariable
		tkwait variable got-symbols
	}
# Load the BASIC operators table.
	if {![catch {open operators.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readoperator
		tkwait variable got-symbols
	}
# Load the BASIC SFR readers table.
	if {![catch {open readsfrs.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readsfrreader
		tkwait variable got-symbols
	}
# Load the BASIC SFR writers table.
	if {![catch {open writesfrs.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readsfrwriter
		tkwait variable got-symbols
	}
# Load the BASIC aliases table.
	if {![catch {open aliases.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readalias
		tkwait variable got-symbols
	}
# Load the BASIC bitio table.
	if {![catch {open bitio.txt r} input]} {
		set got-symbols 0
		fileevent $input readable readbitio
		tkwait variable got-symbols
	}
}

proc delete-basic-files {} {
	delete-file "basicsymbols.txt"
	delete-file "bytevariables.txt"
	delete-file "wordvariables.txt"
	delete-file "operators.txt"
	delete-file "readsfrs.txt"
	delete-file "writesfrs.txt"
	delete-file "aliases.txt"
	delete-file "bitio.txt"
}

proc readbasicsymbol {} {
	global input name address got-symbols basic
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set basic($name) $address
}

proc readbytevariable {} {
	global input name address got-symbols bytevariables
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set bytevariables($name) $address
}

proc readwordvariable {} {
	global input name address got-symbols wordvariables
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set wordvariables($name) $address
}

proc readoperator {} {
	global input name address got-symbols operators
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set operators($name) $address
}

proc readsfrreader {} {
	global input name address got-symbols sfrreaders
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set sfrreaders($name) $address
}

proc readsfrwriter {} {
	global input name address got-symbols sfrwriters
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set sfrwriters($name) $address
}

proc readalias {} {
	global input name address got-symbols aliases
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set aliases($name) $address
}

proc readbitio {} {
	global input name address got-symbols bitio
	if [eof $input] {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set bitio($name) $address
}

proc show-basic-words {} {
	global basic bytevariables wordvariables aliases operators \
		sfrreaders sfrwriters bitio hostbasic
	show "\n-->Host words:\n"
    show-target [sorted hostbasic]
	show " \nSubroutines:\n"
	show-target [sorted basic]
	show " \nByte Variables:\n"
	show-target [sorted bytevariables]
	show " \nWord Variables:\n"
	show-target [sorted wordvariables]
	show " \nSFR Variables:\n"
	show-target [sorted sfrwriters]
	show " \nOperators:\n"
	show-target [sorted operators]
	show " \nI/O bits:\n"
	show-target [sorted bitio]
	show " \nSymbols:\n"
	show-target [sorted aliases]
#	show "\n"
}

proc execute-bytevariable {word} {
	set number [lookup-bytevariable $word]
	execute-number $number
	execute-word [lookupforth "c@"]
}

proc execute-wordvariable {word} {
	set number [lookup-wordvariable $word]
	execute-number $number
	execute-word [lookupforth "@"]
}

proc execute-sfrreader {word} {
	execute-word [lookup-sfrreader $word]
}

proc execute-bitio {word} {
	set number [lookup-bitio $word]
	execute-number $number
	execute-word [lookupforth "p0bit@"]
}

proc execute-operator {word} {
	if {[isoperator $word]} {
		execute-word [lookup-operator $word]
		return
	}
	show-prompt
	error "Not a valid BASIC operator"
}

proc execute-operand {word} {
	if {[isbytevariable $word]} {
		execute-bytevariable $word
		return
	}
	if {[iswordvariable $word]} {
		execute-wordvariable $word
		return
	}
	if {[issfrreader $word]} {
		execute-sfrreader $word
		return
	}
	if {[isbitio $word]} {
		execute-bitio $word
		return
	}
	if {[not-number $word]} {
		show-prompt
		error "Not a valid BASIC operand"
	} else {
		execute-number $word
	}
}

proc next-symbol {} {
	set word [next-word]
	if {[isalias $word]} {
		set word [lookup-alias $word]
	}
	return $word
}

proc infix {} {
	global commandlist in
	set word [next-symbol]
	execute-operand $word
	while {1} {
		set operator [next-word]
		if {$operator == ":"} {
			return 1
		}
		if {$operator == ","} {
			return 1
		}
		if {$operator == ""} {
			return 1
		}
		set operand [next-symbol]
		if {$operand == ""} {
			return 0
		}
		execute-operand $operand
		execute-operator $operator
	}
}

proc read-equals {} {
	global commandlist in
	set word [next-word]
	if {$word != "="} {
		show-prompt
		error "Assignment requires = sign"
	}
}

proc byte-assignment {location} {
	read-equals
	if {[infix]} {
		execute-number [lookup-bytevariable $location]
		execute-word [lookupforth "c!"]
	}
}

proc word-assignment {location} {
	read-equals
	if {[infix]} {
		execute-number [lookup-wordvariable $location]
		execute-word [lookupforth "!"]
	}
}

proc sfrwriter-assignment {location} {
	read-equals
	if {[infix]} {
		execute-word [lookup-sfrwriter $location]
	}
}

proc bitio-assignment {location} {
	read-equals
	if {[infix]} {
		execute-number [lookup-bitio $location]
		execute-word [lookupforth "p0bit!"]
	}
}

proc basic-let {} {
	global commandlist in
	set word [next-symbol]
	if {[isbytevariable $word]} {
		byte-assignment $word
		return
	}
	if {[iswordvariable $word]} {
		word-assignment $word
		return
	}
	if {[issfrwriter $word]} {
		sfrwriter-assignment $word
		return
	}
	if {[isbitio $word]} {
		bitio-assignment $word
		return
	}
	show-prompt
	error "Not an assignable variable."
}

proc basic-print {} {
#	global commandlist in
	if {[infix]} {
		execute-word [lookupforth "."]
	}
}

proc basic-pause {} {
	if {[infix]} {
		execute-word [lookupforth "ms"]
	}
}

proc basic-wait {} {
	if {[infix]} {
		execute-word [lookupforth "wait"]
	}
}

proc basic-pulseout {} {
	if {![infix]} {
		show-prompt
		error "Invalid parameter for pulseout"
	}
	if {![infix]} {
		show-prompt
		error "Invalid parameter for pulseout"
	}
	execute-word [lookupforth "pulseout"]
}

proc basic-high {} {
	if {![infix]} {
		show-prompt
		error "Invalid parameter for high"
	}
	execute-word [lookupforth "high"]
}

proc basic-low {} {
	if {![infix]} {
		show-prompt
		error "Invalid parameter for low"
	}
	execute-word [lookupforth "low"]
}

set hostbasic(bye) {exitapp}
set hostbasic(words) {show-basic-words}
set hostbasic(host) {use-host}
set hostbasic(forth) {use-forth}
set hostbasic(jtag) {use-jtag}
set hostbasic(c2) {use-c2}
set hostbasic(basic) {}
set hostbasic(let) {basic-let}
set hostbasic(gosub) {}
set hostbasic(print) {basic-print}
set hostbasic(pause) {basic-pause}
set hostbasic(wait)  {basic-wait}
set hostbasic(:) {}
set hostbasic(high) {basic-high}
set hostbasic(low) {basic-low}
set hostbasic(edit) {filetoopen}
set hostbasic(c) {run-compiler}
set hostbasic(t) {run-rommer}
set hostbasic(d) {run-downloader}
set hostbasic(e) {locate-source}

proc ishostbasic {word} {
	global hostbasic
	return [info exists hostbasic($word)]
}

proc isbasicvariable {word} {
	global variables
	return [info exists variables($word)]
}

proc isbasicalias {word} {
	global aliases
	return [info exists aliases($word)]
}

proc isbasic {word} {
	global basic
	return [info exists basic($word)]
}

proc isbytevariable {word} {
	global bytevariables
	return [info exists bytevariables($word)]
}

proc iswordvariable {word} {
	global wordvariables
	return [info exists wordvariables($word)]
}

proc isoperator {word} {
	global operators
	return [info exists operators($word)]
}

proc issfrreader {word} {
	global sfrreaders
	return [info exists sfrreaders($word)]
}

proc issfrwriter {word} {
	global sfrwriters
	return [info exists sfrwriters($word)]
}

proc isbitio {word} {
	global bitio
	return [info exists bitio($word)]
}

proc isalias {word} {
	global aliases
	return [info exists aliases($word)]
}

proc lookuphostbasic {word} {
	global hostbasic
	return $hostbasic($word)
}

proc lookupbasic {word} {
	global basic
	return $basic($word)
}

proc lookup-bytevariable {word} {
	global bytevariables
	return $bytevariables($word)
}

proc lookup-wordvariable {word} {
	global wordvariables
	return $wordvariables($word)
}

proc lookup-operator {word} {
	global operators
	return $operators($word)
}

proc lookup-sfrreader {word} {
	global sfrreaders
	return $sfrreaders($word)
}

proc lookup-sfrwriter {word} {
	global sfrwriters
	return $sfrwriters($word)
}

proc lookup-bitio {word} {
	global bitio
	return $bitio($word)
}

proc lookup-alias {word} {
	global aliases
	return $aliases($word)
}

proc interpret-basic {word} {
	if {[isalias $word]} {
		set word [lookup-alias $word]
	}
	if {[ishostbasic $word]} {
		eval [lookuphostbasic $word]
		return
	}
	if {[isbasic $word]} {
		execute-word [lookupbasic $word]
		return
	}
	if {[isbytevariable $word]} {
		byte-assignment $word
		return
	}
	if {[iswordvariable $word]} {
		word-assignment $word
		return
	}
	if {[issfrwriter $word]} {
		sfrwriter-assignment $word
		return
	}
	if {[isbitio $word]} {
		bitio-assignment $word
		return
	}
	show-prompt
	error "Not a valid BASIC expression"
}

