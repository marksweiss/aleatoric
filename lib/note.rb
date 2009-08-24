module Aleatoric

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
  attr_accessor :name
  attr_reader :ordered_keys, :note_attrs

  def initialize(name=nil, format=nil, attrs=nil)
    @name = name
    @note_attrs = {}
    @@format = format || :csound
    case @@format
    when :csound
      # @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]
    when :midi
      # @ordered_keys = [:channel, :pitch, :duration, :velocity, :time]
    end 
    attrs ||= {}
    attrs.each {|name, val| self.method_missing(name, val)}  
  end
  
  # Returns a deep copy of the object
  def dup
    ret = Note.new
    ret.name = self.name
    @note_attrs.each {|name, val| ret.method_missing(name, val)}
    ret
  end  
  
  # Set to_s appropriately based on output format
  # Adds a to_s definition to the class based on format value passed to class method
  def Note.to_s_format=(format)
    @@format = format.to_sym
  end
  def Note.to_s_format
    @@format
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
      ret
    # TODO This is useless
    when :midi
      ret = ""
      @ordered_keys.each do |key|
        val = @note_attrs[key].to_s.strip	
        ret.concat("#{val} ")
      end
      ret
    end    
  end

  # Creates accessors for newly created attributes of the object
  def method_missing(name, val)
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
