def make_textile(line)
  j = 0
  prefix = ''
  while line[j] == 32
    prefix.concat "&nbsp;"
    j += 1
  end
  prefix + '@' + line.strip + '@'
end


lines = 
'  render "my_composition.wav"
    phrases   "Intro Phrase"
    format    csound
    orchestra  "my_csound_orchestra.orc"'
 
lines.each do |line|
  puts(make_textile(line))
end