# amrforth.tcl
# the amrforth v6 gui.

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

# ALL20030705 font 'micro' added, better for 1024x768

}
if {[file exists errors.log]} {file delete errors.log}

global using_windows

# Platform dependencies
if {$tcl_platform(platform) == "windows"} {
	set using_windows 1
	set homepath /amrforth/v6_4
	set gforthpath /PROGRA~1/gforth/gforth
	set local_url "C:\\amrforth\\www.amresearch.com\\v6\\index.html"
} else {
	set using_windows 0
	set homepath ~/amrforth/v6_4
	set gforthpath gforth
	set local_url "file://$env(HOME)/amrforth/www.amresearch.com/v6/index.html"
}

# question set, windows or linux.
proc qset {var win lin} {
    global using_windows $var
    if {$using_windows} {
        set $var $win
    } else {
        set $var $lin
    }
}

# question source, local or global.
proc qsource {filename} {
    global homepath hostbasic
    if {[file exists "./$filename"]} {
        source "./$filename"
    } else {
        source "$homepath/$filename"
    }
}

set processor "No Processor"
set commname "No Comm"
set comport 0
set freq "No Frequency"
set baudrate "9600"
set mode "Host"
set fgColor black
set bgColor LightGray
set hlColor blue
set fgTargetColor blue
set fgMesgColor red
set cursorColor blue
set downloader ""
set th1 0
set smod true
set romstart 691
set sfrfile "nothing"
set kernel "undefined"
qset browser "" "konqueror"
set online_url "http://www.amresearch.com/v6/index.html"
set default_size 10
set editor_height 10
set text_height 10
set main_height 400
set main_width 600
set main_percent 0.5
set orientation vertical
set keypressed 0
set timing 0
set immed ""
set stepping 0
set manual 0
set nestlevel 0
set theKey 0
set keywaiting 1
set ip 0
set waiting_for_key 0
set key_question 0
set latest_key 0
set at_target 0

set history(0) ""
set history(1) ""
set history(2) ""
set history(3) ""
set history(4) ""
set history(5) ""
set history(6) ""
set history(7) ""
set historypointer 0

if {[file exists ./amrflook.tcl]} {
    source ./amrflook.tcl
}

qsource amrbasic.tcl

set datelog ""
if {[file exists $homepath/date.tcl]} {
    source $homepath/date.tcl
}

set version "amrForth v6.4.x $datelog"
# Version number.
proc identify {} {
	global version
	wm title .  "$version   [pwd]"
}
identify

set fileName " "
set saveTextMsg 0
set winTitle " "

# Fonts.                # ALL20030705
font create default -family courier -size $default_size
proc font-size {size} {font configure default -size $size}
proc font-micro {} {font-size 8}
proc font-tiny {} {font-size 10}
proc font-medium {} {font-size 12}
proc font-large {} {font-size 14}
proc font-huge {} {font-size 16}
proc font-huger {} {font-size 18}
proc current-size {} {
	array set this [font actual default]
	return $this(-size)
}

# Create a file named myfont.tcl with this line in it:
# set myfavoritefont "-*-*-medium-r-normal--20-*-*-*-c-*-iso8859-*"
# for example, to specify your own favorite font by its unix style name.
proc resetfont {} {
	global myfont
	if {[file exists myfont.tcl]} {
		source myfont.tcl
		set myfont $myfavoritefont
	} else {
		set myfont [font actual default]
	}
}

# GUI widgets.

# From the book, "Practical Programming in Tcl and Tk",
# by Brent B. Welch
proc Pane_Create {f1 f2 args} {
    
    # Map optional arguments into array values
    set t(-orient) vertical
    set t(-percent) 0.5
    set t(-in) [winfo parent $f1]
    array set t $args
    
    # Keep state in an array associated with the master frame
    set master $t(-in)
    upvar #0 Pane$master pane
    array set pane [array get t]
    
    # Create the grip and set placement attributes that
    # will not change.  A thin divider line is achieved by
    # making the two frames one pixel smaller in the
    # adjustable dimension and making the main frame black.

    set pane(1) $f1
    set pane(2) $f2
    set pane(grip) [frame $master.grip -background gray50 \
        -width 10 -height 10 -bd 1 -relief raised \
        -cursor crosshair]
    if {[string match vert* $pane(-orient)]} {
        set pane(D) Y ;# Adjust boundary in Y direction
        place $pane(1) -in $master -x 0 -rely 0.0 -anchor nw \
            -relwidth 1.0 -height -1
        place $pane(2) -in $master -x 0 -rely 1.0 -anchor sw \
            -relwidth 1.0 -height -1
        place $pane(grip) -in $master -anchor c -relx 0.8
    } else {
        set pane(D) X ;# Adjust boundary in X direction
        place $pane(1) -in $master -relx 0.0 -y 0 -anchor nw \
            -relheight 1.0 -width -1
        place $pane(2) -in $master -relx 1.0 -y 0 -anchor ne \
            -relheight 1.0 -width -1
        place $pane(grip) -in $master -anchor c -rely 0.8
    }
    $master configure -background black

    # Set up bindings for resize, <Configure>, and
    # for dragging the grip.

    bind $master <Configure> [list PaneGeometry $master]
    bind $pane(grip) <ButtonPress-1> \
        [list PaneDrag $master %$pane(D)]
    bind $pane(grip) <B1-Motion> \
        [list PaneDrag $master %$pane(D)]
    bind $pane(grip) <ButtonRelease-1> \
        [list PaneStop $master]

    # Do the initial layout

    PaneGeometry $master
}

proc PaneDrag {master D} {
    global main_percent
    upvar #0 Pane$master pane
    if [info exists pane(lastD)] {
        set delta [expr double($pane(lastD) - $D) \
            / $pane(size)]
        set pane(-percent) [expr $pane(-percent) - $delta]
        if {$pane(-percent) < 0.0} {
            set pane(-percent) 0.0
        } elseif {$pane(-percent) > 1.0} {
            set pane(-percent) 1.0
        }
        set main_percent $pane(-percent)
        PaneGeometry $master
    }
    set pane(lastD) $D
}

proc PaneStop {master} {
    upvar #0 Pane$master pane
    catch {unset pane(lastD)}
}

proc PaneGeometry {master} {
    upvar #0 Pane$master pane
    if {$pane(D) == "X"} {
        place $pane(1) -relwidth $pane(-percent)
        place $pane(2) -relwidth [expr 1.0 - $pane(-percent)]
        place $pane(grip) -relx $pane(-percent)
        set pane(size) [winfo width $master]
    } else {
        place $pane(1) -relheight $pane(-percent)
        place $pane(2) -relheight [expr 1.0 - $pane(-percent)]
        place $pane(grip) -rely $pane(-percent)
        set pane(size) [winfo height $master]
    }
}

proc orient {master direction} {
    save-options-config
    show "Orientation will be $direction after restarting.\n"
    show-prompt
}

# End of code...
# From the book, "Practical Programming in Tcl and Tk",
# by Brent B. Welch

frame .p -width $main_width -height $main_height
pack .p -expand true -fill both
pack propagate .p off

# Create test (interpreter) window.
frame .p.t
set log [text .p.t.log -width 64 -height $text_height \
	-borderwidth 2 -relief raised -setgrid true \
	-wrap word -yscrollcommand {.p.t.scroll set} \
    -highlightthickness 3 -highlightcolor $hlColor \
	-insertbackground $cursorColor -font default]
$log tag configure target -foreground $fgTargetColor
$log tag configure mesg -foreground $fgMesgColor
scrollbar .p.t.scroll -command {$log yview}
pack .p.t.scroll -side right -fill y
# Create info line for interpreter.
frame .p.t.i -borderwidth 2
pack .p.t.i -side bottom -fill x
label .p.t.i.info
pack .p.t.i.info -side left
pack $log -side left -fill both -expand true
pack .p.t -side top -fill both -expand true

# Create editor window.
frame .p.e
set edit_log [text .p.e.log -width 64 -height $editor_height \
	-borderwidth 2 -relief raised -setgrid true \
	-wrap word -yscrollcommand {.p.e.scroll set} \
    -highlightthickness 3 -highlightcolor $hlColor \
	-insertbackground $cursorColor -font default]
scrollbar .p.e.scroll -command {.p.e.log yview}
pack .p.e.scroll -side right -fill y
# Create info line for editor.
frame .p.e.i -borderwidth 2
pack .p.e.i -side bottom -fill x
label .p.e.i.info
pack .p.e.i.info -side left
pack $edit_log -side left -fill both -expand true
pack .p.e -side top -fill both -expand true

# Create menus and assign their functions.

Pane_Create .p.t .p.e -in .p -orient $orientation -percent $main_percent

menu .menubar
. config -menu .menubar
foreach m {File Edit Search Compiler Debugger Decompiler \
    Programmer Options Help} {
	set $m [menu .menubar.m$m]
	.menubar add cascade \
	-label $m \
	-underline 0 \
	-menu .menubar.m$m
}

$File add command -label "New" -underline 0 \
	-command "filesetasnew"
$File add command -label "Open" -underline 0 \
	-command "filetoopen" -accelerator Ctrl+o
$File add command -label "Save" -underline 0 \
	-command "filetosave" -accelerator Ctrl+s
$File add command -label "Save As" -underline 5 \
	-command filesaveas
$File add separator
$File add command -label "View Logs" -underline 0 \
    -command logtoopen
$File add separator
$File add command -label "New Project" -underline 2 \
	-command "new-project 1"
$File add command -label "Update Project" -underline 0 \
	-command "new-project 0"
$File add command -label "Open Project" -underline 5 \
	-command open-project
$File add separator
$File add command -label "Quit  \"bye\"" -underline 0 \
	-command exitapp

$Edit add command -label "Cut" -underline 2 \
	-accelerator Ctrl+x -command cuttext
$Edit add command -label "Copy" -underline 0 \
	-accelerator Ctrl+c -command copytext
$Edit add command -label "Paste" -underline 0 \
	-accelerator Ctrl+v -command pastetext
$Edit add command -label "Delete" -underline 0 \
	-command deletetext
$Edit add separator	
$Edit add command -label "Select All" -underline 0 \
	-command selectall -accelerator Ctrl+a
$Edit add command -label "Time/Date" -underline 0 \
	-command printtime
$Edit add separator
$Edit add command -label "Edit Source" -underline 0 \
	-command edit-word -accelerator e

$Search add command -label "Find" -underline 0 \
	-command "findtext find" -accelerator Ctrl+f
$Search add command -label "Find Next" -underline 5 \
	-command "findnext find" -accelerator F3
$Search add command -label "Replace" -underline 0 \
	-command "findtext replace"

$Compiler add command -label "Compile  \"c\"" -underline 0 \
	-command run-compiler-menu
$Compiler add command -label "Turnkey  \"t\"" -underline 0 \
	-command run-rommer-menu
$Compiler add separator
$Compiler add command -label "Download RS232  \"d\"" -underline 0 \
	-command run-downloader-menu

$Debugger add command -label "Word     \"step\"" -underline 0 \
    -command step-from-menu
$Debugger add command -label "Step  \"<space>\"" -underline 0 \
    -command one-step
$Debugger add command -label "Nest        \"n\"" -underline 0 \
    -command nesting-step
$Debugger add command -label "Skip        \"s\"" -underline 1 \
    -command skip-step
$Debugger add command -label "Forth       \"f\"" -underline 0 \
    -command temp-forth
$Debugger add command -label "Quit \"<escape>\"" -underline 0 \
    -command {stop-stepping ; focus $log}

$Decompiler add command -label "Word      \"see\"" -underline 0 \
    -command see-from-menu

$Programmer add cascade -label "JTAG  \"jtag\"" -underline 0 \
	-menu $Programmer.jtag
$Programmer add separator
$Programmer add cascade -label "C2  \"c2\"" -underline 0 \
	-menu $Programmer.c2

menu $Programmer.jtag
$Programmer.jtag add command -label "Download" -underline 1 \
	-command jtag-download-menu
$Programmer.jtag add separator
$Programmer.jtag add command -label "Erase" -underline 0 \
	-command jtag-erase-menu
$Programmer.jtag add separator
$Programmer.jtag add command -label "Dump" -underline 0 \
	-command jtag-dump-menu
$Programmer.jtag add command -label "Next  \"n\"" -underline 0 \
	-command jtag-next-menu
$Programmer.jtag add command -label "Halt" -underline 0 \
	-command jtag-halt-menu
$Programmer.jtag add command -label "Suspend" -underline 0 \
	-command jtag-suspend-menu
$Programmer.jtag add command -label "Reset" -underline 0 \
	-command jtag-reset-menu
$Programmer.jtag add command -label "Run" -underline 1 \
	-command jtag-run-menu

menu $Programmer.c2
$Programmer.c2 add command -label "Download" -underline 1 \
	-command c2-download-menu
$Programmer.c2 add separator
$Programmer.c2 add command -label "Erase" -underline 0 \
	-command c2-erase-menu
$Programmer.c2 add separator
$Programmer.c2 add command -label "Dump" -underline 0 \
	-command c2-dump-menu
$Programmer.c2 add command -label "Next  \"n\"" -underline 0 \
	-command c2-next-menu

$Options add command -label "Configure  \"config\"" -underline 0 \
    -command dialog-config
$Options add cascade -label "Schema" -underline 0 \
    -menu $Options.schema
$Options add cascade -label "Browser" -underline 0 \
	-menu $Options.browser
$Options add command -label "Toggle Timer" -underline 0 \
    -command toggletimer
$Options add command -label "Save Look and Feel" -underline 0 \
	-command save-look-and-feel

menu $Options.schema
$Options.schema add cascade -label "Font" -underline 0 \
	-menu $Options.font
$Options.schema add cascade -label "Colors" -underline 2 \
	-menu $Options.colors
$Options.schema add command -label "Horizontal" -underline 0 \
    -command horizontal-orientation
$Options.schema add command -label "Vertical" -underline 0 \
    -command vertical-orientation

menu $Options.kernel
$Options.kernel add command -label "RS232 Interrupts" \
    -command interrupts-kernel
$Options.kernel add command -label "RS232 Polled" \
    -command polled-kernel

menu $Options.font
# ALL20030705
$Options.font add command -label " 8 point" -underline 0 \
	-command font-micro
$Options.font add command -label "10 point" -underline 1 \
	-command font-tiny
$Options.font add command -label "12 point" -underline 1 \
	-command font-medium
$Options.font add command -label "14 point" -underline 1 \
	-command font-large
$Options.font add command -label "16 point" -underline 1 \
	-command font-huge
$Options.font add command -label "18 point" -underline 3 \
	-command font-huger

menu $Options.colors
$Options.colors add command -label "black on gray" \
	-command black_on_gray
$Options.colors add command -label "black on white" \
	-command black_on_white
$Options.colors add command -label "green on black" \
	-command green_on_black
$Options.colors add cascade -label "custom colors" \
	-menu $Options.colors.custom

menu $Options.colors.custom
$Options.colors.custom add command -label "Background Color" \
    -command choose_background_color
$Options.colors.custom add command -label "Host FG Color" \
    -command choose_host_FG_color
$Options.colors.custom add command -label "Target FG Color" \
    -command choose_target_FG_color
$Options.colors.custom add command -label "Insert Cursor Color" \
    -command choose_insert_color
$Options.colors.custom add command -label "Highlight Color" \
    -command choose_highlight_color

menu $Options.browser
if {$using_windows} {
$Options.browser add command -label "Internet Explorer" \
	-command use-IE
}
$Options.browser add command -label "Choose Browser" \
	-command change-browser

$Help add command -label "Manual" -underline 0 \
	-command run-browser-local -accelerator F1
$Help add command -label "Online" -underline 0 \
	-command run-browser-online -accelerator F2

# Keyboard bindings.
bind All <Alt-F> {}
bind All <Alt-E> {}
bind All <Alt-S> {}
bind ALL <Alt-H> {}
bind Text <Control-o> {}
bind Text <Control-f> {}

# Both windows.
bind . <Control-o> {filetoopen ; break}
bind . <Control-s> {filetosave ; break}
bind . <F1> {run-browser-local ; break}
bind . <F2> {run-browser-online ; break}

# Editor window.
bind $edit_log <Control-x> {cuttext ; break}
bind $edit_log <Control-c> {copytext ; break}
bind $edit_log <Control-v> {pastetext ; break}
bind $edit_log <Control-a> {selectall ; break}
bind $edit_log <Key> inccount
bind $edit_log <Control-f> {findtext find ; break}
bind $edit_log <Control-r> {findtext replace ; break}
bind $edit_log <F3> {findnext find ; break}

# Interpreter window.
bind $log <Shift-Right> {focus $edit_log ; break}
bind $log <Shift-Left> {focus $edit_log ; break}
bind $log <BackSpace> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set native [encoding convertto $temp]
            binary scan $native c latest_key
        }
        break
    }
	bottom
	if {[$log compare insert > limit]} {
		$log delete insert-1c
		$log see insert
	}
	break
}
bind $log <Up> {bottom ; up-arrow ; break}
bind $log <Down> {bottom ; down-arrow ; break}
bind $log <Left> {bottom ; break}
bind $log <Right> {bottom ; break}

bind $log <Escape> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set native [encoding convertto $temp]
            binary scan $native c latest_key
        }
        break
    }
    if {$stepping} {
        stop-stepping
        break
    } else {
        if {$manual} {
            set stepping 1
            set manual 0
            execute-word $kernelword(dots)
            show-next-word
            break
        }
        bottom
        bailout
    }
}

proc temp-forth {} {
    global manual stepping log
    set manual 1
    set stepping 0
    show-mesg "\nPress <Esc> to continue stepping"
    show-prompt
    focus $log
}

bind $log <f> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set native [encoding convertto $temp]
            binary scan $native c latest_key
        }
        break
    }
    if {$stepping} {
        temp-forth
        break
    }
}

bind $log <s> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set this [encoding convertto $temp]
            binary scan $this c latest_key
        }
        break
    }
    if {$stepping} {
        skip-step
        break
    }
}

bind $log <space> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set this [encoding convertto $temp]
            binary scan $this c latest_key
        }
        break
    }
    set keypressed 1
    if {$stepping == 1} {
        one-step
        break
    }
}

bind $log <n> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set this [encoding convertto $temp]
            binary scan $this c latest_key
        }
        break
    }
    if {$stepping == 1} {
        nesting-step
        break
    }
}

bind $log <Return> {
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set this [encoding convertto $temp]
            binary scan $this c latest_key
        }
        break
    }
    if {$stepping == 1} {
        one-step
        break
    } else {
        bottom
        run-interpreter
        break
    }
}

bind $edit_log <Shift-Right> {focus $log ; break}
bind $edit_log <Shift-Left> {focus $log ; break}
bind $log <Key> {
    bottom
    if {$waiting_for_key == 1} {
        set temp %A
        if {$temp != {}} {
            set key_question 1
            set this [encoding convertto $temp]
            binary scan $this c latest_key
        }
        break
    }
}

# Test window.

$log mark set tib end

proc horizontal-orientation {} {
    global orientation
    set orientation "horizontal"
    orient .p $orientation
    save-look-and-feel
}

proc vertical-orientation {} {
    global orientation
    set orientation "vertical"
    orient .p $orientation
    save-look-and-feel
}

# Move cursor to bottom of file.
proc bottom {} {
	global log
	if {[$log compare insert < limit]} {
		$log mark set insert end
		$log see insert
	}
}

# Place text in the interpreter window.
proc show {string} {
	global log
	$log insert insert $string
	$log see insert
	update
}

proc show-target {string} {
	global log
	$log insert insert $string {target}
	$log see insert
	update
}

proc show-mesg {string} {
    global log
    $log insert insert $string {mesg}
    $log see insert
    update
}

proc update-info {} {
	global processor commname project infotext mode fileName \
		freq baudrate fgColor bgColor saveTextMsg kernel log \
        fgTargetColor cursorColor hlColor edit_log
	set current_file [file tail $fileName]
    .p.e.i.info configure -text \
    "Editor: $current_file"
    if [catch {set freqq [expr $freq / 1000000.0]}] {
        set freqq 0
    }
	.p.t.i.info configure -text \
	"Interpreter:  $processor  $freqq MHz   $commname  $baudrate  $kernel"
	tk_setPalette background $bgColor foreground $fgColor
    $log tag configure target -foreground $fgTargetColor
    $log configure -insertbackground $cursorColor
    $log configure -highlightcolor $hlColor
    $edit_log configure -insertbackground $cursorColor
    $edit_log configure -highlightcolor $hlColor
	identify
    PaneGeometry .p
	update
}

proc black_on_gray {} {
	global fgColor bgColor
	set fgColor black
	set bgColor LightGray
	update-info
}

proc black_on_white {} {
	global fgColor bgColor
	set fgColor black
	set bgColor white
	update-info
}

proc green_on_black {} {
	global fgColor bgColor
	set fgColor green
	set bgColor black
	update-info
}

proc choose_host_FG_color {} {
	global fgColor
	set fgColor [tk_chooseColor -title "Host Foreground"]
	update-info
}

proc choose_background_color {} {
	global bgColor
	set bgColor [tk_chooseColor -title "Background"]
	update-info
}

proc choose_target_FG_color {} {
	global fgTargetColor
	set fgTargetColor [tk_chooseColor -title "Target Foreground"]
	update-info
}

proc choose_highlight_color {} {
	global hlColor
	set hlColor [tk_chooseColor -title "Highlight Border"]
	update-info
}

proc choose_insert_color {} {
	global cursorColor
	set cursorColor [tk_chooseColor -title "Insert Cursor"]
	update-info
}

# Serial Ports and downloader.

set comfid 0

proc close-comm {} {
	global comfid
	if {$comfid != 0} {
		close $comfid
		set comfid 0
	}
}

proc open-comm {} {
	global comfid commname processor baudrate
	close-comm
	if [catch {open $commname r+} comfid] {
		show-prompt
		error "Can't open $commname: $comfid"
	} else {
		fconfigure $comfid -mode $baudrate,n,8,1 \
		-buffering none -translation binary \
		-blocking 0
	}
}

proc open-com1 {} {
	choose-com1
	update-info
	open-comm
}

proc open-com2 {} {
	choose-com2
	update-info
	open-comm
}

proc com1-string {} {
    global using_windows
	if {$using_windows} {
		return "com1"
	} else {
		return "/dev/ttyS0"
	}
}

proc com2-string {} {
    global using_windows
	if {$using_windows} {
		return "com2"
	} else {
		return "/dev/ttyS1"
	}
}

proc choose-com1 {} {
	global commname comport
	set comport 1
    set commname [com1-string]
}

proc choose-com2 {} {
	global commname comport
	set comport 2
    set commname [com2-string]
}

proc open-comport {} {
	global comport
	close-comm
	if {$comport == 1} {open-com1}
	if {$comport == 2} {open-com2}
}

proc emit-s {char} {
	global comfid
	puts -nonewline $comfid $char
}

# Returns "" if no character available,
# otherwise returns the available character.
# proc old-key?-s {} {
#	global comfid
#	catch {read $comfid 1} char
#	return $char
# }
# Found the -queue option on the web, not in the Tcl book we have.
# 20May2004 Chas.
proc key?-s {} {
	global comfid
	set flag [fconfigure $comfid -queue]
	if {[lindex $flag 0] == 0} {
		return ""
	} else {
		catch {read $comfid 1} char
		return $char
	}
}

proc clear-sbuf {} {
	global comfid
	set char [key?-s]
	while {[string compare $char ""]} {
		set char [key?-s]
	}
}

proc handle-char {} {
	global comfid done character
	set character [read $comfid 1]
	set done 1
}

proc key-s {} {
	global comfid done character
	set done 0
	fileevent $comfid readable handle-char
	tkwait variable done
	catch [fileevent $comfid readable ""]
	return $character
}

proc handle-chars {} {
	global comfid done characters
	set characters [read $comfid]
	set done 1
}

proc keys-s {} {
	global comfid done characters
	set done 0
	fileevent $comfid readable handle-chars
	tkwait variable done
	catch [fileevent $comfid readable ""]
	return $characters
}

proc bailout {} {
	global done finished
	set done 1
	set finished 1
	show-prompt
	close-comm
	open-comm
	error "Escape key pressed"
}

proc using-cygnal {} {
	global processor
	if {[string equal $processor "C8051F30x"]} {return 1}
	if {[string equal $processor "C8051F0xx"]} {return 1}
	if {[string equal $processor "C8051F31x"]} {return 1}
	if {[string equal $processor "C8051F06x"]} {return 1}
	return 0
}

proc open-object-file {} {
	global data romHERE number_pages bytes_left binfid
	if {[catch {file size "rom.bin"} romHERE]} {
		show-prompt
		error "Problem sizing rom.bin"
	}
	if {[using-cygnal]} {
		set n [expr $romHERE - 0x200]
		set r [expr $n & 511]
		set q [expr $n / 512]
	} else {
		set r [expr $romHERE & 511]
		set q [expr $romHERE / 512]
	}
	if {$r != 0} {incr q}
	set number_pages $q
	set bytes_left $r
	if {[catch {open "rom.bin" r} binfid]} {
		show-prompt
		error "Problem opening rom.bin"
	} else {
		fconfigure $binfid -translation binary
	}
}

proc close-object-file {} {
	global binfid
	close $binfid
	set binfid 0
}

proc get-key {} {
    global waiting_for_key key_question latest_key kernelword
    if {$key_question != 1} {
        set waiting_for_key 1
        tkwait variable key_question
    }
    set key_question 0
    set waiting_for_key 0
    return $latest_key
}

proc simulate-key {} {
    set latest_key [get-key]
    send-number $latest_key
}

proc simulate-keyquestion {} {
    global waiting_for_key key_question latest_key kernelword
    if {$key_question != 1} {
        set waiting_for_key 1
        tkwait variable key_question
        set waiting_for_key 0
    }
    set this $key_question
    if {$key_question != 0} {set this -1}
    send-number $this
}

# In Tcl avoid showing the carriage returns.
proc old-listen {} {
	global log listen_char finished
	set finished 0
	set listen_char [key-s]
	if {$listen_char == [binary format c 7]} {
		return
	}
	if {$listen_char == [binary format c 1]} {
		simulate-key
	} else {
		if {$listen_char == [binary format c 2]} {
			simulate-keyquestion
		} else {
			if {$listen_char != [binary format c 13]} {
				if {$listen_char == [binary format c 10]} {
					set time [currenttime]
					show " $time"
				}
				show-target $listen_char
			}
		}
	}
	while {$finished == 0} {
		set listen_char [key-s]
		if {$listen_char == [binary format c 7]} {
			break
		}
		if {$listen_char == [binary format c 1]} {
			simulate-key
		} else {
			if {$listen_char == [binary format c 2]} {
				simulate-keyquestion
			} else {
				if {$listen_char != [binary format c 13]} {
					if {$listen_char == [binary format c 10]} {
						set time [currenttime]
						show " $time"
					}
					show-target $listen_char
				}
			}
		}
	}
}

# In Tcl avoid showing the carriage returns.
proc listen {} {
	global log listen_char finished
	set finished 0
	set listen_line ""
	while {$finished == 0} {
		set listen_char [key-s]
		if {$listen_char > [binary format c 31]} {
			append listen_line $listen_char
			continue
		}
		if {$listen_char == [binary format c 7]} {
			show-target $listen_line
			set $listen_line ""
			break
		}
		if {$listen_char == [binary format c 10]} {
			set time [currenttime]
			show-target $listen_line
			show " $time\n"
			set listen_line ""
			continue
		}
		if {$listen_char == [binary format c 1]} {
			simulate-key
			continue
		}
		if {$listen_char == [binary format c 2]} {
			simulate-keyquestion
			continue
		}
	}
}

proc start-word {num} {
	set highbyte [expr $num / 256]
	set lowbyte [expr $num & 255]
	clear-sbuf
	set x [binary format c 2]
	emit-s $x
	set x [binary format c $lowbyte]
	emit-s $x
	set x [binary format c $highbyte]
	emit-s $x
}

proc execute-word {num} {
	global timing
	start-word $num
	set this [clock clicks -milliseconds]
	listen
	set that [clock clicks -milliseconds]
	if {$timing} {
		set elapsed [expr $that - $this]
		show "$elapsed ms "
	}
}

proc execute-number {num} {
	set highbyte [expr $num / 256]
	set lowbyte [expr $num & 255]
	clear-sbuf
	set x [binary format c 1]
	emit-s $x
	set x [binary format c $lowbyte]
	emit-s $x
	set x [binary format c $highbyte]
	emit-s $x
	listen
}

proc send-number {num} {
	set highbyte [expr $num / 256]
	set lowbyte [expr $num & 255]
	clear-sbuf
	set x [binary format c $lowbyte]
	emit-s $x
	set x [binary format c $highbyte]
	emit-s $x
}

# Symbol table.

proc init-vocabulary {vocabulary} {
	if {[info exists $vocabulary]} {unset $vocabulary}
}

proc read-forth-symbol-table {} {
	global forth got-symbols input addresses
	if {[info exists forth]} {unset forth}
    if {[info exists addresses]} {unset addresses}
# Load the Forth symbol table.
	if [catch {open symbols.log r} input] {
		show $input
		show-prompt
	} else {
		set got-symbols 0
		fileevent $input readable readsymbol
		tkwait variable got-symbols
	}
    foreach {index value} [array get forth] {
        set addresses($value) $index
    }
}

proc read-hidden-symbols-table {} {
    global hiddenforth got-symbols input hiddenaddresses
    if {[info exists hiddenforth]} {unset hiddenforth}
    if [catch {open hiddensymbols.log r} input] {
        show $input
        show-prompt
    } else {
        set got-symbols 0
        fileevent $input readable readhidden
        tkwait variable got-symbols
    }
    foreach {index value} [array get hiddenforth] {
        set hiddenaddresses($value) $index
    }
}

proc read-exits-symbol-table {} {
    global exits got-symbols input
    if {[info exists exits]} {unset exits}
    if [catch {open exits.log r} input] {
        show $input
        show-prompt
    } else {
        set got-symbols 0
        fileevent $input readable readexits
        tkwait variable got-symbols
    }
}

proc read-stepper-source-table {} {
    global steppersource got-symbols input
    if {[info exists steppersource]} {unset steppersource}
    if [catch {open steppersource.log r} input] {
        show $input
        show-prompt
    } else {
        set got-symbols 0
        fileevent $input readable readsteppersource
        tkwait variable got-symbols
    }
}

proc read-immed-vocabulary {} {
    global immed got-symbols input
	if {[info exists immed]} {unset immed}
    if [catch {open immed.log r} input] {
        show $input
        show-prompt
    } else {
        set got-symbols 0
        fileevent $input readable readimmed
        tkwait variable got-symbols
    }
}

proc read-symbol-table {} {
    global kernelword
	read-forth-symbol-table
    read-hidden-symbols-table
    read-exits-symbol-table
	read-basic-symbol-table
    read-immed-vocabulary
    read-stepper-source-table
    read-rom.bin
	if {[info exists kernelword]} {unset kernelword}
    source "kernelwords.log"
}

proc read-input-line {} {
	global input name address
	gets $input asymbol
	set thesymbol [split $asymbol]
	set name [string tolower [lrange $thesymbol 1 1]]
	set address [lrange $thesymbol 2 2]
# Strip special list characters, { and }.    
    set str1 [string range $name 1 end-1]
    set str2 [list $str1]
    if {$str2 == $name} {set name $str1}
}

proc read-object-line {} {
    global input name address
    gets $input asymbol
    set thesymbol [split $asymbol]
    set name [lrange $thesymbol 0 0]
    set address [string tolower [lrange $thesymbol 1 1]]
}

proc readsymbol {} {
	global input name address got-symbols forth
	if {[eof $input]} {
		Stop_reading_symbols
		set got-symbols 1
		return
	}
	read-input-line
	set forth($name) $address
}

proc readhidden {} {
    global input name address got-symbols hiddenforth
    if {[eof $input]} {
        Stop_reading_symbols
        set got-symbols 1
        return
    }
    read-input-line
    set hiddenforth($name) $address
}

proc readexits {} {
    global input name address got-symbols exits
    if {[eof $input]} {
        Stop_reading_symbols
        set got-symbols 1
        return
    }
    read-input-line
    set exits($name) $address
}

proc readsteppersource {} {
    global input name address got-symbols steppersource
    if {[eof $input]} {
        Stop_reading_symbols
        set got-symbols 1
        return
    }
    read-input-line
    set steppersource($name) $address
}

proc readimmed {} {
    global input name address got-symbols immed
    if {[eof $input]} {
        Stop_reading_symbols
        set got-symbols 1
        return
    }
    gets $input immed
}

proc runner {script} {
	global log input done
	if [catch {open "|$script 2> errors.log"} input] {
		show "$input"
		show-prompt
	} else {
		fileevent $input readable Log
		set done 0
		tkwait variable done
	}
}

proc delete-file {name} {
	if {[file exists $name]} {file delete $name}
}

proc run-compiler {} {
	global homepath terminal using_windows gforthpath
	if {![file exists job.fs]} {
		set jobid [open job.fs w]
		puts $jobid "\\ job.fs\n"
		close $jobid
	}
	if {![file exists amrfconf.fs]} {
		show-prompt
		error "No config file, amrfconf.fs"
	}
	delete-file "rom.bin"
	delete-file "symbols.log"
    delete-file "immed.log"
    delete-file "hiddensymbols.log"
    delete-file "steppersource.log"
    delete-file "exits.log"
    delete-file "kernelwords.log"
	delete-basic-files
	show "Compiling Interactive System\n"
	set script \
	"$gforthpath -m 1M -e false ./compile.fs -e bye"
  	runner $script
	after 1000
	update
    read-symbol-table
#    run-downloader
}

proc run-compiler-menu {} {
	run-compiler
	show-prompt
}

proc run-rommer {} {
	global homepath using_windows terminal gforthpath
	if {![file exists job.fs]} {
        show-prompt
		error "You need to create a job.fs load file.\n"
	}
	if {![file exists amrfconf.fs]} {
        show-prompt
		error "No config file, amrfconf.fs"
	}
	delete-file "rom.hex"
	delete-file "rom.bin"
	delete-file "symbols.log"
    delete-file "immed.log"
    delete-file "hiddensymbols.log"
    delete-file "steppersource.log"
    delete-file "exits.log"
	delete-basic-files
	show "Compiling Turnkey System\n"
	set script \
    "$gforthpath -m 1M -e true ./compile.fs -e bye"
	runner $script
	after 1000
	update
    read-symbol-table
#    run-downloader
}

proc run-runner {} {
    run-compiler
    run-downloader
}

proc run-rommer-menu {} {
	run-rommer
	show-prompt
}

proc run-downloader-menu {} {
	run-downloader
	show-prompt
}

proc run-browser {url} {
	global browser using_windows
	if {$browser == ""} {
		show "Starting default browser"
		show-prompt
		if {$using_windows} {
			exec "/PROGRA~1/INTERN~1/IEXPLORE.EXE" $url &
		} else {
			exec mozilla $url &
		}
		return
	}
	show "Starting $browser"
    show-prompt
	exec $browser $url &
}

proc run-browser-online {} {
	global online_url
	run-browser $online_url
}

proc run-browser-local {} {
	global local_url
	run-browser $local_url
}

proc download-jtag-page {} {
	global binfid
	for {set i 0} {$i < 8} {incr i} {
		for {set j 0} {$j < 64} {incr j} {
			if {[catch {read $binfid 1} char]} {
				set char [binary format c 0]
			}
			emit-s $char
		}
		key-s
	}
}

proc _jtag-download {} {
	global number_pages binfid
	set pages [expr $number_pages + 1]
	clear-sbuf
	emit-s "jtag\n"
	show "512 byte pages: "
	set char [key-s]
	while {$char != "A"} {
		set char [key-s]
	}
	emit-s [binary format c $pages]
	for {set i 0} {$i < $pages} {incr i} {
		set j [expr $pages - $i - 1]
		show "$j "
		download-jtag-page
	}
}

proc _c2-download {} {
	global number_pages binfid
	set pages [expr $number_pages + 1]
	clear-sbuf
	emit-s "C2download\n"
	show "512 byte pages: "
	set char [key-s]
	while {$char != "A"} {
		set char [key-s]
	}
	emit-s [binary format c $pages]
	for {set i 0} {$i < $pages} {incr i} {
		set j [expr $pages - $i - 1]
		show "$j "
		download-jtag-page
	}
}

proc jtag-download {} {
	if {[hello-jtag] == 1} {return}
	if {[file exists rom.bin]} {
		show "Download rom.bin via JTAG\n"
		open-object-file
		_jtag-download
		close-object-file
	} else {
		show "No object file, rom.bin\n"
	}
	show "\n"
}

proc jtag-download-menu {} {
	jtag-download
	show-prompt
}

proc c2-download {} {
	if {[hello-jtag] == 1} {return}
	if {[file exists rom.bin]} {
		show "Download rom.bin via C2\n"
		open-object-file
		_c2-download
		close-object-file
	} else {
		show "No object file, rom.bin\n"
	}
}

proc c2-download-menu {} {
	c2-download
	show-prompt
}

proc copy_script {script flag} {
    global thispath
    if {![file exists $thispath/$script]} {
        show "$thispath/$script not there, not copied\n"
        return
    }
    if {$flag != 0} {
        if {[file exists ./$script]} {
            show "$script already exists, no changes made.\n"
            return
        }
    }
    file copy -force $thispath/$script .
}

proc copy_scripts {flag} {
    global homepath
    copy_script "amrf" $flag
	copy_script "amrf.bat" $flag
    copy_script "amrforth.tcl" $flag
    copy_script "amrbasic.tcl" $flag
    copy_script "asm8051.fs" $flag
    copy_script "basic.fs" $flag
    copy_script "bin2hex.fs" $flag
    copy_script "compile.fs" $flag
    copy_script "debug.fs" $flag
    copy_script "download-aduc.tcl" $flag
    copy_script "download-cygnal.tcl" $flag
    copy_script "download-80c552.tcl" $flag
    copy_script "end8051.fs" $flag
    copy_script "kernel8051.fs" $flag
    copy_script "metacomp.fs" $flag
    copy_script "sfr-31.fs" $flag
    copy_script "sfr-32.fs" $flag
    copy_script "sfr-537.fs" $flag
    copy_script "sfr-552.fs" $flag
    copy_script "sfr-812.fs" $flag
    copy_script "sfr-816.fs" $flag
    copy_script "sfr-f000.fs" $flag
    copy_script "sfr-f061.fs" $flag
    copy_script "sfr-f300.fs" $flag
    copy_script "sfr-f310.fs" $flag
    copy_script "vtags.fs" $flag
    copy_script "amrfconf.fs" $flag
    copy_script "amrfconf.tcl" $flag
    copy_script "amrflook.tcl" $flag
    copy_script "disassembler.tcl" $flag
    show-prompt
}

proc new-project {flag} {
	global project using_windows homepath thispath fgColor bgColor
    tk_setPalette background LightGray foreground black
	set project [tk_chooseDirectory -mustexist false -title "New Project"]
    tk_setPalette background $bgColor foreground $fgColor
	if {$project == ""} {return}
	file mkdir $project
    set thispath [pwd]
	cd $project
    copy_scripts $flag
	update-info
	if {[file exists "./amrfconf.tcl"]} {
		source ./amrfconf.tcl
	} else {
		show "You need to save a configuration, see Options menu.\n"
		show-prompt
	}
}

proc reconfigure {} {
	global project processor baudrate freq commname comport dlfile \
		homepath downloader sfrfile mode kernel
	if {[file exists "./amrfconf.tcl"]} {
		show "Loading configuration files."
		if {[file exists "./amrflook.tcl"]} {source "./amrflook.tcl"}
		source ./amrfconf.tcl
		if {$downloader != ""} {
			if {[file exists ./$downloader]} {
				source ./$downloader
			} else {
				source $homepath/$downloader
			}
		}
		open-comport
	} else {
		show "You need to save a configuration, see Options menu.\n"
	}
	show-prompt
}

proc change-FGcolor {} {
	global fgColor bgColor
	set fgColor [tk_chooseColor]
	tk_setPalette background $bgColor foreground $fgColor
}

proc change-BGcolor {} {
	global fgColor bgColor
	set bgColor [tk_chooseColor]
	tk_setPalette background $bgColor foreground $fgColor
}

proc save-options {} {
	global processor commname sfrfile freq th1 smod \
		romstart kernel downloader baudrate fgColor bgColor \
		browser comport mode
	set fid [open ./amrfconf.tcl w]
	puts $fid "set processor \"$processor\""
	puts $fid "set baudrate \"$baudrate\""
	puts $fid "set freq $freq"
	puts $fid "set th1 $th1"
	puts $fid "set smod $smod"
	puts $fid "set romstart $romstart"
	puts $fid "set kernel \"$kernel\""
	puts $fid "set sfrfile \"$sfrfile\""
	puts $fid "set downloader \"$downloader\""
	if {$comport == 0} {
		puts $fid "choose-no-comm"
	}
	if {$comport == 1} {
		puts $fid "choose-com1"
	}
	if {$comport == 2} {
		puts $fid "choose-com2"
	}
	close $fid
	reconfigure
}

proc save-config {} {
	global freq th1 smod romstart sfrfile kernel
	set fid [open ./amrfconf.fs w]
	puts $fid "create frequency $freq ,"
	puts $fid "$th1 constant default-TH1"
	puts $fid "$smod constant smod?"
	puts $fid "$romstart constant rom-start"
	puts $fid "create $kernel"
	puts $fid ": sfr-file  s\" $sfrfile\" ;"
	close $fid
}

proc save-look-and-feel {} {
	global browser fgColor bgColor homepath edit_log log \
        main_percent orientation cursorColor hlColor \
        fgTargetColor mode timing
	set fid [open  ./amrflook.tcl w]
	puts $fid "set browser \"$browser\""
	puts $fid "set fgColor \"$fgColor\""
	puts $fid "set bgColor \"$bgColor\""
    puts $fid "set fgTargetColor \"$fgTargetColor\""
    puts $fid "set cursorColor \"$cursorColor\""
    puts $fid "set hlColor \"$hlColor\""
	puts $fid "set default_size [current-size]"
    set mh [winfo height .p]
    set mw [winfo width .p]
    puts $fid "set main_height $mh"
    puts $fid "set main_width $mw"
    puts $fid "set main_percent $main_percent"
    puts $fid "set orientation $orientation"
    puts $fid "set mode \"$mode\""
    puts $fid "set timing $timing"
	close $fid
}

proc save-options-config {} {
	save-options
	save-config
    save-look-and-feel
}

proc update-processor-freq-config {} {
    global conf processor freq baudrate
    .conf.procframe.proc configure -text $processor
    set freqq [expr $freq / 1000000.0]
    .conf.procframe.lab2 configure -text "$freqq MHz"
    update-info
}

proc f30x-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "C8051F30x"
	set sfrfile "sfr-f300.fs"
	set baudrate 9600
	set freq 24500000
	set th1 250
	set smod true
	set romstart 611
	set kernel "polled-kernel"
	set downloader "download-cygnal.tcl"
    update-processor-freq-config
}

proc f31x-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "C8051F31x"
	set sfrfile "sfr-f310.fs"
	set baudrate 9600
	set freq 24500000
	set th1 250
	set smod true
	set romstart 635
	set kernel "polled-kernel"
	set downloader "download-cygnal.tcl"
    update-processor-freq-config
}

proc f0xx-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "C8051F0xx"
	set sfrfile "sfr-f000.fs"
	set baudrate 9600
	set freq 24000000
	set th1 243
	set smod true
	set romstart 691
	set kernel "polled-kernel"
	set downloader "download-cygnal.tcl"
    update-processor-freq-config
}

proc f06x-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "C8051F06x"
	set sfrfile "sfr-f061.fs"
	set baudrate 9600
	set freq 24500000
	set th1 97
	set smod true
	set romstart 691
	set kernel "polled-kernel"
	set downloader "download-cygnal.tcl"
    update-processor-freq-config
}

proc interrupts-kernel {} {
    global kernel
    set kernel "interrupts-kernel"
    update-info
}

proc polled-kernel {} {
    global kernel
    set kernel "polled-kernel"
    update-info
}

proc aduc812-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "ADuC812"
	set sfrfile "sfr-812.fs"
	set baudrate 9600
	set freq 11059200
	set th1 250
	set smod true
	set romstart 75
	set kernel "interrupts-kernel"
	set downloader "download-aduc.tcl"
    update-processor-freq-config
}

proc aduc816-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "ADuC816"
	set sfrfile "sfr-816.fs"
	set baudrate 9600
	set freq 12589120
	set th1 249
	set smod true
	set romstart 75
	set kernel "interrupts-kernel"
	set downloader "download-aduc.tcl"
    update-processor-freq-config
}

proc 80c552-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "80c552"
	set sfrfile "sfr-552.fs"
	set baudrate 19200
	set freq 11059200
	set th1 253
	set smod true
	set romstart [expr 0x8000 + 0x7b]
	set kernel "polled-kernel"
	set downloader "download-80c552.tcl"
    update-processor-freq-config
}

proc 80c537-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "80c537"
	set sfrfile "sfr-537.fs"
	set baudrate 19200
	set freq 11059200
	set th1 253
	set smod true
	set romstart [expr 0x8000 + 0x8b]
	set kernel "polled-kernel"
	set downloader "download-80c552.tcl"
    update-processor-freq-config
}

proc 8032-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "8032"
	set sfrfile "sfr-32.fs"
	set baudrate 19200
	set freq 11059200
	set th1 253
	set smod true
	set romstart [expr 0x8000 + 0x7b]
	set kernel "polled-kernel"
	set downloader "download-80c552.tcl"
    update-processor-freq-config
}

proc 8031-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "8031"
	set sfrfile "sfr-31.fs"
	set baudrate 19200
	set freq 11059200
	set th1 253
	set smod true
	set romstart [expr 0x8000 + 0x7b]
	set kernel "polled-kernel"
	set downloader "download-80c552.tcl"
    update-processor-freq-config
}

proc C51RC2-processor {} {
	global processor sfrfile freq th1 smod \
		romstart kernel downloader baudrate
	set processor "C51RC2"
	set sfrfile "sfr-C51RC2.fs"
	set baudrate 19200
    set freq 22118400
    set th1 250
	set smod true
	set romstart [expr 0 + 0x4b]
	set kernel "polled-kernel"
	set downloader "download-atmel.tcl"
    update-processor-freq-config
}

# ----- Dialog creation,
#  from "Practical Programming in Tcl and Tk"
#  by Brent B. Welch

proc Dialog_Create {top title args} {
	global dialog
	if [winfo exists $top] {
		switch -- [wm state $top] {
			normal {
				# Raise a buried window
				raise $top
			}
			withdrawn -
			iconic {
				# Open and restore geometry
				wm deiconify $top
				catch {wm geometry $top \
					$dialog(geo,$top)}
			}
		}
		return 0
	} else {
		eval {toplevel $top} $args
		wm title $top $title
		return 1
	}
}

proc Dialog_Wait {top varName {focus {}}} {
	upvar $varName var
	
	# Poke the variable if the user nukes the window
	bind $top <Destroy> [list set $varName cancel]

	# Grab focus for the dialog
	if {[string length $focus] == 0} {
		set focus $top
	}
	set old [focus -displayof $top]
	focus $focus
	catch {tkwait visibility $top}
	catch {grab $top}

	# Wait for the dialog to complete
	tkwait variable $varName
	catch {grab release $top}
	focus $old
}

# # This procedure doesn't work as advertised.
# # There is a work-around in "dialog-prompt".
# proc Dialog_Dismiss {top} {
#    global dialog
#    # Save current size and position
#    catch {
#        # window may have been deleted
#        set dialog (geo,$top) [wm geometry $top]
#        wm withdraw $top
#    }
# }

proc save-or-restore-config {} {
    global conf
    if {$conf(save) == 1} {
        show "Saving new configuration.\n"
        save-options-config
    }
    if {$conf(save) == 0} {
        show "Restoring original configuration.\n"
        reconfigure
    }
}

proc handle-close-config {widget} {
    global conf
	save-or-restore-config
    destroy $widget
}

proc dialog-config {} {
    global conf processor commname comport kernel freq baudrate
	set conf(save) 0
    set f .conf
    if [Dialog_Create $f "Configure" -borderwidth 10] {
        wm protocol $f WM_DELETE_WINDOW {handle-close-config .conf} 
        wm resizable $f 0 0
        set xx [winfo screenwidth .]
        set yy [winfo screenheight .]
        set x [expr ($xx/2) - 100]
        set y [expr ($yy/2) - 100]
        wm geometry $f +$x+$y
        # ----- Choosing a processor ----- #
        set pf [frame $f.procframe]
        pack $pf -side top -fill x
        set pl [label $pf.lab -text "Processor defaults"]
        pack $pl -side left -fill x
        set pmb [menubutton $pf.proc -text $processor -menu \
            $pf.proc.menu -relief raised]
        pack $pmb -side right -padx 10 -pady 10
        set pm [menu $pf.proc.menu -tearoff 1]
        if [catch {set freqq [expr $freq / 1000000.0]}] {
            set freqq 0
        }
        set pl2 [label $pf.lab2 -text "$freqq MHz"]
        pack $pl2 -side right -padx 10 -pady 10
        $pm add radio -label "C8051F0xx" \
            -variable processor -value "C8051F0xx" \
            -command f0xx-processor
        $pm add radio -label "C8051F06x" \
            -variable processor -value "C8051F06x" \
            -command f06x-processor
        $pm add radio -label "C8051F30x" \
            -variable processor -value "C8051F30x" \
            -command f30x-processor
        $pm add radio -label "C8051F31x" \
            -variable processor -value "C8051F31x" \
            -command f31x-processor
        $pm add radio -label "ADuC812" \
            -variable processor -value "ADuC812" \
            -command aduc812-processor
        $pm add radio -label "ADuC816" \
            -variable processor -value "ADuC816" \
            -command aduc816-processor
        $pm add radio -label "80c552" \
            -variable processor -value "80c552" \
            -command 80c552-processor
        $pm add radio -label "80c537" \
            -variable processor -value "80c537" \
            -command 80c537-processor
        $pm add radio -label "8031" \
            -variable processor -value "8031" \
            -command 8031-processor
        $pm add radio -label "8032" \
            -variable processor -value "8032" \
            -command 8032-processor
        $pm add radio -label "C51RC2" \
            -variable processor -value "C51RC2" \
            -command C51RC2-processor
        # ----- Choosing a comm port ----- #
        set cf [frame $f.commframe]
        pack $cf -side top -fill x
        set cl [label $cf.lab -text "Comm Port"]
        pack $cl -side left -fill x
        set cmb [menubutton $cf.comm -text $commname -menu \
            $cf.comm.menu -relief raised]
        pack $cmb -side right -padx 10 -pady 10
        set cm [menu $cf.comm.menu -tearoff 1]
        set cl2 [label $cf.lab2 -text "$baudrate baud"]
        pack $cl2 -side right -padx 10 -pady 10
        $cm add radio -label [com1-string] \
            -variable comport -value 1 \
            -command {
                open-com1
                .conf.commframe.comm configure -text [com1-string]
                .conf.commframe.lab2 configure -text "$baudrate baud"
                update-info
            }
        $cm add radio -label [com2-string] \
            -variable comport -value 2 \
            -command {
                open-com2
                .conf.commframe.comm configure -text [com2-string]
                .conf.commframe.lab2 configure -text "$baudrate baud"
                update-info
            }
        # ----- Choosing RS232 polled or interrupts ----- #
        set rf [frame $f.rs232frame]
        pack $rf -side top -fill x
        set rl [label $rf.lab -text "RS232 Mode"]
        pack $rl -side left -fill x
        set rmb [menubutton $rf.kern -text $kernel -menu \
            $rf.kern.menu -relief raised]
        pack $rmb -side right -padx 10 -pady 10
        set rm [menu $rf.kern.menu -tearoff 1]
        $rm add radio -label "RS232 Polled" \
            -variable kernel -value "polled-kernel" \
            -command {
                .conf.rs232frame.kern configure -text $kernel
                update-info
            }
        $rm add radio -label "RS232 Interrupts" \
            -variable kernel -value "interrupts-kernel" \
            -command {
                .conf.rs232frame.kern configure -text $kernel
                update-info
            }
        # ----- Saving or cancelling ----- #
        set b [frame $f.buttons]
		pack $f.buttons -side bottom -fill x
		button $b.save -text Save -command {set conf(save) 1}
		button $b.cancel -text Cancel \
			-command {set conf(save) 0}
		pack $b.save -side left
		pack $b.cancel -side right
    }
	Dialog_Wait $f conf(save) $f.buttons
    save-or-restore-config
	destroy $f
}

proc dialog-prompt {string} {
	global prompt
	set f .prompt
	if [Dialog_Create $f "Prompt" -borderwidth 10] {
		message $f.msg -text $string -aspect 1000
		entry $f.entry -textvariable prompt(result)
		set b [frame $f.buttons]
		pack $f.msg $f.entry $f.buttons -side top -fill x
		pack $f.entry -pady 5
		button $b.ok -text OK -command {set prompt(ok) 1}
		button $b.cancel -text Cancel \
			-command {set prompt(ok) 0}
		pack $b.ok -side left
		pack $b.cancel -side right
		bind $f.entry <Return> {set prompt(ok) 1 ; break}
		bind $f.entry <Control-c> {set prompt(ok) 0 ; break}
	}
	set prompt(ok) 0
	Dialog_Wait $f prompt(ok) $f.entry
#    Dialog_Dismiss $f
#    if {$prompt(ok)} {
#        return $prompt(result)
#    } else {
#        return {}
#    }
	set this ""
	if {$prompt(ok)} {set this $prompt(result)}
	destroy $f
	set prompt(result) ""
	return $this
}

proc calc-TH1 {} {
	global baudrate freq smod th1
	set k 1
	if {$smod == "true"} {incr k}
	set a [expr $k * $freq]
	set b [expr 384 * $baudrate]
	set c [expr $a / $b]
	set d [expr round($c)]
	set th1 [expr 256 - $d]
}

proc edit-word {} {
	set word [dialog-prompt "Enter the word to edit"]
	if {$word == ""} {return}
	edit-source $word
}

proc change-baudrate {} {
	global baudrate
	set this [dialog-prompt "Enter the baudrate, e.g. 9600"]
	if {$this == ""} {return}
	set baudrate $this
	calc-TH1
	update-info
}

proc change-frequency {} {
	global freq
	set this [dialog-prompt "Enter the Crystal Frequency, e.g. 24500000"]
	if {$this == ""} {return}
	set that [expr $this * 1000000]
	set freq [expr int($that)]
	calc-TH1
	update-info
}

proc change-browser {} {
	global browser
	set browser [dialog-prompt "Enter the name of your browser"]
	save-options-config
}

proc use-IE {} {
	global browser
	set browser "/Program Files/Internet Explorer/IEXPLORE.EXE"
	save-options-config
}

proc sorted {vocab} {
	upvar $vocab this
	set pairs ""
	foreach {key value} [array get this] {
		lappend pairs "$value     $key"
	}
        set sortedpairs [lsort -dictionary -decreasing $pairs]
	set sorted ""
	foreach pair $sortedpairs {
		set one [split $pair]
		lappend sorted [lindex $one end]
	}
	return [lrange $sorted 0 end-1]
}

proc show-words {} {
	global forth hostforth immed addresses hiddenforth
	show "\n-->Host words:\n"
	show-target [sorted hostforth]
	show "\n-->Compiler words:\n"
    show-target $immed
	show "\n-->Target words:\n"
	show-target [sorted forth]
    show "\n-->Hidden words:\n"
    show-target [sorted hiddenforth]
}

proc show-host-words {} {
	global hostword
	show "\n"
	show [sorted hostword]
}

proc show-jtag-words {} {
	global hostjtag
	show "\n"
	show [sorted hostjtag]
}

proc show-c2-words {} {
	global hostc2
	show "\n"
	show [sorted hostc2]
}

proc hello-target {} {
    global at_target
	emit-s 0
	# with timeout.
	set char [key?-s]
	set timer 20
	while {[string equal $char ""]} {
		incr timer -1
		if {$timer < 0} {
			show "Target does not respond"
            set at_target 0
			return 0
		}
		set char [key?-s]
		after 50
	}
	binary scan $char c number
	if {$number == 7} {
        set at_target 1
		return 1
	}
	binary scan $number c char
	show "$char"
    set at_target 1
    return 1
}

proc hello-jtag {} {
	clear-sbuf
	emit-s "\n"
	# with timeout.
	set char [key?-s]
	set timer 20
	while {[string equal $char ""]} {
		incr timer -1
		if {$timer < 0} {
			show "Programmer not responding"
			return 1
		}
		set char [key?-s]
		after 50
	}
	return 0
}

proc use-basic {} {
	global mode
	set mode "BASIC"
	update-info
	hello-target
}

proc use-forth {} {
	global mode
	set mode "Forth"
	update-info
	hello-target
}

proc use-host {} {
	global mode
	set mode "Host"
	update-info
}

proc use-jtag {} {
	global mode
	set mode "JTAG"
	update-info
}

proc use-c2 {} {
	global mode
	set mode "C2"
	update-info
}

proc next-word {} {
	global commandlist in
	incr in
	return [lindex $commandlist $in]
}

proc edit-source {word} {
	global edit_log saveTextMsg
	if [catch {open "tags.log"} in] {
        show-prompt
		error "Problem opening tags.log"
	}
	while {[gets $in raw_line] >= 0} {
		set line [string tolower $raw_line]
		if {[string first "$word\t" $line] == 0} {
			close $in
			if {$saveTextMsg == 1} {filetosave}
			setTextTitleAsNew
			set words [split $line \t]
			set file [lindex $words 1]
			set lineno [ expr [lindex $words 2] + 0]
			openoninit $file
			focus $edit_log
			$edit_log mark set insert "$lineno.0"
			$edit_log see insert
			update-info
			return
		}
	}
	close $in
    show-prompt
	error "\n$word not found"
}

proc locate-source {} {
	set word [next-word]
	edit-source $word
}

proc ascii-char {} {
    set word [next-word]
    binary scan $word c this
    execute-number $this
}

proc wait-ok {} {
	set char [key-s]
	while {$char != "O"} {
		if {$char != "\r"} {show $char}
		set char [key-s]
	}
	key-s
	key-s
	key-s
}

proc jtag-erase {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "erase-all\n"
	wait-ok
}

proc jtag-erase-menu {} {
	jtag-erase
	show-prompt
}

proc c2-erase {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "C2erase\n"
	wait-ok
}

proc c2-erase-menu {} {
	c2-erase
	show-prompt
}

proc jtag-dump {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "dump\n"
	wait-ok
}

proc jtag-dump-menu {} {
	jtag-dump
	show-prompt
}

proc c2-dump {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "C2dump\n"
	wait-ok
}

proc c2-dump-menu {} {
	c2-dump
	show-prompt
}

proc jtag-next {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "next\n"
	wait-ok
}

proc jtag-next-menu {} {
	jtag-next
	show-prompt
}

proc c2-next {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "C2next\n"
	wait-ok
}

proc c2-next-menu {} {
	c2-next
	show-prompt
}

proc jtag-run {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "run\n"
	wait-ok
}

proc jtag-run-menu {} {
	jtag-run
	show-prompt
}

proc jtag-reset {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "reset\n"
	wait-ok
}

proc jtag-reset-menu {} {
	jtag-reset
	show-prompt
}

proc jtag-halt {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "halt\n"
	wait-ok
}

proc jtag-halt-menu {} {
	jtag-halt
	show-prompt
}

proc jtag-suspend {} {
	if {[hello-jtag] == 1} {return}
	clear-sbuf
	emit-s "suspend\n"
	wait-ok
}

proc jtag-suspend-menu {} {
	jtag-suspend
	show-prompt
}

proc toggletimer {} {
    global timing
    if {$timing} {
        set timing 0
        return
    }
    set timing 1
}

# Words executed by host, not target.
set hostword(bye) {exitapp}
set hostword(basic) {use-basic}
set hostword(forth) {use-forth}
set hostword(jtag) {use-jtag}
set hostword(c2) {use-c2}
set hostword(host) {}
set hostword(edit) {filetoopen}
set hostword(words) {show-host-words}
set hostword(help) {run-browser-local}
set hostword(c) {run-compiler}
set hostword(t) {run-rommer}
set hostword(d) {run-downloader}
set hostword(e) {locate-source}
set hostword(config) {dialog-config}

set hostforth(bye) {exitapp}
set hostforth(words) {show-words}
set hostforth(bw) {show-basic-words}
set hostforth(host) {use-host}
set hostforth(basic) {use-basic}
set hostforth(jtag) {use-jtag}
set hostforth(c2) {use-c2}
set hostforth(forth) {}
set hostforth(edit) {filetoopen}
set hostforth(c) {run-compiler}
set hostforth(t) {run-rommer}
set hostforth(d) {run-downloader}
set hostforth(r) {run-runner}
set hostforth(e) {locate-source}
set hostforth(char) {ascii-char}
set hostforth(step) {step}
set hostforth(') {tick}
set hostforth(`) {name}
set hostforth(dump-line) {dump-line}
set hostforth(see) {see}
set hostforth(dis) {dis}
set hostforth(listen) {listen}
set hostforth(timer) {toggletimer}

set hostc2(bye) {exitapp}
set hostc2(words) {show-c2-words}
set hostc2(host) {use-host}
set hostc2(forth) {use-forth}
set hostc2(basic) {use-basic}
set hostc2(jtag) {use-jtag}
set hostc2(c2) {}
set hostc2(download) {c2-download}
set hostc2(erase) {c2-erase}
set hostc2(dump) {c2-dump}
set hostc2(next) {c2-next}
set hostc2(n) {c2-next}
set hostc2(t) {run-rommer}

set hostjtag(bye) {exitapp}
set hostjtag(words) {show-jtag-words}
set hostjtag(host) {use-host}
set hostjtag(forth) {use-forth}
set hostjtag(basic) {use-basic}
set hostjtag(jtag) {}
set hostjtag(c2) {use-c2}
set hostjtag(download) {jtag-download}
set hostjtag(erase) {jtag-erase}
set hostjtag(dump) {jtag-dump}
set hostjtag(next) {jtag-next}
set hostjtag(n) {jtag-next}
set hostjtag(reset) {jtag-reset}
set hostjtag(run) {jtag-run}
set hostjtag(halt) {jtag-halt}
set hostjtag(suspend) {jtag-suspend}
set hostjtag(t) {run-rommer}

proc ishostforth {word} {
	global hostforth
	return [info exists hostforth($word)]
}

proc ishostword {word} {
	global hostword
	return [info exists hostword($word)]
}

proc ishostjtag {word} {
	global hostjtag
	return [info exists hostjtag($word)]
}

proc ishostc2 {word} {
	global hostc2
	return [info exists hostc2($word)]
}

proc isforth {word} {
	global forth
	return [info exists forth($word)]
}

proc ishiddenforth {word} {
    global hiddenforth
    return [info exists hiddenforth($word)]
}

proc isaddress {word} {
    global addresses
    return [info exists addresses($word)]
}

proc ishiddenaddress {word} {
    global hiddenaddresses
    return [info exists hiddenaddresses($word)]
}

proc isexit {addr} {
    global exits
    return [info exists exits($addr)]
}

proc not-number {word} {
	catch {expr $word + 0}
}

proc lookuphostforth {word} {
	global hostforth
	return $hostforth($word)
}

proc lookupaddress {word} {
    global addresses
    return $addresses($word)
}

proc lookuphiddenaddress {word} {
    global hiddenaddresses
    return $hiddenaddresses($word)
}

proc lookuphostword {word} {
	global hostword
	return $hostword($word)
}

proc lookupjtagword {word} {
	global hostjtag
	return $hostjtag($word)
}

proc lookupc2word {word} {
	global hostc2
	return $hostc2($word)
}

proc lookupforth {word} {
	global forth
	return $forth($word)
}

proc lookuphidden {word} {
    global hiddenforth
    return $hiddenforth($word)
}

proc lookupcursor {addr} {
    global steppersource
    return $steppersource($addr)
}

proc interpret-forth {word} {
	if {[isforth $word]} {
		execute-word [lookupforth $word]
		return
	}
	if {[ishostforth $word]} {
		eval [lookuphostforth $word]
		return
	}
	regsub {^\$} $word 0x word
	if [not-number $word] {
		show "?"
		show-prompt
		error "Not a valid forth word"
	}
	execute-number $word
}

proc interpret-host {word} {
	if {[ishostword $word]} {
		eval [lookuphostword $word]
	} else {
		show "?"
		show-prompt
		error "Not a valid host word"
	}
}

proc interpret-jtag {word} {
	if {[ishostjtag $word]} {
		eval [lookupjtagword $word]
	} else {
		show "?"
		show-prompt
		error "Not a valid JTAG word"
	}
}

proc interpret-c2 {word} {
	if {[ishostc2 $word]} {
		eval [lookupc2word $word]
	} else {
		show "?"
		show-prompt
		error "Not a valid C2 word"
	}
}

proc interpret-word {word} {
	global mode
	if {$mode == "Forth"} {
		interpret-forth $word
		return
	}
	if {$mode == "BASIC"} {
		interpret-basic $word
		return
	}
	if {$mode == "Host"} {
		interpret-host $word
		return
	}
	if {$mode == "C2"} {
		interpret-c2 $word
		return
	}
	if {$mode == "JTAG"} {
		interpret-jtag $word
		return
	}
}

proc show-prompt {} {
	global mode commname log stepping
    if {$stepping} {return}
	show "\n$mode> "
	$log mark set limit insert
	$log mark gravity limit left
}

proc remember {line} {
	global history historypointer
	set history($historypointer) $line
	set historypointer [expr ($historypointer + 1) & 7]
}

proc up-arrow {} {
	global log history historypointer
	$log delete limit "insert lineend"
	set historypointer [expr ($historypointer - 1) & 7]
	show $history($historypointer)
}

proc down-arrow {} {
	global log history historypointer
	$log delete limit "insert lineend"
	set historypointer [expr ($historypointer + 1) & 7]
	show $history($historypointer)
}

proc run-interpreter {} {
	global log commname commandlist in tibend
	set tibend [$log index "insert lineend"]
	set rawline [$log get limit $tibend]
	remember $rawline
	show " "
	set line [string tolower $rawline]
	set commandlist [split $line]
	for {set in 0} {$in < [llength $commandlist]} {incr in} {
		set word [lindex $commandlist $in]
		if {[string length $word]} {
			interpret-word $word
		}
	}
	show-prompt
}

# Read and log output from the program.
proc Log {} {
	global input log
	if [eof $input] {
		Stop
	} else {
		gets $input line
        $log insert end "$line\n"
	}
	update
}

# Stop the program.
proc Stop {} {
	global input done comfid
	catch {close $input}
	if ![catch {open "errors.log" r} this] {
		while {[gets $this line] >= 0} {show "$line\n"}
		close $this
	}
	set done 1
}

proc Stop_reading_symbols {} {
	global input done comfid
	catch {close $input}
	set done 1
}

# --- Editor ---

# generic case switcher for message box
proc switchcase {yesfn nofn} {
    global saveTextMsg
    if [ expr [string compare $saveTextMsg 1] ==0 ] { 
	set answer [tk_messageBox -message "The contents of this file may have changed, do you wish to to save your changes?" \
	-title "New Confirm?" -type yesnocancel -icon question]
	case $answer {
	     yes { if {[eval $yesfn] == 1} { $nofn } }
             no {$nofn }
	}
    } else {
   	$nofn
    }
}

# new file
proc filesetasnew {} {
	switchcase filetosave setTextTitleAsNew
}

proc setTextTitleAsNew {} {
	global fileName edit_log
	$edit_log delete 0.0 end
	set fileName " "
	outccount
}

# kill main window
proc killwin {} {
	destroy .
}

# exit app
proc exitapp {} {
    global done comfid
    set done 1
# This is an attempt at fixing the serial lockup bug in Windows.
    after 100
    catch [close-comm]
# End of proposed fix.
    savesession
	switchcase filetosave killwin
}

# bring up open win
proc showopenwin {} {
	global edit_log
	set types {
	{"All files"		*}
	}
	set file [tk_getOpenFile -filetypes $types -parent .]
	if [string compare $file ""] {
		setTextTitleAsNew
		openoninit $file
		outccount
		focus $edit_log
		$edit_log see insert
	}
	update-info
}

proc showopenlogfile {} {
	global homepath
    exec wish $homepath/logview.tcl &
}

# proc to open files or read a pipe
proc openoninit {thefile} {
	global edit_log
    if [string match " " $thefile] {  
        fconfigure stdin -blocking 0
        set incoming [read stdin 1]
        if [expr [string length $incoming] == 0] {
            fconfigure stdin -blocking 1
        } else {
            fconfigure stdin -blocking 1
            $edit_log insert end $incoming
            while {![eof stdin]} {
                $edit_log insert end [read -nonewline stdin]
            }
        }
    } else {
        if [ file exists $thefile ] {
            set newnamefile [open $thefile r]
        } else {
            set newnamefile [open $thefile a+]
        }
        while {![eof $newnamefile]} {
	       $edit_log insert end [read -nonewline $newnamefile ] 
        }
        close $newnamefile
        settitle $thefile
    }
}

# this proc just sets the title to what it is passed
proc settitle {WinTitleName} {
	global fileName
	set fileName $WinTitleName
}

#open an existing file
proc filetoopen {} {
  	switchcase filetosave showopenwin
}

proc logtoopen {} {
    switchcase filetosave showopenlogfile
}

# generic save function
proc writesave {nametosave} {
	global edit_log
    set FileNameToSave [open $nametosave w+]
    puts -nonewline $FileNameToSave [$edit_log get 0.0 end]
    close $FileNameToSave
    outccount
}

# save session log
proc savesession {} {
    global log
    set sessionlog [open "lastsession.log" w+]
    set datestamp [clock format [clock seconds]]
    puts $sessionlog $datestamp
    set project [pwd]
    puts $sessionlog $project
    puts -nonewline $sessionlog [$log get 0.0 end]
    close $sessionlog
}

#save a file
proc filetosave {} {
    global fileName
    #check if file exists file
    if [file exists $fileName] {
    	show "Saving file: $fileName"
	show-prompt
	writesave $fileName
        return 1
    } else {
	 return [eval filesaveas]
    }
}

#save a file as
proc filesaveas {} {
    set types {
	{"All files"		*}
    }
    set myfile [tk_getSaveFile -filetypes $types -parent . -initialfile Untitled]
    if { [expr [string compare $myfile ""]] != 0} {
	writesave  $myfile 
	settitle $myfile
        return 1
    }
    return 0
}

# this sets saveTextMsg to 1 for message boxes
proc inccount {} {
    global saveTextMsg
    set saveTextMsg 1
}
# this resets saveTextMsg to 0
proc outccount {} {
    global saveTextMsg
    set saveTextMsg 0
}

proc cuttext {} {
	global edit_log
    tk_textCut $edit_log
    inccount
}

proc copytext {} {
	global edit_log
    tk_textCopy $edit_log
    inccount
}

proc pastetext {} {
    global tcl_platform edit_log
    if {"$tcl_platform(platform)" == "unix"} {
	    catch {
		$edit_log delete sel.first sel.last
	    }
    }
    tk_textPaste $edit_log
    inccount
}

proc deletetext {} {
    set cuttexts [selection own]
    if {$cuttexts != "" } {
        $cuttexts delete sel.first sel.last
        selection clear
    }
    inccount
}

proc selectall {} {
	global edit_log
	$edit_log tag add sel 1.0 end
}

proc currenttime {} {
    return [clock format [clock seconds] -format "%r %D"]
}

proc printtime {} {
	global edit_log
	$edit_log insert insert currenttime
	inccount
}

# procedure to find text
proc findtext {typ} {
	global SearchString SearchDir ReplaceString findcase c find \
		edit_log
	set find .find
	catch {destroy $find}
	toplevel $find
	wm title $find "Find"
	setwingeom $find
	ResetFind
	frame $find.l
	frame $find.l.f1
	label $find.l.f1.label -text "Find what:" -width 11  
	entry $find.l.f1.entry  -textvariable SearchString -width 30 
	pack $find.l.f1.label $find.l.f1.entry -side left
	$find.l.f1.entry selection range 0 end
	if {$typ=="replace"} {
		frame $find.l.f2
		label $find.l.f2.label2 -text "Replace with:" -width 11
		entry $find.l.f2.entry2  -textvariable ReplaceString -width 30 
		pack $find.l.f2.label2 $find.l.f2.entry2 -side left
		pack $find.l.f1 $find.l.f2 -side top
	} else {
		pack $find.l.f1
	}
	frame $find.f2
	button $find.f2.button1 -text "Find Next" \
	-command "FindIt $find" -width 10 -height 1 -underline 5 
	button $find.f2.button2 -text "Cancel" \
	-command "CancelFind $find" -width 10 -underline 0
	if {$typ=="replace"} {
		button $find.f2.button3 -text "Replace" \
		-command ReplaceIt -width 10 -height 1 -underline 0
		button $find.f2.button4 -text "Replace All" \
		-command ReplaceAll -width 10 -height 1 -underline 8		
		pack $find.f2.button3 $find.f2.button4 $find.f2.button2  -pady 4
	} else {
		pack $find.f2.button1 $find.f2.button2  -pady 4
	}
	frame $find.l.f4
	frame $find.l.f4.f3 -borderwidth 2 -relief groove
	radiobutton $find.l.f4.f3.up -text "Up" \
		-underline 0 -variable SearchDir -value "backwards" 
	radiobutton $find.l.f4.f3.down -text "Down" \
		-underline 0 -variable SearchDir -value "forwards" 
	$find.l.f4.f3.down invoke
	pack $find.l.f4.f3.up $find.l.f4.f3.down -side left 
	checkbutton $find.l.f4.cbox1 -text "Match case" \
		-variable findcase -underline 0 
	pack $find.l.f4.cbox1 $find.l.f4.f3 -side left -padx 10
	pack $find.l.f4 -pady 11
	pack $find.l $find.f2 -side left -padx 1
	bind $find <Escape> "destroy $find"

     # each widget must be bound to th eevents of the other widgets
     proc bindevnt {widgetnm types find} {
	if {$types=="replace"} {
		bind $widgetnm <Return> "ReplaceIt"
		bind $widgetnm <Control-r> "ReplaceIt"
		bind $widgetnm <Control-a> "ReplaceAll"
	} else {
		bind $widgetnm <Return> "FindIt $find"
		bind $widgetnm <Control-n> "FindIt $find"
	}
	bind $widgetnm <Control-m> { $find.l.f4.cbox1 invoke }
	bind $widgetnm <Control-u> { $find.l.f4.f3.up invoke }
	bind $widgetnm <Control-d> { $find.l.f4.f3.down invoke }
     }
	if {$typ == "replace"} {
   		bindevnt $find.f2.button3 $typ $find
		bindevnt $find.f2.button4 $typ $find
	} else {
		bindevnt $find.f2.button1 $typ $find
  	        bindevnt $find.f2.button2 $typ $find
	}
        bindevnt $find.l.f4.f3.up  $typ $find
        bindevnt $find.l.f4.f3.down $typ $find
        bindevnt $find.l.f4.cbox1 $typ $find
	bindevnt $find.l.f1.entry $typ $find	
	bind $find <Control-c> "destroy $find"
	focus $find.l.f1.entry
	grab $find
}

# proc for find next
proc findnext {typof} {
	global SearchString SearchDir ReplaceString findcase c find
	if [catch {expr [string compare $SearchString "" ] }] {
		findtext $typof
	} else {
	 	FindIt $find
	}
}

proc FindIt {w} {
	global SearchString SearchPos SearchDir findcase edit_log
	$edit_log tag configure sel -background green
	if {$SearchString!=""} {
		if {$findcase=="1"} {
 			set caset "-exact"
		} else {
			set caset "-nocase"
		}
		if {$SearchDir == "forwards"} {
			set limit end
		} else {
			set limit 1.0
		}
		set SearchPos [ $edit_log search -count len \
			$caset -$SearchDir $SearchString $SearchPos $limit]
		set len [string length $SearchString]
		if {$SearchPos != ""} {
        			$edit_log see $SearchPos
			$edit_log mark set insert $SearchPos
			if {$SearchDir == "forwards"} {
        				set SearchPos "$SearchPos + $len char"
			}         
            		} else {
	           		set SearchPos "0.0"
	          	}
 	}
	focus $edit_log
}

proc ReplaceIt {} {
	global SearchString SearchDir ReplaceString SearchPos findcase \
		edit_log
	if {$SearchString != ""} {
	    if {$findcase=="1"} {
		set caset "-exact"
	    } else {
		set caset "-nocase"
	    }
	    if {$SearchDir == "forwards"} {
		set limit end
	    } else {
		set limit 1.0
	    }
	    set SearchPos [ $edit_log search -count len \
	    	$caset -$SearchDir $SearchString $SearchPos $limit]
		set len [string length $SearchString]
	    if {$SearchPos != ""} {
        		$edit_log see $SearchPos
               		$edit_log delete $SearchPos "$SearchPos+$len char"
        		$edit_log insert $SearchPos $ReplaceString
		if {$SearchDir == "forwards"} {
        			set SearchPos "$SearchPos+$len char"
		}         
	    } else {
	       	set SearchPos "0.0"
	    }
	}
	inccount
}

proc ReplaceAll {} {
      global SearchPos SearchString
       if {$SearchString != ""} {
                ReplaceIt
	while {$SearchPos!="0.0"} {
		ReplaceIt
	}
       }
}

proc CancelFind {w} {
	global edit_log
    $edit_log tag delete tg1
    destroy $w
}

proc ResetFind {} {
    global SearchPos
    set SearchPos insert
}

# procedure to find text
proc findtext {typ} {
	global SearchString SearchDir ReplaceString findcase c find
	set find .find
	catch {destroy $find}
	toplevel $find
	wm title $find "Find"
	setwingeom $find
	ResetFind
	frame $find.l
	frame $find.l.f1
	label $find.l.f1.label -text "Find what:" -width 11  
	entry $find.l.f1.entry  -textvariable SearchString -width 30 
	pack $find.l.f1.label $find.l.f1.entry -side left
	$find.l.f1.entry selection range 0 end
	if {$typ=="replace"} {
		frame $find.l.f2
		label $find.l.f2.label2 -text "Replace with:" -width 11
		entry $find.l.f2.entry2  -textvariable ReplaceString -width 30 
		pack $find.l.f2.label2 $find.l.f2.entry2 -side left
		pack $find.l.f1 $find.l.f2 -side top
	} else {
		pack $find.l.f1
	}
	frame $find.f2
	button $find.f2.button1 -text "Find Next" \
		-command "FindIt $find" -width 10 -height 1 -underline 5 
	button $find.f2.button2 -text "Cancel" \
		-command "CancelFind $find" -width 10 -underline 0
	if {$typ=="replace"} {
		button $find.f2.button3 -text "Replace" \
		-command ReplaceIt -width 10 -height 1 -underline 0
		button $find.f2.button4 -text "Replace All" \
		-command ReplaceAll -width 10 -height 1 -underline 8		
		pack $find.f2.button3 $find.f2.button4 $find.f2.button2  -pady 4
	} else {
		pack $find.f2.button1 $find.f2.button2  -pady 4
	}
	frame $find.l.f4
	frame $find.l.f4.f3 -borderwidth 2 -relief groove
	radiobutton $find.l.f4.f3.up -text "Up" \
		-underline 0 -variable SearchDir -value "backwards" 
	radiobutton $find.l.f4.f3.down -text "Down"  \
		-underline 0 -variable SearchDir -value "forwards" 
	$find.l.f4.f3.down invoke
	pack $find.l.f4.f3.up $find.l.f4.f3.down -side left 
	checkbutton $find.l.f4.cbox1 -text "Match case" \
		-variable findcase -underline 0 
	pack $find.l.f4.cbox1 $find.l.f4.f3 -side left -padx 10
	pack $find.l.f4 -pady 11
	pack $find.l $find.f2 -side left -padx 1
	bind $find <Escape> "destroy $find"

     # each widget must be bound to th eevents of the other widgets
     proc bindevnt {widgetnm types find} {
	if {$types=="replace"} {
		bind $widgetnm <Return> "ReplaceIt"
		bind $widgetnm <Control-r> "ReplaceIt"
		bind $widgetnm <Control-a> "ReplaceAll"
	} else {
		bind $widgetnm <Return> "FindIt $find"
		bind $widgetnm <Control-n> "FindIt $find"
	}
	bind $widgetnm <Control-m> { $find.l.f4.cbox1 invoke }
	bind $widgetnm <Control-u> { $find.l.f4.f3.up invoke }
	bind $widgetnm <Control-d> { $find.l.f4.f3.down invoke }
     }
	if {$typ == "replace"} {
   		bindevnt $find.f2.button3 $typ $find
		bindevnt $find.f2.button4 $typ $find
	} else {
		bindevnt $find.f2.button1 $typ $find
  	        bindevnt $find.f2.button2 $typ $find
	}
        bindevnt $find.l.f4.f3.up  $typ $find
        bindevnt $find.l.f4.f3.down $typ $find
        bindevnt $find.l.f4.cbox1 $typ $find
	bindevnt $find.l.f1.entry $typ $find	
	bind $find <Control-c> "destroy $find"
	focus $find.l.f1.entry
	grab $find
}

# proc for find next
proc findnext {typof} {
	global SearchString SearchDir ReplaceString findcase c find
	if [catch {expr [string compare $SearchString "" ] }] {
		findtext $typof
	} else {
	 	FindIt $find
	}
}

# proc to set child window position
proc setwingeom {wintoset} {
    wm resizable $wintoset 0 0
    set myx [expr (([winfo screenwidth .]/2) - ([winfo reqwidth $wintoset]))]
    set myy [expr (([winfo screenheight .]/2) - ([winfo reqheight $wintoset]/2))]
    wm geometry $wintoset +$myx+$myy
}

proc open-project {} {
	global project processor baudrate freq commname comport dlfile \
		homepath downloader bgColor fgColor
    tk_setPalette background LightGray foreground black
	set project [tk_chooseDirectory -mustexist true -title "Open Project"]
    tk_setPalette background $bgColor foreground $fgColor
	if {$project != ""} {
		cd $project
		reconfigure
		update-info
	}
}

# ----- Single stepper ----- #

proc push-source {addr} {
    global source_stack
    lappend source_stack $addr
}

proc pop-source {} {
    global source_stack
    set answer [lindex $source_stack end]
    set source-stack [lrange $source_stack 0 [expr [llength $source_stack] - 2]]
    return $answer
}

proc decimal {num} {
    return [expr 0 | $num]
}

proc hex {num} {
    return [format "%04x" $num]
}

proc hexbyte {num} {
    return [format "%02x" $num]
}

proc asciichar {num} {
	return [format "%c" $num]
}

proc show-hex {num} {
    set it [hex $num]
    show-target "$it "
}

proc read-rom.bin {} {
    global target_image
    if [catch {open "rom.bin" r} input] {
        show $input
        show-prompt
        return
    }
    fconfigure $input -translation binary
    set target_image [read $input]
    close $input
}
if {[file exists "rom.bin"]} {read-rom.bin}

proc at {addr} {
    global target_image at_target kernelword processor
    if {$at_target == 0} {
    	if {$processor == "80c552" || $processor == "80c537"} {
        	set addr [expr $addr & 0x7fff]
    	}
        binary scan $target_image "@${addr}c" this
    } else {
        execute-number $addr
        execute-word $kernelword(cfetchp)
        set this [get-target-byte]
    }
    set that [expr $this & 0xff]
    return $that
}

proc at_signed {addr} {
    set this [at $addr]
    show " $this "
    set that [expr $this & 0xff]
    show " $that "
    if {[expr $that > 127]} {
        set it [expr 255 - $that]
        return $it
        show " $it "
    }
    return $that
}

proc atw {addr} {
    global target_image
    set hi [at $addr]
    set high [expr 256 * $hi]
    incr addr 1
    set low [at $addr]
    set total [expr $high + $low]
    return $total
}

proc long-addr {} {
    global ip
    set addr $ip
    incr ip 3
    incr addr 1
    return [atw $addr]
}

proc absolute {} {
    global ip
    set addr $ip
    incr ip 2
    set high [at $addr]
    incr addr 1
    set low [at $addr]
    set high [expr $high & 0xe0] 
    set high [expr $high * 8]
    set offset [expr $high + $low]
    set page [expr $ip & 0xf800]
    set it [expr $offset + $page]
    return $it
}

# This is hand coded, if definition of exec: changes,
# then so should this.
proc execcolon {} {
    global ip
    set place $ip
    if {[at $place] != 0x90} {return -1}
    if {[at [expr 3 + $place]] != 0x08} {return -1}
    if {[at [expr 4 + $place]] != 0x08} {return -1}
    if {[at [expr 5 + $place]] != 0xe6} {return -1}
    if {[at [expr 6 + $place]] != 0xff} {return -1}
    if {[at [expr 7 + $place]] != 0x2f} {return -1}
    if {[at [expr 8 + $place]] != 0x2f} {return -1}
    if {[at [expr 9 + $place]] != 0x73} {return -1}
    return -2
}

proc execliteral {} {
    global ip literal
    set place $ip
    if {[at $place] != 0x74} {return -1}
    if {[at [expr 2 + $place]] != 0x75} {return -1}
    if {[at [expr 3 + $place]] != 0xf0} {return -1}
    set hi [at [expr 4 + $place]]
    set lo [at [expr 1 + $place]]
    set literal [expr (256 * $hi) + $lo]
    return -3
}

proc execstring {} {
	global ip
	set place $ip
	return -1
}

proc get-code-address {} {
    global ip instruction
    set instruction [at $ip]
    set hex_instruction [hex $instruction]
    switch -exact -- $hex_instruction {
        0002 {return [long-addr]}
        0012 {return [long-addr]}
        0001 {return [absolute]}
        0011 {return [absolute]}
        0021 {return [absolute]}
        0031 {return [absolute]}
        0041 {return [absolute]}
        0051 {return [absolute]}
        0061 {return [absolute]}
        0071 {return [absolute]}
        0081 {return [absolute]}
        0091 {return [absolute]}
        00a1 {return [absolute]}
        00b1 {return [absolute]}
        00c1 {return [absolute]}
        00d1 {return [absolute]}
        00e1 {return [absolute]}
        00f1 {return [absolute]}
        0090 {return [execcolon]}
        0074 {return [execliteral]}
#	00XX {return [execstring]}
        default {return -1}
    }
    return 0
}

# Load the jumps array, for isjump.
set jumps([decimal 0x02]) yes
set jumps([decimal 0x01]) yes
set jumps([decimal 0x21]) yes
set jumps([decimal 0x41]) yes
set jumps([decimal 0x61]) yes
set jumps([decimal 0x81]) yes
set jumps([decimal 0xA1]) yes
set jumps([decimal 0xC1]) yes
set jumps([decimal 0xE1]) yes

proc isjump {instruction} {
    global jumps
    return [info exists jumps($instruction)]
}

# Load the calls array, for iscall.
set calls([decimal 0x12]) yes
set calls([decimal 0x11]) yes
set calls([decimal 0x31]) yes
set calls([decimal 0x51]) yes
set calls([decimal 0x71]) yes
set calls([decimal 0x91]) yes
set calls([decimal 0xB1]) yes
set calls([decimal 0xD1]) yes
set calls([decimal 0xF1]) yes

proc iscall {instruction} {
    global calls
    return [info exists calls($instruction)]
}

proc simulate-clit {} {
     global ip
     set num [at $ip]
     incr ip 1
     execute-number $num
}

proc simulate-lit {} {
    global ip 
    set num [atw $ip]
    incr ip 2
    execute-number $num
}

proc simulate-string {} {
	global ip
	set count [at $ip]
	incr ip 1
	set addr $ip
	incr ip $count
	execute-number $addr
	execute-number $count
}

proc get-target-byte {} {
    global kernelword
    start-word $kernelword(emit)
    set char [key-s]
    binary scan $char "c" answer
    return $answer
}

proc simulate-qbranch {} {
    global ip kernelword
    execute-word $kernelword(not)
    set answer [get-target-byte]
    if {$answer != 0} {
        set temp [atw $ip]
        set ip $temp
    } else {
        incr ip 2
    }
}

proc simulate-next {} {
    global ip kernelword
    execute-word $kernelword(pop)
    execute-number "1"
    execute-word $kernelword(minus)
    execute-word $kernelword(dup)
    execute-word $kernelword(not)
    start-word $kernelword(emit)
    set last_char [key-s]
    binary scan $last_char "c" answer
    if {$answer == 0} {
        execute-word $kernelword(push)
        set temp [atw $ip]
        set ip $temp
    } else {
        incr ip 2
        execute-word $kernelword(drop)
    }
}

proc simulate-squote {} {
    global ip kernelword
    execute-number $ip
    execute-word $kernelword(count)
    set temp [at $ip]
    incr temp 1
    incr ip $temp
}

proc simulate-execcolon {} {
    global ip nestlevel
    set tos [get-target-word]
    set offset [expr $tos * 3]
    incr ip 10
    incr ip $offset
}

proc simulate-literal {} {
    global ip kernelword
    execute-number $ip
    execute-word $kernelword(fetchp)
    incr ip 2
}

proc simulate {addr} {
    if {![ishiddenaddress $addr]} {return 0}
    if {$addr == [lookuphidden "lit"]} {
        simulate-lit
        return 1
    }
    if {$addr == [lookuphidden "?branch"]} {
        simulate-qbranch
        return 1
    }
    if {$addr == [lookuphidden "(next)"]} {
        simulate-next
        return 1
    }
    if {$addr == [lookuphidden "(string)"]} {
	simulate-string
	return 1
    }
    return 0
}

proc unnest {} {
    global nestlevel
    if {$nestlevel == 0} {
        stop-stepping
        return
    }
    unnesting-step
}

proc execute-word-at-ip {} {
    global ip instruction nestlevel kernelword literal
    set lastip $ip
    set addr [get-code-address]
    if {$addr == -1} {return}
    if {$addr == -2} {simulate-execcolon;return}
    if {$addr == -3} {simulate-literal;return}
    if {[isjump $instruction]} {
        if {[isexit $lastip]} {
            if {[isaddress $addr]} {
                execute-word $addr
                execute-word $kernelword(dots)
                unnest
                return
            }
        } else {
            set ip $addr
            return
        }
    } else {
        if {[isaddress $addr]} {
            execute-word $addr
            return
        }
        if {[simulate $addr]} {return}
    }
    stop-stepping
    show-prompt
    error "\nCan't step that word"
}

proc show-dots {} {
    global nestlevel
    for {set i $nestlevel} {$i > 0} {incr i -1} {
        show "."
    }
}

set pt1 "1.0"
set pt2 "1.0"

proc show-next-word {} {
    global ip instruction edit_log steppersource pt1 pt2 literal
    $edit_log tag remove ip $pt1 $pt2
    catch {lookupcursor $ip} pt1
    set pt2 [$edit_log search " " $pt1]
    $edit_log tag add ip $pt1 $pt2
    $edit_log see $pt1
    set fix $ip
    set addr [get-code-address]
    set ip $fix
    if {[isjump $instruction]} {
        if {![isexit $ip]} {
            show "\n"
            show-dots
            show-hex $ip
            show "branch "
            return 0
        }
    }
    if {$addr == -1} {
        if {$instruction == 0x22} {
            show "\n"
            show-dots
            show-hex $ip
            show "; "
            unnest
            return 0
        } else {
            return -1
        }
    }
    if {$addr == -3} {
        show "\n"
        show-dots
        show-hex $ip
        show "|lit $literal "
        return 0
    }
    if {$addr == -2} {
        show "\n"
        show-dots
        show-hex $ip
        show "exec: "
        return 0
    }
    if {[isaddress $addr]} {
        set word [lookupaddress $addr]
    } else {
        if {[ishiddenaddress $addr]} {
            set word [lookuphiddenaddress $addr]
        } else {
            stop-stepping
            show-prompt
            error "Unknown word"
        }
    }
    show "\n"
    show-dots
    show-hex $ip
    show "${word} "
    if {[isexit $ip]} {show "; "}
    return 0
}

proc one-step {} {
    global stepping instruction ip nestlevel edit_log kernelword
    if {$stepping == 0} {return}
    set temp $nestlevel
    execute-word-at-ip
    if {$stepping == 0} {return}
    if {$nestlevel != $temp} {return}
    execute-word $kernelword(dots)
    if {[show-next-word] == -1} {stop-stepping ; return}
}

proc skip-step {} {
    global stepping instruction ip nestlevel edit_log kernelword
    if {$stepping == 0} {return}
    set temp $nestlevel
    set addr [get-code-address]
    if {[ishiddenaddress $addr]} {
        set word [lookuphiddenaddress $addr]
        if {$word == "clit"} {
            incr ip 1
        } else {
            if {$word == "lit"} {
                incr ip 2
            } else {
                stop-stepping
            }
        }
    }
    if {$stepping == 0} {return}
    if {$nestlevel != $temp} {return}
    execute-word $kernelword(dots)
    if {[show-next-word] == -1} {stop-stepping ; return}
}

proc nesting-step {} {
    global ip nestlevel log kernelword
    set lastip $ip
    set addr [get-code-address]
    if {$addr == -1} {
        set ip $lastip
        return
    }
    if {![isexit $lastip]} {
        execute-number $ip
        execute-word $kernelword(push)
        incr nestlevel 1
    }
    set ip $addr
	if {![callable]} {
        show-mesg "Not high level forth, can't be stepped\n"
        set ip $lastip
        if {![isexit $ip]} {
            execute-word $kernelword(pop)
            execute-word $kernelword(drop)
            incr nestlevel -1
        }
        return
    }
    set word [lookupaddress $addr]
    edit-source $word
    focus $log
    if {[show-next-word] == -1} {stop-stepping}
}

proc get-target-word {} {
    global kernelword
    execute-word $kernelword(dup)
    set temp [get-target-byte]
    set low [expr $temp & 0xff]
    execute-word $kernelword(flip)
    set temp [get-target-byte]
    set high [expr $temp & 0xff]
    set answer [expr ($high * 256) + $low]
    return $answer
}

proc unnesting-step {} {
    global ip nestlevel log kernelword
    if {$nestlevel != 0} {incr nestlevel -1}
    execute-word $kernelword(pop)
    set temp [get-target-word]
    set ip $temp
    set word [pop-source]
    edit-source $word
    focus $log
    if {[show-next-word] == -1} {stop-stepping}
}

proc stop-stepping {} {
    global stepping edit_log pt1 pt2
    set stepping 0
    show-prompt
    $edit_log tag remove ip $pt1 $pt2
}

proc first-step {} {
    global ip stepping nestlevel kernelword
    execute-word $kernelword(dots)
    set nestlevel 0
    set stepping 1
    if {[show-next-word] == -1} {stop-stepping}
}
    
proc callable {} {
    global ip instruction
    set fix $ip
    get-code-address
    set ip $fix
    if {[iscall $instruction]} {return 1}
    return 0
}

proc generic-step {word} {
    global ip stepping nestlevel log edit_log
    if {![hello-target]} {
        show-prompt
        error "Can't step without target device"
    }
    if {![isforth $word]} {
        show-prompt
        error "Not in Symbol Table"
    }
    set ip [lookupforth $word]
	if {![callable]} {
        show-prompt
        error "$word not high level forth, can't be stepped"
    }
    show-mesg "\nCR|BL=step, N=nest, F=forth, S=skip, Esc=quit\n"
    show-source-code $word
    first-step
}

proc step {} {
    hello-target
    set word [next-word]
    generic-step $word
}

proc step-from-menu {} {
    set old [focus]
	set word [dialog-prompt "Enter the word to single step"]
	if {$word == ""} {return}
    generic-step $word
    focus $old
}

proc show-source-code {word} {
    global log edit_log
    $edit_log tag configure ip -background green
    push-source $word
    edit-source $word
    focus $log
}
proc tick {} {
    set word [next-word]
    if {![isforth $word]} {
        if {![ishiddenforth $word]} {
            show-prompt
            error "Not in Symbol Table"
        } else {
            set num [lookuphidden $word]
        }
    } else {
        set num [lookupforth $word]
    }
	if [not-number $num] {
		show "?"
		show-prompt
		error "Not a valid forth word"
	}
	execute-number $num
}

source disassembler.tcl

# catch the kill of the windowmanager
wm protocol . WM_DELETE_WINDOW exitapp


# Top level functions, executed at startup.

$log insert end $version
show "\n"

if {$commname != "No Comm"} {
	open-comm
}
if {[file exists "symbols.log"]} {
	read-symbol-table
}
if {$using_windows == 1} {
	focus -force $log
} else {
	focus $log
}
reconfigure
font-size $default_size
update-info
set cur_dir $argv0

