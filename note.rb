module CSnd

# Note and NoteTest #######################

=begin RDoc
1. This class represents a musical Note in CSound.  Defines the basic required parameters of a CSound notes as instance attributes: instrument, start time, duration, amplitude and pitch.  
2. Supports syntax to retrieve values asproperties.  
3. Supports chained invocation of set calls, DSL style.  
4. Users can add properties to an instance dynamically.  The class maintains attributes in order added, because string output is in format of a line in a CSound score and must maintain this order to be valid.

Ex. of ctor and set calls:
<tt>note = Note.new.instr(1).dur(3.0).amp(4).pitch(5.0)</tt>

Ex. of get calls property style:
<tt>my_instr = note.instr</tt>
=end
class Note
  
  NUM_DEFAULT_ATTRS = 5
  @@id_counter = -1
  
  attr_reader :nid # , :player
  # attr_writer :player
  
  # This is an enumerable class; it defines an each iterator below.
  include Enumerable   # Include the methods of this module in this class  

=begin RDoc
ctor
=end
  def initialize (instrument=nil, start=nil, duration=nil, amplitude=nil, pitch=nil)
    # @note_attrs stores named properties of the Note. 
    # @ordered_keys maintains output order for to_s()
    @note_attrs = {
      :instrument => instrument, 
      :start => start, 
      :duration => duration, 
      :amplitude => amplitude, 
      :pitch => pitch}
	
    @note_custom_attrs = Hash.new

    @ordered_keys = [:instrument, :start, :duration, :amplitude, :pitch]
  
    # Assign the note a unique_id, this is obviously cheesy and not thread safe, but fine for now
	@nid = @@id_counter + 1
	@@id_counter = @nid
    @player_id = -1
  end
  
=begin RDoc
Writes a rest, a note with amp = 0
=end
  def Note.rest(note, duration, player_id)
    note.dup.player_id(player_id).dur(duration).amp(0)
  end

  # Sets the player_id of the Note, that is the Player which has the phrase in which the 
  #  Note lives.  Supports partitioned output
  def player_id(player_id=nil)
    if player_id == nil      
      return @player_id
    else   
      @player_id = player_id
      return self
    end
  end
  
=begin RDoc
Get or set instrument that the Note plays.
=end
  def instrument(instrument=nil)
    # Note the hack here to support chained DSL style set calls and property
    #  style get calls.  This approach avoids a problem with using the Ruby
    #  lang supported attr() attr=() syntax, which is ambiguous when calls are
    #  chained and fails.
    # If this is a get call, no arg passed, so return attr value
    if instrument == nil
      return @note_attrs[:instrument]
    # Else if this is a set call, arg passed, set new attr value and return self
    else
      @note_attrs[:instrument] = instrument
      return self
    end
  end
  alias instr instrument

=begin RDoc
Get or set start time value of the Note.
=end
  def start(start=nil)
    if start == nil
      return @note_attrs[:start]
	elsif start < 0.0
      @note_attrs[:start] = 0.0
	  return self
    else
      @note_attrs[:start] = start
	  return self
    end	
  end
  
=begin RDoc
Get or set duration value of the Note.
=end
  def duration(duration=nil)
    if duration == nil
      return @note_attrs[:duration]
    else
      @note_attrs[:duration] = duration
      return self
    end
  end
  alias dur duration
  
=begin RDoc
Get or set amplitude value of the Note
=end
  def amplitude(amplitude=nil)
    if amplitude == nil
      return @note_attrs[:amplitude]
    else
       
      # TEMP DEBUG
      # puts "big amp boost #{amplitude}, player = #{self.player_id}" if amplitude > 750
    
      @note_attrs[:amplitude] = amplitude
      return self
    end 
  end
  alias amp amplitude
  
=begin RDoc
Get or set pitch value of the Note
=end
  def pitch(pitch=nil)
    if pitch == nil
      return @note_attrs[:pitch]
    else  
      @note_attrs[:pitch] = pitch
      return self
    end
  end    

=begin RDoc
Adds a new attr to the Note. Adds it by key name in correct key order, that is, it appends it to the end of the curent set of attrs.  If init_val is non-nil, attr will be initialized with that value.
=end  
  def add_attr(attr_name, init_val=nil)
    # Normalize all keys to symbols internally
    attr_name = attr_name.to_sym
    # Update ordered_keys by appending new key to the end of the list
    @ordered_keys = @ordered_keys.push(attr_name) if not @ordered_keys.include?(attr_name)
    # Add the key/value pair to support key based access
    @note_attrs.merge!({attr_name => init_val})
    
    # Append a new named getter/setter method named for key
	# TODO Switch to %Q{} style of string so we can layout def/end to be indented like code
    code = "def #{attr_name}(#{attr_name}=nil); if #{attr_name} == nil then return @note_attrs[:#{attr_name}] end; @note_attrs[:#{attr_name}] = #{attr_name}; return self; end"    
    self.class.class_eval code

    return self
  end

=begin RDoc
Allows addition of a new attr to this Note at runtime.  Used for example to modify particular
Notes to be legato, by passing an attribute and the block that is its implementation, which
in the case of legato stretches the duration and adjusts the start time
=end
  def add_custom_attr(attr_name, &attr_block) 
    attr_name = attr_name.to_sym
    @ordered_keys = @ordered_keys.push(attr_name) if not @ordered_keys.include?(attr_name)
    # Custom attrs are understood to be derived from other Note attrs, so default value is nil
    @note_attrs.merge!({attr_name => nil})
    # Store the name of the attribute and its implementation, so client can call apply_custom_attrs()
    #  and call send() on each custom_attr added to modify this instance of Note
    #  and so dup() can add these dynamically added methods to copies of this instance
    self.class.class_eval {define_method(attr_name, &attr_block)}
    @note_custom_attrs[attr_name] = self.method(attr_name)
    return self
  end

=begin RDoc
Cycle through each custom attributes and call each one
=end
  def apply_custom_attrs
    @note_custom_attrs.each_value {|v| v.call}
  end

=begin RDoc
Returns the attrs of the Note in order. Base attrs are in order required by CSound. Additional attrs are in order added.  This lets client get a list of attrs in this instance. It also, in conjuntion with attrs, lets  the user iterate a Hash of the attrs in key order to retrieve/inspect the  values in key order.
=end
  def ordered_keys
    @ordered_keys
  end

=begin RDoc
Returns the values of the Note in order. Base attrs are in order required by CSound. Additional attr values are in order added.  This lets client get a list of attr values in this instance.
=end
  def ordered_vals
    @ordered_keys.collect do |key|
      if @note_attrs.has_key? key
        @note_attrs[key]
      else
        @note_custom_attrs[key].call
      end
    end
  end  

=begin RDoc
The attrs of the Note, in the form of a Hash.  Note that Hash is unordered by key, so to traverse in ordered fashion this should be used in conjuntion with ordered_keys.
=end
  def attrs
    @note_attrs.clone
  end

  def custom_attrs
    @note_custom_attrs.clone
  end

=begin RDoc 
This is the iterator required by the Enumerable module
=end
def each
  @ordered_keys.each do |key|
    if @note_attrs.has_key? key
      yield key, @note_attrs[key]
    else
      yield key, @note_custom_attrs[key].call
    end
  end
end

=begin RDoc
Returns the number of attributes the Note has
=end
def length
  @ordered_keys.length
end
alias size length

=begin RDoc
Returns a string representation of the Note that is formatted to be included in a CSound Score file   
=end
  def to_s
    ret = "i "    
    @ordered_keys.each do |key|
      val = @note_attrs[key].to_s.strip	  
      if val.include? '.'
        ret.concat(sprintf("%.3f", val) + " ")
      else
        ret.concat("#{val} ")
      end	  
    end
    # Concat the note's player id for debugging ease. TODO parameterize turning this off
    # TODO Now actually experimenting with this as note param to pan player output left to right
	# ret.concat("    ; player id: #{self.player_id}")
    ret.concat("#{self.player_id} ")
	# ret.chomp(" ")
  end
  alias print to_s;

=begin RDoc
Returns a deep copy of the note
=end
  def dup
    note = Note.new
    note.
      instr(self.instr).
      start(self.start).
      dur(self.dur).
      amp(self.amp).
      pitch(self.pitch).
      player_id(self.player_id)
    if @ordered_keys.length > 5
      # range op with three dot is half-open interval, not including right side val
      for j in 5...@ordered_keys.length
        note.add_attr(@ordered_keys[j], @note_attrs[@ordered_keys[j]]) if not @note_custom_attrs.has_key? @ordered_keys[j] 
      end          
    end

 	@note_custom_attrs.each do |k, v| 
	  # NOTE: Need to use & operator on the v arg, which was passed in a block but
	  #  then converted to a Proc by the original call to add_custom_attr(x, &y)
	  #  by the & operator on the arg y.  Need to thus use the & on the call here
	  #  to convert the Proc back into a block or you get an error of passing 2 args
	  #  when 1 is expected. Ruby signature lists &y in the def signature, but the
	  #  method actually expects the block to be passed external to the arguments
	  #  and it doesn't count as an argument to the signature
	  note.add_custom_attr(k, &v) 
	end
    
    note
  end
  
  def ==(rhs)
    rhs.ordered_keys == @ordered_keys &&
    rhs.attrs == @note_attrs &&
    rhs.custom_attrs == @note_custom_attrs
  end

end
# /Note and NoteTest #######################

end  
#/CSnd Module