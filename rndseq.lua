-- RNDSEQ: random sequencer
--
-- E1 speed control
-- E2 scale select
--   scale change generates a
--   new sequence
-- E3 number of steps

-- uses NORNSLERPLATE written by TE

music = require 'musicutil'

engine.name = 'PolyPerc'

max_steps = 16
valid_notes = {}
sequence = {}
position = 1

function init()
  -- setting number of steps using params
  params:add{type = "number", id = "num_steps", name = "number of steps",
    min = 2, max = 16, default = 8}

  -- setting root notes using params
  params:add{type = "number", id = "root_note", name = "root note",
    min = 0, max = 127, default = 60, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function() build_scale() end} -- by employing build_scale() here, we update the scale

  -- setting scale type using params
  scale_names = {}
  for i = 1, #music.SCALES do
    table.insert(scale_names, music.SCALES[i].name)
  end
  params:add{
    type="option",
    id="scale",
    name="scale",
    options=scale_names,
    default=2,
    action=function() build_scale() end}
  build_scale()
  generate_sequence()
  screen_dirty = true
  redraw_clock_id = clock.run(redraw_clock)
  clock.run(play)
end

function play()
  while true do
    position = (position % params:get("num_steps")) + 1
    engine.hz(music.note_num_to_freq(sequence[position]))
    screen_dirty = true
    clock.sync(1/4)
  end
end

function build_scale() 
  valid_notes = music.generate_scale(
    params:get("root_note"),
    params:get("scale"),
    1
  )
  generate_sequence()
end

function generate_sequence()
  for x = 1, max_steps do
    sequence[x] = valid_notes[math.random(#valid_notes)]
  end
end

function enc(e, d)
  if e == 1 then
    params:delta("clock_tempo", d)
  end
  if e == 2 then 
    params:delta("scale", d)
  end
  if e == 3 then
    params:delta("num_steps", d)
  end
  screen_dirty = true
end

function turn(e, d)
  message = "encoder " .. e .. ", delta " .. d
end

function key(k, z)
  if z == 0 then return end
  if k == 2 then press_down(2) end
  if k == 3 then press_down(3) end
  screen_dirty = true
end

function press_down(i)
  message = "press down " .. i
end

function redraw_clock()
  while true do
    clock.sleep(1/15)
    if screen_dirty then
      redraw()
      screen_dirty = false
    end
  end
end

function redraw()
  screen.clear()
  number_of_notes = #music.SCALES[params:get("scale")].intervals
  -- draw grid
  --for i = 1, #music.SCALES[params:get("scale")].intervals
  for i = 1, params:get("num_steps")
  do
    for j = 1, number_of_notes
    --for j = 1, params:get("num_steps")
    do
      brightness = 4
      if i == position then
        brightness = brightness + 4
      end
      if sequence[i] == valid_notes[j] then
        brightness = brightness + 7
      end
      screen.level(brightness)
      screen.rect(5 * i, 5 * (number_of_notes - j + 1), 3.5, 3.5)
      screen.fill()
    end
  end 
  screen.level(4)
  screen.font_face(25)
  screen.font_size(6)
  screen.move(85, 10)
  screen.text('bpm ')
  screen.move(85, 18)
  screen.level(10)
  screen.text(params:get("clock_tempo"))
  screen.move(85, 26)
  screen.level(4)
  screen.text('scale')
  screen.move(85,34)
  screen.level(10)
  screen.text(music.SCALES[params:get("scale")].name)
  screen.move(85,42)
  screen.level(4)
  screen.text('steps')
  screen.move(85,50)
  screen.level(10)
  screen.text(params:get("num_steps"))
  screen.update()
end

function r()
  norns.script.load(norns.state.script)
end

function cleanup()
  clock.cancel(redraw_clock_id)
end
