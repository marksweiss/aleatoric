$LOAD_PATH << "..\\lib"
require 'player'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start


module Aleatoric

class Ensemble

  attr_accessor :name, :players

  def initialize(name)
    @name = name
    @players = []
  end
  
  def <<(players)
    players.each do |player|
      @players << player.dup
    end      
  end
  
  def to_s
    @name
  end

end

#class Ensemble_Test < Test::Unit::TestCase

#end

end