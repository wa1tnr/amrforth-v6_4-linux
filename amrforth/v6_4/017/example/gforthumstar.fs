\ gforthumstar.fs
\ This program creates a list of multiplication problems and their
\ answers around byte boundaries in hex.  The file testumstar.fs does
\ the same thing on the microcontroller.  If we believe the answers
\ given by gforth then we can compare the answers given by amrFORTH and
\ be fairly confident that um* works.  The answers are in hex because
\ amrFORTH doesn't have a d. word.
create multipliers
$0000 , $0001 , $0002 , $00fe , $00ff ,
$0100 , $0101 , $0102 , $01fe , $01ff ,
$fe00 , $fe01 , $fe02 , $fefe , $feff ,
$ff00 , $ff01 , $ff02 , $fffe , $ffff ,
: num  ( i - n) 2* 2* multipliers + @ ;
: h.  ( n - )
    base @ >r hex
    0 <# # # # # #> type
    r> base ! space ;
: hh.  ( n - )
    base @ >r hex
    0 <# # # # # BL hold # # # # #> type
    r> base ! space ;
: testone  ( i1 i2 - )
    over num dup h. ." * "
    over num dup h. ." = "
    * hh. cr ;
: test  (  - )
    cr 1 1 
    19 0 do
        19 0 do
            testone 1+
        loop
        drop 1+ 1
    loop  2drop ;
