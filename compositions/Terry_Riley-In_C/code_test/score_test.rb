require 'test/unit'
require 'score'

module CSnd

class Score_Test < Test::Unit::TestCase
  # def setup
  # end
  # def teardown
  # end
  puts "TESTING Class Score"

  def test__initialize__last_start__notes
    puts "test__initialize__last_start__notes ENTERED"
    
	# No notes passed in to score.  Gets default empty notes list.  Gets default last_start of 0.0
	# NOTE: also testing last_start() and notes() methods
    score = Score.new nil
    assert(score.last_start == 0.0)
    assert(score.notes.size == 0)	

	# Notes passed in to score.  last_start shold be start time of last note passed in.
	duration = 2.0
	note1 = CSnd::Note.new.instr(1).start(0.0).amp(100).dur(duration).pitch(2.0)
    note2 = CSnd::Note.new.instr(1).start(3.0).amp(100).dur(duration).pitch(2.0)
    score = Score.new [note1, note2]
    assert(score.last_start == 3.0)    
    assert(score.notes.size == 2)
	
    puts "test__initialize__last_start__notes COMPLETED"
  end
  
  def test__attr_slice
    puts "test__attr_slice ENTERED"
	
	note1 = CSnd::Note.new.instr(1).start(1.0).amp(100).dur(1.0).pitch(1.0)
    note2 = CSnd::Note.new.instr(2).start(2.0).amp(200).dur(2.0).pitch(2.0)
    note3 = CSnd::Note.new.instr(3).start(3.0).amp(300).dur(3.0).pitch(3.0)
    score = Score.new [note1, note2, note3]
	assert(score.attr_slice(:instr) == [1, 2, 3])
	assert(score.attr_slice(:start) == [1.0, 2.0, 3.0])
	assert(score.attr_slice(:amp) == [100, 200, 300])
	assert(score.attr_slice(:dur) == [1.0, 2.0, 3.0])
	assert(score.attr_slice(:pitch) == [1.0, 2.0, 3.0])

    puts "test__attr_slice COMPLETED"  
  end
  
  def test__empty?
    puts "test__empty? ENTERED"

	score = Score.new nil
    assert(score.empty?)

	note1 = CSnd::Note.new.instr(1).start(1.0).amp(100).dur(1.0).pitch(1.0)
    score = Score.new [note1]
    assert(! score.empty?)    
	
	note2 = CSnd::Note.new.instr(2).start(2.0).amp(200).dur(2.0).pitch(2.0)
    score = Score.new [note1, note2]
    assert(! score.empty?)    

    puts "test__empty? COMPLETED"  
  end
  
  def test__length__size
    puts "test__length__size ENTERED"

	score = Score.new nil
    assert(score.length == 0)

	note1 = CSnd::Note.new.instr(1).start(1.0).amp(100).dur(1.0).pitch(1.0)
    score = Score.new [note1]
    assert(score.length == 1)    
	
	note2 = CSnd::Note.new.instr(2).start(2.0).amp(200).dur(2.0).pitch(2.0)
    score = Score.new [note1, note2]
    assert(score.size == 2)    
	
    puts "test__length__size COMPLETED"
  end
  
  def test__each
    puts "test__each ENTERED"
	
	note1 = CSnd::Note.new.instr(1).start(1.0).amp(100).dur(1.0).pitch(1.0)
    note2 = CSnd::Note.new.instr(2).start(2.0).amp(200).dur(2.0).pitch(2.0)
    note3 = CSnd::Note.new.instr(3).start(3.0).amp(300).dur(3.0).pitch(3.0)
	score = Score.new [note1, note2, note3]
	notes_str = ""
    score.each do |note|
	  notes_str = notes_str + note.to_s + "_"
	end
	assert notes_str == "i 1 1.000 1.000 100 1.000_i 2 2.000 2.000 200 2.000_i 3 3.000 3.000 300 3.000_"
	
    puts "test__each COMPLETED"	
  end
  
  def test__insert_note
    puts "test__insert_note ENTERED"
    
    duration = 2.0
    idx = 0
    
    score = Score.new nil

    note1 = CSnd::Note.new.instr(1).start(0.0).amp(100).dur(duration).pitch(2.0)
    # With offset
    score.insert_note(idx, note1)
    assert(score.notes.size == 1)
    
    note2 = CSnd::Note.new.instr(1).start(duration).amp(100).dur(duration).pitch(2.0)
    # No offset
    score.insert_note(idx + 1, note2)
    assert(score.notes.size == 2)

    note3 = CSnd::Note.new.instr(1).start(0.0).amp(100).dur(duration).pitch(2.0)
    score.insert_note(idx + 1, note3)
    assert(score.notes.size == 3)

    notes = score.notes
    assert(notes[0] == note1)
    assert(notes[1] == note3)
    assert(notes[2] == note2)

    puts "test__insert_note COMPLETED"    
  end
  
  def test__delete_note
    puts "test__delete_note ENTERED"
    
    offset = 1.0
    duration = 2.0
    start = 0.0
    idx = 0
    
    score = Score.new nil

    note1 = CSnd::Note.new.instr(1).start(0.0).amp(100).dur(duration).pitch(2.0)
    # With offset
    score.insert_note(idx, note1)
    assert(score.notes.size == 1)
    notes = score.notes
    assert(notes[0] == note1)
    
    note2 = CSnd::Note.new.instr(1).start(offset + duration).amp(100).dur(duration).pitch(2.0)
    # No offset
    score.insert_note(idx + 1, note2)
    assert(score.notes.size == 2)
    notes = score.notes
    assert(notes[1] == note2)

    score.delete_note(note2)
    assert(score.notes.size == 1)
    assert(notes[0] == note1)

    score.delete_note(note1)
    assert(score.notes.size == 0)
    
    # Test deleting empty Score, should be a no-op and not fail, raise
    score.delete_note(note1)
    assert(score.notes.size == 0)
    
    puts "test__delete_note COMPLETED"    
  end
  
  def test__append_note
    puts "test__append_note ENTERED"
    
    score = Score.new nil 
    note1 = CSnd::Note.new.instr(1).start(0.0).amp(100).dur(2.0).pitch(2.0)
    score.append_note(note1)
    assert(score.notes.size == 1)
    notes = score.notes
    assert(notes[0] == note1)
    
    note2 = CSnd::Note.new.instr(1).start(2.0).amp(100).dur(3.0).pitch(2.0)
    score.append_note(note2)
    assert(score.notes.size == 2)
    notes = score.notes
    assert(notes[1] == note2)
	
	assert(score.last_start == 2.0)
    
    puts "test__append_note COMPLETED"    
  end
  
  def test__last_start
    puts "test__last_start ENTERED"
    
    start = 0.0
    score = Score.new nil
    assert(score.last_start == 0.0)
    
    note1 = CSnd::Note.new
    note1.instr(4).start(1.0).dur(12.0).amp(2000).pitch(5.0)    
    score.append_note(note1)
    assert(score.last_start == 1.0)

    note2 = CSnd::Note.new
    note2.instr(4).start(2.0).dur(12.0).amp(2000).pitch(5.0)    
    score.append_note(note2)
    assert(score.last_start == 2.0)
       
    puts "test__last_start FINISHED"
  end

  def test__max_start
    puts "test__max_start ENTERED"
    
    score = Score.new nil
    assert(score.max_start == 0.0)
    
    note1 = CSnd::Note.new.instr(4).start(1.0).dur(12.0).amp(2000).pitch(5.0)    
    score.insert_note(0, note1)
    assert(score.max_start == 1.0)

    note2 = CSnd::Note.new.instr(4).start(2.0).dur(12.0).amp(2000).pitch(5.0)    
    score.append_note(note2)
    assert(score.max_start == 2.0)
    
    note3 = CSnd::Note.new.instr(4).start(3.0).dur(12.0).amp(2000).pitch(5.0)
    note4 = CSnd::Note.new.instr(4).start(4.0).dur(12.0).amp(2000).pitch(5.0)
    score2 = Score.new [note3, note4]
    score.append_score score2
    assert(score.max_start == 4.0)
    
    note5 = CSnd::Note.new.instr(4).start(5.0).dur(12.0).amp(2000).pitch(5.0)
    note6 = CSnd::Note.new.instr(4).start(6.0).dur(12.0).amp(2000).pitch(5.0)
    score3 = Score.new [note5, note6]
    idx = 1
    score.insert_score idx, score3
    assert(score.max_start == 6.0)
    
    puts "test__max_start FINISHED"
  end 
  
  def test__tempo!
    puts "test__tempo! ENTERED"
    
    start = 0.0
    score = Score.new nil
    
    # Actual useful values taken from "markov_opt.sco"
    note1 = CSnd::Note.new
    note1.instr(4).start(0).dur(12).amp(2000).pitch(5)
    note2 = CSnd::Note.new
    note2.instr(4).start(4).dur(8).amp(2000).pitch(3)
    
    score.append_note(note1)
    score.append_note(note2)
    
    score.tempo!(2.0)

    notes = score.notes
    assert(notes[0].start == 0.000)
    assert(notes[1].start == 2.000)
    assert(notes[0].dur == 6.000)
    assert(notes[1].dur == 4.000)
       
    puts "test__tempo! FINISHED"
  end
  
  def test__transpose!
    puts "test__transpose! ENTERED"
    
    start = 0.0
    score = Score.new nil
    
    # Actual useful values taken from "markov_opt.sco"
    note1 = CSnd::Note.new
    note1.instr(4).start(0).dur(12).amp(2000).pitch(5)
    note2 = CSnd::Note.new
    note2.instr(4).start(4).dur(8).amp(2000).pitch(3)
    
    score.append_note(note1)
    score.append_note(note2)
    
    score.transpose!(2.0)

    notes = score.notes
    assert(notes[0].pitch == 10.000)
    assert(notes[1].pitch == 6.000)
       
    puts "test__transpose! FINISHED"
  end
  
  def test__transform!
    puts "test__transform! ENTERED"
    
    start = 0.0
    score = Score.new nil
    
    # Actual useful values taken from "markov_opt.sco"
    note1 = CSnd::Note.new
    note1.instr(4).start(0).dur(12).amp(2000).pitch(5)
    note2 = CSnd::Note.new
    note2.instr(4).start(4).dur(8).amp(2000).pitch(3)
    
    score.append_note(note1)
    score.append_note(note2)
    
    score.transform! {|n| n.instr(5)}

    notes = score.notes
    assert(notes[0].instr == 5)
    assert(notes[1].instr == 5)
       
    puts "test__transform! FINISHED"
  end
  
  def test__insert_score
    puts "test__insert_score ENTERED"
    
    start = 0.0
    score1 = Score.new nil
    score2 = Score.new nil
    
    # Actual useful values taken from "markov_opt.sco"
    note1 = CSnd::Note.new
    note1.instr(4).start(0).dur(12).amp(2000).pitch(5)
    note2 = CSnd::Note.new
    note2.instr(4).start(4).dur(8).amp(2000).pitch(3)

    note3 = CSnd::Note.new
    note3.instr(4).start(1).dur(13).amp(3000).pitch(6)
    note4 = CSnd::Note.new
    note4.instr(4).start(5).dur(9).amp(3000).pitch(4)
    
    score1.append_note(note1)
    score1.append_note(note2)
    score2.append_note(note3)
    score2.append_note(note4)
    
    notes = score1.notes

    assert(notes[0] == note1)
    assert(notes[1] == note2)

    score1.insert_score(0, score2)
    notes = score1.notes
    
    assert(notes[0] == note3)
    assert(notes[1] == note4)
    assert(notes[2] == note1)
    assert(notes[3] == note2)
       
    puts "test__insert_score FINISHED"
  end   
  
  def test__append_score
    puts "test__append_score ENTERED"
    
    start = 0.0
    score1 = Score.new nil
    score2 = Score.new nil
    
    # Actual useful values taken from "markov_opt.sco"
    note1 = CSnd::Note.new
    note1.instr(4).start(0).dur(12).amp(2000).pitch(5)
    note2 = CSnd::Note.new
    note2.instr(4).start(4).dur(8).amp(2000).pitch(3)

    note3 = CSnd::Note.new
    note3.instr(4).start(1).dur(13).amp(3000).pitch(6)
    note4 = CSnd::Note.new
    note4.instr(4).start(5).dur(9).amp(3000).pitch(4)
    
    score1.append_note(note1)
    score1.append_note(note2)
    score2.append_note(note3)
    score2.append_note(note4)
    
    notes = score1.notes

    assert(notes[0] == note1)
    assert(notes[1] == note2)

    score1.append_score(score2)
    notes = score1.notes
    
    assert(notes[0] == note1)
    assert(notes[1] == note2)
    assert(notes[2] == note3)
    assert(notes[3] == note4)
       
    puts "test__append_score FINISHED"
  end   
  
end
# /Score and ScoreTest #######################

end  
#/CSnd Module