$LOAD_PATH << "..\\lib"
require 'player'
require 'test/unit'
require 'rubygems'
require 'ruby-debug' ; Debugger.start

module Aleatoric

class Player_Test < Test::Unit::TestCase

  def test__initialize
    puts "test__initialize ENTERED"

    player = Player.new("Test Player")
    assert(player.class == Player)
    
    puts "test__initialize COMPLETED"
  end

  def test__add_score__append_score__scores_length__scores_size
    puts "test__add_score__append_score__scores_length__scores_size ENTERED"

    player = Player.new("Test Player")
    player.add_score Score.new
    assert(player.scores_length == 1)
    player.append_score Score.new
    assert(player.scores_size == 2)
    
    puts "test__add_score__append_score__scores_length__scores_size COMPLETED"
  end

  def test__scores_index__scores_empty__clear_scores__scores_index_increment__scores_index_decrement
    puts "test__scores_index__scores_empty__clear_scores__scores_index_increment__scores_index_decrement ENTERED"

    player = Player.new("Test Player")
    player.add_score Score.new
    assert(player.scores_length == 1)
    player.append_score Score.new
    assert(player.scores_size == 2)
    player.clear_scores
    assert(player.scores_size == 0)    
    assert(player.scores_empty?)
    assert(player.scores_index == Player.no_index)
    player.add_score Score.new
    assert(player.scores_index == 0)
    # Test don't increment past end of scores
    player.increment_scores_index
    assert(player.scores_index == 0)
    player.add_score Score.new
    # Use alias for 'increment', 'inc' is also valid
    player.increment        
    assert(player.scores_index == 1)
    player.add_score Score.new 
    # Use alias for 'decrement', 'decrement' is also valid
    player.dec
    assert(player.scores_index == 0)
    
    puts "test__scores_index__scores_empty__clear_scores__scores_index_increment__scores_index_decrement COMPLETED"
  end

  def test__current_score
    puts "test__current_score ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new note_1_name
    note_2 = Note.new note_2_name
    score_1 = Score.new
    score_1 << [note_1, note_2]
    player.add_score score_1
    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new note_3_name
    note_4 = Note.new note_4_name
    score_2 = Score.new    
    score_2 << [note_3, note_4]
    player.add_score score_2
    expected = score_1.notes
    actual = player.current_score.notes    
    assert(expected == actual)
    
    puts "test__current_score COMPLETED"
  end
  
  def test__remove_score
    puts "test__remove_score ENTERED"

    player = Player.new("Test Player")
    score_name = "score 1"
    score_1 = Score.new(score_name)
    player.add_score score_1
    assert(player.scores_length == 1)
    player.remove_score(score_1.name)
    assert(player.scores_size == 0)
    
    puts "test__remove_score COMPLETED"
  end

  def test__play
    puts "test__play ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new note_1_name
    note_2 = Note.new note_2_name
    expected_1 = [note_1, note_2]
    score = Score.new
    score << expected_1
    player.add_score score

    player.play
    actual = player.output
    
    assert(actual.length == expected_1.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new note_3_name
    note_4 = Note.new note_4_name
    expected_2 = [note_3, note_4]
    score_2 = Score.new
    score_2 << expected_2
    
    player.clear_output
    player.add_score score_2
    player.play
    player.increment
    player.play
    actual = player.output
        
    assert(actual.length == expected_1.length + expected_2.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)
    assert(actual[2].name == expected_2[0].name && actual[3].name == expected_2[1].name)
    
    player.clear_scores
    player.clear_output
    player.add_score score
    player.play
    actual = player.output    
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)
    
    puts "test__play COMPLETED"
  end
  
  def test__add_preplay_hook__get_preplay_hook
    puts "test__add_preplay_hook__get_preplay_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_preplay_hook(hook_1_name, &expected)
    actual = player.get_preplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    
    puts "test__add_preplay_hook__get_preplay_hook COMPLETED"
  end  

  def test__remove_preplay_hook
    puts "test__remove_preplay_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_preplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = player.get_preplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    player.remove_preplay_hook(hook_1_name)
    actual = player.get_preplay_hook(hook_1_name)
    assert(actual == nil)
    
    puts "test__remove_preplay_hook COMPLETED"
  end

  def test__add_postplay_hook__get_postplay_hook
    puts "test__add_postplay_hook__get_postplay_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_postplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = player.get_postplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    
    puts "test__add_postplay_hook__get_postplay_hook COMPLETED"
  end  

 def test__remove_postplay_hook
    puts "test__remove_postplay_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_postplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = player.get_postplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    player.remove_postplay_hook(hook_1_name)
    actual = player.get_postplay_hook(hook_1_name)
    assert(actual == nil)
    
    puts "test__remove_postplay_hook COMPLETED"
  end


  def test__add_improvising__hook__get_improvising_hook
    puts "test__add_improvising__hook__get_improvising_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_improvising_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = player.get_improvising_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    
    puts "test__add_improvising__hook__get_improvising_hook COMPLETED"
  end     
  
  def test__remove_improvising_hook
    puts "test__remove_improvising_hook ENTERED"

    player = Player.new("Test Player")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    player.add_improvising_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = player.get_improvising_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    player.remove_improvising_hook(hook_1_name)
    actual = player.get_improvising_hook(hook_1_name)
    assert(actual == nil)
    
    puts "test__remove_improvising_hook COMPLETED"
  end
  
  
  def test__set_state__get_state
    puts "test__set_state__get_state ENTERED"

    player = Player.new("Test Player")
    expected_key = "key_1"
    expected_val = 100
    player.set_state(expected_key, expected_val)
    actual_val = player.get_state(expected_key)
    assert(expected_val == actual_val)

    puts "test__set_state__get_state COMPLETED"
  end   

  def test__clear_state__state_keys
    puts "test__clear_state__state_keys ENTERED"

    player = Player.new("Test Player")
    expected_key = "key_1"
    player.clear_state
    player.set_state(expected_key, nil)
    actual = player.state_keys
    assert([expected_key] == actual)

    puts "test__clear_state__state_keys COMPLETED"
  end   
  
  def test__playing
    puts "test__playing ENTERED"

    player = Player.new("Test Player")
    expected = true
    # Test default
    assert(player.playing? == expected)
    # Toggle value
    player.playing?(expected)
    actual = player.playing?
    assert(expected == actual)
    player.playing?(! expected)
    actual = player.playing?
    assert(expected != actual)

    puts "test__playing COMPLETED"
  end 
  
  def test__improvising
    puts "test__improvising ENTERED"

    player = Player.new("Test Player")
    expected = false
    # Test default - NOTE - opposite default to playing?()
    assert(player.improvising? == expected)
    # Toggle value
    player.improvising?(expected)
    actual = player.improvising?
    assert(expected == actual)
    player.improvising?(! expected)
    actual = player.improvising?
    assert(expected != actual)

    puts "test__improvising COMPLETED"
  end   
  
  def test__dup
    puts "test__dup ENTERED"

    expected = Player.new("Test Player")
    actual = expected.dup
    
    # TODO More tests for the three hooks!
    assert(expected.name == actual.name)
    assert(expected.scores_idx == actual.scores_idx)
    assert(expected.preplay_hooks_ordered_names == actual.preplay_hooks_ordered_names)
    assert(expected.postplay_hooks_ordered_names == actual.postplay_hooks_ordered_names)
    assert(expected.improvising_hooks_ordered_names == actual.improvising_hooks_ordered_names)
    assert(expected.state == actual.state)
    assert(expected.is_playing == actual.is_playing)
    assert(expected.is_playing == actual.is_playing)
    assert(expected.out_notes.length == actual.out_notes.length)
    
    puts "test__dup COMPLETED"
  end  
  
end

end