require 'note'
require 'util'
require 'singleton'

module Aleatoric

class Score
  attr_reader :notes
  attr_accessor :name

  def initialize(name=nil)
    @name = name
    @notes = []
  end
  
  def <<(notes)
    notes.each do |note| 
      @notes << note.dup
    end    
  end
       
  def method_missing(name, val) 
    def_accessor(name, val)
    instance_eval("self.#{name}(#{val})")
  end
  
  private
  def def_accessor(name, val)
    self.class.class_eval %Q{
      def #{name}(val=nil)
        if val == nil then
          @#{name}
        else
          @#{name} = val
          self
        end
      end
    }
  end
  public
  
  # TODO Use format == midi, format == csound set in Composer
  def to_s
    s = ""   
    @notes.each do |note|
      s << note.to_s
    end
    s
  end
end

class ScoreWriter < Score
  include Singleton
end

class Phrase < Score
end

class Section < Score
end

class Player < Score
end

end