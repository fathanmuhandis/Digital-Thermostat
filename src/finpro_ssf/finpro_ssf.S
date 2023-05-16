;------------------------
; Assembly Code
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main

main:
; start of main function
  RCALL init_functions ; call subroutines used for initializing components/functionalities
main_loop:
  RCALL servo_l1
  RCALL DHT11_sensor

  RJMP main_loop ; jump back to start of main loop

;============
; INITIALIZE 
;============
init_functions:
  RCALL MAX_SPI_init
  RCALL ADC_init
  RCALL servo_init
RET

;===================
; SERVO SUBROUTINES
;===================
servo_init:
;-----------
    SBI   DDRB, 4         ;pin PB4 o/p for servo control
    RET
;-----------------------------------------------------------
servo_l1: 
    ;LDI R16, 11
    ;MUL R31, R16       ;load rotation pos
    ;MOV R31, R0
    LDI R31, 90
    RCALL servo_rotate    ;& rotate servo
    RET           ;go back & repeat
;---------------------------------------------------------------
servo_rotate:
;------------
    LDI   R20, 10         ;count to give enough cycles of PWM
servo_l2: SBI   PORTB, 4
    RCALL servo_delay_tim0
    CBI   PORTB, 4        ;send msec pulse to rotate servo
    RCALL servo_delay_20ms      ;wait 20ms before re-sending pulse
    DEC   R20
    BRNE  servo_l2              ;go back & repeat PWM signal
    ;----------------------------------------------------------
bak:
    RCALL servo_delay_05s        ;0.5s delay
    RET                   ;& return to main subroutine
;-------------------------------------------
;delay subroutines
;-------------------------------------------
servo_delay_tim0:             ;delay via Timer0
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCNT0, R21      ;initialize timer0 with count=0
    MOV   R21, R31
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ;timer0: CTC mode, prescaler 256
    ;-----------------------------------------------------------
servo_tim0_l3: IN    R21, TIFR0      ;get TIFR0 byte & check
    SBRS  R21, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  servo_tim0_l3              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCCR0B, R21     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R21, (1<<OCF0A)
    OUT   TIFR0, R21      ;clear OCF0 flag
    RET
;===============================================================
servo_delay_20ms:               ;delay 20ms
    LDI   R21, 255
servo_d20_l1: LDI   R22, 210
servo_d20_l2: LDI   R23, 2
servo_d20_l3: DEC   R23
    BRNE  servo_d20_l3
    DEC   R22
    BRNE  servo_d20_l2
    DEC   R21
    BRNE  servo_d20_l1
    RET
;===============================================================
servo_delay_05s:                 ;delay 0.5s
    LDI   R21, 255
servo_d05s_l1 :LDI   R22, 255
servo_d05s_l2 :LDI   R23, 41
servo_d05s_l3 :DEC   R23
    BRNE  servo_d05s_l3
    DEC   R22
    BRNE  servo_d05s_l2
    DEC   R21
    BRNE  servo_d05s_l1
    RET


;================
; CALCULATE TEMP
;================
; R19: ADCL-Hi, R18: ADCL-Lo
calc_temp:
	MOV R22, R19
	CLR R23 ;initialize quotient to 0
	calc_l0:
		SUBI R22, 16 ;num = num - denom
		BRLO calc_done ;exit loop when -ve
		INC R23 ;increment quotient by 1
		RJMP calc_l0 ;loop & do another subtraction
	calc_done:
    MOV R31, R23
		SUBI R23, -16

RET

;=================
; ADC SUBROUTINES
;=================
ADC_init:
  SBI DDRC, 0 ; Set PC0 as input
  LDI R20, 0xE0 ; Load b1100 0000 to R20
  STS ADMUX, R20 ; Store b1100 0000 to ADMUX
  LDI R20, 0x87 ; Load b1000 0111 to R20
  STS ADCSRA, R20 ; Store b1000 0111 to ADCSRA to configure ADC
  RET
ADC_read:
  LDI R20, 0xC7 ; Load b1100 0111 to R20
  STS ADCSRA, R20 ; This will set the 'start conversion' bit
                  ; and start the conversion
ADC_wait:
  LDS R21, ADCSRA ; Load value of ADCSRA to R2
  SBRS R21, 4 ; Check if the interrupt flag bit is set
  RJMP ADC_wait ; If not set, run this and loop back
                ; If set skip this to the next instruction
  LDI R17, 0xD7 ;
  STS ADCSRA, R17 ; Set interrupt flag back
  LDS R18, ADCL ; Load low-byte result to R18 from ADCL
  LDS R19, ADCH ; Load high-byte result to R19 from ADCH
  RET

;===================
; DHT11 SUBROUTINES
;===================
DHT11_sensor:
;-----------------------------------------------------------------
DHT11_agn:
RCALL DHT11_delay_2s      ;wait 2s for DHT11 to get ready
; start_signal
    SBI   DDRD, 7       ;pin PD7 as o/p
    CBI   PORTD, 7      ;first, send low pulse
    RCALL DHT11_delay_20ms    ;for 20ms
    SBI   PORTD, 7      ;then send high pulse
; response signal
    CBI   DDRD, 7       ;pin PD7 as i/p
DHT11_w1: SBIC  PIND, 7
    RJMP  DHT11_w1            ;wait for DHT11 low pulse
DHT11_w2: SBIS  PIND, 7
    RJMP  DHT11_w2            ;wait for DHT11 high pulse
DHT11_w3: SBIC  PIND, 7
    RJMP  DHT11_w3            ;wait for DHT11 low pulse
;----------------------------------------------------------------
  RCALL DHT11_reading ;read humidity (1st byte of 40-bit data)
  MOV   R25, R24
  RCALL DHT11_reading
  RCALL DHT11_reading ;read temp (3rd byte of 40-bit data)
;----------------------------------------------------------------
; Convert temp & humidity bytes to decimal & display on MAX7219
;----------------------------------------------------------------
    RCALL MAX_disp_text

    MOV   R28, R24
    LDI   R29, 0x07
    LDI   R30, 0x06
    ;------------------
    RCALL MAX_binary2decimal  ;temp in decimal
    ;-------------------
    RCALL ADC_read
    RCALL calc_temp
    MOV   R28, R23
    LDI   R29, 0x02
    LDI   R30, 0x01
    ;-------------------
    RCALL MAX_binary2decimal  ;humidity in decimal

    ;-------------------
    RET           ;go back & get another sensor reading
;=================================================================
DHT11_reading:
    LDI   R16, 8        ;set counter for receiving 8 bits
    CLR   R24           ;clear data register
    ;-------------------------------------------------------
DHT11_w4: SBIS  PIND, 7
    RJMP  DHT11_w4            ;detect data bit (high pulse)
    RCALL DHT11_delay_tim0  ;wait 50us & then check bit value
    ;-------------------------------------------------------
    SBIS  PIND, 7       ;if received bit=1, skip next inst
    RJMP  DHT11_skip           ;else, received bit=0, jump to DHT11_skip
    SEC                 ;set carry flag (C=1)
    ROL   R24           ;shift in 1 into LSB data register
    RJMP  DHT11_w5            ;jump & wait for low pulse
DHT11_skip:LSL   R24           ;shift in 0 into LSB data register
    ;-------------------------------------------------------
DHT11_w5: SBIC  PIND, 7
    RJMP  DHT11_w5            ;wait for DHT11 low pulse
    ;-------------------------------------------------------
    DEC   R16           ;decrement counter
    BRNE  DHT11_w4            ;go back & detect next bit
    RET                 ;return to calling subroutine
;========
; DELAYS
;========
DHT11_delay_20ms:             ;delay 20ms
    LDI   R21, 255
d20_l1: LDI   R22, 210
d20_l2: LDI   R23, 2
d20_l3: DEC   R23
    BRNE  d20_l3
    DEC   R22
    BRNE  d20_l2
    DEC   R21
    BRNE  d20_l1
    RET
;-----------------------------------------------------------------
DHT11_delay_2s:               ;delay 2s
    LDI   R21, 255
d2_l1: LDI   R22, 255
d2_l2: LDI   R23, 164
d3_l3: DEC   R23
    BRNE  d3_l3
    DEC   R22
    BRNE  d2_l2
    DEC   R21
    BRNE  d2_l1
    RET
;----------------------------------
DHT11_delay_50us:               ;delay 50us
    LDI   R21, 255
d50_l1: LDI   R22, 1
d50_l2: LDI   R23, 1
d50_l3: DEC   R23
    BRNE  d50_l3
    DEC   R22   
    BRNE  d50_l2
    DEC   R21
    BRNE  d50_l1
    RET
;===============================================================
DHT11_delay_tim0:             ;50 usec delay via Timer 0
    ;---------------------------------------------------------
    CLR   R20
    OUT   TCNT0, R20      ;initialize timer0 with count=0
    LDI   R20, 100
    OUT   OCR0A, R20      ;OCR0 = 100
    LDI   R20, 0b00001010
    OUT   TCCR0B, R20     ;timer0: CTC mode, prescaler 64
    ;---------------------------------------------------------
dht_l2: IN    R20, TIFR0      ;get TIFR0 byte & check
    SBRS  R20, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  dht_l2              ;else, loop back & check OCF0 flag
    ;---------------------------------------------------------
    CLR   R20
    OUT   TCCR0B, R20     ;stop timer0
    ;---------------------------------------------------------
    LDI   R20, (1<<OCF0A)
    OUT   TIFR0, R20      ;clear OCF0 flag
    RET
;=====================
; MAX7219 SUBROUTINES
;=====================
MAX_SPI_init:
;----------------
.equ  SCK, 5
.equ  MOSI, 3
.equ  SS, 2
;--------------------------------------------------------------
      LDI   R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
      OUT   DDRB, R17       ;set MOSI, SCK, SS as o/p
      ;--------------------------------------------------------
      LDI   R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
      OUT   SPCR, R17       ;enable SPI as master, fsck=fosc/16
      ;--------------------------------------------------------
      LDI   R17, 0x0A       ;set segment intensity (0 to 15)
      LDI   R18, 8          ;intensity level = 8
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x09       ;set decoding mode command
      LDI   R18, 0b01100011 ;decoding byte
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x0B       ;set scan limit command
      LDI   R18, 0x07       ;8 digits connected to MAX7219
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x0C       ;set turn ON/OFF command
      LDI   R18, 0x01       ;turn ON MAX7219
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      RET
;==============================================================
MAX_disp_text:
;-----------------
      LDI   R17, 0x08       ;select digit 8
      LDI   R18, 0xCE      ;data = C.
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x05       ;select digit 5
      LDI   R18, 0x01       ;data = -
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x04       ;select digit 4
      LDI   R18, 0x01       ;data = space
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      LDI   R17, 0x03       ;select digit 4
      LDI   R18, 0x8F       ;data = t.
      RCALL MAX_send_bytes      ;send command & data to MAX7219---------------------------------------

      RET
;==============================================================
MAX_send_bytes:
      CBI   PORTB, SS       ;enable slave device MAX7219
      OUT   SPDR, R17       ;transmit command
      ;--------------------------------------------------------
MAX_ll2:  IN    R19, SPSR
      SBRS  R19, SPIF       ;wait for byte transmission
      RJMP  MAX_ll2             ;to complete
      ;--------------------------------------------------------
      OUT   SPDR, R18       ;transmit data
      ;--------------------------------------------------------
MAX_ll3:  IN    R19, SPSR
      SBRS  R19, SPIF       ;wait for byte transmission
      RJMP  MAX_ll3             ;to complete
      ;--------------------------------------------------------
      SBI   PORTB, SS       ;disable slave device MAX7219
      RET
;==============================================================
MAX_binary2decimal:
;--------------
      CLR   R26             ;set counter1, initial value 0
      CLR   R27             ;set counter2, initial value 0
      ;--------------------------------------------------------
MAX_l70:  CPI   R28, 100        ;compare R28 with 100
MAX_ret:  BRMI  MAX_l80             ;jump when R28 < 100
      INC   R26             ;increment counter1 by 1
      SUBI  R28, 100        ;R28 = R28 - 100
      RJMP  MAX_l70
      ;--------------------------------------------------------
MAX_l80:  CPI   R28, 10         ;compare R28 with 10
      BRMI  MAX_dsp             ;jump when R28 < 10
      INC   R27             ;increment counter2 by 1
      SUBI  R28, 10         ;R28 = R28 - 10
      RJMP  MAX_l80
      ;--------------------------------------------------------  
MAX_dsp:  MOV   R18, R27
      MOV   R17, R29        ;select digit
      RCALL MAX_send_bytes      ;send command & data to MAX7219
      ;--------------------------------------------------------
      MOV   R18, R28
      MOV   R17, R30        ;select digit
      RCALL MAX_send_bytes      ;send command & data to MAX7219    
      ;--------------------------------------------------------
      RET