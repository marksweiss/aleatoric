$LOAD_PATH << "..\\lib"
require 'util'
require 'player'


module Aleatoric

class Ensemble

  attr_accessor :name, :players

  def initialize(name)
    @name = name
    @players = {}
    @preplay_hooks_ordered_names = []
    @preplay_hooks = {}
    @postplay_hooks_ordered_names = []
    @postplay_hooks = {}    
    @state = {}    
  end
  
  def get_players
    @players.values    
  end
  alias players get_players
  
  def add_player(name, player)
    @players[name] = player
    self
  end

  def remove_player(name)
    @players.delete name
    self
  end
  
  def get_player(name)
    @players[name]
  end

  def clear_players
    @players.clear
    self
  end

  def players_length
    @players.length
  end

  def players_empty?
    @players.length == 0
  end
  
  def set_state(key, val)
    @state[key] = val
    self
  end
  
  def get_state(key)
    @state[key]
  end
  
  def clear_state
    @state.clear
    self
  end
  
  def state_keys
    @state.keys
  end

  def add_preplay_hook(name, &f)
    @preplay_hooks_ordered_names << name
    @preplay_hooks[name] = f    
    self
  end
  
  def remove_preplay_hook(name)
    @preplay_hooks_ordered_names.delete(name)
    @preplay_hooks.delete(name)
    self
  end
  
  def get_preplay_hook(name)
    @preplay_hooks[name]
  end

  def add_postplay_hook(name, &f)  
    @postplay_hooks_ordered_names << name
    @postplay_hooks[name] = f
    self
  end
  
  def remove_postplay_hook(name)
    @postplay_hooks_ordered_names.delete(name)
    @postplay_hooks.delete(name)
    self
  end
  
  def get_postplay_hook(name)
    @postplay_hooks[name]
  end

  def play(name, &blk)
    if not @players.include? name
      return
    end
    
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    
    # TEMP DEBUG
    debug_log @postplay_hooks_ordered_names.class
    debug_log @postplay_hooks_ordered_names.length
    
    @preplay_hooks_ordered_names.each do |hook_name|
      @preplay_hooks[hook_name].call   
    end
    
    # If user passed in additional one-time-only block for this play() call, run it on current score
    blk.call if block_given?
    
    # Now call name's play
    # Player.play can have it's own preplay hooks, preplay optional block, postplay hooks
    @players[name].play 
    
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    @postplay_hooks_ordered_names.each do |hook_name|
      @postplay_hooks[hook_name].call
    end    
  end
  
  def play_repeat(name, num_times, &blk)
    num_times.times {play(name, &blk)}
  end
  
  def play_all(&blk)
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    @preplay_hooks_ordered_names.each do |hook_name|
      # NOTE: Ensemble hooks take a reference to their containing ensemble
      @preplay_hooks[hook_name].call self
    end
    
    # If user passed in additional one-time-only block for this play() call, run it on current score
    blk.call if block_given?
    
    # Now call each player's play
    # Player.play can have it's own preplay hooks, preplay optional block, postplay hooks
    @players.values.each {|player| player.play}
    
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    # NOTE: Ensemble hooks take a reference to their containing ensemble
    @postplay_hooks_ordered_names.each do |hook_name|
      @postplay_hooks[hook_name].call self
    end    
  end
  
  def play_all_repeat(num_times, &blk)
    num_times.times {play_all(&blk)}
  end  
  
  def to_s
    @name
  end

end

end
