# download-cygnal.tcl
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

proc hex_A5 {} {
	binary format c 0xa5
}

proc hex_5A {} {
	binary format c 0x5a
}

proc probe {} {
	set iterations 600
	clear-sbuf
	emit-s [hex_A5]
#	after 50
	after 10
	set char [key?-s]
	while {$char != [hex_5A]} {
		incr iterations -1
		if {$iterations < 0} {
			show-prompt
			error "Target not responding"
		}
		emit-s [hex_A5]
#		after 50
		after 10
		set char [key?-s]
	}
}

proc download-page {} {
	global binfid
	for {set i 0} {$i < 512} {incr i} {
		if {[catch {read $binfid 1} char]} {
			set char [binary format c 0]
		}
		emit-s $char
	}
}

proc download {} {
	global number_pages binfid
	probe
	emit-s "a"
	emit-s "m"
	emit-s "r"
	set char [key-s]
	while {$char != [hex_A5]} {
		set char [key-s]
	}
    show "Cygnal downloader.\n"
	show "Downloading rom.bin via RS232\n"
	show "512 byte pages: "
	emit-s [binary format c $number_pages]
	set char [key-s]
	if {$char != [hex_5A]} {
		show-prompt
		error " Problem bootloading"
	}
	set trash [read $binfid 512]
	for {set i 0} {$i < $number_pages} {incr i} {
		download-page
		set response [key-s]
		binary scan $response "H2" page
		show "$page "
	}
	set char [binary format c "0"]
	emit-s $char
}

proc run-downloader {} {
    global keypressed log
	if {[file exists rom.bin]} {
		open-object-file
        show "\n    To download to the target,\n"
		show "press and hold RESET on the target board,\n"
        show "then press the SPACE key...\n"
        set keypressed 0
# bind $log <Key> {set keypressed 1}
        tkwait variable keypressed
        show "   Now release the RESET button.\n"
        download
		close-object-file
		read-symbol-table
	} else {
		show "No object file, rom.bin\n"
	}
	update-info
}

