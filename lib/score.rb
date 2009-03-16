require 'note'
require 'util'
require 'singleton'

module Aleatoric

class Score
  attr_reader :notes

  def initialize
    @notes = []
  end
  
  def <<(n)
    if n.is_array? # Defined on Object in util.rb
      n.each {|note| @notes << note}
    elsif n
      @notes << n
    end
  end
    
  def last
    @notes.last
  end
  
  def method_missing_handler(name, val)
    last.method_missing(name, val)
  end
  
  def to_s
    s = ""
    @notes.each {|note| s << note.to_s}
    s
  end
end

class ScoreWriter < Score
  include Singleton
end

end