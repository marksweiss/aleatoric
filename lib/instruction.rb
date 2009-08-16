$LOAD_PATH << "..\\lib"
require 'player'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

module Aleatoric

# A very simple type to hold the name and description of data provided by Composer keyword 'instruction'
class Instruction

  attr_accessor :name, :description
  
  def initialize(name)
    @name = name
  end

end

# A very simple type to hold the name and description of data provided by Composer keyword 'improvisation'
class Improvisation < Instruction
end

end