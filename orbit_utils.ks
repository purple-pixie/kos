@lazyglobal off.
//orbit_utils.
//utilities relating to orbits and maneuvering

function bodyprops {
    // set celestial body properties
    // ease future parametrisation
    set b to body:name.
    set mu to body:mu. // gravitational parameter, mu = G mass
    set rb to body:radius. // radius of body
    set ha to 0.
    set lorb to 0.
    if b = "Kerbin" {
        set ha to 69077.            // atmospheric height
        set lorb to 80000.          // low orbit altitude
    }
    if b = "Mun" {
        set ha to 0.
        set lorb to 14000. 
    }
    if b = "Minmus" {
        set ha to 0.
        set lorb to 10000. 
    }
    if lorb = 0 {
        output(" Warning: no body properties for " + b + "!").
    }
    if lorb > 0 {
        output(" Loaded body properties for " + b).
    }
}

function speed_at {
    parameter r. // radius (height)
    parameter a. //semi-major axis
    return sqrt( body:mu * (2/r - 1/a ) ).
}

//Find Eccentric given True Anomaly.
function EccAnom_from_TrueAnom {
    declare parameter ec.   //eccentricity
    declare parameter T.    //True anomaly in degrees
   // return arccos((ec+cos(T))/(1+ec*cos(T))).
    local out is arctan2(sqrt(1.0-ec*ec)*sin(T),cos(T)+ec).
    if out < 0 { return out + 360. }
    return out.
}

// Given eccentricity and Eccentric Anomaly, return True Anomaly.
// *Nearly perfect accuracy despite sqrt.
// function TrueAnom_from_EccAnom {
    // declare parameter ec.   //eccentricity
    // declare parameter E.    //Eccentric Anomaly in degrees
    // local out is arctan2(sqrt(1.0-ec*ec)*sin(E),ec-cos(E)).
    // if out < 0 { return out + 360. }
    // return out.
// }

//Return mean given Eccentric, all in degrees.
function MeanAnom_from_EccAnom{
    declare parameter ec.   //eccentricity
    declare parameter E.    //Eccentric Anomaly
    return  E - constant:radtodeg*ec*sin(E).
}

// function MeanAnom_from_EccAnom{
    // declare parameter ec.   //eccentricity
    // declare parameter E.    //Eccentric Anomaly
    // return MeanAnom_from_EccAnom_rad(ec, E) * constant:radtodeg.
// }
//eta to a given True Anomaly.
//will always be positive (i.e. will return the instance from the next orbit 
// if this orbit's has already passed).
function eta_to_TrueAnom {
    declare parameter orbit_in.
    declare parameter t. // True Anomaly in degrees
    local dt is pe_to_TrueAnom(orbit_in, t) - pe_to_TrueAnom(orbit_in, orbit_in:TrueAnomaly) .
    if (dt < 0) { set dt to orbit_in:period + dt. }
    return dt.
}

function pe_to_TrueAnom {
    declare parameter orbit_in.
    declare parameter t. // True Anomaly in degrees
    local ecc is orbit_in:eccentricity.
    local EccAnom is EccAnom_from_TrueAnom(ecc, t).
    local MeanAnom is MeanAnom_from_EccAnom(ecc, EccAnom).
    return MeanAnom * orbit_in:period / 360.
}

function orbit_normal {
    declare parameter orbit_in.
    return vcrs(orbit_in:position - body:position, orbit_in:velocity:orbit):normalized.
}