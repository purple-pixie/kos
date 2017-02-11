@LAZYGLOBAL OFF.
//util.
//general utilities for kOS scripts.

//for some weird reason this is more accurate.
global g is 9.82. // KERBIN:MU / KERBIN:RADIUS^2.

function output {
    //print text. optionally prints mission elapsed time too
    declare parameter text.
    declare parameter showtime is true.
    if (showtime) {print "T+" + round(missiontime) + text.}
    else { print text.}
}

function error {
    unlock throttle.
    set throttle to 0.
    unlock steering.
    print "Script aborted" + 1/0.
}

function circularise {
    //circularise orbit at apoapse, or if at_pe is true at periapse.
    parameter at_pe is false.
    local nd is 0.
    if at_pe {
         local current is velocityat(ship,time+eta:periapsis):orbit:mag.
         local desired is sqrt(kerbin:mu / ship:periapsis+kerbin:radius).
         set nd to Node(time:seconds+eta:periapsis, 0, 0, desired-current).
     }
     else
     {
         local current is velocityat(ship,time+eta:apoapsis):orbit:mag. // sqrt(kerbin:mu * (2/AP - 1/ship:obt:semimajoraxis)).
         local desired is sqrt(kerbin:mu / ship:apoapsis+kerbin:radius).
         set nd to Node(time:seconds+eta:apoapsis, 0, 0, desired-current).
     }
     add nd.
}

function total_planned_dv {
  local sum is 0.
  for nd in allnodes { set sum to sum + nd:deltav:mag. }
  return sum.
}

function warp_until {
    // Warp to arbitrary time, uses KAC if possible else use steer_utils' warpto()
    parameter endtime.
    parameter notes is "".
    if addons:available("KAC") {
        local dt is endtime - time:seconds.
        local alarm is ADDALARM("Raw",endtime,"kOS maneuver alarm", notes).
        local wp is 1.
        if dt > 5      { set wp to 2. }
        if dt > 30     { set wp to 3. }
        if dt > 100    { set wp to 4 .}
        if dt > 1000   { set wp to 5. }
        if dt > 10000  { set wp to 6. }
        if dt > 100000 { set wp to 7. }
        set warp to wp.
        wait until alarm:remaining < 2.
        set warp to 0.
        deletealarm(alarm:id).
    }
    else
    {
        run once steer_utils.
        warpto(endtime).
    }
}
