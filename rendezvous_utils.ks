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
  //the true anomaly at which we can give up - 1 complete orbit away.
  local ta_failed is ta + 360.

  local sma_1 is orbit_1:semimajoraxis.
  local ecc_1 is orbit_1:eccentricity.
  local sma_2 is orbit_2:semimajoraxis.
  local ecc_2 is orbit_2:eccentricity.
  until ta > ta_failed {
    // set dist to alt_from_trueanom(orbit_1, ta) -
                // alt_from_trueanom(orbit_2, ta + ta_diff).
    set dist to
      sma_1 * (1-ecc_1^2) / (1 + ecc_1 * cos(ta)) -
      sma_2 * (1-ecc_2^2) / (1 + ecc_2 * cos(ta+ta_diff)).
    if (dist * dist_old) < 0 {
      //direction change in distance between orbits
      //i.e the two orbits have crossed each other
      if abs(speed) < precision {
        //we have a crossing at the specified accuracy, return it
    //    print "found at speed " + speed + " at: " + mod(ta, 360).
        return List(mod(ta, 360), mod(ta+ta_diff, 360)).
      }
      //else { print "intersect passed at speed " + speed + ", reversing search at: " + mod(ta, 360).}
      set speed to -speed/2.
    }
    set dist_old to dist.
    set ta to ta + speed.
  }
return -1. //we did a complete loop and never found a hit :(
}

function match_inclination {
    parameter vessel_1, orbit_2.

    if hasnode {
      print "nodes already on flight plan, cannot handle.".
      return -1.
    }
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

  if hasnode {
    print "nodes already on flight plan, cannot handle.".
    return -1.
  }
  local ta_diff is trueanom_offset(orbit_2, vessel_1:obt).
  return set_apoapsis_at_trueanom(vessel_1, orbit_2:apoapsis, ta_diff).
}

//match either apoapsis and inclination, depending on efficient order
// (if apo-match increases SMA then do that first, else match incline)
function match_apo_inc {
  parameter vessel_1, orbit_2.
  local orbit_1 is vessel_1:obt.
  //check if we're trying to increase or decrease semimajoraxis with the apo-match
  local desired_sma is (orbit_2:apoapsis + orbit_2:body:radius +
    alt_from_trueanom(orbit_1, trueanom_offset(orbit_2, orbit_1)))/2.
  print "delta SMA: " +(desired_sma - orbit_1:semimajoraxis).
  if desired_sma > orbit_1:semimajoraxis {
    return match_apoapsis(vessel_1, orbit_2).
  }
  else {
    return match_inclination(vessel_1, orbit_2).
  }
  return -1.
}

// calls match_spacetime and then tweaks the maneuver to get it within distance
function match_spacetime_precise {
  parameter vessel_1, orbitable_2, distance.
  local nd is match_spacetime(vessel_1, orbitable_2).
  // matching failed, can't really tweak that.
  if (nd = -1) { return -1.}

  add nd.

}

// match target orbit in space and time at target's apoapsis
// i.e. plan a close encounter with it
function match_spacetime {
    // not sold on using AP as a target.
    // there's a whole interset finding routine going to waste
  parameter vessel_1, orbitable_2, speed is 5, precision is 0.1.

  local orbit_1 is vessel_1:orbit.
  local orbit_2 is orbitable_2:orbit.
  local intersect_ta is intersect_trueanom(orbit_1, orbit_2, speed, precision).
  if (intersect_ta = -1) {
    print "NO INTERSECT FOUND".
    return -1.
  }
  //interseect_ta[0] is TA from orbit_1's reference
  //    [1] is from orbit_2's.

  //encounter_eta/ut refer to the next time orbit_1 hits the intersect.
  //positionat(orbit_2, encuonter_ut) will be orbit_2's position at this time.
  local encounter_eta is eta_to_trueanom(orbit_1, intersect_ta[0]).
  local encounter_ut is time:seconds + encounter_eta.

  local ap_1 is positionat(vessel_1, encounter_ut).
  local alt_ap_1 is (ap_1-body:position):mag.
  local ap_2 is positionat(orbitable_2, time:seconds + eta_to_trueanom(orbit_2, intersect_ta[1])).
  local orbit_2_pos_enc is positionat(orbitable_2, encounter_ut).


  // local line is -orbit_normal(orbit_1).
  // draw_delegates({return positionat(vessel_1, encounter_ut) - line.}, line, blue, "ap_1").
  // draw_line_to({return positionat(vessel_1, encounter_ut).}, line, blue, "ap_1").
  // draw_line_to( {return positionat(orbitable_2, time:seconds +
  //     eta_to_trueanom(orbit_2, intersect_ta[1])).}, line, red, "ap_2").
  // draw_line_to({return positionat(orbitable_2, encounter_ut).}, line, green, "target at enc").

  local orbit_2_ma_of_enc is MeanAnom_from_EccAnom(orbit_2:eccentricity,
          EccAnom_from_TrueAnom(orbit_2:eccentricity, intersect_ta[1])).
  local orbit_2_ta_enc is intersect_ta[1] - vang(orbit_2_pos_enc - orbit_2:body:position,
                    ap_2 - orbit_2:body:position).
  if orbit_2_ta_enc < 0
    {set  orbit_2_ta_enc to orbit_2_ta_enc + 360.}

  // print "distance of apoapses: " + (ap_1- ap_2):mag.
  // if (ap_1- ap_2):mag > 10000 {
  //   print "too far apart at orbit_2's apoapse, aborting".
  //   return -1.
  // }
  // print "distance in space at encounter: " + (ap_1 - positionat(orbitable_2,
  //       time:seconds + encounter_eta)):mag.


  local orbit_2_ma_enc is MeanAnom_from_EccAnom(orbit_2:eccentricity,
          EccAnom_from_TrueAnom(orbit_2:eccentricity, orbit_2_ta_enc)).
  // print "orbit_2's mean anomaly from encounter: " + (intersect_ta[1] - orbit_2_ma_enc).
  local period_ratio is orbit_1:period/orbit_2:period.

  local orbit_2_ma_enc_2 is (orbit_2_ma_enc+(orbit_1:period*360/orbit_2:period)).
  if orbit_2_ma_enc_2 > 360 { set orbit_2_ma_enc_2 to mod(orbit_2_ma_enc_2, 360).}
  else until orbit_2_ma_enc_2 > 0 { set orbit_2_ma_enc_2 to orbit_2_ma_enc_2 + 360.}


  local enc_2_ut is time:seconds+encounter_eta+orbit_1:period.


    // local orbit_2_pos_enc_2 is positionat(orbitable_2,enc_2_ut).
    // draw_line_to({return positionat(orbitable_2, enc_2_ut).}, line, purple, "target at enc2").
    // local orbit_2_ta_enc_2 is intersect_ta[1] - vang(orbit_2_pos_enc_2 - orbit_2:body:position,
    //                           ap_2 - orbit_2:body:position).
    //
    // local projected_orbit_2_ma_enc_2 is MeanAnom_from_EccAnom(orbit_2:eccentricity,
    //   EccAnom_from_TrueAnom(orbit_2:eccentricity, orbit_2_ta_enc_2)).
    //
    // print "orbit 2 ta of encounter: " + intersect_ta[1].
    // print "orbit 2 ta at enc 2: " + orbit_2_ta_enc_2.
    // print "orbit 2 ma at enc 2: " + orbit_2_ma_enc_2.
    // print "   projected: " + projected_orbit_2_ma_enc_2.

  //future encounters dont just depend on orbit_2's period but also orbit 1.
  // can ignore complete o2s but period_1 mod period_2 seconds will have effectively elapsed
  //
  //given the difference in mean anomalies from position at encounter
  local desired_period is orbit_1:period + (orbit_2_ma_of_enc-orbit_2_ma_enc_2)*orbit_2:period/360.
  if orbit_2_ma_enc_2 > orbit_2_ma_of_enc {
    set desired_period to desired_period + orbit_2:period.
  }

  local desired_sma is sma_from_period(vessel_1:body, desired_period).
  local speed_at_enc is velocityat(vessel_1, encounter_ut):orbit:mag.
  local desired_speed is speed_at(alt_ap_1, desired_sma, vessel_1:body).

  local nd is node(encounter_ut+0.001, 0, 0, desired_speed - speed_at_enc).

  print "Final distance at encounter: "+round((positionat(vessel_1, enc_2_ut) -
        positionat(orbitable_2, enc_2_ut)):mag).

  return nd.
}
