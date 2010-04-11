; HEADER
sr		    	=         44100		; OPT - play with sampling rate, try lower rate
kr        	=         441			; OPT - play with control rate, here its sr/10
ksmps     	=         100
nchnls    	=         2

instr	1					
		; Initialize variables
		; Envelope shape
    iRiseFctr = .13
    iDecayFctr = .08
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
    
    ; 	Envelope; Give each channel have a slightly different envelope, with beautiful results
		;   	Opcode,   Amplitude,  Rise,            Duration,   Decay
		ar1		linen	    iAmp,       iRise1*.999,     iDur1,      iDec1*1.01  
		ar2		linen	    iAmp,       iRise1*1.001,    iDur1,      iDec1*.999
    
		; 	Opcode, Amplitude, 	  Frequency, 	Function#
		a1	oscil   ar1,	        iPitch,			iFuncNum
		a2	oscil   ar2,		    	iPitch,			iFuncNum
				outs a1, a2
endin
