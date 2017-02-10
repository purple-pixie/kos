@LAZYGLOBAL OFF.
run once orbit_utils.
run once rendezvous_utils.
run once draw_utils.
run once util.
//print node_eta().
//print warp_to_next_node().


//just remove any existing nodes. don't call random test scripts, kids.
function remove_nodes {
    for nd in allnodes
      remove nd.
  }

 remove_nodes().
 add match_apoapsis(ship, target:obt).
 //add match_inclination(ship, target:obt).
 print trueanom_offset(ship:obt, nextnode:orbit).
 draw_ship_at(ship, time:seconds+obt:period).
//  print "inclination match: " + nd:deltav:mag + " m/s".
//  run pilot.
//set nd to set_apoapsis_at_trueanom(ship, 2200000, 120).
// print "AP and ArgOfP match: " + nd:deltav:mag + " m/s".

// run pilot.
// add match_apoapsis_ext(ship, ship:obt, target).
// print "inc->apo: " + total_planned_dv().


// remove_nodes().
// add match_apoapsis(ship, target).
// add match_inclination(ship, target:obt).
// print "apo->inc: " + total_planned_dv().




//local int is intersect_trueanom(obt, target:obt, 2, 0.01).
//if int = -1 { print "no interset found with target".}
//else {add node(time:seconds+eta_to_trueanom(obt, int[0]),0,0,0).}

//straight match orbit at intersect: 294 m/s

//matching across target periapse: 201 m/s (total)


//15deg vs 0.
//incline then match AP pos
//123 + 177 = 300

//match ap then incline
//146 + 71 = 201 m/s
//definitely the answer from a smaller orbit
