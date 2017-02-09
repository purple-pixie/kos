//steer_utils.
//steer function and obselete warp code

run once util.
function steer {
    declare parameter fset.
    declare parameter tolerance is 0.02.
    output(" Turning to face " + fset). //solar panels...").
    sas off.
    // lock fset to arg.
    lock steering to fset.
    wait until abs(sin(fset:pitch) - sin(facing:pitch)) < tolerance and abs(sin(fset:yaw) - sin(facing:yaw)) < tolerance.
    unlock steering.
    sas on.
    output(" Steering done.").
}

function warpfor {
    declare parameter dt.
    warpto(time:seconds+dt).
}
function warpdys {
    declare parameter y,d,s.
    set dt to (y*365+d)*21600 + s.
    warpto(time:seconds+dt).
}

function warpto {
    declare parameter t1.
    // warp    (0:1) (1:5) (2:10) (3:50) (4:100) (5:1000) (6:10000) (7:100000)
    // min alt        atmo   atmo   atmo    120k     240k      480k       600k
    set dt to t1 - time:seconds.
    if dt < 0 {
        output(" Warning: wait time " + round(dt) + " is in the past.").
    }
    if dt >= 21600 {
        output(" Waiting for " + round(dt/21600) + "d" + mod(round(dt),21600) + "s").
        output(" Wait start @ " + time:calendar + ", " + time:clock).
    }
    set oldwp to 0.
    until time:seconds >= t1 {
        set rt to t1 - time:seconds.       // remaining time
        set wp to 0.
        if rt > 5      { set wp to 1. }
        if rt > 30     { set wp to 2. }
        if rt > 300    { set wp to 3. }
        if rt > 600    { set wp to 4. }
        if rt > 6000   { set wp to 5. }
        if rt > 60000  { set wp to 6. }
        if rt > 600000 { set wp to 7. }
        set warp to wp.
        if not (wp = oldwp) {
            output(" Warp " + warp + ", remaining wait " + round(rt) + "s").
            set oldwp to wp.
        }
        wait 0.5.
    }
    if dt >= 21600 {
        output(" Wait complete @ " + time:calendar + ", " + time:clock).
    }
}