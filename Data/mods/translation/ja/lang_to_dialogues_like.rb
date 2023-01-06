require __dir__ + "/lang"

File.open(__dir__ + "/dialogues_like.txt", "w+") do |f|
  $events_lang.each do |k1, v1|
    v1.each do |k2, v2|
      v2.each do |k3, v3|
        v3.each do |k4, v4|
          id = "Map:%d:%d:%d:%d" % [k1, k2, k3, k4]
          if v4.instance_of?(Array)
            header = "+++++++++++++++++++++++++++++++++++++++++++++++++" + id
            body = v4[0].join("\n")
          else
            header = "-------------------------------------------------" + id
            body = v4
          end
          f.puts(header)
          f.puts(body)
        end
      end
    end
  end
end
