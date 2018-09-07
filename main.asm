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

.list
.org progstart
    .db $BB,$6D
Start:
	; Set up ISR
	ld hl,%000111010
	ld (cube_data),hl
	ld hl,%010111000
	ld (cube_data + 2),hl
	ld hl,%010011010
	ld (cube_data + 4),hl
	ld a,2
	ld (layer),a

    call Install_ISR
	
	; XXX REMOVE
	jr $
	
	call Kill_ISR
	bcall(_delRes)
	ret

#include "../source/calcledcube/interrupt.asm"

.end
END