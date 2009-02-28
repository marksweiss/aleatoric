; HEADER
sr		    =         44100		; OPT - play with sampling rate, try lower rate
kr        	=         441		; OPT - play with control rate, here its sr/10
ksmps     	=         100
nchnls    	=         2


; INSTRUMENTS

; Preprocessor Defines
;#define NUMINSTR #62#
;#define FTABLETYPESPLIT #40#
;#define AMPFACTOR #3#



instr	1
						
	; Initialize variables
	; Envelope shape
    ;iPhsFctr = .97
    iRiseFctr = .15
    iDecayFctr = .10
	iDur1 = p3
	iRise1 = iDur1 * iRiseFctr
	iDec1 = iDur1 * iDecayFctr
    ; Amp
    iNumOuts = 2
    iAmpDampeningFctr = 1.0
    iAmp = (p4 / iNumOuts) * iAmpDampeningFctr
	; Other note params
    iPitch = cpspch(p5) ; Convert from std. Western notation to frequency
	iFuncNum = p6
    
        ; *(rnd(1)*iPhsFctr)
    	; 	Envelope
		;   Opcode,     Amplitude,  Rise,                       Duration,   Decay
		ar1	linen	    iAmp,       iRise1*.999,                iDur1,      iDec1*1.01  ; Give each channel have a slightly different envelope, with beautiful results
		ar2	linen	    iAmp,       iRise1*1.001,               iDur1,      iDec1*.999  ; Give each channel have a slightly different envelope, with beautiful results
		;ar3	linen	    iAmp,       iRise1 * (rnd(1)*iPhsFctr), iDur1,      iDec1 * (rnd(1)*iPhsFctr)
		;ar4	linen	    iAmp,       iRise1 * (rnd(1)*iPhsFctr), iDur1,      iDec1 * (rnd(1)*iPhsFctr)
    
		; 	Opcode, Amplitude, 	    Frequency, 	Function#
		a1	oscil   ar1,	        iPitch,		iFuncNum
		a2	oscil   ar2,		    iPitch,		iFuncNum
		;a3	oscil   ar3,	        iPitch,		iFuncNum
		;a4	oscil   ar4,	        iPitch,		iFuncNum
			;outs	( (((a1 + a2) / 2) + (a3 * .05))) , ( (((a1 + a2) / 2) + (a4 * .05)))
            outs	 (a1 / 2) , (a2 / 2) 
            ; % 10000
endin
