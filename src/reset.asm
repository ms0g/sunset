.include "constants.inc"

.segment "CODE"
.import main
.export reset_handler

.proc reset_handler
  SEI         ; Disable all interrupts
  CLD         ; Disable decimal mode
  LDX #$40
  STX $4017   ; Disable APU frame IRQ
  LDX #$FF
  TXS         ; Setup stack
  INX         ; Now X=0
  
  STX PPUCTRL ; Disable NMI
  STX PPUMASK ; Disable rendering
  STX $4010   ; Disable DMC IRQs

@vblankwait:
  BIT PPUSTATUS
  BPL @vblankwait
  JMP main
.endproc