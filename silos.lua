-- live granular instrument
--
-- use a keyboard to
-- assign controls,
-- set parameter values,
-- and control a granular
-- engine.
--

engine.name = "Thresh"

local tabutil = require 'tabutil'

local a = arc.connect(1)
local g = grid.connect(1)
local alt = false
local grid_alt = false
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
for i = 1, 3 do
  controls[i] = {
    i .. "gain",
    i .. "position",
    i .. "speed",
    i .. "jitter",
    i .. "size",
    i .. "pitch",
    i .. "fdbk",
    i .. "density",
    i .. "dispersal",
    i .. "spread",
    i .. "send"
  }
end

local fx_controls = {
  "fx_gain",
  "time",
  "verbsize",
  "damp",
  "diff",
  "mod_depth",
  "mod_freq",
  "lowx",
  "midx",
  "highx",
  "quality"
}

local bit_depths = {4, 8, 10, 12, 32}

local function set_quality(v)
  engine.bit_depth(bit_depths[v])
end

-- for saving state
local silos = {}
silos.grid_mode = 1
silos.grid_modes = {"2xy", "snaps"}
-- current control choices for enc/arc/grid
silos.enc_choices = {"1gain", "1position", "1speed"}
silos.arc_choices = {"1jitter", "1spread", "1density", "1pitch"}
silos.gridx_choices = {"1spread", "2spread"}
silos.gridy_choices = {"1jitter", "2jitter"}
-- for parameter snapshots
silos.snaps = {}
for i = 1, 3 do
  silos.snaps[i] = {}
  for j = 1, 16 do
    silos.snaps[i][j] = {}
  end
end
-- for control macros
silos.macros = {}
silos.muls = {}
for i = 1, 3 do
  silos.macros[i] = {}
  silos.muls[i] = {}
end
silos.is_macro = {false, false, false}

-- for screen redraw
local is_dirty = true
local start_time = util.time()
local walk = 123


local function save_state(id)
  if id == nil then id = "silos" end
  tabutil.save(silos, paths.code .. "silos/lib/" .. id .. ".state")
end


local function load_state(id)
  if id == nil then id = "silos" end
  silos = tabutil.load(paths.code .. "silos/lib/" .. id .. ".state")
end


local function save_pset()
  params:write()
end


local function load_pset()
  params:read()
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
  for i = 1, 3 do
    params:add_group("track " .. i, 14)

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

    params:add_taper(i .. "jitter", i .. " jitter", 0, 500, 0, 5, "ms")
    params:set_action(i .. "jitter", function(value) engine.jitter(i, value / 1000) end)

    params:add_taper(i .. "size", i .. " size", 1, 500, 150, 5, "ms")
    params:set_action(i .. "size", function(value) engine.size(i, value / 1000) end)

    params:add_taper(i .. "flux", i .. " flux", 0, 1, 0, 0, "")
    params:set_action(i .. "flux", function(value) engine.size_mod_amt(i, value) end)

    params:add_taper(i .. "density", i .. " density", 0, 512, 32, 6, "hz")
    params:set_action(i .. "density", function(value) engine.density(i, value) end)

    params:add_control(i.."dispersal", i.." dispersal", controlspec.new(0.00, 1.00, "lin", 0, 0))
    params:set_action(i.."dispersal", function(v) engine.density_mod_amt(i, v) end)

    params:add_taper(i .. "pitch", i .. " pitch", -4, 4, 1, 0, "")
    params:set_action(i .. "pitch", function(value) engine.pitch(i, value) end)

    params:add_taper(i .. "spread", i .. " spread", 0, 100, 35, 0, "%")
    params:set_action(i .. "spread", function(value) engine.spread(i, value / 100) end)

    params:add_control(i .. "fdbk", i .." fdbk", controlspec.new(0.0, 1.0, "lin", 0.01, 0))
    params:set_action(i .. "fdbk", function(value) engine.pre_level(i, value) end)

    params:add_control(i .. "send", i .." send", controlspec.new(0.0, 1.0, "lin", 0.01, 0))
    params:set_action(i .. "send", function(value) engine.send(i, value) end)
  end

  params:add_separator()
   params:add_group("fx", 13)
  -- effect controls
  -- delay time
  params:add_taper("time", "*" .. "time", 0.0, 60.0, 60, 0, "")
  params:set_action("time", function(value) engine.time(value) end)
  -- delay size
  params:add_taper("verbsize", "*" .. "size", 0.5, 5.0, 1.67, 0, "")
  params:set_action("verbsize", function(value) engine.verbsize(value) end)
  -- dampening
  params:add_taper("damp", "*" .. "damp", 0.0, 1.0, 0.3144, 0, "")
  params:set_action("damp", function(value) engine.damp(value) end)
  -- diffusion
  params:add_taper("diff", "*" .. "diff", 0.0, 1.0, 0.71, 0, "")
  params:set_action("diff", function(value) engine.diff(value) end)
  -- mod depth
  params:add_taper("mod_depth", "*" .. "mod depth", 0.0, 1.0, .66, 0, "")
  params:set_action("mod_depth", function(value) engine.mod_depth(value) end)
  -- mod rate
  params:add_taper("mod_freq", "*" .. "mod freq", 0.0, 10.0, 3.00, 0, "hz")
  params:set_action("mod_freq", function(value) engine.mod_freq(value) end)
  -- reverb eq
  params:add_taper("lowx", "*" .. "lowx", 0.0, 1.0, 0.8, 0, "")
  params:set_action("lowx", function(value) engine.low(value) end)

  params:add_taper("midx", "*" .. "midx", 0.0, 1.0, 0.70, 0, "")
  params:set_action("midx", function(value) engine.mid(value) end)

  params:add_taper("highx", "*" .. "highx", 0.0, 1.0, 0.3, 0, "")
  params:set_action("highx", function(value) engine.high(value) end)

  params:add_taper("lowcross", "*" .. "low crossover", 100, 6000.0, 2450.0, 0, "")
  params:set_action("lowcross", function(value) engine.lowcut(value) end)

  params:add_taper("highcross", "*" .. "high crossover", 1000.0, 10000.0, 1024.0, 0, "")
  params:set_action("highcross", function(value) engine.highcut(value) end)
  -- bit depth
  params:add_option("quality", "*quality", bit_depths, 5)
  params:set_action("quality", function(value) set_quality(value) end)
  -- reverb output volume
  params:add_taper("fx_gain", "*" .. "gain", 0.0, 1.0, 0.50, 0, "")
  params:set_action("fx_gain", function(value) engine.fxgain(value) end)

  params:add_separator()

  params:add_option("grid_mode", "grid mode", silos.grid_modes, 1)
  params:set_action("grid_mode", function(value) silos.grid_mode = value end)

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
  -- grid redraw metro
  local grid_redraw_timer = metro.init()
  grid_redraw_timer.time = 0.025
  grid_redraw_timer.event = function() g.redraw() end
  grid_redraw_timer:start()
end

-- norns hardware ----------
function key(n, z)
  if n == 1 then alt = z == 1 and true or false end

  if n == 2 and z == 1 then
    -- gate on for selected track
    if params:get(track .. "gate") == 0 then
      params:set(track .. "gate", 1)
    else
      params:set(track .. "gate", 0)
    end
  elseif n == 3 and z == 1 then
    if alt then
      show_info = not show_info
    -- recording on for selcted track
    elseif params:get(track .. "record") == 0 then
      params:set(track .. "record", 1)
    else
      params:set(track .. "record", 0)
    end
  end
  is_dirty = true
end


function enc(n, d)
  if alt  then
    if n == 2 then
      track = util.clamp(track + d, 1, 3)
    elseif n == 3 then
      info_focus = util.clamp(info_focus + d, 1, 5)
    end
  elseif silos.is_macro[n] then
    for i = 1, #silos.macros[n] do
      params:delta(silos.macros[n][i], d * silos.muls[n][i])
    end
  else
    params:delta(silos.enc_choices[n], d)
  end
  is_dirty = true
end

-- screen ----------

local function draw_engine_params()
  screen.move(1, 10)
  screen.text(1 .. " gain " .. string.format("%.1f", params:get(track .."gain")))
  screen.move(1, 18)
  screen.text(2 .. " position " .. string.format("%.1f", params:get(track .. "position")))
  screen.move(1, 26)
  screen.text(3 .. " speed " .. string.format("%.1f", params:get(track .. "speed")))
  screen.move(1, 34)
  screen.text(4 .. " jitter " .. string.format("%.1f", params:get(track .. "jitter")))
  screen.move(1, 42)
  screen.text(5 .. " size " .. string.format("%.1f", params:get(track .. "size")))
  screen.move(1, 50)
  screen.text(6 .. " pitch " .. string.format("%.1f", params:get(track .. "pitch")))
  screen.move(65, 18)
  screen.text(7 .. " fdbk " .. string.format("%.1f", params:get(track .. "fdbk")))
  screen.move(65, 26)
  screen.text(8 .. " density " .. string.format("%.1f", params:get(track .. "density")))
  screen.move(65, 34)
  screen.text(9 .. " dispersal "..string.format("%.1f", params:get(track .. "dispersal")))
  screen.move(65, 42)
  screen.text(10 .. " spread " .. string.format("%.1f", params:get(track .. "spread")))
  screen.move(65, 50)
  screen.text(11 .. " send " .. string.format("%.1f", params:get(track .. "send")))
end


local function draw_fx_params()
  screen.move(54, 10)
  screen.text_center("-fx-")
  screen.move(1, 18)
  screen.text("1 gain " .. string.format("%.2f", params:get("fx_gain")))
  screen.move(1, 26)
  screen.text("2 time " .. string.format("%.1f", params:get("time")))
  screen.move(1, 34)
  screen.text("3 size " .. string.format("%.2f", params:get("verbsize")))
  screen.move(1, 42)
  screen.text("4 damp " .. string.format("%.3f", params:get("damp")))
  screen.move(1, 50)
  screen.text("5 diff " .. string.format("%.3f", params:get("diff")))
  screen.move(65, 18)
  screen.text("6 mod depth " .. string.format("%.2f", params:get("mod_depth")))
  screen.move(65, 26)
  screen.text("7 mod freq " .. string.format("%.2f", params:get("mod_freq")))
  screen.move(65, 34)
  screen.text("8 lowx " .. string.format("%.2f", params:get("lowx")))
  screen.move(65, 42)
  screen.text("9 midx " .. string.format("%.2f", params:get("midx")))
  screen.move(65, 50)
  screen.text("10 highx " .. string.format("%.2f", params:get("highx")))
end


local function draw_controls1()
  screen.move(54, 10)
  screen.text_center("-controls-")
  screen.move(1, 18)
  screen.text("enc:")
  screen.move(20, 18)
  screen.text(silos.enc_choices[1])
  screen.move(20, 28)
  screen.text( silos.enc_choices[2])
  screen.move(20, 38)
  screen.text(silos.enc_choices[3])
  screen.move(64, 18)
  screen.text("arc:")
  screen.move(84, 18)
  screen.text(silos.arc_choices[1])
  screen.move(84, 28)
  screen.text(silos.arc_choices[2])
  screen.move(84, 38)
  screen.text(silos.arc_choices[3])
  screen.move(84, 48)
  screen.text(silos.arc_choices[4])
end


local function draw_controls2()
  screen.move(54, 10)
  screen.text_center("-controls-")
  screen.move(1, 28)
  screen.text("gridx:")
  screen.move(28, 28)
  screen.text(silos.gridx_choices[1] .. " " .. silos.gridx_choices[2])
  screen.move(1, 38)
  screen.text("gridy:")
  screen.move(28, 38)
  screen.text(silos.gridy_choices[1] .. " " .. silos.gridy_choices[2])
end


local function draw_snaps()
  -- show snap slots
  -- dim for unused, bright for contains data
  screen.move(64, 10)
  screen.text_center("-snapshots-")
  for i = 1, 3 do
    for j = 1, 16 do
      screen.level(#silos.snaps[i][j] > 0 and 10 or 2 )
      screen.rect(0.5 + j * 8, 10 + i * 8, 4, 4)
      screen.fill()
      screen.stroke()
    end
  end
end


function redraw()
  screen.clear()
  -- splash screen type logo thing
  if util.time() - start_time < 3.2 then
    screen.display_png("/home/we/dust/code/silos/assets/silos4.png", 0, 0)
    screen.aa(1)
    screen.font_face(34)
    screen.font_size(32)
    screen.level(4)
    screen.move(walk, 61)
    screen.text("silos")
    screen.stroke()
    walk = walk - 2
  else
    screen.aa(0)
    screen.font_face(1)
    screen.font_size(8)
    screen.level(10)
    screen.move(126, 6)
    screen.text_right(track)
    screen.move(106, 6)
    screen.level(params:get(track .. "gate") == 0 and 2 or 10)
    screen.text_right("g")
    screen.move(116, 6)
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
        draw_engine_params()
      elseif info_focus == 2 then
        draw_fx_params()
      elseif info_focus == 3 then
        draw_controls1()
      elseif info_focus == 4 then
        draw_controls2()
      elseif info_focus == 5 then
        draw_snaps()
      end
    end
    screen.stroke()
  end
  screen.update()
  if util.time() - start_time < 3.2 then
    is_dirty = true
  else
    is_dirty = false
  end
end

-- arc ------------

function a.delta(n, d)
  params:delta(silos.arc_choices[n], d / 10)
  is_dirty = true
end


function arc_redraw()
  for i = 1, 4 do
    local ring_choice = silos.arc_choices[i]
    local low, high = params:get_range(ring_choice)[1], params:get_range(ring_choice)[2]
    a:segment(i, util.degs_to_rads(210), util.degs_to_rads(util.linlin(low, high, 210, 309 + 210,  params:get(ring_choice))), 15)
  end
  a:refresh()
end

-- grid ----------

function grid_2xy(x, y, z)
  -- two 8x8 x/y pads
  if x <= 8  and z == 1 then
    -- left x/y pad
    -- scale values and set selected params
    local grid_choicex = silos.gridx_choices[1]
    local grid_choicey = silos.gridy_choices[1]
    local x_scaled = util.linlin(1, 8, params:get_range(grid_choicex)[1], params:get_range(grid_choicex)[2], x)
    local y_scaled = util.linlin(1, 8, params:get_range(grid_choicey)[1], params:get_range(grid_choicey)[2], y)
    params:set(grid_choicex, x_scaled)
    params:set(grid_choicey, y_scaled)

  elseif x >= 9 and z == 1 then
    -- right x/y pad
    -- scale values and set params
    local grid_choicex = silos.gridx_choices[2]
    local grid_choicey = silos.gridy_choices[2]
    local x_scaled = util.linlin(9, 16, params:get_range(grid_choicex)[1], params:get_range(grid_choicex)[2], x)
    local y_scaled = util.linlin(1, 8, params:get_range(grid_choicey)[1], params:get_range(grid_choicey)[2], y)
    params:set(grid_choicex, x_scaled)
    params:set(grid_choicey, y_scaled)

  end
end


function grid_snap(x, y, z)
  if y <= 4 and z == 1 then
    if grid_alt then
      local snap_id, t = x, y
      silos.snaps[t][snap_id] = {}
      for i = 1, #controls[t] do
        table.insert(silos.snaps[t][snap_id], params:get(controls[t][i]))
      end
    elseif #silos.snaps[y][x] > 0 then
      for i = 1, #controls[y] do
        params:set(controls[y][i], silos.snaps[y][x][i])
      end
    end
  elseif x == 4 and y == 6 then
    grid_alt = z == 1 and true or false
  end
end


function g.key(x, y, z)
  if silos.grid_mode == 1 then
    grid_2xy(x, y, z)
  elseif silos.grid_mode == 2 then
    -- snapshot mode
    grid_snap(x, y, z)
  end
  g.redraw()
  is_dirty = true
end


function g.redraw()
  g:all(0)
  if silos.grid_mode == 1 then
    local gxh, gxl = params:get_range(silos.gridx_choices[1])[1], params:get_range(silos.gridx_choices[1])[2]
    local gyh, gyl = params:get_range(silos.gridy_choices[1])[1], params:get_range(silos.gridy_choices[1])[2]

    local x_scaled = util.linlin(gxh, gxl, 1, 8, params:get(silos.gridx_choices[1]))
    local y_scaled = util.linlin(gyh, gyl, 1, 8, params:get(silos.gridy_choices[1]))

    gxh, gxl = params:get_range(silos.gridx_choices[2])[1], params:get_range(silos.gridx_choices[2])[2]
    gyh, gyl = params:get_range(silos.gridy_choices[2])[1], params:get_range(silos.gridy_choices[2])[2]

    local x_scaled2 = util.linlin(gxh, gxl, 9, 16, params:get(silos.gridx_choices[2]))
    local y_scaled2 = util.linlin(gyh, gyl, 1, 8, params:get(silos.gridy_choices[2]))


    x_scaled = math.floor(x_scaled + 0.5)
    y_scaled = math.floor(y_scaled + 0.5)
    x_scaled2 = math.floor(x_scaled2 + 0.5)
    y_scaled2 = math.floor(y_scaled2 + 0.5)

    for i = 1, 8 do
      g:led(i, y_scaled, 2)
      g:led(x_scaled, i, 2)
      g:led(i + 8, y_scaled2, 2)
      g:led(x_scaled2, i, 2)
    end

    g:led(x_scaled, y_scaled, 10)
    g:led(x_scaled2, y_scaled2, 10)
  elseif silos.grid_mode == 2 then
    for i = 1, 3 do
      for j = 1, 16 do
        g:led(j, i, #silos.snaps[i][j] > 0 and 10 or 2 )
      end
    end
    g:led(4, 6, grid_alt and 10 or 2)
  end

  g:refresh()
end

-- keyboard input ----------

function keyboard.char(character)
  if keyboard.ctrl() or keyboard.alt() then
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

  if value == 1 or value == 2 then -- 1 is down, 2 is held, 0 is release
    if keyboard.ctrl() then
      -- hold control for script control keybinds
      if code == "G" then
        -- toggle gate for selected track
        if params:get(track .. "gate") == 0 then
          params:set(track .. "gate", 1)
        else
          params:set(track .. "gate", 0)
        end
      elseif code == "R" then
        -- toggle record
        if params:get(track .. "record") == 0 then
          params:set(track .. "record", 1)
        else
          params:set(track .. "record", 0)
        end
      elseif code == "1" or code == "2" or code == "3" or code == "4" then
        track = tonumber(code)
      end
    elseif code == "BACKSPACE" then
      -- erase characters from my_string
      my_string = my_string:sub(1, -2)
    elseif code == "UP" then
      -- make sure there's a history
      if #history > 0 then
        -- reset the history index after pressing enter
        if new_line then
          history_index = #history
          new_line = false
        else
          -- decrement history_index
          history_index = util.clamp(history_index - 1, 1, #history)
        end
        my_string = history[history_index]
      end
    elseif code == "DOWN" then
      -- make sure there is a history, and we are accessing it
      if #history > 0 and history_index ~= nil then
        -- increment history_index
        history_index = util.clamp(history_index + 1, 1, #history)
        my_string = history[history_index]
      end
    elseif code == "RIGHT" then
      if show_info then
        info_focus = util.clamp(info_focus + 1, 1, 5)
      end
    elseif code == "LEFT" then
      if show_info then
        info_focus = util.clamp(info_focus - 1, 1, 5)
      end
    elseif code == "ENTER" then
      -- parse string for commands
      -- there is likely a better way to do this sort of thing
      local command = split_string(my_string)
      -- rand
      if command[1] == "rand" then
        local track, control, p = tonumber(command[2]), tonumber(command[3]), controls[track][control]
        local low, high = tonumber(params:get_range(p)[1]), tonumber(params:get_range(p)[2])
        local n = math.random(low, high)
        params:set(controls[track][control], n)
      -- rrand
      elseif command[1] == "rrand" then
        local low, high, track, control = tonumber(command[2]), tonumber(command[3]), tonumber(command[4]), tonumber(command[5])
        local n = math.random(low, high)
        params:set(controls[track][control], n)
      -- assign controls
      -- enc
      elseif command[1] == "enc" then
        local id = tonumber(command[2])
        if command[3] == "macro" then
          local state = tonumber(command[4])
          silos.is_macro[id] = state == 1 and true or false
        elseif command[3] == "fx" then
          local control = tonumber(command[4])
          silos.enc_choices[id] = fx_controls[control]
        else
          local track, control = tonumber(command[3]), tonumber(command[4])
          silos.enc_choices[id] = controls[track][control]
        end
      -- arc
      elseif command[1] == "arc" then
        local id = tonumber(command[2])
        if command[3] == "fx" then
          local control = tonumber(command[4])
          silos.arc_choices[id] = fx_controls[control]
        else
          local track, control = tonumber(command[3]), tonumber(command[4])
          silos.arc_choices[id] = controls[track][control]
        end
      -- gridx
      elseif command[1] == "gridx" then
        local id = tonumber(command[2])
        if command[3] == "fx" then
          local control = tonumber(command[4])
          silos.gridx_choices[id] = fx_controls[control]
        else
          local track, control = tonumber(command[3]), tonumber(command[4])
          silos.gridx_choices[id] = controls[track][control]
        end
      -- gridy
      elseif command[1] == "gridy" then
        local id = tonumber(command[2])
        if command[3] == "fx" then
          local control = tonumber(command[4])
          silos.gridy_choices[id] = fx_controls[control]
        else
          local track, control = tonumber(command[3]), tonumber(command[4])
          silos.gridy_choices[id] = controls[track][control]
        end
      -- set grid mode
      elseif command[1] == "grid_mode" then
        silos.grid_mode = tonumber(command[2])
      -- set all gates
      elseif command[1] == "g" or command[1] == "gate" then
        for i = 1, 4 do
          local state = tonumber(command[i + 1])
          params:set(i .. "gate", state)
        end
      -- set all records
      elseif command[1] == "r" or command[1] == "record" then
        for i = 1, 4 do
          local state = tonumber(command[i + 1])
          params:set(i .. "record", state)
        end
      -- parameter snapshots
      -- snap
      elseif command[1] == "s" or command[1] == "snap" then
        local snap_id, t = tonumber(command[2]), tonumber(command[3])
        silos.snaps[t][snap_id] = {}
        for i = 1, #controls[t] do
          table.insert(silos.snaps[t][snap_id], params:get(controls[t][i]))
        end
      -- load
      elseif command[1] == "l" or command[1] == "load" then
        local snap_id, t = tonumber(command[2]), tonumber(command[3])
        if #silos.snaps[t][snap_id] > 0 then
          for i = 1, #controls[t] do
            params:set(controls[t][i], silos.snaps[t][snap_id][i])
          end
        end
      -- macro commands
      elseif command[1] == "macro" then
        local id = tonumber(command[2])
        if command[3] == "clear" then
          silos.macros[id] = {}
        elseif command[3] == "fx" then
          local control, mul = tonumber(command[4]), tonumber(command[5])
          table.insert(silos.macros[id], fx_controls[control])
          table.insert(silos.muls[id], mul)
        else
          local track, control, mul = tonumber(command[3]), tonumber(command[4]), tonumber(command[5])
          table.insert(silos.macros[id], controls[track][control])
          table.insert(silos.muls[id], mul)
        end
      -- state/pset persistence
      elseif command[1] == "save_state" then
        save_state(command[2])
      elseif command[1] == "load_state" then
        load_state(command[2])
      elseif command[1] == "save_pset" then
        save_pset()
      elseif command[1] == "load_pset" then
        load_pset()
      -- set single parameters
      elseif tabutil.contains(controls[track], command[2] .. command[1]) then
        local v = tonumber(command[3])
        params:set(command[2] .. command[1], v)
      elseif command[1] == "fx" then
        local c, v = tonumber(command[2]), tonumber(command[3])
        params:set(fx_controls[c], v)
      end
      -- append the command to history
      table.insert(history, my_string)
      -- clear my_string
      my_string = ""
      new_line = true
    end
    is_dirty = true
  end
end
