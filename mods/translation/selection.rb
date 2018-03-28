#==============================================================================
# ** Window_Translation
#------------------------------------------------------------------------------
#  This class presents translation items
#==============================================================================
class Window_Translation < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     width    : window width
  #     commands : command text string array
  #--------------------------------------------------------------------------
  def initialize(commands)
    # Compute window height from command quantity
    super(0, 32, 460, 330)
    @data = [nil] + commands
    @column_max = 1
    refresh
    self.index = 0
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    if self.contents != nil
      self.contents.dispose
      self.contents = nil
    end

    # variables
    @journal_height = (@data.size - 1)*32   # y coord of entire journal (# of entries - 1) * 32
    @n = 0                    # y coord for each entry
    @item_max = 0              # max items to display

    # draw the bitmap. the text will appear on this bitmap
    self.contents = Bitmap.new(width - 32, @journal_height)
    for i in 1...@data.size
      draw_item(i)
      @item_max += 1
    end

    $translation_system.load_font $I18N_LANGUAGE

  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #     index : item number
  #     color : text color
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    $translation_system.load_font item[0]
    self.contents.font.name = $override_fonts_lang.fetch("5yearsoldfont", "5yearsoldfont")
    rect = Rect.new(10, @n, 460, 32)
    self.contents.fill_rect(rect, Color.new(0,0,0,0))
    self.contents.draw_text(10, @n, 460, 32, item[1], 0)
    @n += 32
 end
end


#==============================================================================
# ** Scene_TranslationMenu
#------------------------------------------------------------------------------
#  This class performs translation screen processing.
#==============================================================================
class Scene_TranslationMenu
  include Mouse_Windows
  attr_sec_reader :mouse_windows, '[]'

  #--------------------------------------------------------------------------
  # * Main Processing
  #--------------------------------------------------------------------------
  def main
    # Make sprite set
    # Make title graphic
    @sprite = Sprite.new
    @sprite.bitmap = Bitmap.new("#{$translation_system.path}/Rakuen.png")
    # Make command window
    @available = $translation_system.list_lang
    @language = []
    @available.each do |code|
      @language.push [code, $translation_system.lang_name(code)]
    end
    @command_window = Window_Translation.new(@language)
    @command_window.index = @available.index($I18N_LANGUAGE)
    @command_window.back_opacity = 0
    @command_window.x = 320 - (@command_window.width / 2)
    @command_window.y = 240 - (@command_window.height / 2)
    # <Z> Add as a mouse enabled window
    mouse_windows << @command_window
    @command_window.owner = self    # </Z>

    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # <Z> Mouse update
      mouse_update
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
    # Dispose of windows
    @command_window.dispose
    # Dispose of title graphic
    @sprite.bitmap.dispose
    @sprite.dispose
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
      $scene = Scene_Title.new
      return
    end
    # If C button was pressed
    if Input.trigger?(Input::C)
      # Branch by command window cursor position
      choose_command(@command_window.index)
      $game_system.se_play($data_system.decision_se)

      $scene = Scene_Title.new
      return
    end
  end

  def fireEvent(event)
    choose_command(event.info)
  end

  def choose_command(index)
    $translation_system.set_lang @available[index]
    $translation_system.reload
    $game_system.se_play($data_system.decision_se)
    $scene = Scene_Title.new
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
      $scene = Scene_TranslationMenu.new
    when 3  # Shutdown
      command_shutdown
    end
  end
end