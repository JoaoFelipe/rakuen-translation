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

# This file loads mods for Rakuen
# You must add
# load "#{Dir.getwd}/mods.rb"
# on top of Data/Scripts.rxdata/Main

$EXE_PATH = "#{Dir.getwd}/Data"
$WD_PATH = Dir.getwd

class Mod_System

  def load_mods
    mods = Dir["#{$EXE_PATH}/mods/*"].select{ |f| 
      (File.directory? f) && (File.exists? "#{f}/init.rb")
    }.map{|f| File.basename f}.sort

    mods.each do |mod|
      load("#{$EXE_PATH}/mods/#{mod}/init.rb")
    end
  end

  def reload
    load("#{$WD_PATH}/mods.rb")
  end

end

$mod_system = Mod_System.new
$mod_system.load_mods
