require 'composer'
require 'composer_lang'
require 'thread'
include Aleatoric

def main
  file_name = ARGV[0]
  script = IO.read(file_name)
  script = ComposerAST.new(script).preprocess_script(file_name).to_s
  open(file_name, 'w') {|f| f << script} 
  load file_name
end

main