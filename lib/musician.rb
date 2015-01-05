require "rubygems"
require File.join(File.dirname(__FILE__), 'pow')
require File.join(File.dirname(__FILE__), 'simctl_parser')
require File.join(File.dirname(__FILE__), 'install_parser')

require "chairs/version"

# this command comes in handy for dev
# rm *.gem; gem uninstall chairs -ax;gem build *.gemspec; gem install *.gem;

module Chairs

  class Musician

    def initialize(args)
      # find a command
      @params = args
      command = @params[0].to_sym rescue :help
      commands.include?(command) ? send(command.to_sym) : help
    end

    def help
      puts ""
      puts "Musical Chairs - for swapping in/out app data in the iOS Simulator."
      puts ""
      puts "           sync               takes the app from the *currently open* sim, and send it to all other sims."
      puts "           pull [name]        get documents and support files from latest built app and store as name."
      puts "           push [name]        overwrite documents and support files from the latest build in Xcode."
      puts "           rm   [name]        delete the files for the chair."
      puts "           open               open the current app folder in Finder."
      puts "           list               list all the current docs in working directory."
      puts ""
      puts "                                                                                      ./"
    end

    def open
      setup
      puts "Opening #{ @app_name }"
      `open "#{ @app.bundle_path }"`
    end

    def pull
      unless @params[1]
        puts "Chairs needs a name for the target."
        return
      end

      setup

      # validate
      if Pow("chairs/#{@target_folder}").exists?
        print "This chair already exists, do you want to overwrite? [Yn] "
        confirm = STDIN.gets.chomp
        if confirm.downcase == "y" || confirm == ""
          FileUtils.rm_r( Pow().to_s + "/chairs/#{@target_folder}/")
        else
          return
        end
      end

      puts "Pulling files for #{ @app_name }"
      puts "From #{@app} to chairs/#{@target_folder}"

      Pow("chairs/#{@target_folder}/").create_directory do
        copy(Pow("#{@app}/*"), Pow())
      end

      puts "Done!"
    end

    def push
      unless @params[1]
        puts "Chairs needs a name for the target."
        return
      end

      setup

      unless Pow("chairs/#{@target_folder}").exists?
        puts "You don't have a folder for #{@target_folder}."
        list
        return
      end

      puts "Pushing files for #{@app_name}"
      puts "From chairs/#{@target_folder} to #{@app}"

      # clean the directory we're about to throw things in
      target_path = Pow(@app).to_s.gsub(" ", "\\ ")
      system "rm -r #{target_path}/*"

      copy(Pow("chairs/#{@target_folder}/*"), Pow("#{@app}/"))
      puts "Done!"
    end

    def list
      unless Pow("chairs/").exists?
        puts "You haven't used chairs yet."
        return
      end

      # get all folders in the directory
      folders = []
      @target_folder = @params[1]
      Pow("chairs/").each do |doc|
        if doc.directory?
          filename = File.basename(doc)
          size = `du -sh '#{doc}' | cut -f1`.strip
          folders << "#{filename} (#{size})"
        end
      end

      # turn it into a sentence
      if folders.length == 0
        folders = "have no chairs setup."
      elsif folders.length == 1
        folders = "just " + folders[0]
      else
        last = folders.last
        folders = "have " + folders[0..-2].join(", ") + " and " + last
      end

      puts "Currently you #{ folders }."
    end

    def rm
      unless @params[1]
        puts "Chairs needs a name for the target."
        return
      end

      @target_folder = @params[1]
      if Pow("chairs/#{@target_folder}/").exists?
        FileUtils.rm_r( Pow().to_s + "/chairs/#{@target_folder}/")
        puts "Deleted #{@target_folder}/"
      else
        puts "That chair does not exist."
        list
      end
    end

    def clean
      setup

      puts "Deleting App directory"
      target_path = Pow(@app).to_s.gsub(" ", "\\ ")
      
      command =  "rm -r #{target_path}"
      puts command
      system command

      puts "Cleaned"
    end
    
    def sync
      setup
      
      simctl = SimctlParser.new
      current_device = simctl.open_device
      devices = simctl.get_devices
      
      unless current_device 
        puts "Couldn't find an active iOS Simulator"
        return
      end
      
      
      print "Migrating #{@app_name} from #{current_device[:name]} to all other devices"

      os = ""
      devices.each do |device|
        next if device[:id] == current_device[:id]
        if device[:os] != os
          os = device[:os]
          print "\n #{os} -> "
        end
        
        same_app_different_device = @all_apps.flatten.select do | app |
            app.app_path.include?(device[:id]) && app.bundle_id == @app.bundle_id
        end.first
        
        if same_app_different_device
          new_app = same_app_different_device
          puts 
          puts [@app.app_path, new_app.app_path]
          puts [@app.bundle_path, new_app.bundle_path]
#          copy(@app.app_path, new_app.app_path, true)
          
        else
          
        end
          
          
        puts "cp -RF -> "

        app_folder = @app.app_path
        
        # `rm -rf #{new_app_path}`

        if device == devices.last 
          print "and #{ device[:name] }."
        else
          print "#{ device[:name] }, "
        end
      end
    end

    protected

    def setup
      check_for_gitignore

      @target_folder = @params[1]
      @all_apps = get_all_apps
      @app = get_most_recent_app
      @app_name = @app.bundle_id
    end

    def check_for_gitignore
      gitignore = Pow(".gitignore")

      # if the folder already exists, don't ask twice
      # but surely everyone'll add it to the gitignore on first pull
      if gitignore.exists? && ( Pow("chairs/").exists? == false )
        gitignore_line = "\nchairs/\n"
        file = File.open(gitignore, "a")
        reader = File.read(gitignore)

        unless reader.include?(gitignore_line)
          print "You don't have chairs/ in your .gitignore would you like chairs to add it? [Yn] "
          confirm = STDIN.gets.chomp
          file << gitignore_line if confirm && ( confirm.downcase == "y" || confirm == "" )
        end
      end
    end

    def get_all_apps
      sims = Dir.glob(Dir.home + "/Library/Logs/CoreSimulator/*")
      all_apps = []
      sims.map do |simulator_folder|
        if File.directory? simulator_folder
          log = "#{simulator_folder}/MobileInstallation/mobile_installation.log.0"
          if File.exist?(log)
            all_apps << InstallParser.new.parse(log)
          end
        end
      end.compact
    end

    # get the most recently used simulator app
    def get_most_recent_app
      @all_apps.flatten.sort_by(&:modified_date).reverse.first
    end

    def copy(source, dest, verbose=true)
      source = source.to_s.gsub(" ", "\\ ")
      dest = dest.to_s.gsub(" ", "\\ ")
      copy = "cp -R #{source} #{dest}"
      if verbose
        puts copy
        system copy
      else
        `#{copy}`
      end
    end

    def commands
      (public_methods - Object.public_methods).sort.map{ |c| c.to_sym }
    end
  end
end
