$LOAD_PATH << psub("../lib")
require 'util'
require 'score'

require 'rubygems'
# TEMP DEBUG
# require 'ruby-debug' ; Debugger.start

module Aleatoric

# Player has a score of notes that it is currently choosing to play from.
# Player tests pre-play hooks for each note for each note property and applies result
# to each note before playing it.
# Player tests post-play hooks for each note for each note property and applies result
# to each note after playing it.
# Hooks may manipulate Player internal state based on the available methods: #playing?, #improvising?
# Hooks may use the #set_state and #get_state methods as a key/value "property bag" to
# store and retrieve data as needed.  This lets, for example, preplay hooks leave state to be
# tested and set by postplay hooks, and vice versa.
class Player

  attr_accessor :ensemble, :name
  attr_accessor :scores, :scores_ordered_names, :scores_idx
  attr_accessor :preplay_hooks_ordered_names, :postplay_hooks_ordered_names, :improvising_hooks_ordered_names
  attr_accessor :preplay_hooks, :postplay_hooks, :improvising_hooks
  attr_accessor :state, :is_playing, :is_improvising, :out_notes
  attr_accessor :current_start # Made this read/write becasue reset by player_test.rb
  attr_reader :total_loops   # VERBOSE
  
  @@NO_INDEX = -1
  def Player.no_index
    @@NO_INDEX
  end
  
  # Ctor
  # @param [String] name of the Player
  def initialize(name, instrument=nil, channel=nil)
    @name = name
    @instrument = instrument
    @channel = channel
    @default_volume = nil
    @scores = {}
    @scores_idx = -1
    @scores_ordered_names = []
    @preplay_hooks_ordered_names = []
    @preplay_hooks = {}
    @postplay_hooks_ordered_names = []
    @postplay_hooks = {}
    @improvising_hooks_ordered_names = []
    @improvising_hooks = {}
    @state = {}
    @is_playing = true
    @is_improvising = true    
    @out_notes = []
    @current_start = 0.0
    @auto_next_start = true
  end
  
  def handle
    self.object_id
  end
  
  def instrument(instrument=nil)
    if instrument == nil
      @instrument
    else
      @instrument = instrument
      self
    end
  end
  
  def channel(channel=nil)
    if channel == nil
      @channel
    else
      @channel = channel
      self
    end
  end
  
  def default_volume(volume=nil)
    if volume == nil
      @default_volume
    else
      @default_volume = volume
      self
    end
  end
  
  # Add a score to the Player's list of scores.  Note the scores are added by key
  # but also stored in order they are added.  Clients can call #play by passing
  # a score name, but they can also use the #increment_scores_index and decrement ...
  # methods along with #scores_length to iterate the scores in order and play them.
  # NOTE: MIDI scores added have all notes set channel to this player's channel
  # @param [String] name of the Aleatoric::Score object being added
  # @param [Aleatoric::Score] the score object being added
  def add_score(score_name, score)
    # Append player name and id to each note for debugging
    dup_score = set_added_score_note_attrs score
    @scores[score_name] = dup_score
    @scores_ordered_names << score_name
    # If there were no scores, set index to new first score
    @scores_idx = 0 if @scores_idx == -1
    self
  end
  alias append_score add_score
  alias append_phrase add_score
  alias add_phrase add_score
    
  # Remove a score from the Player's list of scores.
  # @param [String] name of the Aleatoric::Score object being removed
  # @return [self]
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
  alias remove_phrase remove_score
  alias delete_phrase remove_score
  
  # Replace (update) a score in the Player's list of scores.
  # @param [String] name of the Aleatoric::Score object being replaced
  # @param [Aleatoric::Score] the score object being added in place of the previous
  # score object stored under this score_name
  # @return [self]
  def set_score(score_name, score)
    # Start out in invalid position and index for each score until we match
    idx = -1
    @scores_ordered_names.each do |name|
      idx += 1
      break if name == score_name
    end
    if valid_scores_idx? idx
      set_score_channel score
      # For debugging
      dup_score = set_added_score_note_attrs score
      @scores[score_name] = dup_score 
    end
    self
  end
  alias set_phrase set_score
  
  def set_current_score(score_name)
    # Start out in invalid position and index for each score until we match
    idx = -1
    @scores_ordered_names.each do |name|
      idx += 1
      if name == score_name
        @scores_idx = idx
        break
      end
    end
    self
  end
  alias set_current_phrase set_current_score
  
  # Clear all scores stored by this Player
  # @return [self]
  def clear_scores
    @scores.clear
    @scores_ordered_names.clear
    @scores_idx = -1
    self
  end
  alias clear_phrases clear_scores

  # Clients can call #play by passing
  # a score name, but they can also use the #increment_scores_index and decrement ...
  # methods along with #scores_length to iterate the scores in order and play them. 
  # @return [Integer] the number of scores currently stored by this Player
  def scores_length
    @scores_ordered_names.length
  end
  alias scores_size scores_length
  alias phrases_length scores_length
  alias phrases_size scores_length
  
  # @return [true, false] indicates whether the Player currently stores any scores
  def scores_empty?
    @scores_ordered_names.length == 0
  end
  alias phrases_empty? scores_empty?
  
  # Clients can call #play by passing
  # a score name, but they can also use the #increment_scores_index and decrement ...
  # methods along with #scores_length to iterate the scores in order and play them.  
  # @return [Integer] the number of the currently active scores in the ordered list of scores stored by this Player
  def scores_index
    @scores_idx
  end
  alias phrases_index scores_index

  # @return [Aleatoric::Score] a reference to the currently active score
  def current_score
    @scores[@scores_ordered_names[@scores_idx]] if valid_scores_idx? @scores_idx
  end
  alias current_phrase current_score
  
  # Increments the index of the currently active scorein the ordered list of scores
  # stored by this Player.  Clients can call #play by passing
  # a score name, but they can also use the #increment_scores_index and decrement ...
  # methods along with #scores_length to iterate the scores in order and play them.  
  # @return [self]
  def increment_scores_index
    @scores_idx +=1 if valid_scores_idx?(@scores_idx + 1)
    self
  end
  alias increment increment_scores_index
  alias inc increment_scores_index
  alias increment_phrases_index increment_scores_index

  # Decrements the index of the currently active scorein the ordered list of scores
  # stored by this Player.  Clients can call #play by passing
  # a score name, but they can also use the #increment_scores_index and decrement ...
  # methods along with #scores_length to iterate the scores in order and play them.  
  # @return [self]
  def decrement_scores_index
    @scores_idx -=1 if valid_scores_idx?(@scores_idx - 1)
    self
  end
  alias decrement decrement_scores_index
  alias dec decrement_scores_index  
  alias decrement_phrases_index decrement_scores_index

  # By default Player will make sure each note starts after the last one, which is very useful
  #  for using players in real long-running compositions.  User can override this behavior
  #  by calling auto_next_start_off, and then the player will output notes with their given start time
  def auto_next_start_on
    @auto_next_start = true
  end
  def auto_next_start_off
    @auto_next_start = false
  end
  
  # Plays the currently active score, which means, precisely:
  # - set current score to the name argument passed, if name is not nil
  # - set current score to self's current_score if name arg is nil
  # - make a copy of the current score so as to not modify the object held by self
  # - pass the current score copy as input to each preplay hook, recieve the modified
  # score from the hook in return, and pass this to the next hook
  # - run any block on the resulting score if one #block_given? is true
  # - add all notes in the resulting score to the output notes for self
  # - run any postplay hooks
  # @param [String, nil] the name of the score to play
  # @param [block, nil] a block to apply to the current score after preplay hooks are run
  # @return [Array<Aleatoric::Note>] the notes generated from this call to play()
  def play(name=nil, &blk)    
    
    # VERBOSE
    @total_loops = 0 if @total_loops.nil?
    @total_loops += 1
    # puts "#{self.name}\t\tTotal Loops: #{@total_loops}"
    # /VERBOSE    
    
    ret = []
    return ret if not playing?
    # NOTE: Default is to NOT change the state of score but to make a copy for each play call.
    #  Client can call    
    cur_score = @scores[name] if name != nil
    cur_score = self.current_score() if name == nil      
    cur_score = cur_score.dup
                
    # NOTE: hooks can have whatever side effects they want, based on the access they have through
    #  the Player public API.  But barring that the promise the class makes in #play is like a 
    #  a functional map idea -- each hook is called, in order, and transforms the current state
    #  of the current score and passes that to the next hook        
    @preplay_hooks_ordered_names.each do |hook_name|
      cur_score = @preplay_hooks[hook_name].call(self, cur_score)    
    end
    
    # If user passed in additional one-time-only block for this #play call, run it on current score
    cur_score = blk.call cur_score if block_given?
    
    # Now push the notes cur_score to output. Store added notes just from
    #  this #play call in separate step to return them for client convenience, testing
    cur_score.notes.each do |note|
      dup_note = set_added_note_attrs note       
      # NOTE: This is a very important business rule on this line, namely that Player silently pushes
      #  the start time of notes ahead of their literal value.  Modified this because it broke a test
      #  which pointed out the subtle issue that it should really only do this if the new note is before
      #  the current Player start time. So added the if check.
      if @auto_next_start and dup_note.start <= @current_start
        # if the new note start is < current_start, treat it as an offset from current_start
        dup_note.start(dup_note.start + @current_start)
      end      
      # and move the offset forward past the end of the current note
      @current_start += dup_note.duration        

      ret << dup_note
      @out_notes << dup_note            
    end
            
    # Now run postplay hooks. 
    # NOTE: These make no promise as far as manipulating the current_score.  These rely on the
    #  Player API and the client simply must implement whatever logic they want.  Only promise
    #  here is they'll get called by each #play call AFTER notes are written to output.
    # Typical use would be #get_state/#set_state and perhaps also manipulate the score or
    #  the score_index. The #*state calls are the generic API for holding state between #play calls
    # Must pass in reference to containing object since method was passed in from outside this object as lambda
    @postplay_hooks_ordered_names.each do |hook_name|
      @postplay_hooks[hook_name].call self
    end    
    
    # Also return the notes written, for client convenience in case they want a local copy, 
    #  and, more so, for convenience of unit testing    
    ret
  end
  
  # Runs the improvisation hook registered with the name arg to generate output notes.
  # @param [String] name of the improvisation hook to run
  # @return [Array<Aleatoric::Note>] a copy of the notes generated by the improvisation hook call
  def improvise(name)
    ret = []     
    return ret if not improvising? or @improvising_hooks.empty? or not @improvising_hooks.include? name   
    @improvising_hooks[name].call.notes.each do |note| 
      dup_note = set_added_note_attrs note
      @out_notes << dup_note
      @current_start += dup_note.duration
      ret << dup_note.dup
    end    
    ret
  end

  # TODO add a @see below to link to documentation about preplay hooks
  
  # Preplay hooks are named blocks that run, in the order they are registered, before each
  # call to #play.  They are responsible for taking a reference to the Player in which the 
  # hook is registered and an Aleatoric::Score object as input and returning an Aleatoric::Score.
  # @param [String] a name of the hook to add
  # @param [block] the block that is the hook body
  # @return [self]  
  def add_preplay_hook(name, &f)  
    @preplay_hooks_ordered_names << name
    @preplay_hooks[name] = f    
    self
  end
  
  # @param [String] the name of the hook to remove
  # @return [self]
  def remove_preplay_hook(name)
    @preplay_hooks_ordered_names.delete(name)
    @preplay_hooks.delete(name)
    self
  end
  
  # @param [String] the name of the hook being retrieved
  # @return [block] returns a lambda of the body of the hook matching the name argument
  def get_preplay_hook(name)
    @preplay_hooks[name]
  end

  # Postplay hooks are named blocks that run, in the order they are registered, after each
  # call to #play.  They are responsible for taking a reference to the Player in which the 
  # hook is registered and returning nil.
  # @param [String] a name of the hook to add
  # @param [block] the block that is the hook body
  # @return [self]
  def add_postplay_hook(name, &f)    
    @postplay_hooks_ordered_names << name
    @postplay_hooks[name] = f    
    self
  end
  
  # @param [String] the name of the hook to remove
  # @return [self]
  def remove_postplay_hook(name)
    @postplay_hooks_ordered_names.delete(name)
    @postplay_hooks.delete(name)
    self
  end
  
  # @param [String] the name of the hook being retrieved
  # @return [block] returns a lambda of the body of the hook matching the name argument
  def get_postplay_hook(name)
    @postplay_hooks[name]
  end
  
  # Improvising hooks are named blocks that run, when called by name in the #improvise method.
  # They are responsible for taking no arguments and for returning an Array of Aleatoric::Note's
  # @param [String] a name of the hook to add
  # @param [block] the block that is the hook body
  # @return [self]
  def add_improvising_hook(name, &f)  
    @improvising_hooks_ordered_names << name
    @improvising_hooks[name] = f
    self
  end
  alias add_improvisation_hook add_improvising_hook
  
  # @param [String] the name of the hook to remove
  # @return [self]
  def remove_improvising_hook(name)
    @improvising_hooks_ordered_names.delete(name)
    @improvising_hooks.delete(name)
    self
  end
  alias remove_improvisation_hook remove_improvising_hook
  
  # @param [String] the name of the hook being retrieved
  # @return [block] returns a lambda of the body of the hook matching the name argument  
  def get_improvising_hook(name)
    @improvising_hooks[name]
  end
  alias get_improvisation_hook get_improvising_hook
  
  # Store a value by keyname, serving as a generic interface for hooks to store state for later use.
  # Supports the design pattern of testing/setting state in preplay hooks and testing/setting in 
  # postplay hooks in a complementary fashion.  So, state can be tested/set before and after each
  # time the Player plays, so state can affect what is played and be affected by it.
  # @param [Object] a valid Ruby Hash as the key of the value being stored
  # @param [Object] any Ruby object as a value being stored
  # @return [self]
  def set_state(key, val)
    @state[key] = val
    self
  end
  
  # Retrieves a value by keyname, serving as a generic interface for hooks to store state for later use.
  # Supports the design pattern of testing/setting state in preplay hooks and testing/setting in 
  # postplay hooks in a complementary fashion.  So, state can be tested/set before and after each
  # time the Player plays, so state can affect what is played and be affected by it.
  # @param [Object] a valid Ruby Hash as the key of the value being stored
  # @return [Object] a reference to the Object stored under this key, or nil if #include?(key) == false
  def get_state(key)
    @state[key]
  end
  
  # Clears all key/values in the Player's state store.
  # @return [self]
  def clear_state
    @state.clear
    self
  end
  
  # Returns the keys in the Player's state store.
  def state_keys
    @state.keys
  end
  
  # Test set whether the player is enabled to play.  Setting this to false means a call to #play
  # will generate no output notes.
  # @param [true, false, nil] if a boolean is passed then it sets this on or off.
  # @return [true, false] the current value of of playing?. If is_playing arg wasn't nil then it is returned.
  def playing?(is_playing=nil)
    @is_playing = is_playing if is_playing != nil
    @is_playing
  end

  # Test set whether the player is enabled to improvise.  Setting this to false means a call to #improvise
  # will generate no output notes.
  # @param [true, false, nil] if a boolean is passed then it sets this on or off.
  # @return [true, false] the current value of of improvisng?. If is_playing arg wasn't nil then it is returned.
  def improvising?(is_improvising=nil)
    @is_improvising = is_improvising if is_improvising != nil
    @is_improvising
  end
  
  # @return [Array<Aleatoric::Note>] a copy of the notes currently in this Player's output
  def get_output
    ret = []
    @out_notes.each {|note| ret << note.dup}
    ret
  end
  alias output get_output

  # Replaces all current output notes for this Player with the array of notes passed in
  # @param [Array<Aleatoric::Note>] the notes to set as the current output for the Player
  # @return [self]
  def set_output_notes(notes)
    @out_notes.clear
    notes.each do |note|
      dup_note = set_added_note_attrs note
      @out_notes << dup_note
    end
    self
  end
  alias set_output set_output_notes
  
  # TODO TEST FOR adj_start_to_current_start=true
  # Appends a note to the current output
  # @param [Array<Aleatoric::Note>] a notes to be appended to the current output for the Player 
  # @return [self]  
  def append_note_to_output(note, adj_start_to_current_start=false)
    dup_note = set_added_note_attrs note
    if adj_start_to_current_start
      dup_note.start(dup_note.start + @current_start) 
      @current_start += dup_note.duration
    end    
    # For debugging
    @out_notes << dup_note
    self
  end
  
  # TODO TEST FOR adj_start_to_current_start=true
  def prepend_note_to_output(note)
    dup_note = set_added_note_attrs note   
    @out_notes.insert(0, dup_note)
    self    
  end
  
  # TODO TEST FOR adj_start_to_current_start=true
  # Appends a score to the current output
  # @param [Array<Aleatoric::Score>] a score which has all of its notes appended to the current output for the Player 
  # @return [self]  
  def append_score_to_output(score, adj_start_to_current_start=false)   
    score.notes.each do |note| 
      dup_note = set_added_note_attrs note
      if adj_start_to_current_start
        dup_note.start(dup_note.start + @current_start) 
        @current_start += dup_note.duration
      end
      @out_notes << dup_note
    end
    self
  end
  alias append_phrase_to_output append_score_to_output
    
  # Tests whether there is any output, that is, any notes in the current output
  # @return [true, false] indicates whethere ther are currently any notes in the output of this Player
  def output_empty?
    @out_notes.length == 0
  end
  
  # Clears all notes from the output of this Player
  # @return [self]  
  def clear_output
    @out_notes.clear
    self
  end
  
  # Creates and returns a deep copy of this Player, including copies of all Scores
  # stored by the player (with in turn copies of the Notes it the Scores), and copies
  # of all registered hooks, the same current score, and the values for #playing? and #improvising?
  # @return [Aleatoric::Player]
  def dup  
    ret = Player.new(self.name)
    
    @scores.keys.each do |score_name| 
      add_score = @scores[score_name].dup      
      ret.add_score(add_score.name, add_score)
    end
    
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
    ret.current_start = @current_start
    
    ret
  end
  
  private
  def valid_scores_idx?(idx)
     idx >= 0 and idx < @scores.length
  end
  
  def set_added_score_note_attrs(score)
    dup_score = score.dup
    dup_score.notes.each do |note| 
      set_added_note_attrs_helper note
    end
    dup_score  
  end
  
  def set_added_note_attrs(note)
    dup_note = note.dup
    set_added_note_attrs_helper dup_note
    dup_note
  end
  
  def set_added_note_attrs_helper(note)
    note.instrument(@instrument) if @instrument
    note.channel(@channel) if @channel
    note.volume(@default_volume) if @default_volume
    # For debugging
    note.player_id = "#{@name}_#{self.object_id}"
  end
  
end

end
