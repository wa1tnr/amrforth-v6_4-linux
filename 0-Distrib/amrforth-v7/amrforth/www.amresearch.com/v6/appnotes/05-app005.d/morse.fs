\ morse.fs  Morse Code Generator

: within  ( n lo hi - flag)
    push over pop <  push < not  pop and ;

\ Convert character to uppercase if need be.
: upc  ( c1 - c2)
    dup [char] a [ char z 1 + ] literal
    within if  $df and  then ;

code init-mstimer  (  - )
    $08 # PCA0MD mov    \ Sysclk/1
    $49 # PCA0CPM0 mov  \ Software Timer (Compare) Mode
    $40 # PCA0CN mov    \ Start the timer.
    $08 # EIE1 orl  \ Enable pca interrupt.
    $80 # IE orl    \ Enable global interrupts.
    next c;

\ 24.5 MHz = 24500 cycles per millisecond.
24500 $ff and constant ms-lo
24500 256 / $ff and constant ms-hi

cvariable wpm-counter

label pca-interrupt  (  - )
    ACC push  PSW push
    0 .PCA0CN set? if
        wpm-counter direct A mov
        0<> if  wpm-counter direct dec  then
        \ Set up for next interrupt in 1 ms.
        ms-lo # A mov  PCA0CPL0 A add  A PCA0CPL0 mov
        ms-hi # A mov  PCA0CPH0 A addc  A PCA0CPH0 mov
    then
    $40 # PCA0CN mov  \ Clear interrupt bit.
    PSW pop  ACC pop
    reti c;
pca-interrupt $4b int!

code ms  ( c - )
    SP inc  Apop  A wpm-counter direct mov
    begin  wpm-counter direct A mov  0= until
    next c;

\ Using PARIS as the standard sized word,
\ there are 50 counts or space values per word.
\ ms = (1/((wpm*50)/60sec/min))*1000
\ ms = 1000/(wpm*50/60)
\ ms = 1000*60/wpm*50
\ ms = 1200/wpm

cvariable duration
: wpm  ( wpm - ) 1200 swap / duration c! ;

code enable-sound  (  - )
    $04 # P0MDOUT orl  \ pin 0.2 is push/pull output.
    next c;

label t2-interrupt
    2 .P0 cpl  \ Toggle the piezo transducer pin.
    7 .TMR2CN clr  \ Clear the interrupt bit.
    reti c;
t2-interrupt $2b int!  \ Install at interrupt vector.

code steps  ( n - )
    Apop  A cpl  A TMR2RLH mov
    Apop  A cpl  A TMR2RLL mov
    next c;

code noise-on  (  - )
    $04 # TMR2CN mov  \ Auto-reload, timer on.
    5 .IE setb  \ Enable the T2 interrupt.
    7 .IE setb  \ Enable global interrupts.
    next c;

code noise-off  (  - )
    5 .IE clr  \ Disable the T2 interrupt.
    $00 # TMR2CN mov  \ Turn timer 2 off.
    next c;

\ T2 runs at a rate of 24.5 Mhz divided by 12.
\ This means 24.5/12=2.0416666 us per step.
\ That equals 0.000002041666 sec per step.
\ Invert that to get 489796 steps per sec.
\ Frequency = cycles per sec = (steps/sec)/steps
\ Let n = number of steps per toggle, that's half a cycle.
\ freq = (489796/n)*2  (Multiply by 2 for a full cycle.
\ freq = 979592/n
\ n = 979592/freq
\ subtract n from 65535 and store that
\ in the timer reload registers.

: hz>steps  ( n1 - n2)
    30 max 2000 min
    push 979592. pop um/mod nip ;

\ Specify the frequency of the sound in Hz.
: hz  ( n - ) enable-sound hz>steps steps ;

: space   (  - ) duration c@ ms ;
: letter  (  - ) space space ;
: word    (  - ) space space space space ;

: .  (  - ) noise-on space noise-off space ;
: -  (  - ) noise-on space space space noise-off space ;

: A  . -      letter ;
: B  - . . .  letter ;
: C  - . - .  letter ;
: D  - . .    letter ;
: E  .        letter ;
: F  . . - .  letter ;
: G  - - .    letter ;
: H  . . . .  letter ;
: I  . .      letter ;
: J  . - - -  letter ;
: K  - . -    letter ;
: L  . - . .  letter ;
: M  - -      letter ;
: N  - .      letter ;
: O  - - -    letter ;
: P  . - - .  letter ;
: Q  - - . -  letter ;
: R  . - .    letter ;
: S  . . .    letter ;
: T  -        letter ;
: U  . . -    letter ;
: V  . . . -  letter ;
: W  . - -    letter ;
: X  - . . -  letter ;
: Y  - . - -  letter ;
: Z  - - . .  letter ;

: #0  - - - - -  letter ;
: #1  . - - - -  letter ;
: #2  . . - - -  letter ;
: #3  . . . - -  letter ;
: #4  . . . . -  letter ;
: #5  . . . . .  letter ;
: #6  - . . . .  letter ;
: #7  - - . . .  letter ;
: #8  - - - . .  letter ;
: #9  - - - - .  letter ;

: period      . - . - . -  letter ;
: comma       - - . . - -  letter ;
: colon       - - - . . .  letter ;
: question    . . - - . .  letter ;
: apostrophe  . - - - - .  letter ;
: hyphen      - . . . . -  letter ;
: fraction    - . . - .    letter ;
: paren       - . - - . -  letter ;
: quote       . - . . - .  letter ;

\ Default action for illegal characters.
: ---  (  - ) ;

: translate  ( c - )
    upc -31 + 0 max 60 min exec:
    --- word --- quote --- --- ---
    --- apostrophe paren paren ---
    --- comma hyphen period fraction
    #0 #1 #2 #3 #4 #5 #6 #7 #8 #9
    colon --- --- --- --- question ---
    A B C D E F G H I J K L M
    N O P Q R S T U V W X Y Z ---
    -;

: x-on   (  - ) $11 emit ;  \ ^Q for Continue
: x-off  (  - ) $13 emit ;  \ ^S for Stop

\ This is where the x-on/x-off is handled.
\ We only turn x-on when we have an empty buffer.
\ This is as conservative as we can get.
: key-echo  (  - c)
    key? not if  x-on  then  key x-off dup emit ;

: get-number  (  - n)
    0
    begin
        key-echo
        dup [char] 0 [ char 9 1 + ] literal
        within not if  drop exit  then
        [ char 0 negate ] literal + swap 10 * +
    again -;

: change-hz   (  - ) get-number hz ;
: change-wpm  (  - ) get-number wpm ;

: check  ( c1 - c2)
    dup [char] ` = if
        drop key-echo dup [char] \ = if
            drop key-echo upc
            dup [char] H = if
                drop change-hz key-echo exit
            then
            dup [char] W = if
                drop change-wpm key-echo exit
            then
        then
    then ;

: init  (  - ) init-mstimer  1300 hz  13 wpm ;

: go  (  - )
    init
    begin
        key-echo check translate
    again -;
