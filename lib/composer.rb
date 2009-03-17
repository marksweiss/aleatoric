require 'score'

module Aleatoric

$SCORE = ScoreWriter.instance
$SCORES = {}
$LAST_SCORE = nil


# Score properties, toggle on/off, all on scripts get each note() call added to their Notes
def on
  $LAST_SCORE.active? true
end
def off
  $LAST_SCORE.active? false
end
# handles keyword "score," puts a new Score into the hash of all active Scores, keyed by name arg
def score(name)
  $SCORES[name] = Score.new unless $SCORES.include? name
  $LAST_SCORE = $SCORES[name]
end

# handles Note file line keyword "note," construct new Note, makes it current Note
def note(attrs=nil)
  note = Note.new(attrs)
  $SCORE << note
  $SCORES.values.each {|score| score << note if score.active?}
  note
end

# handles all other Note file line keywords, adds name val as attr to curent Note
def method_missing(name, val)
  $SCORE.method_missing_handler(name, val)
  $SCORES.values.each {|score| score.method_missing_handler(name, val) if score.active?}
end

# handles composition client command to load and execute a Note file in the context of this module
def Aleatoric.load(file)
  Kernel::load file
end

# allows composition client to push:
#  - hash of note params to become Note in current ScoreWriter
#  - string of hash of note params to become Note in current ScoreWriter
#  - a Note to append to Notes in current ScoreWriter
def push(arg=nil)
  if not arg
    note arg
  elsif arg.class == {}.class
    note arg
  elsif arg.class == "".class
    note eval(arg)
  elsif arg.class == Note.new.class
    $SCORE << arg
    $SCORES.values.each {|score| score << arg if score.active?}
  end
end

# TODO This is totally toy at this point
def csound; :csound; end
def midi; :midi; end
def write(format)
  if format == csound
    # puts $SCORE
    $SCORES.keys.each {|k| puts "*** Score = #{k} ***\n#{$SCORES[k]}"}
    $SCORE
  elsif format == midi
    puts $SCORE
    $SCORE
  end
end

end