$LOAD_PATH << "..\\lib"
require 'util'
require 'score'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

module Aleatoric

# Player has a score of notes that he is currently choosing to play from
# Player tests pre-play hooks for each note for each note property and applies result
#  to each note before playing it
# Player tests post-play hooks for each note for each note property and applies result
#  to each note after playing it
# Player may adjust other internal state based on supplies hooks
#  - not playing
#  - filtering certain sections, phrases or measures
#  - improvising

# Fields
# - current score - sections, phrases, measures
# - registered pre-play hooks for symbols which name valid Note properties
# - registered post-play hooks for symbols which name valid Note properties
# - is_playing state
# - is_improvising state
# - improvising hook function to generate notes

# Methods
# Public
# (DONE)- add/delete current score
# (DONE)- play
# (DONE)- add pre-play hook by a key name
# (DONE)- remove pre-play hook by a key name
# (DONE)- get pre-play hook by key name
# (DONE)- add post-play hook by a key name
# (DONE)- remove pre-play hook by a key name
# (DONE)- get post-play hook by key name# - set state by a key name
# (DONE)- set state by a key name
# (DONE)- get state by a key name
# (DONE)- playing?
# (DONE)- playing?
# (DONE)- improvising?
# (DONE)- improvising?
# (DONE)- add improvising hook by a key name
# (DONE)- remove improvising hook by a key name
# (DONE)- get improvising hook by key name
# Private
# - run pre-play hook by a key name
# - run post-play hook by a key name

class Player

  attr_accessor :ensemble, :name
  attr_accessor :scores, :scores_ordered_names, :scores_idx
  attr_accessor :preplay_hooks_ordered_names, :postplay_hooks_ordered_names, :improvising_hooks_ordered_names
  attr_accessor :state, :is_playing, :is_improvising, :out_notes
  attr_accessor :preplay_hooks, :postplay_hooks, :improvising_hooks
  
  @@NO_INDEX = -1
  def Player.no_index
    @@NO_INDEX
  end
  
  def initialize(name)
    @name = name
    @scores = {}
    @scores_idx = 0
    @scores_ordered_names = []
    @preplay_hooks_ordered_names = []
    @preplay_hooks = {}
    @postplay_hooks_ordered_names = []
    @postplay_hooks = {}
    @improvising_hooks_ordered_names = []
    @improvising_hooks = {}
    @state = {}
    @is_playing = true
    @is_improvising = false    
    @out_notes = []
  end
  
  def add_score(name, score)
    @scores[name] = score
    @scores_ordered_names << name
    # If there were no scores, set index to new first score
    @scores_idx = 0 if @scores_idx == -1
    self
  end
  alias append_score add_score
    
  def remove_score(score_name)
    dead_score = nil
    @scores_ordered_names.each do |name|
      if name == score_name
        dead_score = @scores[score_name]
        break
      end
    end
    # If score_idx is on last position and we're deleting that position, move it into a valid position
    @scores_idx -= 1 if @scores_idx == @scores.length - 1
    @scores.delete dead_score
    @scores_ordered_names.delete score_name
    self
  end
  alias delete_score remove_score
  
  def set_score(score_name, score)
    # Start out in invalid position and index for each score until we match
    idx = -1
    @scores_ordered_names.each do |name|
      idx += 1
      break if name == score_name
    end
    @scores[score_name] = score if valid_scores_idx? idx
  end
  
  def clear_scores
    @scores.clear
    @scores_ordered_names.clear
    @scores_idx = -1
    self
  end
  
  def scores_length
    @scores_ordered_names.length
  end
  alias scores_size scores_length
  
  def scores_empty?
    @scores_ordered_names.length == 0
  end
  
  def scores_index
    @scores_idx
  end
  alias phrases_index scores_index

  def current_score
    @scores[@scores_ordered_names[@scores_idx]] if valid_scores_idx? @scores_idx
  end
  alias current_phrase current_score
  
  def increment_scores_index
    @scores_idx +=1 if valid_scores_idx?(@scores_idx + 1)
    self
  end
  alias increment increment_scores_index
  alias inc increment_scores_index

  def decrement_scores_index
    @scores_idx -=1 if valid_scores_idx?(@scores_idx - 1)
    self
  end
  alias decrement decrement_scores_index
  alias dec decrement_scores_index  
  
  # TODO Regression unit testing
  def play(name=nil, &blk)
    ret = []
    # NOTE: Default is to NOT change the state of score but to make a copy for each play call.
    #  Client can call
    cur_score = @scores[name] if name != nil
    cur_score = current_score if name == nil
    cur_score = cur_score.dup
        
    # NOTE: hooks can have whatever side effects they want, based on the access they have through
    #  the Player public API.  But barring that the promise the class makes in play() is like a 
    #  a functional map idea -- each hook is called, in order, and transforms the current state
    #  of the current score and passes that to the next hook    
    @preplay_hooks_ordered_names.each do |hook_name|
      cur_score = @preplay_hooks[hook_name].call(self, cur_score)    
    end
    
    # If user passed in additional one-time-only block for this play() call, run it on current score
    cur_score = blk.call cur_score if block_given?
    
    # Now push the notes cur_score to output. Store added notes just from
    #  this play() call in separate step to return them for client convenience, testing
    cur_score.notes.each do |note| 
      note = note.dup
      ret << note
      @out_notes << note
    end
    
    # Now run postplay hooks. 
    # NOTE: These make no promise as far as manipulating the current_score.  These rely on the
    #  Player API and the client simply must implement whatever logic they want.  Only promise
    #  here is they'll get called by each play() call AFTER notes are written to output.
    # Typical use would be get_state()/set_state() and perhaps also manipulate the score or
    #  the score_index. The *state() calls are the generic API for holding state between play() calls
    # Must pass in reference to containing object since method was passed in from outside this object as lambda
    @postplay_hooks_ordered_names.each do |hook_name|
      @postplay_hooks[hook_name].call self
    end    
    
    # Also return the notes written, for client convenience in case they want a local copy, 
    #  and, more so, for convenience of unit testing
    ret
  end
  
  def improvise(name)
    ret = []    
    return ret if @improvising_hooks.empty? or not @improvising_hooks.include? name    
    @improvising_hooks[name].call.notes.each do |note| 
      @out_notes << note
      ret << note.dup
    end
    ret
  end
  
  def add_preplay_hook(name, &f)
    @preplay_hooks_ordered_names << name
    @preplay_hooks[name] = f    
    self
  end
  
  def remove_preplay_hook(name)
    @preplay_hooks_ordered_names.delete(name)
    @preplay_hooks.delete(name)
    self
  end
  
  def get_preplay_hook(name)
    @preplay_hooks[name]
  end

  def add_postplay_hook(name, &f)
    @postplay_hooks_ordered_names << name
    @postplay_hooks[name] = f    
    self
  end
  
  def remove_postplay_hook(name)
    @postplay_hooks_ordered_names.delete(name)
    @postplay_hooks.delete(name)
    self
  end
  
  def get_postplay_hook(name)
    @postplay_hooks[name]
  end
  
  def add_improvising_hook(name, &f)  
    @improvising_hooks_ordered_names << name
    @improvising_hooks[name] = f
    self
  end
  alias add_improvisation_hook add_improvising_hook
  
  def remove_improvising_hook(name)
    @improvising_hooks_ordered_names.delete(name)
    @improvising_hooks.delete(name)
    self
  end
  alias remove_improvisation_hook remove_improvising_hook
  
  def get_improvising_hook(name)
    @improvising_hooks[name]
  end
  alias get_improvisation_hook get_improvising_hook
  
  # Store a value by keyname, generic interface for hooks to store state for later use
  # Supports a network of hooks working togther with shared state in this generic design
  def set_state(key, val)
    @state[key] = val
    self
  end
  
  def get_state(key)
    @state[key]
  end
  
  def clear_state
    @state.clear
    self
  end
  
  def state_keys
    @state.keys
  end
  
  # Default in initialize() is true
  def playing?(is_playing=nil)
    @is_playing = is_playing if is_playing != nil
    @is_playing
  end

  # Default in initialize() is false
  def improvising?(is_improvising=nil)
    @is_improvising = is_improvising if is_improvising != nil
    @is_improvising
  end
  
  def get_output
    ret = []
    @out_notes.each {|note| ret << note.dup}
    ret
  end
  alias output get_output
  
  def set_output_notes(notes)
    @out_notes.clear
    notes.each {|note | @out_notes << note}
    self
  end
  alias set_output set_output_notes
  
  def append_note_to_output(note)
    @out_notes << note.dup
  end
  
  def append_score_to_output(score)
    score.notes.each {|note| @out_notes << note.dup}
  end
  
  def output_empty?
    @out_notes.length == 0
  end
  
  def clear_output
    @out_notes.clear
    self
  end
  
  def dup  
    ret = Player.new(self.name)
    
    @scores.keys.each do |score_name| 
      add_score = @scores[score_name].dup      
      ret.add_score(add_score.name, add_score)
    end
    
    # TODO - CHANGE THIS BACK TO self.* now that there are accessors
    ret.scores_ordered_names = @scores_ordered_names
    ret.scores_idx = @scores_idx
    ret.preplay_hooks_ordered_names = @preplay_hooks_ordered_names
    ret.postplay_hooks_ordered_names = @postplay_hooks_ordered_names
    ret.improvising_hooks_ordered_names = @improvising_hooks_ordered_names
    ret.state = @state
    ret.is_playing = @is_playing
    ret.is_improvising = @is_improvising    
    @out_notes.each {|note| ret.out_notes << note.dup}
    ret.preplay_hooks = @preplay_hooks
    ret.postplay_hooks = @postplay_hooks
    ret.improvising_hooks = @improvising_hooks
    
    ret
  end
  
  private
  def valid_scores_idx?(idx)
     idx >= 0 and idx < @scores.length
  end
    
end

end

