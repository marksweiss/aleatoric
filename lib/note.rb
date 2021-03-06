require_relative 'util'

module Aleatoric

class AleatoricIllegalNoteFormatException < Exception; end

# Models a musical note.  Current implementation supports CSound.  Future implementation
# will also support MIDI.  Two key ideas are used here.  First is that the class
# doesn't actually specify note properties (which include commone core ones by
# convention in CSound but can be arbitrary, and which in MIDI must include a core set
# but also can include several optional ones).  Instead it relies on method missing
# to set properties as they are created by the Composer script.  Second the client
# can set the format with a symbol arg in #initialize, which then forces #to_s to
# output either CSound or MIDI output.  Note also that properties are output by #to_s
# in the order they are added to the object.  Format is class-scope, meaning that 
# all Notes in one execution of a Composer score are of the same format.
class Note

  NO_CHANNEL = 17

  attr_accessor :name, :measure
  attr_reader :ordered_keys, :note_attrs
  # Default is to not include appended player_id, ensemble_id and score_id
  #  with note to_s output, but this can be turned on for logging it, which can help
  #  with debugging, especially when implementing instruction handlers for scores with
  attr_accessor :ensemble_id  # For debugging
  attr_accessor :to_s_with_debug_info

  @@format = nil

  def initialize(name=nil, attrs=nil)    
    @name = name
    # For debugging, so can print these out as comments in a score
    @player_id = nil; @ensemble_id = nil; @score_id = nil
    @note_attrs = {}
    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]    
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}    
    @to_s_with_debug_info = false
  end

  def instrument(instrument=nil)  
    if instrument.nil?
      @note_attrs[:instrument]
    else
      @note_attrs[:instrument] = instrument
      self
    end
  end
  # TODO REAL MIDI PROGRAM CHANGE
  # alias midi name to csound name
  def program_change(instrument=nil)
    self.instrument(instrument)
  end
 
  # NOTE: if arg is named 'start' here fails in Ruby 2.x with name argument exception. No reason for this 
  def start(arg=nil)
    if arg.nil? 
      @note_attrs[:start]
    else
      @note_attrs[:start] = arg 
      self
    end
  end
  # alias midi name to csound name
  def time(st=nil)
    self.start(st)
  end

  def duration(duration=nil)
    if duration.nil?
      @note_attrs[:duration]
    else
      @note_attrs[:duration] = duration 
      self
    end    
  end
  
  def amplitude(amplitude=nil)      
    if amplitude.nil?
      @note_attrs[:amplitude]
    else
      @note_attrs[:amplitude] = amplitude 
      self
    end
  end
  # alias midi name to csound name
  def velocity(amplitude=nil)
    self.amplitude(amplitude)
  end
  # alias normal real-world name to csound name
  def volume(amplitude=nil)
    self.amplitude(amplitude)
  end

  def pitch(pitch=nil)    
    if pitch.nil?
      @note_attrs[:pitch]
    else
      @note_attrs[:pitch] = pitch 
      self
    end
  end
  # alias note pitch
  
  # MIDI only
  def channel(channel=nil)    
    if @@format == :midi
      if channel.nil?
        @note_attrs[:channel]
      else
        @note_attrs[:channel] = channel
        self
      end
    else
      raise AleatoricIllegalNoteFormatException, "Cannot call note_obj.channel() method when Note::@@format != :midi", caller
    end
  end
  
  def player_id=(id)
    @player_id = id
    @player_id
  end
  def player_id
    @player_id
  end
  
  def score_id=(id)        
    @score_id = id
    @score_id
  end
  def score_id
    @score_id
  end
  
  # Returns a deep copy of the object
  def dup
    ret = Note.new
    ret.name = self.name
    ret.measure = self.measure
    ret.player_id = self.player_id      # For debugging
    ret.ensemble_id = self.ensemble_id  # For debugging
    ret.score_id = self.score_id        # For debugging
    @note_attrs.each {|name, val| ret.method_missing(name, val)}    
    ret
  end  
  
  # Set to_s appropriately based on output format
  # Adds a to_s definition to the class based on format value passed to class method
  def Note.to_s_format(format=nil)
    if format == nil
      @@format = $FORMAT
    else
      @@format = format.to_sym
    end    
    @@format
  end
  def Note.output_format(format=nil)  
    if format == nil
      @@format = $FORMAT
    else
      @@format = format.to_sym
    end    
    @@format
  end
  def Note.set_output_format_csound
    @@format = :csound
  end
  def Note.set_output_format_midi
    @@format = :midi
  end
  
  def ==(other)
    return self.note_attrs == other.note_attrs
  end
  
  # Outputs a string representation of the note, based on the value for format passed to #initialize
  def to_s  
    case @@format    
    when :csound
      ret = "i "
      @ordered_keys.each do |key|
        val = @note_attrs[key].to_s.strip
        # TODO: This is an abominable check for a float
        if val.include? '.'
          ret.concat(sprintf("%.5f", val) + " ")
        else
          ret.concat("#{val} ")
        end
      end          
      ret.concat("; #{@name}")
      if @to_s_with_debug_info 
        ret.concat(" #{@player_id}")    # For debugging  
        ret.concat(" #{@ensemble_id}")  # For debugging                      
        ret.concat(" #{@score_id}")     # For debugging
      end
      ret
    # Used only for unit testing, to verify data in note is as expected. Not actually used to render MIDI file output
    when :midi
      ret = ""
      @ordered_keys.each do |key|
        val = @note_attrs[key].to_s.strip
        ret.concat("#{key.to_s.strip}")
        # TODO: This is an abominable check for a float
        
        if val.include? '.'
          ret.concat(sprintf(" %.5f", val) + "  ")
        else
          ret.concat(" #{val}  ")
        end
      end
      ret.chop!
      ret.concat("; #{@name}")
      ret.concat("  #{@player_id}") if self.respond_to? :player_id
      ret.concat("  #{@player}") if self.respond_to? :player
      ret
    end    
  end
  
  def Note.new_rest(dur, chan=NO_CHANNEL)
    rest_note = Note.new
    rest_note.instrument 0
    rest_note.start 0.0
    rest_note.duration dur 
    rest_note.amplitude 0
    if $FORMAT == :csound
      rest_note.pitch 5.01
      rest_note.func_table 1
    else # if $FORMAT == :midi
      rest_note.pitch 1
      rest_note.channel chan
    end
    rest_note
  end

  # Creates accessors for newly created attributes of the object
  def method_missing(name, val=nil)
    @note_attrs[name] = val
    @ordered_keys << name unless @ordered_keys.include? name
    def_accessor name
  end
  
  private
  def def_accessor(name)
    self.class.class_eval %Q{
      def #{name}(val=nil)
        if val == nil then
          @note_attrs[:#{name}]
        else
          @note_attrs[:#{name}] = val
          self
        end
      end
    }
  end
  public
  
end


end
