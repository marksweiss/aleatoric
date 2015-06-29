require_relative 'note'
# require 'conf_csound'
require 'singleton'

module Aleatoric

# Models an ordered sequence of Notes.  #<< is used to add Notes using stream/string
# append syntax. Only trivial accessors are defined for name and the collection of notes.
# Users dynamically add attributes which are processed by #method_missing.  Attribute
# names can be retrieved in the order they were added.
class Score
  attr_reader :notes
  attr_accessor :name
  attr_accessor :score_attrs
  public :name, :notes
  protected :score_attrs
  
  def initialize(name=nil)
    # reasonable default value transparent to user (who didn't provide a name after all)
    #  and that is guaranteed to be unique
    @name = name ||= self.object_id.to_s 
    @notes = []
    @score_attrs = []
  end
  
  # Append an Enumerable of Notes to the Score.  Does a deep copy on each Note added
  # so that any subsequent manipulation by this Score won't affect the source Note.
  # @param[Enumerable<Aleatoric::Note>]
  def <<(notes)
    notes.each do |note|
      new_note = note.dup
      # For debugging
      new_note.score_id = "#{@name}_#{self.object_id}"  
      @notes << new_note
    end    
  end
  
  # TODO UNIT TEST
  def prepend(notes)
    ret = []
    notes.each do |note| 
      new_note = note.dup
      # For debugging
      new_note.score_id = "#{@name}_#{self.object_id}"        
      ret << new_note
    end
    @notes = ret + @notes
  end
  
  # TODO UNIT TEST
  def append_note(note)
    new_note = note.dup
    # For debugging
    new_note.score_id = "#{@name}_#{self.object_id}"        
    @notes << new_note
  end
  
  # TODO UNIT TEST
  def prepend_note(note)
    new_note = note.dup
    # For debugging
    new_note.score_id = "#{@name}_#{self.object_id}"        
    @notes = [new_note] + @notes
  end
  
  def size
    @notes.size
  end
  alias length size

  # Creates accessors for newly created attributes of the object
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
  
  # Clears the collection of Notes held by this Score
  def clear
    @notes = []
    @score_attrs = []  
  end
  
  def attr_slice(attr)
    ret = []
    self.notes.each {|note| ret << note.send(attr.to_sym)}
    ret
  end
  
  def ==(other)
    return self.name == other.name && 
      self.score_attrs == other.score_attrs && 
      self.notes == other.notes
  end
  
  # Returns a deep copy of the object
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
  
  # Iterates over the Notes in this Score, calls note.#to_s, appends the result to an output
  # string and then returns that output string
  # @return [String] the concatenation of the #to_s of each Note in the Score
  def to_s
    s = ''
    @notes.each do |note|    
      s << (note.to_s + "\n")
    end
    s
  end
end

# Inherits from Score and adds ability to prepend header information to the string
# output of the object.  Supports format just as Score does.
class ScoreWriter < Score
  include Singleton
  attr_reader :format
  attr_accessor :file_name
  
  # Modifies the Note #to_s format being used by all Scores in the current process.
  # @param [:csound, :midi] The format to set
  def to_s_format(format)  
    @format = format.to_sym    
    Note.output_format @format
  end
  alias set_output_format to_s_format
  alias set_notes_to_s_format to_s_format
  alias set_notes_output_format to_s_format
  
  # Prepends header to #to_s output and then calls parent Score.#to_s
  def to_s 
    s = ''
    case @format
    when :csound
      s << "#include \"#{$csound_score_include_file_name}\""
      s << "\n"
      s << "\n"
    when :midi
      # No-op since Note::to_s() for :midi just outputs string for testing purposes. MIDI rendering is
      #  straight to binary file via wrapped OS API calls to a MIDI library. No need to output text script for rendering
      #  as with CSound
    end
    
    s << super.to_s
    s
  end
end

# An alias for Score
class Phrase < Score
end

# Extends Score to also support manipulating the start property of the note so that
# as Notes are added they automatically start after the last note added
class Measure < Score
  attr_reader :start
  
  def initialize(name, start=0.0)    
    super(name)
    @start = start    
  end
  
  # Resets the start time of all notes in this Score to value passed in param start
  # param [Float] the value to set for the start attribute for all Notes in the Score
  def reset_notes(start)
    @start = start
    @notes = @notes.collect do |note| 
      new_note = note.dup
      new_note.start(new_note.start + @start)
      new_note
    end
  end
  
  # Adds an Enumerable of Notes to the collection held by this object.  Also adjusts
  # the start time of each note in the Score.
  def <<(notes)  
    notes.each do |note|
      new_note = note.dup
      new_note = new_note.start(new_note.start + self.start)
      # For debugging
      new_note.score_id = "#{@name}_#{self.object_id}"     
      @notes << new_note
    end    
  end
  
  # Returns a deep copy of the object 
  def dup
    # TODO Shouldn't deep copy include @start?
    ret = Measure.new(self.name, self.start)
    ret << self.notes
    ret.score_attrs = self.score_attrs    
    ret
  end
end

# Models a section of a composition in a Composer score file.  The section can have
# Measures within it.  The notion is that this has the same syntax and semantics as 
# Score, but that it is itself the next level up in the hierarchy, an ordered sequence
# of Scores.
class Section
  attr_reader :phrases
  attr_accessor :name

  def initialize(name=nil)
    @name = name
    @phrases = []
  end

  # Append an Enumerable of Phrases
  def <<(phrases)
     phrases.each do |phrase| 
      @phrases << phrase.dup
    end    
  end
  
  # Creates accessors for newly created attributes of the object
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

end
