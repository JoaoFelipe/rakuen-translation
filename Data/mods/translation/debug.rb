$DEBUG = true  # Enables/Disables debugging console
$SAVE_MAP = true # Saves every map


if ENV["LOADED_RAKUEN_DEBUG"].nil?
  class Scene_Map
    alias_method :old_update, :update
  end
  class Game_Map
    alias_method :old_setup, :setup
  end
end

MAPSAVE = "#{$translation_system.path}/mapsave"
class Translation_System
  def debug(msg)
    puts msg
  end
end

if ($DEBUG || $TEST) and (ENV["LOADED_RAKUEN_DEBUG"].nil?)
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

  Dir.mkdir(MAPSAVE) unless File.exists? MAPSAVE

  # Draw the header, displaying current time.
  $translation_system.debug("#{'=' * 75}\n#{Time.now}\n#{'=' * 75}\n")
  # ...

end
ENV["LOADED_RAKUEN_DEBUG"] = "done"


class Game_Map
  def setup(map_id)
    # Only reload translation on debug mode
    $translation_system.debug("Map #{map_id}")

    $translation_system.deactivate_translation
    $mod_system.reload
    result = old_setup(map_id)
    curid = 1

    begin
      begin
        fname = "#{MAPSAVE}/map#{map_id}-#{curid}.rxdata"
        curid += 1
      end while FileTest.exist?(fname)
      file = File.open(fname, "wb")
      $rakuen.write_save_data(file)
      Marshal.dump($ams, file)
      file.close
    rescue
      $translation_system.debug("Failed to save #{map_id}")
    end
    result
  end
end

def validate_msg(map, event, page, position, text)
  width = $game_system.window_width
  height = $game_system.window_height
  face = nil
  name = nil
  contents = Bitmap.new(width - 32, height - 32)
  contents.font.name = $game_system.font
  $game_system.shortcuts.each { |shortcut, code|
    $translation_system.debug shortcut
    text.gsub!(shortcut, code)
  }
  text.gsub!(/\\[Ss][Ll][Vv]\[(.*?)\]/, "")
  text.gsub!(/\\[Ii][Nn][Dd]\[(.*?)\]/, "")
  begin
    last_text = text.clone
    text.gsub!(/\\[Vv]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
  end until text == last_text
  text.gsub!(/\\[Nn]\[([0-9]+)\]/) do
    $game_actors[$1.to_i] != nil ? $game_actors[$1.to_i].name : ""
  end
  if text.index(/\\[Mm]/) != nil
    if $game_system.ums_mode == NORMAL_MODE
      $game_system.ums_mode = FIT_WINDOW_TO_TEXT
    else
      $game_system.ums_mode = NORMAL_MODE
    end
    text.gsub!(/\\[Mm]/) { "" }
  end
  text.gsub!(/\\[Hh][Ee][Ii][Gg][Hh][Tt]\[([0-9]+)\]/) do
    height = $1.to_i
    ""
  end
  text.gsub!(/\\[Ww][Ii][Dd][Tt][Hh]\[([0-9]+)\]/) do
    $width = $1.to_i
    ""
  end
  text.gsub!(/\\[Jj][Rr]/) do
    #$game_system.window_justification = RIGHT
    #reset_window
    ""
  end
  text.gsub!(/\\[Jj][Cc]/) do
    #$game_system.window_justification = CENTER
    #reset_window
    ""
  end
  text.gsub!(/\\[Jj][Ll]/) do
    #$game_system.window_justification = LEFT
    #reset_window
    ""
  end
  text.gsub!(/\\[Ff][Aa][Cc][Ee]\[(.*?)\]/) do
    face = $1.to_s
    ""
  end
  text.gsub!(/\\[Ff][Ll]/, "")
  text.gsub!(/\\[Ff][Rr]/, "")
  text.gsub!(/\\[Ee]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Tt][Aa]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Tt]1/, "")
  text.gsub!(/\\[Tt]2/, "")
  text.gsub!(/\\[Tt][Hh]/, "")
  text.gsub!(/\\[Nn][Mm]\[(.*?)\]/) do
    name = $1.to_s
    ""
  end
  text.gsub!(/\\[Nn][Pp]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Pp][Tt]/, "")
  text.gsub!(/\\[Ss][Kk]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Ss][Hh][Kk]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Bb][Oo][Pp][Cc]\[([0-9]+)\]/, "")
  text.gsub!(/\\[Oo][Pp][Cc]\[([0-9]+)\]/, "")

  # Change "\\\\" to "\000" for convenience
  text.gsub!(/\\\\/) { "\000" }
  # Change "\\C" to "\001" and "\\G" to "\002"
  text.gsub!(/\\[Cc]\[([0-9]+)\]/) { "\001[#{$1}]" }
  text.gsub!(/\\[Gg]/) { "\002" }
  text.gsub!(/\\[Cc]\[0x([0123456789abcdef]+)\]/) { "\026[#{$1}]" }
  
  # text skip code
  text.gsub!(/\\[Ss][Kk][Ii][Pp]/) { "\003" }
  
  # ignore code
  text.gsub!(/\\[Ii][Gg][Nn][Rr]/) { "\023" }
  
  # slave and indy windows
  text.gsub!(/\\[Ss][Ll][Vv]\[(.*?)\]/) { "\024[#{$1}]" }
  text.gsub!(/\\[Ii][Nn][Dd]\[(.*?)\]/) { "\025[#{$1}]" }
  
  # bold and italics
  text.gsub!(/\\[Bb]/) { "\004" }
  text.gsub!(/\\[Ii]/) { "\005" }
  
  # shadow
  text.gsub!(/\\[Ss]/) { "\006" }
  
  # font
  text.gsub!(/\\[Ff][Oo][Nn][Tt]\[(.*?)\]/) { "\007[#{$1}]" }
  
  # pause and wait
  text.gsub!(/\\[Pp]\[([0-9]+)\]/) { "\010[#{$1}]" }
  text.gsub!(/\\[Ww]\[([0-9]+)\]/) { "\011[#{$1}]" }
  
  # write speed
  text.gsub!(/\\[Ww][Ss]\[([0-9]+)\]/) { "\013[#{$1}]" }
        
  # armor, items, skills, and weapons
  text.gsub!(/\\[Oo][Aa]\[([0-9]+)\]/) { 
    item = $data_armors[$1.to_i]
    "\014[#{$1}]" + "  " + item.name
  }
  text.gsub!(/\\[Oo][Ii]\[([0-9]+)\]/) { 
    item = $data_items[$1.to_i]
    "\015[#{$1}]" + "  " + item.name
  }
  text.gsub!(/\\[Oo][Ss]\[([0-9]+)\]/) { 
    item = $data_skills[$1.to_i]
    "\016[#{$1}]" + "  " + item.name
  }
  text.gsub!(/\\[Oo][Ww]\[([0-9]+)\]/) { 
    item = $data_weapons[$1.to_i]
    "\017[#{$1}]" + "  " + item.name
  }
  text.gsub!(/\\[Ii][Cc]\[(.*?)\]/) { 
    "\027[#{$1}]"
  }
  
  # text window_justification
  text.gsub!(/\\[Tt][Cc]/) { "\020" }
  text.gsub!(/\\[Tt][Ll]/) { "\021" }
  text.gsub!(/\\[Tt][Rr]/) { "\022" }

  w = 1
  h = 0
  tex = text.split("\n")
  i = 1
  for line in tex
    if !line.include?("\023")
      w = [w, contents.text_size(line).width].max
      delta = contents.text_size(line).height
      h += delta + (delta * 0.2).to_i
    end
  end

  if not (w <= width && h <= height)
    $translation_system.debug("(#{w}, #{h}) (#{map},#{event},#{page},#{position}) #{text}")
  end
end

def check_maps(maps)
  
  bar = "-" * 42 + "\n"

  maps.each do |map|
    $translation_system.debug("Validating #{map}")
    events = $events_lang.fetch(map, {})
    events.each do |event, pages|
      pages.each do |page, positions|
        positions.each do |position, msg|
          if msg.class == Array
            msg[0].each do |text|
              validate_msg(map, event, page, position, text)
            end
          else
            msg.split(bar).each do |dialog|
              validate_msg(map, event, page, position, dialog)
            end
          end
        end
      end
    end
  end
end

class Scene_TranslationDebug
  include Mouse_Windows
  attr_sec_reader :mouse_windows, '[]'

  def main
    # Make sprite set
    @spriteset = Spriteset_Map.new
    
    # Make command window
    @command_window = Window_Command.new(270, [
      "Reload",
      "Toggle run",
      "All items (breaks game)",
      "All journal (breaks game)",
      "Map 0..25",
      "Map 26..50",
      "Map 51..100",
      "Map 101..150",
      "Map 151..200",
      "Map 201..250",
      "Map 251..300",
      "Map 301..350",
      "Map 351..417",
    ])

    @command_window.index = 0
    @command_window.x = 320 - (@command_window.width / 2)
    @command_window.y = 240 - (@command_window.height / 2)
    # <Z> Add as a mouse enabled window
    #mouse_windows << @command_window
    #@command_window.owner = self    # </Z>

    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # <Z> Mouse update
      #mouse_update
      # </Z>
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of sprite set
    @spriteset.dispose    
    # <Z> Mouse update
    #mouse_update
    # </Z>
    # Dispose of windows
    @command_window.dispose
  end

  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    # Update windows
    @command_window.update
    # If command window is active: call update_command
    if @command_window.active
      update_command
      return
    end
  end

  #--------------------------------------------------------------------------
  # * Frame Update (when command window is active)
  #--------------------------------------------------------------------------
  def update_command
    # If B button was pressed
    if Input.trigger?(Input::B) || Mouse.trigger?(Mouse::RIGHT_CLICK)
      # Play cancel SE
      $game_system.se_play($data_system.cancel_se)
      # Switch to map screen
      $scene = Scene_Map.new
      return
    end
    # If C button was pressed
    if Input.trigger?(Input::C)
      # Branch by command window cursor position
      choose_command(@command_window.index)
      return
    end
  end

  def fireEvent(event)
    choose_command(event.info)
  end

  def choose_command(index)
    $game_system.se_play($data_system.decision_se)
    check_id = 4
    case index
    when 0
      $translation_system.debug("Reloading")
      $mod_system.reload
      $scene = Scene_Map.new
    when 1
      if $game_player.move_speed == 3.5
        $game_player.move_speed = 5
      else
        $game_player.move_speed = 3.5
      end
      $scene = Scene_Map.new
    when 2
      $items_lang.each do |key, item|
        unless item[0].nil? || item[0].empty? || item[0].match(/^----/)
          gitem = $data_items[key]
          begin
            RPG::Cache.icon(gitem.icon_name)
            $game_party.gain_item(key, 1)
          rescue
          end
        end
      end
      $scene = Scene_Map.new
    when 3
      for i in 501...537
        $game_switches[i] = true
      end
      $scene = Scene_Map.new
    when check_id + 0
      check_maps(0..25)
    when check_id + 1
      check_maps(26..50)
    when check_id + 2
      check_maps(51..100)
    when check_id + 3
      check_maps(101..150)
    when check_id + 4
      check_maps(151..200)
    when check_id + 5
      check_maps(201..250)
    when check_id + 6
      check_maps(251..300)
    when check_id + 7
      check_maps(301..350)
    when check_id + 8
      check_maps(351..417)
    end

  end
end



class Scene_Map

  def update
    if Input.press?(Input::F5)
      $scene = Scene_TranslationDebug.new
    end
    if Input.press?(Input::F6)
      $game_system.me_play(nil)
      $game_system.me_play(RPG::AudioFile.new "Laura Shigihara - Jump.ogg")
    end
    if Input.press?(Input::F7)
      puts "Sync"
    end
    old_update
  end
end