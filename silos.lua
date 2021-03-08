-- live granular instrument
--
-- use a keyboard to
-- assign controls,
-- set parameter values,
-- and control a granular
-- engine.
--

engine.name = "Silos"

local tabutil = require 'tabutil'

local a = arc.connect(1)
local g = grid.connect(1)
-- for grid
local last_x = { 4, 12 }
local last_y = { 4, 4 }
-- for keyboard input
local my_string = ""
local history = {}
local history_index = nil
local new_line = false
-- for screen state
local track = 1
local show_info = false
local info_focus = 1
-- controls table in the format controls[track][parameter name]
local controls = {}
for i = 1, 4 do
  controls[i] = {
    i .. "gain",
    i .. "position",
    i .. "speed",
    i .. "jitter",
    i .. "size",
    i .. "density",
    i .. "pitch",
    i .. "spread"
  }
end
-- current control choices for enc/arc/grid
local enc_choices = {"1gain", "1position", "1speed"}
local arc_choices = {"1jitter", "1size", "1density", "1pitch"}
local gridx_choices = {"1spread", "2spread"}
local gridy_choices = {"1jitter", "2jitter"}
-- for screen redraw
local is_dirty = true
local start_time = util.time()
-- for parameter snapshots
local snaps = {}
for i = 1, 4 do
  snaps[i] = {}
  for j = 1, 16 do
    snaps[i][j] = {}
  end
end


function split_string(input_string, sep)
  -- seperates a string by whitespace
  -- returns a table of the results
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(input_string, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end


function init()
  screen.aa(0)

  params:add_separator()
  for i = 1, 4 do
    params:add_group("track " .. i, 10)

    params:add_number(i .. "gate", i .. " gate", 0, 1, 0)
    params:set_action(i .. "gate", function(value) engine.gate(i, value) end)

    params:add_number(i .. "record", i .. " record", 0, 1, 0)
    params:set_action(i .. "record", function(value) engine.record(i, value) end)

    params:add_taper(i .. "gain", i .. " gain", -60, 20, -12, 0, "dB")
    params:set_action(i .. "gain", function(value) engine.gain(i, math.pow(10, value / 20)) end)

    params:add_taper(i .. "position", i .. " position", 0, 1, 0.001, 0)
    params:set_action(i .. "position", function(value)  engine.seek(i, value) end)

    params:add_taper(i .. "speed", i .. " speed", -300, 300, 0, 0, "%")
    params:set_action(i .. "speed", function(value) engine.speed(i, value / 100) end)

    params:add_taper(i .. "jitter", i .. " jitter", 0, 500, 30, 5, "ms")
    params:set_action(i .. "jitter", function(value) engine.jitter(i, value / 1000) end)

    params:add_taper(i .. "size", i .. " size", 1, 500, 150, 5, "ms")
    params:set_action(i .. "size", function(value) engine.size(i, value / 1000) end)

    params:add_taper(i .. "density", i .. " density", 0, 512, 10, 6, "hz")
    params:set_action(i .. "density", function(value) engine.density(i, value) end)

    params:add_taper(i .. "pitch", i .. " pitch", -24, 24, 0, 0, "st")
    params:set_action(i .. "pitch", function(value) engine.pitch(i, math.pow(0.5, -value / 12)) end)

    params:add_taper(i .. "spread", i .. " spread", 0, 100, 35, 0, "%")
    params:set_action(i .. "spread", function(value) engine.spread(i, value / 100) end)
  end

  params:bang()

  -- arc redraw metro
  local arc_redraw_timer = metro.init()
  arc_redraw_timer.time = 0.025
  arc_redraw_timer.event = function() arc_redraw() end
  arc_redraw_timer:start()
  -- norns redraw metro
  local norns_redraw_timer = metro.init()
  norns_redraw_timer.time = 0.025
  norns_redraw_timer.event = function() if is_dirty then redraw() end end
  norns_redraw_timer:start()
end

-- norns hardware ----------
function key(n, z)
  if n == 2 and z == 1 then
    -- gate on for selected track
    if params:get(track .. "gate") == 0 then
      params:set(track .. "gate", 1)
    else
      params:set(track .. "gate", 0)
    end
  elseif n == 3 and z == 1 then
    -- recording on for selcted track
    if params:get(track .. "record") == 0 then
      params:set(track .. "record", 1)
    else
      params:set(track .. "record", 0)
    end
  end
  is_dirty = true
end


function enc(n, d)
  params:delta(enc_choices[n], d)
  is_dirty = true
end


function redraw()
  screen.clear()
  -- splash screen type logo thing
  if util.time() - start_time < 1.5 then
    screen.display_png("/home/we/dust/code/silos/silos4.png", 0, 0)
    screen.font_face(25)
    screen.font_size(6)
    screen.level(0)
    screen.move(123, 60)
    screen.text_right("silos")
    screen.stroke()
  else

  screen.font_face(1)
  screen.font_size(8)
  screen.level(10)
  screen.move(126, 10)
  screen.text_right(track)
  screen.move(106, 10)
  screen.level(params:get(track .. "gate") == 0 and 2 or 10)
  screen.text_right("g")
  screen.move(116, 10)
  screen.level(params:get(track .. "record") == 0 and 2 or 10)
  screen.text_right("r")
  screen.level(10)
  screen.move(5, 62)
  screen.text("> " .. my_string)

  if show_info then
    screen.font_face(25)
    screen.font_size(6)
    screen.level(8)
    if info_focus == 1 then
      screen.move(1, 10)
      screen.text(1 .. " gain " .. string.format("%.1f", params:get(track .."gain")))
      screen.move(1, 18)
      screen.text(2 .. " position " .. string.format("%.2f", params:get(track .. "position")))
      screen.move(1, 26)
      screen.text(3 .. " speed " .. string.format("%.1f", params:get(track .. "speed")))
      screen.move(1, 34)
      screen.text(4 .. " jitter " .. string.format("%.1f", params:get(track .. "jitter")))
      screen.move(1, 42)
      screen.text(5 .. " size " .. string.format("%.1f", params:get(track .. "size")))
      screen.move(65, 35)
      screen.text(6 .. " density " .. string.format("%.1f", params:get(track .. "density")))
      screen.move(65, 42)
      screen.text(7 .. " pitch " .. string.format("%.1f", params:get(track .. "pitch")))
      screen.move(65, 50)
      screen.text(8 .. " spread " .. string.format("%.1f", params:get(track .. "spread")))
    elseif info_focus == 2 then
      screen.move(1, 18)
      screen.text("enc:")
      screen.move(20, 18)
      screen.text(enc_choices[1] .. " " .. enc_choices[2])
      screen.move(20, 28)
      screen.text( enc_choices[3])
      screen.move(1, 38)
      screen.text("arc:")
      screen.move(20, 38)
      screen.text(arc_choices[1] .. " " .. arc_choices[2])
      screen.move(20, 48)
      screen.text(arc_choices[3] .. " " .. arc_choices[4])
    elseif info_focus == 3 then
      screen.move(1, 18)
      screen.text("gridx:")
      screen.move(28, 18)
      screen.text(gridx_choices[1] .. " " .. gridx_choices[2])
      screen.move(1, 38)
      screen.text("gridy:")
      screen.move(28, 38)
      screen.text(gridy_choices[1] .. " " .. gridy_choices[2])
    elseif info_focus == 4 then
      -- show snap slots
      -- dim for unused, mid for "has data", bright for current
    end
    screen.stroke()
  end
  screen.update()
  if util.time() - start_time < 1.5 then
    is_dirty = true
  else
    is_dirty = false
  end
end

-- arc ------------

function a.delta(n, d)
  params:delta(arc_choices[n], d / 10)
  is_dirty = true
end


function arc_redraw()
  for i = 1, 4 do
    ring_choice = arc_choices[i]

    a:segment(i,
      util.degs_to_rads(210),
      util.degs_to_rads(util.linlin(params:get_range(ring_choice)[1], params:get_range(ring_choice)[2],
      210,
      309 + 210,
      params:get(ring_choice))),
    15)
  end
  a:refresh()
end

-- grid ----------

function g.key(x, y, z)
  -- two 8x8 x/y pads
  if x <= 8  and z == 1 then
    -- left x/y pad
    -- scale values and set selected params
    local grid_choicex = control_choices[params:get("1gridx")]
    local grid_choicey = control_choices[params:get("1gridy")]
    local x_scaled = util.linlin(1, 8, params:get_range(grid_choicex)[1], params:get_range(grid_choicex)[2], x)
    local y_scaled = util.linlin(1, 8, params:get_range(grid_choicey)[1], params:get_range(grid_choicey)[2], y)
    params:set(grid_choicex, x_scaled)
    params:set(grid_choicey, y_scaled)

    last_x[1] = x
    last_y[1] = y
  elseif x >= 9 and z == 1 then
    -- right x/y pad
    -- scale values and set params
    local grid_choicex = control_choices[params:get("2gridx")]
    local grid_choicey = control_choices[params:get("2gridy")]
    local x_scaled = util.linlin(9, 16, params:get_range(grid_choicex)[1], params:get_range(grid_choicex)[2], x)
    local y_scaled = util.linlin(1, 8, params:get_range(grid_choicey)[1], params:get_range(grid_choicey)[2], y)
    params:set(grid_choicex, x_scaled)
    params:set(grid_choicey, y_scaled)

    last_x[2] = x
    last_y[2] = y
  end
  g.redraw()
  is_dirty = true
end


function g.redraw()
  g:all(0)

  for i = 1, 8 do
    g:led(i, last_y[1], 2)
    g:led(last_x[1], i, 2)
    g:led(i + 8, last_y[2], 2)
    g:led(last_x[2], i, 2)
  end

  g:led(last_x[1], last_y[1], 10)
  g:led(last_x[2], last_y[2], 10)

  g:refresh()
end

-- keyboard input ----------

function keyboard.char(character)
  if keyboard.shift() then
  else
    my_string = my_string .. character -- add characters to my string
    is_dirty = true
  end
end


function keyboard.code(code,value)
  --print(code)
  if code == "ESC" then
    if value == 1 or value == 2 then
      if show_info then
        show_info = false
      else
        show_info = true
      end
    end
  end

  if keyboard.shift() and value == 1 then
    -- script controls
    if code == "G" then
    -- gate on for selected track
      if params:get(track .. "gate") == 0 then
        params:set(track .. "gate", 1)
      else
        params:set(track .. "gate", 0)
      end

    elseif code == "R" then
      -- arm record
      if params:get(track .. "record") == 0 then
        params:set(track .. "record", 1)
      else
        params:set(track .. "record", 0)
      end
    -- track select
    elseif code == "1" then
      track = 1
    elseif code == "2" then
      track = 2
    elseif code == "3" then
      track = 3
    elseif code == "4" then
      track = 4
    -- track randomize
    elseif code == "TAB" then
      for i = 2, 8 do
        local l, h = params:get_range(controls[track][i])[1], params:get_range(controls[track][i])[2]
        params:set(controls[track][i], math.random(l, h))
      end
    end
  end

  if value == 1 or value == 2 then -- 1 is down, 2 is held, 0 is release
    if code == "BACKSPACE" then
      my_string = my_string:sub(1, -2) -- erase characters from my_string
    elseif code == "UP" then
      if #history > 0 then -- make sure there's a history
        if new_line then -- reset the history index after pressing enter
          history_index = #history
          new_line = false
        else
          history_index = util.clamp(history_index - 1, 1, #history) -- increment history_index
        end
        my_string = history[history_index]
      end
    elseif code == "DOWN" then
      if #history > 0 and history_index ~= nil then -- make sure there is a history, and we are accessing it
        history_index = util.clamp(history_index + 1, 1, #history) -- decrement history_index
        my_string = history[history_index]
      end
    elseif code == "RIGHT" then
      if show_info then
        info_focus = util.clamp(info_focus + 1, 1, 3)
      end
    elseif code == "LEFT" then
      if show_info then
        info_focus = util.clamp(info_focus - 1, 1, 3)
      end
    elseif code == "ENTER" then
      -- parse string
      print(my_string)
      local command = split_string(my_string)
      --print(#command)

      if command[1] == "rrand" then
        local low, high, track, control = tonumber(command[2]), tonumber(command[3]), tonumber(command[4]), tonumber(command[5])
        local n = math.random(low, high)
        params:set(controls[track][control], n)
      elseif command[1] == "enc" then
        local x, n, v = tonumber(command[2]), tonumber(command[3]), tonumber(command[4])
        enc_choices[x] = controls[n][v]
      elseif command[1] == "arc" then
        local x, n, v = tonumber(command[2]), tonumber(command[3]), tonumber(command[4])
        arc_choices[x] = controls[n][v]
      elseif command[1] == "gridx" then
        local x, n, v = tonumber(command[2]), tonumber(command[3]), tonumber(command[4])
        gridx_choices[x] = controls[n][v]
      elseif command[1] == "gridy" then
        local x, n, v = tonumber(command[2]), tonumber(command[3]), tonumber(command[4])
        gridy_choices[x] = controls[n][v]
      elseif command[1] == "stop" then
        for i = 1, 4 do
          params:set(i .. "gate", 0)
        end
      elseif command[1] == "s" or command[1] == "snap" then
        local snap_id, t = tonumber(command[2]), tonumber(command[3])
        snaps[t][snap_id] = {}
        for i = 1, 8 do
          table.insert(snaps[t][snap_id], params:get(controls[t][i]))
        end
      elseif command[1] == "r" or command[1] == "recall" then
        local snap_id, t = tonumber(command[2]), tonumber(command[3])
        if #snaps[t][snap_id] > 0 then
          for i = 1, 8 do
            params:set(controls[t][i], snaps[t][snap_id][i])
          end
        end
      elseif tabutil.contains(controls[track], command[2] .. command[1]) then
        local v = tonumber(command[3])
        params:set(command[2] .. command[1], v)
      end
      table.insert(history, my_string) -- append the command to history
      my_string = "" -- clear my_string
      new_line = true
    end
    is_dirty = true
  end

end

function rerun()
  norns.script.load(norns.state.script)
end
