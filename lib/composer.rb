require 'score'

module Aleatoric

$SCORE = ScoreWriter.instance
instrument = :instrument

# handles Note file line keyword "note," construct new Note, makes it current Note
def note(attrs=nil)
  $SCORE << Aleatoric::Note.new(attrs)  
end

#def instrument(val)
  # TEMP DEBUG
#  puts "val = #{val}"
  
#  $SCORE.method_missing_handler(:instrument, val)
#end
  
# handles all other Note file line keywords, adds name val as attr to curent Note
def method_missing(name, val)
  $SCORE.method_missing_handler(name, val)
end

# handles composition client command to load and execute a Note file in the context of this module
def load(file)
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
  end
end

end