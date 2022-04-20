# Rakuen Translation System

This patch adds a mod system to [Rakuen](https://store.steampowered.com/app/559210/Rakuen/) with a translation mod and a lyrics mod. It currently supports the following languages:

- English
- SpanishP
- Italian
- Korean
- Portuguese
- Chinese


## Default Installation

1. Download patch: https://github.com/JoaoFelipe/rakuen-translation/archive/master.zip
2. Extract the **content** of `rakuen-translation-master` into your rakuen directory (`C:\Program Files (x86)\Steam\steamapps\common\Rakuen`, by default)
3. Run `translation_patch.exe`

Done. If you run the game now, you will be able to choose the language by selecting the third option in the main menu.

## Comparison to DreaMaker translations

[DreaMaker](https://rpgmaker.net/forums/topics/2988/) is a tool that assists in the translation of RPG Maker games. It extracts all map texts into a text file and allow translators to edit these files and repack them into binary rxdata files. For this reason, a DreaMaker translation patchs contains not only translated text, but also all sorts of game content. As consequence, a game patch does not reflect on the DreaMaker translation. Moreover, a game can only have a single translation at a given time, and a translation cannot be easily reloaded during playtime.

On the other hand, our translation system is specifict to Rakuen and loads the translated text from lang.rb files during the game execution. These files contain only translation content. Hence, our patches are smaller. Additionally, since we do not change the base game content, we can have multiple translations, alternate among them and reload them on demand. Finally, if the game gets updated to fix a bug or add a new feature, most dialogues (if not all) will keep working without any changes on the translation.

The drawback of loading the translation from script files during the game execution is that it may impose performance penalties. However, it was not observed in our tests.

## Troubleshooting

### I have a decrypted Engine.rgssad and I would like to install the translation.

If you do not mind replacing your `Scripts.rxdata`, you can just unpack the content of `rakuen-translation-master` into your rakuen directory and everything will work. You do not need to run `translation_patch.exe`

If you do not want to replace the changes you already made on `Scripts.rxdata`, you can extract all the other files, and add the following line to the top of the `Main` script, inside RPG Maker:
```ruby
load "#{Dir.getwd}/mods.rb"
```

### I use linux.

We tested the translation system with `mkxp` engine and it works as well. The only difference in the installation step is that you have to run `translation_patch.elf` instead of `translation_patch.exe`

### I use mac.

Since we do not have a mac, we were unable to test the translation system in a mac. Since it also uses the `mkxp` engine, it will probably work (see the linux answer).

However, to install the translation, it will be necessary to compile `tools\translantion_patch.c` and execute it.

(If you have a mac, feel free to send a pull request with the compiled version)

### I would like to disable the lyrics mod

The mod loader (`mods.rb`) scans for all mods folder in `Data\mods` that have a `init.rb` file. You can either rename `Data\mods\lyrics\init.rb` to something else or delete the entire `Data\mods\lyrics` folder.


## Traslating

### Creating translations

To create a new translation, just copy the "en" folder and create a new one for your language.

Please, do not change the version hash on the top of your `lang.rb`. This hash allows you to check if your translation corresponds to the current game version.

For debugging your translation, I suggest uncommenting the following line from `Data/mods/translation/init.rb`:
```ruby
load("#{path}/debug.rb")
```
Avoid clicking on the middle of the console screen, as it can crash the game.

### Debugging translations

The translation mod has a debug system that adds the following features:

- Auto reload translation on map changes
- Console that shows the map number and untranslated text (Caution: Selecting text from the console crashes the game)
- F5 key opens translation menu with options to reload translation, "run" (increases framerate), put all existing itens in the inventory, put all journal text in the journal, and test all message widths.

To activate the debug system, uncomment it from `Data/mods/translation/init.rb`:
```ruby
43| def load_scripts
44|     load("#{path}/debug.rb")  #<-- uncomment this line
45|     load("#{path}/languages.rb")
46|     load("#{path}/selection.rb")
47| end
```

### Updating translations

For extracting new english translations from updated Engine.rgssad files, you first need to decrypt the new file. To do so, open your Rakuen directory in a command line and run:
```
translation_patch.exe dec Engine.rgssad dec
```
It will create a `dec` directory with the decrypted file.

Then, you will need to [install ruby](https://rubyinstaller.org/) and run:
```
cd tools
ruby extractor.rb ../dec ../dec
```
The new lang.rb file will on `Rakuen\\dec\\en\\lang.rb`.

Unfortunataly, there is no way to update your translation automatically, by now. Thus, you will have to diff the new `en\\lang.rb` with the original `en\\lang.rb` that you based your translation on, and apply the changes manually in your version:
```
diff ../dec/en/lang.rb ../Data/mods/translation/en/lang.rb
```

### Collaborative translation

It is possible to convert the lang.rb into csv files that can by shared at google drive by running
```
python3 lang_to_csv.py Data/mods/translation/<lang>/lang.rb csvfolder -o translations/en/lang.rb
```

After working on the translation, it is possible to convert back to lang.rb by running
```
python3 csv_to_lang.py csvfolder Data/mods/translation/<lang>/lang.rb
```
