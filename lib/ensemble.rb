$LOAD_PATH << psub("../lib")
require 'util'
require 'player'

module Aleatoric

# Clients can do typical add/remove operations on players, by name
# Ensemble has a collection of Players, who play in the order they are added to the Ensemble when #play_all is called
# Ensemlbe has play interface with several options, #play takes a player name and plays that player, 
# #play_all plays all players in order they were added, the #*repeat options take a number of times to iterate these two options
# Ensemble calls it's own pre-play hooks in the order they are are added to the Ensemble, before calling Player.#play 
# on each player.  Such hooks generally test/set Ensemble state that can be used to do things like decide to play 
# or not play a player, or to set state that Player hooks might call.  For example, player may be instructed to 
# play louder if other players are playing louder -- this is an ensemble level attribute that should be set using 
# Ensemble hooks and then tested by Player hooks.
# Ensemble calls it's own post-play hooks in the order they are added to the Ensemble, after calling Player.#play on each player.
# Clients can do typical add/remove operations on hooks, by name
# Hooks may use the set_state() and get_state() methods as a key/value "property bag" to
# store and retrieve data as needed.
class Ensemble

  attr_accessor :name, :players

  # Ctor
  # @param [String] name of the Ensemble
  def initialize(name)
    @name = name
    @players = {}
    @preplay_hooks_ordered_names = []
    @preplay_hooks = {}
    @postplay_hooks_ordered_names = []
    @postplay_hooks = {}    
    @state = {}    
  end
  
  def handle
    self.object_id
  end
    
  # Get an Array of refs to all players held by this Ensemble
  # @return [Array<Aleatoric::Player>]
  def get_players
    @players.values    
  end
  alias players get_players
  
  # Add a Player to the Ensembles's list of players.  Note the players are added by key
  # but also stored in order they are added.  Clients can call #play and #play_repeat and pass
  # a player name to play that player.
  # @param [String] name of the Aleatoric::Player object being added
  # @param [Aleatoric::Player] the score object being added  
  def add_player(name, player)
    @players[name] = player
    self
  end

  # Remove a player from the Ensembles's list of players.
  # @param [String] name of the Aleatoric::Player object being removed
  # @return [self]
  def remove_player(name)
    @players.delete name
    self
  end

  # Get a reference to a player from the Ensembles's list of players.
  # @param [String] name of the Aleatoric::Player object being retrieved
  # @return [Aleatoric::Player] 
  def get_player(name)
    @players[name]
  end

  # Clear all players stored by this Ensemble
  # @return [self] 
  def clear_players
    @players.clear
    self
  end

  # Returns number of players stored by this Ensemble
  # @return [Integer]  
  def players_length
    @players.length
  end

  # Tests whether the Ensemble has any players
  # @return [true, false]    
  def players_empty?
    @players.length == 0
  end
  
  def players_attr_slice(attr)    
    @players.values.collect {|player| player.send(attr.to_sym)}
  end
  
  # Store a value by keyname, serving as a generic interface for hooks to store state for later use.
  # Supports the design pattern of testing/setting state in preplay hooks and testing/setting in 
  # postplay hooks in a complementary fashion.  So, state can be tested/set before and after each
  # time the Player plays, so state can affect what is played and be affected by it.
  # @param [Object] a valid Ruby Hash as the key of the value being stored
  # @param [Object] any Ruby object as a value being stored
  # @return self  
  def set_state(key, val)
    @state[key] = val
    self
  end
  
  # Retrieves a value by keyname, serving as a generic interface for hooks to store state for later use.
  # Supports the design pattern of testing/setting state in preplay hooks and testing/setting in 
  # postplay hooks in a complementary fashion.  So, state can be tested/set before and after each
  # time the Player plays, so state can affect what is played and be affected by it.
  # @param [Object] a valid Ruby Hash as the key of the value being stored
  # @return [Object] a reference to the Object stored under this key, or nil if #include?(key) == false  
  def get_state(key)
    @state[key]
  end
  
  # Clears all key/values in the Player's state store.
  # @return self  
  def clear_state
    @state.clear
    self
  end
  
  # Returns the keys in the Player's state store.  
  def state_keys
    @state.keys
  end

  # Preplay hooks are named blocks that run, in the order they are registered, before each
  # call to any #play* method. They are responsible for taking a reference to the Ensemble in which the 
  # hook is registered and returning nil.
  # @param [String] a name of the hook to add
  # @param [block] the block that is the hook body
  # @return [self]   
  def add_preplay_hook(name, &f)  
    @preplay_hooks_ordered_names << name
    @preplay_hooks[name] = f    
    self
  end
  
  # Removes a hook by name
  # @param [String] the name of the hook to remove
  # @return [self]  
  def remove_preplay_hook(name)
    @preplay_hooks_ordered_names.delete(name)
    @preplay_hooks.delete(name)
    self
  end
  
  # Retrieves a hook by name
  # @param [String] the name of the hook being retrieved
  # @return [block] returns a lambda of the body of the hook matching the name argument  
  def get_preplay_hook(name)
    @preplay_hooks[name]
  end

  # Postplay hooks are named blocks that run, in the order they are registered, after each
  # call to #play*.  They are responsible for taking a reference to the Ensemble in which the 
  # hook is registered and returning nil.
  # @param [String] a name of the hook to add
  # @param [block] the block that is the hook body
  # @return [self]  
  def add_postplay_hook(name, &f)  
    @postplay_hooks_ordered_names << name
    @postplay_hooks[name] = f
    self
  end
  
  # Removes a hook by name
  # @param [String] the name of the hook to remove
  # @return [self]  
  def remove_postplay_hook(name)
    @postplay_hooks_ordered_names.delete(name)
    @postplay_hooks.delete(name)
    self
  end
  
  # Retrieves a hook by name
  # @param [String] the name of the hook being retrieved
  # @return [block] returns a lambda of the body of the hook matching the name argument  
  def get_postplay_hook(name)
    @postplay_hooks[name]
  end

  # Calls player.#play on the player named in the name argument.  Runs all Ensemble preplay hooks in the order they were
  # added first.  Then runs the optional blokc in the &blk argument, if one is provided. Runs all Ensemble postplay hooks in
  # the order they were added after calling player.#play.
  # @param [String] the name of the player on which to call #play
  # @param [block, nil] a block to call after preplay hooks are run
  def play(name, &blk)
    if not @players.include? name
      return
    end
    
    # Ensemble outputs score for each player    
    @preplay_hooks_ordered_names.each do |hook_name|
      @preplay_hooks[hook_name].call self      
    end
    
    # If user passed in additional one-time-only block for this play() call, run it on current score
    blk.call if block_given?
    
    # Now call name's play
    # Player.play can have it's own preplay hooks, preplay optional block, postplay hooks
    @players[name].play 
    
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    @postplay_hooks_ordered_names.each do |hook_name|
      @postplay_hooks[hook_name].call self
    end    
  end
  
  # Calls #play num_times.
  # @param [String] the name of the player on which to call Player.#play
  # @param [Integer] the number of times to call Ensemble.#play
  # @param [block, nil] a block to call after preplay hooks are run  
  def play_repeat(name, num_times, &blk)
    num_times.times {play(name, &blk)}
  end
  
  # Calls player.#play on each player added to the Ensemble, in the order they were added.  Runs all Ensemble 
  # preplay hooks in the order they were added first.  Then runs the optional blokc in the &blk argument, if one 
  # is provided. Runs all Ensemble postplay hooks in the order they were added after calling player.#play.
  # @param [String] the name of the player on which to call #play
  # @param [block, nil] a block to call after preplay hooks are run  
  def play_all(&blk)
    # Ensemble doesn't output score, so this is only called for side effects
    #  presumably on ensemble state and/or state of some/all players
    # NOTE: Ensemble hooks take a reference to their containing ensemble
    @preplay_hooks_ordered_names.each do |hook_name|
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
  
  # Calls #play_all num_times.
  # @param [Integer] the number of times to call Ensemble.#play_all
  # @param [block, nil] a block to call after preplay hooks are run    
  def play_all_repeat(num_times, &blk)
    num_times.times {play_all(&blk)}
  end  

end

end
