cd ..\lib
ruby aleatoric.rb ..\compositions\test_midi.altc
cd ..\compositions
"C:\Program Files\Windows Media Player\mplayer2.exe" test_midi.mid
