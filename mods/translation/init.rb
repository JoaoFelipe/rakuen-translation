# The MIT License (MIT)
#
# Copyright (c) 2018 Joao Pimentel <joaofelipenp at gmail dot com>
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


# This file defines and loads the translation system

class Translation_System

  def path
    "#{$EXE_PATH}/mods/translation"
  end

  def lang_path
    "#{path}/#{$I18N_LANGUAGE}"
  end

  def load_scripts
    #load("#{path}/debug.rb")
    load("#{path}/languages.rb")
    load("#{path}/selection.rb")
  end

  def reload
    deactivate_translation
    load_scripts
    activate_translation
  end

  def get_lang
    result = "en"
    begin
      File.open("#{path}/Translation.cfg", "r") do |f|
        result = f.read()
      end
      raise "No Lang" unless File.exists? "#{path}/#{result}/lang.rb"
    rescue
      result = "en"
    end
    $I18N_LANGUAGE = result
    result
  end

  def set_lang(lang)
    $I18N_LANGUAGE = lang
    begin
      File.open("#{path}/Translation.cfg", "w") do |f|
        f.write($I18N_LANGUAGE)
      end
    rescue

    end
  end

  def list_lang
    Dir["#{path}/*"].select{|f|
      (File.directory? f) && (File.exists? "#{f}/lang.rb")
    }.map{|f| File.basename f}.sort
  end

  def lang_name(lang)
    fname = "#{path}/#{lang}/name.txt"
    begin
      file = File.open(fname, "rb")
      lname = file.read
    rescue
      lname = code
    end
    lname
  end

  def load_font(lang)
    $override_fonts_lang = {
    }
    $defaultfonttype = "5yearsoldfont"
    Font.default_name = $defaultfonttype

    if File.exists? "#{path}/#{lang}/font.rb"
      load("#{path}/#{lang}/font.rb")
    end
  end

  def load_lang
    $animations_lang = {}
    $armors_lang = {}
    $classes_lang = {}
    $items_lang = {}
    $mapinfos_lang = {}
    $skills_lang = {}
    $states_lang = {}
    $tilesets_lang = {}
    $troops_lang = {}
    $weapons_lang = {}
    $actors_lang = {}
    $enemies_lang = {}
    $menu_lang = {}
    $override_images_lang = {}
    $override_fonts_lang = {}
    $events_lang = {}
    $system_words = {}
    $system_elements = []
    $save_lang = "Which file would you like to save to?"
    $load_lang = "Which file would you like to load?"
    $time_lang = "Play Time"
    $file_lang = "File%s"
    $autosave_lang = "Auto-Save"
    $journal_lang = []
    $title_lang = ["New Story", "Resume", "Language", "Close the Book"]
    $end_lang = ["To Title", "Shutdown", "Cancel"]
    debug(lang_path)
    load_font $I18N_LANGUAGE
    load("#{lang_path}/lang.rb")
    activate_translation
  end

  def activate_translation
    # Override in translation
  end

  def deactivate_translation
    # Override in translation
  end

  def debug(msg)

  end
end

$translation_system = Translation_System.new

if ENV["LOADED_TRANSLATION_MOD"].nil?
  $translation_system.get_lang
end
$translation_system.load_scripts
ENV["LOADED_TRANSLATION_MOD"] = "done"
