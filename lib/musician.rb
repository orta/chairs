require "rubygems"
require File.join(File.dirname(__FILE__), 'pow')

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
      puts "           pull [name]        get documents and support files from latest built app and store as name."
      puts "           push [name]        overwrite documents and support files from the latest build in Xcode."
      puts "           rm   [name]        delete the files for the chair."
      puts "           open               open the current app folder in Finder."
      puts "           list               list all the current docs in working directory."
      puts ""
      puts "                                                                                      ./"
    end

    def open
      `open "#{ get_app_folder }"`
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
      puts "From #{@app_folder} to chairs/#{@target_folder}"
      
      Pow("chairs/#{@target_folder}/").create_directory do
        copy(Pow("#{@app_folder}/*"), Pow())
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
      puts "From chairs/#{@target_folder} to #{@app_folder}"

      # clean the directory we're about to throw things in
      target_path = Pow(@app_folder).to_s.gsub(" ", "\\ ")
      system "rm -r #{target_path}/*"

      copy(Pow("chairs/#{@target_folder}/*"), Pow("#{@app_folder}/"))
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
      target_path = Pow(@app_folder).to_s.gsub(" ", "\\ ")
      
      command =  "rm -r #{target_path}"
      puts command
      system command
      
      puts "Cleaned"
    end

    protected

    def setup
      check_for_gitignore

      @target_folder = @params[1]
      @app_folder = get_app_folder()
      @app_name = get_app_name()
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

    # get the most recently used simulator
    def get_app_folder
      app_folder = nil
      app = nil

      # look through all the installed sims
      sims = Pow( Pow("~/Library/Application Support/iPhone Simulator") )

      sims.each do |simulator_folder| 
        next if simulator_folder.class != Pow::Directory

        apps = Pow( "#{simulator_folder}/Applications/" )
        next unless apps.exists?

        # look through all the hash folders for apps
        apps.each do |maybe_app_folder|
          next unless maybe_app_folder.directory?

          # first run
          app_folder = maybe_app_folder if !app_folder
          
          # find the app in the folder and compare their modified dates
          # remember .apps are folders
          maybe_app = maybe_app_folder.directories.reject {|p| p.extension != "app"}
          # it returns as an array
          maybe_app = maybe_app[0]

          if maybe_app && app
            if maybe_app.modified_at > app.modified_at
              app_folder = maybe_app_folder
              app = maybe_app
            end        
          else
              # make the first one the thing to beat
              app_folder = maybe_app_folder
              app = maybe_app
          end
        end

      end
      app_folder
    end

    def get_app_name
      # grab the app name
      # look in the app's folder for a .app
      app_folder = get_app_folder
      Pow(app_folder).each do |app_folder_files|
        if app_folder_files.directory?

          # and use the name of that
          filename = File.basename app_folder_files
          if filename.include? ".app"
            return filename
          end
        end
      end
      
      return ""
    end 

    def copy(source, dest)
      source = source.to_s.gsub(" ", "\\ ")
      dest = dest.to_s.gsub(" ", "\\ ")
      copy = "cp -R #{source} #{dest}"

      puts copy
      system copy
    end

    def commands
      (public_methods - Object.public_methods).sort.map{ |c| c.to_sym}
    end 
  end
end