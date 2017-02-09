run once util.
run once orbit_utils.

function add_node {
    declare parameter alt.
    declare parameter at_peri is TRUE.
    set mu to body:mu.
    set rb to body:radius.
    set x to node(time:seconds + eta:periapsis, 0, 0, 0).
    if (at_peri) {
        // current speed at periapsis
        SET current to velocityat(ship,time+eta:periapsis):orbit:mag.        
        // semi major axis of desired orbit
        set a2 to (alt + 2*rb + periapsis)/2. 
        set desired to speed_at(rb + periapsis, a2).
    } else {
        // current speed at apoapsis
        SET current to velocityat(ship,time+eta:apoapsis):orbit:mag.        
        // semi major axis of desired orbit
        set a2 to (alt + 2*rb + apoapsis)/2. 
        set desired to speed_at(rb + apoapsis, a2).
        set x:eta to eta:apoapsis.
    }
        // set up node 
    set deltav to desired - current.
    set x:prograde to deltav.
    add x.
    output(" Apsis burn: " + round(current) + ", dv:" + round(deltav) + " -> " + round(desired) + "m/s").
}