# download-aduc.tcl
# The amrForth v6 GUI.

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

global using_windows

proc get-char {} {
	set char [key?-s]
	while {[string equal $char ""]} {
		set char [key?-s]
	}
	return $char
}

proc ignore {num} {
	while {$num} {
		set char [key-s]
		incr num -1
	}
}

proc new-chip {} {
	set char [get-char]
	show $char
	update
	if {$char == "A"} {
		set char [get-char]
		show $char
		update
		if {$char == "D"} {
			set char [get-char]
			show $char
			update
			if {$char == "I"} {
				ignore 22
				return 1
			}
			if {$char == "u"} {
				ignore 9
				return 1
			}
		}
	}
	return 0
}

proc spit {number} {
	emit-s [binary format c $number]
}

proc spit-char {char} {
	emit-s [binary format a $char]
}

proc check-spit {number} {
	global checksum
	incr checksum $number
	spit $number
#	show "$checksum "
}

proc check-spit-char {char} {
	global checksum
	binary scan $char c number
	incr checksum $number
	spit-char $char
#	show "$checksum "
}

proc send-address {number} {
	check-spit 0
	set highbyte [expr $number / 256]
	check-spit $highbyte
	set lowbyte [expr $number & 255]
	check-spit $lowbyte
}

proc send-checksum {} {
	global checksum
	set byte [expr -$checksum & 0xff]
	spit $byte
#	binary scan $byte c this
#	show "$this\n"
}

proc send-packet-start-ID {} {
	global checksum
	set checksum 0
	spit 0x07
	spit 0x0e
}

if {$using_windows != 0} {

# With a 3 second timeout.
proc wait-for-ack {} {
	set char [key?-s]
	set timer 300
	while {$char != [binary format c 0x06]} {
		incr timer -1
		if {$timer < 0} {
			show "\n"
			error "Timed out waiting for ack"
		}
		after 10
		# show "!"
# update runs through the event loop, catches serial input?
# That's probably why 'show "!" worked.  Now we don't need to see the !
		update
		set char [key?-s]
	}
}

} else {

# With a 3 second timeout.
proc wait-for-ack {} {
	set char [key?-s]
	set timer 300
	while {$char != [binary format c 0x06]} {
		incr timer -1
		if {$timer < 0} {
			show "\n"
			error "Timed out waiting for ack"
		}
		after 10
		set char [key?-s]
	}
}

}

proc erase-program-memory {} {
	send-packet-start-ID
	check-spit 1
	check-spit-char C
	send-checksum
	wait-for-ack
}

proc run-program-code {} {
	send-packet-start-ID
	check-spit 4
	check-spit-char U
	send-address 0
	send-checksum
	wait-for-ack
}

proc download-line {} {
	global binfid
	for {set i 0} {$i < 16} {incr i} {
		if {[catch {read $binfid 1} char]} {
			set char [binary format c 0]
		}
#		show "$char "
		check-spit-char $char
	}
#	show "\n"
}

proc send-program-line {} {
	global address
	send-packet-start-ID
	check-spit 20
	check-spit-char W
	send-address $address
	download-line
	incr address 16
	send-checksum
	wait-for-ack
}

proc download {} {
	global address romHERE
	if {![new-chip]} {
		error "Problem with downloader"
	}
	show "\nErasing program memory\n"
	update
	erase-program-memory
	show "Writing program memory\n"
	set number_lines [expr $romHERE / 16]
	set address 0
	for {set i 0} {$i < $number_lines} {incr i} {
		send-program-line
		set yes [expr $i & 7]
		if {$yes == 0} {
			show "."
			update
		}
	}
	run-program-code
}

proc run-downloader {} {
	if {[file exists rom.bin]} {
		show "Downloading rom.bin via RS232\n"
		open-object-file
		show "Press RESET on the target board\n"
		clear-sbuf
		download
		close-object-file
		read-symbol-table
	} else {
		show "No object file, rom.bin\n"
	}
	update-info
}

