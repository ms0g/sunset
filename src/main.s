.include "constants.inc"
.include "header.inc"

TileAddrY=$0200
TileAddrX=$0203

.segment "ZEROPAGE"
PtrBg:         .res 2
DirFlag:       .res 1
FrameCounter:  .res 1


.segment "CODE"
.import reset_handler
.export main

.proc irq_handler
	rti
.endproc


.proc nmi_handler
  	pha
  	txa
  	pha
  	tya
  	pha
  
	lda #$00
	sta OAMADDR
	lda #$02
	sta OAMDMA
	
	lda #$00
	sta PPUSCROLL
	sta PPUSCROLL

	inc FrameCounter
	lda FrameCounter
	cmp #$0F
	beq @move
	jmp @done
@move:
	lda #$00
	sta FrameCounter  
	
	lsr DirFlag
	bcs :++
	jmp :+
:
	jsr move_right
	lda #$01
	sta DirFlag
	jmp @done
:
	jsr move_left
	lda #$00
	sta DirFlag
@done:
	; ppu clean up 
	lda #%10010000 
	sta PPUCTRL
	lda #%00011110
	sta PPUMASK

	pla 
	tay
	pla
	tax
	pla
	
	rti
.endproc


.proc main
  	ldx #$00
@clrmem:
	sta $0000, X ; $0000 => $00FF
	sta $0100, X ; $0100 => $01FF
	sta $0300, X
	sta $0400, X
	sta $0500, X
	sta $0600, X
	sta $0700, X
	lda #$FF
	sta $0200, X ; $0200 => $02FF
	lda #$00
	inx
	bne @clrmem

	lda #$00
	sta DirFlag
	sta FrameCounter  
	
	jsr load_palette
	jsr load_background
	jsr load_attribute 
	jsr load_sprite

@vblankwait:       ; wait for another vblank before continuing
	bit PPUSTATUS
	bpl @vblankwait

	lda #%10010000  ; turn on NMIs, sprites use first pattern table,bg uses second one
	sta PPUCTRL
	lda #%00011110  ; turn on screen
  	sta PPUMASK
forever:
  	jmp forever
.endproc


.proc load_palette
	ldx PPUSTATUS
	ldx #$3F
	stx PPUADDR
	ldx #$00
	stx PPUADDR

	ldx #$00
:
	lda palettes, X
	sta PPUDATA
	
	inx
	cpx #$20
	bne :-
	rts
.endproc


.proc load_sprite
  	ldx #$00
:
	lda sprites, X
	sta $0200, X
	inx
	cpx #$E0
	bne :-
	rts
.endproc


.proc load_attribute
	lda PPUSTATUS
	lda #$23
	sta PPUADDR
	lda #$CA
	sta PPUADDR

	ldx #$00
:
	lda attribute, X
	sta PPUDATA

	inx
	cpx #$40
	bne :-
  	rts
.endproc


.proc load_background
	lda PPUSTATUS
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	ldx #$00
	ldy #$00
	lda #<background
	sta PtrBg
	lda #>background
	sta PtrBg+1
:
	lda (PtrBg), Y
	sta PPUDATA
	iny
	bne :-
	inc PtrBg+1
	inx
	cpx #$04 
	bne :-
	rts
.endproc


.proc move_right
  	ldx #$00
:
	inc TileAddrX, X
	txa
	clc
	adc #$04
	tax
	cpx #$E0
	bne :-
	rts
.endproc


.proc move_left
  	ldx #$00
:
	dec TileAddrX, X
	txa
	clc
	adc #$04
	tax
	cpx #$E0
	bne :-
	rts
.endproc


sprites:
	.include "sprites.s"

background:
  	.incbin "assets/background.nam"

.segment "RODATA"
palettes:
  	.byte $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$10,$0F ; background palette
  	.byte $13,$14,$24,$27, $13,$05,$15,$14, $13,$02,$38,$3C, $13,$1C,$15,$14 ; sprite palette 

attribute:
	.byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
	.byte %11111111,%00000000,%00000000,%00000000,%11000000,%11111111,%11111111,%11111111
	.byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
	.byte %00000000,%00000000,%00000000,%11001111,%11111111,%11111111,%11111111,%11111111
	.byte %00000000,%00000000,%00000000,%00000000,%11111111,%11111111,%11111111,%11111111
	.byte %11110011,%00000000,%00000000,%11111100,%11111111,%11111111,%11111111,%11111111
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "assets/graphics.chr"