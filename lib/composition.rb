require 'composer'
include Aleatoric

# Load notes from file, written in plain DSL (no punctuation at all, note lines and
#  attrs one to a line with whitespace between attr and value), or passing a hash
#  of note attrs, or passing a string of a hash of note attrs, or passing nil which pushes
#  a default note onto the score
# Wrap file in module directive so it works but this is hiden from user

file_name = "../test/note.in"
#file = IO.read(file_name)
#header = "module Aleatoric\n\n"
#footer = "\n\nend"
#open(file_name, 'w') {|f| f << header << file << footer} 
load file_name
#open(file_name, 'w') {|f| f << file} 

# Push a default note
# push
# Push a new note with these attrs
# push :instrument => 80, :start => 0.0, :duration => 1.0, :amplitude => 1000, :pitch => 8.03
# Push a new note with these attrs
# push "{:instrument => 90, :start => 0.0, :duration => 2.0, :amplitude => 1200, :pitch => 8.06}"
# Push a new note
# push note({:instrument => 100, :start => 0.0, :duration => 1.0, :amplitude => 1300, :pitch => 11.01})

# write csound

puts @note_state.to_s
puts @phrases.to_s