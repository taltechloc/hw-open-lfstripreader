;    Pin 4 is TX output. Pin 2 selector up/down
;    AN0:AN3 sono risp pins: 7, 6, 5, 3

	list      p=12f675          	 ; list directive to define processor
	#include <p12f675.inc>      ; processor specific variable definitions

	errorlevel  -302              	; suppress message 302 from list file

	__CONFIG   _CP_OFF & _CPD_OFF & _MCLRE_OFF & _BODEN_OFF & _WDT_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT  
    ERRORLEVEL -302

;*    cblock      20h
;*    endc


; '__CONFIG' directive is used to embed configuration word within .asm file.
; The labels following the directive are located in the respective .inc file.
; See data sheet for additional information on configuration word settings.
; Reset Vector
;********************************************************************
	ORG     0x000            		; processor reset vector
	nop				; Inserted For ICD2 Use
	goto    Init              		; go to beginning of program

;***** Assign Constants Value *************************************** 
#define	BANK1		banksel 0x80	;Select Bank1
#define	BANK0		banksel 0x00	;Select Bank0
#define serial_out		GPIO,5		;serial data out
#define	bit_K		h'6b'			; hex DA = 1200 bits/sec (218) mi funzionano bene solo le prime 2 velocità, forse sono i cavetti!!!
									; hex 6b = 2400 bits/sec (107)
									; hex 32 = 4800 bits/sec (50)
									; hex 17 = 9600 bits/sec (23)
									; hex 0A =19200 bits/sec (10)
#define half_bit		bit_K/2		
			
;****** Reserve Space for Variables (file registers) ********************
		org		0x20	; start at memory location Hex 20
					; assign 1, 8 bit byte of memory to each
count		res		1	; used to adjust the delay time
rcv_byte	res		1	; the received byte
delay_cntr	res		1	; counter for serial delay routine
bit_cntr	res		1	; number of transmitted bits
xmt_byte	res		1	; the transmitted byte
read0		res		1	; first read of AN0
read1		res		1	; first read of AN1
read2		res		1	; first read of AN2
read3		res		1	; first read of AN3
lettura         res             1       ; read to be converted to decimal aschii
contatore	res		1	; display counter
Display		res		1	; the variable that carries the byte to be 
					; transmitted to the RS-232 subroutine for								; transmission
;**********************************************************************
Init
	BANK1					;Switch to Bank1
	call   	0x3FF      		; retrieve factory calibration value
	movwf   OSCCAL	   		 ; update register with factory cal value 
	movlw	B'11011111'		 ;set internal clock(bit5=0)
	movwf	OPTION_REG	
	;clrf	VRCON			;Vref Off (power off the comparator voltage, saves power)
	;clrf	ANSEL
	movlw	B'11'		; 
	movwf	TRISIO			;
    movlw   B'110011'
    movwf   ANSEL

	BANK0				;BANK 0
	clrf	GPIO			;Clear Port
	;clrf	GPIO			;Clear Port
	;movlw	0x07		
	;movwf	CMCON		;Comparator Off
   

;attesa di circa 2s


        movlw   d'100'          ;rit di 4*0.25s, nella realta sono 4*0.2 secondo (non so dove li perdo)
        call    DelayW10k       ; (10k * 100 /4)/4M =0.25s
        movlw   d'100'          ;rit di 4*0.25s, nella realta sono 4*0.2 secondo (non so dove li perdo)
        call    DelayW10k       ; (10k * 100 /4)/4M =0.25s



;first 4 reads - one time only


    bcf     GPIO,2   ;spengo gpio2
    bsf     GPIO,4   ;accendo gpio4 e attendo un poco
    movlw   d'200'
    call    DelayW100
    movlw   B'1'     ;leggo AN0
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf  ADRESH,w ;per leggere i due bit meno significativi devo cambiare di banco (perche sono su ADRESL con la giustificazione a sinistra
                  ; la giustificazione a destra è quella che da 8 bit LS su ADRESL e 2 bit MS su ADRESH, la situazione attuale è la più semplice).
    movwf read0


    movlw   B'101'   ;leggo AN1
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf  ADRESH,w ;per leggere i due bit meno significativi devo cambiare di banco (perche sono su ADRESL con la giustificazione a sinistra
                  ; la giustificazione a destra è quella che da 8 bit LS su ADRESL e 2 bit MS su ADRESH, la situazione attuale è la più semplice).
    movwf read1

    bcf     GPIO,4   ;spengo gpio4
    bsf     GPIO,2   ;accendo gpio2 e attendo un poco
    movlw   d'200'
    call    DelayW100
    movlw   B'1'     ;leggo AN0
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf  ADRESH,w ;per leggere i due bit meno significativi devo cambiare di banco (perche sono su ADRESL con la giustificazione a sinistra
                  ; la giustificazione a destra è quella che da 8 bit LS su ADRESL e 2 bit MS su ADRESH, la situazione attuale è la più semplice).
    movwf read2

    movlw   B'101'   ;leggo AN1
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf  ADRESH,w ;per leggere i due bit meno significativi devo cambiare di banco (perche sono su ADRESL con la giustificazione a sinistra
                  ; la giustificazione a destra è quella che da 8 bit LS su ADRESL e 2 bit MS su ADRESH, la situazione attuale è la più semplice).
    movwf read3


    clrf contatore

;*******************************************************************
;  this is the "Main" 	

Main
;        call    spetta1

;send hello
	movlw   0x48  ; H of Hello
	movwf	xmt_byte
	call	xmit232


	movlw   0x65  ; e of Hello
	movwf	xmt_byte
	call	xmit232


	movlw   0x6c  ; l of Hello
	movwf	xmt_byte
	call	xmit232


	movlw   0x6c  ; l of Hello
	movwf	xmt_byte
	call	xmit232


	movlw   0x6f  ; o of Hello
	movwf	xmt_byte
	call	xmit232


	movlw   0x21  ; !
	movwf	xmt_byte
	call	xmit232

	movlw   0x20  ; !
	movwf	xmt_byte
	call	xmit232

	movlw   0x43  ; C per counter
	movwf	xmt_byte
	call	xmit232

;send counter
        incf    contatore,1
        movfw   contatore
        movwf   lettura
	call	mandacifre

;send stored data
	movlw   0x52  ; R
	movwf	xmt_byte
	call	xmit232
	movlw   0x31  ; 1
	movwf	xmt_byte
	call	xmit232
    movf        read0,w 
    movwf       lettura
    call        mandacifre
	movlw   0x52  ; R
	movwf	xmt_byte
	call	xmit232
	movlw   0x32  ; 2
	movwf	xmt_byte
	call	xmit232
    movf        read1,w 
    movwf       lettura
    call        mandacifre
	movlw   0x52  ; R
	movwf	xmt_byte
	call	xmit232
	movlw   0x33  ; 3
	movwf	xmt_byte
	call	xmit232
    movf        read2,w 
    movwf       lettura
    call        mandacifre
	movlw   0x52  ; R
	movwf	xmt_byte
	call	xmit232
	movlw   0x34  ; 4
	movwf	xmt_byte
	call	xmit232
    movf        read3,w 
    movwf       lettura
    call        mandacifre

;read byte and send it
 ;   call    spetta1

    bcf     GPIO,2   ;spengo gpio2
    bsf     GPIO,4   ;accendo gpio4 e attendo un poco
    movlw   d'200'
    call    DelayW100
	movlw   0x72  ; r
	movwf	xmt_byte
	call	xmit232
	movlw   0x31  ; 1
	movwf	xmt_byte
	call	xmit232
    movlw   B'1'     ;leggo AN0
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf    ADRESH,w
    movwf   lettura
    call    mandacifre
	movlw   0x72  ; r
	movwf	xmt_byte
	call	xmit232
	movlw   0x32  ; 2
	movwf	xmt_byte
	call	xmit232
   movlw   B'101'    ;leggo AN1
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf    ADRESH,w
    movwf   lettura
    call    mandacifre
    bcf     GPIO,4   ;spengo gpio4
    bsf     GPIO,2   ;accendo gpio2 e attendo un poco
    movlw   d'200'
    call    DelayW100
	movlw   0x72  ; r
	movwf	xmt_byte
	call	xmit232
	movlw   0x33  ; 3
	movwf	xmt_byte
	call	xmit232
    movlw   B'1'    ;leggo AN0
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf    ADRESH,w
    movwf   lettura
    call    mandacifre
	movlw   0x72  ; r
	movwf	xmt_byte
	call	xmit232
	movlw   0x34  ; 4
	movwf	xmt_byte
	call	xmit232
    movlw   B'101'     ;leggo AN1
    movwf   ADCON0
    movlw   d'200'
    call    DelayW100
    bsf     ADCON0,1 ; setta a 1 il secondo bit di ADCON0 per avviarlo
    call    spetta
    movf    ADRESH,w
    movwf   lettura
    call    mandacifre
    bcf     GPIO,4   ;spengo gpio4
    bcf     GPIO,2   ;spengo gpio2

;send bye
	movlw   0x42  ; B for Bye
	movwf	xmt_byte
	call	xmit232
;send return
	movlw   0xA  ; Carriage return
	movwf	xmt_byte
	call	xmit232

        movlw   d'100'          ;rit di 4*0.25s, nella realta sono 4*0.2 secondo (non so dove li perdo)
        call    DelayW10k       ; (10k * 100 /4)/4M =0.25s

	goto	Main			; do it again
;********************************subroutines ***********************
;*******************************************************************
xmit232					; RS-232C serial out.  the byte in file register
					; xmt_byte will transmit
	
again
	movlw	h'08'
	movwf	bit_cntr
	
	bcf	serial_out		;bsf for direct connection 
					;bcf for standard connection 
	call 	bit_delay
xmit
	rrf	xmt_byte,1
	btfss	STATUS,0		;btfsc	STATUS,0  for direct connection			
					;btfss	STATUS,0  for standard connection
	bcf	serial_out	
	btfsc	STATUS,0		;btfss	STATUS,0  for direct connection	
					;btfsc	STATUS,0  for standard connection
	bsf	serial_out		
	call	bit_delay
	decfsz	bit_cntr,1
	goto	xmit
	bsf	serial_out		;bcf for direct connection
					;bsf for standard connection
	call	bit_delay
	return
	
bit_delay
	movlw	bit_K
	movwf	delay_cntr
loop
	nop
	decfsz	delay_cntr,1
	goto	loop
	return


spetta: btfsc   ADCON0,1 ; salta la prossima istruzione se il bit 1 di ADCON3 è tornato a zero; delay per any ADC
        goto    spetta
	return

mandacifre:
;send space
	movlw   0x3D  ; =
	movwf	xmt_byte
	call	xmit232
;3a cifra
      movlw d'47'     ;literal to w, carico -1 (carattere aschii ordinale prima dello zero)
      movwf xmt_byte  ;w to register
      movf  lettura,0 ;register to w
c3    movwf lettura   ;w to register
      incf  xmt_byte,1;inc register to register
      movlw d'100'     ;literal to w
      subwf lettura,0  ;register - w to w
      btfsc STATUS,C   ;skip clear
      goto  c3
      call  xmit232
;2a cifra
      movlw d'47'     ;literal to w, carico -1 (carattere aschii ordinale prima dello zero)
      movwf xmt_byte  ;w to register
      movf  lettura,0 ;register to w
c2    movwf lettura   ;w to register
      incf  xmt_byte,1;inc register to register
      movlw d'10'     ;literal to w
      subwf lettura,0  ;register - w to w
      btfsc STATUS,C   ;skip clear
      goto  c2
      call  xmit232
;1a cifra
      movf  lettura,0 ;register to w
      addlw d'48'   ; ;aggiungo 0 (carattere aschii ordinale dello zero)
      movwf xmt_byte
      call  xmit232
;spazio
	movlw   0x20  ; spazio
	movwf	xmt_byte
	call	xmit232

      return


        include "delayw.asm"
	END           ; directive 'end of program'
