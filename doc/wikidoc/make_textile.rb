def make_textile(line)
  j = 0
  prefix = ''
  while line[j] == 32
    prefix.concat "&nbsp;"
    j += 1
  end
	line = line.strip
	if line.length > 0
  	prefix + '@' + line + "@<br/>" 
	else
		"<br/>"
	end
end


lines = 
'phrase "C => EFlat, EFlat => C"
  repeat _num_steps
    note "rise 1"
      instrument  1      
      start       loop_step_u: _start1, _nt_dur1 + _rest_dur1, index - 1
      duration    _nt_dur1
      amplitude   modulate_i: _base_amp
      pitch       loop_step_u: C3, _pitch_step1, index
      func_table  1
    
    note "fall 1"
      instrument  1
      start       loop_step_u: _start2, _nt_dur1 + _rest_dur1, index - 1
      duration    _nt_dur1
      amplitude   modulate_i: _base_amp
      pitch       loop_step_d: E3F, _pitch_step1, index
      func_table  1'
 
lines.each do |line|
  puts(make_textile(line))
end