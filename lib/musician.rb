require "rubygems"
require "pow"

require "chairs/version"

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
      puts "Musical Chairs - for swapping in/out document folders in iOS Sims."
      puts ""
      puts "           pull [name]        get the docs file from most recent app and call it name."
      puts "           push [name]        move the named docs to the most recent app doc folder."
      puts "           list               list all the current docs in working directory."
      puts ""
      puts "                                                                                      ./"
    end

    def pull
      unless @params[1]
        puts "Chairs needs a name for the target." 
        return
      end

      setup

      puts "Switching files from #{@app_folder}/Documents to"
      puts "chairs/#{@target_folder} for #{@app_name}."
      
      Pow("chairs/#{@target_folder}").create do
        Pow("#{@app_folder}/Documents").copy_to(Pow())
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


      puts "Moving files from chairs/#{@target_folder} to"
      puts "#{@app_folder}/Documents for #{@app_name}."

      Pow("chairs/#{@target_folder}/Documents/").copy_to(Pow("#{@app_folder}/"))

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
        filename = File.basename(doc)
        folders << filename if doc.directory?
      end

      # turn it into a sentence
      if folders.length == 1
        folders = "just " + folders[0]
      else
        last = folders.last
        folders = "have " + folders[0..-2].join(", ") + " and " + last
      end

      puts "Currently you #{ folders }."
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
          puts "You don't have chairs/ in your .gitignore would you like chairs to add it? [Yn]"
          confirm = STDIN.gets.chomp
          file << gitignore_line if confirm && confirm.downcase == "y"
        end
      end
    end

    # get the most recently used simulator
    def get_app_folder
      app_folder = nil

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
            
          # check that we've found the most recently changed
          if app_folder.modified_at < maybe_app_folder.modified_at
            app_folder = maybe_app_folder
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

    def commands
      (public_methods - Object.public_methods).sort.map{ |c| c.to_sym}
    end 
  end
end