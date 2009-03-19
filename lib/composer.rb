require 'score'
require 'singleton'

module Aleatoric

# State
class NoteState
  include Singleton
  
  def initialize
    @state = false
    @pub_state = false
    @notes = []
    @published_notes = []
  end
  
  def add_note
    @notes << Note.new
  end
  
  def last
    @notes.last
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
    #  the start of each add block    
    @published_notes = @notes.collect {|note| note.dup}    
    @notes = []
    @pub_state = true
  end
  
  def unpublish
    @pub_state = false    
    @published_notes = []
  end
  
  def subscribe(obj)  
    obj << @published_notes
  end
  
  def to_s
    @notes.each {|n| n.to_s}
    @published_notes.each {|n| n.to_s}
  end
end
@note_state = NoteState.instance

@phrases = {}

@event_type = :event_type
@nil_event = :nil_event
@note_event = :note_event
@phrase_event = :phrase_event    

    
# Composer language keyword handlers and helpers

# handles Note file line keyword "note," construct new Note, makes it current Note
def note 
  @note_state.add_note
  @note_state.on!
  @note_state.unpublish
end

# handles keyword "phrase" which should always be a target of an "add"
def phrase(*names)
  names.each do |name|     
    @phrases[name] = Phrase.new unless @phrases.include? name        
    @note_state.subscribe(@phrases[name]) if @note_state.published?        
  end
end

# handles keyword "notes" which just passes a in indicator to "add" so add knows what
#  type of entity is being added to the targets of the add
def notes
  @note_event
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
  end
end

# handles all other Note file line keywords, adds name val as attr to curent Note
def method_missing(name, *args)
  # TEMP DEBUG
  # puts "name #{name}"
  # puts "@note_state.on? #{@note_state.on?}"
  # puts "args[0] #{args[0]}"
  
  # Other handlers for other entities, e.g. Players, Ensembles, Scores, Instruments
  @note_state.last.method_missing(name, args[0]) if @note_state.on?
end

def csound; :csound; end
def format; :format; end

def write(fmt_map)
  fmt = fmt_map[:format]
  @phrases.keys.each {|k| puts @phrases[k].to_s} if fmt == :csound
end


end