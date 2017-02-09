//apodnode.
//perform a burn at apoapsis to adjust peri to ALT

declare parameter alt.

run once maneuver_utils.

output(" Apoapsis maneuver, orbiting " + body:name).
output(" Apoapsis: " + round(apoapsis/1000) + "km").
output(" Periapsis: " + round(periapsis/1000) + "km -> " + round(alt/1000) + "km").

add_node(alt, FALSE).

