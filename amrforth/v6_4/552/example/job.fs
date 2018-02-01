\ job.fs
: 2dup  ( n1 n2 - n1 n2 n1 n2) over over ;
: ?dup  ( n - 0 | n n) dup if  dup  then ;
include iic552.fs
include 16key.fs
include lcd.fs
0 [if]
: test  (  - )
    lcd-dark
    begin
        button lcd-emit
    again -;
[then]
