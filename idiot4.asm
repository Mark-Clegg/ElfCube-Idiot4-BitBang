;-------------------------------------------------------------;
; IDIOT/4 MONITOR FOR THE 1802   WRITTEN: 6/23/82 BY LEE HART ;
; COPYRIGHT 1982-85 BY TMSI	LAST MOD: 3/28/86 BY LEE HART   ;
;							                    ;
; This program may be used for any noncommercial use free of  ;
; charge. Contact information: Lee A. Hart, 814 8th Ave N,    ;
; Sartell MN 56377, email <leeahart@earthlink.net>	        ;
;-------------------------------------------------------------;
;
;fixes by Herb Johnson HRJ April 2010, Jan 2014, Feb 2014
; changed "DC" to "DB"
; ORGed to 8000H for 1802 Membership Card
; changed other ORG [value] to RESET+[value]
;  operating notes
;  EF4 was serial in (BN4, B4), Q is serial out 
;  M/S card uses EF3 - BN3, B3 instructions 
;
; BASIS card used OUT 7 "turn reader on" bit 7, "off" bit 6
;
; added IF EFHI....ELSE ....ENDIF statements
; and   IF QHI....ELSE...ENDIF
; to make it easy to manage serial in/out 
; EFHI or QHI = 1, then active high
; EFHI or QHI = 0, then active low
;
; *remember* that when /EF3 pin on CPU is 0, EF3 is 1
; and B3 WILL branch - 
;
; IDIOT-1, EF3 active low and Q active high at 8400H;
;
; register equivalents for A18
R0		EQU	0
R1		EQU	1
R2		EQU	2
R3		EQU	3
R4		EQU	4
R5		EQU	5
R6		EQU	6
R7		EQU	7
R8		EQU	8
R9		EQU	9
RA		EQU	10
RB		EQU	11
RC		EQU	12
RD		EQU	13
RE		EQU	14
RF		EQU	15
;
;
; REGISTER ASSIGNMENTS:
;
;		1 - INTERRUPT PROGRAM COUNTER (FOR BREAKPOINTS)
;		2 - STACK POINTER
;		3 - NORMAL PROGRAM COUNTER
;		4 - MONITOR: RAM PAGE0 POINTER
;		    BASIC:   SCRT "CALL" PC
;		5 - MONITOR: MAIN PC
;		    BASIC:   SCRT "RETURN" PC
;		8 - MONITOR: ?M VS. !M SWITCH
;	       10 - MONITOR: MEMORY POINTER
DELAY	EQU    12 ; PC FOR DELAY SUBROUTINE
HEXX	EQU    13 ; MONITOR: HEX ADDRESS ACCUMULATOR
BAUD	EQU    14 ; RE.1=BAUD RATE CONSTANT
;		    RE.0=USED FOR READ, TYPE
ASCII	EQU    15 ; RF.1=ASCII I/O CHARACTER
;		    RF.0=USED FOR READ, TYPE
;
	PROCESSOR	1802
;
; EQUATES
;
TYPA	EQU	0D3H		; TYPE CHARACTER MACRO
;
;  EF3 active LOW Q active HIGH
EFHI	EQU	0	; 0=active low EF for serial
QHI	EQU	1	; 1=active high Q for serial
;
	org	0000H		;HRJ for Membership Card
RESET	DIS			; DISABLE INTERRUPTS
	DB	0
FINDRAM LDI	0FFH		; FIND RAM, STARTING AT FFFF
	PHI	R4
TRYAGAIN LDI	0FFH		; REPEAT...
	PLO	R4		; - TEST TOP BYTE ON PAGE
	STR	R4		; - STORE 'FF'
	LDN	R4		;   READ IT BACK,
	XRI	0FFH		;   COMPARE
	LSNZ			; - IF OK, STORE ALL 0'S,
	STR	R4		;   READ BACK,
	LDN	R4		;   COMPARE
	BZ	RAMFOUND	; - IF OK, THEN RAM FOUND
	GHI	R4		; - IF NO MORE PAGES TO TEST,
	BZ	NORAM		;      THEN GO TO NORAM
	PLO	R4		;      ELSE DEC. PAGE NUMBER
	DEC	R4
	GLO	R4
	PHI	R4		; ...UNTIL DONE
	BR	TRYAGAIN
RAMFOUND LDI	0DFH		; RAM FOUND:
	PLO	R4		; SAVE CPU REGISTERS
	SEX	R4
;
; SAVE REGISTERS:  SAVES A COPY OF ALL CPU REGISTERS & I/O BITS
;	IN RAM. MUST BE ENTERED WITH P=R0 OR R1, X=R4.	SAVES
;	ALL REGISTERS CORRECTLY EXCEPT P, X, D, R(P), AND R4.
;
SAVER	GLO	RF		; SAVE REGISTERS R0-RF IN RAM
	STXD
	GHI	RF		; RF 1ST, R0 LAST,
	STXD			; WITH HI BYTE IN LOWER ADDRESS
	GLO	RE
	STXD
	GHI	RE
	STXD			; THE REGISTERS BEING USED FOR PROGRAM
	GLO	RD		; COUNTER AND RAM POINTER ARE CHANGING
	STXD			; DURING EXECUTION, SO THEIR STORED VALUES
	GHI	RD		; WILL BE FIXED LATER.
	STXD
	GLO	RC
	STXD
	GHI	RC
	STXD
	GLO	RB
	STXD
	GHI	RB
	STXD
	GLO	RA
	STXD
	GHI	RA
	STXD
	GLO	R9
	STXD
	GHI	R9
	STXD
	GLO	R8
	STXD
	GHI	R8
	STXD
	GLO	R7
	STXD
	GHI	R7
	STXD
	GLO	R6
	STXD
	GHI	R6
	STXD
	GLO	R5
	STXD
	GHI	R5
	STXD
	STXD			; DON'T BOTHER TO SAVE R4 (SAVES 2 BYTES)
	STXD
	GLO	R3
	STXD
	GHI	R3
	STXD
	GLO	R2
	STXD
	GHI	R2
	STXD
	GLO	R1
	STXD
	GHI	R1
	STXD
	GLO	R0
	STXD
	GHI	R0
	STXD
	LDI	0		; LOAD 0 (& SAVE A COPY FOR LATER)
	PHI	R3
	BN4	$+4		; PACK STATUS OF EF4 & EF3 INTO 1 BYTE
	ORI	004H		; AND PUSH INTO RAM
	BN4	$+4		;   X4 - EF4 ACTIVE
	ORI	030H		;   3X - EF3 ACTIVE
	STXD
	GHI	R3		; PACK STATUS OF EF2 & EF1 INTO 1 BYTE
	BN2	$+4		; AND PUSH INTO RAM
	ORI	002H		;   X2 - EF2 ACTIVE
	BN1	$+4		;   1X - EF1 ACTIVE
	ORI	010H
	STXD
	GHI	R3		; PUSH STATUS OF Q INTO RAM
	LSNQ			;   1 - Q ACTIVE
	ORI	1		;   0 - Q INACTIVE
	STXD
	LDI	1		; PUSH STATUS OF IE INTO RAM
	LSIE			;   1 - ENABLED
	LDI	0		;   0 - DISABLED
	STXD
	GHI	R3		; PUSH D(=0) TO RAM (DUMMY VALUE)
	STXD
	ADCI	0		; PUSH DF INTO RAM
	STXD
	SAV			; PUSH T INTO RAM
	DEC	R4
	LDI	LOW IFINT	; IF CALLED VIA INTERRUPT, RETURN
	PLO	R1
	GHI	R0		; ELSE CALLED VIA RESET,
	PHI	R1		;      SET RP=R1
	LDI	LOW ($+4)
	PLO	R1
	SEP	R1
	LDI	0		; PUSH STATUS=0
	STR	R4
;
CONTINIT LDI	LOW CHANGE	; COPY CODE THAT CHANGES TO THE DESIRED PC
	PLO	R5		; FOR A $R COMMAND. THE CODE GOES TO 35 BYTES
	GHI	R1		; BEFORE "SAVEREG" MEMORY
	ADI	3
	PHI	R5
	LDI	0A0H
	PLO	R4
	LDI	24
	PLO	R3
INITLOOP LDA	R5		; LOOP AND MOVE THE BYTES
	STR	R4
	INC	R4
	DEC	R3		; R4 WILL END UP POINTING TO XXB8
	GLO	R3
	BNZ	INITLOOP
	GHI	R4		; INITIALIZE R2 (STACK POINTER)
	PHI	R2
	LDI	0C3H		; CORRECT STORED VALUE OF R1
	PLO	R4
	LDI	LOW INTERUPT
	STXD
	GHI	R1
	STXD
	GHI	R1		; LOAD R5 WITH ADDRESS OF "ENTRY"
	ADI	1
	PHI	R5
	LDI	LOW ENTRY
	PLO	R5
	LDI	0FEH		; POINT R3 TO TIMALC
	PLO	R3
	GHI	R1
	PHI	R3		; CALL TIMALC; IT RETURNS WITH "SEP R5",
	SEP	R3		; SO IT WILL RETURN TO "ENTRY"
;
; INTERUPT:  INTERRUPT HANDLER FOR IDIOT MONITOR. HARDWARE INTERRUPT
;	SAVES ALL REGISTERS EXCEPT T CORRECTLY. A SOFTWARE INTERRUPT
;	(D1=SEP R1) SAVES ALL BUT P AND X CORRECTLY. R2 MUST POINT TO
;	A STACK WITH AT LEAST 4 FREE BYTES TO SAVE D AND R4 CORRECTLY.
;
INTERUPT SEX	R2		; ENTRY: OLD P AND X DESTROYED
	DEC	R2		; DEC. STACK POINTER TO FREE LOCATION
	STXD			; PUSH D
	GHI	R4		; PUSH R4
	STXD
	GLO	R4
	STR	R2
	SEX	R4		; SET X=R4 AND GO TO SAVE REGISTERS
	BR	FINDRAM
IFINT	LDI	010H		; RETURN HERE:
	STXD			; PUSH STATUS=10
	LDI	0C9H		; CORRECT STORED CONTENTS OF R4
	PLO	R4
	LDA	R2
	STXD
	LDA	R2
	STXD
	LDI	0BBH		; CORRECT STORED CONTENTS OF D
	PLO	R4
	LDA	R2
	STR	R4
	LDI	0C5H		; CORRECT STORED VALUE OF STACK POINTER
	PLO	R4		; TO ACTUAL VALUE AT TIME OF INTERRUPT
	GLO	R2
	STXD
	GHI	R2
	STXD
	BR	CONTINIT	; GO CONTINUE INITIALIZATION
;
NORAM	GHI	R0		; NO RAM: CAN'T SAVE REGISTERS
	ADI	1
	PHI	R3
	LDI	LOW ENTRY	; CHANGE PROGRAM COUNTER TO R3
	PLO	R3
	SEX	R2		; STACK POINTER TO R2
	SEP	R3		; GO TO IDIOT/2
;
; DELAY SUBROUTINE: USED BY THE READ AND TYPE ROUTINES TO GENERATE A
;	TIME DELAY PROPORTIONAL TO THE BAUD RATE. THE LENGTH OF THE DELAY
;	(IN MACHINE CYCLES) IS SPECIFIED BY:
;
;		DELAY = 4 + 4(BAUD)(#BITS + 3)
;
;	WHERE "#BITS" IS AN IN-LINE BYTE FROM THE CALLING PROGRAM
;	AND "BAUD" IS THE BAUD RATE TIMING CONSTANT FROM THE UPPER 7 BITS
;	OF RE.1 (BAUD.1). "DELAY" USES RC AS ITS DEDICATED PROGRAM COUNTER,
;	AND RETURNS VIA A "SEP R3" WITH DF=1, D=0, AND RE.0=0.
;
	ORG	RESET+00EEH	;HRJ offset
	SEP	R3		; RETURN TO CALLER
DELAY1	GHI	BAUD		; GET BAUD CONSTANT
	SHR			; REMOVE ECHO FLAG
	PLO	BAUD		; REPEAT...
	DEC	BAUD		; - DECREMENT BAUD
	LDA	R3		; - GET #BITS,
	SMI	1		;   DECREMENT UNTIL ZERO
	BNZ	$-2
	GLO	BAUD		; ...UNTIL BAUD=0
	BZ	$-11		; GO TO RETURN
	DEC	R3
	BR	$-10
;
; TIMALC:  CALCULATES THE BAUD RATE AND SETS THE ECHO FLAG BASED ON THE
;	1ST CHARACTER RECEIVED:  CARRIAGE RETURN SELECTS FULL DUPLEX (ALL
;	INPUTS ECHOED); LINE FEED SELECTS HALF DUPLEX (NO ECHO). "TIMALC"
;	SETS UP RC AS PC FOR THE "DELAY" ROUTINE AND LOADS A CONSTANT
;	PROPORTIONAL TO THE BAUD RATE IN THE UPPER 7 BITS OF "BAUD" (RE.1),
;	WITH THE LEAST SIGNIFICANT BIT=0 FOR ECHO, OR =1 FOR NO ECHO.
;
	ORG	RESET+ 00FEH	;HRJ ofset
TIMALC	GHI	R3		; POINT RC TO "DELAY"
	PHI	DELAY
	LDI	LOW DELAY1
	PLO	DELAY
	LDI	0		; LET BAUD=0
	PLO	BAUD
	PLO	ASCII		; LET ASCII=0
 IF EFHI
	B4	$		; HRJ M/S card, WAIT FOR START BIT ON EF3
	BN4	$		;               WAIT FOR 1ST NON-0 DATA BIT
 ELSE
	BN4	$		;wait for start active low	
	B4	$		; wait for non-1 data bit
 ENDIF
	LDI	3		; WAIT 14 MACHINE CYCLES
TC	SMI	1
	BNZ	$-2
	GLO	ASCII
 IF EFHI
	BNZ	ZTO1		; MEASURE LENGTH OF 1ST ZERO BIT AFTER START
	B4	INCR		; HRJ M/S card
	INC	ASCII
ZTO1	B4	DAUX		;HRJ M/S card
 ELSE
	BNZ	ZTO1		; MEASURE LENGTH OF 1ST ZERO BIT AFTER START
	BN4	INCR		; BIT (SAME FOR BOTH <CR> AND <LF>)
	INC	ASCII
ZTO1	BN4	DAUX		;HRJ M/S card
 ENDIF
INCR	INC	BAUD
	LDI	7
	BR	TC
DAUX	DEC	BAUD		; BAUD = #LOOPS IN 2 BIT TIMES
	DEC	BAUD
	GLO	BAUD
	ORI	1
	PHI	BAUD
	SEP	DELAY		; WAIT 1.5 BIT TIMES
	DB	00CH
 IF EFHI
	BN4	WAIT		; IF BIT=1, IS LF
 ELSE
	B4	WAIT
 ENDIF
	GHI	BAUD		;    THEN SET LSB BAUD=1
	ANI	0FEH
	PHI	BAUD		;    ELSE LSB BAUD=0,
WAIT	SEP	DELAY		;	  WAIT FOR END OF CHARACTER
	DB	026H
	SEP	R5		; RETURN
;
; READ: READS A SERIAL CHARACTER VIA EF4 AND RETURNS WITH ITS ASCII CODE IN
;	ASCII.1 AND D (BUT D WILL BE LOST IF SCRT CALL & RETURN IS USED).
;	EXPECTS P=3; ALTERS DF, ASCII, & BAUD.0; AND RETURNS WITH SEP R5. 
;
; TTYRED:  SAME AS "READ", BUT FIRST DOES AN "OUT 7" X'80' TO TURN ON 
;	A SERIAL INPUT DEVICE SUCH AS A TAPE RECORDER. ONCE A CHARACTER HAS
;	STARTED, AN "OUT 7" X'40' IS USED TO TURN IT OFF AGAIN.
;
; READAH:  SAME AS "READ", BUT IF A HEX CHARACTER (0-9, A-F), IT IS ALSO 
;	SHIFTED INTO THE LOW 4 BITS OF "HEXX" & DF=1 IS RETURNED; IF NOT
;	HEX, RETURNS DF=0, "READAH" USES P=R3, ALTERS D, DF, RF, RE.0, &
;	RETURNS WITH A "SEP R5" AND R3 POINTING TO "READAH" ENTRY POINT.
;
; NOTE:  THE READ ROUTINES EXIT AT THE BEGINNING OF THE ECHOED STOP BIT,
;	& SET BAUD.0 (RE.0) >0 AS A DELAY FLAG FOR THE "TYPE" ROUTINES. THE
;	"TYPE" ROUTINES CHECK THIS FLAG BEFORE TYPING THE NEXT BYTE, & IF
;	SET, WILL FIRST SEND 2 STOP BITS. TAKE CARE NOT TO RESET THIS FLAG 
;	(BY USING THE DELAY ROUTINE OR RE.0) UNTIL ENOUGH TIME HAS PASSED
;	SO NO FURTHER DELAY IS NEEDED.
;
	ORG	RESET+ 012FH ;HRJ offset
CKDEC	ADI	7		; IF CHARACTER IS 0-9 OR A-F,
	BDF	NFND
	ADI	00AH		;    THEN SHIFT IT IN
	BDF	FND		;    ELSE IS NON-HEX,
NFND	ADI	0		;	SET DF=0
REXIT	GHI	ASCII		; PUT CHARACTER IN D
	SEP	R5		; RETURN WITH ENTRY FLAG SET:
READAH	LDI	080H		;   =80 IF VIA READAH
	SKP
READ	GLO	R3		;   =3F IF VIA READ
	LSKP
TTYRED	LDI	0		;   =00 IF VIA TTYRED
	PLO	ASCII		; SAVE ENTRY FLAG
READ2	LDI	080H		; SET #BITS IN CHARACTER=7
	PHI	ASCII		; (TAKES 7 SHIFTS TO CHANGE '80' INTO '01')
	SEX	R3
	GLO	ASCII		; GET ENTRY FLAG
	LSNZ			; IF TTYRED,
	OUT	7		;    TURN READER ON
	DB	080H
 IF EFHI
	BN4	$		; WAIT IF A STOP BIT
TTY1	B4	$		; FIND A START BIT:
	SEP	DELAY		; - DELAY 1/2 BIT TIME, TEST AGAIN
	DB	2
	B4	TTY1		; - REPEAT IF GONE
 ELSE
	B4	$		; WAIT IF A STOP BIT
TTY1	BN4	$		; FIND A START BIT:
	SEP	DELAY		; - DELAY 1/2 BIT TIME, TEST AGAIN
	DB	2
	BN4	TTY1		; - REPEAT IF GONE
 ENDIF
	GLO	ASCII
	LSNZ			; - IF TTYRED, TURN READER OFF
	OUT	7
	DB	040H
;
; BEGIN SERIAL INPUT (DELAY+44 MC./LOOP)
;
NOBIT	SEX	R2		; EQUALIZE DELAYS
	SEX	R2
BIT	GHI	BAUD
	SHR
	BDF	NOECHO		; IF ECHO=YES,
 IF EFHI
	B4	OUTBIT		; HRJ M/S card
 ELSE
	BN4	OUTBIT
 ENDIF
 IF QHI
	SEQ			;    SET Q IF BIT=1
	LSKP			;    RESET Q IF BIT=0
OUTBIT	REQ
 ELSE
	REQ			;    RESET Q IF BIT=1
	LSKP			;    SET Q IF BIT=0
OUTBIT	SEQ
 ENDIF
NOECHO	NOP			; EQUALIZE DELAYS
	LSNF
	SEX	R2
	SEX	R2
	SEX	R2
	NOP
	NOP
	SEP	RC		; WAIT 1 BIT TIME
	DB	7
	INC	BAUD		; SET DELAY FLAG =1
	GHI	ASCII		; SHIFT ASCII CHARACTER 1 BIT
	SHR
	PHI	ASCII
	BDF	STOP		; IF MORE BITS TO GO,
	ORI	080H		;    THEN MASK CURRENT BIT INTO CHARACTER
 IF EFHI
	BN4	NOBIT		; HRJ M/S card
 ELSE
	B4	NOBIT
 ENDIF
	PHI	ASCII		;	CONTINUE LOOP
	BR	BIT
 IF QHI
STOP	REQ			;    ELSE SET STOP BIT
 ELSE
STOP	SEQ			;    ELSE (RE)SET STOP BIT
 ENDIF
	BZ	READ2		; REPEAT IF 00=NULL
	GLO	ASCII		; IF READ OR TTYRED,
	SHL			;    THEN GO TO EXIT
	BNF	REXIT		;    ELSE IS READAH:
	GHI	ASCII		; IF CHARACTER < "A",
	SMI	041H		;    THEN GO CHECK FOR A NUMBER (0-9)
	BNF	CKDEC
	SMI	006H		;    ELSE CHECK FOR LETTERS A-F
	BDF	NFND
FND	SHL			; CHARACTER IS HEX:
	SHL
	SHL			;   SHIFT IT INTO THE LOWEST 4 BITS OF HEXX,
	SHL			;   1 BIT AT A TIME
	ADI	8
	SHL
FND1	PLO	BAUD		; REPEAT FOUR TIMES...
	GLO	HEXX		; - SHIFT BIT INTO HEXX.0
	SHLC
	PLO	HEXX
	GHI	HEXX		; - SHIFT CARRY BIT INTO HEXX.1
	SHLC
	PHI	HEXX
	GLO	BAUD		; - GET NEXT BIT
	SHL			; ...UNTIL DONE
	BNZ	FND1
	BR	REXIT		; EXIT WITH DELAY FLAG SET
;
; TYPE5: TYPES THE BYTE AT THE MEMORY LOCATION POINTED TO BY R5, & THEN
;	INCREMENTS R5. IF DELAY FLAG IS SET (BAUD.0>1), "TYPE5" 1ST WAITS
;	2 BIT-TIMES SO ANY PREVIOUS READ OPERATIONS END, TYPES THE BYTE,
;	AND THEN RESETS THE DELAY FLAG=0 SO FURTHER TYPES ARE NOT DELAYED.
;
; TYPE6: SAME, BUT USES & INCREMENTS R6.
;
; TYPE:  SAME, BUT TYPES ASCII.1 (RF.1) 
;
; TYPE5D: SAME AS "TYPE5", BUT ALWAYS WAITS 2 BIT-TIMES.
;
; TYPE2:  SAME AS "TYPE5", BUT TYPES THE CONTENTS OF ASCII.1 (RF.1)
;	AS TWO HEX DIGITS (0-9, A-F).
;
;	ALL TYPE ROUTINES USE P=R3, EXIT VIA "SEP R5", & CAN USE THE SCRT 
;	CALL & RETURN.	THE SERIAL OUTPUT USES "Q",WITH 1 START, 8 DATA, & 
;	2 STOP BITS. LINE FEEDS <LF> ARE FOLLOWED BY 3 NULLS (=0) IN CASE 
;	THE TERMINAL NEEDS TIME FOR THE <CR><LF> SEQUENCE.  Q=0 IS "MARK"
;	OR STOP BIT; Q=1 IS A "SPACE" OR START BIT.  THE DELAY ROUTINE
;	DETERMINES THE BAUD RATE.  ALL "TYPE" ROUTINES ALTER D,DF,X,RD.0,
;	RE.0, RF.0, & EXIT WITH R3 AT "TYPE5". 
;
;   BAUD.0 = DELAY FLAG: =0 NO DELAY
;			 >0 DELAY 2 BITS
;  ASCII.0 = (LO 4 BITS) #BITS/CHARACTER
;	   = (HI 4 BITS) 0= BYTE OUTPUT 
;			 1= 1ST HEX OUT 
;			 2= LAST HEX OUT
;			 5= <LF> OUTPUT 
	ORG	RESET+019CH		;HRJ reset
TYPE5D	GHI	BAUD		; IF TYPE5D,
	PLO	BAUD		;    THEN SET DELAY FLAG TRUE (>0)
	SKP
TYPEXIT SEP	R5
TYPE5	LDA	R5		; IF TYPE5, GET BYTE VIA R5, THEN INC. R5
	SKP
TYPE6	LDA	R6		; IF TYPE6, GET BYTE VIA R6, THEN INC. R6
	SKP
TYPE	GHI	ASCII		; IF TYPE, GET BYTE IN ASCII.1
	PLO	RD
;
; DETERMINE CODE BYTE
;
	XRI	00AH		; IF LINE FEED,
	BNZ	TY2		;    THEN SET CODE=<LF>, 11 BITS
	LDI	05BH
	BR	TY3
TYPE2	GHI	ASCII		;	IF TYPE2,
	SHR			;	   THEN GET ASCII.1
	SHR			;		EXTRACT UPPER 4 BITS
	SHR
	SHR
	ADI	0F6H		;		CONVERT TO HEX:
	LSNF			;		IF "A" OR MORE, ADD 37
	ADI	7
	SMI	0C6H		;		   ELSE ADD 30
	PLO	RD
	LDI	01BH		;		CODE=HEX, 11 BITS
	LSKP
TY2	LDI	00BH		;   ELSE SET CODE=BYTE, 11 BITS
TY3	PLO	ASCII		;	SAVE CODE BYTE
;
; BEGIN SERIAL OUTPUT (DELAY + 44 MACHINE CYCLES PER LOOP)
;
BEGIN	GLO	BAUD		; IF DELAY FLAG > 0,
	LSZ			;    WAIT 2 BIT-TIMES IN CASE
	SEP	DELAY		;    PREVIOUS READ NOT DONE
	DB	23
 IF QHI
	SEQ			; BEGIN START BIT
 ELSE
	REQ
 ENDIF
NEXTBIT SEP	RC		; REPEAT...
	DB	7		; - WAIT 1 BIT-TIME
	NOP			;   (RETURNS WITH D=0)
	NOP
	NOP
	NOP
	NOP
	NOP
	DEC	ASCII		; - DECREMENT #BITS
	SD			; - SET DF=1
	GLO	RD		; - GET NEXT BIT OF CHARACTER
	SHRC
	PLO	RD
	LSDF			; - IF BIT=0,
 IF QHI
	SEQ			;      SET Q=1="SPACE"
	LSKP
	REQ			; - IF BIT=1,
	NOP			;      SET Q=0="MARK"
 ELSE
	REQ			;      RESET Q=0="SPACE"
	LSKP
	SEQ			; - IF BIT=1,
	NOP			;      RESET Q=1="MARK"
 ENDIF

	GLO	ASCII		; ...UNTIL #BITS=0
	ANI	00FH
	BNZ	NEXTBIT
NXCHAR	GLO	ASCII		; GET CODE BYTE;
	ADI	0FBH		; DECREMENT CODE,
	PLO	ASCII		; SET #BITS=11
	BNF	TYPEXIT 	; IF NO MORE, EXIT!
;
; TEST CODE BYTE TO SEE WHAT TO DO NEXT
;
	SMI	01BH		; IF CODE=1,
	BZ	TYPEXIT 	;    THEN WAS LAST NULL: EXIT
	LDI	0		; IF CODE>1,
	BDF	HX22		;    THEN GET NULL & GO TYPE IT
;				; IF CODE=0,
HEX2	GHI	ASCII		;    GET BYTE
	ANI	00FH		;    MASK LOWER 4
	ADI	0F6H		;    CONVERT TO HEX
	LSNF			;    IF "A" OR MORE,
	ADI	7		;	THEN ADD 37
	SMI	0C6H		;	ELSE ADD 30
HX22	PLO	RD		;    LOAD BYTE
	BR	BEGIN		;    BEGIN TYPING IT
;
; "IDIOT" MONITOR:  UTILITY PROGRAM TO EXAMINE & CHANGE REGISTERS OR MEMORY,
;	AND EXECUTE PROGRAMS WITH BREAKPOINTS. AN ASTERISK (*) INDICATES
;	"IDIOT" IS READY FOR A COMMAND. ALL COMMANDS CONSIST OF PUNCTUATION
;	(?!$) FOLLOWED BY A LETTER (M,P,R). ALL OTHER INPUTS ARE IGNORED.
;	NUMBERS ARE HEXADECIMAL, AND LEADING ZEROS ARE UNNECESSARY. SPACES,
;	LINE FEEDS, & CARRIAGE RETURNS CAN BE USED BETWEEN NUMBERS FOR
;	READABILITY. THE COMMANDS ARE:
;
;  !M - CHANGE MEMORY
;	  EXAMPLE:  !MA00 11 22 33 <CR>
;	WRITES HEX BYTES (11,22,33) INTO MEMORY, STARTING AT THE SPECIFIED
;	ADDRESS (0A00).
;
;  ?M - EXAMINE MEMORY
;	  EXAMPLE:  ?MA00 3 <CR>
;	    TYPES:  0A00 1122 33 <CR>
;	TYPE THE SPECIFIED ADDRESS (0A00) AND THE CONTENTS OF THE SPECIFIED
;	NUMBER OF BYTES OF MEMORY (3). LONG LISTINGS CAN BE ABORTED BY
;	TYPING A "BREAK".
;
;     - MOVE MEMORY
;	  EXAMPLE:  ?MA00 3 !M800 <CR>
;	MOVES A SPECIFIED NUMBER OF BYTES IN MEMORY (3) FROM ONE ADDRESS
;	(0A00) TO ANOTHER (0800).  THE BLOCKS CAN OVERLAP WITHOUT ERROR.
;
;  ?R - EXAMINE CPU REGISTERS
;	  EXAMPLE:  ?R <CR>
;	    TYPES:  10B8 ID T  DF D  IE Q  EF1234
;		    10C0 R0 R1 R2 R3 R4 R5 R6 R7
;		    10D0 R8 R9 RA RB RC RD RE RF
;	TYPES CONTENTS OF CPU REGISTERS SAVED AFTER THE LAST INTERRUPT,
;	BREAKPOINT, OR RESET. "10B8" ETC. IS THE ADDRESS IN RAM WHERE THIS 
;	DATA IS STORED. REGISTER CONTENTS CAN BE CHANGED WITH A !M COMMAND,
;	AND RESTORED WITH A $R COMMAND.
;
;  $P - RUN PROGRAM
;	  EXAMPLE:  $PA00 <CR>
;	BEGINS PROGRAM EXECUTION AT THE ADDRESS SPECIFIED (0A00) WITH
;	P=X=R0 AND INTERRUPTS ENABLED.
;
;  $R - RUN REGISTERS
;	  EXAMPLE:  $R23 <CR>
;	BEGINS PROGRAM EXECUTION WITH THE CPU REGISTERS SET TO THE CONTENTS
;	OF RAM LOCATIONS 10BA-10EF, AND X & P SET TO THE SPECIFIED VALUES
;	(X=2, P=3).
;
ENTRY	GHI	R5		; SET A POINTER TO TYPE5D
	PHI	R3
	LDI	LOW TYPE5D
	PLO	R3		; TYPE "SIGNON" MESSAGE:
	DB	TYPA,13 	; <CR>
	DB	TYPA,10 	; <LF>
	DB	TYPA,'I'	; <I>
	DB	TYPA,'D'	; <D>
	DB	TYPA,'I'	; <I>
	DB	TYPA,'O'	; <O>
	DB	TYPA,'T'	; <T>
	DB	TYPA,'-'	; <->
	DB	TYPA,'1'	; <1>
RESTART GHI	R5
	SMI	1
	PHI	R3
	LDI	LOW TYPE5D
	PLO	R3		; TYPE "PROMPT" MESSAGE:
	DB	TYPA,13 	; <CR>
	DB	TYPA,10 	; <LF>
	DB	TYPA,'*'	; <*>
IGNORE	LDI	0
	PHI	HEXX		; SET HEXX=0
	PLO	HEXX
	LDI	LOW READAH	; REPEAT...
	PLO	R3
	SEP	R3		; - GET A KEY
	XRI	'$'		; - IF "$",
	BZ	DOLLAR		;	GO TO DOLLAR
	XRI	005H		; - IF "!",
	PLO	R8		;	SET SWITCH=0
	LSZ			; - IF "?",
	XRI	01EH		;	LEAVE SWITCH>0
	BNZ	IGNORE		; ...UNTIL ONE FOUND
;
; GET ADDRESS FOR ?M, !M, OR ?R COMMAND 
;
	SEP	R3		; GET NEXT KEY
	XRI	'R'		; IF "R",
	BNZ	RDARGS
	LDI	0B8H		;    SET ADDRESS TO SAVED REGISTERS
	PLO	RA
	GHI	R2
	PHI	RA
	LDI	40		;    SET #BYTES=40
	PLO	HEXX
	SEP	R3		;    GET NEXT KEY
	BR	RD3		;    GO TYPE IT
RDARGS	XRI	01FH		; IF "M",
	BNZ	IGNORE
RD1	SEP	R3		;    IGNORE LEADING NON-HEX CHARACTERS
	BNF	$-1
	SEP	R3		;    ASSEMBLE HEX CHAR.INTO ADDRESS
	BDF	$-1
	XRI	020H		;    IF NEXT KEY NOT "SPACE",
	BNZ	SYNERR		;	GO TO SYNTAX ERROR
	GHI	HEXX
	PHI	RA		;    LET ADDRESS POINTER=HEXX
	GLO	HEXX
	PLO	RA		; IF SWITCH=0,
	GLO	R8		;    IS "!M" COMMAND;
	BZ	EX1		;    GO TO EX1
;
; ?M COMMAND:  GET #BYTES TO TYPE
;
	LDI	0		; SET HEXX=0
	PLO	HEXX
	PHI	HEXX
RD2	SEP	R3		; GET KEYS & ASSEMBLE INTO HEX
	BDF	$-1
;
; DETERMINE IF TYPE OR MOVE COMMAND
;
RD3	GLO	HEXX		; SET #BYTES=HEXX
	PLO	R8
	GHI	HEXX
	PHI	R8
	GHI	ASCII		; GET LAST KEY
RD5	XRI	'!'		; IF "!",
	BZ	BRMOVE		;    GO TO MOVE DATA
	XRI	001H		; IF "SPACE",
	BNZ	$+5		;    IGNORE IT,
	SEP	R3		;    GET ANOTHER KEY
	BR	RD5		;    REPEAT
	XRI	02DH		; IF <CR>, GO TO TYPE
	BNZ	SYNERR		;    ELSE SYNTAX ERROR
;
; TYPE SPECIFIED DATA
;
RD4	LDI	LOW TYPE5D
	PLO	R3
NXLINE	SEP	R3		; TYPE <LF>
	DB	00AH
 IF EFHI
	BN4	SYNERR		; IF "BREAK", GO TO SYNTAX ERROR
 ELSE
	B4	SYNERR
 ENDIF
LINE1	GHI	RA		; TYPE ADDRESS OF POINTER:
	PHI	ASCII
	LDI	LOW TYPE2
	PLO	R3
	SEP	R3		; UPPER BYTE
	GLO	RA
	PHI	ASCII
	LDI	LOW TYPE2
	PLO	R3
	SEP	R3		; LOWER BYTE
	SEP	R3		; TYPE A "SPACE"
	DB	' '
TLOOP	LDA	RA		; GET BYTE @ POINTER, & ADVANCE POINTER
	PHI	ASCII
	LDI	LOW TYPE2	; TYPE BYTE
	PLO	R3
	SEP	R3
	DEC	R8		; DECREMENT #BYTES
	GLO	R8
	BNZ	TL3		; IF #BYTES=0,
	GHI	R8		;    GO TO RESTART
	BZ	RESTART
TL3	GLO	RA		; IF LINE IS FULL (I.E. ADDRESS ENDS IN XXX0),
	ANI	00FH
	BNZ	TL2
	SEP	R3		;    TYPE <;>
	DB	';'
	SEP	R3		;    TYPE <CR>
	DB	00DH
	BR	NXLINE		;    GO TO NEXT LINE
TL2	SHR			; IF ODD ADDRESS,
	BDF	TLOOP		;    THEN TYPE NEXT BYTE
	BR	TLOOP-2 	;    ELSE GO TYPE A "SPACE" FIRST
;
; !M COMMAND:  WRITES BYTES INTO MEMORY
;
EX3	SEP	R3		; GET KEYS UNTIL HEX
	BNF	$-1
EX2	SEP	R3		; GET 2ND HEX KEY
	BNF	SYNERR		; IF NOT HEX, SYNTAX ERROR
	GLO	HEXX		; STORE BYTE AT ADDRESS,
	STR	RA		; INCREMENT ADDRESS
	INC	RA
EX1	SEP	R3		; GET NEXT KEY
	BDF	EX2		; IF HEX, ASSEMBLE INTO ADDRESS AND REPEAT
	XRI	00DH		; IF <CR>,
	BZ	RESTART 	;    DONE: GO TO RESTART
EX4	XRI	021H		; IF <,>,
	BZ	EX3		;    CONTINUE ON NEW LINE
	XRI	017H		; IF <;>, CONTINUE
	BNZ	EX1		;    ELSE IGNORE KEY & REPEAT
	SEP	R3		; IF <:>,
	XRI	00DH		;    IGNORE FURTHER KEYS UNTIL <CR>
	BNZ	$-3
	BR	RD1		; THEN CONTINUE ON NEW LINE WITH A NEW ADDRESS
;
; SYNTAX ERROR
;
SYNERR	LDI	LOW TYPE5D	; POINT TO TYPE5D
	PLO	R3
	SEP	R3		; TYPE <CR>
	DB	00DH
	SEP	R3		; <LF>
	DB	00AH
	SEP	R3		; <?>
	DB	'?'
	BR	RESTART 	; AND RESTART
;
; $P AND $R COMMANDS
;
DOLLAR	SEP	R3		; GET KEY
	XRI	'R'		; IF "R",
	PLO	R8		;    SET SWITCH=0
	LSZ			; IF "P",
	XRI	002H		;    LEAVE SWITCH>0
	BNZ	IGNORE		; IGNORE ALL ELSE
;
; GET NUMBER FOR $R OR $P COMMAND
;
D1	SEP	R3		; GET NEXT KEY
	BDF	$-1		; IF HEX, ASSEMBLE ADDRESS & REPEAT
	XRI	00DH		; IF NOT <CR>,
	BNZ	SYNERR		;    GO TO SYNTAX ERROR
	GHI	HEXX		; PUT NUMBER IN R0
	PHI	R0
	GLO	HEXX
	PLO	R0
	LDI	LOW TYPE5D	; TYPE <LF>
	PLO	R3
	SEP	R3
	DB	00AH
	GLO	R8		; IF SWITCH>0,
	BZ	RESTORE 	;    IS "$P" COMMAND; CONTINUE
;
; $P COMMAND:  BEGIN EXECUTION AT SPECIFIED ADDRESS WITH P=X=0, IE=1
;
	LDI	LOW INTERUPT	; SET R1 FOR BREAKPOINT INTERRUPT
	PLO	R1
	GHI	R5
	SMI	2
	PHI	R1
	SEX	R5		; EXECUTE AT ADDRESS IN R0!
	RET
	DB	0
	BR	RESET+02FFH		; BRANCH OVER PAGE JUMPS HRJ add offset
	ORG	RESET+02F4H		; PAGE JUMPS: ALLOW RELOCATABLE BRANCH TO PAGE 3
	BR	SYNERR
	NOP
	NOP
	BR	RESTART
BRMOVE	GHI	R5		; GO TO "MOVE" JUMP ON PAGE 3
	ADI	1
	PHI	R5
;
; $R COMMAND:  RESTORE ALL CPU REGISTERS (EXCEPT "T") TO THE VALUES SAVED
;	IN RAM, & EXECUTE WITH THE SPECIFIED VALUES OF X AND P.
;
;	NOTE: REGISTER NAMES IN PARENTHESES INDICATE THE VALUE IN RAM TO
;	BE RESTORED TO THAT REGISTER.
;
RESTORE GHI	R2		; R2=POINTER TO RAM WHERE INITIALIZATION
	PHI	R3		; PROGRAM WILL BE ASSEMBLED
	LDI	0B8H+7
	PLO	R2
	SEX	R2
	LDI	0B8H+9		; START ASSEMBLING LBR INSTRUCTION
	STR	R2
	GLO	R0		; ASSEMBLE LBR(R(P)) AS LAST OPCODE
	PLO	HEXX
	; PLO	HEXX		; incorrect duplicate HRJ jan 19 2014
	ANI	00FH		; - GET (P)
	SHL			; - SET POINTER TO (R(P))
	ADD
	PLO	R3
	LDN	R3		; - ASSEMBLE (R(P)) INTO INIT. PROGRAM
	STXD
	LDI	0A8H		; - CHANGE ORIGINAL (R(P)) TO POINT TO XX9E
	STR	R3		;   SO EXECUTION CAN CONTINUE WHEN (P)=>P
	DEC	R3
	LDN	R3
	STXD
	GHI	R2
	STR	R3
	LDX			; - RESTORE (Q) TO Q
	LSZ			;   IF (Q)=1,
	SEQ			;	THEN SET Q
	SKP			;	ELSE RESET Q
	REQ
	LDI	0C0H		; - FINISH TEMPLATE LBR INSTRUCTION
	STXD
;
; ASSEMBLE LDI OPCODE TO INITIALIZE (D)
;
	LDX			; GET (IE) & SAVE FOR LATER
	PHI	HEXX
	DEC	R2		; ASSMBLE LDI OPCODE TO INITIALIZE D
	LDXA
	STXD			; - ASSEMBLE (D)
	LDI	0F8H		; - ASSEMBLE LDI
	STXD
	LDX			; RESTORE (DF) TO DF
	SHR
	LDI	0A2H		; ASSEMBLE PLO R2 TO INITIALIZE R2.0
	STXD
	LDI	0B8H+13
	PLO	R3		; - ASSEMBLE (R2.0)
	LDN	R3
	STXD
	LDI	0F8H		; - ASSEMBLE LDI
	STXD
;
; NOW RESTORE ALL R'S EXCEPT R2 & R5
;
	LDI	0B8H+8		; SET R2 TO (R0)
	PLO	R2
	LDX			; (R0)=>R0
	PHI	R0
	GHI	HEXX		; GET (IE) & SAVE IN (R0.1)
	STR	R2
	INC	R2
	LDX
	PLO	R0
	GLO	HEXX		; GET (XP) & SAVE IN (R0.0)
	STR	R2
	INC	R2
	LDXA			; (R1)=>R1
	PHI	R1
	LDXA
	PLO	R1
	IRX			; SKIP (R2)
	IRX
	LDXA			; (R3)=>R3
	PHI	R3
	LDXA
	PLO	R3
	LDXA			; (R4)=>R4
	PHI	R4
	LDXA
	PLO	R4
	IRX			; SKIP (R5)
	IRX
	LDXA			; (R6)=>R6
	PHI	R6
	LDXA
	PLO	R6
	LDXA			; (R7)=>R7
	PHI	R7
	LDXA
	PLO	R7
	LDXA			; (R8)=>R8
	PHI	R8
	LDXA
	PLO	R8
	LDXA			; (R9)=>R9
	PHI	R9
	LDXA
	PLO	R9
	LDXA			; (RA)=>RA
	PHI	RA
	LDXA
	PLO	RA
	LDXA			; (RB)=>RB
	PHI	RB
	LDXA
	PLO	RB
	LDXA			; (RC)=>RC
	PHI	RC
	LDXA
	PLO	RC
	LDXA			; (RD)=>RD
	PHI	RD
	LDXA
	PLO	RD
	LDXA			; (RE)=>RE
	PHI	RE
	LDXA
	PLO	RE
	LDXA			; (RF)=>RF
	PHI	RF
	LDX
	PLO	RF
;
; CHANGE PROGRAM COUNTER TO DESIRED REGISTER
;
	BR	BRCHANGE	; THIS IS LOCATION FOR A RELOCATABLE
;				  "BR" TO PAGE WHERE THE PC IS LOCATED
;
; BLOCK MOVE COMMAND  (?MXXXX XX !MXXXX)
;
MOVE	SEP	R3		; GET NEXT KEY
	XRI	'M'		; IF "M",
	BNZ	$+7		;    THEN CLEAR HEXX
	PHI	HEXX		;    ELSE SYNTAX ERROR
	PLO	HEXX
	SEP	R3		; GET HEX ADDRESS OF DESTINATION
	BDF	$-1
	XRI	00DH		; IF NOT <CR>,
	BNZ	BRSYNERR	;    GO TO SYNTAX ERROR
;
; TEST IF MOVE UP/MOVE DOWN (TRICKY WITHOUT RAM)
;
	GHI	RA		; COPY SOURCE ADDRESS INTO R3
	PHI	R3
	GLO	RA
	PLO	R3
	GHI	HEXX		; COPY DESTINATION INTO RF
	PHI	RF
	GLO	HEXX
	PLO	RF
UPDOWN	GHI	R3		; - IF SOURCE=0,
	BNZ	$+3		;	SOURCE<DESTINATION; MOVE DATA UP
	GLO	R3
	BZ	MOVEUP
	DEC	R3		;	DECREMENT SOURCE
	GHI	RF		; - IF DESTINATON=0
	BNZ	$+3		;	SOURCE>DESTINATION; MOVE DATA DOWN
	GLO	RF
	LSKP			; SKIP TO CONTINUE
;-------------------------
; THE FOLLOWING LOCATION IS NEEDED FOR THE RELOCATABLE BRANCH TO THE
; PC CHANGE ROUTINE, WHICH HAS BEEN MOVED TO THE SAME PAGE AS REGISTER
; SAVE AREA.
;
BRCHANGE GHI	R2		; GO TO PAGE THAT PROGRAM IS ON
	PHI	R5
;-------------------------
;
	DEC	RF		; DECREMENT DESTINATION
	BNZ	UPDOWN		; DATA DOWN
;
; SOURCE > DESTINATION:  MOVE DATA DOWN
;
MOVEDN	GHI	R8		; REPEAT...
	BNZ	$+3		; ...UNTIL #BYTES=0
	GLO	R8
	BZ	BRRESTRT	; THEN RESTART
	LDA	RA		; - LOAD VIA SOURCE
	STR	HEXX		; - STORE VIA DESTINATION
	INC	HEXX		; - INCREMENT POINTERS
	DEC	R8		; - DECREMENT #BYTES
	BR	MOVEDN
;
; SOURCE <= DESTINATION:  MOVE DATA UP
;
MOVEUP	GHI	R8		; COPY #BYTES INTO R3
	PHI	R3
	GLO	R8
	PLO	R3
	LSKP			; SET POINTERS TO HIGH END OF DATA
UP	INC	RA		; REPEAT...
	INC	HEXX
	DEC	R3		; - INC. SOURCE
	GHI	R3		; - INC. DESTINATION
	BNZ	UP		; - DEC. #BYTES
	GLO	R3
	BNZ	UP		; ...UNTIL #BYTES=0
	SEX	HEXX		; REPEAT TO MOVE FROM TOP DOWN...
MUP	GHI	R8		; ...UNTIL #BYTES=0
	BNZ	$+3
	GLO	R8
	BZ	BRRESTRT	; THEN RESTART
	LDN	RA		; - LOAD VIA SOURCE
	STXD			; - STORE VIA DESTINATION
	DEC	RA		; - DECREMENT POINTERS
	DEC	R8
	BR	MUP
;
; THE FOLLOWING ROUTINE CHANGES THE PROGRAM COUNTER TO THE ONE DESIRED
; IN A $R COMMAND. IT IS COPIED INTO RAM.
;
CHANGE	LDI	0B8H+8		; SET POINTER TO SAVED (IE)
	PLO	R2
	LDXA			; GET (IE)
	LSZ			; IF (IE)=1,
	RET			;    THEN SET IE=1
	SKP			;	(P)=>P, (X)=>X
	DIS			;    ELSE SET IE=0
;
; NOW SET UP R5 (IF NOT PC), R2, & D
;
RHERE	INC	R5		; IF R5 IS NOT THE PROGRAM COUNTER,
	LSKP			; THIS WILL GIVE CORRECT "BR" ADDRESS
	BR	RESET+03B3H	; TO "R5PC" AFTER IT IS MOVED TO XXA0
	LDI	0B8H+18 	; - SET POINTER TO (R5)
	PLO	R2
	LDA	R2		; - (R5)=>R5
	PHI	R5
	LDN	R2
	PLO	R5
R5PC	LDI	0C4H		; - (R2.1)=>R2.1
	PLO	R2
	LDN	R2
	PHI	R2
;
; SAMPLE TEMPLATE PROGRAM CREATED IN RAM
;
;	ORG	RESET+0XXB8H	;HRJ offset
;	LDI	(R2.0)		; (R2.0)=>R2.0
;	PLO	R2
;	LDI	(D)		; (D)=>D
;	LBR	(R(P))		; GO TO USER PROGRAM
	ORG	RESET+03F0H		; PAGE JUMPS: ALLOWS RELOCATABLE LONG BRANCH
;				; TO PAGE 2.
;
BRSYNERR GHI	R5		; BR TO SYNEER
	SMI	1
	PHI	R5
BRRESTRT GHI	R5		; BR TO RESTART
	SMI	1
	PHI	R5
	ORG	RESET+03FEH
	BR	MOVE
;
	END
