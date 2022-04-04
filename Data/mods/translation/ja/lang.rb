load File.join(File.dirname(__FILE__), "lang.original.rb")

mapEvents = {}
items = {}

File.open(File.join(File.dirname(__FILE__), "dialogues.txt"), "r") do |f|
    f.each_line(){|line|
        eventKey = nil
        if event = line.match(/(\-|\+)\[Map:(\d+:\d+:\d+):\d+\]$/)
            eventKey = event[2]
        elsif event = line.match(/(\-|\+)\[Com Ev:(\d+):\d+\]$/)
            eventKey = "0:#{event[2]}:0"
        end

        if event
            isChoice = event[1] == "+"
            eventRows = []
            loop do
                previousPosition = f.pos
                f.readline
                if $_.match(/^[\-\+\_]{5,}/)
                    f.seek(previousPosition, IO::SEEK_SET)
                    break
                end
                eventRows.push(isChoice ? $_.strip : $_)
            end
            mapEvents[eventKey] = mapEvents.key?(eventKey) ? mapEvents[eventKey] : []
            mapEvents[eventKey].push(isChoice ? eventRows : eventRows.join)
            next
        end

        if item = line.match(/_\[Item:(\d+)\]$/)
            itemKey = item[1].to_i
            items[itemKey] = [f.readline.strip, f.readline.strip]
        end
    }
end

dialogue_separator = "------------------------------------------\n"
$events_lang.each{|k1, v1|
    v1.each{|k2, v2|
        v2.each{|k3, v3|
            eventKey = "#{k1}:#{k2}:#{k3}"
            if !mapEvents.key?(eventKey)
                next
            end
            v3.keys.sort.each{|k4|
                v4 = v3[k4]
                if v4.instance_of?(Array)
                    choices = mapEvents[eventKey].shift
                    v3[k4] = [choices, v4[1]]
                elsif v4.instance_of?(String)
                    dialogues = v4.split(dialogue_separator)
                    dialogues.each_with_index do |_, i|
                        dialogues[i] = mapEvents[eventKey].shift
                    end
                    v3[k4] = dialogues.join(dialogue_separator)
                end
            }
        }
    }
}

items.each{|key, value|
    $items_lang[key] = value
}
