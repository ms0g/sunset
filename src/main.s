.include "constants.inc"
.include "header.inc"

TileAddrY=$0200
TileAddrX=$0203

.segment "ZEROPAGE"
PtrBg:         	.res 2
Direction:      .res 1
FrameCounter:	.res 1
SpriteCounter:	.res 1

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
	
	jsr move
	
	lda Direction
	eor #$01
	sta Direction
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
	sta $0000, x ; $0000 => $00FF
	sta $0100, x ; $0100 => $01FF
	sta $0300, x
	sta $0400, x
	sta $0500, x
	sta $0600, x
	sta $0700, x
	lda #$FF
	sta $0200, x ; $0200 => $02FF
	lda #$00
	inx
	bne @clrmem

	lda #$00
	sta Direction
	sta FrameCounter  
	sta SpriteCounter
	
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
	lda palettes, x
	sta PPUDATA
	
	inx
	cpx #$20
	bne :-
	rts
.endproc

.proc load_sprite
  	ldx #$00
:
	lda sprites, x
	sta $0200, x
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
	lda attribute, x
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
	lda (PtrBg), y
	sta PPUDATA
	iny
	bne :-
	inc PtrBg+1
	inx
	cpx #$04 
	bne :-
	rts
.endproc

.proc move
  	ldx #$00
:
	inc SpriteCounter
	lda SpriteCounter
	cmp #$08
	beq @changeDir
	lda Direction
	lsr A
	bcs @left
@right:
	inc TileAddrX, x
	jmp @keepOn
@left:
	dec TileAddrX, x
@keepOn:
	txa
	clc
	adc #$04
	tax
	cpx #$E0
	bne :-
	jmp @done
@changeDir:
	lda #$00
	sta SpriteCounter
	lda Direction
	eor #$01
	sta Direction
	jmp :-
@done:
	rts
.endproc

sprites:
	.include "sprites.s"

background:
  	.incbin "assets/background.nam"

.segment "RODATA"
palettes:
  	.byte $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$24,$27, $13,$14,$37,$0F ; background palette
  	.byte $13,$14,$24,$27, $13,$05,$15,$14, $13,$02,$38,$3C, $13,$1C,$15,$14 ; sprite palette 

attribute:
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%11111111,%11111111
	.byte %11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111,%11111111
	.byte %01010101,%01010101,%01010101,%11011111,%11111111,%11111111,%11111111,%11111111
	.byte %01010101,%01010101,%01010101,%01010101,%11111111,%11111111,%11111111,%11111111
	.byte %11110111,%01010101,%01010101,%11111101,%11111111,%11111111,%11111111,%11111111
	.byte %01010101,%01010101,%01010101,%01010101,%01010101,%01010101,%00000000,%00000000
	.byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "assets/graphics.chr"