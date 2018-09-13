Install_ISR:

;Disabling interrupts prior to installation.
;This is in case an im 2 interrupt is already running.
;(MirageOS would present such a case.)
;
	di

;A 257 byte vector table(located in StatVars) is 
;filled with the same byte.  This byte will determine 
;the location of the interrupt code's start.
;If the table is filled with $XY then the code must be
;located at $XYXY.
;
	ld hl,$8B00
	ld (hl),$8A
	ld de,$8B01
	ld bc,256
	ldir

;The interrupt code is copied to a safe code buffer(StatVars).
;If the interrupt code is to large, you may alternatively
;place jp instruction in this code buffer that jumps to your
;interrupt code. Interrupt code should be located in ram. While
;nothing physically prevents use of bank4000 area, it is 
;commonly swapped out and so at the very least precautions
;would be required to use that area.
;
	ld hl,Interrupt_Start
	ld de,$8A8A
	ld bc,Interrupt_End-Interrupt_Start
	ldir

;You must designate what hardware will generate an interrupt.
;For safety, acknowledging any waiting requests may
;also be done.
;
	ld a,%00001000		;Acknowledge and disable
	out (3),a
	ld a,%00001010		;Set 1st timer active
	out (3),a
	ld a,%00000000		;Fastest timer 1-only frequency, ~560hz = 10,700 cycles max per interrupt
	out (4),a
	
	ld a,%10000000		; Disable link assist, no interrupts
	out (8),a

	ld a,SendCHDH						; Assert both clock and data, which grounds both.
	out (bPort),a						; There will be enough math after this to waste time before next bit

;i is the higher byte of the address that points to the
;vector table.  The lower byte, for all practicality,
;should be considered random.
;
	ld a,$8B
	ld i,a
	im 2
	ei
	ret


;This small function simply ends the installed interrupt.
;This should be done prior to exit, or when it is not safe
;to have a custom interrupt running.
;
Kill_ISR:
	di
	im 1
	ret


Interrupt_Start:
	exx
	ex af,af'

;<- Interrupt Code Here
;This code should be small and brief.
;Assuming, that the interrupt is occurring 110 times a second, this 
;code would have to execute in (CPU_Speed / Frequency) tstates
;ex: 6000000hz / 110hz = ~54545 tstates
;
;Failure to execute in that time would result in missing an 
;interrupt request, in other words you would skip interrupts.
;
;However using less than that amount of time, but near to it
;would result in leaving little time for the main code's execution.
;For example, if the timer generates interrupts every 54545 tstates,
;and your interrupt code executes in 54000 tstates, you would leave
;only 545 tstates for your main programs execution in that time slice.
;The interrupt would take up 99% of the cpu time.
;(This would be a likely issue in gray scale applications.)

; Very important note about this specific interrupt:
; Because the reference implementation uses PNP transistors for the columns, we need
; 0 bits to turn LEDs on (ie, reverse-bias the transistors), and 1 bits to turn them off,
; *in the columns only*. Therefore, we use 0 for column off, 1 for column on, but then
; 0 for layer on, 1 for layer off. Then, when we're shifting out 12 bits, we just invert
; every bit, yielding 0 for column on, 1 for column off; 0 for layer off, 1 for layer on.
	ld hl,cube_data						; First grab the data for the columns of the layer
	ld a,(layer)
	ld e,a
	ld d,0
	add hl,de
	add hl,de
	ld e,(hl)
	inc hl
	ld d,(hl)
	
	; Put the actual layer number on top.
	inc a
	ld b,3
ISR_SetLayerBits:
	ld c,1									; Why is this reversed? see above
	cp b
	jr nz,ISR_SetLayerBits_WrongLayer
	dec c
ISR_SetLayerBits_WrongLayer:
	rr c
	rl e
	rl d
	djnz ISR_SetLayerBits

	; Now we need to move it to the output
	ld b,9 + 3
ISR_OutputBits:							; Pipe out 9 bits at a time
	; Step 1: Set the data, but not the clock
	xor a
	rr d
	rr e
	;ccf								; Important note: inverting the bits because PNP transistors. See above.
	rl a								; Rotates a bit in, zeroes out carry
	ccf									; Set the carry flag
	rl a								; Guaranteed to rotate in a one, so D is set or reset, and C is set (which is voltage LOW)
	out (bPort),a
	nop
	nop
	and ~ClockLow						; De-assert the clock, to bring it high
	out (bPort),a						; ...and actually shift the bit
	nop
	nop
	dec b
	jr z,ISR_OutputBitsDone
	ld a,SendCHDH						; Assert both clock and data, which grounds both.
	out (bPort),a						; There will be enough math after this to waste time before next bit
	jr ISR_OutputBits

ISR_OutputBitsDone:						; Gotta waste time for a nominal 600 cycles
	ld b,60								; (>= 6e6 clocks/sec * 1e-4 sec / 13 clocks), inflated from 47 for safety
ISR_OutputBitsDone_Wait:
	djnz ISR_OutputBitsDone_Wait
	
	ld a,SendCHDH						; Assert both clock and data, which grounds both.
	out (bPort),a						; There will be enough math after this to waste time before next bit

	;advance to next layer
	ld a,(layer)
	dec a
	jp p,ISR_LayerInc_Done
	ld a,2
ISR_LayerInc_Done:
	ld (layer),a

; Footer after interrupt code
	ld a,%00001000		;Acknowledge and disable
	out (3),a
	ld a,%00001010		;Set 1st timer active
	out (3),a
	ld a,%00000110		;Slowest frequency, ~110hz
	out (4),a
	ex af,af'
	exx
	ei
	ret
Interrupt_End: