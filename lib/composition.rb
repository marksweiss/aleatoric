require 'composer'
include Aleatoric

# Load notes from file, written in plain DSL (no punctuation at all, note lines and
#  attrs one to a line with whitespace between attr and value), or passing a hash
#  of note attrs, or passing a string of a hash of note attrs, or passing nil which pushes
#  a default note onto the score
load("../test/note.in")

# Push a default note
push
# Push a new note with these attrs
push :instrument => 8, :start => 0.0, :duration => 1.0, :amplitude => 1000, :pitch => 8.03
# Push a new note with these attrs
push "{:instrument => 9, :start => 0.0, :duration => 2.0, :amplitude => 1200, :pitch => 8.06}"
# Push a new note
push Note.new({:instrument => 10, :start => 0.0, :duration => 1.0, :amplitude => 1300, :pitch => 11.01})

puts $SCORE
