require 'score'

module Aleatoric

# Notes are ordered but are cleared after each add() block, anonymous so just a list, no hash
@notes = []
# Flag controls clearing hte notes queue @notes
@notes_add_flag = true
# Scores are stored by name and must be ordered, so hash and list
# Score out is a special case singleton Score, master score writing final output
@score_out = ScoreWriter.instance
@scores = {}
@score_names = []
# Phrases are stored by name and must be ordered, so hash and list
@phrases = {}
@phrase_names = []
# Players are just stored by name, not ordered, so just hash
@players = {}

# handles Note file line keyword "note," construct new Note, makes it current Note
def note(attrs=nil)
  if @notes_add_flag
    @notes_add_flag = false
    @notes = []
  end
  @notes << Note.new(attrs)
end

# handles all other Note file line keywords, adds name val as attr to curent Note
def method_missing(name, *args)
  #puts name
  #puts args[0]

  @notes.last.method_missing(name, args[0])
end

# handles keyword "phrase"
def phrase(*names)
  names.each do |name| 
    @phrases[name] = Phrase.new unless @phrases.include? name
    @phrase_names << name unless @phrase_names.include? name
    @phrases[name] << @notes
  end
end

# handles keyword "player"
def player(*names)
  names.each do |name| 
    @players[name] = Player.new unless @players.include? name
    @players[name] << @notes
  end
end

# handles phrases "add notes" or "add phrases" which are then followed by 
#  block (with not do/end notation) of players and phrases that do the add operation
#  on the current queue of stuff they care about.
def notes; :notes; end
def phrases(*args); :phrases; end
def add(add_type)
  if add_type == :notes
    @notes_add_flag = true   
  end
end

# TODO This is totally toy at this point
def csound; :csound; end
def midi; :midi; end
def write(format)
  if format == csound
    puts "\nCSound Score\n\n"
    @score_out.notes.each {|note| puts "#{note}\n"}
    puts "\nCSound Phrases\n\n"
    @phrases.values.each {|phrase| phrase.notes.each {|note| puts "#{note}\n"}}
    puts "\nCSound Players\n\n"
    @players.values.each {|player| player.notes.each {|note| puts "#{note}\n"}}
  elsif format == midi
    puts "MIDI Score\n"
    @score_out.notes.each {|note| puts "#{note}\n"}
    puts "MIDI Phrases\n"
    @phrases.values.each {|phrase| phrase.notes.each {|note| puts "#{note}\n"}}
    puts "CSound Players\n"
    @players.values.each {|player| player.notes.each {|note| puts "#{note}\n"}}
  end
end

# handles composition client command to load and execute a Note file in the context of this module
def load(file)
  Kernel::load file
end

end