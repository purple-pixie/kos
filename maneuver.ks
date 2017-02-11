//maneuver.
//perform the next maneuver node.
// requires a node set or will crash
parameter do_warp is false.

run once engine_utils.

run once util.

set done to false.
DECLARE GLOBAL MANEUVER_FAILED IS FALSE.

set nd to nextnode.

set tset to 0.

lock throttle to tset.

print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

set fuel_burned to burn_mass(nd:deltav:mag) * 90.

if fuel_burned > ship:liquidfuel {

    print "Insufficient fuel to complete burn. Aborting".

    set done to true.
    SET MANEUVER_FAILED TO TRUE.

}

else {

    if fuel_burned > stage:liquidfuel {
        print "WARNING: insufficient fuel in stage, burn timing may be inaccurate".
        print "WARNING: cannot guarantee future stages even have sufficient dV".
    }


    //calculate ship's available acceleration
    set max_acc to ship:availablethrust/ship:mass.

    set total_burn to burn_time(nd:deltav:mag).
    set half_burn to burn_time(nd:deltav:mag/2).

    print "Tsiolkovsky-calculated burn duration: " + round(total_burn) + "s".
    if (do_warp) {
      warp_until(time:seconds + nd:eta - (half_burn + 60)).
    }
    wait until time:seconds + nd:eta - (half_burn + 60).

    set np to nd:deltav:direction. //points to node, don't care about the roll direction.
    sas off.
    lock steering to np.

    //now we need to wait until the burn vector and ship's facing are aligned
    wait until abs(np:pitch - facing:pitch) < 0.15 and abs(np:yaw - facing:yaw) < 0.15.
    //the ship is facing the right direction, let's wait for our burn time
    if (do_warp)
      warp_until(time:seconds + nd:eta - half_burn ).
    wait until nd:eta <= half_burn.

    //initial deltav

    set dv0 to nd:deltav.

    set tolerance to 0.1.
    //tighter tolerance for smaller maneuvers - if they were planned then presumably we have the accuracy to hit them
    if dv0:mag < 10 { set tolerance to 0.001. }

    until done

    {

        if stage:liquidfuel = 0 {
            set done TO true.
            SET MANEUVER_FAILED TO TRUE.
            }
        else {
            //recalculate current available_acceleration, as it changes while we burn through fuel

            set max_acc to ship:availablethrust/ ship:mass.



            //throttle is 100% until there is less than 1 second of time left to burn

            //when there is less than 1 second - decrease the throttle linearly

            set tset to min(nd:deltav:mag /max_acc, 1).



            //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions

            //this check is done via checking the dot product of those 2 vectors

            if vdot(dv0, nd:deltav) < 0

            {

               // print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).

                lock throttle to 0.

                break.

            }



            //we have very little left to burn, less then 0.1m/s

            if nd:deltav:mag < tolerance

            {

               // print "Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).

                //we burn slowly until our node vector starts to drift significantly from initial vector

                //this usually means we are on point

                wait until vdot(dv0, nd:deltav) < 0.5.



                lock throttle to 0.

                //print "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1).

                set done to True.

            }
        }
    }
  }

  unlock steering.
  sas on.
  unlock throttle.
  //set throttle to 0 just in case.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
  //we no longer need the maneuver node
  remove nd.
  wait 1.
