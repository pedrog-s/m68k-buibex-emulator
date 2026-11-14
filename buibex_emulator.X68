*-----------------------------------------------------------
* Title      : PRAFIN25
* Description: Emulador de la BUIBEX
*-----------------------------------------------------------
    ORG $1000
EMEM:   DC.W $A00E,$500B,$C002,$A20F,$500B,$C00B,$E804,$C814,$F7FB
        DC.W $500B,$4007,$C020,$8010,$0000,$0004,$0003,$0000   
EIR:    DC.W 0 ;eregistro de instruccion
EPC:    DC.W 0 ;econtador de programa
ET0:    DC.W 0 ;eregistro T0
ET1:    DC.W 0 ;eregistro T1
ER2:    DC.W 0 ;eregistro R2
ER3:    DC.W 0 ;eregistro R3
ER4:    DC.W 0 ;eregistro R4
ER5:    DC.W 0 ;eregistro R5
ESR:    DC.W 0 ;eregistro de estado (00000000 00000ZNC)

START:
    CLR.W EPC

FETCH:
    ;--- IFETCH: INICIO FETCH
        ;*** En esta seccion debeis introducir el codigo necesario para cargar
        ;*** en EIR la siguiente instruccion a ejecutar, indicada por el EPC,
	    ;*** y dejar listo el EPC para que apunte a la siguiente instruccion
	
    MOVE.W EPC, D0 
    MULS.W #2, D0   ; D0 = EPC * 2 (obtener desplazamiento en bytes)
    MOVEA.W D0, A0  ; calculamos direccion efectiva en A0
    MOVE.W EMEM(A0),EIR ; EIR <- EMEM[A0]
    ADDQ.W #1, EPC     ; EPC ++    
    ;--- FFETCH: FIN FETCH
    
    
    
    ;--- IBRDECOD: INICIO SALTO A DECOD
        ;*** En esta seccion debeis preparar la pila para llamar a la subrutina
        ;*** DECOD, llamar a la subrutina, y vaciar la pila correctamente,
        ;*** almacenando el resultado de la decodificacion en D1

    
    MOVE.W #0, -(SP) ; la salida(ID de instruccion) se almacena en un espacio 
                     ;reservado en la pila antes de la llamada
                     
    MOVE.W EIR, -(SP) ; el parametro de entrada es el valor EIR pasado 
                      ;a traves de la pila
        
    JSR DECOD
    
    MOVE.W 2(SP),D1 ; cogemos la id
    ADDQ.L #4, SP
        
    ;--- FBRDECOD: FIN SALTO A DECOD
    
    
    
    ;--- IBREXEC: INICIO SALTO A FASE DE EJECUCION
        ;*** Esta seccion se usa para saltar a la fase de ejecucion
        ;*** NO HACE FALTA MODIFICARLA
    MULU #6,D1
    MOVEA.L D1,A1
    JMP JMPLIST(A1)
JMPLIST:
    JMP EHLT
    JMP EJMI
    JMP EJMZ
    JMP EJMN
    JMP ESTO
    JMP ELOA
    JMP ETRA
    JMP EADD
    JMP ESUB
    JMP ECMP
    JMP ENAN
    JMP ESET
    JMP EINC
    ;--- FBREXEC: FIN SALTO A FASE DE EJECUCION
    
    
    
    ;--- IEXEC: INICIO EJECUCION
        ;*** En esta seccion debeis implementar la ejecucion de cada einstr.
	
	; ESCRIBID EN CADA ETIQUETA LA FASE DE EJECUCION DE CADA INSTRUCCION
EHLT:
    
     BRA FIN_PROGRAM ; Detiene la maquina
     
     
    

EJMI:
    MOVE.W EIR, D0   ;D0 = 0100xxxxmmmmmmmm
    ANDI.W #$00FF, D0 ; mascara para obtener m (bits 7-0)
    
    MOVE.W D0, EPC      ; EPC <- m
    
    BRA FETCH


EJMZ:
    MOVE.W ESR, D1 ;movemos registro de estado (flags) a D1
    BTST #2, D1 ; comprobamos si Z = 1 y si no lo es salta al FETCH
    BEQ FETCH
    
    MOVE.W EIR, D0 ; D0 = 0101xxxxmmmmmmmm
    ANDI.W #$00FF, D0  ; mascara para obtener m (bits 7-0)     
    
    MOVE.W D0, EPC  ;EPC <- m
    BRA FETCH


EJMN:
    MOVE.W ESR, D1 ;movemos registro de estado (flags) a D1
    BTST #1, D1 ; comprobamos si N = 1 y si no lo es salta al FETCH
    BEQ FETCH 
    
    MOVE.W EIR, D0 ; D0 = 0110xxxxmmmmmmmm  
    ANDI.W #$00FF, D0   ; mascara m para (bits 7-0) 
    
    MOVE.W D0, EPC  ; EPC <- m    
    BRA FETCH 
    
;-----------------------
ESTO:
    BTST #9, EIR ;comprobamos bit j, si bit 9 = 0, usamos ET0, por el contrario ET1
    BEQ USAR_ET0
    
       
    MOVE.W ET1,D1
    BRA CONTINUAR_STO

USAR_ET0:
    MOVE.W ET0, D1    

CONTINUAR_STO:          
    MOVE.W EIR, D0   ; D0 = 100xxxjxmmmmmmmm  
    ANDI.W #$00FF, D0 ;extraemos m (bits 7-0)
    ADD.W D0,D0      ; ajustamos desplazaciemto
    
    LEA EMEM, A0    
    ADD.L D0, A0    ; calculamos direccion efectiva en A0
    
    MOVE.W D1, (A0) ; MEM[A0] <- D1
    
    BRA FETCH
;----------------------

ELOA:
        
    MOVE.W EIR, D0  ;D0 = 101xxxjxmmmmmmmm
    
    ANDI.W #$00FF, D0 ;mascara bits 7-0
    
    ADD.W D0, D0  ; ajustamos tamano palabra, D0 = m * 2 
    
    LEA EMEM, A0
    ADD.L D0, A0 ; calculamos la direccion efectiva: EMEM + 2*m
    
    MOVE.W (A0),D1 ; D1= MEM[A0]

    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN
    
    BTST #9, EIR  ; bit 8: z = 0 si bit = 1 -> T1, por el contrario T0
    BEQ LOA_T0
    
    MOVE.W D1, ET1
    BRA FETCH
LOA_T0:
    MOVE.W D1, ET0
    BRA FETCH
;----------------   

ETRA:
    MOVE.W EIR, D0 ; D0 = 11000xxxxxaaabbb
    
    MOVE.W D0, D2
    ANDI.W #$0038, D2 ; mascara, conserva bits 5-3
    LSR.W #3, D2    ; D2 = Xa (0-7)
    
    MOVE.W D0, D3     ;extrae indice Xb (bits 2-0)
    ANDI.W #$0007, D3 ; D3 = Xb (0-7)
        
    MOVE.W D2, D0   ; lee contenido de Xa
    JSR LEE_REG
    
    MOVE.W D3, D0 ; escribe en Xb el valor leido
    JSR ESCRIBE_REG
    
    BRA FETCH

EADD:

    MOVE.W EIR, D0 ;D0 = 11001xxxxxaaabbb
    
    MOVE.W D0, D2     
    ANDI.W #$0038, D2   ; mascara conserva bits 5-3
    LSR.W #3, D2        ; D2 = Ra (0-7)
    
    MOVE.W D0, D3
    ANDI.W #$0007, D3   ; mascara, bits 2-0 D3 = Rb (0-7)
    
    MOVE.W D2,D0    ; indice Ra
    JSR LEE_REG     ; D1 = [Ra]
    MOVE.W D1, D2   ;[Ra] en D2
    
    MOVE.W D3, D0
    JSR LEE_REG     ; D1 = [Rb]
    MOVE.W D1, D3   ; [Rb] en D3
    
    MOVE.W D3, D1
    ADD.W D2, D1    ; D1 = [Rb] + [Ra]
    
    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN
 
    MOVE.W EIR, D0
    ANDI.W #$0007, D0  ;D0 = Rb
    
    JSR ESCRIBE_REG
        
        
    BRA FETCH
    
    
    
ESUB:

    MOVE.W EIR, D0  ;D0 = 11010xxxxxaaabbb
    
    MOVE.W D0, D2
    ANDI.W #$0038, D2   ;mascara bits 5-3
    LSR.W #3, D2        ;D2 = Ra(0-7)
    
    MOVE.W D0, D3
    ANDI.W #$0007, D3   ;D3 = Rb
    
    MOVE.W D2,D0
    JSR LEE_REG     ;D1 = [Ra]
    MOVE.W D1, D2   ;[Ra] = en D2
    
    MOVE.W D3, D0   
    JSR LEE_REG     ; D1 = [Rb]
    MOVE.W D1, D3   ; [Rb] = en D3
    
    NOT.W D2
    ADDQ.W #1, D2   ; operacion resta en C2: A - B = A + (-B)
    
    ADD.W D2, D3    ;D3 = [Rb] - [Ra]
    
    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN
    
    MOVE.W D3, D1 ; pasamos el resultado de la resta a D1   
    MOVE.W EIR, D0  ; recarga la instr. en D0
    ANDI.W #$0007, D0   ; D0 = Rb
     
    JSR ESCRIBE_REG     
    
    BRA FETCH
    
ECMP:

    MOVE.W EIR, D0  ;D0 = 11011xxxxxaaabbb
    
    MOVE.W D0, D2   
    ANDI.W #$0038, D2   ; mascara bits 5-3
    LSR.W #3, D2        ;D2 = Ra(0-7)
    
    MOVE.W D0, D3       ; mascara bits 2-0
    ANDI.W #$0007, D3   ; D3 = Rb(0-7)
    
    MOVE.W D2, D0       ; D0 = indice Ra
    JSR LEE_REG         
    MOVE.W D1, D2       ; [Ra] = en D2
    
    MOVE.W D3, D0      ; D0 = indice Rb
    JSR LEE_REG     
    MOVE.W D1, D3       ; [Rb] = en D3
    
    NOT.W D2            ; resta en c2 A-B = A+(-B)
    ADDQ.W #1, D2
    
    MOVE.W D3, D1
    ADD.W D2, D1        ; D1 = D3 + D2 = [Rb] - [Ra]
    
    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN
    
    
    BRA FETCH 

ENAN:

    MOVE.W EIR, D0 ; D0 = 11100xxxxxaaabbb
    
    MOVE.W D0, D2
    ANDI.W #$0038, D2 ; mascara bits 5-3
    LSR.W #3, D2    ; D2 = Ra (0-7)
    
    MOVE.W D0, D3
    ANDI.W #$0007, D3 ;mascara bits 2-0 , D3 = Rb(0-7)
    
    MOVE.W D2, D0   ; D0 = Ra
    JSR LEE_REG     ; D1 = [Ra]
    MOVE.W D1, D4   ; D4 = valor de Ra
    
    MOVE.W D3, D0   ; D0, Rb
    JSR LEE_REG     ; D1 = [Rb]
    
    AND.W D4, D1    ; D1 = [Rb] and [Ra]
    NOT.W D1        ; D1 = negado([Rb]and[Ra])
    
    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN
    
    MOVE.W D3, D0   ;restaurad D0 = indice Rb
    JSR ESCRIBE_REG  ;D1 -> ERb 
    
    BRA FETCH
    
ESET:

    MOVE.W EIR, D0    ; D0 = 11101ccccccccbbb
    
    MOVE.W D0, D1     ; copia D0 en D1    
    ANDI.W #$07F8, D1 ; mascara, solo hay bits 10:3
    LSR.W #3, D1     ; desplaza cccccccc -> bits 7:0 de D1
    EXT.W D1            ;extension de signo
    MOVE.W SR, D5

    ANDI.W #$0007, D0 ; mascara, solo bits 2:0
    
    JSR ACTUALIZAR_CZN ; actualiza Z y N con el valor en D1
    
    JSR ESCRIBE_REG   ; compara D0(0-5) y hace MOVE.W D1, ETx/ERx
    BRA FETCH

EINC:

    MOVE.W EIR, D0  ;D0 = 11110ccccccccbbb
    
    MOVE.W D0, D2    
    ANDI.W #$07F8, D2 ; conserva bits 10:3
    LSR.W #3, D2      ; desplaza cccccccc -> bits 7:0
    EXT.W D2          ; extension de signo
    
    MOVE.W D0, D3
    ANDI.W #$0007, D3 ; bits 2-0 en D3
    
    MOVE.W D3, D0 ; se pasa a D0 para leerRegistro
    JSR LEE_REG   ; carga el contenido de Rb en D1
    
    ADD.W D2, D1 ; calculo Rb + c 
        
        
    MOVE.W SR, D5
    JSR ACTUALIZAR_CZN

    MOVE.W D3, D0 ; escribe el resultado en Rb
    JSR ESCRIBE_REG
     

    
    BRA FETCH
    ;--- FEXEC: FIN EJECUCION
    
    

    ;--- ISUBR: INICIO SUBRUTINAS
        ;*** Aqui debeis incluir las subrutinas que necesite vuestra solucion
        ;*** SALVO DECOD, que va en la siguiente seccion

;---------------------------------------------------------;

ACTUALIZAR_ZN:
    MOVE.W ESR, D7         ; Copiamos el registro ESR a D7

                        ; Evaluar flag N (bit 3 en D5)
    BTST #3, D5
    BNE SET_N           ; si N = 1 , salta a SET_N
    BCLR #1, D7
    BRA VERIFICAR_Z

SET_N:
    BSET #1, D7     ; Si N = 1, pone el bit 1 en D7

VERIFICAR_Z:
                    ; Evaluar flag Z (bit 2 en D5)
    BTST #2, D5
    BNE SET_Z       ; si Z= 1 salta a SET_Z
    BCLR #2, D7
    BRA FIN_FLAGS_ZN

SET_Z:
    BSET #2, D7 ; si Z = 1 pone el bit 2 a uno en D7

FIN_FLAGS_ZN:
    MOVE.W D7, ESR ; ahora lo escribe en ESR
    RTS


ACTUALIZAR_CZN:
    JSR ACTUALIZAR_ZN   ;subrutina de FLAGS que primero LLAMA a ACTUALIZAR_ZN

    MOVE.W ESR, D7      ; trae ya el ESR actualizado a D7   

    BTST #0, D5     ; si da todo 0 , el bit era 0 y por tanto salta a NO_C 
    BEQ NO_C

    BSET #0, D7   ; en el caso de que hay carry hace pone el bit 0 a 1 
    MOVE.W D7, ESR
    
    RTS

NO_C:
    BCLR #0, D7   ; pone a 0 el bit 0
    MOVE.W D7, ESR
    RTS
 
 
;---------------------------------------------------------;    
    
    
    
LEE_REG:
                    ; se compara el contenido de D0:
                    ;{0 = T0, 1 = T1, 2 = R2,...., 5 = R5}
    CMP.W #0, D0
    BEQ LEE_T0
    CMP.W #1, D0
    BEQ LEE_T1
    CMP.W #2, D0
    BEQ LEE_R2
    CMP.W #3, D0
    BEQ LEE_R3
    CMP.W #4, D0
    BEQ LEE_R4
    CMP.W #5, D0
    BEQ LEE_R5
    
    
LEE_T0:
    MOVE.W ET0, D1
    RTS
LEE_T1:
    MOVE.W ET1, D1
    RTS
LEE_R2:
    MOVE.W ER2, D1
    RTS
LEE_R3:
    MOVE.W ER3,D1
    RTS
LEE_R4:
    MOVE.W ER4, D1
    RTS
LEE_R5:
    MOVE.W ER5, D1
    RTS
    
;--------------------------------------------;

ESCRIBE_REG:    
    ; se compara el contenido de D0:{0 = T0, 1 = T1, 2 = R2,...., 5 = R5}


    CMP.W #0, D0
    BEQ ESCRIBE_T0
    CMP.W #1, D0
    BEQ ESCRIBE_T1
    CMP.W #2, D0
    BEQ ESCRIBE_R2
    CMP.W #3, D0
    BEQ ESCRIBE_R3
    CMP.W #4, D0
    BEQ ESCRIBE_R4
    CMP.W #5, D0
    BEQ ESCRIBE_R5

ESCRIBE_T0:
    MOVE.W D1, ET0
    RTS
ESCRIBE_T1:
    MOVE.W D1, ET1
    RTS
ESCRIBE_R2: 
    MOVE.W D1, ER2
    RTS
ESCRIBE_R3:
    MOVE.W D1, ER3
    RTS
ESCRIBE_R4:
    MOVE.W D1, ER4
    RTS
ESCRIBE_R5: 
    MOVE.W D1, ER5
    RTS    
;--------------------------------------------;
   ;--- FSUBR: FIN SUBRUTINAS
    
    

    ;--- IDECOD: INICIO DECOD
        ;*** Tras la etiqueta DECOD, debeis implementar la subrutina de 
        ;*** decodificacion, que debera ser de libreria, siguiendo la interfaz
        ;*** especificada en el enunciado
DECOD:
	        
    MOVE.L D0, -(SP) ; empuja el valor de D0 en la pila, 
                     ;reservando espacio y recuperandola  despues
    MOVE.W 8(SP),D0
	        
	;INSTR HLT BITS 15 Y 14 = 00
	;ID 0
    BTST #15, D0            ; SALTAN SI Z = 0;
	BNE NO_HLT              ;BNE = IF NOT EQUAL : Z = 0
	BTST #14, D0 
	BNE NO_HLT
	        
    MOVE.W #0, 10(SP)    
	BRA FIN_DECOD
	
NO_HLT:

    ;INSTR JMI BITS 15-12 = 0100
    ;ID 1
    BTST #15, D0
    BNE NO_JMI          
    BTST #14,D0  
    BEQ NO_JMI              ;BEQ = IF EQUAL : Z = 1
    BTST #13, D0
    BNE NO_JMI
    BTST #12, D0
    BNE NO_JMI 
           
    MOVE.W #1, 10(SP)
	BRA FIN_DECOD
	        
NO_JMI:

    ; INSTR JMZ BITS 15-12 = 0101
    ;ID 2
    BTST #15, D0
    BNE NO_JMZ
    BTST #14, D0
    BEQ NO_JMZ
    BTST #13,D0
    BNE NO_JMZ
    BTST #12, D0
    BEQ NO_JMZ
            
    MOVE.W #2, 10(SP)
    BRA FIN_DECOD
            
NO_JMZ:

    ; INSTR JMN BITS 15-12 = 0110
    ;ID 3
    BTST #15, D0
    BNE NO_JMN
    BTST #14, D0
    BEQ NO_JMN
    BTST #13, D0
    BEQ NO_JMN
    BTST #13, D0
    BNE NO_JMN
    BTST #12,D0
    BNE NO_JMN
            
    MOVE.W #3, 10(SP)
    BRA FIN_DECOD
            
            
            
            
NO_JMN:     
    
    ; INSTR STO BITS 15-13 = 100
    ;ID 4
    BTST #15, D0
    BEQ NO_STO
    BTST #14, D0
    BNE NO_STO
    BTST #13, D0
    BNE NO_STO
            
    MOVE.W #4, 10(SP)
    BRA FIN_DECOD
            
            
NO_STO:     ; INSTR LOA BITS 15-13 = 101
            ;ID 5
    BTST #15, D0
    BEQ NO_LOA
    BTST #14, D0
    BNE NO_LOA
    BTST #13, D0
    BEQ NO_LOA
            
    MOVE.W #5, 10(SP)
    BRA FIN_DECOD        

NO_LOA:     ; INSTR TRA BITS 15-11 = 11000
            ;ID 6
    BTST #15, D0
    BEQ NO_TRA
    BTST #14, D0
    BEQ NO_TRA
    BTST #13, D0
    BNE NO_TRA
    BTST #12, D0
    BNE NO_TRA
    BTST #11, D0
    BNE NO_TRA
            
    MOVE.W #6, 10(SP)
    BRA FIN_DECOD

     
     
NO_TRA:     ; INSTR ADD BITS 15-11 = 11001
            ;ID 7     
    BTST #15, D0
    BEQ NO_ADD
    BTST #14, D0
    BEQ NO_ADD
    BTST #13, D0
    BNE NO_ADD
    BTST #12, D0
    BNE NO_ADD
    BTST #11, D0
    BEQ NO_ADD
            
    MOVE.W #7, 10(SP)         
    BRA FIN_DECOD
                
 NO_ADD:    ;INSTR SUB BITS 15-11 = 11010
            ;ID 8
    BTST #15, D0
    BEQ NO_SUB
    BTST #14, D0
    BEQ NO_SUB
    BTST #13, D0
    BNE NO_SUB
    BTST #12, D0
    BEQ NO_SUB
    BTST #11, D0
    BNE NO_SUB
            
    MOVE.W #8, 10(SP)     
    BRA FIN_DECOD
                    
NO_SUB:     ;INSTR CMP BITS 15-11 = 11011
            ;ID 9
    BTST #15, D0
    BEQ NO_CMP
    BTST #14, D0
    BEQ NO_CMP
    BTST #13, D0
    BNE NO_CMP
    BTST #12, D0
    BEQ NO_CMP
    BTST #11, D0
    BEQ NO_CMP
            
    MOVE.W #9, 10(SP)     
    BRA FIN_DECOD

            
NO_CMP:     ;INSTR NAN BITS 15-11 = 11100
            ;ID 10
    BTST #15, D0
    BEQ NO_NAN
    BTST #14, D0
    BEQ NO_NAN
    BTST #13, D0
    BEQ NO_NAN
    BTST #12, D0
    BNE NO_NAN
    BTST #11, D0
    BNE NO_NAN
        
    MOVE.W #10, 10(SP)
    BRA FIN_DECOD
            
NO_NAN:     ;INSTR SET BITS 15-11 = 11101
            ;ID 11
    BTST #15, D0
    BEQ NO_SET
    BTST #14, D0
    BEQ NO_SET
    BTST #13, D0
    BEQ NO_SET
    BTST #12, D0
    BNE NO_SET
    BTST #11, D0
    BEQ NO_SET
            
    MOVE.W #11, 10(SP)
    BRA FIN_DECOD

NO_SET:     ;INSTR INC BITS 15-11 = 11110
            ;ID 12
     BTST #15, D0
     BEQ INSTR_NO_RECONOCIDA
     BTST #14, D0
     BEQ INSTR_NO_RECONOCIDA
     BTST #13, D0
     BEQ INSTR_NO_RECONOCIDA
     BTST #12, D0
     BEQ INSTR_NO_RECONOCIDA
     BTST #11, D0
     BNE INSTR_NO_RECONOCIDA
            
     MOVE.W #12, 10(SP)     
     BRA FIN_DECOD     

INSTR_NO_RECONOCIDA:
     MOVE.W #-1, 10(SP)
     BRA FIN_DECOD
            
FIN_DECOD:
     MOVE.L (SP)+, D0
     RTS

    ;--- FDECOD: FIN DECOD
FIN_PROGRAM:    
    END    START




    















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
