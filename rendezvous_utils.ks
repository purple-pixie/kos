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
@lazyglobal off.
run once orbit_utils.
run once draw_utils. // DEBUG

//
function ascending_node_trueanom {
    declare parameter orbit_1.
    declare parameter orbit_2.
    parameter offset is orbit_1:trueanomaly.


    local node_pos is vcrs(orbit_normal(orbit_1), orbit_normal(orbit_2)).
    local orbit_1_pos is orbit_1:position - orbit_1:body:position.
    local theta is vang(node_pos, orbit_1_pos). //angle between the node and orbit_1's position (from the centre of the orbited body)
    local sign_vector is vcrs(orbit_1_pos, node_pos).
    if vdot(orbit_normal(orbit_1), sign_vector) < 0  { set theta to 360-theta. }
    return theta + offset.
}

//how far ahead of orbit 2's TA is orbit 1's
function trueanom_offset {
  parameter orbit_1.
  parameter orbit_2.
  return (orbit_1:argumentofperiapsis + orbit_1:lan) -
    (orbit_2:argumentofperiapsis + orbit_2:lan).
}

//calcualtes the true anomaly of the next intersect found, or -1 if none
//returns a list of the true anomaly from orbit_1's reference frame
// and from orbit_2's.
//(or just -1. Not a list)
function intersect_trueanom {
  parameter orbit_1, orbit_2, speed, precision.

  local ta_diff is trueanom_offset(orbit_1, orbit_2).
  //print "TA offset: " + ta_diff.
  local initial_ta is orbit_1:TrueAnomaly.
  local dist_old is 0.
  local dist is 0.
  local ta is initial_ta.
  until (ta - initial_ta) > 360 {
    set dist to alt_from_trueanom(orbit_1, ta) -
                alt_from_trueanom(orbit_2, ta + ta_diff).
    if (dist * dist_old) < 0 {
      //direction change in distance between orbits
      //i.e the two orbits have crossed each other
      if abs(speed) < precision {
        //we have a crossing at the specified accuracy, return it
    //    print "found at speed " + speed + " at: " + mod(ta, 360).
        return List(mod(ta, 360), mod(ta+ta_diff, 360)).
      }
      //else { print "intersect passed at speed " + speed + ", reversing search at: " + mod(ta, 360).}
      set speed to -speed/10.
    }
    set dist_old to dist.
    set ta to ta + speed.
  }
return -1. //we did a complete loop and never found a hit :(
}


// smart version - assumes planed maneuvers are executed
// and plans its maneuver for after the last current one
function match_inclination_smart {
    parameter vessel_1, orbit_2.

    //we're not needed
    if not hasnode { return match_inclination(vessel_1, orbit_2).}
    local orbit_1 is 0.
    local an is allnodes.
    local nd is an[an:length-1].
    // allow a minute after the last node to make sure we have time to turn
    //and to finish that maneuver
    local epoch is time:seconds + nd:eta + 60.
    local orbit_1 is nd:orbit.
    local burn_normal_direction is orbit_normal(orbit_1).
    // this should also be the same direction, it's just the prograde we
    // compare with that might have changed (due to maneuver nodes)
    local burn_direction is (burn_normal_direction + orbit_normal(orbit_2)):normalized.

    // this trueanom value is all based on current values
    // this won't give meaningful data if there are maneuvers planned
    // need to set an epoch after the last maneuver
    // and use the resulting node:orbit as our orbit for all this
    // note this will then probably break eta_to_trueanom since we aren't really
    // in that orbit yet
    // eta_to_trueanom will need to accept a ta argument and not assume it's now
    // add that amount of time to eopch and we have our ut
    local node_trueanom is ascending_node_trueanom(orbit_1, orbit_2).

    //we want to perform the burn at the higher of the two nodes, since it will cost less
    //if the node's true anomaly is closer to our periapsis than to our apoapsis
    //then it is the lower, so swap to the node on the other side of the orbit
    //print "ascending node at " + node_trueanom + " degrees".
    if node_trueanom > 270 { set node_trueanom to node_trueanom - 180. }
    else { if node_trueanom < 90 { set node_trueanom to 180 + node_trueanom. } }
    //print "highest node at " + node_trueanom + " degrees".

    //assumes wrong TA values
    local burn_eta is eta_to_trueanom(orbit_1, node_trueanom).
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


function match_inclination {
    parameter vessel_1, orbit_2.

    local burn_normal_direction is orbit_normal(vessel_1:obt).
    local burn_direction is (burn_normal_direction + orbit_normal(orbit_2)):normalized.
    local node_trueanom is ascending_node_trueanom(vessel_1:obt, orbit_2).

    //we want to perform the burn at the higher of the two nodes, since it will cost less
    //if the node's true anomaly is closer to our periapsis than to our apoapsis
    //then it is the lower, so swap to the node on the other side of the orbit
    //print "ascending node at " + node_trueanom + " degrees".
    if node_trueanom > 270 { set node_trueanom to node_trueanom - 180. }
    else { if node_trueanom < 90 { set node_trueanom to 180 + node_trueanom. } }
    //print "highest node at " + node_trueanom + " degrees".
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


//matches one apsis height to the target's apoapsis
//the opposite will remain at whatever height it was previously
//the resulting semi-major-axis will be based on the height where the burn is performed
//(orbit_2's periapsis projected onto vessel_1's orbit from the body)
// and the apoapsis of orbit_2.
//and matches argumentofperiapsis with the target orbit
//argumentofperiapsis will only be close for eccentric orbits
//(for low-eccentricity orbits it could be anywhere but that should be fine)
function match_apoapsis {
  parameter vessel_1, orbit_2.

  local ta_diff is trueanom_offset(orbit_2, vessel_1:obt).
  return set_apoapsis_at_trueanom(vessel_1, orbit_2:apoapsis, ta_diff).
}
