module Pow
  
  # Pow object representing a directory. Inherits from Pow::Base 
  class Directory < Base
    include Enumerable

    def initialize(path, mode=nil, &block) #:nodoc:
      super
      open(&block) if block_given?
    end

    def open(mode=nil, &block) #:nodoc:
      raise PowError, "'#{path}' does not exist!" unless exists?
      
      begin
        former_dir = Dir.pwd
        Dir.chdir self.to_s
        block.call self
      ensure
        Dir.chdir(former_dir)
      end
    end
    
    def create(&block) #:nodoc:
      create_directory(&block)
    end

    # Deletes an empty directory
    def delete
      raise PowError, "Can not delete '#{path}'. It must be empty before you delete it!" unless children.empty?
      Dir.rmdir path
    end
    
    # Recurslivly deletes the directory, DANGER! DANGER!
    def delete!
      FileUtils.rm_r path
    end
    
    def copy_to(dest)
      FileUtils.cp_r(path, dest.to_s)
    end
    alias_method :cp, :copy_to

    def copy_to!(dest)
      Pow(dest).parent.create_directory
      FileUtils.cp_r(path, dest.to_s)
    end
    alias_method :cp!, :copy_to!
    
    def move_to(dest)
      if FileUtils.mv(path.to_s, dest.to_s)
        self.path = dest
      end
    end
    alias_method :mv, :move_to
  
    def empty?
      children.empty?
    end
  
    # ===============
    # = My Children =
    # ===============
    
    # A wrapper for Dir.glob, returns files & directories found by expanding pattern.
    def glob(pattern, *flags)
      Dir[::File.join(to_s, pattern), *flags].collect {|path| Pow(path)}
    end
    
    # Returns all the files in the directory
    def files
      children(:no_dirs => true)
    end

    # Returns all the directories in the directory
    def directories
      children(:no_files => true)
    end
    alias_method :dirs, :directories

    # Returns all files and directories in the directory. 
    #
    # ==== Parameters
    # options<Hash>:: [:no_dirs, :no_files] (defaults to :no_dirs => true, :no_files => true)
    def children(options={})
      options = {:no_dirs => false, :no_files => false}.merge(options)

      children = []
      Dir.foreach(path) do |child|
        child_path = ::File.join(path, child)

        next if child == '.'
        next if child == '..'
        next if (::File.file?(child_path) and options[:no_files]) 
        next if (::File.directory?(child_path) and options[:no_dirs])
        children << Pow(child_path) 
      end
      
      children
    end

    # Yields the child paths to an each block.
    def each(&block)
      raise PowError, "'#{path.realpath}' does not exist!" unless exists?
      children.each(&block)
    end
  end
end