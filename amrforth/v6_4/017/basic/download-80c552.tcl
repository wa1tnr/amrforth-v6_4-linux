# download-80c552.tcl
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

proc download-page {} {
	global binfid
	for {set i 0} {$i < 512} {incr i} {
		if {[catch {read $binfid 1} char]} {
			error "Problem reading file"
		}
#		set that [expr $i & 15]
#		if {$that == 0} {show "\n"}
		emit-s $char
#		binary scan $char H2 this
#		show "$this "
	}
}

proc send-16bits {num} {
	set highbyte [expr $num / 256]
	set lowbyte [expr $num & 255]
	set x [binary format c $lowbyte]
	emit-s $x
	set x [binary format c $highbyte]
	emit-s $x
}

proc download {} {
	global number_pages binfid
	set address 0x8000
	set length [expr $number_pages * 512]
	emit-s [binary format c "4"]
	after 10
	send-16bits $address
	after 10
	send-16bits $length
	after 10
	# send 2 bytes of address
	set counter $number_pages
	while {$counter} {
		download-page
		show "."
		incr counter -1
	}
	execute-word [lookupforth "abort"]
}

proc run-downloader {} {
	show "80c552 downloader.\n"
	if {[file exists rom.bin]} {
		show "Downloading rom.bin via RS232\n"
		open-object-file
		download
		close-object-file
		read-symbol-table
	} else {
		show "No object file, rom.bin\n"
	}
	update-info
}

