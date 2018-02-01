# download-atmel.tcl

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

proc open-hex-object-file {} {
	global hexfid
	if {[catch {open "rom.hex" r} hexfid]} {
		show-prompt
		error "Problem opening rom.hex"
	}
}

proc close-hex-object-file {} {
	global hexfid
	close $hexfid
	set hexfid 0
}

proc autobaud {} {
    emit-s "U"
    set char [key-s]
    show "$char\n"
}

proc download {} {
	global hexfid comfid
	autobaud
    show "Atmel downloader.\n"
	show "Downloading rom.hex via RS232\n"
    while {[gets $hexfid line] >= 0} {
        set linelen [string length $line]
        puts $comfid $line
        after 100
        gets $comfid response
        set resplen [string length $response]
        if {[expr $resplen != ($linelen + 2)]} {
            error "Download error"
            show-prompt
        }
        show "."
        # show "$linelen $resplen\n"
    }
}

proc run-downloader {} {
    global keypressed log
	if {[file exists rom.hex]} {
		open-hex-object-file
        show "\n    To download to the target,\n"
		show "insert the jumper at JP3 and RESET the target board,\n"
        show "then press the SPACE key...\n"
        set keypressed 0
        tkwait variable keypressed
        download
		close-hex-object-file
		read-symbol-table
	} else {
		show "No object file, rom.hex\n"
	}
	update-info
}

