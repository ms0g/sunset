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
  RTI
.endproc


.proc nmi_handler
  PHA
  TXA
  PHA
  TYA
  PHA
  
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL

  INC FrameCounter
  LDA FrameCounter
  CMP #$0F
  BEQ @move
  JMP @done
@move:
  LDA #$00
  STA FrameCounter  
  
  LSR DirFlag
  BCS :++
  JMP :+
:
  JSR move_right
  LDA #$01
  STA DirFlag
  JMP @done
:
  JSR move_left
  LDA #$00
  STA DirFlag
@done:
  ; ppu clean up 
  LDA #%10010000 
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

  PLA 
  TAY
  PLA
  TAX
  PLA
  
  RTI
.endproc


.proc main
  LDX #$00
@clrmem:
  STA $0000, X ; $0000 => $00FF
  STA $0100, X ; $0100 => $01FF
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FF
  STA $0200, X ; $0200 => $02FF
  LDA #$00
  INX
  BNE @clrmem

  LDA #$00
  STA DirFlag
  STA FrameCounter  
  
  JSR load_palette
  JSR load_background
  JSR load_attribute 
  JSR load_sprite

@vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL @vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table,bg uses second one
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc


.proc load_palette
  LDX PPUSTATUS
  LDX #$3F
  STX PPUADDR
  LDX #$00
  STX PPUADDR

  LDX #$00
:
  LDA palettes, X
  STA PPUDATA
  
  INX
  CPX #$20
  BNE :-
  RTS
.endproc


.proc load_sprite
  LDX #$00
:
  LDA sprites, X
  STA $0200, X
  INX
  CPX #$E0
  BNE :-
  RTS
.endproc


.proc load_attribute
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$CA
  STA PPUADDR

  LDX #$00
:
  LDA attribute, X
  STA PPUDATA

  INX
  CPX #$40
  BNE :-
  RTS
.endproc


.proc load_background
  LDA PPUSTATUS
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  LDX #$00
  LDY #$00
  LDA #<background
  STA PtrBg
  LDA #>background
  STA PtrBg+1
:
  LDA (PtrBg), Y
  STA PPUDATA
  INY
  BNE :-
  INC PtrBg+1
  INX
  CPX #$04 
  BNE :-
  RTS
.endproc


.proc move_right
  LDX #$00
:
  INC TileAddrX, X
  TXA
  CLC
  ADC #$04
  TAX
  CPX #$E0
  BNE :-
  RTS
.endproc


.proc move_left
  LDX #$00
:
  DEC TileAddrX, X
  TXA
  CLC
  ADC #$04
  TAX
  CPX #$E0
  BNE :-
  RTS
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