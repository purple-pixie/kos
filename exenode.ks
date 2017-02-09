// execute maneuver node
run once steer_utils.
run once engine_utils.
set nd to nextnode.
output(" Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag)).
output(" Node apoapsis: " + round(nd:obt:apoapsis/1000) + "km, periapsis: " + round(nd:obt:periapsis/1000) + "km").
set maxda to maxthrust/mass.
output(" Max DeltaA for engine: " + round(maxda)).
set dob to burn_time(nd:deltav:mag). // correct: uses tsiolkovsky formula
output(" Duration of burn: " + round(dob)).

output(" Warping to maneuver...").
warpfor(nd:eta - dob/2 - 45).
// turn does not work during warp - so do now
output(" Turning ship to burn direction.").
sas off.
rcs on.
// workaround for steering:pitch not working with node assigned
lock np to R(0,0,0) * nd:deltav.
lock steering to np.
wait until abs(np:direction:pitch - facing:pitch) < 0.1 and abs(np:direction:yaw - facing:yaw) < 0.1.
rcs off.
warpfor(nd:eta - dob/2).

output(" Orbital burn start " + round(nd:eta) + "s before apoapsis.").
// lock steering to node:prograde which wanders off at small deltav
if nd:deltav:mag > 2*maxda {
    when nd:deltav:mag < 2*maxda then {
        output(" Reducing throttle, deltav " + round(nd:deltav:mag) + ", fuel:" + round(stage:liquidfuel)).
        // continue to accelerate node:deltav
        set np to R(0,0,0) * nd:deltav.
    }
}
set tvar to 0.
lock throttle to tvar.
until nd:deltav:mag < 1 or stage:liquidfuel = 0 {
    set da to maxthrust*throttle/mass.
    set tset to nd:deltav:mag * mass / maxthrust.
    if nd:deltav:mag < 2*da and tset > 0.1 {
        set tvar to tset.
    }
    if nd:deltav:mag > 2*da {
        set tvar to 1.
    }
    print "Throttle: " + round(tset) at (0,29).
    print "DeltaA: " + round(da) at (20,29).
    print "Node DeltaV: " + round(nd:deltav:mag) at (0,30).
    print "Apoapis: " + round(apoapsis/1000) at (0,31).
    print "Periapis: " + round(periapsis/1000) at (20,31).
}
// compensate 1m/s due to "until" stopping short; nd:deltav:mag never gets to 0!
if stage:liquidfuel > 0 {
    //1m/s is a massive error for small maneuvers. Undershoot is better.
    wait 0.1.
    //wait 1/da.
    
}
lock throttle to 0.
unlock steering.
remove nextnode.
output(" Burn complete, apoapsis: " + round(apoapsis/1000) + "km, periapsis: " + round(periapsis/1000) + "km").
output(" Fuel after burn: " + round(stage:liquidfuel)).
