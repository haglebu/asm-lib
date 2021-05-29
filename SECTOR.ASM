;================================================================;
; THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.              ;
; (C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.         ;
;================================================================;
; PETER NORTON'S ASSEMBLERBUCH (PNAB)                            ;
; MARKT & TECHNIK VERLAG AG, 1988                                ;
; ISBN 3-89090-624-9                                             ;
;                                                                ;
; EDITORIAL CHANGES:    THOMAS BRASE, 2021                       ;
;----------------------------------------------------------------;
; FILENAME:             SECTOR.ASM (NEW)                         ;
;                       SOURCE: DISK_I15.ASM, DISP_S15.ASM       ;
;----------------------------------------------------------------;
; THIS FILE CONTAINS THE PROCEDURES FOR READING AND DISPLAYING   ;
; A DISK SECTOR                                                  ;
;                                                                ;
; READ_SECTOR           READ A SECTOR FROM DISK WITH INT25H      ;
; DISP_HALF_SECTOR      DISPLAY A HALF SECTOR (256 BYTE)         ;
; DISP_BPB              DISPLAY THE BIOS PARAMETER BLOCK (BPB)   ;
;                       THIS ARE ONLY 4 LINES OR 4X16 BYTES      ;
; DISP_LINE             DISPLAY ONE LINE (ASCII & HEX)           ;
;================================================================;


;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP      GROUP     CODE_SEG, DATA_SEG
            ASSUME    CS:CGROUP, DS:CGROUP


;================================================================;
CODE_SEG    SEGMENT PUBLIC          ; CODE SEGMENT STARTS HERE



;================================================================;
    PUBLIC  DISP_HALF_SECTOR
    EXTRN   SEND_CRLF:NEAR
;----------------------------------------------------------------;
; THIS PROCEDURE OUTPUTS HALF A SECTOR (256 BYTES).              ;
;    DS:DX      OFFSET IN SECTOR, IN BYTES                       ;
;               SHOULD BE A MULTIPLE OF 16                       ;
;                                                                ;
; USES:         DISP_LINE, SEND_CRLF                             ;
;----------------------------------------------------------------;
DISP_HALF_SECTOR    PROC NEAR
     PUSH   CX
     PUSH   DX
     MOV    CX,16               ; DISPLAY 16 LINES / 256 BYTES
HALF_SECTOR:
     CALL   DISP_LINE
     CALL   SEND_CRLF
     ADD    DX,16
     LOOP   HALF_SECTOR
     POP    DX
     POP    CX
     RET
DISP_HALF_SECTOR    ENDP
;================================================================;


;================================================================;
    PUBLIC  DISP_BPB
    EXTRN   SEND_CRLF:NEAR
;----------------------------------------------------------------;
; THIS PROCEDURE OUTPUTS BIOS PARAMETER BLOCK (64 BYTES).        ;
;    DS:DX      OFFSET IN SECTOR, IN BYTES                       ;
;               SHOULD BE A MULTIPLE OF 16                       ;
;                                                                ;
; USES:         DISP_LINE, SEND_CRLF                             ;
;----------------------------------------------------------------;
DISP_BPB    PROC NEAR
    PUSH    CX
    PUSH    DX
    MOV     CX,4               ; ONLY 4 LINES / 4X16 BYTE
BPB:
    CALL    DISP_LINE
    CALL    SEND_CRLF
    ADD     DX,16
    LOOP    BPB
    POP     DX
    POP     CX
    RET
DISP_BPB    ENDP
;================================================================;


;================================================================;
    PUBLIC  DISP_LINE
    EXTRN   WRITE_HEX:NEAR
    EXTRN   WRITE_CHAR:NEAR
;----------------------------------------------------------------;
; THIS PROCEDURE DISPLAYS ONE LINE (16 BYTE).                    ;
; FIRST IN HEX- THEN IN ASCII-FORMAT.                            ;
;    DS:DX      OFFSET TO DATA SECTOR                            ;
; USES:         WRITE_CHAR, WRITE_HEX                            ;
; READS:        SECTOR                                           ;
;----------------------------------------------------------------;
DISP_LINE PROC NEAR
    PUSH    BX
    PUSH    CX
    PUSH    DX
    MOV     BX,DX               ;OFFSET IST IN BX SINNVOLLER
    MOV     CX,16               ;ANZAHL DER AUSZUGEBENDEN BYTES
    PUSH    BX                  ;OFFSET FšR ASCII_LOOP SICHERN
HEX_LOOP:
    MOV     DL,SECTOR[BX]       ;HOLE 1 BYTE
    CALL    WRITE_HEX           ;GIB DIESES BYTE IN HEX AUS
    MOV     DL,' '              ;SCHREIBE EIN LEERZEICHEN ZWISCHEN 
                                ; DIE ZAHLEN
    CALL    WRITE_CHAR
    INC     BX
    LOOP    HEX_LOOP

    MOV     DL,' '              ;FšGE EIN LEERZEICHEN VOR DEM  
                               ; ZEICHEN AN
    CALL WRITE_CHAR
    MOV     CX,16
    POP     BX                  ;HOLE DEN OFFSET VON SECTOR

ASCII_LOOP:
    MOV     DL,SECTOR[BX]
    CALL    WRITE_CHAR
    INC     BX
    LOOP    ASCII_LOOP

    POP     DX
    POP     CX
    POP     BX
    RET
DISP_LINE   ENDP
;================================================================;

CODE_SEG    ENDS                  ; CODE SEGMENT ENDS HERE

     
;================================================================;
DATA_SEG    SEGMENT PUBLIC      ; DATA SEGMENT STARTS HERE
     PUBLIC     SECTOR
SECTOR      DB  512 DUP (0)     ; SECTOR COMES HERE

DATA_SEG    ENDS                ; DATA SEGMENT ENDS HERE

     END
;================================================================;
; THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.              ;
; (C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.         ;
;================================================================;     