// utilities useful for a launching vessel.
// primarily staging related
global active is list().

function do_stage {
    // stage and set up active engine list for flameout checks
    // (makes looping through engines that much quicker)
    print "Staging.".
    STAGE.
    list engines in inactive.
    set active to list().
    FROM {set i to 0.} UNTIL i = inactive:length STEP {set i to i+1.} DO {
        set en to inactive[i].
        if en:ignition {
            inactive:remove(i).
            set i to i-1.
            active:add(e).
        }
    }
}

function check_stage {
    // check list of active engines for a flameout
    //return true if flamed out, false otherwise
    FROM {set i to 0.} UNTIL i = active:length STEP {set i to i+1.} DO {
        if active[i]:flameout { RETURN 1. }
    }
    RETURN 0.
}

function auto_stage {
    // performs initial staging and monitors engines for flameout.
    // stages whenever an engine flames out.
    parameter launch is false.
    if launch {
      print "Launch!".
      do_stage().
    }
    lock staging to check_stage().
    when staging then {
        do_stage.
        if inactive:length {preserve.}
    }
}

function check_sensors {
    //verify that graivty and accelerometer sensors present.
    // return "grav" or "acc" if grav or acc is missing
    // return false otherwise
    list sensors in sense.
    set acc to false.
    set grav to false.
    for sensor in sense {
        if sensor:type="grav" {set grav to true.}
        if sensor:type = "acc" {set acc to true.}
    }
    if grav = false { return "Gravometer".}
    if acc = false { return "Acclerometer".}
    return 0.
}

function countdown {
    //performs a simple countdown of T seconds
    parameter t.
    until t = 0 {
        print t + "...".
        set t to t - 1.
        wait 1.
    }
}
