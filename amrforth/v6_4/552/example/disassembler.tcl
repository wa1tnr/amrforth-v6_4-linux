# Disassembler additions to amrforth.tcl
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

proc see {} {
    global ip total_cycles
    set total_cycles 0
    set word [next-word]
    generic-see "$word"
}

proc dis {} {
    global ip total_cycles
    set total_cycles 0
    set word [next-word]
    set addr [decimal $word]
    generic-dis "$addr"
}

proc generic-see {word} {
    global ip
    show-source-code $word
    show-mesg "\nPress ESCAPE to quit, any other key to continue..."
    if {![isforth $word]} {
        if {![ishiddenforth $word]} {
            show-prompt
            error "Not in Symbol Table"
        } else {
            set addr [lookuphidden $word]
        }
    } else {
        set addr [lookupforth $word]
    }
    set ip $addr
    disassemble
    while {[get-key] != 27} {
        disassemble
    }
}

proc generic-dis {addr} {
    global ip
    set ip $addr
    disassemble
    while {[get-key] != 27} {
        disassemble
    }
}

proc see-from-menu {} {
	set word [dialog-prompt "Enter the word to decompile"]
	if {$word == ""} {return}
    generic-see $word
    show-prompt
}

proc disassemble {} {
    global ip disasm
    set instruction [at $ip]
    if {[isaddress $ip]} {
        set word [lookupaddress $ip]
        if {[iscall $instruction]} {
            show-target "\n                :"
        } else {
            show-target "\n                code"
        }
        show-target " $word"
        show-header
    }
    if {[ishiddenaddress $ip]} {
        set word [lookuphiddenaddress $ip]
        if {[callable]} {
            show-target "\n                :"
        } else {
            show-target "\n                code"
        }
        show-target " $word"
        show-header
    }
    set instruction [at $ip]
    if {[info exists disasm($instruction)]} {
        eval $disasm($instruction)
    } else {
        dasm 1 "???"
    }
}

proc show-address {bytes} {
    global ip
    set addr [hex $ip]
    show "\n$addr  "
    for {set i 3} {$i != 0} {incr i -1} {
        if {$bytes > 0} {
            set this [hexbyte [at $ip]]
            show "$this "
            incr ip 1
        } else {
            show "   "
        }
        incr bytes -1
    }
}

proc show_string {bytes} {
    global ip
    set addr [hex $ip]
    show "\n$addr  "
    set this [hexbyte [at $ip]]
    show "$this "
    incr ip 1
    for {set i $bytes} {$i != 0} {incr i -1} {
        set this [asciichar [at $ip]]
        show-mesg "$this"
        incr ip 1
    }
}

proc dasm {bytes mnemonic} {
    global ip
    show-address $bytes
    show " $mnemonic"
}

proc get-literal {offset} {
    global ip
    set this [expr $ip + $offset]
    set that [at $this]
    set it [hexbyte $that]
    return $it
}

proc literal {offset} {
    set this [get-literal $offset]
    show $this
}

proc relative {} {
    global ip
    set rel [at [expr $ip - 1]]
    if {[expr $rel > 127]} {set rel [expr -1 * (256 - $rel)]}
    set addr [expr $ip + $rel]
    set this [hex $addr]
    show $this
}

proc fill {word} {
    set extent [string length $word]
    if {$extent < 9} {
        set extra [expr 9 - $extent]
        while {$extra != 0} {
            show " "
            incr extra -1
        }
    }
    show "\t"
}

proc show-header {} {
    show-mesg "\naddr  code      mnemonic    word                cycles"
}

proc addr11 {} {
    global ip
    incr ip -2
    set addr $ip
    set this [absolute]
    set that [hex $this]
    show $that
    if {[isaddress $this]} {
        set word [lookupaddress $this]
        show-target "  $word"
        fill $word
    } else {
        if {[ishiddenaddress $this]} {
            set word [lookuphiddenaddress $this]
            show-target "  $word"
            fill $word
        }
    }
    if {[isexit $addr]} {show-target " ;"}
    show-literal $this
}

proc addr16 {} {
    global ip
    incr ip -3
    set addr $ip
    set this [long-addr]
    set that [hex $this]
    show $that
    if {[isaddress $this]} {
        set word [lookupaddress $this]
        show-target "  $word"
        fill $word
    } else {
        if {[ishiddenaddress $this]} {
            set word [lookuphiddenaddress $this]
            show-target "  $word"
            fill $word
        }
    }
    if {[isexit $addr]} {show-target " ;"}
    show-literal $this
}
    
proc show-literal {addr} {
    global ip
    if {$addr == [lookuphidden "lit"]} {
        show-address 2
        show "\t\t\t\t"
        return
    }
    if {$addr == [lookuphidden "?branch"]} {
        show-address 2
        show "\t\t\t\t"
        return
    }
    if {$addr == [lookuphidden "(next)"]} {
        show-address 2
        show "\t\t\t\t"
        return
    }
    if {$addr == [lookuphidden "(string)"]} {
	set count [at $ip]
	show_string $count
	show "\t"
	return
    }
}

proc cycles {str tabs} {
    global total_cycles
    incr total_cycles $str
    while {$tabs} {
        show "\t"
        incr tabs -1
    }
    show "\t+$str=$total_cycles"
}

# acall
set disasm([decimal 0x11]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0x31]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0x51]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0x71]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0x91]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0xb1]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0xd1]) {dasm 2 "acall ";addr11;cycles 3 0}
set disasm([decimal 0xf1]) {dasm 2 "acall ";addr11;cycles 3 0}

# ajmp
set disasm([decimal 0x01]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0x21]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0x41]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0x61]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0x81]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0xa1]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0xc1]) {dasm 2 "ajmp  ";addr11;cycles 3 0}
set disasm([decimal 0xe1]) {dasm 2 "ajmp  ";addr11;cycles 3 0}

# relative jumps
set disasm([decimal 0x10]) {
    dasm 3 "jbc .";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0x20]) {
    dasm 3 "jb .";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0x30]) {
    dasm 3 "jnb .";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0x40]) {dasm 2 "jc ";relative;cycles 2 3}
set disasm([decimal 0x50]) {dasm 2 "jnc ";relative;cycles 2 2}
set disasm([decimal 0x60]) {dasm 2 "jz ";relative;cycles 2 3}
set disasm([decimal 0x70]) {dasm 2 "jnz ";relative;cycles 2 2}

# 00
set disasm([decimal 0x00]) {dasm 1 "nop";cycles 1 3}
set disasm([decimal 0x02]) {dasm 3 "ljmp ";addr16;cycles 4 0}
set disasm([decimal 0x03]) {dasm 1 "rr A";cycles 1 3}
set disasm([decimal 0x04]) {dasm 1 "inc A";cycles 1 3}
set disasm([decimal 0x05]) {dasm 2 "inc ";literal -1;cycles 2 3}
set disasm([decimal 0x06]) {dasm 1 "inc @R0";cycles 2 3}
set disasm([decimal 0x07]) {dasm 1 "inc @R1";cycles 2 3}
set disasm([decimal 0x08]) {dasm 1 "inc R0";cycles 1 3}
set disasm([decimal 0x09]) {dasm 1 "inc R1";cycles 1 3}
set disasm([decimal 0x0a]) {dasm 1 "inc R2";cycles 1 3}
set disasm([decimal 0x0b]) {dasm 1 "inc R3";cycles 1 3}
set disasm([decimal 0x0c]) {dasm 1 "inc R4";cycles 1 3}
set disasm([decimal 0x0d]) {dasm 1 "inc R5";cycles 1 3}
set disasm([decimal 0x0e]) {dasm 1 "inc R6";cycles 1 3}
set disasm([decimal 0x0f]) {dasm 1 "inc R7";cycles 1 3}

# 10
set disasm([decimal 0x12]) {dasm 3 "lcall ";addr16;cycles 4 0}
set disasm([decimal 0x13]) {dasm 1 "rrc A";cycles 1 3}
set disasm([decimal 0x14]) {dasm 1 "dec A";cycles 1 3}
set disasm([decimal 0x15]) {dasm 2 "dec ";literal -1;cycles 2 3}
set disasm([decimal 0x16]) {dasm 1 "dec @R0";cycles 2 2}
set disasm([decimal 0x17]) {dasm 1 "dec @R1";cycles 2 2}
set disasm([decimal 0x18]) {dasm 1 "dec R0";cycles 1 3}
set disasm([decimal 0x19]) {dasm 1 "dec R1";cycles 1 3}
set disasm([decimal 0x1a]) {dasm 1 "dec R2";cycles 1 3}
set disasm([decimal 0x1b]) {dasm 1 "dec R3";cycles 1 3}
set disasm([decimal 0x1c]) {dasm 1 "dec R4";cycles 1 3}
set disasm([decimal 0x1d]) {dasm 1 "dec R5";cycles 1 3}
set disasm([decimal 0x1e]) {dasm 1 "dec R6";cycles 1 3}
set disasm([decimal 0x1f]) {dasm 1 "dec R7";cycles 1 3}

# 20
set disasm([decimal 0x22]) {dasm 1 "ret";cycles 5 3}
set disasm([decimal 0x23]) {dasm 1 "rl A";cycles 1 2}
set disasm([decimal 0x24]) {dasm 2 "add A,#";literal -1;cycles 2 2}
set disasm([decimal 0x25]) {dasm 2 "add A,";literal -1;cycles 2 2}
set disasm([decimal 0x26]) {dasm 1 "add A,@R0";cycles 2 2}
set disasm([decimal 0x27]) {dasm 1 "add A,@R1";cycles 2 2}
set disasm([decimal 0x28]) {dasm 1 "add A,R0";cycles 1 2}
set disasm([decimal 0x29]) {dasm 1 "add A,R1";cycles 1 2}
set disasm([decimal 0x2a]) {dasm 1 "add A,R2";cycles 1 2}
set disasm([decimal 0x2b]) {dasm 1 "add A,R3";cycles 1 2}
set disasm([decimal 0x2c]) {dasm 1 "add A,R4";cycles 1 2}
set disasm([decimal 0x2d]) {dasm 1 "add A,R5";cycles 1 2}
set disasm([decimal 0x2e]) {dasm 1 "add A,R6";cycles 1 2}
set disasm([decimal 0x2f]) {dasm 1 "add A,R7";cycles 1 2}

# 30
set disasm([decimal 0x32]) {dasm 1 "reti";cycles 5 3}
set disasm([decimal 0x33]) {dasm 1 "rlc A";cycles 1 3}
set disasm([decimal 0x34]) {dasm 2 "addc A,#";literal -1;cycles 2 2}
set disasm([decimal 0x35]) {dasm 2 "addc A,";literal -1;cycles 2 2}
set disasm([decimal 0x36]) {dasm 1 "addc A,@R0";cycles 2 2}
set disasm([decimal 0x37]) {dasm 1 "addc A,@R1";cycles 2 2}
set disasm([decimal 0x38]) {dasm 1 "addc A,R0";cycles 1 2}
set disasm([decimal 0x39]) {dasm 1 "addc A,R1";cycles 1 2}
set disasm([decimal 0x3a]) {dasm 1 "addc A,R2";cycles 1 2}
set disasm([decimal 0x3b]) {dasm 1 "addc A,R3";cycles 1 2}
set disasm([decimal 0x3c]) {dasm 1 "addc A,R4";cycles 1 2}
set disasm([decimal 0x3d]) {dasm 1 "addc A,R5";cycles 1 2}
set disasm([decimal 0x3e]) {dasm 1 "addc A,R6";cycles 1 2}
set disasm([decimal 0x3f]) {dasm 1 "addc A,R7";cycles 1 2}

# 40
set disasm([decimal 0x42]) {
    dasm 2 "orl ";literal -1;show ",A";cycles 2 2
}
set disasm([decimal 0x43]) {
    dasm 3 "orl ";literal -2;show ",#";literal -1;cycles 3 2
}
set disasm([decimal 0x44]) {dasm 2 "orl A,#";literal -1;cycles 2 2}
set disasm([decimal 0x45]) {dasm 2 "orl A,";literal -1;cycles 2 2}
set disasm([decimal 0x46]) {dasm 1 "orl A,@R0";cycles 2 2}
set disasm([decimal 0x47]) {dasm 1 "orl A,@R1";cycles 2 2}
set disasm([decimal 0x48]) {dasm 1 "orl A,R0";cycles 1 2}
set disasm([decimal 0x49]) {dasm 1 "orl A,R1";cycles 1 2}
set disasm([decimal 0x4a]) {dasm 1 "orl A,R2";cycles 1 2}
set disasm([decimal 0x4b]) {dasm 1 "orl A,R3";cycles 1 2}
set disasm([decimal 0x4c]) {dasm 1 "orl A,R4";cycles 1 2}
set disasm([decimal 0x4d]) {dasm 1 "orl A,R5";cycles 1 2}
set disasm([decimal 0x4e]) {dasm 1 "orl A,R6";cycles 1 2}
set disasm([decimal 0x4f]) {dasm 1 "orl A,R7";cycles 1 2}

# 50
set disasm([decimal 0x52]) {
    dasm 2 "anl ";literal -1;show ",A";cycles 2 2
}
set disasm([decimal 0x53]) {
    dasm 3 "anl ";literal -2;show ",#";literal -1;cycles 3 2
}
set disasm([decimal 0x54]) {dasm 2 "anl A,#";literal -1;cycles 2 2}
set disasm([decimal 0x55]) {dasm 2 "anl A,";literal -1;cycles 2 2}
set disasm([decimal 0x56]) {dasm 1 "anl A,@R0";cycles 2 2}
set disasm([decimal 0x57]) {dasm 1 "anl A,@R1";cycles 2 2}
set disasm([decimal 0x58]) {dasm 1 "anl A,R0";cycles 1 2}
set disasm([decimal 0x59]) {dasm 1 "anl A,R1";cycles 1 2}
set disasm([decimal 0x5a]) {dasm 1 "anl A,R2";cycles 1 2}
set disasm([decimal 0x5b]) {dasm 1 "anl A,R3";cycles 1 2}
set disasm([decimal 0x5c]) {dasm 1 "anl A,R4";cycles 1 2}
set disasm([decimal 0x5d]) {dasm 1 "anl A,R5";cycles 1 2}
set disasm([decimal 0x5e]) {dasm 1 "anl A,R6";cycles 1 2}
set disasm([decimal 0x5f]) {dasm 1 "anl A,R7";cycles 1 2}

# 60
set disasm([decimal 0x62]) {
    dasm 2 "xrl ";literal -1;show ",A";cycles 2 2
}
set disasm([decimal 0x63]) {
    dasm 3 "xrl ";literal -2;show ",#";literal -1;cycles 3 2
}
set disasm([decimal 0x64]) {dasm 2 "xrl A,#";literal -1;cycles 2 2}
set disasm([decimal 0x65]) {dasm 2 "xrl A,";literal -1;cycles 2 2}
set disasm([decimal 0x66]) {dasm 1 "xrl A,@R0";cycles 2 2}
set disasm([decimal 0x67]) {dasm 1 "xrl A,@R1";cycles 2 2}
set disasm([decimal 0x68]) {dasm 1 "xrl A,R0";cycles 1 2}
set disasm([decimal 0x69]) {dasm 1 "xrl A,R1";cycles 1 2}
set disasm([decimal 0x6a]) {dasm 1 "xrl A,R2";cycles 1 2}
set disasm([decimal 0x6b]) {dasm 1 "xrl A,R3";cycles 1 2}
set disasm([decimal 0x6c]) {dasm 1 "xrl A,R4";cycles 1 2}
set disasm([decimal 0x6d]) {dasm 1 "xrl A,R5";cycles 1 2}
set disasm([decimal 0x6e]) {dasm 1 "xrl A,R6";cycles 1 2}
set disasm([decimal 0x6f]) {dasm 1 "xrl A,R7";cycles 1 2}

# 70
set disasm([decimal 0x72]) {
    dasm 2 "orl C,.";literal -1;cycles 2 2
}
set disasm([decimal 0x73]) {dasm 1 "jmp @A+DPTR";cycles 3 2}
set disasm([decimal 0x74]) {dasm 2 "mov A,#";literal -1;cycles 2 2}
set disasm([decimal 0x75]) {
    dasm 3 "mov ";literal -2; show ",#";literal -1;cycles 3 2
}
set disasm([decimal 0x76]) {dasm 2 "mov @R0,#";literal -1;cycles 2 2}
set disasm([decimal 0x77]) {dasm 2 "mov @R1,#";literal -1;cycles 2 2}
set disasm([decimal 0x78]) {dasm 2 "mov R0,#";literal -1;cycles 1 2}
set disasm([decimal 0x79]) {dasm 2 "mov R1,#";literal -1;cycles 1 2}
set disasm([decimal 0x7a]) {dasm 2 "mov R2,#";literal -1;cycles 1 2}
set disasm([decimal 0x7b]) {dasm 2 "mov R3,#";literal -1;cycles 1 2}
set disasm([decimal 0x7c]) {dasm 2 "mov R4,#";literal -1;cycles 1 2}
set disasm([decimal 0x7d]) {dasm 2 "mov R5,#";literal -1;cycles 1 2}
set disasm([decimal 0x7e]) {dasm 2 "mov R6,#";literal -1;cycles 1 2}
set disasm([decimal 0x7f]) {dasm 2 "mov R7,#";literal -1;cycles 1 2}

# 80
set disasm([decimal 0x80]) {dasm 2 "sjmp  ";relative;cycles 3 2}
set disasm([decimal 0x82]) {
    dasm 2 "anl C,.";literal -1;cycles 2 2
}
set disasm([decimal 0x83]) {dasm 1 "movc A,@A+PC";cycles 3 2}
set disasm([decimal 0x84]) {dasm 1 "div AB";cycles 8 3}
set disasm([decimal 0x85]) {
    dasm 3 "mov ";literal -1;show ",";literal -2;cycles 3 2
}
set disasm([decimal 0x86]) {
    dasm 2 "mov ";literal -1;show ",@R0";cycles 2 2
}
set disasm([decimal 0x87]) {
    dasm 2 "mov ";literal -1;show ",@R0";cycles 2 2
}
set disasm([decimal 0x88]) {
    dasm 2 "mov ";literal -1;show ",R0";cycles 2 2
}
set disasm([decimal 0x89]) {
    dasm 2 "mov ";literal -1;show ",R1";cycles 2 2
}
set disasm([decimal 0x8a]) {
    dasm 2 "mov ";literal -1;show ",R2";cycles 2 2
}
set disasm([decimal 0x8b]) {
    dasm 2 "mov ";literal -1;show ",R3";cycles 2 2
}
set disasm([decimal 0x8c]) {
    dasm 2 "mov ";literal -1;show ",R4";cycles 2 2
}
set disasm([decimal 0x8d]) {
    dasm 2 "mov ";literal -1;show ",R5";cycles 2 2
}
set disasm([decimal 0x8e]) {
    dasm 2 "mov ";literal -1;show ",R6";cycles 2 2
}
set disasm([decimal 0x8f]) {
    dasm 2 "mov ";literal -1;show ",R7";cycles 2 2
}

# 90
set disasm([decimal 0x90]) {
    dasm 3 "mov DPTR,#";literal -2;literal -1;cycles 3 2
}
set disasm([decimal 0x92]) {
    dasm 2 "mov .";literal -1;show ",C";cycles 2 2;
}
set disasm([decimal 0x93]) {dasm 1 "movc A,@A+DPTR";cycles 3 2}
set disasm([decimal 0x94]) {dasm 2 "subb A,#";literal -1;cycles 2 2}
set disasm([decimal 0x95]) {dasm 2 "subb A,";literal -1;cycles 2 2}
set disasm([decimal 0x96]) {dasm 1 "subb A,@R0";cycles 2 2}
set disasm([decimal 0x97]) {dasm 1 "subb A,@R1";cycles 2 2}
set disasm([decimal 0x98]) {dasm 1 "subb A,R0";cycles 1 2}
set disasm([decimal 0x99]) {dasm 1 "subb A,R1";cycles 1 2}
set disasm([decimal 0x9a]) {dasm 1 "subb A,R2";cycles 1 2}
set disasm([decimal 0x9b]) {dasm 1 "subb A,R3";cycles 1 2}
set disasm([decimal 0x9c]) {dasm 1 "subb A,R4";cycles 1 2}
set disasm([decimal 0x9d]) {dasm 1 "subb A,R5";cycles 1 2}
set disasm([decimal 0x9e]) {dasm 1 "subb A,R6";cycles 1 2}
set disasm([decimal 0x9f]) {dasm 1 "subb A,R7";cycles 1 2}

# a0
set disasm([decimal 0xa0]) {
    dasm 2 "orl C,/.";literal -1;cycles 2 2
}
set disasm([decimal 0xa2]) {
    dasm 2 "mov C,.";literal -1;cycles 2 2
}
set disasm([decimal 0xa3]) {dasm 1 "inc DPTR";cycles 1 2}
set disasm([decimal 0xa4]) {dasm 1 "mul AB";cycles 4 3}
set disasm([decimal 0xa6]) {dasm 2 "mov @R0,";literal -1;cycles 2 2}
set disasm([decimal 0xa7]) {dasm 2 "mov @R1,";literal -1;cycles 2 2}
set disasm([decimal 0xa8]) {dasm 2 "mov R0,";literal -1;cycles 2 2}
set disasm([decimal 0xa9]) {dasm 2 "mov R1,";literal -1;cycles 2 2}
set disasm([decimal 0xaa]) {dasm 2 "mov R2,";literal -1;cycles 2 2}
set disasm([decimal 0xab]) {dasm 2 "mov R3,";literal -1;cycles 2 2}
set disasm([decimal 0xac]) {dasm 2 "mov R4,";literal -1;cycles 2 2}
set disasm([decimal 0xad]) {dasm 2 "mov R5,";literal -1;cycles 2 2}
set disasm([decimal 0xae]) {dasm 2 "mov R6,";literal -1;cycles 2 2}
set disasm([decimal 0xaf]) {dasm 2 "mov R7,";literal -1;cycles 2 2}

# b0
set disasm([decimal 0xb0]) {
    dasm 2 "anl C,/.";literal -1;cycles 2 2
}
set disasm([decimal 0xb2]) {
    dasm 2 "cpl .";literal -1;cycles 2 1
}
set disasm([decimal 0xb3]) {dasm 1 "cpl C";cycles 1 2}
set disasm([decimal 0xb4]) {
    dasm 3 "cjne A,#";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0xb5]) {
    dasm 3 "cjne A,";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0xb6]) {
    dasm 3 "cjne @R0,#";literal -2;show ",";relative;cycles 4 1
}
set disasm([decimal 0xb7]) {
    dasm 3 "cjne @R1,#";literal -2;show ",";relative;cycles 4 1
}
set disasm([decimal 0xb8]) {
    dasm 3 "cjne R0,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xb9]) {
    dasm 3 "cjne R1,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xba]) {
    dasm 3 "cjne R2,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xbb]) {
    dasm 3 "cjne R3,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xbc]) {
    dasm 3 "cjne R4,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xbd]) {
    dasm 3 "cjne R5,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xbe]) {
    dasm 3 "cjne R6,#";literal -2;show ",";relative;cycles 3 1
}
set disasm([decimal 0xbf]) {
    dasm 3 "cjne R7,#";literal -2;show ",";relative;cycles 3 1
}

# c0
set disasm([decimal 0xc0]) {dasm 2 "push ";literal -1;cycles 2 3}
set disasm([decimal 0xc2]) {
    dasm 2 "clr .";literal -1;cycles 2 3
}
set disasm([decimal 0xc3]) {dasm 1 "clr C";cycles 1 3}
set disasm([decimal 0xc4]) {dasm 1 "swap A";cycles 1 2}
set disasm([decimal 0xc5]) {dasm 2 "xch A,";literal -1;cycles 2 2}
set disasm([decimal 0xc6]) {dasm 1 "xch A,@R0";cycles 2 2}
set disasm([decimal 0xc7]) {dasm 1 "xch A,@R1";cycles 2 2}
set disasm([decimal 0xc8]) {dasm 1 "xch A,R0";cycles 1 2}
set disasm([decimal 0xc9]) {dasm 1 "xch A,R1";cycles 1 2}
set disasm([decimal 0xca]) {dasm 1 "xch A,R2";cycles 1 2}
set disasm([decimal 0xcb]) {dasm 1 "xch A,R3";cycles 1 2}
set disasm([decimal 0xcc]) {dasm 1 "xch A,R4";cycles 1 2}
set disasm([decimal 0xcd]) {dasm 1 "xch A,R5";cycles 1 2}
set disasm([decimal 0xce]) {dasm 1 "xch A,R6";cycles 1 2}
set disasm([decimal 0xcf]) {dasm 1 "xch A,R7";cycles 1 2}

# d0
set disasm([decimal 0xd0]) {dasm 2 "pop   ";literal -1;cycles 2 2}
set disasm([decimal 0xd2]) {
    dasm 2 "setb .";literal -1;cycles 2 2
}
set disasm([decimal 0xd3]) {dasm 1 "setb C";cycles 1 3}
set disasm([decimal 0xd4]) {dasm 1 "da A  ";cycles 1 3}
set disasm([decimal 0xd5]) {
    dasm 3 "djnz ";literal -2;show ",";relative;cycles 3 2
}
set disasm([decimal 0xd6]) {dasm 1 "xchd A,@R0";cycles 2 2}
set disasm([decimal 0xd7]) {dasm 1 "xchd A,@R1";cycles 2 2}
set disasm([decimal 0xd8]) {dasm 2 "djnz R0,";relative;cycles 2 2}
set disasm([decimal 0xd9]) {dasm 2 "djnz R1,";relative;cycles 2 2}
set disasm([decimal 0xda]) {dasm 2 "djnz R2,";relative;cycles 2 2}
set disasm([decimal 0xdb]) {dasm 2 "djnz R3,";relative;cycles 2 2}
set disasm([decimal 0xdc]) {dasm 2 "djnz R4,";relative;cycles 2 2}
set disasm([decimal 0xdd]) {dasm 2 "djnz R5,";relative;cycles 2 2}
set disasm([decimal 0xde]) {dasm 2 "djnz R6,";relative;cycles 2 2}
set disasm([decimal 0xdf]) {dasm 2 "djnz R7,";relative;cycles 2 2}


# e0
set disasm([decimal 0xe0]) {dasm 1 "movx A,@DPTR";cycles 3 2}
set disasm([decimal 0xe2]) {dasm 1 "movx A,@R0";cycles 3 2}
set disasm([decimal 0xe3]) {dasm 1 "movx A,@R1";cycles 3 2}
set disasm([decimal 0xe4]) {dasm 1 "clr A";cycles 1 3}
set disasm([decimal 0xe5]) {dasm 2 "mov A,";literal -1;cycles 2 2}
set disasm([decimal 0xe6]) {dasm 1 "mov A,@R0";cycles 2 2}
set disasm([decimal 0xe7]) {dasm 1 "mov A,@R1";cycles 2 2}
set disasm([decimal 0xe8]) {dasm 1 "mov A,R0";cycles 1 2}
set disasm([decimal 0xe9]) {dasm 1 "mov A,R1";cycles 1 2}
set disasm([decimal 0xea]) {dasm 1 "mov A,R2";cycles 1 2}
set disasm([decimal 0xeb]) {dasm 1 "mov A,R3";cycles 1 2}
set disasm([decimal 0xec]) {dasm 1 "mov A,R4";cycles 1 2}
set disasm([decimal 0xed]) {dasm 1 "mov A,R5";cycles 1 2}
set disasm([decimal 0xee]) {dasm 1 "mov A,R6";cycles 1 2}
set disasm([decimal 0xef]) {dasm 1 "mov A,R7";cycles 1 2}

# f0
set disasm([decimal 0xf0]) {dasm 1 "movx @DPTR,A";cycles 3 2}
set disasm([decimal 0xf2]) {dasm 1 "movx @R0,A";cycles 3 2}
set disasm([decimal 0xf3]) {dasm 1 "movx @R1,A";cycles 3 2}
set disasm([decimal 0xf4]) {dasm 1 "cpl A";cycles 1 3}
set disasm([decimal 0xf5]) {
    dasm 2 "mov ";literal -1;show ",A";cycles 2 2
}
set disasm([decimal 0xf6]) {dasm 1 "mov @R0,A";cycles 2 2}
set disasm([decimal 0xf7]) {dasm 1 "mov @R1,A";cycles 2 2}
set disasm([decimal 0xf8]) {dasm 1 "mov R0,A";cycles 1 2}
set disasm([decimal 0xf9]) {dasm 1 "mov R1,A";cycles 1 2}
set disasm([decimal 0xfa]) {dasm 1 "mov R2,A";cycles 1 2}
set disasm([decimal 0xfb]) {dasm 1 "mov R3,A";cycles 1 2}
set disasm([decimal 0xfc]) {dasm 1 "mov R4,A";cycles 1 2}
set disasm([decimal 0xfd]) {dasm 1 "mov R5,A";cycles 1 2}
set disasm([decimal 0xfe]) {dasm 1 "mov R6,A";cycles 1 2}
set disasm([decimal 0xff]) {dasm 1 "mov R7,A";cycles 1 2}

