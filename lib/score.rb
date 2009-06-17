require 'note'
require 'conf_csound'
require 'singleton'

module Aleatoric

class Score
  attr_reader :notes
  attr_accessor :name
  attr_accessor :score_attrs
  public :name, :notes
  protected :score_attrs
  
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
  attr_reader :format
  
  def to_s_format(format)  
    @format = format.to_sym
    Note.to_s_format = @format
  end
  
  def to_s 
    s = ''
    case @format
    when :csound
      s << "#include \"#{$csound_score_include_file_name}\""
      s << "\n"
      s << "\n"
    when :midi
      # TODO Really support MIDI
    end
    
    s << super.to_s
    s
  end
end

class Phrase < Score
end


class Measure < Score
  attr_reader :start
  
  def initialize(name, start=0.0)
    super(name)
    @start = start    
  end
  
  def reset_notes(start)
    @start = start
    @notes = @notes.collect do |note| 
      new_note = note.dup
      new_note.start(new_note.start + @start)
      new_note
    end
  end
  
  def <<(notes)  
    notes.each do |note|
      new_note = note.dup
      new_note = new_note.start(new_note.start + self.start)       
      @notes << new_note
    end    
  end
  
  def dup
    # TODO better than this ugly hack
    ret = Measure.new(self.name, self.start)
    ret << self.notes
    ret.score_attrs = self.score_attrs    
    ret
  end
end

#TODO THIS IS BEGGING FOR A MIX-IN - identical code, different 'types'
class Section
  attr_reader :phrases
  attr_accessor :name

  def initialize(name=nil)
    @name = name
    @phrases = []
  end
    
  def <<(phrases)
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