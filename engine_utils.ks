// engine_utils.
// utilities relating to the engines and fuel.
// all utilities respect thrust limiting tweakables.

function current_isp {
    // current effective ISP of the ship - 
    // = the sum of  (ISP * that engines percentage of the ship's total thrust) for each engine
    local isp is 0.
    set available to ship:availablethrust.
    list engines in eng.
    for en in eng {
        if en:ignition {
            set isp to isp + (en:isp * en:availablethrust / available).
        }
    }
    return isp.
}

function maxfuelflow {
    //maximum available fuel flow in tons/s
    //respects thrust limiters
    local flow is 0.
    list engines in eng.
    for en in eng {
        if en:ignition {
            set flow to flow + (en:availablethrust / (en:isp * g)).
        }
    }
    return flow.
}

function burn_mass {
    parameter deltav.
    set m0 to ship:mass.
    if ship:availablethrust = 0 { print "WARNING, NO ACTIVE ENGINES. EXPECT A DIVIDE BY ZERO.".}
    set m1 to m0 * constant:e ^ (-deltav / (g * current_isp())).
    return m0-m1.
}
function burn_time {
    parameter deltav.
    return (burn_mass(deltav) / maxfuelflow()).
}