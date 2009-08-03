$LOAD_PATH << "..\\lib"
require 'player'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

module Aleatoric

class Instruction

  attr_accessor :name, :description
  
  def initialize(name)
    @name = name
  end

end

class Improvisation < Instruction
end

end