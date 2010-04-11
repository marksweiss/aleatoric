require 'test_global'
$LOAD_PATH << psub("../lib")

require 'ensemble'

require 'test/unit'

require 'rubygems'
# require 'ruby-debug' ; Debugger.start

module Aleatoric

class Ensemble_Test < Test::Unit::TestCase
  def test__initialize
    puts "test__initialize ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    assert(ensemble.class == Ensemble)
    
    puts "test__initialize COMPLETED"
  end

  def test__add_player__get_player__players
    puts "test__add_player__get_player__players ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    name = "Test Player"
    player = Player.new("Test Player")
    ensemble.add_player(name, player)    

    expected = player
    actual = ensemble.players.last
    assert(expected.name == actual.name && expected.object_id == actual.object_id)

    actual = ensemble.get_player(name)
    assert(expected.name == actual.name && expected.object_id == actual.object_id)
    
    puts "test__add_player__get_player__players COMPLETED"  
  end

  def test__remove_player__clear_players__players_length__players_empty
    puts "test__clear_players__players_length__players_empty ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    name = "Test Player"
    player = Player.new("Test Player")

    expected = 0
    actual = ensemble.players_length
    assert(expected == actual)
    assert(ensemble.players_empty?)

    ensemble.add_player(name, player)    
    expected = 1
    actual = ensemble.players_length
    assert(expected == actual)

    name2 = "Test Player 2"
    player2 = Player.new("Test Player")
    ensemble.add_player(name2, player2)    
    expected = 2
    actual = ensemble.players_length
    assert(expected == actual)
    
    ensemble.remove_player(name2)
    expected = 1
    actual = ensemble.players_length
    assert(expected == actual)
    
    ensemble.remove_player(name)
    expected = 0
    actual = ensemble.players_length
    assert(expected == actual)
    assert(ensemble.players_empty?)
    
    puts "test__clear_players__players_length__players_empty COMPLETED"  
  end

  def test__set_state__get_state
    puts "test__set_state__get_state ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    expected_key = "key_1"
    expected_val = 100
    ensemble.set_state(expected_key, expected_val)
    actual_val = ensemble.get_state(expected_key)
    assert(expected_val == actual_val)

    puts "test__set_state__get_state COMPLETED"
  end   

  def test__clear_state__state_keys
    puts "test__clear_state__state_keys ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    expected_key = "key_1"
    ensemble.clear_state
    ensemble.set_state(expected_key, nil)
    actual = ensemble.state_keys
    assert([expected_key] == actual)

    puts "test__clear_state__state_keys COMPLETED"
  end  

  def test__add_preplay_hook__get_preplay_hook
    puts "test__add_preplay_hook__get_preplay_hook ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    ensemble.add_preplay_hook(hook_1_name, &expected)
    actual = ensemble.get_preplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    
    puts "test__add_preplay_hook__get_preplay_hook COMPLETED"
  end  

  def test__remove_preplay_hook
    puts "test__remove_preplay_hook ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    ensemble.add_preplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = ensemble.get_preplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    ensemble.remove_preplay_hook(hook_1_name)
    actual = ensemble.get_preplay_hook(hook_1_name)
    assert(actual == nil)
    
    puts "test__remove_preplay_hook COMPLETED"
  end

  def test__add_postplay_hook__get_postplay_hook
    puts "test__add_postplay_hook__get_postplay_hook ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    ensemble.add_postplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = ensemble.get_postplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    
    puts "test__add_postplay_hook__get_postplay_hook COMPLETED"
  end  

 def test__remove_postplay_hook
    puts "test__remove_postplay_hook ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    note_1_name = "note 1"
    note_1 = Note.new note_1_name
    note_1.start(0.0)
    hook_1_name = "hook 1"
    expected = lambda {|note| note.start(note.start + 1.0)}
    ensemble.add_postplay_hook(hook_1_name) {|note| note.start(note.start + 1.0)}
    actual = ensemble.get_postplay_hook(hook_1_name)
    assert(expected.call(note_1) == actual.call(note_1))
    ensemble.remove_postplay_hook(hook_1_name)
    actual = ensemble.get_postplay_hook(hook_1_name)
    assert(actual == nil)
    
    puts "test__remove_postplay_hook COMPLETED"
  end
  
 def test__play
    puts "test__play ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    player_1_name = "Test Player 1"
    player_1 = Player.new(player_1_name)
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new(note_1_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_2 = Note.new(note_2_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    expected_1 = [note_1, note_2]
    score_1_name = "score 1"
    score_1 = Score.new(score_1_name)
    score_1 << expected_1
    player_1.add_score(score_1_name, score_1)
    ensemble.add_player(player_1_name, player_1)
    
    ensemble.play player_1_name
    
    actual = player_1.output    
    assert(actual.length == expected_1.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    player_2_name = "Test Player 2"
    player_2 = Player.new(player_2_name)
    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new(note_3_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_4 = Note.new(note_4_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    expected_2 = [note_3, note_4]
    score_2_name = "score 2"
    score_2 = Score.new(score_2_name)
    score_2 << expected_2
    player_2.add_score(score_2_name, score_2)
    ensemble.add_player(player_2_name, player_2)     
    player_1.clear_output
    
    ensemble.play player_1_name

    actual = player_1.output    
    assert(actual.length == expected_1.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    ensemble.play player_2_name

    actual = player_2.output
    assert(actual.length == expected_2.length)
    assert(actual[0].name == expected_2[0].name && actual[1].name == expected_2[1].name)
    
    puts "test__play COMPLETED"
  end

 def test__play_all
    puts "test__play_all ENTERED"

    ensemble = Ensemble.new("Test Ensemble")

    player_1_name = "Test Player 1"
    player_1 = Player.new(player_1_name)
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new(note_1_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_2 = Note.new(note_2_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    score_1_name = "score 1"
    score_1 = Score.new(score_1_name)
    expected_1 = [note_1, note_2]
    score_1 << expected_1
    player_1.add_score(score_1_name, score_1)
    ensemble.add_player(player_1_name, player_1)    
    player_2_name = "Test Player 2"
    player_2 = Player.new(player_2_name)
    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new(note_3_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_4 = Note.new(note_4_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    score_2_name = "score 2"
    score_2 = Score.new(score_2_name)
    expected_2 = [note_3, note_4]
    score_2 << expected_2
    player_2.add_score(score_2_name, score_2)
    ensemble.add_player(player_2_name, player_2)     

    ensemble.play_all

    actual = player_1.output
    assert(actual.length == expected_1.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    actual = player_2.output        
    assert(actual.length == expected_2.length)
    assert(actual[0].name == expected_2[0].name && actual[1].name == expected_2[1].name)
    
    puts "test__play_all COMPLETED"
  end

 def test__play_repeat
    puts "test__play_repeat ENTERED"

    ensemble = Ensemble.new("Test Ensemble")
    player_1_name = "Test Player 1"
    player_1 = Player.new(player_1_name)
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new(note_1_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_2 = Note.new(note_2_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    expected_1 = [note_1, note_2]
    score_1_name = "score 1"
    score_1 = Score.new(score_1_name)
    score_1 << expected_1
    player_1.add_score(score_1_name, score_1)
    ensemble.add_player(player_1_name, player_1)    
    ensemble.play player_1_name
    actual = player_1.output
    
    assert(actual.length == expected_1.length)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    player_2_name = "Test Player 2"
    player_2 = Player.new(player_2_name)
    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new(note_3_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_4 = Note.new(note_4_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    expected_2 = [note_3, note_4]
    score_2_name = "score 2"
    score_2 = Score.new(score_2_name)
    score_2 << expected_2
    player_2.add_score(score_2_name, score_2)
    ensemble.add_player(player_2_name, player_2)     
    player_1.clear_output
    
    num_times_repeat = 3
    ensemble.play_repeat(player_1_name, num_times_repeat)
    
    actual = player_1.output    
    assert(actual.length == expected_1.length * num_times_repeat)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    ensemble.play_repeat(player_2_name, num_times_repeat)
    actual = player_2.output
        
    assert(actual.length == expected_2.length * num_times_repeat)
    assert(actual[0].name == expected_2[0].name && actual[1].name == expected_2[1].name)
    
    puts "test__play_repeat COMPLETED"
  end

 def test__play_all_repeat
    puts "test__play_all_repeat ENTERED"

    ensemble = Ensemble.new("Test Ensemble")

    player_1_name = "Test Player 1"
    player_1 = Player.new(player_1_name)
    note_1_name = "note 1"
    note_2_name = "note 2"
    note_1 = Note.new(note_1_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_2 = Note.new(note_2_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    score_1_name = "score 1"
    score_1 = Score.new(score_1_name)
    expected_1 = [note_1, note_2]
    score_1 << expected_1
    player_1.add_score(score_1_name, score_1)
    ensemble.add_player(player_1_name, player_1)    
    player_2_name = "Test Player 2"
    player_2 = Player.new(player_2_name)
    note_3_name = "note 3"
    note_4_name = "note 4"
    note_3 = Note.new(note_3_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})
    note_4 = Note.new(note_4_name, {:instrument=>1, :start=>0.0, :duration=>4.0, :amplitude=>1000, :pitch=>8.01000, :func_table=>1})    
    score_2_name = "score 2"
    score_2 = Score.new(score_2_name)
    expected_2 = [note_3, note_4]
    score_2 << expected_2
    player_2.add_score(score_2_name, score_2)
    ensemble.add_player(player_2_name, player_2)     

    num_times_repeat = 3
    ensemble.play_all_repeat(num_times_repeat)

    actual = player_1.output    
    assert(actual.length == expected_1.length * num_times_repeat)
    assert(actual[0].name == expected_1[0].name && actual[1].name == expected_1[1].name)

    actual = player_2.output        
    assert(actual.length == expected_2.length * num_times_repeat)
    assert(actual[0].name == expected_2[0].name && actual[1].name == expected_2[1].name)
    
    puts "test__play_all_repeat COMPLETED"
  end
  
end

end