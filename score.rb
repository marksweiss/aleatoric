require 'note'

=begin RDoc
Is this the canonical missing Array function? Also inject() is not intuitive at all.
=end
class Array
  def sum
    inject(0) {|sum, x| sum + x}
  end
end

module CSnd
  
# Score and ScoreTest #######################

=begin RDoc
This class represents a Score in CSound.  A Score is just a collection of
Notes that will be printed to a *.sco file in the order they are added to the
Score.
=end
class Score
  
  # This is an enumerable class; it defines an each iterator below.
  include Enumerable   # Include the methods of this module in this class  
  
  public
   
=begin RDoc
Args:
1. <i>file_name</i> An optional file name for the *.sco file
2. <i>instr_include</i> An optional name of an include file that will be printed as the first line in the Score. This is a CSound include of an instrument file defining instrumentes referred to by number in the notes' instrument values (column 1) in each line of the Score.
3. <i>last_start</i> An optional offset from time == 0 for the offset of the first note in the score. Each call to <tt>insert_note</tt> or <tt>append_note</tt> can pass in an <i>offset</i> that will offset from the last value of <i>last_start</i>, which is then adjusted to this new value for the next call. 
=end
  def initialize(notes=nil)
    @notes = notes || []
    @max_start = attr_slice(:start).max || 0.0
  end

  #
  # Accessors/Iterators

=begin RDoc
Retrieve the array of all Notes in the Score
=end
  def notes
    @notes
  end

  # Slicer to return the list of values for a Note attribute for all Notes in the Score
  def attr_slice(attr)  
    @notes.collect do |note| 	  
	  note.send(attr)
	end
  end
  
=begin RDoc
Returns empty? for the list of Notes in the Score
=end
  def empty?
    @notes.empty?
  end

=begin RDoc
Returns 0.0 if the Score is empty, or the start time of the last Note in the sequence
of Notes in the Score if the score is not empty.
=end
  def last_start
    @notes.empty? ? 0.0 : @notes.last.start
  end

=begin RDoc
Returns the max for the start instance variable value among all
Notes in the Score
=end
  def max_start
    @max_start
  end

=begin RDoc 
This is the iterator required by the Enumerable module
=end
  def each
    @notes.each {|note| yield note}
  end

=begin RDoc
Returns the number of Notes the Score has
=end
  def length
    @notes.length
  end
  alias size length
  
  def duration
    attr_slice(:dur).sum
  end
  alias dur duration

  #
  # Modify Score

=begin RDoc
Insert a <i>note</i> at position <i>idx</i> in the Score.  Optional <i>offset</i> will adjust the <i>start</i> value of note to the sum of the current value of <i>last_start + offset</i>.
=end
  def insert_note(idx, note)
    @notes.insert(idx, note)
    @max_start = note.start if note.start > @max_start
    self
  end
  
=begin RDoc
Insert all <i>notes in score</i> at position <i>idx</i> in the Score.
=end
  def insert_score(idx, score)
    @notes.insert(idx, score.notes).flatten!
	# List of current score notes start values, append current @max_start, get max of that list 
    @max_start = (score.attr_slice(:start).push(@max_start)).max
    self
  end  

=begin RDoc
Append a <i>note</i> as the last note in the Score.
=end
  def append_note(note)
    self.insert_note(@notes.length, note)
    @max_start = note.start if note.start > @max_start
    self
  end
  
=begin RDoc
Append a <i>notes in score</i> at position <i>idx</i> in the Score.
=end
  def append_score(score)
    self.insert_score(@notes.length, score)
	# List of current score notes start values, append current @max_start, get max of that list 	
    @max_start = (score.attr_slice(:start).push(@max_start)).max
    self
  end  

=begin RDoc
Delete <b>all instances</b> of Notes in the Score that == argument <i>note</i>.
=end
  def delete_note(note)
    @notes.delete(note)
    self
  end
  
  #
  # Modify Notes in Score
  
=begin RDoc
Modify all start times and durations of all Notes in the Score by a factor of 1/tempo.
=end
  def tempo!(tempo)
    @notes.map! {|note| note.start(note.start * (1.0/tempo)).dur(note.dur * (1.0/tempo))}
    self
  end
  
=begin RDoc
Modify the pitch of all Notes in the Score by a factor of pitch.
=end
  def transpose!(pitch)
    @notes.map! {|note| note.pitch(note.pitch + pitch)}
    self
  end

=begin RDoc
Apply &proc to each Note in the Score
=end  
  def transform!(&proc)
    @notes.map! {|note| proc.call(note)}
    self
  end

=begin RDoc
Returns a new Score with a dup() of each note, so a deep copy
=end
  def dup
    Score.new @notes.collect {|note| note.dup}
  end
  
  #
  # Write/Utils
  
=begin RDoc
Write the Score file.
=end
  def write(file_name, instr_include)
    # Truncates existing
    File.open(file_name, "w") do |f| 
      f << ("#include #{instr_include}\n\n") if instr_include.length > 0
      @notes.each do |note|	  
        f << note << "\n"
	  end
    end
  end
  
=begin RDoc
Partitions all Notes by their player_id, and writes each partition to its own output file
=end
  def write_partitioned(file_name, instr_include)
    partitioned_notes = {}
    @notes.each do |note|
      k = note.player_id      
      if not partitioned_notes[k] then
        partitioned_notes[k] = [note]
      else
        partitioned_notes[k].push(note)
      end      
    end
    
    file_name_base, file_ext = file_name.split(".")
    partitioned_notes.keys.each do |player|
      notes = partitioned_notes[player]
      File.open("#{file_name_base}#{player}.#{file_ext}", "w") do |f| 
        f << ("#include #{instr_include}\n\n") if instr_include.length > 0     
        notes.each do |note| 
          f << note << "\n"
        end
	  end
    end
  end
  
=begin RDoc
Append a write the Score file.
=end
  def write_append
    File.open(@file_name, "a") do |f| 
      @notes.each do |note| 
        f << note << "\n"
      end
    end   
  end

=begin RDoc  
Generates a Score in which all of the notes of this score are the same in all
attributes except amp, which is set to rest (i.e. 0) for all Notes.  So you have
a phrase of the same duration, which is silent
=end
  def rest
	ret = []
	@notes.each do |n|
	  ret.push CSnd::Note.rest(n, n.dur, n.player_id)
	end
    Score.new ret
  end
  
end  # /Score

end
#/CSnd Module
