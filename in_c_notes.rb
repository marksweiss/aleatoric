require 'note'
require 'globals'

module In_C

# REQS
# - "...53 melodic patterns played in sequence."
# /REQS
#

# Blocks to implement attrs for custom attributes, in this case to allow notes to
#  to add a "legato" attribute, which is a transformation derived from other
#  attrs, and not just a simple getter/setter attr
# Note::add_custom_attr(attr_name, &attr_block) supports this
# TODO This, like all constants, should come from a YAML config
LEGATO_FCTR = 1.03
legato_nxt = lambda {dur(dur * LEGATO_FCTR)}
legato_prv = lambda {start(start - ((dur * LEGATO_FCTR) - dur)) if start >= 0}

# "Prototype" note to dupe from, so instr and func don't need to repeat on every
#   new Note created in the phrases
# Note these note properties can and are manipulated as Ensemble plays to generate
#  the score.
# TODO This, like all constants, should come from a YAML config
DFLT_AMP = 750
note = CSnd::Note.new.
  instr(1).
  start(0.0).dur(0.0).
  amp(DFLT_AMP).pitch(0.0).
  add_attr(:func).func(1)
@phrases = []

#
# These are the phrases that make up the Score. There are 53 of them.
#

# 1
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($C4).
    add_custom_attr(:legato_nxt, &legato_nxt), # Note use of custom_attr to apply legato to Note and provide implementation
  note.dup.
    start(0.0 + $EITH).dur($QRTR).
    pitch($E4).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start($EITH + $QRTR).dur($EITH).
    pitch($C4).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start($HLF).dur($QRTR).
    pitch($E4).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start($HLF + $QRTR).dur($EITH).
    pitch($C4).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($QRTR).
    pitch($E4).
    add_custom_attr(:legato_prv, &legato_prv)
])

# 2
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($C4).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start($EITH).dur($EITH).
    pitch($E4).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($F4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E4)
])

# 3
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($E4),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($F4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E4)
])

# 4
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($E4),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($F4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E4)
])

# 5
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($E4),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($F4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    amp($REST).pitch($C4)
])

# 6
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL).
    pitch($C5).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start($WHL).dur($WHL).
    pitch($C5).
    add_custom_attr(:legato_prv, &legato_prv)
])

# 7
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($QRTR).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $QRTR).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($EITH).
    pitch($C4),
  note.dup.
    start($WHL).dur($EITH).
    pitch($C4),
  note.dup.
    start($WHL + $EITH).dur($EITH).
    pitch($C4),
  note.dup.
    start($WHL + $QRTR).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($WHL + $QRTR + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($WHL + $HLF + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($WHL + $HLF + $QRTR + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start(2.0 * $WHL + $EITH).dur($QRTR).
    amp($REST).pitch($C4)
])

# 8
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL + $HLF).
    pitch($G4),
  note.dup.
    start($WHL + $HLF).dur($WHL).
    pitch($F4).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start(2.0 * $WHL + $HLF).dur($WHL).
    pitch($F4).
    add_custom_attr(:legato_prv, &legato_prv)
])

# 9
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($B4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($QRTR + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
])

# 10
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($B4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($G4)
])

# 11
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($B4),    
  note.dup.
    start($QRTR + $EITH).dur($SXTNTH).
    pitch($G4)
])

# 12
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($F4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($WHL).
    pitch($B4),
  note.dup.
    start($QRTR + $WHL).dur($QRTR).
    pitch($C5),
])

# 13
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($SXTNTH).dur($EITH + $SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($G4),    
  note.dup.
    start($HLF).dur($EITH + $SXTNTH).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4).
    add_custom_attr(:legato_nxt, &legato_nxt), 
  note.dup.
    start($HLF + $QRTR).dur($HLF + $QRTR).
    pitch($G4).
    add_custom_attr(:legato_prv, &legato_prv)    
])

# 14
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL).
    pitch($C5),
  note.dup.
    start($WHL).dur($WHL).
    pitch($B4),
  note.dup.
    start(2.0 * $WHL).dur($WHL).
    pitch($G4),    
  note.dup.
    start(3.0 * $WHL).dur($WHL).
    pitch($F4S),    
])

# 15
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($EITH + $SXTNTH).
    amp($REST).pitch($C4),
  note.dup.
    start($QRTR).dur($QRTR).
    amp($REST).pitch($C4),    
  note.dup.
    start($HLF).dur($QRTR).
    amp($REST).pitch($C4),    
  note.dup.
    start($HLF + $QRTR).dur($QRTR).
    amp($REST).pitch($C4)
])

# 16
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($A4),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($C5),    
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($B4)
])

# 17
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($B4),    
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR + $EITH).dur($SXTNTH).
    amp($REST).pitch($C4)    
])

# 18
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($E4),    
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($QRTR + $SXTNTH).dur($EITH + $SXTNTH).
    pitch($E4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E4)    
])

# 19
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($QRTR + $EITH).
    amp($REST).pitch($E4),
  note.dup.
    start($QRTR + $EITH).dur($QRTR + $EITH).
    pitch($G5)
])

# 20
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($E4),    
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($QRTR + $SXTNTH).dur($EITH + $SXTNTH).
    pitch($G3),
  note.dup.
    start($HLF).dur($EITH).
    pitch($E4),   
  note.dup.
    start($HLF + $EITH).dur($EITH).
    pitch($F4S),
  note.dup.
    start($HLF + $QRTR).dur($EITH).
    pitch($E4),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($EITH).
    pitch($F4S),
  note.dup.
    start($WHL).dur($EITH).
    pitch($E4)    
])

# 21
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($HLF + $QRTR).
    amp($REST).pitch($F4S)
])

# 22
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($QRTR + $EITH).
    pitch($E4),
  note.dup.
    start($QRTR + $EITH).dur($QRTR + $EITH).
    pitch($E4),
  note.dup.
    start(2.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($E4),    
  note.dup.
    start(3.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($E4),
  note.dup.
    start(4.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($E4),
  note.dup.
    start(5.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($F4S),
  note.dup.
    start(6.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start(7.0 * ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($A4),
  note.dup.
    start(8.0 * ($QRTR + $EITH)).dur($EITH).
    pitch($B4)
])

# 23
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($E4),
  note.dup.
    start($EITH).dur($QRTR + $EITH).
    pitch($F4S),
  note.dup.
    start($HLF).dur($QRTR + $EITH).
    pitch($F4S),    
  note.dup.
    start($HLF + ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($F4S),
  note.dup.
    start($HLF + (2.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($F4S),
  note.dup.
    start($HLF + (3.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($F4S),    
  note.dup.
    start($HLF + (4.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($HLF + (5.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($A4),
  note.dup.
    start($HLF + (6.0 * ($QRTR + $EITH))).dur($QRTR).
    pitch($B4)
])

# 24
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($E4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($F4S),
  note.dup.
    start($QRTR).dur($QRTR + $EITH).
    pitch($G4),    
  note.dup.
    start($HLF + $EITH).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL + ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($G4),    
  note.dup.
    start($WHL + (2.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL + (3.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($A4),
  note.dup.
    start($WHL + (4.0 * ($QRTR + $EITH))).dur($EITH).
    pitch($B4)
])

# 25
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($E4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($F4S),
  note.dup.
    start($QRTR).dur($QRTR + $EITH).
    pitch($G4),    
  note.dup.
    start($HLF + $EITH).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL + ($QRTR + $EITH)).dur($QRTR + $EITH).
    pitch($G4),    
  note.dup.
    start($WHL + (2.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($G4),
  note.dup.
    start($WHL + (3.0 * ($QRTR + $EITH))).dur($QRTR + $EITH).
    pitch($A4),
  note.dup.
    start($WHL + (4.0 * ($QRTR + $EITH))).dur($EITH).
    pitch($B4)
])

# 26
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($E4),
  note.dup.
    start($EITH).dur($EITH).
    pitch($F4S),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($G4),    
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($A4),    
  note.dup.
    start($HLF).dur($QRTR + $EITH).
    pitch($B4),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($QRTR + $EITH).
    pitch($B4),
  note.dup.
    start($WHL + $QRTR).dur($QRTR + $EITH).
    pitch($B4),    
  note.dup.
    start($WHL + $HLF + $EITH).dur($QRTR + $EITH).
    pitch($B4),
  note.dup.
    start(2.0 * $WHL).dur($QRTR + $EITH).
    pitch($B4)   
])

# 27
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($E4),    
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($F4S),    
  note.dup.
    start($QRTR).dur($EITH).
    pitch($G4),
  note.dup.
    start($QRTR + $EITH).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($QRTR + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),    
  note.dup.
    start($HLF).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($HLF + $SXTNTH).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($HLF + $EITH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($HLF + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($E4)
])

# 28
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($E4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($E4),    
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($F4S),
  note.dup.
    start($QRTR).dur($EITH + $SXTNTH).
    pitch($E4),
  note.dup.
    start($QRTR + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($E4)
])

# 29
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($HLF + $QRTR).
    pitch($E4),
  note.dup.
    start($HLF + $QRTR).dur($HLF + $QRTR).
    pitch($G4),
  note.dup.
    start($WHL + $HLF).dur($HLF + $QRTR).
    pitch($C5)
])

# 30
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL + $HLF).
    pitch($C5)
])

# 31
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($G4),    
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($B4)
])

# 32
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($F4),    
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($F4).
    add_custom_attr(:legato_nxt, &legato_nxt),     
  note.dup.
    start($QRTR + $EITH).dur($HLF + $QRTR).
    pitch($F4).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start($WHL + $EITH).dur($QRTR + $EITH).
    pitch($G4)  
])

# 33
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($EITH).dur($SXTNTH).
    amp($REST).pitch($C4)  
])

# 34
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4)
])

# 35
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($B4),    
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR + $EITH).dur($SXTNTH).
    pitch($B4),    
  note.dup.
    start($QRTR + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($HLF).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($HLF + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($HLF + $EITH).dur($EITH).
    amp($REST).pitch($C4),    
  note.dup.
    start($HLF + $QRTR).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start($WHL).dur($QRTR).
    amp($REST).pitch($C4),   
  note.dup.
    start($WHL + $QRTR).dur($QRTR).
    amp($REST).pitch($C4), 
  note.dup.
    start($WHL + $HLF).dur($QRTR).
    pitch($A4S),  # BFlat    
  note.dup.
    start($WHL + $HLF + $QRTR).dur($HLF + $QRTR).
    pitch($G5),
  note.dup.
    start((2.0 * $WHL) + $HLF).dur($EITH).
    pitch($G5),
  note.dup.
    start((2.0 * $WHL) + $HLF + $EITH).dur($EITH).
    pitch($A5),
  note.dup.
    start((2.0 * $WHL) + $HLF + $QRTR).dur($EITH).
    pitch($G5).
    add_custom_attr(:legato_nxt, &legato_nxt), 
  note.dup.
    start((2.0 * $WHL) + $HLF + $QRTR + $EITH).dur($EITH).
    pitch($G5).
    add_custom_attr(:legato_prv, &legato_prv), 
  note.dup.
    start(3.0 * $WHL).dur($EITH).
    pitch($B5),
  note.dup.
    start((3.0 * $WHL) + $EITH).dur($QRTR + $EITH).
    pitch($A5),   
  note.dup.
    start((3.0 * $WHL) + $HLF).dur($EITH).
    pitch($G5),
  note.dup.
    start((3.0 * $WHL) + $HLF + $EITH).dur($HLF + $QRTR).
    pitch($E5),
  note.dup.
    start((4.0 * $WHL) + $QRTR + $EITH).dur($EITH).
    pitch($G5),
  note.dup.
    start((4.0 * $WHL) + $HLF).dur($EITH).
    pitch($F5S).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start((4.0 * $WHL) + $HLF + $EITH).dur($HLF + $QRTR).
    pitch($F5S).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start((5.0 * $WHL) + $QRTR + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start((5.0 * $WHL) + $HLF + $EITH).dur($QRTR).
    amp($REST).pitch($C4),
  note.dup.
    start((5.0 * $WHL) + $HLF + $QRTR + $EITH).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start(6.0 * $WHL).dur($EITH).
    pitch($E5).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start((6.0 * $WHL) + $EITH).dur($HLF).
    pitch($E5).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start((6.0 * $WHL) + $HLF + $EITH).dur($WHL).
    pitch($F5)     
])

# 36
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($G4)    
])

# 37
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4)   
])

# 38
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($B4)    
])

# 39
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($C4)     
])

# 40
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F4)   
])

# 41
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($B4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4)   
])

# 42
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL).
    pitch($C5),
  note.dup.
    start($WHL).dur($WHL).
    pitch($B4),
  note.dup.
    start(2.0 * $WHL).dur($WHL).
    pitch($A4),
  note.dup.
    start(3.0 * $WHL).dur($WHL).
    pitch($B4)    
])

# 43
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($E5),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($F5),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($E5),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($F5),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($E5),    
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E5),
  note.dup.
    start($HLF).dur($EITH).
    pitch($E5),
  note.dup.
    start($HLF + $EITH).dur($SXTNTH).
    pitch($F5), 
  note.dup.
    start($HLF + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($E5) 
])

# 44
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($EITH).
    pitch($F5),
  note.dup.
    start($EITH).dur($EITH).
    pitch($E5).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start($QRTR).dur($EITH).
    pitch($E5).
    add_custom_attr(:legato_prv, &legato_prv),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($E5),
  note.dup.
    start($HLF).dur($QRTR).
    pitch($C5) 
])

# 45
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($QRTR).
    pitch($C5),
  note.dup.
    start($QRTR).dur($QRTR).
    pitch($C5),
  note.dup.
    start($HLF).dur($QRTR).
    pitch($G4) 
])

# 46
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($E5),
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($QRTR).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($QRTR + $EITH).dur($EITH).
    pitch($G4),    
  note.dup.
    start($HLF).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $EITH).dur($EITH).
    pitch($G4),    
  note.dup.
    start($HLF + $QRTR).dur($EITH).
    amp($REST).pitch($C4),
  note.dup.
    start($HLF + $QRTR + $EITH).dur($EITH).
    pitch($G4),
  note.dup.
    start($WHL).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($WHL + $SXTNTH).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($WHL + $EITH).dur($SXTNTH).
    pitch($E5),
  note.dup.
    start($WHL + $EITH + $SXTNTH).dur($SXTNTH).
    pitch($C5)
])

# 47
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($C5),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($E5),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($C5)
])

# 48
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($WHL + $HLF).
    pitch($G4),
  note.dup.
    start($WHL + $HLF).dur($WHL).
    pitch($G4),
  note.dup.
    start((2.0 * $WHL) + $HLF).dur($WHL).
    pitch($F4).
    add_custom_attr(:legato_nxt, &legato_nxt),
  note.dup.
    start((3.0 * $WHL) + $HLF).dur($QRTR).
    pitch($F4).
    add_custom_attr(:legato_prv, &legato_prv)   
])

# 49
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($A4S), # B Flat
  note.dup.
    start($EITH + $SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($QRTR).dur($SXTNTH).
    pitch($A4S),  
  note.dup.
    start($QRTR + $SXTNTH).dur($SXTNTH).
    pitch($G4)    
])

# 50
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4)  
])

# 51
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($F4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($EITH).dur($SXTNTH).
    pitch($A4S) # B Flat    
])

# 52
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($G4),
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($A4S) # B Flat    
])

# 53
@phrases.push CSnd::Score.new([
  note.dup.
    start(0.0).dur($SXTNTH).
    pitch($A4S), # B Flat
  note.dup.
    start($SXTNTH).dur($SXTNTH).
    pitch($G4)   
])

# For clients to get a copy of the Phrases
def In_C.phrases_dup
  @phrases.collect {|phrase| phrase.dup}
end

end

















