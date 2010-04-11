module Aleatoric
# include Aleatoric

# Yes, a hack, these two methods are used to redirect error to a dummy file
#  so warnings don't show up anywhere while script is executed. Used to suppress warnings
#  in composer.rb::format(), which dynamically requires in either global_midi.rb or
#  global_csound.rb depending on format arg.  This redefines global constants, which is what
#  we *want* to happen, but that raises an error, so we wrap the call in a toggle off and on
#  of errors so no ugliness occurs in output of running script
def warnings_on
  $stderr.flush
  $stderr = STDERR
end

def warnings_off
  $stderr.flush
  $stderr = File.open('tempflush', 'w')
end


# Default format set in script invocation command line or set to :csound if no format arg passed
# TODO Make this support command-line argument or config for which is default
$FORMAT = $ARG_FORMAT || :csound
$LAST_FORMAT = $FORMAT

# TODO implement this to load both csound and midi from a config and then fill in values from the first
#  'format' statement it encounters
# TODO Add all of these consts and put them in a '' conf somewhere
REST = 0

# Change dur_factor to change global tempo, this changes duration of all notes
#  defined using these global constants
# TODO make dur_factor configurable and rename to indicate it controls global tempo
#  and expose it in Composer language to composition scripts so user can set, and so we can set it
#  in testing so that tests that rely on actual tempo (of kw 'meter') don't break
DUR_FACTOR = 1.0 # 0.4 for 'In_C'
# Default durations in seconds
WHL = 4.0 * DUR_FACTOR
HLF = 2.0 * DUR_FACTOR
QRTR = 1.0 * DUR_FACTOR
EITH = 0.5 * DUR_FACTOR
SXTNTH = 0.25 * DUR_FACTOR
THRTYSCND = 0.125 * DUR_FACTOR
SXTYFRTH = 0.0625 * DUR_FACTOR

# Remove MIDI consts only used by MIDI to avoid using them with CSound format
#  and silently passing bogus values to CSound that might not cause errors but
#  might not behave as intended
# Only called by set_csound_consts()
def unset_midi_consts

# These are notes in range in MIDI only
Aleatoric.send :remove_const, :Cneg1
Aleatoric.send :remove_const, :Cneg1S
Aleatoric.send :remove_const, :Dneg1F
Aleatoric.send :remove_const, :Dneg1
Aleatoric.send :remove_const, :Dneg1S
Aleatoric.send :remove_const, :Eneg1F
Aleatoric.send :remove_const, :Eneg1
Aleatoric.send :remove_const, :Fneg1
Aleatoric.send :remove_const, :Fneg1S
Aleatoric.send :remove_const, :Gneg1F
Aleatoric.send :remove_const, :Gneg1
Aleatoric.send :remove_const, :Gneg1S
Aleatoric.send :remove_const, :Aneg1F
Aleatoric.send :remove_const, :Aneg1
Aleatoric.send :remove_const, :Aneg1S
Aleatoric.send :remove_const, :Bneg1F
Aleatoric.send :remove_const, :Bneg1
Aleatoric.send :remove_const, :C0
Aleatoric.send :remove_const, :C0S
Aleatoric.send :remove_const, :D0F
Aleatoric.send :remove_const, :D0
Aleatoric.send :remove_const, :D0S
Aleatoric.send :remove_const, :E0F
Aleatoric.send :remove_const, :E0
Aleatoric.send :remove_const, :F0
Aleatoric.send :remove_const, :F0S
Aleatoric.send :remove_const, :G0F
Aleatoric.send :remove_const, :G0
Aleatoric.send :remove_const, :G0S
Aleatoric.send :remove_const, :A0F
Aleatoric.send :remove_const, :A0
Aleatoric.send :remove_const, :A0S
Aleatoric.send :remove_const, :B0F
Aleatoric.send :remove_const, :B0

Aleatoric.send :remove_const, :C9
Aleatoric.send :remove_const, :C9S
Aleatoric.send :remove_const, :D9F
Aleatoric.send :remove_const, :D9
Aleatoric.send :remove_const, :D9S
Aleatoric.send :remove_const, :E9F
Aleatoric.send :remove_const, :E9
Aleatoric.send :remove_const, :F9
Aleatoric.send :remove_const, :F9S
Aleatoric.send :remove_const, :G9F
Aleatoric.send :remove_const, :G9

Aleatoric.send :remove_const, :MIDI_Acoustic_Grand_Piano
Aleatoric.send :remove_const, :MIDI_Bright_Acoustic_Piano
Aleatoric.send :remove_const, :MIDI_Electric_Grand_Piano
Aleatoric.send :remove_const, :MIDI_Honky_tonk_Piano
Aleatoric.send :remove_const, :MIDI_Electric_Piano_1
Aleatoric.send :remove_const, :MIDI_Electric_Piano_2
Aleatoric.send :remove_const, :MIDI_Harpsichord
Aleatoric.send :remove_const, :MIDI_Clavi
Aleatoric.send :remove_const, :MIDI_Celesta
Aleatoric.send :remove_const, :MIDI_Glockenspiel
Aleatoric.send :remove_const, :MIDI_Music_Box
Aleatoric.send :remove_const, :MIDI_Vibraphone
Aleatoric.send :remove_const, :MIDI_Marimba
Aleatoric.send :remove_const, :MIDI_Xylophone
Aleatoric.send :remove_const, :MIDI_Tubular_Bells
Aleatoric.send :remove_const, :MIDI_Dulcimer
Aleatoric.send :remove_const, :MIDI_Drawbar_Organ
Aleatoric.send :remove_const, :MIDI_Percussive_Organ
Aleatoric.send :remove_const, :MIDI_Rock_Organ
Aleatoric.send :remove_const, :MIDI_Church_Organ
Aleatoric.send :remove_const, :MIDI_Reed_Organ
Aleatoric.send :remove_const, :MIDI_Accordion
Aleatoric.send :remove_const, :MIDI_Harmonica
Aleatoric.send :remove_const, :MIDI_Tango_Accordion
Aleatoric.send :remove_const, :MIDI_Acoustic_Guitar_nylon
Aleatoric.send :remove_const, :MIDI_Acoustic_Guitar_steel
Aleatoric.send :remove_const, :MIDI_Electric_Guitar_jazz
Aleatoric.send :remove_const, :MIDI_Electric_Guitar_clean
Aleatoric.send :remove_const, :MIDI_Electric_Guitar_muted
Aleatoric.send :remove_const, :MIDI_Overdriven_Guitar
Aleatoric.send :remove_const, :MIDI_Distortion_Guitar
Aleatoric.send :remove_const, :MIDI_Guitar_harmonics
Aleatoric.send :remove_const, :MIDI_Acoustic_Bass
Aleatoric.send :remove_const, :MIDI_Electric_Bass_finger
Aleatoric.send :remove_const, :MIDI_Electric_Bass_pick
Aleatoric.send :remove_const, :MIDI_Fretless_Bass
Aleatoric.send :remove_const, :MIDI_Slap_Bass_1
Aleatoric.send :remove_const, :MIDI_Slap_Bass_2
Aleatoric.send :remove_const, :MIDI_Synth_Bass_1
Aleatoric.send :remove_const, :MIDI_Synth_Bass_2
Aleatoric.send :remove_const, :MIDI_Violin
Aleatoric.send :remove_const, :MIDI_Viola
Aleatoric.send :remove_const, :MIDI_Cello
Aleatoric.send :remove_const, :MIDI_Contrabass
Aleatoric.send :remove_const, :MIDI_Tremolo_Strings
Aleatoric.send :remove_const, :MIDI_Pizzicato_Strings
Aleatoric.send :remove_const, :MIDI_Orchestral_Harp
Aleatoric.send :remove_const, :MIDI_Timpani
Aleatoric.send :remove_const, :MIDI_String_Ensemble_1
Aleatoric.send :remove_const, :MIDI_String_Ensemble_2
Aleatoric.send :remove_const, :MIDI_SynthStrings_1
Aleatoric.send :remove_const, :MIDI_SynthStrings_2
Aleatoric.send :remove_const, :MIDI_Choir_Aahs
Aleatoric.send :remove_const, :MIDI_Voice_Oohs
Aleatoric.send :remove_const, :MIDI_Synth_Voice
Aleatoric.send :remove_const, :MIDI_Orchestra_Hit
Aleatoric.send :remove_const, :MIDI_Trumpet
Aleatoric.send :remove_const, :MIDI_Trombone
Aleatoric.send :remove_const, :MIDI_Tuba
Aleatoric.send :remove_const, :MIDI_Muted_Trumpet
Aleatoric.send :remove_const, :MIDI_French_Horn
Aleatoric.send :remove_const, :MIDI_Brass_Section
Aleatoric.send :remove_const, :MIDI_SynthBrass_1
Aleatoric.send :remove_const, :MIDI_SynthBrass_2
Aleatoric.send :remove_const, :MIDI_Soprano_Sax
Aleatoric.send :remove_const, :MIDI_Alto_Sax
Aleatoric.send :remove_const, :MIDI_Tenor_Sax
Aleatoric.send :remove_const, :MIDI_Baritone_Sax
Aleatoric.send :remove_const, :MIDI_Oboe
Aleatoric.send :remove_const, :MIDI_English_Horn
Aleatoric.send :remove_const, :MIDI_Bassoon
Aleatoric.send :remove_const, :MIDI_Clarinet
Aleatoric.send :remove_const, :MIDI_Piccolo
Aleatoric.send :remove_const, :MIDI_Flute
Aleatoric.send :remove_const, :MIDI_Recorder
Aleatoric.send :remove_const, :MIDI_Pan_Flute
Aleatoric.send :remove_const, :MIDI_Blown_Bottle
Aleatoric.send :remove_const, :MIDI_Shakuhachi
Aleatoric.send :remove_const, :MIDI_Whistle
Aleatoric.send :remove_const, :MIDI_Ocarina
Aleatoric.send :remove_const, :MIDI_Lead_1_square
Aleatoric.send :remove_const, :MIDI_Lead_2_sawtooth
Aleatoric.send :remove_const, :MIDI_Lead_3_calliope
Aleatoric.send :remove_const, :MIDI_Lead_4_chiff
Aleatoric.send :remove_const, :MIDI_Lead_5_charang
Aleatoric.send :remove_const, :MIDI_Lead_6_voice
Aleatoric.send :remove_const, :MIDI_Lead_7_fifths
Aleatoric.send :remove_const, :MIDI_Lead_8_bass_plus_lead
Aleatoric.send :remove_const, :MIDI_Pad_1_new_age
Aleatoric.send :remove_const, :MIDI_Pad_2_warm
Aleatoric.send :remove_const, :MIDI_Pad_3_polysynth
Aleatoric.send :remove_const, :MIDI_Pad_4_choir
Aleatoric.send :remove_const, :MIDI_Pad_5_bowed
Aleatoric.send :remove_const, :MIDI_Pad_6_metallic
Aleatoric.send :remove_const, :MIDI_Pad_7_halo
Aleatoric.send :remove_const, :MIDI_Pad_8_sweep
Aleatoric.send :remove_const, :MIDI_FX_1_rain
Aleatoric.send :remove_const, :MIDI_FX_2_soundtrack
Aleatoric.send :remove_const, :MIDI_FX_3_crystal
Aleatoric.send :remove_const, :MIDI_FX_4_atmosphere
Aleatoric.send :remove_const, :MIDI_FX_5_brightness
Aleatoric.send :remove_const, :MIDI_FX_6_goblins
Aleatoric.send :remove_const, :MIDI_FX_7_echoes
Aleatoric.send :remove_const, :MIDI_FX_8_sci_fi
Aleatoric.send :remove_const, :MIDI_Sitar
Aleatoric.send :remove_const, :MIDI_Banjo
Aleatoric.send :remove_const, :MIDI_Shamisen
Aleatoric.send :remove_const, :MIDI_Koto
Aleatoric.send :remove_const, :MIDI_Kalimba
Aleatoric.send :remove_const, :MIDI_Bag_pipe
Aleatoric.send :remove_const, :MIDI_Fiddle
Aleatoric.send :remove_const, :MIDI_Shanai
Aleatoric.send :remove_const, :MIDI_Tinkle_Bell
Aleatoric.send :remove_const, :MIDI_Agogo
Aleatoric.send :remove_const, :MIDI_Steel_Drums
Aleatoric.send :remove_const, :MIDI_Woodblock
Aleatoric.send :remove_const, :MIDI_Taiko_Drum
Aleatoric.send :remove_const, :MIDI_Melodic_Tom
Aleatoric.send :remove_const, :MIDI_Synth_Drum
Aleatoric.send :remove_const, :MIDI_Reverse_Cymbal
Aleatoric.send :remove_const, :MIDI_Guitar_Fret_Noise
Aleatoric.send :remove_const, :MIDI_Breath_Noise
Aleatoric.send :remove_const, :MIDI_Seashore
Aleatoric.send :remove_const, :MIDI_Bird_Tweet
Aleatoric.send :remove_const, :MIDI_Telephone_Ring
Aleatoric.send :remove_const, :MIDI_Helicopter
Aleatoric.send :remove_const, :MIDI_Applause
Aleatoric.send :remove_const, :MIDI_Gunshot

# Program Change Channel 10 Drum Program Change Values

Aleatoric.send :remove_const, :MIDI_Acoustic_Bass_Drum
Aleatoric.send :remove_const, :MIDI_Bass_Drum_1
Aleatoric.send :remove_const, :MIDI_Side_Stick
Aleatoric.send :remove_const, :MIDI_Acoustic_Snare
Aleatoric.send :remove_const, :MIDI_Hand_Clap
Aleatoric.send :remove_const, :MIDI_Electric_Snare
Aleatoric.send :remove_const, :MIDI_Low_Floor_Tom
Aleatoric.send :remove_const, :MIDI_Closed_Hi_Hat
Aleatoric.send :remove_const, :MIDI_High_Floor_Tom
Aleatoric.send :remove_const, :MIDI_Pedal_Hi_Hat
Aleatoric.send :remove_const, :MIDI_Low_Tom
Aleatoric.send :remove_const, :MIDI_Open_Hi_Hat
Aleatoric.send :remove_const, :MIDI_Low_Mid_Tom
Aleatoric.send :remove_const, :MIDI_Hi_Mid_Tom
Aleatoric.send :remove_const, :MIDI_Crash_Cymbal_1
Aleatoric.send :remove_const, :MIDI_High_Tom
Aleatoric.send :remove_const, :MIDI_Ride_Cymbal_1
Aleatoric.send :remove_const, :MIDI_Chinese_Cymbal
Aleatoric.send :remove_const, :MIDI_Ride_Bell
Aleatoric.send :remove_const, :MIDI_Tambourine
Aleatoric.send :remove_const, :MIDI_Splash_Cymbal
Aleatoric.send :remove_const, :MIDI_Cowbell
Aleatoric.send :remove_const, :MIDI_Crash_Cymbal_2
Aleatoric.send :remove_const, :MIDI_Vibraslap
Aleatoric.send :remove_const, :MIDI_Ride_Cymbal_2
Aleatoric.send :remove_const, :MIDI_Hi_Bongo
Aleatoric.send :remove_const, :MIDI_Low_Bongo
Aleatoric.send :remove_const, :MIDI_Mute_Hi_Conga
Aleatoric.send :remove_const, :MIDI_Open_Hi_Conga
Aleatoric.send :remove_const, :MIDI_Low_Conga
Aleatoric.send :remove_const, :MIDI_High_Timbale
Aleatoric.send :remove_const, :MIDI_Low_Timbale
Aleatoric.send :remove_const, :MIDI_High_Agogo
Aleatoric.send :remove_const, :MIDI_Low_Agogo
Aleatoric.send :remove_const, :MIDI_Cabasa
Aleatoric.send :remove_const, :MIDI_Maracas
Aleatoric.send :remove_const, :MIDI_Short_Whistle
Aleatoric.send :remove_const, :MIDI_Long_Whistle
Aleatoric.send :remove_const, :MIDI_Short_Guiro
Aleatoric.send :remove_const, :MIDI_Long_Guiro
Aleatoric.send :remove_const, :MIDI_Claves
Aleatoric.send :remove_const, :MIDI_Hi_Wood_Block
Aleatoric.send :remove_const, :MIDI_Low_Wood_Block
Aleatoric.send :remove_const, :MIDI_Mute_Cuica
Aleatoric.send :remove_const, :MIDI_Open_Cuica
Aleatoric.send :remove_const, :MIDI_Mute_Triangle
Aleatoric.send :remove_const, :MIDI_Open_Triangle

end

def unset_csound_consts
  # No-Op at this time, all CSound consts are names also used by MIDI, i.e. are a subset of MIDI const names
end


def set_midi_consts

unset_csound_consts if $LAST_FORMAT == :csound
$LAST_FORMAT = :midi

# Toggle stderr off for a minute to suppress warning from redefining constants from this dynamic
#  reloading of all the constants in global_midi.rb and global_csound.rb 
warnings_off

# MIDI note values

Aleatoric.const_set :Cneg1, 0
Aleatoric.const_set :Cneg1S, 1
Aleatoric.const_set :Dneg1F, 1
Aleatoric.const_set :Dneg1, 2
Aleatoric.const_set :Dneg1S, 3
Aleatoric.const_set :Eneg1F, 3
Aleatoric.const_set :Eneg1, 4
Aleatoric.const_set :Fneg1, 5
Aleatoric.const_set :Fneg1S, 6
Aleatoric.const_set :Gneg1F, 6
Aleatoric.const_set :Gneg1, 7
Aleatoric.const_set :Gneg1S, 8
Aleatoric.const_set :Aneg1F, 8
Aleatoric.const_set :Aneg1, 9
Aleatoric.const_set :Aneg1S, 10
Aleatoric.const_set :Bneg1F, 10
Aleatoric.const_set :Bneg1, 11
Aleatoric.const_set :C0, 12
Aleatoric.const_set :C0S, 13
Aleatoric.const_set :D0F, 13
Aleatoric.const_set :D0, 14
Aleatoric.const_set :D0S, 15
Aleatoric.const_set :E0F, 15
Aleatoric.const_set :E0, 16
Aleatoric.const_set :F0, 17
Aleatoric.const_set :F0S, 18
Aleatoric.const_set :G0F, 18
Aleatoric.const_set :G0, 19
Aleatoric.const_set :G0S, 20
Aleatoric.const_set :A0F, 20
Aleatoric.const_set :A0, 21
Aleatoric.const_set :A0S, 22
Aleatoric.const_set :B0F, 22
Aleatoric.const_set :B0, 23
Aleatoric.const_set :C1, 24
Aleatoric.const_set :C1S, 25
Aleatoric.const_set :D1F, 25
Aleatoric.const_set :D1, 26
Aleatoric.const_set :D1S, 27
Aleatoric.const_set :E1F, 27
Aleatoric.const_set :E1, 28
Aleatoric.const_set :F1, 29
Aleatoric.const_set :F1S, 30
Aleatoric.const_set :G1F, 30
Aleatoric.const_set :G1, 31
Aleatoric.const_set :G1S, 32
Aleatoric.const_set :A1F, 32
Aleatoric.const_set :A1, 33
Aleatoric.const_set :A1S, 34
Aleatoric.const_set :B1F, 34
Aleatoric.const_set :B1, 35
Aleatoric.const_set :C2, 36
Aleatoric.const_set :C2S, 37
Aleatoric.const_set :D2F, 37
Aleatoric.const_set :D2, 38
Aleatoric.const_set :D2S, 39
Aleatoric.const_set :E2F, 39
Aleatoric.const_set :E2, 40
Aleatoric.const_set :F2, 41
Aleatoric.const_set :F2S, 42
Aleatoric.const_set :G2F, 42
Aleatoric.const_set :G2, 43
Aleatoric.const_set :G2S, 44
Aleatoric.const_set :A2F, 44
Aleatoric.const_set :A2, 45
Aleatoric.const_set :A2S, 46
Aleatoric.const_set :B2F, 46
Aleatoric.const_set :B2, 47
Aleatoric.const_set :C3, 48
Aleatoric.const_set :C3S, 49
Aleatoric.const_set :D3F, 49
Aleatoric.const_set :D3, 50
Aleatoric.const_set :D3S, 51
Aleatoric.const_set :E3F, 51
Aleatoric.const_set :E3, 52
Aleatoric.const_set :F3, 53
Aleatoric.const_set :F3S, 54
Aleatoric.const_set :G3F, 54
Aleatoric.const_set :G3, 55
Aleatoric.const_set :G3S, 56
Aleatoric.const_set :A3F, 56
Aleatoric.const_set :A3, 57
Aleatoric.const_set :A3S, 58
Aleatoric.const_set :B3F, 58
Aleatoric.const_set :B3, 59
Aleatoric.const_set :C4, 60
Aleatoric.const_set :C4S, 61
Aleatoric.const_set :D4F, 61
Aleatoric.const_set :D4, 62
Aleatoric.const_set :D4S, 63
Aleatoric.const_set :E4F, 63
Aleatoric.const_set :E4, 64
Aleatoric.const_set :F4, 65
Aleatoric.const_set :F4S, 66
Aleatoric.const_set :G4F, 66
Aleatoric.const_set :G4, 67
Aleatoric.const_set :G4S, 68
Aleatoric.const_set :A4F, 68
Aleatoric.const_set :A4, 69
Aleatoric.const_set :A4S, 70
Aleatoric.const_set :B4F, 70
Aleatoric.const_set :B4, 71
Aleatoric.const_set :C5, 72
Aleatoric.const_set :C5S, 73
Aleatoric.const_set :D5F, 73
Aleatoric.const_set :D5, 74
Aleatoric.const_set :D5S, 75
Aleatoric.const_set :E5F, 75
Aleatoric.const_set :E5, 76
Aleatoric.const_set :F5, 77
Aleatoric.const_set :F5S, 78
Aleatoric.const_set :G5F, 78
Aleatoric.const_set :G5, 79
Aleatoric.const_set :G5S, 80
Aleatoric.const_set :A5F, 80
Aleatoric.const_set :A5, 81
Aleatoric.const_set :A5S, 82
Aleatoric.const_set :B5F, 82
Aleatoric.const_set :B5, 83
Aleatoric.const_set :C6, 84
Aleatoric.const_set :C6S, 85
Aleatoric.const_set :D6F, 85
Aleatoric.const_set :D6, 86
Aleatoric.const_set :D6S, 87
Aleatoric.const_set :E6F, 87
Aleatoric.const_set :E6, 88
Aleatoric.const_set :F6, 89
Aleatoric.const_set :F6S, 90
Aleatoric.const_set :G6F, 90
Aleatoric.const_set :G6, 91
Aleatoric.const_set :G6S, 92
Aleatoric.const_set :A6F, 92
Aleatoric.const_set :A6, 93
Aleatoric.const_set :A6S, 94
Aleatoric.const_set :B6F, 94
Aleatoric.const_set :B6, 95
Aleatoric.const_set :C7, 96
Aleatoric.const_set :C7S, 97
Aleatoric.const_set :D7F, 97
Aleatoric.const_set :D7, 98
Aleatoric.const_set :D7S, 99
Aleatoric.const_set :E7F, 99
Aleatoric.const_set :E7, 100
Aleatoric.const_set :F7, 101
Aleatoric.const_set :F7S, 102
Aleatoric.const_set :G7F, 102
Aleatoric.const_set :G7, 103
Aleatoric.const_set :G7S, 104
Aleatoric.const_set :A7F, 104
Aleatoric.const_set :A7, 105
Aleatoric.const_set :A7S, 106
Aleatoric.const_set :B7F, 106
Aleatoric.const_set :B7, 107
Aleatoric.const_set :C8, 108
Aleatoric.const_set :C8S, 109
Aleatoric.const_set :D8F, 109
Aleatoric.const_set :D8, 110
Aleatoric.const_set :D8S, 111
Aleatoric.const_set :E8F, 111
Aleatoric.const_set :E8, 112
Aleatoric.const_set :F8, 113
Aleatoric.const_set :F8S, 114
Aleatoric.const_set :G8F, 114
Aleatoric.const_set :G8, 115
Aleatoric.const_set :G8S, 116
Aleatoric.const_set :A8F, 116
Aleatoric.const_set :A8, 117
Aleatoric.const_set :A8S, 118
Aleatoric.const_set :B8F, 118
Aleatoric.const_set :B8, 119
Aleatoric.const_set :C9, 120
Aleatoric.const_set :C9S, 121
Aleatoric.const_set :D9F, 121
Aleatoric.const_set :D9, 122
Aleatoric.const_set :D9S, 123
Aleatoric.const_set :E9F, 123
Aleatoric.const_set :E9, 124
Aleatoric.const_set :F9, 125
Aleatoric.const_set :F9S, 126
Aleatoric.const_set :G9F, 126
Aleatoric.const_set :G9, 127

# General MIDI Program Change Instrument Values

Aleatoric.const_set :MIDI_Acoustic_Grand_Piano, 1
Aleatoric.const_set :MIDI_Bright_Acoustic_Piano, 2
Aleatoric.const_set :MIDI_Electric_Grand_Piano, 3
Aleatoric.const_set :MIDI_Honky_tonk_Piano, 4
Aleatoric.const_set :MIDI_Electric_Piano_1, 5
Aleatoric.const_set :MIDI_Electric_Piano_2, 6
Aleatoric.const_set :MIDI_Harpsichord, 7
Aleatoric.const_set :MIDI_Clavi, 8
Aleatoric.const_set :MIDI_Celesta, 9
Aleatoric.const_set :MIDI_Glockenspiel, 10
Aleatoric.const_set :MIDI_Music_Box, 11
Aleatoric.const_set :MIDI_Vibraphone, 12
Aleatoric.const_set :MIDI_Marimba, 13
Aleatoric.const_set :MIDI_Xylophone, 14
Aleatoric.const_set :MIDI_Tubular_Bells, 15
Aleatoric.const_set :MIDI_Dulcimer, 16
Aleatoric.const_set :MIDI_Drawbar_Organ, 17
Aleatoric.const_set :MIDI_Percussive_Organ, 18
Aleatoric.const_set :MIDI_Rock_Organ, 19
Aleatoric.const_set :MIDI_Church_Organ, 20
Aleatoric.const_set :MIDI_Reed_Organ, 21
Aleatoric.const_set :MIDI_Accordion, 22
Aleatoric.const_set :MIDI_Harmonica, 23
Aleatoric.const_set :MIDI_Tango_Accordion, 24
Aleatoric.const_set :MIDI_Acoustic_Guitar_nylon, 25
Aleatoric.const_set :MIDI_Acoustic_Guitar_steel, 26
Aleatoric.const_set :MIDI_Electric_Guitar_jazz, 27
Aleatoric.const_set :MIDI_Electric_Guitar_clean, 28
Aleatoric.const_set :MIDI_Electric_Guitar_muted, 29
Aleatoric.const_set :MIDI_Overdriven_Guitar, 30
Aleatoric.const_set :MIDI_Distortion_Guitar, 31
Aleatoric.const_set :MIDI_Guitar_harmonics, 32
Aleatoric.const_set :MIDI_Acoustic_Bass, 33
Aleatoric.const_set :MIDI_Electric_Bass_finger, 34
Aleatoric.const_set :MIDI_Electric_Bass_pick, 35
Aleatoric.const_set :MIDI_Fretless_Bass, 36
Aleatoric.const_set :MIDI_Slap_Bass_1, 37
Aleatoric.const_set :MIDI_Slap_Bass_2, 38
Aleatoric.const_set :MIDI_Synth_Bass_1, 39
Aleatoric.const_set :MIDI_Synth_Bass_2, 40
Aleatoric.const_set :MIDI_Violin, 41
Aleatoric.const_set :MIDI_Viola, 42
Aleatoric.const_set :MIDI_Cello, 43
Aleatoric.const_set :MIDI_Contrabass, 44
Aleatoric.const_set :MIDI_Tremolo_Strings, 45
Aleatoric.const_set :MIDI_Pizzicato_Strings, 46
Aleatoric.const_set :MIDI_Orchestral_Harp, 47
Aleatoric.const_set :MIDI_Timpani, 48
Aleatoric.const_set :MIDI_String_Ensemble_1, 49
Aleatoric.const_set :MIDI_String_Ensemble_2, 50
Aleatoric.const_set :MIDI_SynthStrings_1, 51
Aleatoric.const_set :MIDI_SynthStrings_2, 52
Aleatoric.const_set :MIDI_Choir_Aahs, 53
Aleatoric.const_set :MIDI_Voice_Oohs, 54
Aleatoric.const_set :MIDI_Synth_Voice, 55
Aleatoric.const_set :MIDI_Orchestra_Hit, 56
Aleatoric.const_set :MIDI_Trumpet, 57
Aleatoric.const_set :MIDI_Trombone, 58
Aleatoric.const_set :MIDI_Tuba, 59
Aleatoric.const_set :MIDI_Muted_Trumpet, 60
Aleatoric.const_set :MIDI_French_Horn, 61
Aleatoric.const_set :MIDI_Brass_Section, 62
Aleatoric.const_set :MIDI_SynthBrass_1, 63
Aleatoric.const_set :MIDI_SynthBrass_2, 64
Aleatoric.const_set :MIDI_Soprano_Sax, 65
Aleatoric.const_set :MIDI_Alto_Sax, 66
Aleatoric.const_set :MIDI_Tenor_Sax, 67
Aleatoric.const_set :MIDI_Baritone_Sax, 68
Aleatoric.const_set :MIDI_Oboe, 69
Aleatoric.const_set :MIDI_English_Horn, 70
Aleatoric.const_set :MIDI_Bassoon, 71
Aleatoric.const_set :MIDI_Clarinet, 72
Aleatoric.const_set :MIDI_Piccolo, 73
Aleatoric.const_set :MIDI_Flute, 74
Aleatoric.const_set :MIDI_Recorder, 75
Aleatoric.const_set :MIDI_Pan_Flute, 76
Aleatoric.const_set :MIDI_Blown_Bottle, 77
Aleatoric.const_set :MIDI_Shakuhachi, 78
Aleatoric.const_set :MIDI_Whistle, 79
Aleatoric.const_set :MIDI_Ocarina, 80
Aleatoric.const_set :MIDI_Lead_1_square, 81
Aleatoric.const_set :MIDI_Lead_2_sawtooth, 82
Aleatoric.const_set :MIDI_Lead_3_calliope, 83
Aleatoric.const_set :MIDI_Lead_4_chiff, 84
Aleatoric.const_set :MIDI_Lead_5_charang, 85
Aleatoric.const_set :MIDI_Lead_6_voice, 86
Aleatoric.const_set :MIDI_Lead_7_fifths, 87
Aleatoric.const_set :MIDI_Lead_8_bass_plus_lead, 88
Aleatoric.const_set :MIDI_Pad_1_new_age, 89
Aleatoric.const_set :MIDI_Pad_2_warm, 90
Aleatoric.const_set :MIDI_Pad_3_polysynth, 91
Aleatoric.const_set :MIDI_Pad_4_choir, 92
Aleatoric.const_set :MIDI_Pad_5_bowed, 93
Aleatoric.const_set :MIDI_Pad_6_metallic, 94
Aleatoric.const_set :MIDI_Pad_7_halo, 95
Aleatoric.const_set :MIDI_Pad_8_sweep, 96
Aleatoric.const_set :MIDI_FX_1_rain, 97
Aleatoric.const_set :MIDI_FX_2_soundtrack, 98
Aleatoric.const_set :MIDI_FX_3_crystal, 99
Aleatoric.const_set :MIDI_FX_4_atmosphere, 100
Aleatoric.const_set :MIDI_FX_5_brightness, 101
Aleatoric.const_set :MIDI_FX_6_goblins, 102
Aleatoric.const_set :MIDI_FX_7_echoes, 103
Aleatoric.const_set :MIDI_FX_8_sci_fi, 104
Aleatoric.const_set :MIDI_Sitar, 105
Aleatoric.const_set :MIDI_Banjo, 106
Aleatoric.const_set :MIDI_Shamisen, 107
Aleatoric.const_set :MIDI_Koto, 108
Aleatoric.const_set :MIDI_Kalimba, 109
Aleatoric.const_set :MIDI_Bag_pipe, 110
Aleatoric.const_set :MIDI_Fiddle, 111
Aleatoric.const_set :MIDI_Shanai, 112
Aleatoric.const_set :MIDI_Tinkle_Bell, 113
Aleatoric.const_set :MIDI_Agogo, 114
Aleatoric.const_set :MIDI_Steel_Drums, 115
Aleatoric.const_set :MIDI_Woodblock, 116
Aleatoric.const_set :MIDI_Taiko_Drum, 117
Aleatoric.const_set :MIDI_Melodic_Tom, 118
Aleatoric.const_set :MIDI_Synth_Drum, 119
Aleatoric.const_set :MIDI_Reverse_Cymbal, 120
Aleatoric.const_set :MIDI_Guitar_Fret_Noise, 121
Aleatoric.const_set :MIDI_Breath_Noise, 122
Aleatoric.const_set :MIDI_Seashore, 123
Aleatoric.const_set :MIDI_Bird_Tweet, 124
Aleatoric.const_set :MIDI_Telephone_Ring, 125
Aleatoric.const_set :MIDI_Helicopter, 126
Aleatoric.const_set :MIDI_Applause, 127
Aleatoric.const_set :MIDI_Gunshot, 128

# Program Change Channel 10 Drum Program Change Values

Aleatoric.const_set :MIDI_Acoustic_Bass_Drum, 35
Aleatoric.const_set :MIDI_Bass_Drum_1, 36
Aleatoric.const_set :MIDI_Side_Stick, 37
Aleatoric.const_set :MIDI_Acoustic_Snare, 38
Aleatoric.const_set :MIDI_Hand_Clap, 39
Aleatoric.const_set :MIDI_Electric_Snare, 40
Aleatoric.const_set :MIDI_Low_Floor_Tom, 41
Aleatoric.const_set :MIDI_Closed_Hi_Hat, 42
Aleatoric.const_set :MIDI_High_Floor_Tom, 43
Aleatoric.const_set :MIDI_Pedal_Hi_Hat, 44
Aleatoric.const_set :MIDI_Low_Tom, 45
Aleatoric.const_set :MIDI_Open_Hi_Hat, 46
Aleatoric.const_set :MIDI_Low_Mid_Tom, 47
Aleatoric.const_set :MIDI_Hi_Mid_Tom, 48
Aleatoric.const_set :MIDI_Crash_Cymbal_1, 49
Aleatoric.const_set :MIDI_High_Tom, 50
Aleatoric.const_set :MIDI_Ride_Cymbal_1, 51
Aleatoric.const_set :MIDI_Chinese_Cymbal, 52
Aleatoric.const_set :MIDI_Ride_Bell, 53
Aleatoric.const_set :MIDI_Tambourine, 54
Aleatoric.const_set :MIDI_Splash_Cymbal, 55
Aleatoric.const_set :MIDI_Cowbell, 56
Aleatoric.const_set :MIDI_Crash_Cymbal_2, 57
Aleatoric.const_set :MIDI_Vibraslap, 58
Aleatoric.const_set :MIDI_Ride_Cymbal_2, 59
Aleatoric.const_set :MIDI_Hi_Bongo, 60
Aleatoric.const_set :MIDI_Low_Bongo, 61
Aleatoric.const_set :MIDI_Mute_Hi_Conga, 62
Aleatoric.const_set :MIDI_Open_Hi_Conga, 63
Aleatoric.const_set :MIDI_Low_Conga, 64
Aleatoric.const_set :MIDI_High_Timbale, 65
Aleatoric.const_set :MIDI_Low_Timbale, 66
Aleatoric.const_set :MIDI_High_Agogo, 67
Aleatoric.const_set :MIDI_Low_Agogo, 68
Aleatoric.const_set :MIDI_Cabasa, 69
Aleatoric.const_set :MIDI_Maracas, 70
Aleatoric.const_set :MIDI_Short_Whistle, 71
Aleatoric.const_set :MIDI_Long_Whistle, 72
Aleatoric.const_set :MIDI_Short_Guiro, 73
Aleatoric.const_set :MIDI_Long_Guiro, 74
Aleatoric.const_set :MIDI_Claves, 75
Aleatoric.const_set :MIDI_Hi_Wood_Block, 76
Aleatoric.const_set :MIDI_Low_Wood_Block, 77
Aleatoric.const_set :MIDI_Mute_Cuica, 78
Aleatoric.const_set :MIDI_Open_Cuica, 79
Aleatoric.const_set :MIDI_Mute_Triangle, 80
Aleatoric.const_set :MIDI_Open_Triangle, 81

# Toggle stderr back on
warnings_on

end


def set_csound_consts

# Toggle stderr off for a minute to suppress warning from redefining constants from this dynamic
#  reloading of all the constants in global_midi.rb and global_csound.rb 
warnings_off

# Remove MIDI consts only used by MIDI to avoid using them with CSound format
#  and silently passing bogus values to CSound that might not cause errors but
#  might not behave as intended
unset_midi_consts if $LAST_FORMAT == :midi
$LAST_FORMAT = :csound

# Now set CSound consts, which are just the scale note values in CSound cspch format
Aleatoric.const_set :C1, 5.00
Aleatoric.const_set :C1S, 5.01
Aleatoric.const_set :D1F, 5.01
Aleatoric.const_set :D1, 5.02
Aleatoric.const_set :D1S, 5.03
Aleatoric.const_set :E1F, 5.03
Aleatoric.const_set :E1, 5.04
Aleatoric.const_set :F1, 5.05
Aleatoric.const_set :F1S, 5.06
Aleatoric.const_set :G1F, 5.06
Aleatoric.const_set :G1, 5.07
Aleatoric.const_set :G1S, 5.08
Aleatoric.const_set :A1F, 5.08
Aleatoric.const_set :A1, 5.09
Aleatoric.const_set :A1S, 5.10
Aleatoric.const_set :B1F, 5.10
Aleatoric.const_set :B1, 5.11
Aleatoric.const_set :C2LIM, 5.12
Aleatoric.const_set :C2, 6.00
Aleatoric.const_set :C2S, 6.01
Aleatoric.const_set :D2F, 6.01
Aleatoric.const_set :D2, 6.02
Aleatoric.const_set :D2S, 6.03
Aleatoric.const_set :E2F, 6.03
Aleatoric.const_set :E2, 6.04
Aleatoric.const_set :F2, 6.05
Aleatoric.const_set :F2S, 6.06
Aleatoric.const_set :G2F, 6.06
Aleatoric.const_set :G2, 6.07
Aleatoric.const_set :G2S, 6.08
Aleatoric.const_set :A2F, 6.08
Aleatoric.const_set :A2, 6.09
Aleatoric.const_set :A2S, 6.10
Aleatoric.const_set :B2F, 6.10
Aleatoric.const_set :B2, 6.11
Aleatoric.const_set :C3LIM, 6.12
Aleatoric.const_set :C3, 7.00
Aleatoric.const_set :C3S, 7.01
Aleatoric.const_set :D3F, 7.01
Aleatoric.const_set :D3, 7.02
Aleatoric.const_set :D3S, 7.03
Aleatoric.const_set :E3F, 7.03
Aleatoric.const_set :E3, 7.04
Aleatoric.const_set :F3, 7.05
Aleatoric.const_set :F3S, 7.06
Aleatoric.const_set :G3F, 7.06
Aleatoric.const_set :G3, 7.07
Aleatoric.const_set :G3S, 7.08
Aleatoric.const_set :A3F, 7.08
Aleatoric.const_set :A3, 7.09
Aleatoric.const_set :A3S, 7.10
Aleatoric.const_set :B3F, 7.10
Aleatoric.const_set :B3, 7.11
Aleatoric.const_set :C4LIM, 7.12
Aleatoric.const_set :C4, 8.00
Aleatoric.const_set :C4S, 8.01
Aleatoric.const_set :D4F, 8.01
Aleatoric.const_set :D4, 8.02
Aleatoric.const_set :D4S, 8.03
Aleatoric.const_set :E4F, 8.03
Aleatoric.const_set :E4, 8.04
Aleatoric.const_set :F4, 8.05
Aleatoric.const_set :F4S, 8.06
Aleatoric.const_set :G4F, 8.06
Aleatoric.const_set :G4, 8.07
Aleatoric.const_set :G4S, 8.08
Aleatoric.const_set :A4F, 8.08
Aleatoric.const_set :A4, 8.09
Aleatoric.const_set :A4S, 8.10
Aleatoric.const_set :B4F, 8.10
Aleatoric.const_set :B4, 8.11
Aleatoric.const_set :C5LIM, 8.12
Aleatoric.const_set :C5, 9.00
Aleatoric.const_set :C5S, 9.01
Aleatoric.const_set :D5F, 9.01
Aleatoric.const_set :D5, 9.02
Aleatoric.const_set :D5S, 9.03
Aleatoric.const_set :E5F, 9.03
Aleatoric.const_set :E5, 9.04
Aleatoric.const_set :F5, 9.05
Aleatoric.const_set :F5S, 9.06
Aleatoric.const_set :G5F, 9.06
Aleatoric.const_set :G5, 9.07
Aleatoric.const_set :G5S, 9.08
Aleatoric.const_set :A5F, 9.08
Aleatoric.const_set :A5, 9.09
Aleatoric.const_set :A5S, 9.10
Aleatoric.const_set :B5F, 9.10
Aleatoric.const_set :B5, 9.11
Aleatoric.const_set :C6LIM, 9.12
Aleatoric.const_set :C6, 10.00
Aleatoric.const_set :C6S, 10.01
Aleatoric.const_set :D6F, 10.01
Aleatoric.const_set :D6, 10.02
Aleatoric.const_set :D6S, 10.03
Aleatoric.const_set :E6F, 10.03
Aleatoric.const_set :E6, 10.04
Aleatoric.const_set :F6, 10.05
Aleatoric.const_set :F6S, 10.06
Aleatoric.const_set :G6F, 10.06
Aleatoric.const_set :G6, 10.07
Aleatoric.const_set :G6S, 10.08
Aleatoric.const_set :A6F, 10.08
Aleatoric.const_set :A6, 10.09
Aleatoric.const_set :A6S, 10.10
Aleatoric.const_set :B6F, 10.10
Aleatoric.const_set :B6, 10.11
Aleatoric.const_set :C7LIM, 10.12
Aleatoric.const_set :C7, 11.00
Aleatoric.const_set :C7S, 11.01
Aleatoric.const_set :D7F, 11.01
Aleatoric.const_set :D7, 11.02
Aleatoric.const_set :D7S, 11.03
Aleatoric.const_set :E7F, 11.03
Aleatoric.const_set :E7, 11.04
Aleatoric.const_set :F7, 11.05
Aleatoric.const_set :F7S, 11.06
Aleatoric.const_set :G7F, 11.06
Aleatoric.const_set :G7, 11.07
Aleatoric.const_set :G7S, 11.08
Aleatoric.const_set :A7F, 11.08
Aleatoric.const_set :A7, 11.09
Aleatoric.const_set :A7S, 11.10
Aleatoric.const_set :B7F, 11.10
Aleatoric.const_set :B7, 11.11
Aleatoric.const_set :C8LIM, 11.12
Aleatoric.const_set :C8, 12.00
Aleatoric.const_set :C8S, 12.01
Aleatoric.const_set :D8F, 12.01
Aleatoric.const_set :D8, 12.02
Aleatoric.const_set :D8S, 12.03
Aleatoric.const_set :E8F, 12.03
Aleatoric.const_set :E8, 12.04
Aleatoric.const_set :F8, 12.05
Aleatoric.const_set :F8S, 12.06
Aleatoric.const_set :G8F, 12.06
Aleatoric.const_set :G8, 12.07
Aleatoric.const_set :G8S, 12.08
Aleatoric.const_set :A8F, 12.08
Aleatoric.const_set :A8, 12.09
Aleatoric.const_set :A8S, 12.10
Aleatoric.const_set :B8F, 12.10
Aleatoric.const_set :B8, 12.11

# Toggle stderr back on
warnings_on

end


end