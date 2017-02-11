// launch to orbit (w/ atmosphere)

clearscreen.
// gravity turn parameters.
set gt0 to 1000.
set theta0 to 0.
set gt1 to 50000.
set theta1 to 90.
// constants
run once util.
run once launch_utils.
run once orbit_utils.
bodyprops().

print "Launch program start at: " + time:calendar + ", " + time:clock.
set tset to 1.
lock throttle to tset.
lock steering to up + R(0, 0, -180).
print "T-1  All systems GO. Ignition!".
set ralt to alt:radar + 15.          // ramp altitude
when alt:radar > ralt then {
    output(" Liftoff.").
}
wait 1.
output(" Ignition.").
auto_stage(true). 


when alt:radar > gt0 then {
    output(" Beginning gravity turn.").
}

// control speed and attitude
set vt to 200.
when alt:radar > 5000 then {
    set vt to 350.
    when alt:radar > 13000 then { set vt to 2500. }
}
until altitude > ha or apoapsis > lorb {
    set ar to alt:radar.
    // control attitude
    if ar > gt0 and ar < gt1 {
        set arr to (ar - gt0) / (gt1 - gt0).
        set pda to (cos(arr * 180) + 1) / 2.
        set theta to theta1 * ( pda - 1 ).
        lock steering to up + R(0, theta, -180).
        print "theta: " + round(theta) at (0,25).
    }
    if ar > gt1 {
        lock steering to up + R(0, theta, -180).
    }
    // control speed - TODO: limit drag
    // calculate target velocity
    set vl to vt*0.9.
    set vh to vt*1.1.
    set vsm to velocity:surface:mag.
    if vsm < vl { set tset to 1. }
    if vsm > vl and vsm < vh { set tset to (vh-vsm)/(vh-vl). }
    if vsm > vh { set tset to 0. }
    print "alt:radar: " + round(ar) at (0,28).
    print "velocity:surface: " + round(vsm) at (0,29).
    print "throttle: " + round(tset,2) + "  " at (0,30).
    print "apoapis: " + round(apoapsis/1000) at (0,31).
    print "periapis: " + round(periapsis/1000) at (20,31).
    wait 0.5.
}
set tset to 0.
if altitude < ha {
    output(" Waiting to leave atmosphere").
    lock steering to up + R(0, theta, 0).       // roll for orbital orientation
}
// thrust to compensate atmospheric drag losses
until altitude > ha {
    // calculate target velocity
    if apoapsis >= lorb { set tset to 0. }
    if apoapsis < lorb { set tset to (lorb-apoapsis)/(lorb*0.01). }
    print "altitude: " + round(altitude) at (0,30).
    print "throttle: " + round(tset,2) + "   " at (20,30).
    print "apoapis: " + round(apoapsis) at (0,31).
    print "periapis: " + round(periapsis/1000) at (20,31).
}
lock throttle to 0.
circularise().
run pilot.
lock face to R(-90,0,0).
steer(face).
output(" Configuring for orbit...").
ag2 on.     // extend antenna
