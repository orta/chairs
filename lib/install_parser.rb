class App
  attr_accessor :bundle_id, :name, :app_path, :bundle_path, :modified_date, :exists
end

class InstallParser
  def parse ( log_path )
    apps = {}
    
    File.read(log_path).lines.each do |line|
      if line.include? "MIInstallableBundle ID="
        app = App.new
        app.bundle_id = line.split("MIInstallableBundle ID=").last.split(";").first
        apps[app.bundle_id] = app
      end

      if line.include? "Made container live for"
        bundle_id = line.split("Made container live for ").last.split(" at").first
        next unless apps[bundle_id]
        
        if line.include? "Bundle/Application"
          app = apps[bundle_id]
          app_container = line.split(" at ").last.strip 

          app.exists = Dir.exists? app_container
          
          if app.exists
            app.app_path = Dir.glob(app_container + "/*.app").first
            app.modified_date = File.mtime app.app_path
            
            if File.read("#{app.app_path}/Info.plist").include? "CFBundleDisplayName"
              app.name = `/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" '#{app.app_path}/Info.plist'`.strip
            else
              app.name = `/usr/libexec/PlistBuddy -c "Print CFBundleName" '#{app.app_path}/Info.plist'`.strip
            end
          end
        elsif line.include? "Data/Application"
          apps[bundle_id].bundle_path = line.split(" at ").last.strip
        end
      end
    end

    apps.values.select(&:exists).sort_by(&:modified_date)
  end
end