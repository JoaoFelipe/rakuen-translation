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


# This file overrides rgss functions to load translations for Rakuen
# You must add
# load "#{Dir.getwd}/translations/languages.rb"
# on top of Data/Scripts.rxdata/Main

$DEBUG = false  # Enables/Disables debugging console


if ENV["LOADED_RAKUEN"].nil?
  File.open("#{Dir.getwd}/translations/Translation.cfg", "r") do |f|
    $I18N_LANGUAGE = f.read()
  end
  class Class
    def check_method(method, name, read, access, original_value, new_value)
      lines = []
      lines.push("def #{method}")
      lines.push("  obj = #{read}")
      lines.push("  if obj.nil?")
      lines.push("    puts \"#{name} not found: #{access}\"")
      lines.push("    result = #{original_value}")
      lines.push("    puts result")
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
    alias_method :'old_name', :'name='
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
  end
end


if ($DEBUG || $TEST) and (ENV["LOADED_RAKUEN"].nil?)
  # Create a console object and redirect standard output to it.
  Win32API.new('kernel32', 'AllocConsole', 'V', 'L').call
  $stdout.reopen('CONOUT$')
  # Find the game title.
  ini = Win32API.new('kernel32', 'GetPrivateProfileString','PPPPLP', 'L')
  title = "\0" * 256
  ini.call('Game', 'Title', '', title, 256, '.\\Game.ini')
  title.delete!("\0")
  # Set the game window as the top-most window.
  hwnd = Win32API.new('user32', 'FindWindowA', 'PP', 'L').call('RGSS Player', title)  
  Win32API.new('user32', 'SetForegroundWindow', 'L', 'L').call(hwnd)
  # Set the title of the console debug window'
  Win32API.new('kernel32','SetConsoleTitleA','P','S').call("#{title} :  Debug Console")
  # Draw the header, displaying current time.
  puts ('=' * 75, Time.now, '=' * 75, "\n")
  # ...

  class Game_Map
    alias_method :old_setup, :setup

    def setup(map_id)
      # Only reload translation on debug mode
      load("#{Dir.getwd}/translations/languages.rb")
      old_setup(map_id)
    end
  end
end
ENV["LOADED_RAKUEN"] = "done"


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
        puts "System Word not found: [#{attr}]"
        result = @words.send(attr)
        puts result
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
      puts "Menu item not found: [:#{symbol}]"
      result = word
      puts result
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
      available = Dir["#{Dir.getwd}/translations/*"].select{|f| File.directory? f}.map{|f| File.basename f}.sort
      current = available.index $I18N_LANGUAGE
      $I18N_LANGUAGE = available[(current + 1) % available.size]
      File.open("#{Dir.getwd}/translations/Translation.cfg", "w") do |f|
        f.write($I18N_LANGUAGE)
      end
      load("#{Dir.getwd}/translations/languages.rb")
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
    old_initialize
    @data = $journal_lang
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
        result = "#{Dir.getwd}/translations/Ending Credits 8.png"
      end
      override = $override_images_lang[args[0]]
      unless override.nil?
        result = "#{Dir.getwd}/translations/#{$I18N_LANGUAGE}/#{override}"
      end
      args[0] = result
    end
    old_initialize(*args)
    
  end
end

class Font
  def name=(value)
    result = value
    override = $override_fonts_lang[value]
    unless override.nil?        
      result = override
    end
    old_name(result)
  end
end

class Interpreter
  def access_event_text(map, event, index, text)
    if event == 0
      map = 0
      event = $game_temp.common_event_id
      page = 0
    else
      event_object = $game_map.events[event]
      page = event_object.event.pages.index event_object.page
    end

    new_text = $events_lang.fetch(map, {}).fetch(event, {}).fetch(page, {})[index]
    if new_text.nil? && $DEBUG
      puts "Event Message not found: [#{map}][#{event}][#{page}][#{index}]"
      puts text.inspect
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

          
          if new_command.code == 402 and new_command.indent == index
            new_command.parameters = [command.parameters[0][par_i]]
            par_i += 1
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

load("#{Dir.getwd}/translations/#{$I18N_LANGUAGE}/lang.rb")
