require 'score'
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

@cur_section = nil
@sections = []
@sections_by_name = {}
@processing_section = false

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

# Handles keyword "section"
def section(name, &args_blk)
  @processing_section = true
  @cur_phrases.clear
  @cur_section = Section.new(name)
  @sections << @cur_section
  @sections_by_name[name] = @cur_section
  yield
  @cur_section << @cur_phrases  
  @cur_phrases.clear
  @processing_section = false
end

# Handles keyword "phrases", called inside write() block
def phrases(*names)
  # Because Score is a singleton, this can just write its notes to Score's output notes
  # This is bad because it goes in the opposite direction of the nesting logic for Notes, Phrases, etc.
  # So, lurking bugs.  Also it breaks if we want to have more than on Score.  Fine for "now."
  names.each do |name| 
    @phrases_by_name[name].notes.each do |note|
      @score_notes << note.dup
    end
  end
end

# Handles keyword "sections", called inside write() block
def sections(*names)
  names.each do |name| 
    @sections_by_name[name].notes.each do |note|
      @score_notes << note.dup
    end
  end
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

def repeat(limit, &blk)
  index = limit
  limit.times do
    yield index
    index -= 1
  end
end

def write(name, &args_blk)
  @processing_score = true
  @score_out.name = name
  # Sets write properties, and writes all notes of all Phrases and Sections into a queue
  yield
  @score_out << @score_notes
  @score_out.format = @format
  
  # TEMP DEBUG
  puts @score_out.to_s
  
  File.open(name, "w") do |f|
    f << @score_out.to_s
  end
  @processing_score = false  
end

# Handles "render" keyword, renders for csound now, eventually midi support
# score_file_name, orc_file_name=nil
def render(out_file, &args_blk)
  @processing_renderer = true
  # Set rendering params as child keyword calls in the "render" block
  yield  
  renderer = @score_out.format; score_file = @score_out.name
  @renderer.render(renderer, out_file, score_file)
  @processing_renderer = false
end

def method_missing(name, arg)
  # TEMP DEBUG
  # puts "method_missing() name = #{name}   arg = #{arg}" if @processing_renderer

  # Conditionals enforce the hierarchy from leaf to root:
  #  Note -> Phrase -> Section -> Score
  # This is in reverse order of the nested order of the blocks, so it's an implicit
  #  stack of precedence -- Notes are deepest and so always evaluated first, Phrases
  #  can contain Notes so a Note in scope should come first, but otherwise the Phrase
  #  should be considered before a Section, and so on.
  @cur_note.method_missing(name, arg) if @processing_note
  @phrase.method_missing(name, arg) if @processing_phrase
  @section.method_missing(name, arg) if @processing_section
  @score_out.method_missing(name, arg) if @processing_score
  @renderer.method_missing(name, arg) if @processing_renderer
end

end