// n : Mean Notion
// P: Orbital Period
// M: Mean Anomaly (Current)
// E: Eccentric Anomaly
// e: Eccentricity
// theta: True Anomaly
// a: Semi-Major Axis

// M1 = Mean Anomaly of First Node (wether its ascending or descending depends on inclination) = pi/2 - e

// M2 = Mean Anomaly of Second Node (this will be the opposite of the first node) = 3*pi/2 - e

//if theta > 270 (remember max is 360, then resets to 0) OR theta < 90 { Use M1}
// if theta > 90 AND theta < 270 { Use M2 }

//n = 2*pi/P
//t = Time to Next Node = (Mx - M)/n (Mx is either M1 or M2 depending on where you are on the orbit)

run once orbit_utils.
run once draw_utils. // DEBUG

function ascending_node_trueanom {
    declare parameter orbit_1.
    declare parameter orbit_2.
    
    
    local node_pos is vcrs(orbit_normal(orbit_1), orbit_normal(orbit_2)).
    local orbit_1_pos is orbit_1:position - orbit_1:body:position.
    local theta is vang(node_pos, orbit_1_pos). //angle between the node and orbit_1's position (from the centre of the orbited body)
    local sign_vector is vcrs(orbit_1_pos, node_pos).
    if vdot(orbit_normal(orbit_1), sign_vector) < 0  { set theta to 360-theta. }
    return theta + orbit_1:trueanomaly.
}

function warp_to_next_node {
    //run once util.
    print "deprecated | warp_to_next_node".
   // warp_until(time:seconds+node_eta()).
}

function match_inclination {
    parameter vessel_1, orbit_2.
    local burn_normal_direction is orbit_normal(vessel_1:obt).
    local burn_direction is (burn_normal_direction + orbit_normal(orbit_2)):normalized.
    local node_trueanom is ascending_node_trueanom(vessel_1:obt, orbit_2).
    
    //we want to perform the burn at the higher of the two nodes, since it will cost less
    //if the node's true anomaly is closer to our periapsis than to our apoapsis
    //then it is the lower, so swap to the node on the other side of the orbit
    print "ascending node at " + node_trueanom + " degrees".
    if node_trueanom > 270 { set node_trueanom to node_trueanom - 180. }
    else { if node_trueanom < 90 { set node_trueanom to 180 + node_trueanom. } }
    print "highest node at " + node_trueanom + " degrees".
    local burn_eta is eta_to_trueanom(vessel_1:obt, node_trueanom).
    local burn_ut is burn_eta + time:seconds.
    local vel_at_burn is velocityat(vessel_1, burn_eta + time:seconds):orbit.
    
    //radial element will be zero because it's just an inclination change
    //local burn_radial_direction is (positionat(vessel_1, burn_ut)-body:position):normalized.
    
    local burn_mag is -2*vel_at_burn:mag*cos(vang(vel_at_burn,burn_direction)).
    local a2p is vang(vel_at_burn,burn_direction) .
    local a2n is vang(burn_normal_direction,burn_direction).
    
    if burn_mag > vel_at_burn:mag { 
        print "WARNING: BURN EXCEEDS CURRENT ORBITAL SPEED. ".
        print "continuing anyway".
    }
    local nd is node(burn_eta + time:seconds,0,-burn_mag*cos(a2n),burn_mag*cos(a2p)).
    return nd.
}