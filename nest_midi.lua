-- nest_ study 4
-- state & meta-affordances
--
-- grid (synth):
--      1-8        9-16
--   1:  patterns  presets
-- 2-8: keybaord  controls   
--
-- screen (delay):
-- e1: delay
-- e2: rate
-- e3: feedback
-- k2: reverse

include 'lib/nest_/core'
include 'lib/nest_/norns'
include 'lib/nest_/grid'
include 'lib/nest_/txt'
local music = require "musicutil"
local scales = {names = {}, notes = {}}
for i = 1, #music.SCALES do
    table.insert(scales['names'], string.lower(music.SCALES[i].name))
    table.insert(scales['notes'], music.generate_scale(0, scales['names'][i]))
end
local note_list = {}
for i=0,11 do
    table.insert(note_list, music.note_num_to_name(i))
end

--polysub = include 'we/lib/polysub'
--delay = include 'awake/lib/halfsecond'
local cs = require 'controlspec'
m = midi.connect()

scale = scales['notes'][1]
root = 440 * 2^(5/12) -- the d above middle a

--engine.name = 'PolySub'

synth = nest_ {
    grid = nest_ {
        pattern_group = nest_ {
            keyboard = _grid.momentary {
                x = { 1, #scale }, -- notes on the x axis
                y = { 2, 8 },-- octaves on the y axis
                
                action = function(self, value, t, d, added, removed)
                    local key = added or removed
                    local id = key.y * 7 + key.x -- a unique integer for this grid key
                    
                    local octave = key.y - 5
                    local note = 59 + params:get("root") + scale[key.x] + 12*octave
                    --local playNote = root * 2^octave * 2^(note/12)
                    --print(music.note_num_to_name(note))
                    if params:get("output") == 1 then
                        if added then m:note_on(note, 100, 1) --engine.start(id, hz)
                        elseif removed then m:note_off(note, 0, 1) end--engine.stop(id) end
                    elseif params:get("output") == 2 then
                        if added then crow.send("ii.wsyn.play_note(".. ((note-48)/12 ..", " .. params:get("wsyn_vel") .. ")")) end
                    end
                end
            },
            control_preset = _grid.preset {
                y = 1, x = { 9, 16 },
                target = function(self) return synth.grid.controls end
            }
        },
        pattern = _grid.pattern {
            y = 1, x = { 1, 8 },
            target = function(self) return synth.grid.pattern_group end,
            stop = function()
                synth.grid.pattern_group.keyboard:clear()
                --engine.stopAll()
                for i=0,127 do
                    m:note_off(i,0,1)
                end
            end
        },
    
        -- synth controls
        controls = nest_ {
            shape = _grid.control {
                x = 9, y = { 2, 8 },
                action = function(self, value) 
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_1"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_curve", (value * 10) - 5)
                    end
                end --engine.shape(value)
                
            },
            timbre = _grid.control {
                x = 10, y = { 2, 8 },
                --v = 0.5,
                action = function(self, value) 
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_2"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_ramp", (value * 10) - 5)
                    end
                end --engine.timbre(value)
            },
            noise = _grid.control {
                x = 11, y = { 2, 8 },
                action = function(self, value) 
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_3"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_fm_index", (value * 10) / 2)
                    end
                    --print(math.floor(value * 127))
                end --engine.noise(value)
            },
            hzlag = _grid.control {
                x = 12, y = { 2, 8 },
                --range = { 0, 10 },
                action = function(self, value)
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_4"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_fm_env", (value * 10) - 5)
                    end
                end --engine.hzLag(value)
            },
            cut = _grid.control {
                x = 13, y = { 2, 8 },
                --range = { 1.5, 8 },
                --value = 8,
                action = function(self, value) 
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_5"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_fm_ratio_num", math.floor(value * 10))
                    end
                end --engine.cut(value)
            },
            attack = _grid.control {
                x = 14, y = { 2, 8 },
                --range = { 0.01, 10 },
                --value = 0.01,
                action = function(self, value)
                    --m:cc() --engine.cutAtk(value)
                    --m:cc() --engine.ampAtk(value)
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_6"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_fm_ratio_den", math.floor(value * 10))
                    end
                end
            },
            sustain = _grid.control {
                x = 15, y = { 2, 8 },
                --value = 1,
                action = function(self, value)
                    --engine.cutSus(value)
                    --engine.ampSus(value)
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_7"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_lpg_time", (value * 10) - 5)
                    end
                end
            },
            release = _grid.control {
                x = 16, y = { 2, 8 },
                --range = { 0.01, 10 },
                --value = 0.01,
                action = function(self, value)
                    --engine.cutDec(value)
                    --print(math.floor(value * 127))
                    if params:get("output") == 1 then
                        m:cc(params:get("cc_8"), math.floor(value * 127), 1)
                    elseif params:get("output") == 2 then
                        params:set("wsyn_lpg_symmetry", (value * 10) - 5)
                    end 
                    --engine.ampDec(value)
                    --engine.cutRel(value)
                    --engine.ampRel(value)
                    --m:cc(89, math.floor(value * 127), 1)
                end
            }
        }
    },
    
    -- screen stuff
    --[[screen = nest_ {
        delay = _txt.enc.control {
            x = 2, y = 8,
            value = 0.5,
            n = 1,
            action = function(self, value) end --softcut.level(1, value) end
        },
        rate = _txt.enc.control {
            x = 2, y = 30,
            range = { 0.5, 2 },
            warp = 'exp',
            value = 0.5,
            n = 2,
            action = function(self, value) 
                --local dir = (self.parent.reverse.value == 1) and -1 or 1
                --softcut.rate(1, value * dir) 
                --print("rate", value * dir)
            end
        },
        feedback = _txt.enc.control {
            x = 64, y = 30,
            n = 3,
            value = 0.75,
            --action = function(self, value) softcut.pre_level(1, value) end
        },
        reverse = _txt.key.toggle {
            x = 2, y = 50,
            n = 2,
            action = function(self, value) 
                --local dir = (value == 1) and -1 or 1
                --local rate = self.parent.rate.value
                --softcut.rate(1, rate * dir)
                --print("rate", rate * dir)
            end
        }
    }]]
}

synth.grid:connect {
    g = grid.connect()
}

--synth.screen:connect {
--    screen = screen,
--    key = key,
--    enc = enc
--}

function init()
    --delay.init()
    --polysub.params()
    params:add_option("scale", "scale", scales['names'], 1)
    params:add_option("root", "root note", note_list, 1)
    params:add_option("output", "output", {"midi", "w/syn"}, 1)
    params:add_group("midi mappings", 8)
    params:add_number("cc_1", "x = 9 -> cc:", 1, 127, 27)
    params:add_number("cc_2", "x = 10 -> cc:", 1, 127, 29)
    params:add_number("cc_3", "x = 11 -> cc:", 1, 127, 23)
    params:add_number("cc_4", "x = 12 -> cc:", 1, 127, 24)
    params:add_number("cc_5", "x = 13 -> cc:", 1, 127, 25)
    params:add_number("cc_6", "x = 14 -> cc:", 1, 127, 86)
    params:add_number("cc_7", "x = 15 -> cc:", 1, 127, 87)
    params:add_number("cc_8", "x = 16 -> cc:", 1, 127, 88)
    
    wsyn_add_params()

    synth:load()
    synth:init()
end

function wsyn_add_params()
    params:add_group("w/syn",10)
    params:add {
      type = "option",
      id = "wsyn_ar_mode",
      name = "AR mode",
      options = {"off", "on"},
      default = 2,
      action = function(val) 
        crow.send("ii.wsyn.ar_mode(".. (val-1) ..")")
      end
    }
    params:add {
      type = "control",
      id = "wsyn_vel",
      name = "Velocity",
      controlspec = controlspec.new(0, 5, "lin", 0, 3, "v"),
      action = function(val) 
        pset_wsyn_vel = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_curve",
      name = "Curve",
      controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.curve(" .. val .. ")") 
        pset_wsyn_curve = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_ramp",
      name = "Ramp",
      controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.ramp(" .. val .. ")") 
        pset_wsyn_ramp = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_fm_index",
      name = "FM index",
      controlspec = controlspec.new(0, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.fm_index(" .. val .. ")") 
        pset_wsyn_fm_index = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_fm_env",
      name = "FM env",
      controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.fm_env(" .. val .. ")") 
        pset_wsyn_fm_env = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_fm_ratio_num",
      name = "FM ratio numerator",
      controlspec = controlspec.new(1, 20, "lin", 1, 2),
      action = function(val) 
        crow.send("ii.wsyn.fm_ratio(" .. val .. "," .. params:get("wsyn_fm_ratio_den") .. ")") 
        pset_wsyn_fm_ratio_num = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_fm_ratio_den",
      name = "FM ratio denominator",
      controlspec = controlspec.new(1, 20, "lin", 1, 1),
      action = function(val) 
        crow.send("ii.wsyn.fm_ratio(" .. params:get("wsyn_fm_ratio_num") .. "," .. val .. ")") 
        pset_wsyn_fm_ratio_den = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_lpg_time",
      name = "LPG time",
      controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.lpg_time(" .. val .. ")") 
        pset_wsyn_lpg_time = val
      end
    }
    params:add {
      type = "control",
      id = "wsyn_lpg_symmetry",
      name = "LPG symmetry",
      controlspec = controlspec.new(-5, 5, "lin", 0, 0, "v"),
      action = function(val) 
        crow.send("ii.wsyn.lpg_symmetry(" .. val .. ")") 
        pset_wsyn_lpg_symmetry = val
      end
    }
    params:add{
      type = "trigger",
      id = "wsyn_init",
      name = "Init",
      action = function()
        params:set("wsyn_curve", pset_wsyn_curve)
        params:set("wsyn_ramp", pset_wsyn_ramp)
        params:set("wsyn_fm_index", pset_wsyn_fm_index)
        params:set("wsyn_fm_env", pset_wsyn_fm_env)
        params:set("wsyn_fm_ratio_num", pset_wsyn_fm_ratio_num)
        params:set("wsyn_fm_ratio_den", pset_wsyn_fm_ratio_den)
        params:set("wsyn_lpg_time", pset_wsyn_lpg_time)
        params:set("wsyn_lpg_symmetry", pset_wsyn_lpg_symmetry)
        params:set("wsyn_vel", pset_wsyn_vel)
      end
    }
    params:hide("wsyn_init")
  end

function cleanup()
    synth:save()
end