class SimctlParser
  def get_devices
    output = `xcrun simctl list`.strip
    output = output.split("== Devices ==").last
    os = ""
    output.lines.map do |line|
      if line.strip.start_with?( "--")
        os = line.gsub("-","").strip
      end
      
      if line.strip.length != 0 && line.strip.start_with?( "--") == false && line.include?("unavailable") == false
      {
        :name => line.strip.split(" ")[0..-3].join(" "),
        :state => line.strip.split(" ")[-1],
        :id => line.strip.split(" ")[-2][1..-2].strip,
        :os => os
      }
      end
    end.compact
  end
  
  def open_device
    get_devices.select do | device |
      device[:state] == "(Booted)"
    end.first
  end
end
