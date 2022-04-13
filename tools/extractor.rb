# The MIT License (MIT)
#
# Copyright (c) 2017 Joao Pimentel <joaofelipenp at gmail dot com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# The only purpuse of this script is to extract translation data from unpacked
# rpg maker projects. It is not executed in the game, and can be safelly removed
# for deploy

require 'fileutils'
require 'digest'

def convert(text)
  #return text.inspect
  if text.is_a?(Array)
    joined = text.collect {|x| convert(x)}.join(", ")
    "[#{joined}]".force_encoding("UTF-8")
  elsif text.is_a?(String)
    replaced = (text
      .gsub(/\\/, '\\\\\\')
      .gsub(/\n/, '\\\\n')
      .gsub(/\r/, '\\\\r')
      .gsub(/\t/, '\\\\t')
      .gsub(/\f/, '\\\\f')
      .gsub(/"/, '\\\\"')
    )
    "\"#{replaced}\"".force_encoding("UTF-8")
  else
    text.inspect.force_encoding("UTF-8")
  end
end


class Class
 
  def initializer(params, defaults)
    
    if params.nil?
      params = defaults.keys
    end
    pars = []
    params.each do |param|
      if defaults.include? param
        pars.push("#{param} = #{defaults[param].inspect}")
      else
        pars.push("#{param}")
      end
    end
    compare_lines = ["def <=>(other)"]
    
    lines = ["def initialize(#{pars.join(", ")})"]
    defaults.each do |key, value|
      if params.include? key
        lines.push("@#{key} = #{key}")
      elsif value.instance_of? String and value.start_with? ">"
        lines.push("@#{key} = #{value[1..-1]}")
      else
        lines.push("@#{key} = #{value.inspect}")
      end
      self.class_eval("def #{key};@#{key};end")
      self.class_eval("def #{key}=(val);@#{key}=val;end")
      compare_lines.push("(self.#{key} <=> other.#{key}).nonzero? ||")
    end
    lines.push("end")
    compare_lines.push("0")
    compare_lines.push("end")
    self.class_eval(lines.join("\n"))
    self.class_eval("include Comparable")
    self.class_eval(compare_lines.join("\n"))
  end
end

class Color  # Credits: vgvgf
  def initialize(r, g, b, a = 255)
    @red, @green, @blue, @alpha = r, g, b, a
  end
  attr_accessor :red, :green, :blue, :alpha
  def <=>(other)
    (@red <=> other.red).nonzero? ||
    (@green <=> other.green).nonzero? ||
    (@blue <=> other.blue).nonzero? ||
    (@alpha <=> other.alpha).nonzero? ||
    0
  end
  def self._load(s)
    Color.new(*s.unpack('d4'))
  end
  def _dump(d = 0)
    [@red, @green, @blue, @alpha].pack('d4')
  end
  # ...
end

class Table  # Credits: vgvgf/Raku
  def initialize(x, y = 0, z = 0)
     @dim = 1 + (y > 0 ? 1 : 0) + (z > 0 ? 1 : 0)
     @xsize, @ysize, @zsize = x, [y, 1].max, [z, 1].max
     @data = Array.new(x * y * z, 0)
  end
  def <=>(other)
    (@xsize <=> other.xsize).nonzero? ||
    (@ysize <=> other.ysize).nonzero? ||
    (@zsize <=> other.zsize).nonzero? ||
    (@data <=> other.data).nonzero? ||
    0
  end
  def [](x, y = 0, z = 0)
     @data[x + y * @xsize + z * @xsize * @ysize]
  end
  def []=(*args)
     x = args[0]
     y = args.size > 2 ? args[1] : 0
     z = args.size > 3 ? args[2] : 0
     v = args.pop
     @data[x + y * @xsize + z * @xsize * @ysize] = v
  end
  def _dump(d = 0)
     [@dim, @xsize, @ysize, @zsize, @xsize * @ysize * @zsize].pack('LLLLL') <<
     @data.pack("S#{@xsize * @ysize * @zsize}")
  end
  def self._load(s)
     size, nx, ny, nz, items = *s[0, 20].unpack('LLLLL')
     t = Table.new(*[nx, ny, nz][0,size])                # The * breaks apart an array into an argument list
     t.data = s[20, items * 2].unpack("S#{items}")
     t
  end
  attr_accessor(:xsize, :ysize, :zsize, :data)
end

class Tone  # Credits: vgvgf
  def initialize(r, g, b, a = 0)
    @red, @green, @blue, @gray = r, g, b, a
  end
  attr_accessor :red, :green, :blue, :gray
  def <=>(other)
    (@red <=> other.red).nonzero? ||
    (@green <=> other.green).nonzero? ||
    (@blue <=> other.blue).nonzero? ||
    (@gray <=> other.gray).nonzero? ||
    0
  end
  def self._load(s)
    Tone.new(*s.unpack('d4'))
  end
  def _dump(d = 0)
    [@red, @green, @blue, @gray].pack('d4')
  end
  # ...
end
  

# Mimics RPG module, according to RMXP documentation
module RPG
  
  module Cache
    
  end
  class Sprite

  end
  class Weather
  end
  
  class Actor
    initializer([], {
      id: 0, name: "", class_id: 1, initial_level: 1, final_level:99,
      exp_basis: 30, exp_inflation: 30, character_name: "",
      character_hue: 0, battler_name: "", battler_hue: 0,
      parameters: (">Table.new(5, 100)\n" +
        "for i in 1..99\n" +
        "  @parameters[0,i] = 500+i*50\n" +
        "  @parameters[1,i] = 500+i*50\n" +
        "  @parameters[2,i] = 50+i*5\n" +
        "  @parameters[3,i] = 50+i*5\n" +
        "  @parameters[4,i] = 50+i*5\n" +
        "  @parameters[5,i] = 50+i*5\n" +
        "end"
        ),
      weapon_id: 0, armor1_id: 0, armor2_id: 0, armor3_id: 0, armor4_id: 0,
      weapon_fix: false, armor1_fix: false, armor2_fix: false,
      armor3_fix: false, armor4_fix: false,
    })
  end
  
  class Animation
    initializer([], {
      id: 0, name: "", animation_name: "", animation_hue: 0, position: 1,
      frame_max: 1, frames: ">[RPG::Animation::Frame.new]", timings: []
    })
    
    class Frame
      initializer([], {cell_max: 0, cell_data: ">Table.new(0, 0)"})
    end
    
    class Timing
      initializer([], {
        frame: 0, se: ">RPG::AudioFile.new('', 80)", flash_scope: 0,
        flash_color: ">Color.new(255,255,255,255)", flash_duration: 5,
        condition: 0
      })
    end
  end
  
  class Armor
    initializer([], {
      id: 0, name: "", icon_name: "", description: "", kind: 0,
      auto_state_id: 0, price: 0, pdef: 0, mdef: 0, eva: 0, str_plus: 0,
      dex_plus: 0, agi_plus: 0, int_plus: 0, guard_element_set: [],
      guard_state_set: []
    })
  end
  
  class AudioFile
    initializer(nil, {name: "", volume: 100, pitch: 100})
  end
  
  class Class
    initializer([], {
      id: 0, name: "", position: 0, weapon_set: [], armor_set: [],
      element_ranks: ">Table.new(1)", state_ranks: ">Table.new(1)",
      learnings: []
    })
    
    class Learning
      initializer([], {level: 1, skill_id: 1})
    end
  end
  
  class CommonEvent
    initializer([], {
      id: 0, name: "", trigger: 0, switch_id: 1,
      list: ">[RPG::EventCommand.new]"
    })
  end
  
  class Enemy
    initializer([], {
      id: 0, name: "", battler_name: "", battler_hue: 0, maxhp: 500,
      maxsp: 500, str: 50, dex: 50, agi: 50, int: 50, atk: 100, pdef: 100,
      mdef: 100, eva: 0, animation1_id: 0, animation2_id: 0, 
      element_ranks: ">Table.new(1)", state_ranks: ">Table.new(1)",
      actions: ">[RPG::Enemy::Action.new]", exp: 0, gold: 0, item_id: 0,
      weapon_id: 0, armor_id: 0, treasure_prob: 100
    })
    
    class Action
      initializer([], {
        kind: 0, basic: 0, skill_id: 1, condition_turn_a: 0,
        condition_turn_b: 1, condition_hp: 100, condition_level: 1,
        condition_switch_id: 0, rating: 5
      })
    end
  end
  
  class Event
    initializer([:x, :y], {id: 0, name: "", pages:">[RPG::Event::Page.new]"})
    
    class Page
      initializer([], {
        contition: ">RPG::Event::Page::Condition.new",
        graphic: ">RPG::Event::Page::Graphic.new",
        move_type: 0,
        move_speed: 3,
        move_frequency: 3,
        move_route: ">RPG::MoveRoute.new",
        walk_anime: true,
        step_anime: false,
        direction_fix: false,
        through: false,
        always_on_top: false,
        trigger: 0,
        list: ">[RPG::EventCommand.new]"
      })

      class Condition
        initializer([], {
          switch1_valid: false,
          switch2_valid: false,
          variable_valid: false,
          self_switch_valid: false,
          switch1_id: 1,
          switch2_id: 1,
          variable_id: 1,
          varaible_value: 0,
          self_switch_ch: "A",
        })
      end
      class Graphic
        initializer([], {
          tile_id: 0,
          character_name: "",
          character_hue: 0,
          direction: 2,
          pattern: 0,
          opacity: 255,
          blend_type: 0
        })
      end
    end
  end
  
  class EventCommand
    initializer(nil, {code: 0, indent: 0, parameters: []})
  end
  
  class Item
    initializer([], {
      id: 0, name: "", icon_name: "", description: "", scope: 0,
      occasion: 0, animation1_id: 0, animation2_id: 0, 
      menu_se: ">RPG::AudioFile.new('', 80)", common_event_id: 0,
      price: 0, consumable: true, parameter_type: 0, parameter_points: 0,
      recover_hp_rate: 0, recover_hp: 0, recover_sp_rate: 0, recover_sp: 0,
      hit: 100, pdef_f: 0, mdef_f: 0, variance: 0, element_set: [],
      plus_state_set: [], minus_state_set: []
    })
  end
  
  class Map
    initializer([:width, :height], {
      tileset_id: 1,
      autoplay_bgm: false,
      bgm: '>RPG::AudioFile.new',
      autoplay_bgs: false,
      bgs: '>RPG::AudioFile.new("", 80)', 
      encounter_list: [],
      encounter_step: 30,
      data: '>Table.new(width, height, 3)',
      events: {},
    })
  end
  
  class MapInfo
    initializer([], {
      name: "", parent_id: 0, order: 0, expanded: false, scroll_x: 0,
      scroll_y: 0
    })
  end
  
  class MoveCommand
    initializer(nil, {code: 0, parameters: []})
  end
    
  class MoveRoute
    initializer([], {repeat: true, skippable: false, list: ">[RPG::MoveCommand.new]"})
  end
  
  class Skill
    initializer([], {
      id: 0, name: "", icon_name: "", description: "", scope: 0,
      occasion: 1, animation1_id: 0, animation2_id: 0, 
      menu_se: ">RPG::AudioFile.new('', 80)", common_event_id: 0,
      sp_cost: 0, power: 0, atk_f: 0, eva_f: 0, str_f: 0, dex_f: 0,
      agi_f: 0, int_f: 100, hit: 100, pdef_f: 0, mdef_f: 100, variance: 15,
      element_set: [], plus_state_set: [], minus_state_set: []
    })
  end
  
  class State
    initializer([], {
      id: 0, name: "", animation_id: 0, restriction: 0, nonresistence: false,
      zero_hp: false, cant_get_exp: false, cant_evade: false,
      slip_damage: false, rating: 5, hit_rate: 100, maxhp_rate: 100,
      maxsp_rate: 100, str_rate: 100, dex_rate: 100, agi_rate: 100,
      int_rate: 100, atk_rate: 100, pdef_rate: 100, mdef_rate: 100,
      eva: 0, battle_only: true, hold_turn: 0, auto_release_prob: 0,
      shock_release_prob: 0, guard_element_set: [],
      plus_state_set: [], minus_state_set: []
    })
  end
  
  class System
    initializer([], {
      magic_number: 0, party_members: [1], elements: [nil, ""],
      switches: [nil, ""], variables: [nil, ""], windowskin_name: "",
      title_name: "", gameover_name: "", battle_transition: "",
      title_bgm: ">RPG::AudioFile.new", battle_bgm: ">RPG::AudioFile.new", 
      battle_end_me: ">RPG::AudioFile.new", gameover_me: ">RPG::AudioFile.new",
      cursor_se: ">RPG::AudioFile.new('', 80)", decision_se: ">RPG::AudioFile.new('', 80)",
      cancel_se: ">RPG::AudioFile.new('', 80)", buzzer_se: ">RPG::AudioFile.new('', 80)",
      equip_se: ">RPG::AudioFile.new('', 80)", shop_se: ">RPG::AudioFile.new('', 80)",
      save_se: ">RPG::AudioFile.new('', 80)", load_se: ">RPG::AudioFile.new('', 80)",
      battle_start_se: ">RPG::AudioFile.new('', 80)", escape_se: ">RPG::AudioFile.new('', 80)",
      actor_collapse_se: ">RPG::AudioFile.new('', 80)", enemy_collapse_se: ">RPG::AudioFile.new('', 80)",
      words: ">RPG::System::Words.new", test_battlers: [], test_troop_id: 1,
      start_map_id: 1, start_x: 0, start_y: 0, battleback_name: "", 
      battler_name: "", battler_hue: 0, edit_map_id: 1
    })
    
    class Words
      initializer([], {
        gold: "", hp: "", sp: "", str: "", dex: "", agi: "", int: "",
        atk: "", pdef: "", mdef: "", weapon: "", armor1: "", armor2: "",
        armor3: "", armor4: "", attack: "", skill: "", guard: "", item: "",
        equip: ""
      })
    end
    
    class TestBattler
      initializer([], {
        actor_id: 1, level: 1, weapon_id: 0, armor1_id: 0, armor2_id: 0,
        armor3_id: 0, armor4_id: 0
      })
    end
  end
  
  class Tileset
    initializer([], {
      id: 0, name: "", tileset_name: "", autotile_names: ">['']*7",
      panorama_name: "", panorama_hue: 0, fog_name: "", fog_hue: 0,
      fog_opacity: 64, fog_blend_type: 0, fog_zoom: 200, fog_sx: 0,
      fog_sy: 0, battleback_name: "", passages: ">Table.new(384)",
      priorities: ">Table.new(384)\n@priorities[0] = 5", 
      terrain_tags: ">Table.new(384)"
    })
  end
  
  class Troop
    initializer([], {
        id: 0, name: "", members: [], pages: ">[RPG::Troop::Page.new]"
    })
    
    class Member
      initializer([], {
        enemy_id: 1, x: 0, y: 0, hidden: false, immortal: false
      })
    end
    
    class Page
      initializer([], {
        condition: ">RPG::Troop::Page::Condition.new", span: 0,
        list: ">[RPG::EventCommand.new]"
      })
      
      class Condition
        initializer([], {
          turn_valid: false, enemy_valid: false, actor_valid: false,
          switch_valid: false, turn_a: 0, turn_b: 0, enemy_index: 0,
          enemy_hp: 50, actor_id: 1, actor_hp: 50, switch_id: 1
        })
      end
    end
  end
  
  class Weapon
    initializer([], {
      id: 0, name: "", icon_name: "", description: "", animation1_id: 0,
      animation2_id: 0, price: 0, atk: 0, pdef: 0, mdef: 0, str_plus: 0,
      dex_plus: 0, agi_plus: 0, int_plus: 0, element_set: [], 
      plus_state_set: [], minus_state_set: [],
    })
  end
  
end

class Window_Selectable
  attr_accessor :index
  attr_accessor :data

  def initialize(x, y, z, w)
    self.index = 0
  end
end


class Scene_File
  attr_accessor :text

  def initialize(x)
    self.text = x
  end
  def make_filename(x)
    "<invalid>"
  end
end

class Game_Temp
  attr_accessor :last_file_index
end

class Spriteset_Map
end



def process_page(result, page_id, list)
  added = false
  index = 0
  semibar = "-" * 42
  bar = semibar + "\n"
  temp = []
  temp.push("      #{page_id} => {")
  
  loop do
    break if index >= list.size
    command = list[index] 
    last_index = index
    index += 1
    if command.code == 101
      message_text = command.parameters[0].force_encoding("UTF-8") + "\n"
      loop do
        break if index >= list.size
        command = list[index]
        if command.code == 101
          message_text += bar
          message_text += command.parameters[0].force_encoding("UTF-8") + "\n"
        elsif command.code == 401
          message_text += command.parameters[0].force_encoding("UTF-8") + "\n"
        else
          break
        end
        index += 1
      end
      added = true
      temp.push("        #{last_index} =>")
      temp.push("          ##{semibar}")
      message_text.split("\n").each do |line|
        temp.push("          #{convert(line + "\n")}\\")
      end
      temp[-1][-1] = ","
    elsif command.code == 102
      added = true
      temp.push("        #{last_index} => #{convert(command.parameters)},")  
    end
  end
  temp.push("      },")
  result.push(*temp) if added
  added
end

def process_common_event(result, event_id, event)
  return false if event.nil?
  temp = []
  temp.push("    #{event_id} => {")
  added = process_page(temp, 0, event.list)
  temp.push("    },")
  result.push(*temp) if added
  added
end

def process_event(result, event_id, event)
  added = false
  temp = []
  temp.push("    #{event_id} => {")
  event.pages.each_with_index do |page, id|
    added |= process_page(temp, id, page.list)
  end
  temp.push("    },")
  result.push(*temp) if added
  added
end

def process_map(result, map_id, base=".")
  added = false
  temp = []
  temp.push("  #{map_id} => {")
  fname = File.join(base, "Data", "Map#{map_id.to_s.rjust(3, "0")}.rxdata")
  File.open(fname, "rb") do |f|
    map = Marshal.load(f)
    map.events.sort.to_h.each do |id, event|
      added |= process_event(temp, id, event)
    end
  end
  $singleton_digest << Digest::SHA256.file(fname).hexdigest
  temp.push("  },")
  result.push(*temp) if added
  added
end

def process_common_events(result, base=".")
  added = false
  temp = []
  temp.push("  0 => {")
  fname = File.join(base, "Data", "CommonEvents.rxdata")
  File.open(fname, "rb") do |f|
    common_events = Marshal.load(f)
    common_events.each_with_index do |event, id|
      added |= process_common_event(temp, id, event)
    end
  end
  $singleton_digest << Digest::SHA256.file(fname).hexdigest
  temp.push("  },")
  result.push(*temp) if added
  added
end

def process_maps(result, base=".")
  added = false
  Dir[File.join(base, "Data", "Map[0-9][0-9][0-9].rxdata")].each do |name|
    map_id = /Map(\d\d\d).rxdata/.match(name)[1].to_i
    added |= process_map(result, map_id, base=base)
  end
  added
end

def process_events(result, base=".")
  result.push("$events_lang = {")
  process_common_events(result, base=base)
  process_maps(result, base=base)
  result.push("}")
  true
end
  
def process_name(result, instance_id, instance)
  return false if instance.nil?
  result.push("  #{instance_id} => #{convert(instance.name)},")
  true
end

def process_name_description(result, instance_id, instance)
  return false if instance.nil?
  result.push("  #{instance_id} => #{convert([instance.name, instance.description])},")
  true
end

def process_name_list(result, filename, method=:process_name)
  added = false
  File.open(filename, "rb") do |f|
    list = Marshal.load(f)
    list.each_with_index do |instance, id|
      added |= send(method, result, id, instance)
    end
  end
  $singleton_digest << Digest::SHA256.file(filename).hexdigest
  added
end
  
def process_actors(result, base=".")
  result.push("$actors_lang = {")
  process_name_list(result, File.join(base, "Data", "Actors.rxdata"))
  result.push("}")
  true
end

def process_animations(result, base=".")
  result.push("$animations_lang = {")
  process_name_list(result, File.join(base, "Data", "Animations.rxdata"))
  result.push("}")
  true
end
  
def process_armors(result, base=".")
  result.push("$armors_lang = {")
  process_name_list(result, File.join(base, "Data", "Armors.rxdata"), :process_name_description)
  result.push("}")
  true
end

def process_classes(result, base=".")
  result.push("$classes_lang = {")
  process_name_list(result, File.join(base, "Data", "Classes.rxdata"))
  result.push("}")
  true
end

def process_enemies(result, base=".")
  result.push("$enemies_lang = {")
  process_name_list(result, File.join(base, "Data", "Enemies.rxdata"))
  result.push("}")
  true
end

def process_items(result, base=".")
  result.push("$items_lang = {")
  process_name_list(result, File.join(base, "Data", "Items.rxdata"), :process_name_description)
  result.push("}")
  true
end

def process_mapinfos(result, base=".")
  result.push("$mapinfos_lang = {")
  fname = File.join(base, "Data", "MapInfos.rxdata")
  File.open(fname, "rb") do |f|
    hashmap = Marshal.load(f)
    hashmap.sort.to_h.each do |id, instance|
      send(:process_name, result, id, instance)
    end
  end
  $singleton_digest << Digest::SHA256.file(fname).hexdigest
  result.push("}")
  true
end

def process_skills(result, base=".")
  result.push("$skills_lang = {")
  process_name_list(result, File.join(base, "Data", "Skills.rxdata"), :process_name_description)
  result.push("}")
  true
end

def process_states(result, base=".")
  result.push("$states_lang = {")
  process_name_list(result, File.join(base, "Data", "States.rxdata"))
  result.push("}")
  true
end

def process_system(result, base=".")
  fname = File.join(base, "Data", "System.rxdata")
  File.open(fname, "rb") do |f|
    $data_system = sys = Marshal.load(f)
    words = [
      :gold, :hp, :sp, :str, :dex, :agi, :int, :atk, :pdef, :mdef,
      :weapon, :armor1, :armor2, :armor3, :armor4, :attack, :skill, 
      :guard, :item, :equip
    ]
    result.push("$system_words = {")
    words.each do |attr|
      result.push("  :#{attr} => #{convert(sys.words.send(attr))},")
    end
    $singleton_digest << Digest::SHA256.file(fname).hexdigest
    result.push("}")
    result.push("")
    result.push("$system_elements = #{convert(sys.elements)}")
  end
  true
end

def process_tilesets(result, base=".")
  result.push("$tilesets_lang = {")
  process_name_list(result, File.join(base, "Data", "Tilesets.rxdata"))
  result.push("}")
  true
end

def process_troops(result, base=".")
  result.push("$troops_lang = {")
  process_name_list(result, File.join(base, "Data", "Troops.rxdata"))
  result.push("}")
  true
end

def process_weapons(result, base=".")
  result.push("$weapons_lang = {")
  process_name_list(result, File.join(base, "Data", "Weapons.rxdata"), :process_name_description)
  result.push("}")
  true
end

def include_mom(result, mom)
  unless mom.nil?
    begin
      eval(mom)
    rescue
      puts "Failed to load Mom text"
      mom = nil
    end
  end
  result.push("$MOM = {")
  if mom.nil?
    result.push('  0 =>')
    result.push('    "\\\\ignr\\\\nm[]\\\\face[]\\\\fr\\n"\\')
    result.push('    "There is no one to talk to right now.",')
    result.push('  1 =>')
    result.push('    "\\\\ignr\\\\nm[Mom]\\\\face[Mom]\\\\fr\\n"\\')
    result.push('    "Did you notice the envelope on the floor \\n"\\')
    result.push('    "in your room? Maybe someone left \\n"\\')
    result.push('    "you a letter...",')
    result.push('  2 =>')
    result.push('    "\\\\ignr\\\\nm[Mom]\\\\face[Mom]\\\\fr\\n"\\')
    result.push('    "Hmm... that\'s an interesting riddle. \\n"\\')
    result.push('    "What smiles back at you, when you \\n"\\')
    result.push('    "smile at it? I wonder...",')
    result.push('  3 =>')
    result.push('    "\\\\ignr\\\\nm[Mom]\\\\face[Mom]\\\\fr\\n"\\')
    result.push('    "I wonder if there are any secret doors \\n"\\')
    result.push('    "in this hospital that lead to Morizora\'s \\n"\\')
    result.push('    "world! Wouldn\'t that be something!",')
  else
    $MOM.each do |key, value|
      result.push("  #{key} =>" )
      value.split("\n").each do |line|
        result.push("    #{convert(line + "\n")}\\")
      end
      result[-1][-1] = ","
    end
  end
  result.push("}")
  result.push("$MOMHINT = {")
  if mom.nil?
    result.push('  1 =>')
    result.push('    "\\\\ignr\\\\nm[Mom]\\\\face[Mom]\\\\fr\\n"\\')
    result.push('    "I love you!",')
  else
    $MOMHINT.each do |key, value|
      result.push("  #{key} =>" )
      value.split("\n").each do |line|
        result.push("    #{convert(line + "\n")}\\")
      end
      result[-1][-1] = ","
    end
  end
  result.push("}")
end

def include_journal(result, window_journal)
  unless window_journal.nil?
    begin
      eval(window_journal)
      Window_Journal.class_eval do
        def refresh
        end
      end
      journal = Window_Journal.new
    rescue
      puts "Failed to load journal"
    end
  end

  result.push("$journal_lang = [")
  if window_journal.nil?
    result.push('  nil,')
    result.push('  "Find out who stole your book!",')
    result.push('  "Look for a door to Morizora\'s Forest.",')
    result.push('  "Find Morizora in the cave northwest of here.",')
    result.push('  "Help Blacksmith Jacky get his tools back.",')
    result.push('  "Visit Blacksmith Jacky to get an axe.",')
    result.push('  "Gather 5 Camphor Sticks and 3 Nightstones.",')
    result.push('  "Find out how to help Winston.",')
    result.push('  "Get Winston to build a boat to Tony island.",')
    result.push('  "Get 10 pieces of bamboo and Danielle\'s sail.",')
    result.push('  "Give Danielle 3 Wool from Sky Ranch.",')
    result.push('  "Get Tony bear to stop harassing Leebles.",')
    result.push('  "Help Tony find his music box.",')
    result.push('  "Ask Blacksmith Jacky to fix the music box.",')
    result.push('  "Ask Tony to teach you the music box\'s song.",')
    result.push('  "Check Kisaburo\'s room, find Christina.",')
    result.push('  "Gather materials and build wings.",')
    result.push('  "Give Tony the letter.",')
    result.push('  "Help Kisaburo.",')
    result.push('  "Help Kazuko in the Midnight Tea Shop.",')
    result.push('  "Find Puchi and return her to Sue.",')
    result.push('  "Find a Pickaxe to clear fallen rocks.",')
    result.push('  "Get Monsieur Bud to try a tea sample.",')
    result.push('  "Get Dragon Ash from Stormey the Dragon.",')
    result.push('  "Remove the blockage in the water.",')
    result.push('  "Find out what Puchi wants.",')
    result.push('  "Bring Panky 40 Sila Berries.",')
    result.push('  "Bring Cora 5 Reeds and 6 Fireflies.",')
    result.push('  "Visit Leeble Chief when the stars fall.",')
    result.push('  "Bring Sue one of her lost marbles.",')
    result.push('  "Help Leebles prepare for Star Night.",')
    result.push('  "Go to Star Night tonight!",')
    result.push('  "Borrow Hikaribana from Winston.",')
    result.push('  "1.) Find work papers",')
    result.push('  "2.) Start the laundry",')
    result.push('  "3.) Water the plant",')
    result.push('  "4.) Turn on rice cooker",')
    result.push('  500,')
  else
    journal.data.each do |text|
      result.push("  #{convert(text)},")
    end
  end
  result.push("]")
end

def load_scene_overrides(language, scene_overrides)
  unless scene_overrides.nil?
    begin
      scene_overrides.gsub!(/@command_window =/, "if defined? s1\n  $menu = [s1, s2, s3]\n  end\nend\ndef other\n  ")
      scene_overrides.gsub!(/s1 =/, "end\ndef main\n  s1 =")
      eval(scene_overrides)
      # Title Menu
      Scene_Title.new.main
      title_menu = [$menu[0], $menu[1], language, $menu[2]]
      # End Menu
      Scene_End.new.main
      end_menu = $menu
      # Scene Menu
      $menu = {}
      Scene_Menu.class_eval do
        def add_command(command_array, symbol, word)
          $menu[symbol] = word
        end

        def mom_available?
          true
        end

        def cave_map_available?
          true
        end
      end
      Scene_Menu.new.main
      scene_menu = $menu
    rescue
      scene_overrides = nil
      puts "Failed to load Title_Menu"
      puts "Failed to load Scene_Menu"
    end
  end
  title_menu = ["New Story", "Resume", language, "Close the Book"] if scene_overrides.nil?
  end_menu = ["To Title", "Shutdown", "Cancel"] if scene_overrides.nil?
  scene_menu = {
    :item => "Item",
    :journal => "Journal",
    :mom => "Hi Mom!",
    :cave_map => "See Cave Map",
    :save => "Save",
    :end_game => "End Game"
  } if scene_overrides.nil?
  [title_menu, end_menu, scene_menu]
end

def load_scene_save(scene_save)
  unless scene_save.nil?
    begin
      eval(scene_save)
      save_lang = Scene_Save.new.text
    rescue
      scene_save = nil
      puts "Failed to load Scene_Save"
    end
  end
  save_lang = "Which file would you like to save to?" if scene_save.nil?
  save_lang
end

def load_scene_load(scene_load)
  unless scene_load.nil?
    begin
      eval(scene_load)
      load_lang = Scene_Load.new.text
    rescue
      scene_load = nil
      puts "Failed to load Scene_Load"
    end
  end
  load_lang = "Which file would you like to save to?" if scene_load.nil?
  load_lang
end

def load_window_playtime(window_playtime)
  unless window_playtime.nil?
    begin
      window_playtime.gsub!(/< Window_Base/, "")
      window_playtime.gsub!(/self.contents.draw_text\(4, 0, 120, 32,(.*)\)/, "end\ndef ptime\n\\1\nend\ndef initialize\nend\ndef refresh")
      eval(window_playtime)
      playtime = Window_PlayTime.new.ptime
    rescue
      window_playtime = nil
      puts "Failed to load Window_PlayTime"
    end
  end
  playtime = "Play Time" if window_playtime.nil?
  playtime
end

def load_window_autosave(autosave)
  unless autosave.nil?
    begin
      autosave.gsub!(/< Window_Base/, "")
      autosave.gsub!(/self.contents.clear/, "")
      autosave.gsub!(/self.contents.font.color/, "a")
      autosave.gsub!(/self.contents.draw_text\(4, 0, 600, 32, name\)/, "name\nend\ndef other\n")
      eval(autosave)
      Window_SaveFile.class_eval do
        attr_accessor :file_index
        def initialize(index)
          @file_index = index
        end
        def normal_color
          nil
        end
        def disabled_color
          nil
        end
      end
      file_lang = Window_SaveFile.new(998).refresh.sub("999", '%s')
      autosave_lang = Window_SaveFile.new(3).refresh
    rescue => e
   puts "Error during processing: #{$!}"
  puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
      autosave = nil
      puts "Failed to load AutoSave"
    end
  end
  file_lang = "File%s" if autosave.nil?
  autosave_lang = "Auto-Save" if autosave.nil?
  [file_lang, autosave_lang]
end

def include_menu(result, language, scene_save, scene_load, scene_overrides, window_playtime, autosave)
  title_menu, end_menu, scene_menu = load_scene_overrides(language, scene_overrides)
  save_lang = load_scene_save(scene_save)
  load_lang = load_scene_load(scene_load)
  playtime = load_window_playtime(window_playtime)
  file_lang, autosave_lang = load_window_autosave(autosave)

  result.push("# Title")
  result.push("$title_lang = [")
  title_menu.each do |text|
    result.push("  #{convert(text)},")
  end
  result.push("]")

  result.push("")
  result.push("# Menu")
  result.push("$menu_lang = {")
  scene_menu.each do |key, value|
    result.push("  :#{key} => #{convert(value)},")
  end
  result.push("}")

  result.push("")
  result.push("$save_lang = #{convert(save_lang)}")
  result.push("$load_lang = #{convert(load_lang)}")
  result.push("$time_lang = #{convert(playtime)}")
  result.push("$file_lang = #{convert(file_lang)}")
  result.push("$autosave_lang = #{convert(autosave_lang)}")
  result.push("")
  result.push("$end_lang = [")
  end_menu.each do |text|
    result.push("  #{convert(text)},")
  end
  result.push("]")
end

def extract_text(language, original, show_code, dirname, base=".")
  result = []
  original_scripts = nil
  window_journal_script = nil
  mom_script = nil
  scene_save_script = nil
  scene_load_script = nil
  scene_overrides_script = nil
  window_playtime_script = nil
  autosave_script = nil

  begin
    require "zlib"
    unless original.nil?
      original_scripts = {}
      File.open(File.join(original, "Data", "Scripts.rxdata"), "r") do |f|
        oscripts = Marshal.load(f)
        oscripts.each_with_index do |script, index|
          original_scripts[index] = script
        end
      end
    end
    scripts = []

    File.open(File.join(base, "Data", "Scripts.rxdata"), "r") do |f|
      scripts = Marshal.load(f)
      scripts.each do |script|
        if script[1] == "Window_Journal"
          window_journal_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Mom"
          mom_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Scene_Save"
          scene_save_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Scene_Load"
          scene_load_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Scene overrides"
          scene_overrides_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Window_PlayTime"
          window_playtime_script = Zlib::Inflate.inflate(script[2])
        elsif script[1] == "Window_SaveFile***autosave-modified"
          autosave_script = Zlib::Inflate.inflate(script[2])
        end
      end
    end

    unless original.nil?
      require "diff/lcs"
      require 'set'
      require 'differ'
      Differ.format = :color
      original_scripts = {}
      File.open(File.join(original, "Data", "Scripts.rxdata"), "r") do |f|
        oscripts = Marshal.load(f)
        scode = Set.new(scripts) {|x| x[2]}
        ocode = Set.new(oscripts) {|x| x[2]}
        filtered_scripts = Hash[scripts.reject do |script|
          ocode.include? script[2]
        end.collect { |x| [x[1], x] }]
        filtered_oscripts = Hash[oscripts.reject do |script|
          scode.include? script[2]
        end.collect { |x| [x[1], x] }]

        filtered_oscripts.each do |key, oscript|
          if filtered_scripts[key].nil?
            puts "Removed: #{key}!"
            if show_code
              puts Zlib::Inflate.inflate(oscript[2])
            end
          elsif not ["Scene_Save", "Scene_Load", "Mom", "Window_Journal",
                     "Scene overrides", "Window_PlayTime",
                     "Window_SaveFile***autosave-modified", "Scene_Title"].include? key
            puts "Changed: #{key}!"
            if show_code
              puts Differ.diff_by_line(
                Zlib::Inflate.inflate(filtered_scripts[key][2]),
                Zlib::Inflate.inflate(oscript[2])
              )
            end
          end
        end
        filtered_scripts.each do |key, script|
          if filtered_oscripts[key].nil?
            puts "Added: #{key}!"
            if show_code
              puts Zlib::Inflate.inflate(script[2])
            end
          end
        end
      end
    end
  rescue
    puts 'Failed to load Scripts.rxdata'
  end


  result.push("#") # Replace
  result.push("# Language: #{language}")
  result.push("# Authors: Rakuen Team")
  result.push("")
  result.push("# Override font names")
  result.push("$override_fonts_lang = {")
  result.push('#  "5yearsoldfont" => "MS PGothic",')
  result.push("}")
  result.push("")
  result.push("# Override Images. Note that the path here is relative to the language folder")
  result.push("$override_images_lang = {")
  empty = true
  unless original.nil?
    require 'find'
    require 'pathname'
    base_name = Pathname.new base
    Find.find(File.join(base, "Graphics")) do |path|
      unless File.directory? path
        relative = Pathname.new(path).relative_path_from(base_name)
        original_path = File.join(original, relative)
        new_path = File.join(base, relative)
        if File.exists?(original_path) and not FileUtils.identical?(original_path, new_path)
          dir = File.join(dirname, File.dirname(relative))
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
          FileUtils.cp(new_path, File.join(dirname, relative))

          original_name = relative.to_s[0..-(File.extname(relative.to_s).length + 1)]
          result.push("  #{convert(original_name)} => #{convert(relative.to_s)},")
          empty = false
        end
      end
    end
  end
  if empty
    result.push('#  "Graphics/Titles/Rakuen1" => "../Ending Credits 8.png"')
  end
  result.push("}")
  result.push("")
  temp_system = []
  process_system(temp_system, base=base)
  include_menu(
    result, language,
    scene_save_script, scene_load_script, scene_overrides_script,
    window_playtime_script, autosave_script
  )
  result.push("")
  result.push("# Mom")
  include_mom(result, mom_script)
  result.push("")
  result.push("# Journal")
  include_journal(result, window_journal_script)
  result.push("")
  result.push("# Events")
  process_events(result, base=base)

  result.push("")
  result.push("# Actors")
  process_actors(result, base=base)
  result.push("")
  result.push("# Animations")
  process_animations(result, base=base)
  result.push("")
  result.push("# Armors")
  process_armors(result, base=base)
  result.push("")
  result.push("# Classes")
  process_classes(result, base=base)
  result.push("")
  result.push("# Enemies")
  process_enemies(result, base=base)
  result.push("")
  result.push("# Items")
  process_items(result, base=base)
  result.push("")
  result.push("# MapInfos")
  process_mapinfos(result, base=base)
  result.push("")
  result.push("# Skills")
  process_skills(result, base=base)
  result.push("")
  result.push("# States")
  process_states(result, base=base)
  result.push("")
  result.push("# System")
  result.push(*temp_system)
  result.push("")
  result.push("# Tilesets")
  process_tilesets(result, base=base)
  result.push("")
  result.push("# Troops")
  process_troops(result, base=base)
  result.push("")
  result.push("# Weapons")
  process_weapons(result, base=base)
  result
end

if __FILE__ == $0
  $singleton_digest = Digest::SHA256.new
  ARGV[0] = ".." if ARGV.size < 1
  ARGV[1] = "." if ARGV.size < 2
  ARGV[2] = "en" if ARGV.size < 3
  ARGV[3] = "English" if ARGV.size < 4
  ARGV[4] = nil if ARGV.size < 5
  ARGV[5] = false if ARGV.size < 6

  folder, translations, i18n, language, original, show_code = ARGV
  lang_file = File.join(translations, i18n, "lang.rb")
  name_file = File.join(translations, i18n, "name.txt")
  dirname = File.dirname(lang_file)
  FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
  File.open(lang_file, "w") do |f|
    result = extract_text(language, original, show_code, dirname, folder)
    result[0] = "# Version: #{$singleton_digest.hexdigest}"
    f.write(result.join("\n"))
  end
  File.open(name_file, "w") do |f|
    f.write(language)
  end
end

