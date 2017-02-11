//  Test for gravity and acceleration sensors
run once util.
print "Checking sensors...".
set sense to check_sensors().

//  if found
if sense = 0 {
    print "Sensor check OK.".
    print "Initiating countdown.".
    countdown(1).
    // TAKEOFF
    auto_stage().
}
else
{
    print sense + " not found. Aborting launch".
    error().
}

//  SET UP DIRECTIONS
SET thrott TO 1.
SET dthrott TO 0.
LOCK THROTTLE TO thrott.
LOCK STEERING TO R(0,0,-90) + HEADING(90,90).

//  TODO: ADJUST HEADING BASED ON ALT.
//  MAKE THROTTLE MAKE BETTER DECISIONS

//  THROTTLE TRIGGERS FOR ATMOSPHERE
WHEN SHIP:ALTITUDE > 1000 THEN {
    SET g TO KERBIN:MU / KERBIN:RADIUS^2.
    LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
    LOCK gforce TO accvec:MAG / g.
    LOCK dthrott TO 0.05 * (1.5 - gforce).

    WHEN SHIP:ALTITUDE > 70000 THEN {
        LOCK dthrott TO 0.05 * (2.0 - gforce).

        WHEN SHIP:ALTITUDE > 15000 THEN {
            LOCK dthrott TO 0.05 * (4.0 - gforce).

            // go full on thrust at 30km
            // note this might be after
            WHEN SHIP:ALTITUDE > 30000 THEN {
                unlock dthrott.
                unlock THROTTLE.
                // only max out throttle if we still need to burn
                if (SHIP:APOAPSIS < 80000)
                {   SET throttle TO 1.}
            }
        }
    }
}
UNTIL SHIP:ALTITUDE > 30000 {
    SET thrott to thrott + dthrott.
    // wait one physics tick
    WAIT 0.
}

// BURN UNTIL APO @80km
UNLOCK dthrott.
UNLOCK thrott.
SET THROTTLE TO 1.
WAIT UNTIL SHIP:APOAPSIS > 80000.

// COAST TO APO
print "Coasting to Apoapsis".
SET THROTTLE TO 0.

// add maneuver to circularise
add circularise().
//effect maneuver
run pilot(true).
//done?
