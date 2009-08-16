require 'util'
require 'score'
require 'meter'
require 'player'
require 'ensemble'
require 'instruction'
require 'renderer'

# This module implements the basic parser/processor for the Composer language.
# At the core of the language is a simple class hierarchy that models both the main entities
#  (i.e. the "semantics") of the language and the main data structure for holding the
#  state of what the script has declared at any point in time.  These are the notes and groupings
#  of notes the script is working with, some or all of which end up in some form in the final
#  output script.

# The hierarchy looks like this:
# Score (attrs: output format (csound | midi), grouping options, sorting options, etc.)
#   - Section/Movement (attrs: ?)
#     - Phrase/Measure (attrs: transposed?, transpose_action [i.e. - a block], etc.)
#        - Note (attrs: instrument, start, end, amplitude, pitch, function_table, etc.)

# Notes are the leaf of this tree, i.e. - Notes cannot contain Notes or any other objects 
#  but can only have attributes which are either ints, reals or strings.
# Phrases (or Measures, an alias), just as in standard musical notation, are collections of Notes.
#  They may define attributes that transform the Notes they are holding.  Maybe other attrs
#  as needed too.
# Sections are intended to group Phrases into longer, well, sections of a composition.
#  Movement is an alias.

# However, this hierarchy can also be bypassed, partially.  Phrases and Sections are simply 
#  conveniences -- for example, it can be really handy to create a a few bars of notes, give that a name
#  and reuse that as needed.  It can also make a piece more understandable and is a common
#  musical convention to have sections that group a series of measures/phrases 
#  - "intro," "bridge," "coda" etc.  But you don't need to do this.  To produce an output that
#  gets rendered into an audio file you need only create Notes, and then include the 'write'
#  statement.

# The one exception to this is that you do need at least one Phrase or Section wrapping the Notes
#  in a piece that you want to include in the output.

# Scores are structured in "blocks."  Sections contain Phrases, and Phrases containt Notes.
# Then, when all Notes have been defined, a 'write' and then a 'render' statement follow, 
#  specifying the format of output desired.  These are separate because it can be useful to
#  write a script file without rendering a sound file, as the latter can sometimes take 
#  some time and you may be trying to fix unexpected output and not want to wait on rendering.

module Aleatoric

@cur_note = nil
@notes = []
@notes_by_name = {}
@processing_note = false

@cur_phrase = nil
@cur_phrases = []
@phrases = []
@phrases_by_name = {}
@processing_phrase = false

@cur_sections = []
@cur_section = nil
@sections = []
@sections_by_name = {}
@processing_section = false

@meter = Meter.new(quantizing=false)

@cur_start = 0.0
@cur_measure = nil
@measures = []
@measures_by_name = {}
@processing_measure = false

@processing_instruction = false
@cur_instruction = nil
@instructions_by_name = {}
@processing_improvisation = false  
@cur_improvisation = nil  
@improvisations_by_name = {}
@ordered_improvisations = []
# NOTE: these need to be module scope across all files in the module, which is
#  true @@ 'module scope' rather than @ 'module scope'.  The latter is visible
#  across translation units in the module, but is not guaranteed to be 
#  initialized when called from another translation unit.  @@ is true module scope
#  and is guaranteed to be initialized when referenced by any methods in the module
#  in any translation unit.
# These guys are referred to by the set_*instruction() methods, which live here but are called
#  from the 'user_instructions.rb' translation unit, where the programmer/composer
#  puts 'instruction' keyword definitions and maps them to their name with the set_*_instruction() call
@@player_preplay_instructions = {}
@@player_postplay_instructions = {}
# Supports syntax of passing an improve name (play by key) or not passing a name
#  and then just playing the last 'improvisation' kw improv hook defined, i.e. @@ordered_improv_instructions.last 
@@improvisations = {}
#
def set_player_preplay_instruction(instruction_name, &instr_blk)
  @@player_preplay_instructions[instruction_name] = instr_blk
end
def set_player_postplay_instruction(instruction_name, &instr_blk)
  @@player_postplay_instructions[instruction_name] = instr_blk
end
def set_improvisation(instruction_name, &instr_blk)
  @@improvisations[instruction_name] = instr_blk
end

@@ensemble_preplay_instructions = {}
@@ensemble_postplay_instructions = {}
def set_ensemble_preplay_instruction(instruction_name, &instr_blk)
  @@ensemble_preplay_instructions[instruction_name] = instr_blk
end
def set_ensemble_postplay_instruction(instruction_name, &instr_blk)
  @@ensemble_postplay_instructions[instruction_name] = instr_blk
end

@processing_play = false
@processing_improvise = false
@processing_player = false
@processing_ensemble = false
@cur_ensemble = nil
@ensembles = []
@ensembles_by_name = {}
@cur_player = nil
@cur_players = []
@players = []
@players_by_name = {}

@write_called = false
DEFAULT_EXT = '.ext'
@score_out = ScoreWriter.instance
@processing_score = false
@score_notes = []

@renderer = Renderer.instance
@processing_renderer = false


# Handles keyword "note," assigns attrs in block to a new Note
def note(name=nil, &args_blk)
  # Set flag for method_missing() so it traps methods and adds to this Note
  @processing_note = true
  # Declare the new Note  
  @cur_note = Note.new(name)
  # Now run the block. This call all the method_missing attribute functions, thus
  #  passing their name and arg to Note.method_missing, and thus adding them as attrs of this Note
  yield
  # Notes must always be created in the context of a containing Phrase or Section
  # This is the queue of Notes being created in that containing block, which that object
  #  will then pick up and append to its collection of Notes.  So the containing block
  #  is responsible for clearing this at the start and end of its block, before its yield.
  @notes << @cur_note
  # Notes are also stored by name, if they are named, for convenient random access by key
  #  at any point later in the script. This is an internal data structure and these are not
  #  put into the output Score
  @notes_by_name[name] = @cur_note unless name == nil
  # We're done with this Note, unset method_missing() flag
  @processing_note = false
  
  # Each note can adjust @cur_start, which supports start NEXT in 'measure' blocks
  # Sort of lame we have to list-ify it, but the same method takes a list for 'copy_measure'
  adjust_cur_start [@cur_note]
  
  # Return the note, useful for testing purposes only. Allows independent testing of function
  #  and no additional exposure of module state, e.g. @notes
  @cur_note
end

# Handles keyword "phrase"
def phrase(name, &args_blk)
  @processing_phrase = true
  # Init (clear) the queue of notes created -- this holds state contained by this block scope
  @notes.clear
  @cur_phrase = Phrase.new(name)
  # State that persists for the life of the score
  @phrases << @cur_phrase
  # State that is built/torn down within current containing section block, if any, or just ignored
  @cur_phrases << @cur_phrase
  # NOTE: nil name breaks because then Phrase can't be retrieved by key in write() block
  @phrases_by_name[name] = @cur_phrase
  # Construct and put into @notes queue all Notes in the block for this Phrase block
  yield args_blk
  # Now add them to the Notes in this Phrase object
  @cur_phrase << @notes  
  # Phrase just copied the Notes, so clear the queue again (redundant, but a bug waiting to happen)
  @notes.clear
  @processing_phrase = false
end

def meter(beat_per_measure, beat_length, &args_blk)  
  @meter.beat_per_measure beat_per_measure
  @meter.beat_length beat_length
  # This will end up firing quantize() immediately below, won't go to method_missing
  #  because there is a local match
  yield
end

def on; 'on'; end
def off; 'off'; end
def quantize(flag_str)
  @meter.quantizing?(true) if flag_str == on
  @meter.quantizing?(false) if flag_str == off
end

def measure(name, &args_blk)
  @processing_measure = true
  @notes.clear
  # A measure is a Phrase but it's also passed a position, which is the ordinal position of the
  #  measure among all measures, and a start offset
  # This lets sequences of measures not need to figure out their offset from the beginning
  # So you have this:
  #   note
  #     start QRTR
  # instead of this:
  #   note
  #     start running_total_since_start + QRTR  
  @cur_measure = Measure.new(name, @cur_start)
  # NOTE: Need to wrap yield call (which processes notes) to put Note in scope as the 
  #  method_missing() handler or else the 'start' attribute from the script is trapped
  #  by Measure, which has a 'start' property, and doesn't reach the note, and changes
  #  the value for Measure.start inadvertantly. i.e. - but that took 90 minutes to find
  @processing_measure = false
  @processing_note = true
  yield args_blk
  @processing_note = false
  @processing_measure = true
  @notes = @meter.quantize(@notes) if @meter.quantizing?
  @cur_measure << @notes  
  @measures << @cur_measure
  @measures_by_name[name] = @cur_measure
  @notes.clear
  @processing_measure = false  
end

# TODO Why not also have copy_section, copy_phrase and copy_note?
# Only reason is they's stack up on the same start time ...
def copy_measure(src_name, target_name)
  @cur_measure = @measures_by_name[src_name].dup
  @cur_measure.name = target_name 
  @cur_measure.reset_notes @cur_start
  @cur_measure.notes.each do |note|
    @notes << note
  end  
  @measures << @cur_measure
  @measures_by_name[target_name] = @cur_measure
  adjust_cur_start @cur_measure.notes
end

def adjust_cur_start(notes)
  new_start = (notes.collect {|note| note.start + note.duration}).max  
  @cur_start = new_start if new_start > @cur_start
end

# Handles keyword "section"
def section(name, &args_blk)
  @processing_section = true
  @cur_phrases.clear
  @cur_section = Section.new(name)
  @sections << @cur_section
  @cur_sections << @cur_section
  @sections_by_name[name] = @cur_section
  yield args_blk
  @cur_section << @cur_phrases  
  @cur_phrases.clear
  @processing_section = false
end

def player(name, &args_blk)
  @processing_player = true
  if not @players_by_name.include? name
    @cur_player = Player.new(name)
    @players_by_name[name] = @cur_player
    @players << @cur_player
  else
    @cur_player = @players_by_name[name]
  end
  @cur_player.ensemble = @cur_ensemble
  
  @cur_sections.clear
  @cur_phrases.clear
  
  yield
  
  @cur_sections.each do |section|
    section.phrases.each do |phrase|
      @cur_player.add_score(phrase.name, phrase)
    end
  end
    
  @cur_phrases.each do |phrase|
    @cur_player.add_score(phrase.name, phrase)
  end

  @cur_sections.clear
  @cur_phrases.clear 
  @processing_player = false  
end

# NOTE: CANNOT mix section and phrase in an ensemble block
# CAN have 1 or more sections or 0 sections and instead 1 or more phrases
# So supports either but still hierarchical structure with ensemble a parent 
#  of sections or phrases but not both
def ensemble(name, &args_blk)
  @processing_ensemble = true
  @cur_players.clear
  @cur_sections.clear
  @cur_phrases.clear
  
  @cur_ensemble = Ensemble.new(name)
  @ensembles << @cur_ensemble
  @ensembles_by_name[name] = @cur_ensemble

  yield

  @cur_players.each do |player| 
    player.ensemble = @cur_ensemble
    @cur_ensemble.add_player(player.name, player)
    
    if @cur_sections.length > 0
      @cur_sections.each do |section|
        section.phrases.each do |phrase|
          player.add_score(phrase.name, phrase)
        end
      end
    end
    
    if @cur_phrases.length > 0
      @cur_phrases.each do |phrase|
        player.add_score(phrase.name, phrase)
      end
    end
  end
      
  @cur_players.clear
  @cur_sections.clear
  @cur_phrases.clear  
  @processing_ensemble = false  
end

def play
  @processing_play = true
  yield
  @processing_play = false
end

def improvise(name=nil)
  @processing_improvise = true
  # If no name passed, set current improv to the most recent one declared, else
  #  set it to the one matching the name passed in
  if name == nil  
    @cur_improvisation = @ordered_improvisations.last
  else
    @cur_improvisation = @improvisations_by_name[name]
  end
  #
  yield
  @processing_improvise = false
end

def players(*names)
  if @processing_ensemble
    names.each do |name| 
      name = name.strip
      if not @players_by_name.include? name
        @players_by_name[name] = Player.new(name)
        @players << @players_by_name[name]
      end
      @cur_players << @players_by_name[name]      
    end
  end
  
  if @processing_instruction
    names.each do |name|
      name = name.strip
      player = @players_by_name[name]
      instr_name = @cur_instruction.name
      # Note the pass by '&' to pass as a lambda which the recieving method in Player stores as a Proc and then calls 'call()' to run it
      player.add_preplay_hook(instr_name, &@@player_preplay_instructions[instr_name]) if @@player_preplay_instructions.include? instr_name
      player.add_postplay_hook(instr_name, &@@player_postplay_instructions[instr_name]) if @@player_postplay_instructions.include? instr_name
    end    
  end

  if @processing_improvisation
    names.each do |name| 
      player = @players_by_name[name]
      improv_name = @cur_improvisation.name      
      player.add_improvisation_hook(improv_name, &@@improvisations[improv_name]) if @@improvisations.include? improv_name
    end    
  end
  
  if @processing_play
    names.each do |name|
      name = name.strip    
      @players_by_name[name].play if @players_by_name.include? name
    end 
  end
  
  if @processing_improvise
    names.each do |name|
      name = name.strip
      @players_by_name[name].improvise(@cur_improvisation.name) if @players_by_name.include? name
    end 
  end  
  
  if @processing_score
    names.each do |name| 
      name = name.strip
      player = @players_by_name[name]
      if player != nil
        player.output.each do |note|        
          @score_notes << note
        end
        player.clear_output
      end
    end
  end
end

def instruction(name)
  @processing_instruction = true  
  @cur_instruction = Instruction.new(name)  
  @instructions_by_name[name] = @cur_instruction  
  yield
  @processing_instruction = false  
end

def improvisation(name)
  @processing_improvisation = true  
  @cur_improvisation = Improvisation.new(name)   
  @improvisations_by_name[name] = @cur_improvisation
  @ordered_improvisations << @cur_improvisation
  yield
  @processing_improvisation = false  
end

def description(desc)
  @cur_instruction.description = desc if @processing_instruction
  @cur_improvisation.description = desc if @processing_improvisation
end

# Handles keyword "phrases", called inside write() block
def phrases(*names)
  # Because Score is a singleton, this can just write its notes to Score's output notes
  # This is bad because it goes in the opposite direction of the nesting logic for Notes, Phrases, etc.
  # So, lurking bugs.  Also it breaks if we want to have more than on Score.  Fine for "now."
  names.each do |name| 
    name = name.strip
    phrase = @phrases_by_name[name]
    phrase.notes.each do |note|
      @score_notes << note.dup
    end
  end
end

def measures(*names)
  if names != nil and names.length > 0
    names.each do |name| 
      name = name.strip
      measure = @measures_by_name[name]    
      measure.notes.each do |note|
        @score_notes << note.dup
      end
    end
  else
  
    # TODO replace with @measures_by_name[name].keys.each and get rid of @measures
    @measures.length.times do |j|
      @measures[j].notes.each do |note|
        @score_notes << note.dup
      end
    end
  end
end

# Handles keyword "sections", called inside write() block
def sections(*names)
  names.each do |name|
    name = name.strip
    section = @sections_by_name[name]
    section.phrases.each do |phrase|
      phrase.notes.each do |note|
        @score_notes << note.dup
      end
    end
  end
end

# Handles keyword "ensembles", called inside write() block
def ensembles(*names)
  if @processing_instruction
    names.each do |name| 
      ensemble = @ensembles_by_name[name.strip]
      instr_name = @cur_instruction.name      
      # Note the pass by '&' to pass as a lambda which the recieving method in Player stores as a Proc and then calls 'call()' to run it
      ensemble.add_preplay_hook(instr_name, &@@ensemble_preplay_instructions[instr_name]) if @@ensemble_preplay_instructions.include? instr_name
      ensemble.add_postplay_hook(instr_name, &@@ensemble_postplay_instructions[instr_name]) if @@ensemble_postplay_instructions.include? instr_name
    end    
  end
  
  if @processing_play
    names.each do |name| 
      name = name.strip
      ensemble = @ensembles_by_name[name]
      # Will run ensemble.play_all, which plays ensemble preplay hooks,
      #  calls play on each player in ensemble (running their preplay hooks, 
      #  then generating their output, then running their postplay hooks),
      #  then calls ensemble postplay hooks
      ensemble.play_all if ensemble != nil
    end 
  end
  
  if @processing_score
    names.each do |name| 
      name = name.strip
      ensemble = @ensembles_by_name[name]
      ensemble.players.each do |player|
        player.output.each do |note|
          @score_notes << note
        end
        player.clear_output
      end
    end    
  end  
end

def repeat(limit, &blk)
  # NOTE: 1-based loops.  Shoot me now!  But 1-based loops make more sense in this domain,
  #  particularly since the typical use case is to use the index as a factor of multiplication in
  #  a loop.  In that case, identity is 1 (the base case, that has no effect) and 0 is a special
  #  case returning no value.  The user should have to choose the 0 case,
  #  not have it thrust on them silently.
  @notes.clear
  index = 1
  limit.times do
    # Pass the index to the block
    yield index
    index += 1
  end
  
  # Now add them to the Notes in the currently nearest Phrase, which should be the parent of this node
  @cur_phrase << @notes  
  @notes.clear
end

# Handles constant arg to method_missing "format" function in "write" block
# NOTE: This didn't work returning a symbol, but did work returning a string, why?
def csound; "csound"; end
# handles keyword "write"
# NOTE: MUST implement "format" keyword, because can't method_missing() it because there is a
#  default private format() method on class Object. Nice.
def format(name)
  @format = name
end

def write(name, &args_blk)
  
  @processing_score = true
  @score_out.name = name
  # Sets write properties, and writes all notes of all Phrases and Sections into a queue
  yield
  @score_out << @score_notes
  @score_out.to_s_format @format  
  
  File.open(name, "w") do |f|
    f << @score_out.to_s
  end
  @processing_score = false
  @write_called = true
end

# Handles "render" keyword, renders for csound now, eventually midi support
# score_file_name, orc_file_name=nil
def render(out_file, &args_blk)  

  # TEMP DEBUG
  debug_log "HERE"

  @processing_renderer = true
  # Set rendering params as child keyword calls in the "render" block
  yield  
  
  # If write not called, then call it here to flush all notes before rendering
  write(out_file + DEFAULT_EXT, &args_blk) if not @write_called

  @renderer.render(renderer=@score_out.format, out_file=out_file, score_file=@score_out.name)
  @processing_renderer = false
end

# FOR UNIT TESTING
def dump_notes
  File.open("..\\test\\composer_test_results.txt", "w") do |f|
    @notes.each do |note|
      f << (note.to_s + "\n")
    end
  end
end

def dump_last_note
  File.open("..\\test\\composer_test_results.txt", "w") do |f|
    f << @notes.last.to_s
  end
end

def dump_last_phrase
  File.open("..\\test\\composer_test_results.txt", "w") do |f|
    @phrases.last.notes.each do |note|
      f << (note.to_s + "\n")
    end
  end
end

def dump_last_section
  File.open("..\\test\\composer_test_results.txt", "w") do |f|
    @sections.last.phrases.each do |phrase|
      phrase.notes.each do |note|
        f << (note.to_s + "\n")
      end
    end
  end
end

def dump_last_ensemble
  File.open("..\\test\\composer_test_results.txt", "w") do |f|    
    ensemble = @ensembles.last
    players = ensemble.players
    f << ensemble.name + "\n"
    f << players.length.to_s + "\n"
    players.each do |player|        
      f << player.name + "\n"
    end
  end
end

def dump_last_player
  File.open("..\\test\\composer_test_results.txt", "w") do |f|
    f << @players.last.name
  end
end

def reset_script_state
  # *** KEEP THIS HERE ALWAYS ***
  @score_out.clear
  # *** KEEP THIS HERE ALWAYS ***

  @cur_note = nil
  @notes = []
  @notes_by_name = {}
  @processing_note = false

  @cur_phrase = nil
  @cur_phrases = []
  @phrases = []
  @phrases_by_name = {}
  @processing_phrase = false

  @cur_sections = []
  @cur_section = nil
  @sections = []
  @sections_by_name = {}
  @processing_section = false
  
  @meter = Meter.new(quantizing=false)
  
  @cur_measure = nil
  @measures = []
  @processing_measure = false
  @measures_by_name = {}
  @cur_start = 0.0
  
  @processing_instruction = false
  @cur_instruction = nil
  @instructions_by_name = {}
  @processing_improvisation = false  
  @cur_improvisation = nil  
  @improvisations_by_name = {}
  @@ordered_improv_instructions = []
  # *** KEEP THIS HERE ALWAYS ***
  # Don't reset, because these are set at beginning of run
  #  and live for lifetime of run of a process
  #  because they are set by a require at top of overall
  #  test.altc file, which includes all of the separate test scripts
  # @@player_preplay_instructions = {}
  # @@player_postplay_instructions = {}
  # @@improvisations = {}
  # *** KEEP THIS HERE ALWAYS ***
  
  @processing_play = false
  @processing_improvise = false
  @processing_player = false
  @processing_ensemble = false
  @cur_ensemble = nil
  @ensembles = []
  @ensembles_by_name = {}
  @cur_player = nil
  @cur_players = []
  @players = []
  @players_by_name = {}

  @write_called = false
  @processing_score = false
  @score_notes = []
  
  @processing_renderer = false

end
# /FOR UNIT TESTING

def method_missing(name, arg)
  # Conditionals enforce the hierarchy from leaf to root:
  #  Note -> Phrase -> Section -> Score
  # This is in reverse order of the nested order of the blocks, so it's an implicit
  #  stack of precedence -- Notes are deepest and so always evaluated first, Phrases
  #  can contain Notes so a Note in scope should come first, but otherwise the Phrase
  #  should be considered before a Section, and so on.
  @cur_note.method_missing(name, arg) if @processing_note
  @cur_phrase.method_missing(name, arg) if @processing_phrase
  @cur_section.method_missing(name, arg) if @processing_section
  @cur_measure.method_missing(name, arg) if @processing_measure
  @score_out.method_missing(name, arg) if @processing_score
  @renderer.method_missing(name, arg) if @processing_renderer
end

end