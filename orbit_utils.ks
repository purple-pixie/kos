@lazyglobal off.
//orbit_utils.
//utilities relating to orbits and maneuvering

function bodyprops {
    // set celestial body properties
    // ease future parametrisation
    global  b is body:name.
    global mu is body:mu. // gravitational parameter, mu = G mass
    global rb is body:radius. // radius of body
    global ha is 0.
    global lorb is 0.
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
    parameter bod is kerbin.
    return sqrt( bod:mu * (2/r - 1/a ) ).
}
//
// function TrueAnom_from_Pos {
//   parameter orbit_1, pos.
//
// }

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

//eta to a given True Anomaly T from a starting T2 (defaults to current TA).
//will always be positive (i.e. will return the instance from the next orbit
// if this orbit's has already passed).
function eta_to_TrueAnom {
    declare parameter orbit_in.
    declare parameter t. // True Anomaly in degrees
    declare parameter t2 is orbit_in:TrueAnomaly.
    local dt is pe_to_TrueAnom(orbit_in, t) - pe_to_TrueAnom(orbit_in, t2).
    until (dt > 0) { set dt to orbit_in:period + dt. }
    return dt.
}

//time to go from pe to a given TrueAnomaly
function pe_to_TrueAnom {
    declare parameter orbit_in.
    declare parameter t. // True Anomaly in degrees
    local ecc is orbit_in:eccentricity.
    local EccAnom is EccAnom_from_TrueAnom(ecc, t).
    local MeanAnom is MeanAnom_from_EccAnom(ecc, EccAnom).
    return MeanAnom * orbit_in:period / 360.
}

function alt_from_trueanom {
  parameter orbit_in.
  parameter t. //trueanomaly
  //  r = a . (1-e^2)/(1 + e.cos(T)
  return orbit_in:semimajoraxis * (1-orbit_in:eccentricity^2) / (1 + orbit_in:eccentricity * cos(t)).
}

function orbit_normal {
    declare parameter orbit_in.
    return vcrs(orbit_in:position - body:position, orbit_in:velocity:orbit):normalized.
}

//raise or lower and rotate radially orbit at the given TrueAnomaly
//such that one of the new apsides is at this trueanomaly
//and the other is at the specified altitude.
//argument of periapsis will be less accurate for small changes relative
//to the starting orbit
function set_apoapsis_at_trueanom {
  parameter vessel_1, desired_apo, ta.

  //note that the "_pe" suffix refers to the location of the burn
  //not guranateed to be at an apsis
  local ut_at_pe is time:seconds+eta_to_trueanom(vessel_1:obt, ta).
  local pe_pos is positionat(vessel_1, ut_at_pe).
  //the altitude vector. handily contains altitiude and the radial vector
  local pe_alt_vec is pe_pos - body:position.
  local pe_alt is pe_alt_vec:mag.
  local pe_vel is velocityat(vessel_1, ut_at_pe):orbit.
  local pe_normal_dir is orbit_normal(vessel_1:obt).
  local desired_prograde_dir is vcrs(pe_normal_dir, pe_alt_vec):normalized.
  local pe_radial_dir is vcrs(pe_vel, pe_normal_dir):normalized.
  draw_line({return positionat(vessel_1, ut_at_pe).}, pe_radial_dir, red, "actual").
  draw_line({return positionat(vessel_1, ut_at_pe).}, pe_alt_vec, blue, "desired").
  local desired_sma is vessel_1:body:radius/2+(pe_alt + desired_apo)/2.
  // print "Semi-Major Axes:".
  // print "current: " + vessel_1:obt:semimajoraxis.
  // print "orbit_2: " + orbitable_2:obt:semimajoraxis.
  // print "desired: " + desired_sma.
  local desired_mag is sqrt(vessel_1:body:mu * (2/pe_alt - 1/desired_sma)).
  local desired_vector is desired_prograde_dir * desired_mag.
  local burn_dv is (desired_vector-pe_vel).
  draw_line({return positionat(vessel_1, ut_at_pe).}, burn_dv, green, "delta_v").
  draw_line({return positionat(vessel_1, ut_at_pe).}, desired_prograde_dir, yellow, "new prograde").
  local burn_mag is burn_dv:mag.
  local burn_vang is vang(burn_dv, pe_vel).
  print "vang: " + vang(pe_radial_dir, burn_dv).
  print "vdot: " + vdot(pe_radial_dir, burn_dv).
  local prograde_burn is burn_mag * cos(burn_vang).
  local radial_burn is burn_mag * sin(burn_vang).
  if vdot(pe_radial_dir, burn_dv) < 0 {
     set radial_burn to -radial_burn.
  }
  local nd is node(ut_at_pe,radial_burn,0,prograde_burn).

  // print "burn_mag (calc): " + burn_mag.
  //615.8 desired prograde_burn
  //903 reported
  return nd.
}

function sma_from_period {
  //given a body b and period p return the semi major axis of an orbit
  // around b with period p
  parameter b, p.
  return (((p/(constant:pi*2))^2)*b:mu)^(1/3).
}

function apsis_from_sma {
  //given one apsis ap and semimajoraxis sma return the other apsis
  //note: agnostic of body:radius, ap will probably not include it and sma will
  //make sure both match or results will be very wrong
  parameter ap, sma.
  return sma * 2 - ap.
}
