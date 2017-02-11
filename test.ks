@LAZYGLOBAL OFF.

parameter compiled is false.
print "test begin".
// run once draw_utils.
if compiled
  run once compile_test.
else {
  run once util.
  run once orbit_utils.
  run once rendezvous_utils.
}
// run once compile_test.
local t1 is time.
print "compiled".
//print node_eta().
//print warp_to_next_node().

//just remove any existing nodes. don't call random test scripts, kids.
function remove_nodes {
    for nd in allnodes
      remove nd.
  }

 remove_nodes().
 print "nodes removed".
 local nd is -1.
 // set nd to match_apoapsis(ship, target:obt).
 set nd to match_spacetime(ship, target, 1, 0.001).
 // add match_inclination(ship, target:obt).
 //add match_apo_inc(ship, target:obt).
 //wait until not hasnode.
 // draw_line( { return nextnode:obt:position. }, {return nextnode:obt:velocity:orbit.}).
 if not (nd = -1) { add nd. }
 else {print "match failed".}

print "elapsed game time: " + (time:seconds - t1:seconds).
