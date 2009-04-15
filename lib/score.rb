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
    @score_attrs = []
  end
  
  def <<(notes)
    notes.each do |note| 
      @notes << note.dup
    end    
  end

  def method_missing(name, val)
    def_accessor(name, val)
    @score_attrs.push name.to_sym
    self.send(name.to_sym, val)
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
  
  def clear
    @notes = []
    @score_attrs = []  
  end
    
  def dup
    ret = Score.new
    ret.name = self.name
    self.notes.each {|note| ret.notes.push(note.dup)}    
    @score_attrs.each do |attr|
      val = self.send(attr.to_sym)
      ret.method_missing(attr, val)
    end
    ret
  end   
         
  # TODO Use format == midi, format == csound set in Composer
  def to_s 
    s = ''
    @notes.each do |note|    
      s << note.to_s
      s << "\n"
    end
    s
  end
end

class ScoreWriter < Score
  include Singleton
  attr_accessor :format
  
  def to_s 
    s = ''
    if self.format.to_sym == :csound
      # TODO THIS COMES FROM YAML CONFIG, it's optional in CSound so needs 
      #  instr_include.length check etc.
      s << "#include \"oscil_sine_ftables_1.txt\""
      s << "\n"
      s << "\n"
    end
    s << super.to_s
    s
  end  
end

class Phrase < Score
end

#TODO THIS IS BEGGING FOR A MIX-IN - identical code, different 'types'
class Section
  attr_reader :phrases
  attr_accessor :name

  def initialize(name=nil)
    @name = name
    @phrases = []
  end
  
  def add_phrases(phrases)
    phrases.each do |phrase| 
      @phrases << phrase.dup
    end    
  end
  
  def method_missing(name, val)
    def_accessor(name, val)
    self.send(name.to_sym, val)
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
           
  def to_s 
    s = ''
    @phrases.each do |phrase|    
      s << phrase.to_s
      s << "\n"
    end
    s
  end
end

class Player < Score
end

end