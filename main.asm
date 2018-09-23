.nolist
#include "ti83plus.inc"
#include "dcs7.inc"

; For the output, clock = clocking bits into register, data = data to clock in.
SendCLDL		.equ	$00
SendCHDL		.equ	$01
SendCLDH		.equ	$02
SendCHDH		.equ	$03

ClockMask		.equ	$01
ClockHigh		.equ	$00
ClockLow		.equ	$01

DataMask		.equ	$02
DataHigh		.equ	$00
DataLow			.equ	$02

LinkMask		.equ 	$03
GetCLDL			.equ	$03
GetCHDL			.equ	$02
GetCLDH			.equ	$01
GetCHDH			.equ	$00

.varloc SaveSScreen,768
.var 1,layer
.var 6, cube_data

ANIM_STEPS = 4

.list
.org progstart
    .db $BB,$6D
Start:
	; Set up ISR
	ld a,2
	ld (layer),a

    call Install_ISR
	
LayerAnimationRestart:
	xor a
LayerAnimationOuter:
	push af
		ld hl,LayerAnimation1
		ld e,a
		ld d,0
		add hl,de
		add hl,de
		ld b,6				; 3 words
		ld de,cube_data
LayerAnimationInner:
		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		djnz LayerAnimationInner
		
		; Time to wait
		ld bc,40000
LayerAnimationWait:
		nop
		nop
		dec bc
		ld a,b
		or c
		jr nz,LayerAnimationWait
		
		pop af
	inc a
	cp ANIM_STEPS
	jr nz,LayerAnimationOuter
	xor a
	jr LayerAnimationOuter

	call Kill_ISR
	bcall(_delRes)
	ret

#include "../source/calcledcube/interrupt.asm"

LayerAnimation1:
	.dw %000101010
	.dw %000000101
	.dw %010000000
	.dw %101010000
	.dw %000101010
	.dw %000000101
	.dw %010000000

.end
END