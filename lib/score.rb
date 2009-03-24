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
         
  # TODO Use format == midi, format == csound set in Composer
  def to_s 
    s = ''
    @notes.each do |note|    
      s << note.to_s
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
    @notes.each do |note|
      s << note.to_s
      s << "\n"
    end
    s
  end  
end

class Phrase < Score
end

class Section < Score
end

class Player < Score
end

end