\ testumstar.fs
\ This program creates a list of multiplication problems and their
\ answers around byte boundaries in hex.  The file gforthumstar.fs does
\ the same thing on the host computer.  If we believe the answers
\ given by gforth then we can compare the answers given by amrFORTH and
\ be fairly confident that um* works.  The answers are in hex because
\ amrFORTH doesn't have a d. word.
create multipliers
$0000 , $0001 , $0002 , $00fe , $00ff ,
$0100 , $0101 , $0102 , $01fe , $01ff ,
$fe00 , $fe01 , $fe02 , $fefe , $feff ,
$ff00 , $ff01 , $ff02 , $fffe , $ffff ,
: num  ( i - n) 2* multipliers + @ ;
: testone  ( i1 i2 - )
    over num dup h. ." * " over num dup h. ." = "
    um* h. h. cr 10000 for next ;
: test  (  - )
    cr 1 1 
    19 for
        19 for
            testone 1+
        next
        drop 1+ 1
    next  2drop ;
