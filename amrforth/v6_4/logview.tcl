# Log View

if 0 {
Copyright (C) 1991-2003 by AM Research, Inc.

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

# Platform dependencies
if {$tcl_platform(platform) == "windows"} {
	set using_windows 1
	set homepath /amrforth/v6
	set local_url "C:\\amrforth\\v6\\html\\index.html"
} else {
	set using_windows 0
	set homepath ~/amrforth/v6
	set local_url "file://$env(HOME)/amrforth/v6/html/index.html"
}

proc openlogfile {} {
	global homepath
    set types {
    	{"Log Files"		*.log}
	}
	set file [tk_getOpenFile -filetypes $types -parent .]
	if [string compare $file ""] {
	}
}

wm minsize . 30 5

proc Scrolled_Text { f args } {
    frame $f
    eval {text $f.text -wrap none \
        -xscrollcommand [list $f.xscroll set] \
        -yscrollcommand [list $f.yscroll set] } $args
    scrollbar $f.xscroll -orient horizontal \
        -command [list $f.text xview]
    scrollbar $f.yscroll -orient vertical \
        -command [list $f.text yview]
    grid $f.text $f.yscroll -sticky news
    grid $f.xscroll -sticky news
    grid rowconfigure $f 0 -weight 1
    grid columnconfigure $f 0 -weight 1
    return $f.text
}
set t [Scrolled_Text .f -width 80 -height 16]
pack .f -side top -fill both -expand true
set types {
    {"Log Files"		*.log}
}
set file [tk_getOpenFile -filetypes $types -parent .]
if [string compare $file ""] {
    set in [open $file]
    $t insert end [read $in]
    close $in
    $t configure -state disabled
}
   
