# Rakuen Translation System

This patch adds a translation menu to Rakuen and loads custom translations from a directory.

## Applying the patch

### Default - I still have an Engine.rgssad on my Rakuen folder

Just put these files on your Rakuen directory and execute:
```
translation_patch.exe
```
This file will patch Engine.rgssad to include an updated Scripts.rxdata that loads the translation system.

### Without encryptation - I decrypted my Engine.rgssadd

#### I don't mind replacing my Scripts.rxdata

If you have already decrypted your Scripts.rxdata, just put these files on your Rakuen directory, and replace yours Scripts.rxdata.

#### I don't want to lose my Scripts.rxdata

In this case, put the `translation` folder in you Rakuen directory, and add the following line to the top of the `Main` script, inside RPG Maker:
```ruby
load "#{Dir.getwd}/translations/languages.rb"
```

## Creating translations

To create a new translation, just copy the "en" folder and create a new one for your language.

Please, do not change the version hash on the top of your `lang.rb`. This hash allows you to check if your translation corresponds to the current game version.

For debugging your translation, I suggest setting:
```ruby
$DEBUG = true
```
On your `languages.rb`, but avoid clicking on the middle of the console screen, as it can crash the game.

## Updating translations

For extracting new english translations from updated Engine.rgssad files, you first need to decrypt the new file. To do so, open your Rakuen directory in a command line and run:
```
translation_patch.exe dec Engine.rgssad dec
```
It will create a `dec` directory with the decrypted file.

Then, you will need to [install ruby](https://rubyinstaller.org/) and run:
```
cd translations
ruby extractor ../dec ../dec
```
The new lang.rb file will on `Rakuen\\dec\\en\\lang.rb`.

Unfortunataly, there is no way to update your translation automatically, by now. Thus, you will have to diff the new `en\\lang.rb` with the original `en\\lang.rb` that you based your translation on, and apply the changes manually in your version:
```
diff ../dec/en/lang.rb en/lang.rb
```

