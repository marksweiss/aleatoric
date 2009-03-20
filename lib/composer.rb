require 'score'
require 'singleton'

module Aleatoric

# State
class CollectionState
  attr_accessor :cls
  attr_reader :items, :items_map
  
  def initialize
    @state = false
    @pub_state = false
    @items = []
    @published_items = []
    @items_map = {}
  end
  
  #def cls(cls=nil)
  #  @cls = cls unless cls == nil
  #  @cls
  #end
    
  # Add one or more at a time
  def add(*items)
    items.each {|item| @items << item}
  end

  # Supports client classes that want to store instances by key, assumes the associated values
  #  should only be stored at all if the key is unique -- otherwise hash and list out of sync
  def add_by_key(key, item)
    if not @items_map.include? key
      @items_map[key] = item
      add item
    end
  end
  
  def [](key)
    return @items_map[key]
  end
  
  def items
    @items
  end
  
  def items_map
    @items_map
  end
  
  def last
    @items.last
  end
  
  def on?
    @state == true
  end
  
  def on!
    @state = true
  end
  
  def off!
    @state = false
  end
  
  def published?
    @pub_state == true
  end
    
  def publish  
    # Notes are copied into the published buffer and cleared at
    #  the start of each "add" block
    # Duck-type requirement here, item type @cls must implement dup()
    @published_items = @items.collect {|item| item.dup}    
    @items = []
    @pub_state = true
  end
  
  def unpublish
    @pub_state = false    
    @published_items = []
  end
  
  def subscribe(obj)
    obj << @published_items
  end
  
  def to_s
    @items.each {|i| i.to_s}
    @published_items.each {|i| i.to_s}
  end
end

# State management of entities being declared and added to each other in "add" blocks
@note_state = CollectionState.new
@note_state.cls = Note.class
@phrase_state = CollectionState.new
@phrase_state.cls = Phrase.class
@section_state = CollectionState.new
@section_state.cls = Section.class

# "add" Event types, these are things that can be added
@nil_event = :nil_event
@note_event = :note_event
@phrase_event = :phrase_event    
@section_event = :section_event    


################################################
# Composer language keyword handlers and helpers

# handles Note file line keyword "note," construct new Note, makes it current Note
def note(name=nil)
  @note_state.add Note.new
  @note_state.on!
  @note_state.unpublish
end

# handles keyword "phrase" which should always be a target of an "add" of "notes"
def phrase(*names)
  names.each do |name|    
    # If it's the target of an "add" block, it's adding published notes
    # Each name is a phrase in the list next to "phrase", each is adding the notes
    if @note_state.published?
      # Phrases can be declared for the first time in an add block, as add target
      @phrase_state.add_by_key(name, Phrase.new)      
      @note_state.subscribe(@phrase_state[name])
    else
      # It's a standard phrase block declaring phrase and 
      #  setting attributes (in method missing), triggered by turning state on
      @phrase_state.add_by_key(name, Phrase.new)
      @phrase_state.on!
    end
  end
end

# handles keyword "section" which should always be a target of an "add" of "notes" or "phrases"
def section(*names)
  names.each do |name|
    # Sections can add notes or phrases in "add" block
    if @note_state.published?
      @section_state.add_by_key(name, Section.new)  
      @note_state.subscribe(@section_state[name])
    end
    if @phrase_state.published?
      @section_state.add_by_key(name, Section.new)  
      @phrase_state.subscribe(@section_state[name])
    else
      # It's a standard phrase block declaring section and setting attributes
      @section_state.add_by_key(name, Section.new)
      @section_state.on!
    end
  end
end

# handles keyword "notes" which just passes a in indicator to "add" so add knows what
#  type of entity is being added to the targets of the add
def notes
  @note_event
end
# handles keyword "phrases" which passes an event indicator to "add"
def phrases
  @phrase_event
end

# handles "add" keyword, which moves some stored state referred to as arg to add
#  into targets which are listed one entity call to a line after the dummy keyword "to"
#
# add notes
# to
#   phrases "1", "2", "33"
def add(event)
  if event == @note_event
    # Copy notes built up since last add() call into a buffer for targets of add() to copy
    @note_state.publish
    # Turn off state so that method_missing won't call Note.method_missing in add() block    
    @note_state.off!
  elsif event == @phrase_event
    @phrase_state.publish
    @phrase_state.off!
  elsif event == @section_event
    @section_state.publish
    @section_state.off!    
  end
end

# handles all other Note file line keywords, adds name val as attr to curent Note
def method_missing(name, *args)
  # TEMP DEBUG
  # puts @note_state.last
  # puts "@note_state == nil  #{@note_state == nil}" 
  # puts "method_missing() name =  #{name}" if @note_state == nil
  # return if @note_state == nil
  # puts "method_missing() @note_state.on?aaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa@note_state.on?}"
  # puts "method_missing() args[0] #{args[0]}"
  
  # Other handlers for other entities, e.g. Players, Ensembles, Scores, Instruments
  @note_state.last.method_missing(name, args[0]) if @note_state.on?
  @phrase_state.last.method_missing(name, args[0]) if @phrase_state.on?
  @section_state.last.method_missing(name, args[0]) if @section_state.on?
end

def csound; :csound; end
def format; :format; end
def write(fmt_map)
  fmt = fmt_map[:format]
  if fmt == :csound
    puts 'PHRASES'  
    @phrase_state.items_map.each do |k, v|
      puts "\n" + k.to_s + "\n" + "\n"
      puts v.to_s
    end
    puts 'SECTIONS'  
    @section_state.items_map.each do |k, v|
      puts "\n" + k.to_s + "\n" + "\n"
      puts v.to_s
    end    
  end    
end

end