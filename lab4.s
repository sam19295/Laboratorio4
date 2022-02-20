; Archivo: main.s
; Dispositivo: PIC16F887
; Autor: Melanie Samayoa
; Compilador: pic-as (v2.30), MPLAB v5.40
; Programa: Contadores utilizando interrupciones y Pullups
; Hardware: Botones en el puerto B y Leds en el puerto A
;	   
; Creado: 17 febrero, 2022
; Última modificación: 17 febrero, 2022
    
PROCESSOR 16F887
#include <xc.inc>

; CONFIGURACIÓN 1
  CONFIG  FOSC = INTRC_NOCLKOUT // Oscilador interno sin salidas
  CONFIG  WDTE = OFF            // WDT disabled (reinicio repetitivo del pic)
  CONFIG  PWRTE = ON            // PWRT enabled (reinicio repetitivo del pic)
  CONFIG  MCLRE = OFF           // El pin de MCLR se utiliza como I/O
  CONFIG  CP = OFF              // Sin protección de código
  CONFIG  CPD = OFF             // Sin protección de datos
  CONFIG  BOREN = OFF           // Sin reinicio cuando el voltaje de alimentación baja de 4V
  CONFIG  IESO = OFF            // Reinicio sin cambio de reloj de interno a externo 
  CONFIG  FCMEN = OFF           // Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = ON              // Programación en bajo voltaje permitida

; CONFIGURACIÓN 2
  CONFIG  BOR4V = BOR40V        // Reinicio abajo de 4V, (BOR21V=2.1V)
  CONFIG  WRT = OFF             // Protección de autoescritura por el programa desactivado
  
 
;--------------Macros-------------------------;
  
rein_tmr0 MACRO
   
    banksel PORTD
    movlw 178    ; imcremento de 1000ms
    movwf TMR0
    bcf T0IF    ; limpiar la bandera
    ENDM

UP EQU 7
DOWN EQU 0
 
PSECT udata_bank0   ; common memory
    cont: DS 2	    ; 2 byte
    cont1: DS 2
    port: DS 1
    port1: DS 1
    port2: DS 2
    port3: DS 1
    portc1: DS 1
    
PSECT udata_shr	    ; common memory
    tempw: DS 1
    temp_status: DS 1
    
    
PSECT resVect, class=CODE, abs, delta=2

;--------------Vector reset-------------------------;
ORG 00h ; posición 0000h para el reset

resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2

ORG 04h ; Posición para las interrupciones
 
;---------- interrupciones -----------------;

push:
    movwf tempw
    swapf STATUS, W
    movwf temp_status
isr:
    btfsc T0IF
    call intmr0
    
    btfsc RBIF
    call intiocb
       
pop:
    swapf temp_status,W
    movwf STATUS
    swapf tempw, F
    swapf tempw, W
    retfie
    
;--------------- subrutinas interrupciones  -----------
intiocb:
    banksel PORTA
    btfss PORTB, UP
    incf port
    btfss PORTB, DOWN
    decf port
    movf port, W
    andlw 00001111B
    movwf PORTA
 
    bcf RBIF
    return

intmr0:
    rein_tmr0
    incf cont
    movf cont,W
    sublw 50
    btfss ZERO
    goto return_to
    clrf cont
    incf port1
    movf port1,W
    call tabla
    movwf PORTD
    
    movf port1, W
    sublw 10
    btfsc STATUS, 2
    call inc
    
    movf port3,W
    call tabla
    movwf PORTC
    
    return
    
inc:
    incf port3
    clrf port1
    movf port1,W
    call tabla
    movwf PORTD
    
    movf port3, W
    sublw 6
    btfsc STATUS, 2
    clrf port3
    return

return_to:
    return
    
 ;--------------- tabla -----------
   
PSECT code, delta=2, abs
ORG 100h	; posición para el codigo

tabla: 
    clrf PCLATH		    ; El registro de PCLATH se coloca en 0
    bsf PCLATH, 0	    ; El valor del PCLATH adquiere el valor 01
    andlw 0x0f		    ; Se restringe el valor máximo de la tabla
    addwf PCL 
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
    
;----------------- configuracion principal----------------------;
    
main:
    call configIO      ; se manda a llamar configuración de los pines
    call configwatch   ;4 Mhz
    call configtmr0
    call configint
    call configiocrb    
    
;-----------------Loop principal----------------------;
loop:
    goto loop     ; loop por siempre


;-----------------Sub rutinas----------------------;
configiocrb:
    banksel TRISA
    bsf IOCB, UP
    bsf IOCB, DOWN
    
    banksel PORTA
    movf PORTB, W   ; al leer termina la condición mismatch
    bcf RBIF
    return
    
configtmr0:
    banksel TRISD
    bcf T0CS ; reloj interno - tmr0 como contador
    bcf PSA ; prescaler
    bsf PS2
    bsf PS1
    bsf PS0 ; PS=111 - 1:256
    rein_tmr0
    return
    
configint:
    bsf GIE 
    bsf T0IE
    bcf RBIE
    
    bsf T0IF
    bcf T0IF
    return
    
configwatch:
    banksel OSCCON
    ;Oscilador de 4MHz (110)
    
    bsf IRCF2   
    bsf IRCF1
    bcf IRCF0    
    bsf SCS ; reloj interno
    return
    
configIO:
    bsf STATUS, 5 ; banco 11
    bsf STATUS, 6  
    clrf ANSEL    ; Pines digitales
    clrf ANSELH

    
    bsf STATUS, 5 ; banco 01
    bcf STATUS, 6  
    clrf TRISA    ; PORT A como salida
    clrf TRISC    ; PORT C como salida
    clrf TRISD    ; PORT D como salida
    
    bsf TRISB, UP
    bsf TRISB, DOWN
    
    bcf OPTION_REG, 7 ;habilita pull-ups
    bsf WPUB, UP
    bsf WPUB, DOWN
    
    bcf STATUS, 5 ; banco 00
    bcf STATUS, 6 
    clrf PORTA
    clrf PORTC
    clrf PORTD
    return
    
    
END