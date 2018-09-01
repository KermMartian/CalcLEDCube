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
	ld hl,cube_data						; First grab the data for the columns of the layer
	ld a,(layer)
	ld e,a
	ld d,0
	add hl,de
	add hl,de
	ld d,(hl)
	inc hl
	ld e,(hl)
	
	; Put the actual layer number on top.
	inc a
	ld b,3
ISR_SetLayerBits:
	ld c,0
	cp b
	jr nz,ISR_SetLayerBits_WrongLayer
	inc c
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
	rlca								; Rotates a bit in, zeroes out carry
	rlca								; Guaranteed to rotate in a zero, so D is set or reset, and C is reset
	out (bPort),a
	nop
	nop
	or %00000001
	out (bPort),a						; Assert clock in order to actually shift the bit
	nop
	nop
	dec b
	jr z,ISR_OutputBitsDone
	xor a
	out (bPort),a						; De-assert both clock and data. There will be enough math after this to waste time before next bit
	jr ISR_OutputBits

ISR_OutputBitsDone:						; Gotta waste time for a nominal 600 cycles
	ld b,60								; (>= 6e6 clocks/sec * 1e-4 sec / 13 clocks), inflated from 47 for safety
ISR_OutputBitsDone_Wait:
	djnz ISR_OutputBitsDone_Wait

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