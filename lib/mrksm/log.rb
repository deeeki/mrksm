module Mrksm
  class Log
    attr_accessor :slug

    def initialize file = './.downloaded'
      @file = file
      @slug = read if exist?
    end

    def exist?
      File.exist?(@file)
    end

    def read
      File.read(@file).chomp
    end

    def write str
      File.write(@file, str)
    end
  end
end
