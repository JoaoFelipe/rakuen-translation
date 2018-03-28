if ENV["LOADED_LYRICS"].nil?
  class Game_Screen
    alias_method :old_update, :update
  end
  class Game_System
    alias_method :old_me_play, :me_play
  end

  $lyrics_playing = nil
  $lyrics_start = 0
end
ENV["LOADED_LYRICS"] = "done"


class Game_System
  def me_play(me)
    $lyrics_playing = nil
    if me != nil and me.name != ""
      $lyrics_playing = me.name
      $lyrics_start = Time.now
    else
      $lyrics_playing = nil
    end
    old_me_play(me)
  end
end

def binary(arr, ellapsed)
  first = 0
  last = arr.length - 1
  while first <= last
    i = (first + last) / 2
    if arr[i][0] <= ellapsed && arr[i][1] >= ellapsed
      return arr[i]
    elsif arr[i][1] > ellapsed
      last = i - 1
    elsif arr[i][0] < ellapsed
      first = i + 1
    else
      return nil
    end
  end
end



class Lyrics_Window < Window_Base
  def initialize
    x = (640 - $game_system.window_width) / 2
    y = 480 - $game_system.window_height - 16
    super(x, y, $game_system.window_width, $game_system.window_height)
    self.contents = Bitmap.new(width - 32, height - 32)
    self.z = 5000
    self.opacity = 0
    refresh
  end

  def refresh
    arr = $lyrics_config[$lyrics_playing]
    unless arr.nil?
      $lyrics_elapsed = Time.now - $lyrics_start
      if self.contents != nil
        self.contents.dispose
        self.contents = nil
      end
      arr_line = binary(arr, $lyrics_elapsed)
      if arr_line.nil?
        self.opacity = 0
        if arr[-1][1] < $lyrics_elapsed
          $lyrics_elapsed = 0
          $lyrics_playing = nil
        end
      else
        self.opacity = 80
        self.contents = Bitmap.new(width - 32, height - 32)
        width = 1

        text = arr_line[4].split("\n")
        height = 0
        i = 0
        for line in text
          # don't count this line's width if it has the ignr code
          width = [width, self.contents.text_size(line).width].max
          delta = self.contents.text_size(line).height
          height += delta + (delta * 0.2).to_i
        end
        if height == 0
          height = 1
        end
        self.width = width + 48
        self.height = height + 48

        self.x = arr_line[2] - self.width / 2
        self.y = arr_line[3] - self.height / 2

        self.contents.font.name = $game_system.font
        self.contents.font.color = text_color(4)
        self.contents.font.bold = true
        i = 0
        for line in text
          self.contents.draw_text(4, 32 * i, width, 32, line)
          i += 1
        end
      end
    else
      self.opacity = 0
    end
  end

  def update
    super
    if $lyrics_playing
      refresh
    end
  end

end

unless $lyrics_overlay.nil?
  $lyrics_overlay.dispose
  $lyrics_overlay = nil
end

class Game_Screen

  def create_lyrics_overlay
    $lyrics_overlay = Lyrics_Window.new
  end

  def update
    result = old_update
    if $lyrics_overlay.nil?
      create_lyrics_overlay
    end

    $lyrics_overlay.update
  end
end

$lyrics_config = {
  "Laura Shigihara - Jump" => [
    [8.0, 13.5, 320, 130, "Underneath the big dipper we gathered stars"],
    [13.5, 18.9, 320, 130, "We took off both our slippers"],
    [18.9, 21.1, 320, 130, "And sank into the water"],

    [24.1, 27.6, 320, 130, "Then we swan beneath the bridge"],
    [27.6, 34.8, 320, 130, "We met a man who sould us what we needed"],
    [34.8, 37.1, 320, 130, "He gave us directions"],

    [39.1, 47.1, 320, 130, "And we swim... And we fall"],
    [47.1, 55.1, 320, 130, "Hold my hand... Through it all"],

    [55.1, 58.0, 320, 130, "If we jump into the water"],
    [58.0, 63.0, 320, 130, "Would we swim or would we drown?"],
    [63.0, 67.0, 320, 130, "If we build a set of wings then"],
    [67.0, 71.0, 320, 130, "Could we fly or just fall down?"],
    [71.0, 74.3, 320, 130, "And if you keep talking to me"],
    [74.3, 78.3, 320, 130, "Through this darkness through this night"],
    [78.3, 81.1, 320, 130, "I'll be alright"],

    [88.1, 90.0, 320, 130, "Though we were without a map"],
    [90.0, 98.9, 320, 130, "Without a plan, without a destination"],
    [98.9, 101.1, 320, 130, "We knew where we were going"],

    [104.1, 107.5, 320, 130, "We put feathers on our backs"],
    [107.5, 114.8, 320, 130, "And climbed so we could see all that below us"],
    [114.8, 118.0, 320, 130, "Before we let go"],

    [119.2, 127.1, 320, 130, "And we fly... And we fall"],
    [127.1, 135.1, 320, 130, "Hold my hand... Through it all"],

    [135.1, 138.1, 320, 130, "If we jump into the water"],
    [138.1, 143.2, 320, 130, "Would we swim or would we drown?"],
    [143.2, 147.2, 320, 130, "If we build a set of wings then"],
    [147.2, 151.0, 320, 130, "Could we fly or just fall down?"],
    [151.0, 154.3, 320, 130, "And if you keep talking to me"],
    [154.3, 158.3, 320, 130, "Through this darkness through this night"],
    [158.3, 162.6, 320, 130, "I'll be alright"],
    [162.6, 167.2, 320, 130, "I'll be alright"],
    [167.2, 170.8, 320, 130, "I'll be alright"],

    [175.6, 183.3, 320, 130, "Would you hold me so i'd never be afraid"],
    [183.3, 190.9, 320, 130, "As the sky falls down around us now"],
    [190.9, 198.6, 320, 130, "If you tell me everything will be ok"],
    [198.6, 203.3, 320, 130, "I'll believe you, you don't have to tell me how"],

    [236.0, 239.0, 320, 130, "If we jump into the water"],
    [239.0, 243.5, 320, 130, "Would we swim or would we drown?"],
    [243.5, 247.5, 320, 130, "If we build a set of wings then"],
    [247.5, 251.7, 320, 130, "Could we fly or just fall down?"],
    [251.7, 254.7, 320, 130, "And if you keep talking to me"],
    [254.7, 259.0, 320, 130, "Through this darkness through this night"],
    [259.0, 263.0, 320, 130, "I'll be alright"],
  ],
  "Laura Shigihara - Build a little world with me" => [
    [28.00, 32.18, 320, 130, "Once these walls were grey"],
    [32.18, 38.80, 320, 130, "But you made stars and skies and snowflakes"],
    [38.80, 44.76, 320, 130, "We found a rainbow everywhere"],
    [44.76, 51.47, 320, 130, "You made a place so we could hide away"],
    [51.47, 56.88, 320, 130, "And if you stay right by my side"],
    [56.88, 59.95, 320, 130, "And make it through the night"],
    [59.95, 66.01, 320, 130, "Then you’ll never have to feel alone again"],
    [66.01, 69.12, 320, 130, "So before it’s time to leave,"],
    [69.12, 76.00, 320, 130, "Would you build a little world with me?"],

    [101.90, 105.64, 320, 130, "Once this room was cold"],
    [105.64, 112.33, 320, 130, "But then I asked the sun to smile again"],
    [112.33, 118.28, 320, 130, "Our castle covered the expense"],
    [118.28, 125.20, 320, 130, "With all the patches, pillows we could hold"],
    [125.20, 130.50, 320, 130, "And if I stay right by your side"],
    [130.50, 133.89, 320, 130, "And make it through the night"],
    [133.89, 139.51, 320, 130, "And I’ll never have to feel alone again"],
    [139.51, 142.74, 320, 130, "So before it’s time to leave,"],
    [142.74, 150.0, 320, 130, "Would you build a little world with me?"],

    [175.40, 178.40, 320, 130, "If you stay right by my side"],
    [178.40, 181.56, 320, 130, "We’ll make it through the night"],
    [181.56, 187.44, 320, 130, "And we’ll never have to feel alone again"],
    [187.44, 190.65, 320, 130, "So before it’s time to leave,"],
    [190.65, 200.59, 320, 130, "Would you build a little world with me?"],
    [200.59, 203.49, 320, 130, "Now it’s time for me to leave"],
    [203.49, 217.0, 320, 130, "I’m glad you built this little world with me"],
  ]


}
