; PIC16F877A Configuration Bit Settings

; Assembly source line config statements

#include "p16f877a.inc"

; CONFIG
; __config 0xFF31
 __CONFIG _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _BOREN_OFF & _LVP_OFF & _CPD_OFF & _WRT_OFF & _CP_OFF

;////////////////////////////////////////////
cont1		equ		0x21 ; contador multiproposito
cont2		equ		0x22 ; contador multiproposito
Bguardado	equ		0x25 ; valor previo puerto B (input)
Bactual		equ		0x26 ; lectura actual puerto B
Boperado	equ		0x27 ; diferencia Bactual XOR Bguardado
LIVES		equ		0x28 ; vidas del jugador
obst_row	equ		0x29 ; fila de pared vertical
obst_col	equ		0x2A ; columna de pared vertical
player_row	equ		0x2B ; fila jugador
player_col	equ		0x2C ; columna jugador
cont3		equ		0x2D ; contador multiproposito
cont4		equ		0x2E ; contador multiproposito
cont_wall	equ		0x2F ; tiempo antes de mover pared
cont_player	equ		0x30 ; velocidad jugador
rand_val	equ		0x31 ; valor pseudoaleatorio
cont_iter	equ		0x32 ; iteraciones del main loop
limite_veloc	equ		0x33 ; limite de velocidad pared
ult_hueco	equ		0x34 ; ultimo hueco generado pared vertical
MAX_RETRY	equ		0x35 ; maximo intentos para generar hueco
penult_hueco	equ		0x36 
antepenult_hueco	equ	0x37
cont_parpadeo	equ		0x38 ; contador parpadeo de pared
obstrow_TEMP	equ		0x39
obst1_row	equ		0x3A ; fila pared horizontal
obst1_col	equ		0x3B ; columna pared horizontal
ult_hueco_1	equ		0x3C ; ultimo hueco pared horizontal
penult_hueco_1	equ		0x3D
antepenult_hueco_1	equ	0x3E
nivel		equ		0x3F ; nivel actual del juego
colision	equ		0x40 ; bandera colision
cont_nivel	equ		0x41 ; contador de iteracioens de nivel (cuantas paredes nuevas han pasado)
blink_wall_once	equ		0x42 ; flag de parpadeo para pared horizontal
VELOC_WALL	equ		0x43 ; velocidad inicial pared
puntaje		equ		0x44 ; puntaje de cuántas paredes pasó el jugador exitosamente
	
;////////////////////////////////////////////
	
    org	0x00
    goto    inicio
    
    org	0x04			;interrupts
    goto    ISR
    
inicio
    bcf     STATUS, RP0		; Banco 0
    
    ; CONTADOR ITERACIONES
    clrf    cont_iter		; inicia en 0
    clrf    cont_parpadeo
    clrf    puntaje
    movlw   0x0A
    movwf   MAX_RETRY		; maximo 10 intentos para generar huecos
    ;movlw   b'10000000'
    clrf    nivel		; nivel (nivel 0 inicial)
    clrf    colision
    clrf    cont_nivel
    clrf    blink_wall_once
    ; RANDOM
    ; Configuracion del Timer0 para generar semilla aleatoria
    movlw   b'00000111'		; 1:256
    movwf   OPTION_REG		; TMR0
    clrf    TMR0		; empezar timer en 0
    ; Semilla inicial para RNG
    movlw   0xAB
    movwf   rand_val
    call    random
    call    seed_rng
    ; DEFINICIONES JUGADOR
    movlw   b'00000011'
    movwf   LIVES		; vidas (3)
    movlw   b'00010000'		; punto de inicio jugador (fila inicial)
    movwf   player_row
    movlw   b'00000001'		; punto de inicio jugador (columna inicial)
    movwf   player_col
    movlw   0x03		; velocidad de movimiento jugador
    movwf   cont_player
    ; DEFINICIONES OBSTACULO
    movlw   b'11111111'		; pared
    movwf   obstrow_TEMP
    movwf   obst_row		; pared vertical
    movwf   obst1_col		; pared horizontal
    movwf   ult_hueco
    movwf   penult_hueco	; ult_hueco, penult_hueco, antepenult_hueco evitan repetir obstaculos consecutivos
    movwf   antepenult_hueco
    movwf   ult_hueco_1
    movwf   penult_hueco_1	
    movwf   antepenult_hueco_1
    call    generate_hole	; generar hueco en pared
    call    generate_hole_1
    
    movlw   b'10000000'		; valor para generar carry == 1 al cargar programa
    movwf   obst_col		; pared vertical
    movlw   b'00000001'
    movwf   obst1_row		; pared horizontal
    ; Velocidad pared
    movlw   0x1E
    movwf   limite_veloc
    movwf   VELOC_WALL		; velocidad original
    movwf   cont_wall		; cuanto tiempo antes de que empiece a moverse la pared
    ; DEFINICIONES PINES
    bsf	    STATUS,	RP0
    movlw   b'00000000'
    movwf   TRISC		; PORTC como salida
    movwf   TRISD		; PORTD como salida
    movlw   b'11110000'
    movwf   TRISB		; PORTD como entrada
    bcf	    STATUS,	RP0
    ; INTERRUPTS
    bsf	    INTCON,	GIE	; enable global interrupts
    bsf	    INTCON,	RBIE	; enable interrupts port B
    movf    PORTB,  W		; Se habilita estado a puerto B
    movwf   Bguardado		; valor inicial (usualmente 0x00)
    
    call    blink_wall
bucle
    ; Actualizar RNG
    call    random 
    
    ; Control de velocidad jugador
    decfsz  cont_player,    F
    goto    skip_player_move
    
    ; Lectura de inputs y movimiento jugador
    btfsc   Boperado,	4
    btfss   Bactual,	4
    goto    skip_izquierda
    call    mov_izquierda
skip_izquierda
    
    btfsc   Boperado,	5   ; si el boton del input sigue apretado, 
    btfss   Bactual,	5   ; se continua moviendo al jugador
    goto    skip_abajo
    call    mov_abajo
skip_abajo
    
    btfsc   Boperado,	6
    btfss   Bactual,	6
    goto    skip_arriba
    call    mov_arriba
skip_arriba
    
    btfsc   Boperado,	7
    btfss   Bactual,	7
    goto    skip_derecha
    call    mov_derecha
skip_derecha
    
    movlw   0x03	    ; velocidad movimiento jugador
    movwf   cont_player
    
skip_player_move
    
    ; Movimiento pared
    ; pared 1 (vertical)
    decfsz  cont_wall,	    F	
    goto    skip_move_wall
    call    move_wall
    ; pared 2 (horizontal)
    btfsc   nivel,	7	    ; saltar si es nivel 0
    call    move_wall_1
    btfsc   blink_wall_once,	0   ; parpadear ambas nuevas paredes
    call    blink_wall_once_func    ; cuando se activa flag
    
    movf    limite_veloc,   W	    ; velocidad movimiento obstaculo
    movwf   cont_wall
    
skip_move_wall
    ; Chequeo de colision
    call    check_collision
    
    ; Refrescar display
    call    refresh_display
    
    ; Incrementar contador de iteraciones
    incf    cont_iter,	F
    movlw   0x40		; 64 iteraciones
    subwf   cont_iter,	W
    btfsc   STATUS,	Z
    goto    acelerar_pared      ; acelerar pared cada 64 iteraciones
    goto    bucle
 
acelerar_pared
    decfsz  limite_veloc, F	; aumentar velocidad
    clrf    cont_iter		; reiniciar contador de iteraciones
    goto    bucle
    
blink_wall_once_func
    call    blink_wall		
    clrf    blink_wall_once	; limpiar flag para parpadear una sola vez cuando aparece por primera vez la segunda pared
    movlw   b'00010000'		; punto de inicio jugador (row)
    movwf   player_row
    movlw   b'00000001'		; punto de inicio jugador (col)
    movwf   player_col
    
    return
    
; INTERRUPT
;-----------------------
ISR
    ; Detectar cambios en puerto B
    movf    PORTB,	W   ;lectura de puerto
    movwf   Bactual
    xorwf   Bguardado,	W   ;definimos los valores nuevos obtenidos del puerto (con un XOR)
    movwf   Boperado	    ;se guarda resultado de la operacion
    
    ; Actualziar estado previo
    movf    Bactual,	W   ;actualizando valores iniciales
    movwf   Bguardado	 
    
    ; Limpair flag
    bcf	INTCON,	RBIF	    ;limpiar bandera de interrupción
    retfie		    ;salir de interrupt
;-----------------------

; RANDOM
;-----------------------
; Generar nuevo valor aleatorio usando XOR y rotaciones de bits
random
    ;bcf	STATUS, C
    movf    cont_wall,	W
    xorwf   rand_val,	F
    rrf	    rand_val,   F
    btfsc   rand_val,	7
    xorlw   b'10111000' ; mezclar con una constante cualquiera para generar aleatoriedad
    return

; Semilla inicial usando Timer0
seed_rng
    movf    TMR0,	W	    ; valor del timer
    xorwf   rand_val,	F	    ; hacer XOR con valor actual de rand_val
    return
    
; Tabla de mascaras para generar huecos en paredes    
mask_table
    addwf   PCL, F ; sumar a PCL (Program Counter Low). En base a lo que está en el registro W, se salta del 0 al 15 en base a rand_val gracias a andlw 0x0F en gen_intentar
    retlw   b'11111110'	;   0  (retlw hace un literal write y luego retorna)
    retlw   b'11111101' ;   1
    retlw   b'11111011' ;   2
    retlw   b'11110111' ;   3
    retlw   b'11101111' ;   4
    retlw   b'11011111' ;   5
    retlw   b'10111111' ;   6
    retlw   b'01111111' ;   7
    retlw   b'01111110' ;   8
    retlw   b'10111101' ;   9
    retlw   b'11011011' ;   10
    retlw   b'11111011' ;   11
    retlw   b'11011111' ;   12
    retlw   b'01011011' ;   13
    retlw   b'01111111' ;   14
    retlw   b'10111111' ;   15
;-----------------------
    
; OBSTACULO (pared)
;-----------------------

    ; pared 1 (vertical)
move_wall
    bcf	    STATUS,	C	    ; limpiar el carry que se puede quedar en el registro para evitar errores
    rrf	    obst_col,	F	    ; desplaza la pared
    btfsc   STATUS,	C	    ; si carry = 1, la pared llegó al borde
    goto    new_wall
    return
new_wall			    ; crear nueva pared cuando la pared pasa el borde
    incf    puntaje,	F	    ; aumentar contador de puntaje al crear nueva pared
    incf    cont_nivel,	F	    ; incrementar el registro del contador de nivel
    movlw   7			    ; cuantas paredes antes de pasar a siguiente nivel (depende del valor de cont_nivel)
    subwf   cont_nivel,	W	    ; restar el valor en movlw al contador de nivel en el registro W
    btfsc   STATUS, Z		    ; si el resultado es 0 (Z = 1), se llama la funcion subir_nivel
    call    subir_nivel
    
    incf    rand_val,	F	    ; se incrementa el valor de rand_val para aleatoriedad
    call    random		    ; se llama funcion random para lo anterior
    call    seed_rng		    ; se cambia la semilla de nuevo para aumentar aleatoriedad
    call    generate_hole	    ; se genera nuevo hueco en base a este valor pseudoaleatorio nuevo
    movlw   0x80		    
    movwf   obst_col		    ; la pared se deja en la esquina derecha (en base al valor del movlw en el registro W)

    return
subir_nivel
    clrf    cont_iter
    movlw   b'10000000'
    movwf   nivel	    ; nivel 2 se activa
    movlw   1
    movwf   blink_wall_once ; flag para parpadeo al aparecer segunda pared por primera vez
    movf    VELOC_WALL,	W   ; restaurar velocidad original
    movwf   limite_veloc
    
    return
 
    ; pared 2 (horizontal)
    ; para entender logica, consultar funcion de pared 1
move_wall_1
    bcf	    STATUS,	C
    rrf	    obst1_row,	F ; se mueve fila en vez de columna, ya que la pared es horizontal
    btfsc   STATUS,	C
    goto    new_wall_1
    return
new_wall_1
    incf    rand_val,	F
    call    random
    call    seed_rng
    call    generate_hole_1
    movlw   0x80
    movwf   obst1_row

    return   
    
blink_wall
    movlw   0x03		; 3 parpadeos
    movwf   cont_parpadeo
blink_loop
    ; mostrar pared apagada
    clrf    PORTC
    clrf    PORTD
    btfss   nivel,  7		; si es el nivel 2, llamar un delay para mejorar visibilidad de ambas paredes
    call    delay_parpadeo
    ; mostrar pared encendida
    ; pared 1
    movf    obst_row,	W
    movwf   PORTC
    movf    obst_col,	W
    movwf   PORTD
    call    delay_parpadeo
    ; pared 2
    btfsc   nivel,  7		; no llamar funcion pared2 si es nivel 0
    call    pared2
    decfsz  cont_parpadeo, F	; disminuir el contador de parpadeo
    goto    blink_loop
    return
pared2
    movf    obst1_row,	W
    movwf   PORTC
    movf    obst1_col,	W
    movwf   PORTD
    call    delay_parpadeo
    return
    
; pared 1    
generate_hole			; generar agujero en pareed
    call    seed_rng		; se crea una nueva "semilla" para el RNG (generador de numero aleatorio)
    movlw   MAX_RETRY		; cuantos intentos hay para obtener huecos distintos a el ultimo, penultimo y antepenultimo hueco
    movwf   cont1		; contador para intentos
gen_intentar
    movf    rand_val,	W	
    andlw   0x0F		; del valor pseudo aleatorio, se considera los numeros de 0 al 15
    call    mask_table		; se llama la tabla de mascara para, mediante el PCL, elegir una mezcla de huecos predefinido
    movwf   obst_row		; lo resultante de este mask_table (con el retlw), se escribe el resultado a la pared y genera los huecos correspondientes
    
    ;	evitar mismos huecos generados consecutivamente
    ;	ultimo hueco
    movf    obst_row,	W
    subwf   ult_hueco,   W
    btfsc   STATUS,	Z
    goto    gen_retry
    
    ;	penultimo hueco
    movf    obst_row,	W
    subwf   penult_hueco, W
    btfsc   STATUS,	Z 
    goto    gen_retry
    
    ;	antepenultimo hueco
    movf    obst_row,	W
    subwf   antepenult_hueco, W
    btfsc   STATUS,	Z
    goto    gen_retry
gen_accept
    movf    penult_hueco,   W
    movwf   antepenult_hueco 
    movf    ult_hueco,	W
    movwf   penult_hueco
    movf    obst_row,	W
    movwf   ult_hueco
    return
gen_retry
    decfsz  cont1, F
    goto    gen_random
    ; si se acaban los intentos, aceptar lo que haya
    goto    gen_accept
gen_random
    call    random
    goto    gen_intentar

; pared 2
generate_hole_1
    call    seed_rng
    movlw   MAX_RETRY
    movwf   cont1
gen_intentar_1
    movf    rand_val,	W
    andlw   0x0F
    call    mask_table
    movwf   obst1_col
    
    ;	ultimo hueco
    movf    obst1_col,	W
    subwf   ult_hueco_1,    W
    btfsc   STATUS,	Z
    goto    gen_retry_1
    
    ;	penultimo hueco
    movf    obst1_col,	W
    subwf   penult_hueco_1, W
    btfsc   STATUS,	Z 
    goto    gen_retry_1
    
    ;	antepenultimo hueco
    movf    obst1_col,	W
    subwf   antepenult_hueco_1,	W
    btfsc   STATUS,	Z
    goto    gen_retry_1
gen_accept_1
    movf    penult_hueco_1, W
    movwf   antepenult_hueco_1 
    movf    ult_hueco_1,    W
    movwf   penult_hueco_1
    movf    obst1_col,	W
    movwf   ult_hueco_1
    return
gen_retry_1
    decfsz  cont1, F
    goto    gen_random_1
    ; si se acaban los intentos, aceptar lo que haya
    goto    gen_accept_1
gen_random_1
    call    random
    goto    gen_intentar_1
    
;-----------------------

;////////////////////////////////////////////////////////////////////////////////////////
    
; MOVIMIENTO DEL JUGADOR
;-----------------------
mov_arriba
    ;limite (frontera definida, esquina del display)
    btfss   player_row, 0
    goto    mover_arr
    return
mover_arr
    ;mover jugador
    bcf	    STATUS,	C
    rrf     player_row, F
    return
mov_abajo
    ;limite
    btfss   player_row, 7
    goto    mover_ab
    return
mover_ab    
    ;mover jugador
    bcf	    STATUS,	C
    rlf     player_row, F
    return
mov_izquierda
    ;limite
    btfss   player_col, 0
    goto    mover_izq
    return
mover_izq
    ;mover jugador
    bcf	    STATUS,	C
    rrf	    player_col,	F
    return
mov_derecha
    ;limite
    btfss   player_col, 7
    goto    mover_der
    return
mover_der    
    ;mover jugador
    bcf	    STATUS,	C
    rlf	    player_col, F
    return
;-----------------------
    
; CHEQUEAR COLISIÓN
;-----------------------
check_collision
    clrf    colision
    call    colision_pared1
    btfsc   nivel,	7
    call    colision_pared2
    
    movf    colision,	W
    btfsc   STATUS, Z	    ; si colision = 0, no existe colision y se sale de la funcion
    return
    
    call    damage
    return
damage	; recibir daño
    clrf    colision
    decfsz  LIVES,	F   ; disminuir LIVES (vida)
    goto    still_alive
    goto    game_over
    return
colision_pared1
    movf    obst_row,	W
    andwf   player_row, W
    btfsc   STATUS, Z      
    return
    
    movf    obst_col,	W
    andwf   player_col,	W
    btfsc   STATUS,	Z
    return
    
    call    existe
    return
colision_pared2
    movf    player_row, W
    andwf   obst1_row,	W
    btfsc   STATUS,	Z
    return
    
    movf    player_col, W
    andwf   obst1_col,	W
    btfsc  STATUS,	Z
    return
    
    call    existe
    return
existe
    incf    colision
    return
;-----------------------

; PERDER JUEGO
;-----------------------
game_over
    
    movf    LIVES,  W
    subwf   puntaje,	F   ; el puntaje final es la cantidad de nuevas paredes menos la cantidad de vidas perdidas
    
    clrf    PORTC
    clrf    PORTD
    
    ; flash 2 veces
    comf    PORTC, F
    comf    PORTD, F
    call    grandemora
    comf    PORTC, F
    comf    PORTD, F
    call    grandemora
    comf    PORTC, F
    comf    PORTD, F
    call    grandemora
    comf    PORTC, F
    comf    PORTD, F
    call    grandemora
    
    goto    inicio
    
;-----------------------

; RECIBIR DAÑO
;-----------------------
still_alive
    ; reiniciar posicion jugador
    movlw   b'00010000'		; punto de inicio jugador (row)
    movwf   player_row
    movlw   b'00000001'		; punto de inicio jugador (col)
    movwf   player_col
    
    ; limpiar pantalla
    clrf    PORTC
    clrf    PORTD
    
    ; flash
    comf    PORTC, F		; invertir bits con complemento de f (comf), en este caso el puerto C, para generar parpadeo
    comf    PORTD, F
    call    demora
    comf    PORTC, F
    comf    PORTD, F

    call    new_wall
    btfsc   nivel,  7
    call    new_wall_1
    call    blink_wall		; parpadeo antes de mover obstaculo y preparar al jugador
    return
;-----------------------

; DISPLAY
;-----------------------
refresh_display

    ; jugador
    ; representar bits correspondientes al jugador en la pantalla
    movf    player_row,	W	
    movwf   PORTC
    movf    player_col,	W
    movwf   PORTD
    call    delay_peq
    
    ; obstaculo
    ; representar bits correspondientes a la(s) pared(es) en la pantalla
    movf    obst_row,	W
    movwf   PORTC
    movf    obst_col,	W
    movwf   PORTD
    btfsc   nivel,  7   ; si se encuentra en el nivel 2, se muestra pared 2
    call    disp_pared2
    call    delay_peq
    return
disp_pared2
    call    delay_peq
    movf    obst1_row,	W
    movwf   PORTC
    movf    obst1_col,	W
    movwf   PORTD
    return
;----------------------- 
    
; DELAY
;-----------------------
    
    ; delay para el parpadeo de pared
delay_parpadeo
    call    demora
    call    demora
    call    delay_peq
    return
    
    ; demora mas grande
grandemora
    call    demora
    call    demora
    call    demora
    call    demora
    return
   
    ; delay pequeño
delay_peq
    movlw   0xFF
    movwf   cont3
repet
    movlw   0x0A
    movwf   cont4
repet_again
    decfsz  cont4
    goto    repet_again
    decfsz  cont3
    goto    repet
    return    
    
    ; demora base
demora
    movlw   0xFF
    movwf   cont1
repet1
    movlw   0xC3
    movwf   cont2
repet2
    decfsz  cont2
    goto    repet2
    decfsz  cont1
    goto    repet1
    return    
;-----------------------
    
;////////////////////////////////////////////////////////////////////////////////////////
    
    end