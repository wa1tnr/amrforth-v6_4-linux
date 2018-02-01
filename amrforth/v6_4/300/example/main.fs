\ main.fs  Example code for the f300

: delay  (  - ) 6000 for 10 for next next ;

: go  (  - )
    init-adc init-leds
    begin
        adc@ . cr
        -P0.2 -P0.3 -P0.1 -P0.6 -P0.7 delay
        +P0.2 +P0.3 +P0.1 +P0.6 +P0.7 delay
    again -;
