#!/usr/bin/env ruby

# BOILERPLATE FOR ALL user_instruction.rb FILES
# for calling sign(), swing(), swing?() no_swing(), meets_condition?()
$LOAD_PATH << "../../lib"
require 'util' 
include Aleatoric
# /BOILERPLATE FOR ALL user_instruction.rb FILES


# IMPLEMENTATION OF THIS user_instruction.rb

# Used to restore volume if it has decrescendo'd to 0
DEFAULT_VOLUME = 20

# *************************
# Player State Management
# These values govern the behavior of each Player
PLAYER_SETTINGS = {
  "num_phrases" => 1, # 162,
  
  # Player Phrase Advance
  # Player must play each phrase at least this long
  "min_repeat_phrase_count" => 1, # D_1 * 2.0, # D_4 * (45.0 + rand(15).to_f),
  # The most important factor governing advance of Players through phrases, this is simply
  #  the percentage prob that they advance on any given iteration  
  "phrase_advance_prob" => 0.3, # 0.11, 
  # Tunable parms for shifting playing of current phrase out of its current
  #  phase, and also to shift it more in alignment.  Shift simple pre-pends
  #  a rest Note to current phrase before writing it to Score.  Supports
  #  score directive to adjust phase, and another to move in and out of phase
  #  during a performance
  
  # Player Phrase Phase Adjustment
  # Percentage prob that a Player will adjust phase on any given iteration
  "adj_phase_prob_factor" => 0.02,
  # Supports Instruction that Player this is too often in alignment should favor
  #  trying to be out of phase a bit more. If Player hasn't adjusted phase
  #  this many times or more, then adj_phase_prob_increase_factor will be applied
  "adj_phase_count_threshold" => 1,
  "adj_phase_prob_increase_factor" => 1.0,
  # The length of the rest Note (in seconds) inserted if a Player is adjusting its phase  
  "phase_adj_dur" => D_64 * 0.1,
  # Players are adjusted out of phase initially a tiny bit, to make it easier for midi file to play
  "init_adj_phase_dur" => D_64 * 0.1,
  
  # Prob that a Player will seek unison on any given iteration.  The idea is that
  #  to seek unison the Ensemble and all the Players must seek unison  
  "unison_prob_factor" => 0.8,
  
  # Player Rest/Play
  # Tunable parms for probability that Player will rest rather than playing a note.
  # Supports score directive to listen as well as play and not always play
  # Prob that a Player will try to rest on a given iteration (not play)
  "rest_prob_factor" => 0.1,  
  # Factor multiplied by rest_prob_factor if the Player is already at rest  
  "stay_at_rest_prob_factor" => 1.5,
  
  # Player Volume Adjusment, De/Crescendo
  # Tunable parms for adjusting volume up and down, and prob of making
  #  an amp adjustment. Supports score directive to have crescendos and
  #  decrescendos in the performance  
  # Threshold for the ratio of this Players average amp for its current phrase
  #  to the max average amp among all the Players. Ratio above/below this means the Player
  #  will raise/lower its amp by amp_de/crescendo_adj_factor    
  # "amp_adj_crescendo_ratio_threshold" => 1.0,
  # "amp_crescendo_adj_factor" => 1.1,
  # "amp_adj_diminuendo_ratio_threshold" => 1.0,
  # "amp_diminuendo_adj_factor" => 0.9,
  # Prob that a Player is seeking de/crescendo  
  # "crescendo_prob_factor" => 0.4,
  # "diminuendo_prob_factor" => 0.4,
  
  # Player Pitch Transpose
  # Tunable parms for transposing the playing of a phrase.  Suppports score directive
  #  to transpose as desired.
  # Prob that a Player will seek to transpose its current phrase
  "transpose_prob_factor" => 0.05,
  # Number of octaves to transpose if the Player does do so
  # Amount that represents an octave in backend being used to render notes (1.0 in CSound, 12 in MIDI)
  "transpose_shift" => 1.0, 
  # Sadly, we need this also, because CSound is float type and MIDI is int type (0.0 or 0)
  "transpose_no_shift" => 0.0,
  # Factor for shift down, likewise (-1.0 in CSound, -1 in MIDI)
  "transpose_shift_down_factor" => -1.0,
  # Factor for shift up, likewise (1.0 in CSound, 1 in MIDI)
  "transpose_shift_up_factor" => 1.0,  
  # From the Instructions: "Transposing down by octaves works best on the patterns containing notes of long durations."
  # Minimum average duration of notes in a phrase for that phrase to be more likely
  #  to transpose down rather than up
  "transpose_down_prob_factor" => 0.5,
  # Minimum average duration of notes in a phrase for that phrase to be more likely
  #  to transpose down rather than up  
  "transpose_down_dur_threshold" => 2.0,
  
  # Swing
  # Give notes a bit of variance in start time and duration. If not overdone 
  #  gives a more human feel.  A tiny bit goes a long, long way ...
  # Use standard Aleatoric implementation in lib/util.rb
  # swing(base_val, num_steps, swing_step)
  #  returns a factor to multiply note.duration and note.start by
  #  base_val - the smallest possible swing factor
  #  num_steps - the number of values incremented up from the base_val
  #  swing_step - the size of each step value increment
  # So, example: swing(0.98, 5, 0.01) -> swing range with the discrete values [0.98, 0.99, 1.0, 1.01, 1.02]
  "swing_base_val" => 0.9998,
  "swing_num_steps" => 3,
  "swing_step_size" => 0.0002
}


# Ensemble State Management
# These values govern the behavior of the Ensemble
ENSEMBLE_SETTINGS = {
  "num_players" => 9,
  # Threshold number of phrases behind the furthest ahead any Player is allowed to slip.
  # If they are more than N behind the leader, they must advance.     
  "phrases_idx_range_threshold" => 3,
  # Prob that the Ensemble will seek to have all Players play the same phrase
  #  on any one iteration through the Players  
  "unison_prob_factor" => 0.2,
  # Threshold number of phrases apart within which all players 
  #  must be for Ensemble to seek unison
  "max_phrases_idx_range_for_seeking_unison" => 2,
  
  # Crescendos before concluding section
  # Probability that the ensemble will de/crescendo in a unison
  "crescendo_prob_factor"=> 0.02,
  "decrescendo_prob_factor"=> 0.01,
  # Maximum de/increase in volume (in CSound scale) that notes can gain in de/crescendo 
  "crescendo_max_amp_range" => DEFAULT_VOLUME,
  "decrescendo_max_amp_range" => DEFAULT_VOLUME,
  # Minimum number of iterations over which a de/crescendo will take to de/increase volume by crescendo amount
  # NOTE: Must be < max_crescendo_num_steps
  "min_crescendo_num_steps" => 10, # 50,
  # Maximum number of iterations over which a de/crescendo will take to de/increase volume by crescendo amount
  # NOTE: Must be >= de/crescendo_max_amp_range
  "max_crescendo_num_steps" => 20, # 70, 
  
  # Parameters governing the Conclusion
  # This is the ratio of steps in the Conclusion to the total steps before the Conclusion  
  "conclusion_steps_ratio" => 0.03, # 0.06,
  # This extends the duration of the repetition of the last phrase
  #  curing the final coda.  At the start of the coda each player
  #  has its start time pushed ahead to be closer to the maximum
  #  so that they arrive at the end closer together.  This factor offsets the Player from
  #  repeating the last phrase until exactly reaching the Conclusion  
  "conclusion_cur_start_offset_factor" => 0.05,
  # Minimum number of crescendo and decrescendo steps in the conclusion, supporting the 
  #  Instruction indicating ensemble should de/crescendo "several times"
  "min_number_concluding_crescendos" => 2,  
  # Maximum number of crescendo and decrescendo steps in the conclusion, supporting the 
  #  Instruction indicating ensemble should de/crescendo "several times"
  "max_number_concluding_crescendos" => 3
}

# Add this to store properties global to the score and need to be stored in module-scope vars
#  because used by the instruction handlers
SCORE_SETTINGS = {
  "last_phrase_dur" => D_1
}
# *************************

# *************************
# Manages the state associated with each Player
class In_C_Player
  include Aleatoric
  
  attr_reader :ensemble, :handle, 
              :num_phrases, :phrases_idx, :adj_phase_count, :at_rest, :cur_phrase_count,
              :swing_range_max_factor, :swing_range_min_factor, :swing_factor_range, :has_advanced, 
              # VERBOSE
              :max_phrase_count, :total_loops, :advanced_on_play_next, 
              :advanced_on_play_next2, :advanced_on_play_next3  # /VERBOSE
  attr_writer :cur_phrase_count
  

  def initialize(ensemble, num_phrases, handle)    
    @ensemble = ensemble
    @num_phrases = num_phrases
    @handle = handle
	  # Offset into @phrases that this player is currently playing
	  @phrases_idx = 0
	  @cur_start = 0.0
	  # Count of how many times Player has played current phrase
	  @cur_phrase_count = 0
	  # Count of how many times Player has adjusted phase, to support testing against
	  #  adj_phase_count_threshold to apply adj_phase_prob_increase_factor in adj_phase?
	  @adj_phase_count = 0
    # Indicator that the Player is at rest
    @at_rest = false
    @repeating_cur_phrase = false 
    
    # VERBOSE
    @max_phrase_count = 0
    @total_loops = -1
    @advanced_on_play_next = 0
    @advanced_on_play_next2 = 0
    @advanced_on_play_next3 = 0
    # /VERBOSE
  end
    
  # Player Public API
  # This is what the Instruction handlers call to control each Player on each call to play() in the Composer score
  # Some methods public also so In_C_Ensemble can call them
  public
  
  def phrases_index
    @phrases_idx
  end
  
  # Used by Ensemble to test if all phrases have reached the last phrase
  def reached_last_phrase?
    # This should be ==, >= is a relic of a bug and trying to defend against it      
    @phrases_idx >= @num_phrases
  end
  
  # Instruction 3
  # NOTE: Instruction 5 and Instruction 6 grouped with this. They can also advance the player to next phrase
  #  but since there is an Instruction that players must play all phrases must not advance twice in one play() iteration
  def play_next_phrase?  
    # VERBOSE
    @total_loops += 1
    # /VERBOSE

    @has_advanced = false
    
    # Must repeat each phrase for minimum duration, so skip all other checks
    #  for advancing duration if haven't done so for current phrase
    @repeating_cur_phrase = repeat_cur_phrase?
        
    can_advance = ! @repeating_cur_phrase && ! reached_last_phrase?
    # Now test this advance condition, if conditions preventing advance aren't true
    if can_advance and advance_phrases_idx?
      @has_advanced = true
      @phrases_idx += 1
      @cur_phrase_count = 0
  
      # VERBOSE
      @advanced_on_play_next += 1 if @has_advanced
      # /VERBOSE    
    end
    @has_advanced
  end
  
  # Instruction 5, grouped with Instruction 3
  def play_next_phrase_too_far_behind?        
    # VERBOSE
    adv_here = false
    # /VERBOSE
    
    can_advance = ! @has_advanced && ! @repeating_cur_phrase && ! reached_last_phrase?
    if can_advance and phrases_idx_too_far_behind?
      @has_advanced = true
      adv_here = true # VERBOSE
      @cur_phrase_count = 0
      @phrases_idx += 1
    end
  
    # VERBOSE
    @advanced_on_play_next2 += 1 if adv_here
    # VERBOSE

    @has_advanced 
  end
  
  # Instruction 6, grouped with Instructions 5 and 6
  def play_next_phrase_seeking_unison?
    # VERBOSE
    adv_here = false
    # /VERBOSE

    can_advance = ! @has_advanced && ! @repeating_cur_phrase && ! reached_last_phrase? 
    if can_advance and seeking_unison? 
      @has_advanced = true        
      adv_here = true # VERBOSE
      @cur_phrase_count = 0
      @phrases_idx += 1
    end    

    # VERBOSE
    @advanced_on_play_next3 += 1 if adv_here
    # /VERBOSE
    
    @has_advanced
  end

  # PREPLAY bool, return whether or not to have Player rest for this iteration
  def rest?
    # Only try to rest if the ensemble is not currently in a crescendo or decrescendo
    if not @ensemble.in_crescendo?
      # More likely to stay at rest if already at rest -- the Player is "listening"
      stay_at_rest_factor = @at_rest ? @stay_at_rest_prob_factor : NO_FACTOR
  	  meets_condition?(@rest_prob_factor * stay_at_rest_factor)
  
  	else
  	  false
  	end
  end

  def phase_adj
    adj_phase? ? @phase_adj_dur : 0.0      
  end
  
  # PREPLAY, arg = container.cur_phrase
  def min_amp(phrase)
    phrase.attr_slice(:amplitude).min
  end
  
  # PREPLAY, arg = container.cur_phrase
  def max_amp(phrase)
    phrase.attr_slice(:amplitude).max
  end  

  # PREPLAY, arg = container.cur_phrase, return = amount to shift all notes in current phrase by, by adding to pitch of each note
  def transpose_shift(phrase)	
    shift = @transpose_no_shift

  	if meets_condition?(@transpose_prob_factor)
      # Figure out if we shift up or down, it depends on the length of notes in the phrase ...
      # ... so get mean length of all notes in current phrase ...
      durations = phrase.attr_slice(:duration)
      
      # NOTE: Extending module Array with #sum() only works for code within
      #  module Aleatoric, apparently, not code that includes it, such as here
      # Note also that module-level free methods from util.rb, where #sum() is
      #  can be called here.
	    # mean_dur = durations.sum / durations.length
      len = durations.length
      len = 1 if len == 0
	    dur_sum = durations.inject(0) {|sum, x| sum + x}
	    mean_dur = dur_sum / len
      
      # ... and test it against the threshold for favoring down transpose
      if meets_condition?(@transpose_down_prob_factor) and mean_dur >= @transpose_down_dur_threshold
        shift = @transpose_shift * @transpose_shift_down_factor
      else
        shift = @transpose_shift * @transpose_shift_up_factor
      end
    end

    shift
  end

  # PREPLAY, returns tuple of factor to multiply by note start time and factor to multiply by note duration
  # NOTE: Instruction handler can decide to call this for each note in container.cur_phrase individually, or apply one
  #  swing value to all notes in cur_phrase.  Former should be more "realistic" but hearing is believing
  def swing_adj
    if swing?(@swing_base_val, @swing_num_steps) then
      # swing(base_val, num_steps, swing_step)
      #  base_val - the smallest possible swing factor
      #  num_steps - the number of values incremented up from the base_val
      #  swing_step - the size of each step value increment
      # For example swing(0.98, 5, 0.01) returns one of five values [0.98, 0.99, 1.0, 1.01, 1.02]
      start_swing = swing(@swing_base_val, @swing_num_steps, @swing_step_size) * sign
      dur_swing =  swing(@swing_base_val, @swing_num_steps, @swing_step_size) * sign
      return start_swing, dur_swing
    else
      return no_swing, no_swing
    end
  end
  
  def align_last_phrase_start
    last_phrase_length = @phrases[@num_phrases-1].duration
    # Get the start time past current latest start time so all crescendo notes start after that
    max_start = players_attr_slice(:cur_start).max
    amp_adj = 0
    @players.each do |player|
      num_plays_last_phrase = ((max_start - player.cur_start) / last_phrase_length).floor    
      num_plays_last_phrase.times do 
        player.play_conclusion_phrase amp_adj
      end
    end  
  end
  
  # NOTE: Had to make this public and called after initialize() returned
  # When it was called by initialize() the methods were not dynamically added
  def def_accessors 
    PLAYER_SETTINGS.each do |k,v|     
      self.instance_eval "@#{k} = #{v}"
      self.class_eval("def #{k}\n@#{k}\nend")
    end
    # Derived from settings loaded in def_accessors()
    @swing_factor_range = @swing_range_max_factor - @swing_range_min_factors
  end
    
  # Helpers
  private

  def repeat_cur_phrase?
    durations = @@al_players[self.handle].current_phrase.notes.collect {|note| note.duration}
    cur_phrase_dur = durations.inject(0) {|sum, x| sum + x} 
    
    # VERBOSE
    @max_phrase_count = @cur_phrase_count if @cur_phrase_count > @max_phrase_count
    # /VERBOSE
        
    # NOTE: This approach based on duration of measure from "In C" version, which has no phrases
    #  without any notes, i.e. with duration == 0.  But that isn't a useful general assumption
    #  obviously -- we need to support empty phrases.  Also, duration approach is a bug for
    #  empty phrases.  So switch to simple "# of times played" approach.  Note that this was
    #  abandoned in "In C" because some phrases were so much longer than others, and so the long
    #  ones dominated the performance and distorted it from the actual intent (or at least from
    #  typical real-world performances)
    # @cur_phrase_count * cur_phrase_dur < @min_repeat_phrase_duration
    @cur_phrase_count < @min_repeat_phrase_count
  end

  def advance_phrases_idx?
    meets_condition? @phrase_advance_prob
  end

  def phrases_idx_too_far_behind?
    @ensemble.phrases_idx_too_far_behind?(@phrases_idx)
  end

  def seeking_unison?
    @ensemble.seeking_unison? and meets_condition?(@unison_prob_factor)
  end

  def seeking_crescendo?
    @ensemble.seeking_crescendo? and meets_condition?(@crescendo_prob_factor)
  end

  def seeking_diminuendo?
    @ensemble.seeking_diminuendo? and  meets_condition?(@diminuendo_prob_factor)
  end
  
  def adj_phase?    
    adj_phase_prob_factor = @adj_phase_prob_factor
    adj_phase_prob_factor *= @adj_phase_prob_increase_factor if @adj_phase_count <= @adj_phase_count_threshold
    adj_phase = meets_condition?(adj_phase_prob_factor)
    @adj_phase_count += 1 if adj_phase
    adj_phase
  end      
end
# *************************

# *************************
# Manages the state associated with the Ensemble
class In_C_Ensemble
  include Aleatoric
    
  attr_reader     :name, :num_players, :num_phrases, :unison_count, :players
  attr_writer     :reached_conclusion, :max_crescendo_step_count

  def initialize(name, handle)
    @name = name
    # The unique Id of the Composer Ensemble that this class is "shadowing"
    #  that is, managing state to implement the Instructions and then
    #  use the Composer API in the Instruction handlers to affect the Composer Ensemble
    @handle = handle
    @players = []
    @num_players = 0
    @num_phrases = PLAYER_SETTINGS["num_phrases"]
    # Controls check for increasing prob of getting all players in unison
    @unison_count = 0
    @perform_steps_count = 0
    @reached_conclusion = false
    @crescendo_amp_adj = 0
    @in_crescendo = false
    @in_decrescendo = false
    @crescendo_step_count = 0
    @max_crescendo_step_count = 0
    @in_crescendo_decrescendo = false
    @in_decrescendo_crescendo = false
    @crescendo_sign = 1
  end

  # Ensemble Public API
  # This is what pre/post handlers call to get/set Ensemble state on each call to play() in Composer script
  # Also methods are public if In_C_Players need to call them
  public
  
  def players=(players)
    @players = players.values
    @num_players = players.length
    # Controls whether all Players have reached last phrase and conclusion should begin
  end
  
  ## Player Phrase Position Management Methods
  def max_phrases_idx    
    players_phrases_idxs.max
  end
  
  def min_phrases_idx
    players_phrases_idxs.min
  end  
  
  def phrases_idx_too_far_behind?(phrases_idx)
    max_phrases_idx - phrases_idx >= @phrases_idx_range_threshold    
  end
  # /Player Phrase Position Management Methods
  
  ## Unison methods  
  def seeking_unison?
    ! reached_unison? &&
      players_phrases_idx_range <= @max_phrases_idx_range_for_seeking_unison &&
      meets_condition?(@unison_prob_factor)
  end  
  ## /Unison methods

  ## Player Amp methods
  # Public because In_C_Player needs to call it
  def max_player_amp    
    (@players.collect {|p| p.max_amp(@@al_players[p.handle].current_phrase)}).max
  end
  ## /Player Amp methods

  ## Player De/Crescendo methods
  # Both of these are called by In_C_Player
  # Works because assignment is an expression returning value assigned as side effect
  def set_crescendo_decrescendo        
    return if @in_decrescendo_crescendo or @in_crescendo_decrescendo
    @max_crescendo_step_count = @min_crescendo_num_steps + rand(@max_crescendo_num_steps - @min_crescendo_num_steps + 1)
    @max_crescendo_step_count = @crescendo_max_amp_range if @max_crescendo_step_count > @crescendo_max_amp_range
    @crescendo_amp_adj = (@crescendo_max_amp_range / @max_crescendo_step_count).floor
    @crescendo_amp_adj = 1 if @crescendo_amp_adj == 0
    @crescendo_step_count = 0    
    @crescendo_sign = 1
    @in_crescendo = true
    @in_crescendo_decrescendo = true
  end
  
  def set_decrescendo_crescendo
    return if @in_decrescendo_crescendo or @in_crescendo_decrescendo
    # Handle case where maximum crescendo range is > DEFAULT_VOLUME
    # Only descrescendo down to 0 and back up to DEFAULT_VOLUME
    if @crescendo_max_amp_range > DEFAULT_VOLUME
      @crescendo_max_amp_range = DEFAULT_VOLUME
    end
    @max_crescendo_step_count = @min_crescendo_num_steps + rand(@max_crescendo_num_steps - @min_crescendo_num_steps + 1)
    @max_crescendo_step_count = @crescendo_max_amp_range if @max_crescendo_step_count > @crescendo_max_amp_range
    @crescendo_amp_adj = (@crescendo_max_amp_range / @max_crescendo_step_count).floor
    @crescendo_amp_adj = 1 if @crescendo_amp_adj == 0
    @crescendo_step_count = 0
    @crescendo_sign = -1
    @in_decrescendo = true
    @in_decrescendo_crescendo = true
  end
  
  def crescendo_increment    
    if @in_crescendo_decrescendo      
      # Test increment step_count and test for boundary transitions 
      #  from crescendo to decrescendo and exit from de/crescendo      
      # Case 1: In crescendo but not finished, no switch, just increment step count
      if @in_crescendo and @crescendo_step_count <= @max_crescendo_step_count
        @crescendo_step_count += 1
      # Case 2: In descrescendo but not finished, no switch, just decrement step count
      elsif @in_decrescendo and @crescendo_step_count > 0
        @crescendo_step_count -= 1
      # Case 3: Just finished crescendo, switch to decrescendo to come back down
      elsif @in_crescendo and @crescendo_step_count > @max_crescendo_step_count
        @in_decrescendo = true
        @in_crescendo = false
        @crescendo_step_count -= 1
      # Case 4: Finished crescendo and then decrescendo, done with entire cycle, no amp adjustment
      elsif @in_decrescendo and @crescendo_step_count <= 0
        @in_crescendo_decrescendo = false
        @in_decrescendo = false
        @in_crescendo = false
        @crescendo_step_count = 0      
      end     
    # Just like above but case where we started with decrescendo first
    elsif @in_decrescendo_crescendo
      # Case 1: In crescendo but not finished, no switch, just increment step count
      if @in_decrescendo and @crescendo_step_count <= @max_crescendo_step_count
        @crescendo_step_count += 1
      # Case 2: In crescendo but not finished, no switch, just decrement step count
      elsif @in_crescendo and @crescendo_step_count > 0
        @crescendo_step_count -= 1
      # Case 3: Just finished decrescendo, switch to crescendo to come back down
      elsif @in_decrescendo and @crescendo_step_count > @max_crescendo_step_count
        @in_crescendo = true
        @in_decrescendo = false
        @crescendo_step_count -= 1
      # Case 4: Finished crescendo and then decrescendo, done with entire cycle, no amp adjustment
      elsif @in_crescendo and @crescendo_step_count <= 0
        @in_decrescendo_crescendo = false
        @in_crescendo = false
        @in_decrescendo = false
        @crescendo_step_count = 0      
      end      
    end  
  end

  def crescendo_amp_adj   
    if in_crescendo_decrescendo? or in_decrescendo_crescendo?
      # Return increment or decrement of step size * step number        
      @crescendo_sign * @crescendo_step_count * @crescendo_amp_adj
    else
      0
    end
  end

  def seeking_crescendo?
    ! in_crescendo_decrescendo? && meets_condition?(@crescendo_prob_factor)
  end

  def seeking_decrescendo?
    ! in_decrescendo_crescendo? && meets_condition?(@decrescendo_prob_factor)
  end
  
  def in_crescendo_decrescendo?
    @in_crescendo_decrescendo
  end
  def in_decrescendo_crescendo?
    @in_decrescendo_crescendo
  end
  # A bit confusing semantics, sadly, but this is either of the above two predicates
  def in_crescendo?
    in_crescendo_decrescendo? or in_decrescendo_crescendo?
  end
  ## Player De/Crescendo methods

  ## Performance Conclusion methods
  ## Test whether all Players have reached last phrase
  def reached_concluding_unison?
    # So client code doesn't have to check every Player over hundreds of iterations once Ensemble reaches conlcusion phase
    # Once in conclusion phase can't exit it, so just set and test this once
    if not @reached_concluding_unison
      @players.each do |player|
        if not player.reached_last_phrase?
          @reached_concluding_unison = false
          return @reached_concluding_unison
        end        
      end
    end
    @reached_concluding_unison = true
    @reached_concluding_unison                           
  end
  
  # Set by Instruction 14 Postplay Handler when it enters the block to have the players
  #  play the final crescendos after they have all reached unison.
  # repeat_until() handler checks its handler, which checks this flag, on every iteration
  def reached_conclusion?
    @reached_conclusion
  end
  
  # NOTE: Had to make this public and called after initialize() returned
  # When it was called by initialize() the methods were not dynamically added
  def def_accessors     
    ENSEMBLE_SETTINGS.each do |k,v|
      self.instance_eval "@#{k} = #{v}"
      self.class_eval("def #{k}\n@#{k}\nend")      
    end
  end  
    
  # Helpers
  private
  
  def set_crescendo_step_and_adj
    @max_crescendo_step_count = 
      @min_crescendo_num_steps + 
      rand(@max_crescendo_num_steps - @min_crescendo_num_steps + 1)
    # Reset step count, new de/crescendo
    @crescendo_step_count = 0
    # Handle case where maximum crescendo range is > DEFAULT_VOLUME
    # Only descrescendo down to 0 and back up to DEFAULT_VOLUME
    if @crescendo_max_amp_range > DEFAULT_VOLUME
      @crescendo_max_amp_range = DEFAULT_VOLUME
    end
    # Range of de/crescendo is >= than # of steps, just divide to get adj per step
    if @crescendo_max_amp_range >= @max_crescendo_step_count
      # Use .ceil to insure step volume adj of at least 1.
      @crescendo_amp_adj = (@crescendo_max_amp_range / @max_crescendo_step_count).ceil
    # Handle case where # of steps > total volume adj of de/crescendo, 
    #  make step size 1 and adjust # of steps to be the total adj for the de/crescendo
    else
      @crescendo_amp_adj = 1
      @max_crescendo_step_count = @crescendo_max_amp_range
    end    
  end

  def reached_unison?
    @unison_count >= @num_players
  end
    
  def min_player_amp
    (@players.collect {|p| p.max_amp(@@al_players[p.handle].current_phrase)}).max
  end

  def amp_range
    max_player_amp - min_player_amp
  end  
    
  # Helper to get Player indexes, since it's called multiple times
  def players_phrases_idxs
    players_attr_slice(:phrases_index) 
  end  

  def players_phrases_idx_range
    idxs = players_phrases_idxs
    idxs.max - idxs.min
  end

  # Helper to collect a list of all values for a Player attr, for all Players. 
  def players_attr_slice(attr)  
    @players.collect {|player| player.send(attr.to_sym)}
  end
end
# *************************


# *************************
# Declare local Ensemble and Player objects of this user_instruction class
# Module scope and used by all the instruction handlers, which are free
#  lambdas at module scope

# Register a callback that will be run the first time play() is called
# This is exposed by the API and it passes arrays of all the main entities
#  in Composer to the callback, namely Notes, Scores, Measures, Phrases, Sections, Players, Ensembles
in_c_players = {}
@@al_players = {}
in_c_init_play_handler = lambda do |notes, scores, measures, phrases, sections, al_players, al_ensembles|
  # Instantiate In_C_Ensemble and In_C_Players, these are used by the Instruction handlers
  #  to implement the Instructions
  al_players.each {|al_player| @@al_players[al_player.handle] = al_player}
  al_ensemble_handle = al_ensembles.first.handle
  al_player_handles = al_players.collect {|p| p.handle}
  # Construct with reference to Composer Ensemble object
  @@in_c_ensemble = In_C_Ensemble.new("In C Orchestra", al_ensemble_handle)
  # Call to create accessors from ENSEMBLE_SETTINGS  
  @@in_c_ensemble.def_accessors

  num_players = al_player_handles.length
  num_phrases = PLAYER_SETTINGS["num_phrases"]
  initial_rest_note_dur = PLAYER_SETTINGS["init_adj_phase_dur"]
  num_players.times do |j|
    in_c_player = In_C_Player.new(@@in_c_ensemble, num_phrases, al_player_handles[j])
    in_c_player.def_accessors
    # Reverse key mapping of Composer Player handle to this shadowing In_C_Player
    in_c_players[al_player_handles[j]] = in_c_player  
    # Add a rest of duration times index so each Aleatoric player has an offset
    # This sets each ones notes off from the others a bit to make MIDI more likely to play well
    # Get player's assigned MIDI channel from associated al_player -- MIDI already imported by now
    al_player = @@al_players[al_player_handles[j]]
    rest_note = Note.new_rest(j * initial_rest_note_dur, al_player.channel)
    al_player.append_note_to_output rest_note
  end
  @@in_c_ensemble.players = in_c_players  
end
set_play_init_handler("in_c_init_play_handler", &in_c_init_play_handler)

# VERBOSE
processing_start_time = Time.now
# /VERBOSE
# *************************


# *************************
# Composer Instruction and 'repeat until' Implementation
# This uses the above classes to manage state of the In_C_Players and In_C_Ensemble, to encapsulate all the
#  predicates and computations that determine what actions each Player takes on each iteration of play().
#  Here we apply the changes based on using these classes to the actual Composer Players and Ensemble, in the
#  pre- and post-play handlers, access the Composer Players and Ensemble through the handler 'container' argument,
#  and then using the nice Composer Player() and Ensemble() public methods as our API to change what each Player plays
# We could do all the state management and logic by using the set_state()/get_state Composer API, but that works better
#  for simpler rules and fewer of them.  It's nice to have an OO setup visible here to implement a composition as
#  complex as this.  Of course this means extra work to plug into Composer API calls here, but we get the rest
#  of Composer by doing this (executable and human-readable musical score, generating/rendering output)

# No Op Instructions
# No operation instructions.  These are either implicitly satisfied by the
#  overall solution, instructions to a live orchestra of humans, or general
#  directions that don't actually describe any constraints to be satisfied.

# "All performers play from the same page of 53 melodic patterns played in sequence."
instruction_1 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 1", &instruction_1)

# "Any number of any kind of instruments can play.  A group of about 35 is desired if possible but smaller or larger groups will work.  If vocalist(s) join in they can use any vowel and consonant sounds they like."
instruction_2 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 2", &instruction_2)

# "If for some reason a pattern can’t be played, the performer should omit it and go on."
instruction_12 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 12", &instruction_12)

# "Instruments can be amplified if desired.  Electronic keyboards are welcome also."
instruction_13 = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 13", &instruction_13)


# *************************
# Instructions

# "Patterns are to be played consecutively with each performer having the freedom to determine how many 
#  times he or she will repeat each pattern before moving on to the next.  There is no fixed rule 
#  as to the number of repetitions a pattern may have, however, since performances normally average 
#  between 45 minutes and an hour and a half, it can be assumed that one would repeat each pattern 
#  from somewhere between 45 seconds and a minute and a half or longer."
instruction_3_player_pre = lambda do |container, score|  
  # In_C_Players stowed in a Hash keyed to the handle() (a unique id) of the Aleatoric Player 
  in_c_player = in_c_players[container.handle]  
  # In_C_Player stores all the state about a player.  Ask if this player is on the last phrase  
  container.increment_scores_index if in_c_player.play_next_phrase?
    
  score
end
set_player_preplay_instruction("Instruction 3", &instruction_3_player_pre)

# "It is very important that performers listen very carefully to one another and this means occasionally to drop out and listen. ...
#  As an ensemble, it is very desirable to play very softly as well as very loudly and to try to diminuendo and crescendo together."
# This handler controls whether all Players in Ensemble will enter crescendo or
#  descrescendo state.  If they do then all amp-related hanlders will be skipped
#  for as long as the de/crescendo lasts.  Instead all Players will move amp up/down
#  one step each iteration, for the number of steps of the de/crescendo.  The amount
#  amp changes overall is controlled in Ensemble setting 
#  max_amp_range_for_seeking_crescendo
instruction_4_ensemble_pre = lambda do |container|  
  in_c_ensemble = in_c_players.values[0].ensemble   
  if in_c_ensemble.seeking_crescendo?
    in_c_ensemble.set_crescendo_decrescendo
  elsif in_c_ensemble.seeking_decrescendo?
    in_c_ensemble.set_decrescendo_crescendo
  end
end
set_ensemble_preplay_instruction("Instruction 4", &instruction_4_ensemble_pre)

# This adjusts the state of the ensemble tracking what step in a de/crescendo it's in
instruction_4_ensemble_post = lambda do |container|
  in_c_ensemble = in_c_players.values[0].ensemble  
  in_c_ensemble.crescendo_increment
end
set_ensemble_postplay_instruction("Instruction 4", &instruction_4_ensemble_post)

# This implements de/crescendo amp adjustment on each player after the ensemble handler sets whether
#  or not the orchestra is in de/crescendo
instruction_4_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  in_c_ensemble = in_c_player.ensemble  
  # Ensemble manages current state of whether all Players are in de/crescendo, and if so by how
  #  much each Player adjusts their volume. All each Player does is call this, if there is 
  #  no current de/crescendo then crescendo_amp_adj() returns 0
  amp_adj = in_c_ensemble.crescendo_amp_adj    
  score.notes.each do |note|        
    new_vol = note.volume + amp_adj
    new_vol = 0 if new_vol < 0 or note.volume == 0
    note.volume new_vol    
  end

  score
end
set_player_preplay_instruction("Instruction 4", &instruction_4_player_pre)

# "Each pattern can be played in unison or canonically in any alignment with itself or with its neighboring patterns.  ..."
instruction_5_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  # In_C_Player manages whether this player is changing its phase, that is its starting position 
  #  in its current phrase to not start at the same time as the last time it played.  
  # This in effect changes its "alignment" in playing relative to the other players
  # Construct the rest Note
  rest_note_dur = in_c_player.phase_adj
  rest_note = Note.new_rest(rest_note_dur)
  # Shift the start times of all notes following the prepended note, and prepend it
  # This (i.e. score.notes.first == nil) won't happen if notes are defined in Composer score, but MIDI import brings in
  #  more variable quality note data
  if score.notes.first
    rest_note.start score.notes.first.start 
    score.notes.each {|note| note.start(note.start + rest_note_dur)}
    score.prepend_note rest_note
  end
  
  score
end
set_player_preplay_instruction("Instruction 5", &instruction_5_player_pre)

#  "... As the performance progresses, performers should stay within 2 or 3 patterns of each other. ..."
instruction_6_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  container.increment_scores_index if in_c_player.play_next_phrase_too_far_behind?
  score
end
set_player_preplay_instruction("Instruction 6", &instruction_6_player_pre)

# "The ensemble can be aided by the means of an eighth note pulse played on the high c’s of the piano or on a mallet instrument.  
# It is also possible to use improvised percussion in strict rhythm (drum set, cymbals, bells, etc.), 
#  if it is carefully done and doesn’t overpower the ensemble.  
# All performers must play strictly in rhythm and it is essential that everyone play each pattern carefully
instruction_7_player_pre = lambda do |container, score|
  # TODO IMPLENENT THIS
  score
end
set_player_preplay_instruction("Instruction 7", &instruction_7_player_pre)

# Well, these performers can play at any tempo, so ignore this restriction. It might be interesting to hear this 
#  performed at a glacially slow pace
# Use this Instruction to apply swing, since original score speaks to players making tempo decisions
# "The tempo is left to the discretion of the performers, obviously not too slow, but not faster than performers can comfortably play."
instruction_8 = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  start_swing, dur_swing = in_c_player.swing_adj
  score.notes.each do |note| 
    note.start(note.start + (note.start * start_swing))
    note.start(0.0) if note.start < 0.0
    note.duration(note.duration + (note.duration * dur_swing))
    note.duration(0.0) if note.duration < 0.0
  end
  score
end
set_player_preplay_instruction("Instruction 8", &instruction_8)

# TODO This *really* could be implemented, but it would be tricky and sophisticated
# "It is important to think of patterns periodically so that when you are resting you are conscious of the larger 
#  periodic composite accents that are sounding, and when you re-enter you are aware of what effect your entrance 
#  will have on the music’s flow."
instruction_9_player_pre = lambda do |container, score|
  # no_op
  score
end
set_player_preplay_instruction("Instruction 9", &instruction_9_player_pre)

# "The group should aim to merge into a unison at least once or twice during the performance.  
# At the same time, if the players seem to be consistently too much in the same alignment of a pattern, 
# they should try shifting their alignment by an eighth note or quarter note with what’s going on in the rest of the ensemble."
instruction_10_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  container.increment_scores_index if in_c_player.play_next_phrase_seeking_unison?
  score
end
set_player_preplay_instruction("Instruction 10", &instruction_10_player_pre)

# Extra helper handler to set player post-play state -- whether they have advanced
#  a phrase or not.  If not, increment player counter on current phrase
# Depends on separate checks in instruction handlers for instructions 3, 6 and 10
instruction_3_6_10_player_post = lambda do |container|
  in_c_player = in_c_players[container.handle]
  # Now increment count after testing for have we played this phrase long enough  
  in_c_player.cur_phrase_count += 1 if not in_c_player.has_advanced
end
set_player_postplay_instruction("Instruction 10", &instruction_3_6_10_player_post)

# "It is OK to transpose patterns by an octave, especially to transpose up.  Transposing down by octaves 
# works best on the patterns containing notes of long durations. 
# TODO HOW TO IMPLEMENT THIS PART OF THIS INSTRUCTION Augmentation of rhythmic values can also be effective."
instruction_11_player_pre = lambda do |container, score|
  in_c_player = in_c_players[container.handle]
  shift = in_c_player.transpose_shift(score)
  score.notes.each {|note| note.pitch(note.pitch + shift)}
  score
end
set_player_preplay_instruction("Instruction 11", &instruction_11_player_pre)

# "In C is ended in this way:  when each performer arrives at figure #53, he or she stays on it until the entire ensemble has arrived there.  
# The group then makes a large crescendo and diminuendo a few times and each player drops out as he or she wishes."

# Unfortunately, this relies on state in the Aleatoric objects, specifically the wall time start time of each Player, which
#  is stateful because it built up over every Play call, in the real Player, and it's only there that it knows whether Notes
#  were really added to output and so advanced the actual start time.  So we have implementation here

# ... Now end the piece in this repeat_until Postplay Instruction, the first time the ensemble has reached conclusion
# Just performed all of the conclusion in the Preplay Ensemble handler for this same Instruction
# NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
#  NAME PASSED TO set_repeat_until_stop_postplay_test()
#j = 0
instruction_14_repeat_until_test_post = lambda do    
  # Violates encapsulation -- needs to know about module scope variable defined above
  # NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
  #  NAME PASSED TO set_repeat_until_stop_postplay_test()  
  if @@in_c_ensemble.reached_conclusion?
    set_repeat_until_stop "... each player drops out as he or she wishes."
  end
end
# NOTE REPEAT UNTIL NAME PASSED TO set_repeat_until_stop() *** MUST MATCH ***
#  NAME PASSED TO set_repeat_until_stop_postplay_test()
set_repeat_until_stop_postplay_test("... each player drops out as he or she wishes.", &instruction_14_repeat_until_test_post)

# Handle all crescendo management in this Preplay Instruction, which fires the first time the Ensemble reaches the conclusion ... 
instruction_14_ensemble_post = lambda do |container|  
  aleatoric_ensemble = container
  
  # Every call to play(), i.e. every iteration of the repeat until loop, fires every instruction, so
  #  increment a counter here that is used in the concluding unison code below
  play_count = aleatoric_ensemble.get_state("play_count")
  
  # VERBOSE
  if not play_count.nil?
    if play_count % 100 == 0
      puts "play() called #{play_count} times"
      in_c_players.values.each do |p|    
        puts "player #{p.handle}  phrase index #{p.phrases_idx}"
        processing_elapsed_time = Time.now - processing_start_time
        puts "score processing time elapsed #{processing_elapsed_time}"
        puts "avg processing time per iteration #{processing_elapsed_time / (play_count * 1.0)}"
      end
    end
  end
  # VERBOSE
    
  if play_count == nil
    aleatoric_ensemble.set_state("play_count", 1)  
  else
    aleatoric_ensemble.set_state("play_count", play_count + 1)
  end

  if @@in_c_ensemble.reached_concluding_unison?    
    
    # Verbose timing logging
    t = Time.now
    puts "Entering concluding unison"
    
    # In practice, variations in duration from swing, added notes for phase align changes can lead to significant delta
    #  in when players arrive at the same phrase, so we need this
    # Use flags to just all this block once, which which catches each player up to the one farthest ahead
    # Get current phrase of any player because all are on the last phrase
    aleatoric_players = aleatoric_ensemble.get_players
    # NOTE: This only worked for "In C" where no players had any phrases with no notes.  In
    #  "Kashmir," player 0 had no notes until many measures in, so it broke on a divide by 0 below.
    #  Also, it wasn't meaningful in that case of imported MIDI where each measure is the same
    #  duration and each is imported as a seprate phrase, so the duration of the last "phrase"
    #  is known -- it's the duration of one measure in the meter of the input (i.e. 4/4 == D_1)
    # durations = aleatoric_players[0].current_phrase.notes.collect {|note| note.duration}
    last_phrase_dur = SCORE_SETTINGS['last_phrase_dur'] # durations.inject(0) {|sum, x| sum + x}
    # Get the start time past current latest start time so all crescendo notes start after that
    max_start = aleatoric_ensemble.players_attr_slice(:current_start).max
    # Loop through all players in the Aleatoric Ensemble
    aleatoric_players.each do |al_player|
      # Figure out how many times it needs to repeat the last phrase      
      num_plays_last_phrase = ((max_start - al_player.current_start) / last_phrase_dur).floor    
      # Append the notes of the last phrase to the output for this Player
      num_plays_last_phrase.times do 
        in_c_player = in_c_players[al_player.handle]
        phrase = al_player.current_phrase
        al_player.append_phrase_to_output(phrase=phrase, adj_start_to_current_start=true)        
      end
    end
    
    # VERBOSE
    t_new = Time.now
    puts "Appending concluding unison notes took #{(t_new - t) * 1000.0} milliseconds"
    t = Time.now
    # /VERBOSE
    
    #  "... The group then makes a large crescendo and diminuendo a few times ..."
    # Crescendo a random number of times below a settings limit
    # e.g. range is 2 to 4, min is 2, max is 4 ...
    #  2 + rand(4 - 2 + 1) == 2 + rand(3) == 2 + [0|1|2] == [2|3|4]
    min_crescendos = ENSEMBLE_SETTINGS["min_number_concluding_crescendos"]
    max_crescendos = ENSEMBLE_SETTINGS["max_number_concluding_crescendos"]
    num_crescendos = min_crescendos + rand(max_crescendos - min_crescendos + 1)            
    # Calculate the number of steps in each crescendo -- total calls to play * a fraction of 1 to determine 
    #  the length of the conclusion crescendo as a ratio of length of the whole performance, divide by
    #  number of crescendos to spread total crescendoing length over multiple crescendos
    num_crescendo_steps = (play_count * (ENSEMBLE_SETTINGS["conclusion_steps_ratio"] / num_crescendos)).ceil    
    # Split the max allowed increase in amp for a crescendo evenly among the steps of the crescendo
    volume_adj = ((ENSEMBLE_SETTINGS["crescendo_max_amp_range"] * 2).to_f / num_crescendo_steps.to_f).ceil
    if (num_crescendo_steps * volume_adj) > (ENSEMBLE_SETTINGS["crescendo_max_amp_range"] * 2)
      num_crescendo_steps = ((ENSEMBLE_SETTINGS["crescendo_max_amp_range"] * 2).to_f / volume_adj.to_f).ceil
    end
    
    # VERBOSE
    puts "num_crescendos #{num_crescendos}"
    puts "num_crescendo_steps #{num_crescendo_steps}"
    puts "volume_adj #{volume_adj}"
    # /VERBOSE
    
    
    num_crescendos.times do
      # Walk half the steps and crescendo
      cur_volume_adj = volume_adj
      num_crescendo_steps.times do     
        aleatoric_players.each do |al_player|  
          phrase = al_player.current_phrase.dup              
          phrase.notes.each do |note|             
            note.volume(note.volume + cur_volume_adj) 
          end          
          al_player.append_phrase_to_output(phrase=phrase, adj_start_to_current_start=true)
        end
        cur_volume_adj += volume_adj
      end
      
      # Walk the other half of the steps and diminuendo, using factor starting at current step
      #  and subtracting on each time through, times the volume adjusement per step, down to 0
      j = num_crescendo_steps - 1
      num_crescendo_steps.times do     
        aleatoric_players.each do |al_player| 
          phrase = al_player.current_phrase.dup
          phrase.notes.each {|note| note.volume(note.volume + (j * volume_adj))}
          al_player.append_phrase_to_output(phrase=phrase, adj_start_to_current_start=true)
        end
        j -= 1
      end  
    end
    
    # VERBOSE
    t_new = Time.now
    puts "Appending concluding crescendos took #{(t_new - t) * 1000.0} milliseconds"              
    @@in_c_ensemble.players.each do |player|
      puts "handle #{player.handle}  advanced on play next #{player.advanced_on_play_next}"
      puts "handle #{player.handle}  advanced on too far behind #{player.advanced_on_play_next2}"
      puts "handle #{player.handle}  advanced on seeking unison #{player.advanced_on_play_next3}"
      puts "handle #{player.handle}  max phrase count #{player.max_phrase_count}"
    end        
    # /VERBOSE        
        
    # ****
    # Set flag for repeat_until() handler to detect and end the performance
    @@in_c_ensemble.reached_conclusion = true    
  end  
end
set_ensemble_postplay_instruction("Instruction 14", &instruction_14_ensemble_post)


# BOILERPLATE FOR ALL user_instruction.rb FILES
# end
# /BOILERPLATE FOR ALL user_instruction.rb FILES
