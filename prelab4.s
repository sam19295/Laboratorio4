; Archivo: main|.s
; Dispositivo: PIC16F887
; Autor: Melanie Samayoa
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: Contador de boton con interrupción
; Hardware: Boton y leds
;
; Creado: 15 feb, 2022
; Última modificación: 15 feb, 2022

PROCESSOR 16F887
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
;-------------------------------------------------------------------------------
UP EQU 0
DOWN EQU 7
REINICIO MACRO 
    BANKSEL PORTA
    MOVLW   61
    MOVWF   TMR0
    BCF	    T0IF
    ENDM
 
PSECT udata_bank0
 cont:	    DS	2
PSECT udata_shr
 WTEMP:	    DS	1
 STSTEMP:   DS	1

PSECT resVect, class=code, abs, delta=2
;-------------------------------------------------------------------------------
  ORG 00h
  resVect:
    PAGESEL main
    GOTO main  
  PSECT code, delta=2, abs
;-------------------------------------------------------------------------------
ORG 04h

push:
    movwf WTEMP
    swapf STATUS, W
    movwf STSTEMP

isr:
    BTFSC RBIF	
    call INTERRUP
    BTFSC T0IF
    call INTERR2
POP:
    SWAPF STSTEMP, W
    MOVWF STATUS
    SWAPF WTEMP, F
    SWAPF WTEMP, W
    RETFIE
;-------------------------------------------------------------------------------
    INTERRUP:
    BANKSEL PORTA
    btfss PORTB, UP
    INCF PORTA
    BTFSS PORTB, DOWN
    DECF PORTA
    bcf RBIF
    Call cuatrobits
    return
    
    INTERR2:
    REINICIO
    INCF cont
    MOVF cont, w
    sublw 10
    btfss STATUS, 2
    goto RTRN
    CLRF cont
    incf PORTC
    RETURN
    RTRN:
    return
PSECT code, delta=2, abs
 ORG 100h
;-------------------------------configuración-----------------------------------
main:
    call CONF
    call RELOJ
    call TIMER0
    call IOC
    call INTER
    call INTER2
    
    banksel PORTA
loop:
    goto loop
;-------------------------------SUBRUTINAS--------------------------------------
IOC:
    banksel TRISA
    BSF IOCB, UP
    BSF IOCB, DOWN
    BANKSEL PORTA
    MOVF PORTB, W
    BCF RBIF
    return
    
CONF:
    bsf	STATUS, 5
    bsf	STATUS, 6
    CLRF ANSEL
    CLRF ANSELH
    bsf	STATUS, 5
    bCf	STATUS, 6
    CLRF TRISA
    CLRF TRISC
    BSF TRISB, UP
    BSF TRISB, DOWN
    BCF OPTION_REG, 7	;WPUB, PULL-UP
    BSF WPUB, UP
    BSF WPUB, DOWN
    bCf	STATUS, 5
    bCf	STATUS, 6
    CLRF PORTA
    CLRF PORTC
    return
    
RELOJ:
    banksel OSCCON
    BSF IRCF2
    BSF IRCF1
    BCF IRCF0
    BSF SCS
    return
    
TIMER0:
    banksel TRISA
    BCF T0CS
    BCF PSA
    BSF PS2
    BSF PS1
    BSF PS0
    REINICIO 
    return

INTER:
    BSF GIE
    BSF RBIE
    BCF RBIF
    RETURN
INTER2:
    BSF GIE
    BSF T0IE
    BCF T0IF
    RETURN
cuatrobits:
    movLW 16
    SUBwf PORTA, W
    BTFSC ZERO
    CLRF PORTA
    RETURN
    END





