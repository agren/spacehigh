; Space Invaders High Score Hack v0.01
; Copyright Mikael Ågren, 2011. Distributed under GPLv3
;
; This code adds a high score list to Space Invaders, the arcade 
; version, when inserted in the original game code.
; Use at your own risk - This haven't been tested on real SI
; hardware, only in an emulator.
;
; The time and effort put into this was greatly reduced by using
; the dissassembly comments by Chris Cantrell at
; http://computerarcheology.com
;
; Details
;	Compiles with as8085 (http://shop-pdp.kent.edu/ashtml/)
;
;	The high score hack adds a high score list of 8 entries 
;	which are displayed after a game over and before a demo play
; 	To limit the number of roms needed in tried to limit the
;	modifications to the h1000-17FF area. This has required some
;	peculiar solutions, but hey, it seems to work.
;	
;	The game over code is modified to check if score makes the
;	list. If so get the initials save everything, sort the 
;	list and display it.
;	To make a high score splash screen the ClearSmallSprite 
;	routine is modified. This routine will be called when 
;	initializing the game field. If we are in demo mode (and it's 
;	the first time during this demo the routine is called) we'll
;	display the high score list for a few seconds and then return
;	to the demo. To keep track of the first time the 
;	ClearSmallSprite routine is run a flag is modified when the 
;	demo game runs.
;	
;	
;
; Known bugs
; 	* In the case that credits are added when the high score 
;	list is displayed before a demo: When the high score list 
;	display is finished the demo will be skipped. This will cause 
;	PlrFireOrDemo to never be called to reset the 'display high 
;	score list' flag. The effect of this is that the high score 
;	list won't be shown before the next demo.
;
; Todo
;	* Make high score list interruptable when adding credits.
;	* Write a cleaner high score splash screenversion which
;	doesn't use the PlrFireOrDemo. As far as I can tell this
;	would require code to be put outside the 0h1000-0h17FF 
;	boundary.
;	* Clean up code
;
; New in
;	v 0.01
;		* Clear the high score list before adding the first
;		high score after a power cycle.

IM_CHEAP_OR_LAZY = 1	; 1=Fit patch within addresses 1000-17FF. Might cause some, probably minimal, game play slowdown.
			; 0=NOT IMPLEMENTED Use more than 1 rom. Should not affect game play.

XHDATA			.equ	0h2300
XHCODE			.equ	0h1000
XHSIZE			.equ	8	; Number of high score table entries
XHENTRYSIZE		.equ	5
XGOENTRY		.equ	0h1676	; Address to replace with a jp to our own game over routine
XGONEXT			.equ	0h1679	; Address to jump back to after our game over routine is finished
XHNVBASE		.equ	0h5800

PrintMessage		.equ	0h08F3
Print4Digits		.equ	0h09AD
ReadInputs		.equ	0h17C0
ClearPlayField		.equ	0h09D6
WaitOnDelay		.equ	0h0AD7
TwoSecDelay		.equ	0h0AB6
EnableGameTasks		.equ	0h19D1
DisableGameTasks	.equ	0h19D7
RestoreShields1		.equ	0h021A

demoCmdPtrLSB		.equ	0h20ED
isrSplashTask		.equ	0h20C1
gameMode		.equ	0h20EF
vblankStatus		.equ	0h2072
numCoins		.equ	0h20EB
HiScorL			.equ	0h20F4
HiScorM			.equ	0h20F5

	.area	CODE1	(ABS)

.if IM_CHEAP_OR_LAZY
	.org	0h14CE	; Modify the ClearSmallSprite
			; routine to display the high
			; score list before the demo
			; begins
	jmp xhsplash
	.org	0h1657	; Modify the PlrFireOrDemo
			; routine to reset the 
			; 'display high score list'
			; flag so that the list is
			; shown before the next demo
			; game
	jmp	xhflagforhs
.endif

	.org	XGOENTRY
	jmp mygameover

	.org	XHCODE
.if IM_CHEAP_OR_LAZY
	; ****************************************
	; ** Code inserted into ClearSmallSprite
	; ** displaying high score list
	; ****************************************
xhsplash:
	push 	H
	push	D
	sta	xhatmp		; Destroying A will mess things up in game play initialisation
	out 6
	lda	gameMode	; Are we in demo mode?
	ana	A
	jnz	xhsplashexit	; no, return
	;lxi	H, 0h20F5	; Has the machine just been turned on? 
	;mov	A, M		; The ram seems to contain random data after a power up so we're checking for a high score of 0.
	;dcx	H
	;ora	M
	;jnz	xhnotfirsttime	; This wasn't the first time. Don't clear the high score list.
	;call	ClearHighScoreList
;.if NONVOLATILE
;	inr	A
;	sta	xhinitdone	; Flag that we shouldn't load high score table again.
;	mvi	B, XHSIZE*XHENTRYSIZE
;	lxi	H, xhighrt+XHENTRYSIZE
;xhnextnvread:
;	lda	XHNVBASE
;	mov	M, A
;	inx	H
;	dcr	B
;	jnz	xhnextnvread
;.endif
;xhnotfirsttime:
	lda	xhndisplist	; Is this the first time since the previous game demo?
	ana	A
	jnz	xhsplashexit	; no, pretend we were never here
	lda	isrSplashTask	; Are we in demo game mode?
	cpi	0h01
	jnz	xhsplashexit	; no, return
	call	DisableGameTasks
	call	PrintHighScoreList
	call	TwoSecDelay
	out	0h06
	call	TwoSecDelay
	out	0h06
	call	TwoSecDelay
	mvi	A, 1
	sta	xhndisplist	; Don't display high score list next time
	call	ClearPlayField
	call	RestoreShields1
	call	EnableGameTasks
xhsplashexit:
	lda	xhatmp		; Restore A
	pop	D
	pop	H
	lxi	B, 0h0020
	jmp	0h14D1

	; ***************************************
	; ** Code inserted into Turn on display high score list flag
	; **
	; ***************************************
xhflagforhs:
	xra	A
	sta	xhndisplist
	lhld	demoCmdPtrLSB
	jmp	0h165A
	
.endif

	; *********************************
	; ** Clear high score list
	; **
	; *********************************
ClearHighScoreList:
	lxi	H, xhighrt+XHENTRYSIZE
	;mvi	A, 1	; testing 0101 BBB
	xra	A
	mvi	B, XHSIZE*XHENTRYSIZE
clearnext:
	mov	M, A
	inx	H
	dcr	B
	jnz	clearnext
	ret

	; *********************************
	; ** Print high score list routine
	; **
	; *********************************
PrintHighScoreList:
	mvi	A, XHSIZE
	sta	xhscount
	mvi	L, 0h0C		; Start line
	lxi	B, xhighrt+5
pnexths:
	mvi	H, 0h2D
	ldax	B
	mov	E, A
	inx	B
	ldax	B
	mov	D, A
	inx	B
	push	B
	call	Print4Digits
	pop	B
	inr	H
	inr	H
	
	push	B
	mov	E, C
	mov	D, B
	mvi	C, 3

	call	PrintMessage
	pop	B
	inx	B
	inx	B
	inx	B

	inr	L		; Up one line


	lda	xhscount
	dcr	A
	sta	xhscount
	jnz	pnexths

	inr	L
	mov	A, H
	sbi	10
	mov	H, A
	lxi	D, xhmsghighscore
	mvi	C, 11
	call	PrintMessage

	ret

;	.org XGOCODE
	; **************************************
	; ** Replacement game over function
	; **
	; **************************************
mygameover:	
	lxi	H, HiScorM	; Has the machine just been turned on? 
	mov	A, M		; The ram seems to contain random data after a power up so we're checking if high score is 0.
	dcx	H
	ora	M
	jnz	dontclearhslist	; This wasn't the first time. Don't clear the high score list.
	call	ClearHighScoreList
dontclearhslist:
	call	0h09CA			; Get current score address,
	mov	A, M
	sta	xhighrt			; save score to the hidden entry in the high score table
	inx	H
	mov	A, M
	sta	xhighrt+1		; save score to the hidden entry in the high score table
	dcx	H
	lxi	D, xhighrt+5		; and then test it against
	call	checkscore		; lowest high score
	JNC     xgoreturn		; Player score is lower than lowest high ... nothing to do
	jz	xgoreturn		; Player score is equal than lowest high ... nothing to do

	; *******************************************
	; ** Get and save initials at "hidden" entry
	; **
	; *******************************************
	call	ClearPlayField
	lxi	H, 0h2A12
	lxi	D, xhmsgenter
	mvi	C, 14
	call	PrintMessage		; Display "ENTER INITIALS" message
	mvi	A, 3
	sta	xhsinitcount		; 3 initials
	lxi	D, xhighrt+2		; Where to save initials
	lxi	H, 0h2F0F		; Screen coordinates for initials
xhgetinitial:
	out	0h06
	mvi	A, 5			; Wait ~1/12 s
	call	WaitOnDelay
	call	ReadInputs
	rlc
	rlc
	jnc	xhnotright		; Right button haven't been pressed
	ldax	D			; Right button is pressed
	inr	A			; increase character at hidden entry in high score table
	cpi	26
	jnz	.+3+2
	mvi	A, 0			; Roll over alphabet
	stax	D			
xhnotright:
	rlc
	jnc	xhnotleft		; Right button haven't been pressed
	ldax	D			; Right button is pressed
	dcr	A			; increase character at hidden entry in high score table
	jp	.+3+2			; 
	mvi	A, 25			; Roll over alphabet
	stax	D			
xhnotleft:
	mvi	C, 1
	call	PrintMessage		; Display current initial, this changes H and DE
	dcr	H			; Move print coord back
	dcx	D			; Restore pointer to initial in hs table 
	call	ReadInputs
	ani	0h10
	jz	xhgetinitial		; If fire isn't pressed go back, redraw and check for other buttons
	call	ReadInputs		; Fire was pressed, wait until it's not
	ani	0h10
	out	0h06			; Watchdog
	jnz	.-7			; 
	lda	xhsinitcount
	dcr	a
	sta	xhsinitcount		; Count down initials
	jz	xhinitialsready		; All initials collected
	inr	H			; Increase print coord
	inx	D			; Increase hs table pointer to next initial
	jmp	xhgetinitial		; Get next initial
xhinitialsready:

	; *******************************************
	; ** Sort high score list
	; **
	; *******************************************
	lxi	H, xhighrt		; Point to "hidden" high score entry
	lxi	D, xhighrt+5		; Point to lowest high score entry
	mvi	A, XHSIZE
	sta	xhswaplcount
xhsort:
	call	checkscore		; Compare scores
	jnc	xgoreturn		; Score at bottom of list is lower, nothing to sort
	jz	xgoreturn		; Scores are equal, nothing to sort

	; Entries should be swapped
	mvi	C, 5
xhswapnextbyte:
	mov	A, M
	mov	B, A
	ldax	D
	mov	M, A
	mov	A, B
	stax	D
	inx	D
	inx	H
	dcr	C
	jnz	xhswapnextbyte
	lda	xhswaplcount
	dcr	A
	sta	xhswaplcount
	jnz	xhsort



xgoreturn:
	; Display high score screen
	call	ClearPlayField
	call	PrintHighScoreList

	call	0h09CA		; Restore what we've destroyed
	jmp	XGONEXT		; and return to the original game code

checkscore:
	inx	D
	inx	H
	ldax	D
	cmp	M
	dcx	D
	dcx	H
	ldax	D
	JZ      checklower          ; Upper two are the same ... have to check lower two
	ret
checklower:
	CMP     M                   ; Is lower digit higher? (upper was the same)
	ret

xhmsgenter:	.db 4, 13, 19, 4, 17, 38, 8, 13, 8, 19, 8, 0, 11, 18	; ENTER INITIALS
xhmsghighscore: .db 7, 8, 6, 7, 38, 18, 2, 14, 17, 4, 18		; HIGH SCORES


	.org XHDATA
xhighrt:	.ds (4+3)*(XHSIZE+1)	; High score table. 4 bytes for score, 3 bytes for initials.
					; Highest highscore at highest memory address.
xhswaplcount:	.ds 1
xhswapbcount:	.ds 1
xhscount:	.ds 1
xhsinitcount:	.ds 1	; Count initials remaining during initial entry
xhndisplist:	.ds 1	; If 0 hs list should be displayed
xhatmp:		.ds 1	; Temporary for A

; Font
; 0  1  2  3  4  5  6  7 
; A  B  C  D  E  F  G  H
;
; 8  9 10 11 12 13 14 15
; I  J  K  L  M  N  O  P
;
;16 17 18 19 20 21 22 23
; Q  R  S  T  U  V  W  X
;
;24 25  38
; Y  Z ' '

