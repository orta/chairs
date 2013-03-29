module Pow

  # Pow object representing a file. Inherits from Pow::Base 
  class File < Base
    def initialize(path, mode="r+", &block) #:nodoc:
      super
      open(mode, &block) if block_given?
    end
    
    def open(mode="r", &block) #:nodoc:
      Kernel.open(path.to_s, mode, &block)
    end
    
    def create(&block) #:nodoc:
      create_file(&block)
    end 
        
    # Opens the file, optionally seeks to the given offset, then returns length bytes (defaulting to the rest of the file). read ensures the file is closed before returning.
    # Alias for IO.read
    def read(length=nil, offset=nil)
      ::File.read(path.to_s, length, offset)
    end
    
    def write(string)
      open("w") {|f| f.write string}
    end
    
    def delete
      ::File.delete(path)
    end
    
    def empty?
      ::File.size(path) == 0
    end
    
    def copy_to(dest)
      FileUtils.cp(path.to_s, dest.to_s)
      Pow(dest)
    end
    alias_method :cp, :copy_to
    
    # Will create the directory path if it does not already exist.
    def copy_to!(dest)
      Pow(dest).parent.create_directory
      copy_to(dest)
    end
    alias_method :cp!, :copy_to!
        
    def move_to(dest)
      if FileUtils.mv(path.to_s, dest.to_s)
        self.path = dest.path
      end
    end
    alias_method :mv, :move_to
    
    # Will create the directory path if it does not already exist.
    def move_to!(dest)
      Pow(dest).parent.create_directory
      move_to(dest)
    end
    alias_method :mv!, :move_to!
  end
end