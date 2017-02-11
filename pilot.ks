//auto pilot.
// performs all maneuvers planned for this ship then terminates.
parameter do_warp is false.
print "Autopilot engaged".
until not hasnode {
    run maneuver(do_warp).
    if MANEUVER_FAILED {
        print "cannot perform maneuver or out of fuel, cancelling autopilot".
        set warp to 0.
        // for nd in allnodes
        //   remove nd.
        break.
    }
}
print "Autopilot shutting down, have a pleasant flight".
