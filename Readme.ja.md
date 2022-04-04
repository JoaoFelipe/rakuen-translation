# Rakuen日本語化パッチ

これは[翻訳MOD](https://github.com/JoaoFelipe/rakuen-translation)を用いて[Rakuen](https://store.steampowered.com/app/559210/Rakuen/)を日本語化するパッチです。

## インストール方法

1. 次のURLからパッチをダウンロードする: https://github.com/izayoi256/rakuen-translation/archive/ja.zip
2. パッチファイルを解凍して、`rakuen-translation-ja`の中身をRakuenのインストール先に上書きする (デフォルトは`C:\Program Files (x86)\Steam\steamapps\common\Rakuen` )
3. `translation_patch.exe` を実行する

これで完了です。ゲームを起動するとタイトル画面に言語メニューが追加されているので、日本語を選択してください。

## 文字化け回避

日本語化した以降に起動するとタイトル画面の文字が `□` に文字化けします。その場合は言語メニューから日本語を再度選択してください。
(ベースとなった翻訳MODの仕様なので修正ができません)

## トラブルシューティング

### Linuxユーザーの場合

翻訳MODの記載

> mkxpエンジンによるテストも正常に通っているのでプレイ可能です。
> 
> インストール手順でtranslation_patch.exeではなくtranslation_patch.elfを実行してください。

### Macユーザーの場合

翻訳MODの記載

> マシンを持っていないためテストができていません。Macもmkxpエンジンを利用しているため、恐らくプレイ可能だと思います。 (詳しくはLinuxユーザーの場合の回答を参照)
> 
> ですが、翻訳パッチをインストールするにはtools/translation_patch.cをビルドしてコンパイルする必要があります。
> 
> (もしMacをお持ちでしたら、コンパイル済みバージョンのプルリクエストを是非送ってください)
