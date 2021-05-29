;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;
; THOMAS BRASE, WWW.RETROCMP.DE, 05/2021                         ;
;----------------------------------------------------------------;
; FILENAME      MEDIA.ASM                                        ;
;----------------------------------------------------------------;
; THIS FILE CONTAINS THE PROCEDURES FOR WRITING DRIVE MEDIA      ;
; INFORMATION TO THE SCREEN:                                     ;
;                                                                ;
; WRITE_MDS     MEDIA DESPRIPTOR BYTE                            ;
; WRITE_BPS     BYTES PER SECTOR                                 ;
; WRITE_NCL     TOTAL NUMBER OF CLUSTERS                         ;
; WRITE_SPC     SECTORS PER CLUSTER                              ;
;----------------------------------------------------------------;
; USES          VIDEO.ASM (PNAB)                                 ;
;                                                                ;
; ASSEMBLER     MICROSOFT MACROASSEMBLER MASM 5.10               ;
; PNAB          PETER NORTON'S ASSEMBLERBUCH (ISBN 3-89090-624-9);
;----------------------------------------------------------------;
; USES          INT 21 (1CH)                                     ;
;                                                                ;
; ==> INPUT                                                      ; 
;       AH      1CH FUNCTION CODE                                ;
;       DL      DRIVE CODE                                       ;
;               0 = C:                                           ;
;               1 = A:                                           ;
;               2 = B:                                           ;
; <== OUTPUT                                                     ;
;       AL      SECTORS PER CLUSTER                              ;
;       CX      NUMBER OF BYTES PER SECTOR                       ;
;       DX      NUMBER OF CLUSTERS PER DRIVE                     ;
;       DS:BX   'POINTER' TO MEDIA DESCRIPTOR (FAT-ID-BYTE)      ;
;               !!! DS IS CHANGING -> PUSH & POP !!!             ;
;               DS      SEGMENT                                  ;
;               BX      OFFSET                                   ;
;----------------------------------------------------------------;
; 23.05.2018    CREATED                                          ;
;================================================================;


;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP      GROUP     CODE_SEG, DATA_SEG
            ASSUME    CS:CGROUP, DS:CGROUP

DATA_SEG    SEGMENT PUBLIC
S_HEX           DB 'h ', 0H
DATA_SEG    ENDS

CODE_SEG    SEGMENT PUBLIC


;-----------------------------------------------------------------
; EXTERNAL PROCEDURES           VIDEO.ASM (PNAB)
;-----------------------------------------------------------------
        EXTRN   WRITE_HEX:NEAR
        EXTRN   WRITE_DECIMAL:NEAR
        EXTRN   CURSOR_RIGHT:NEAR
        EXTRN   WRITE_STRING:NEAR


;================================================================;
        PUBLIC  WRITE_MDS
;----------------------------------------------------------------;
; THIS PROCEDURE PRINTS THE MEDIA DESCRIPTOR BYTE AS A TWO-DIGIT ;
; HEX NUMBER AT THE CURRENT CURSOR POSITION.                     ;
;                                                                ;
;       DL      DRIVE NUMBER                                     ;
; USES:         WRITE_HEX                                        ;
;----------------------------------------------------------------;
WRITE_MDS       PROC NEAR
        PUSH    AX              ; SAVE ...
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DS              ; IMPORTANT!

        MOV     AH,1CH          ; FUNCTION CODE
        INT     21H

        MOV     DL,BYTE PTR[BX] ; 'POINTER' DS:BX TO MDS
        CALL    WRITE_HEX       ; WRITE MDS

        POP     DS              ; ... RESTORE
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_MDS       ENDP
;================================================================;


;================================================================;
        PUBLIC  WRITE_BPS
;----------------------------------------------------------------;
; THIS PROCEDURE PRINTS THE NUMBER OF BYTES PER SECTOR AT THE    ;
; CURRENT CURSOR POSITION.                                       ;
;                                                                ;
;       DL      DRIVE NUMBER                                     ;
; USES:         WRITE_HEX, WRITE_DECIMAL, WRITE_STRING,          ;
;               CURSOR_RIGHT                                     ;
;----------------------------------------------------------------;
WRITE_BPS       PROC NEAR
        PUSH    AX              ; SAVE ...
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DS              ; IMPORTANT!

        MOV     AH,1CH          ; FUNCTION CODE
        INT     21H

        MOV     DX,CX           ; BYTES PER SEKTOR ARE IN CX
        CALL    WRITE_DECIMAL   ; WRITE BPS (DEZIMAL)
        CALL    CURSOR_RIGHT
        
        POP     DS              ; RESTORE DATA SEGMENT     
        POP     DX              ; ... RESTORE THE REST
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_BPS       ENDP
;================================================================;


;================================================================;
        PUBLIC  WRITE_NCL
;----------------------------------------------------------------;
; THIS PROCEDURE PRINTS THE TOTAL NUMBER OF CYLINDERS OF THE     ;
; DRIVE                                                          ;
;                                                                ;
; USES:         WRITE_DECIMAL                                    ;
;----------------------------------------------------------------;
WRITE_NCL       PROC NEAR
        PUSH    AX              ; SAVE ...
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DS              ; IMPORTANT !

        MOV     AH,1CH          ; FUNCTION CODE
        INT     21H

;       MOV     DX,DX           ; ALREADY IN DX !
        CALL    WRITE_DECIMAL   ; ... WRITE NCL

        POP     DS              ; ... RESTORE
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_NCL       ENDP
;================================================================;


;================================================================;
        PUBLIC  WRITE_SPC
;----------------------------------------------------------------;
; THIS PROCEDURE PRINTS THE SECTORS PER CLUSTER                  ;
;                                                                ;
; USES:         WRITE_DECIMAL, WRITE_HEX                         ;
;----------------------------------------------------------------;
WRITE_SPC       PROC NEAR
        PUSH    AX              ; SAVE ...
        PUSH    BX
        PUSH    CX
        PUSH    DX
        PUSH    DS              ; IMPORTANT !

        MOV     AH,1CH          ; FUNCTION CODE
        INT     21H

        MOV     DL,AL           ; SPC ARE IN AL
;       CALL    WRITE_HEX       ; MAX. WERT IST 02D = 02H
        XOR     DH,DH           ; SET TO 0
        CALL    WRITE_DECIMAL   ; LOOKS BETTER THAN HEX

        POP     DS              ; ... RESTORE
        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
WRITE_SPC       ENDP
;================================================================;


;================================================================;
CODE_SEG    ENDS
         END
;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;         