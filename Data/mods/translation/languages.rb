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


# Overrides RGSS methods to load translation instead of base game messages

if ENV["LOADED_TRANSLATION_LANGUAGES"].nil?
  class Class
    def check_method(method, name, read, access, original_value, new_value)
      lines = []
      lines.push("def #{method}")
      lines.push("  obj = #{read}")
      lines.push("  if obj.nil?")
      lines.push("    $translation_system.debug(\"#{name} not found: #{access}\")")
      lines.push("    result = #{original_value}")
      lines.push("    $translation_system.debug(result)")
      lines.push("  else")
      lines.push("    result = #{new_value}")
      lines.push("  end")
      lines.push("  result")
      lines.push("end")
      self.class_eval(lines.join("\n"))
    end
  end

  class Bitmap
    alias_method :old_initialize, :initialize
  end

  class Font
    alias_method :'old_set_name', :'name='
    alias_method :'old_name', :name
  end

  class Window_Journal
    alias_method :old_initialize, :initialize
  end

  class Window_Command
    alias_method :old_initialize, :initialize
  end

  class RPG::System
    alias_method :old_initialize, :initialize
  end

  class Game_Event
    attr_reader :event, :page
  end

  class Interpreter
    alias_method :old_setup, :setup
    alias_method :old_setup_starting_event, :setup_starting_event
    alias_method :old_command_117, :command_117
    alias_method :old_execute_command, :execute_command

  end
end
ENV["LOADED_TRANSLATION_LANGUAGES"] = "done"

class RPG::Animation
  check_method(:name, "Animation", "$animations_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Armor
  check_method(:name, "Armor", "$armors_lang[@id]", '[#{@id}]', "@name", "obj[0]")
  check_method(:description, "Armor", "$armors_lang[@id]", '[#{@id}]', "@description", "obj[1]")
end

class RPG::Class
  check_method(:name, "Class", "$classes_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Item
  check_method(:name, "Item", "$items_lang[@id]", '[#{@id}]', "@name", "obj[0]")
  check_method(:description, "Item", "$items_lang[@id]", '[#{@id}]', "@description", "obj[1]")
end

class RPG::MapInfo
  check_method(:name, "MapInfo", "$mapinfos_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Skill
  check_method(:name, "Skill", "$skills_lang[@id]", '[#{@id}]', "@name", "obj[0]")
  check_method(:description, "Skill", "$skills_lang[@id]", '[#{@id}]', "@description", "obj[1]")
end

class RPG::State
  check_method(:name, "State", "$states_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Tileset
  check_method(:name, "Tileset", "$tilesets_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Troop
  check_method(:name, "Troop", "$troops_lang[@id]", '[#{@id}]', "@name", "obj")
end

class RPG::Weapon
  check_method(:name, "Weapon", "$weapons_lang[@id]", '[#{@id}]', "@name", "obj[0]")
  check_method(:description, "Weapon", "$weapons_lang[@id]", '[#{@id}]', "@description", "obj[1]")
end

class RPG::System
  def initialize
    old_initialize
    the_words = [
      :gold, :hp, :sp, :str, :dex, :agi, :int, :atk, :pdef, :mdef,
      :weapon, :armor1, :armor2, :armor3, :armor4, :attack, :skill, 
      :guard, :item, :equip
    ]
    the_words.each do |attr|
      item = $system_words[attr]
      if item.nil?
        $translation_system.debug("System Word not found: [#{attr}]")
        result = @words.send(attr)
        $translation_system.debug(result)
      else
        result = item
      end
      @words.send("#{attr}=", result)
    end
    @elements = $system_elements
  end
end

class Game_Actor
  attr_reader :actor_id
  check_method(
    :name, "Actor", "$actors_lang[@actor_id]", '[#{@actor_id}]',
    "$data_actors[@actor_id].name", "obj"
  )
end

class Game_Enemy
  attr_reader :actor_id
  check_method(
    :name, "Enemy", "$enemies_lang[@enemy_id]", '[#{@enemy_id}]',
    "$data_enemies[@enemy_id].name", "obj"
  )
end

class Scene_Menu
  def add_command(command_array, symbol, word)
    result = $menu_lang[symbol]
    if result.nil?
      $translation_system.debug("Menu item not found: [:#{symbol}]")
      result = word
      $translation_system.debug(result)
    end
    @command_map[command_array.size] = symbol
    command_array << result
  end
end

class Scene_File
  def initialize(help_text)
    if help_text == "Which file would you like to save to?"
      @help_text = $save_lang
    elsif help_text == "Which file would you like to load?"
      @help_text = $load_lang
    else
      @help_text = help_text
    end
  end
end

class Scene_Title
  def choose_command(index)
    # Branch by index
    case index
    when 0  # New game
      command_new_game
    when 1  # Continue
      command_continue
    when 2  # Change language
      available = $translation_system.list_lang
      current = available.index $I18N_LANGUAGE
      $translation_system.set_lang available[(current + 1) % available.size]
      $translation_system.reload
      $scene = Scene_Title.new
    when 3  # Shutdown
      command_shutdown
    end
  end

  def update
    # Update command window
    @command_window.update
    # If C button was pressed
    if Input.trigger?(Input::C)
      # Branch by command window cursor position
      choose_command(@command_window.index)
    end
  end
end

class Window_Journal

  def initialize
    super(0, 32, 460, 330)
    @data = $journal_lang
    @data[0] = nil
    @data[37] = 500
    @offset = 500
    @column_max = 1
    refresh
    self.index = 0
  end

  def draw_item(index)
    item = @data[index]
    rect = Rect.new(10, @n, 460, 32)
    self.contents.fill_rect(rect, Color.new(0,0,0,0))    
    self.contents.draw_text(10, @n, 410, 32, "●", 0)
    self.contents.draw_text(25, @n, 410, 32, item, 0)
    @n += 32
  end
end

class Window_Command
  def initialize(width, commands)
    if commands == ["New Story", "Resume", "Close the Book"]
      commands = $title_lang
    elsif commands == ["To Title", "Shutdown", "Cancel"]
      commands = $end_lang
    end
    old_initialize(width, commands)
  end
end

class Window_PlayTime
  def refresh
    self.contents.clear
    self.contents.font.color = system_color
    self.contents.draw_text(4, 0, 120, 32, $time_lang)
    @total_sec = Graphics.frame_count / Graphics.frame_rate
    hour = @total_sec / 60 / 60
    min = @total_sec / 60 % 60
    sec = @total_sec % 60
    text = sprintf("%02d:%02d:%02d", hour, min, sec)
    self.contents.font.color = normal_color
    self.contents.draw_text(4, 32, 120, 32, text, 2)
  end
end

class Window_SaveFile
  def refresh
    self.contents.clear
    # Draw file number
    self.contents.font.color = normal_color
    
    if (@file_index != 3)
      name = $file_lang % [@file_index + 1]
    else
      name = $autosave_lang
    end
    
    self.contents.draw_text(4, 0, 600, 32, name)
    @name_width = contents.text_size(name).width
    # If save file exists
    if @file_exist
      # Draw character
      for i in 0...@characters.size
        bitmap = RPG::Cache.character(@characters[i][0], @characters[i][1])
        cw = bitmap.rect.width / 4
        ch = bitmap.rect.height / 4
        src_rect = Rect.new(0, 0, cw, ch)
        x = 300 - @characters.size * 32 + i * 64 - cw / 2
        self.contents.blt(x, 68 - ch, bitmap, src_rect)
      end
      # Draw play time
      hour = @total_sec / 60 / 60
      min = @total_sec / 60 % 60
      sec = @total_sec % 60
      time_string = sprintf("%02d:%02d:%02d", hour, min, sec)
      self.contents.font.color = normal_color
      self.contents.draw_text(4, 8, 600, 32, time_string, 2)
      # Draw timestamp
      self.contents.font.color = normal_color
      time_string = @time_stamp.strftime("%Y/%m/%d %H:%M")
      self.contents.draw_text(4, 40, 600, 32, time_string, 2)
    end
  end
end

class Bitmap
  def initialize(*args)
    if args.size == 1
      result = args[0]
      if args[0] == "Graphics/Pictures/Ending Credits 8"
        result = "#{$translation_system.data_path}/Ending Credits 8"
      end
      override = $override_images_lang[args[0]]
      unless override.nil?
        result = "#{$translation_system.data_lang_path}/#{override}"
      end
      args[0] = result
    end
    old_initialize(*args)
    
  end
end

class Font

  def name
    value = old_name
    override = $override_fonts_lang[value]
    unless override.nil?
      value = override
    end
    value
  end

  def name=(value)
    result = value
    override = $override_fonts_lang[value]
    unless override.nil?
      result = override
    end
    old_set_name(result)
  end
end

class Interpreter

  def execute_command
    if !(@list[@index].code == 102 and $game_temp.skip_next_choices > 0)
      @parameters = @list[@index].parameters.clone
      if @list[@index].code == 402
        @parameters[0] += @offset
      end
    end
    old_execute_command
  end


  def setup_starting_event
    $translate_common = $game_temp.common_event_id
    old_setup_starting_event
  end

  def command_117
    $translate_common = @parameters[0]
    return old_command_117
  end

  def access_event_text(map, event, index, text)
    if event == 0
      map = 0
      event = $translate_common
      page = 0
    else
      event_object = $game_map.events[event]
      page = event_object.event.pages.index event_object.page
    end

    new_text = $events_lang.fetch(map, {}).fetch(event, {}).fetch(page, {})[index]
    if new_text.nil?
      if $DEBUG
        $translation_system.debug("Event Message not found: [#{map}][#{event}][#{page}][#{index}]")
        $translation_system.debug(text.inspect)
      end
      new_text = text
    end
    new_text
  end

  def setup(list, event_id)
    old_setup(list, event_id)
    @list = []

    index = 0
    bar = "-" * 42 + "\n"
    loop do
      break if index >= list.size
      command = list[index]
      last_index = index
      index += 1
      if command.code == 101
        message_text = command.parameters[0] + "\n"
        loop do
          break if index >= list.size
          command = list[index]
          if command.code == 101
            message_text += bar
            message_text += command.parameters[0] + "\n"
          elsif command.code == 401
            message_text += command.parameters[0] + "\n"
          else
            break
          end
          index += 1
        end
        message_text = access_event_text(
          @map_id, @event_id, last_index, message_text
        )
        message_text.split(bar).each do |message|
          lines = message.split("\n")
          @list.push(RPG::EventCommand.new(101, command.indent, [lines[0]]))
          (lines[1..-1] || []).each do |line|
            @list.push(RPG::EventCommand.new(401, command.indent, [line]))
          end
          @list.pop() if @list[-1].parameters[0].empty?
        end
      elsif command.code == 102
        command.parameters = access_event_text(
          @map_id, @event_id, last_index, command.parameters
        )

        i = index
        par_i = 0
        loop do
          break if i >= list.size
          new_command = list[i]
          break if new_command.indent < command.indent
          if new_command.code == 402 and new_command.indent == command.indent
            new_command.parameters = [par_i, command.parameters[0][par_i]]
            par_i += 1
          elsif new_command.indent == command.indent
            break
          end
          i += 1
        end
        @list.push(command)
      else
        @list.push(command)
      end
    end
  end
end

$translation_system.load_lang
