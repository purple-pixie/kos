//global vd is 0.
global draw_draw is false.
global draw_vectors is list().
local line_length is 100000.
// global draw_start is V(0,0,0).
// global draw_vec is V(0,500000,0).
// global draw_nd is 0.

// global pos_delegate is 0.
// global line_delegate is 0.
function draw_ship_at_trueanom {
    parameter vessel_1.
    parameter t. // true anomaly
    draw_ship_at(vessel_1, time+eta_to_trueanom(vessel_1:obt, t)).
}

function do_draw {
    parameter newvec.
    local pos is newvec[1].
    local line is newvec[2].
    if pos:istype("UserDelegate")  { set pos to pos:call(). }
    else { set newvec[1] to 0. }
    if line:istype("UserDelegate") { set line to line:call(). }
    else { set newvec[2] to 0. }
    set newvec[0]:start to pos.
    set newvec[0]:vec to line.
    set newvec[0]:show to true.
   draw_vectors:add(newvec).
    if draw_draw {
        //already drawing, return
        return.
    }
    set draw_draw to true.
    //set up re-draw trigger, it will stop when draw_stop_drawing gets called (or the script stops)
    on time {
        for vec in draw_vectors {
            local vd is vec[0].
            if not (vec[1] = 0) { set vd:start to vec[1]:call(). }
            if not (vec[2] = 0) { set vd:vec to vec[2]:call(). }
        }.
        if draw_draw { preserve. }
    }
}

function draw_stop_drawing {
    //cancel the trigger, erase all vectors from the list and clear away any vectors that are still shown
    set draw_draw to false.
    draw_vectors:clear().
    clearvecdraws().
}

function draw_ship_at {
    //draws prograde, radial and normal vectors at the ship's position at the given time
    parameter vessel_1.
    parameter ut.
    local pos_func is { return positionat(vessel_1, ut) - positionat(ship, time). }.
    local pos_at_ut is positionat(vessel_1, ut).
    local prograde_at_ut is velocityat(vessel_1, ut):orbit.
    local normal_at_ut is (vcrs(prograde_at_ut, pos_at_ut-vessel_1:body:position)).
    local radial_at_ut is (pos_at_ut-vessel_1:body:position).
    draw_line(pos_func,  prograde_at_ut, yellow, "prograde").
    draw_line(pos_func, normal_at_ut, purple, "normal").
    draw_line(pos_func, radial_at_ut, blue, "radial").
}

function draw_line {
    //normalizes and extends to LINE_LENGTH the given line.
    //if given a delegate it will normalize and extend the result of that.
    parameter pos.
    parameter line.
    parameter color is red.
    parameter text is "line".
    if line:istype("UserDelegate") {
        draw_delegates(pos, { return line:call():normalized*line_length.}, color, text).
        }
    else {
        draw_delegates(pos, line:normalized*line_length, color, text).
    }
}

function draw_axes_at {
    parameter pos_func.
    local x is V(line_length, 0, 0).
    local y is V(0, line_length, 0).
    local z is V(0, 0, line_length).
    draw_delegates(pos_func,  x, blue, "x").
    draw_delegates(pos_func,  y, yellow, "y").
    draw_delegates(pos_func,  z, green, "z").
}

function draw_delegates {
    parameter pos_func.
    parameter line_func.
    parameter color is  red.
    parameter text is "draw_delegate".
    // set pos_delegate to pos_func.
    // set line_delegate to line_func.
    local vd is vecdraw(V(0,0,0), V(0,0,0), color, text).
    local vec is list(vd).
    vec:add(pos_func).
    vec:add(line_func).
    do_draw(vec).
}

function draw_vec_to_position {
    parameter pos. // the position (relative body)
    parameter draw_vec is 0. //V(0,500000,0).
    print "deprecated | draw_vec_to_position".
    return.
    set draw_vec to draw_vec.
    lock draw_start to pos - draw_vec.
    set vd to vecdraw(draw_start, draw_vec, red, "giggling and ladying").
    do_draw().
}

function draw_vec_to_body_position {
    //draw a vector 10k long pointing to a position relative body
    parameter pos. // the position (relative body)
    print "deprecated | draw_vec_to_body_position".
    return.
    set draw_vec to V(0,50000,0).
    lock draw_start to pos + body:position - line.
    set vd to vecdraw(draw_start, draw_vec, red, "body rolls are really hard").
    do_draw().
}
