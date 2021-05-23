;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;
; THOMAS BRASE, WWW.RETROCMP.DE, 05/2021                         ;
;----------------------------------------------------------------;
; FILENAME      MI.ASM                                           ;
;----------------------------------------------------------------;
; WRITE MEDIA INFORMATION (MI) ABOUT DRIVE B: TO THE SCREEN:     ;
;                                                                ;
; USES          VIDEO.ASM (PNAB)                                 ;
;               CURSOR.ASM (PNAB)                                ;
;               MEDIA.ASM                                        ;
;                                                                ;
; COMPILE       MAKE MAKEFILE                                    ;
; ASSEMBLER     MICROSOFT MACROASSEMBLER MASM 5.10               ;
; PNAB          PETER NORTON'S ASSEMBLERBUCH (ISBN 3-89090-624-9);
;----------------------------------------------------------------;
; 11.05.2018    CREATED                                          ,
; 12.05.2018    PUSH/POP AT INT 21 (1CH); ADDED CURSOR.ASM       ;  
; 20.05.2021    THE SHOW MUST GO ON :-)                          ;
; 21.05.2021    MEDIA.ASM WITH PROCS CREATED                     ;
;================================================================;



;-----------------------------------------------------------------
; CREATE EMPTY (DUMMY) CODE SEGMENT, THIS MUST BE LOADED FIRST
; -> IMPORTANT FOR MICROSOFT MASM ASSEMBLER
;-----------------------------------------------------------------
CODE_SEG        SEGMENT PUBLIC
CODE_SEG        ENDS



;-----------------------------------------------------------------
; DATA SEGMENT WITH VARIABLES ETC. OTHERWISE THEY ARE UNKNOWN TO 
; THE ASSEMBLER
; S_ = STRING; MUST END WITH 0H BECAUSE OF WRITE_STRING
;-----------------------------------------------------------------
DATA_SEG        SEGMENT PUBLIC
S_VER           DB 'MI-MEDIA INFORMATION, '
                DB 'VERSION 1.0.(09), '
                DB '(C) 2021, '
                DB 'THOMAS BRASE', 0H
S_NLW           DB 'DRIVE NUMBER       : ', 0H           
S_MDS           DB 'MEDIA DESCRIPTOR   : ', 0H
S_BPS           DB 'BYTES PER SECTOR   : ', 0H
S_NCL           DB 'NUMBER OF CLUSTERS : ', 0H
S_SPC           DB 'SECTORS PER CLUSTER: ', 0H
DATA_SEG        ENDS


;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP  GROUP   CODE_SEG, DATA_SEG
        ASSUME  CS:CGROUP, DS:CGROUP


;-----------------------------------------------------------------
; DEFINE CONSTANTS
; INT 21 DRIVE NUMBERS
;-----------------------------------------------------------------
;LW     EQU     00H     ; DRIVE C:
;LW     EQU     01H     ; DRIVE A:
LW      EQU     02H     ; DRIVE B:



;-----------------------------------------------------------------
; THE 'REAL' CODESEGMENT
;-----------------------------------------------------------------
CODE_SEG        SEGMENT PUBLIC
        ORG     100H    ; THIS IS A "COM" FILE



;-----------------------------------------------------------------
; EXTERNAL PROCEDURES   VIDEO.ASM (PNAB)
;-----------------------------------------------------------------
        EXTRN   WRITE_HEX:NEAR
        EXTRN   WRITE_HEX_DIGIT:NEAR
        EXTRN   WRITE_CHAR:NEAR
        EXTRN   WRITE_CHAR_N_TIMES:NEAR
        EXTRN   WRITE_STRING:NEAR
        EXTRN   WRITE_DECIMAL:NEAR



;-----------------------------------------------------------------
; EXTERNAL PROCEDURES   CURSOR.ASM (PNAB)
;-----------------------------------------------------------------
        EXTRN   GOTO_XY:NEAR
        EXTRN   SEND_CRLF:NEAR  
        EXTRN   CURSOR_RIGHT:NEAR
        EXTRN   READ_CURSOR_POSITION:NEAR
        EXTRN   CLEAR_TO_END_OF_LINE:NEAR
        EXTRN   CLEAR_SCREEN:NEAR
     
     
     
;-----------------------------------------------------------------
; EXTERNAL PROCEDURES   MEDIA.ASM (TBR)
;-----------------------------------------------------------------
        EXTRN   WRITE_MDS:NEAR                  ; USES DL
        EXTRN   WRITE_BPS:NEAR                  ; USES DL
        EXTRN   WRITE_NCL:NEAR                  ; USES DL
        EXTRN   WRITE_SPC:NEAR                  ; USES DL



;-----------------------------------------------------------------
;       WHAT DOES THIS PROGRAM DO?
;       INT 21(1CH) -> GETTING & WRITING DRIVE MEDIA INFORMATION 
;-----------------------------------------------------------------
; ==> INPUT
;       AH      1CH FUNCTION CODE
;       DL      DRIVE CODE
;               0 = C:
;               1 = A:
;               2 = B:
; <== OUTPUT
;       AL      SECTORS PER CLUSTER
;       CX      BYTES PER SECTOR
;       DX      TOTAL NUMBER OF CLUSTERS
;       DS:BX   'POINTER' TO MEDIA DESCRIPTOR (FAT-ID-BYTE)
;               ! DS IS CHANGING -> PUSH & POP !
;-----------------------------------------------------------------



;=================================================================
; BEGIN MAIN
;=================================================================
START   PROC    NEAR

        CALL    CLEAR_SCREEN    ; CLEAR SCREEN, INT10
        MOV     DH,0H           ; LINE Y
        MOV     DL,0H           ; COLUMN X
        CALL    GOTO_XY         ; CURSOR TO 0/0



;-----------------------------------------------------------------
; WRITE PROGRAM VERSION
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_VER  ; STRING VERSION ETC.
        CALL    WRITE_STRING
        CALL    SEND_CRLF



;-----------------------------------------------------------------
; WRITE DRIVE NUMBER
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_NLW  ; STRING DRIVE NUMBER
        CALL    WRITE_STRING
        MOV     DL,LW-01H               ; DOS: A = 0, B = 1
        XOR     DH,DH                   ; SET TO ZERO
        CALL    WRITE_DECIMAL           ; LW AUSGEBEN
        CALL    SEND_CRLF



;-----------------------------------------------------------------
; 1) WRITE MEDIA DESCRIPTOR (MDS)
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_MDS  ; STRING
        CALL    WRITE_STRING            ; NO CR/LF
        MOV     DL, LW                  ; INPUT DRIVE TO DL
        CALL    WRITE_MDS               ; MDS
        CALL    SEND_CRLF               ; ... NEXT LINE



;-----------------------------------------------------------------
; 2) WRITE BYTES PER SECTOR (BPS)
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_BPS  ; STRING
        CALL    WRITE_STRING            ; NO CR/LF
        MOV     DL, LW                  ; INPUT DRIVE TO DL
        CALL    WRITE_BPS               ; BPS
        CALL    SEND_CRLF               ; ... NEXT LINE



;-----------------------------------------------------------------
; 3) WRITE NUMBER OF CLUSTERS (NCL)
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_NCL  ; STRING
        CALL    WRITE_STRING            ; NO CR/LF
        MOV     DL, LW                  ; INPUT DRIVE TO DL
        CALL    WRITE_NCL               ; NCL
        CALL    SEND_CRLF               ; ... NEXT LINE



;-----------------------------------------------------------------
; 4) WRITE SECTORS PER CLUSTER (SPC)
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_SPC	; STRING
        CALL    WRITE_STRING            ; NO CR/LF
        MOV     DL, LW                  ; INPUT DRIVE TO DL
        CALL    WRITE_SPC		        ; SPC
        CALL    SEND_CRLF               ; ... NEXT LINE



;-----------------------------------------------------------------
; DONE ... BACK TO DOS
;-----------------------------------------------------------------
        INT     20H



;=================================================================
; FINAL END
;=================================================================
START		ENDP
CODE_SEG        ENDS
        END     START
;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;