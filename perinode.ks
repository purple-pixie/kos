//apodnode.
//perform a burn at periapsis to adjust apo to ALT

declare parameter alt.

run once maneuver_utils.
run once orbit_utils.

output(" Periapsis maneuver, orbiting " + body:name).
output(" Apoapsis: " + round(apoapsis/1000) + "km -> " + round(alt/1000) + "km").
output(" Periapsis: " + round(periapsis/1000) + "km").

add_node(alt).