require_relative 'test_global'
$LOAD_PATH << psub("../lib")

require_relative 'composer_test'
require_relative 'composer_lang_test'
require_relative 'meter_test'
require_relative 'player_test'
require_relative 'ensemble_test'
require_relative 'midi_test'

require 'set'
require 'thread'

# require 'ruby-debug' ; Debugger.start
