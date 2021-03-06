;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;
; THOMAS BRASE, WWW.RETROCMP.DE, 05/2021                         ;
;----------------------------------------------------------------;
; FILENAME      BPB.ASM                                          ;
;----------------------------------------------------------------;
; DISPLAY BIOS PARAMETER BLOCK INFORMATION (BPB) ABOUT DRIVE A:  ;
;                                                                ;
; USES          VIDEO.ASM (PNAB)                                 ;
;               CURSOR.ASM (PNAB)                                ;
;               SECTOR.ASM (WITH SOURCES FROM PNAB)              ;
;                                                                ;
; COMPILE       MAKE MAKEFILE                                    ;
; ASSEMBLER     MICROSOFT MACROASSEMBLER MASM 5.10               ;
; PNAB          PETER NORTON'S ASSEMBLERBUCH (ISBN 3-89090-624-9);
;----------------------------------------------------------------;
; 25.05.2018    CREATED                                          ;
; 28.05.2021    DOCUMENTATION                                    ;
; 29.05.2021    INPUT/READ FLOPPY DRIVE NUMBER                   ;
;               ...                                              ;
;================================================================;

;#################################################################
;   SECTOR  BPB     FIELD   DESCRIPTION
;   OFFSET  OFFSET  LENGTH
;-----------------------------------------------BOOT SECTOR BEGIN-
;   0000    BYTE    EB (JMP)
;   0001    BYTE    ADR (TO BOOT LOADER ADDRESS)
;   0002    BYTE    90 (NOP)
;   0003    8 BYTE  SYSTEM ID, OEM NAME
;----------------------- DOS 2.0 -----------------------BPB BEGIN-
;   000B    0000    WORD    BYTES PER LOGICAL SECTOR
;   000D    0002    BYTE    LOGICAL SECTORS PER CLUSTER
;   000E    0003    WORD    RESERVED LOGICAL SECTORS
;   0010    0005    BYTE    NUMBER OF FATS
;   0011    0006    WORD    ROOT DIRECTORY ENTRIES
;   0013    0008    WORD    TOTAL LOGICAL SECTORS
;   0015    000A    BYTE    MEDIA DESCRIPTOR
;   0016    000B    WORD    LOGICAL SECTORS PER FAT
;----------------------- DOS 3.31 ---------------------------------
;   0018    000D    WORD    PHYSICAL SECTORS PER TRACK
;   001A    000F    WORD    NUMBER OF HEADS
;   001C    0011    DWORD   HIDDEN SECTORS
;   0020    0015    DWORD   LARGE TOTAL LOGICAL SECTORS
;----------------------- DOS 4.0 ----------------------------------
;   0024    0019    BYTE    PHYSICAL DRIVE NUMBER
;   0025    001A    BYTE    FLAGS ETC.
;   0026    001B    BYTE    EXTENDED BOOT SIGNATURE
;   0027    001C    DWORD   VOLUME SERIAL NUMBER
;   002B    0020    11 BYTE VOLUME LABEL
;   0036    002B    8 BYTE  FILE-SYSTEM TYPE
;--------------------------------------------------------BPB END---
;   .....
;                   DOS BOOT LOADER
;   .....
;   01FE            BYTE    0X55 (BOOT SECTOR SIGNATURE)
;   01FF            BYTE    0XAA
;--------------------------------------------------BOOT SECTOR END-
;   0X200           512 BYTE
;##################################################################

;-----------------------------------------------------------------
;       WHAT DOES THIS PROGRAM DO?
;       DISPLAY BIOS PARAMETER BLOCK INFORMATION (BPB) ABOUT DRIVE A:
;       USES INT 25
;-----------------------------------------------------------------
; ==> INPUT
;       AL = LOGICAL DRIVE NUMBER (0=A:, 1=B:, 2=C:, ...)
;           CX = NUMBER OF SECTORS TO READ
;              = -1 IF DOS 4.X (CONTROL BLOCK POINTER IS IN DS:BX)
;       DX = STARTING LOGICAL SECTOR NUMBER (SEE BELOW FOR DOS 4.X+)
;       DS:BX = POINTER TO DATA BUFFER
;          = POINTER TO CONTROL BLOCK (DOS 4.X+, SEE BELOW)
;
; <=== RETURN
;       AH = ERROR CODE IF CF SET:
;       AL = BIOS ERROR CODE IF CF SET
;-----------------------------------------------------------------   

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
S_VER           DB 'BPB - BIOS PARAMETER BLOCK, '
                DB 'V1.1, '
                DB 'CC-BY-NC-SA 4.0, '
                DB 'THOMAS BRASE, 29.05.2021', 0H
S_FDN           DB 'FLOPPY DRIVE NUMBER    : ', 0H

S_SID           DB 'SYSTEM ID              : ', 0H  ; 0003 / 8 BYTE
S_BPS           DB 'BYTES PER SECTOR       : ', 0H  ; 000B / WORD
S_SPC           DB 'SECTORS PER CLUSTER    : ', 0H  ; 000D / BYTE
S_NOF           DB 'NUMBER OF FATS         : ', 0H  ; 0010 / BYTE
S_RDE           DB 'ROOT DIRECTOTY ENTRIES : ', 0H  ; 0011 / WORD
S_TLS           DB 'TOTAL LOGICAL SECTORS  : ', 0H  ; 0013 / WORD
S_MDS           DB 'MEDIA DESCRIPTOR       : ', 0H  ; 0015 / BYTE
S_SPT           DB 'SECTORS PER TRACK      : ', 0H  ; 0018 / WORD
S_NOH           DB 'NUMBER OF HEADS        : ', 0H  ; 001A / WORD
;S_PDN           DB 'PHYSICAL DRIVE NUMBER  : ', 0H  ; 0024 / BYTE
S_VSN           DB 'VOLUME SERIAL NUMBER   : ', 0H  ; 0027 / DWORD
S_VOL           DB 'VOLUME LABEL           : ', 0H  ; 002B / 11 BYTE
S_FST           DB 'FILE SYSTEM TYPE       : ', 0H  ; 0036 / 8 BYTE

                EXTRN     SECTOR:BYTE   ; MEMORY LOCATION FOR SECTOR
                                        ;  SEE SECTOR.ASM
DATA_SEG        ENDS             


;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP  GROUP   CODE_SEG, DATA_SEG
        ASSUME  CS:CGROUP, DS:CGROUP


;-----------------------------------------------------------------
; DEFINE CONSTANTS / NOTE: INT 21 DRIVE NUMBERS !!!
; NOT NEEDED IN BPB.ASM
;-----------------------------------------------------------------
;LW     EQU     00H     ; DRIVE C:
;LW     EQU     01H     ; DRIVE A:
;LW     EQU     02H     ; DRIVE B:


;-----------------------------------------------------------------
; THE 'REAL' CODESEGMENT
;-----------------------------------------------------------------
CODE_SEG        SEGMENT PUBLIC
        ORG     100H    ; THIS IS A "COM" FILE


;-----------------------------------------------------------------
; EXTERNAL PROCEDURES   SECTOR.ASM (PNAB)
;-----------------------------------------------------------------
        EXTRN   DISP_BPB:NEAR


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
; EXTERNAL PROCEDURES   CURSOR.ASM (PNAB)
;-----------------------------------------------------------------
        EXTRN   READ_BYTE:NEAR


;=================================================================
; BEGIN MAIN/START
;=================================================================
START   PROC    NEAR

        CALL    CLEAR_SCREEN        ; CLEAR SCREEN WITH INT10
        MOV     DH,0H               ; LINE Y
        MOV     DL,0H               ; COLUMN X
        CALL    GOTO_XY             ; CURSOR TO 0/0
                                                                
        MOV     DX,OFFSET CGROUP:S_VER  ; DISPLAY VERSION
        CALL    WRITE_STRING
        CALL    SEND_CRLF

        MOV     DL,'-'
        MOV     CX,79D
        CALL    WRITE_CHAR_N_TIMES
        CALL    SEND_CRLF

        MOV     DX,OFFSET CGROUP:S_FDN  ; INPUT FLOPPY DRIVE NUMBER
        CALL    WRITE_STRING

        CALL    READ_BYTE           ; READ NUMBER 00 OR 01 TO AX
        CALL    SEND_CRLF

        MOV     DL,'-'
        MOV     CX,79D
        CALL    WRITE_CHAR_N_TIMES
        CALL    SEND_CRLF


;-----------------------------------------------------------------
; READ COMPLETE BOOTSECTOR (512 BYTE) FROM DRIVE A: TO [SECTOR]
;-----------------------------------------------------------------
;                                   ; DRIVE NUMBER IS IN AL
        MOV     CX,1                ; NUMBER OF SECTORS (1) TO READ
        MOV     DX,0                ; THE SECTOR (0) TO READ
        LEA     BX,SECTOR           ; WHERE THE SECTOR SHOULD BE
        INT     25H                 ; READ SECTOR
        POPF                        ; GET FLAGS FROM STACK 
                                    ;  (DOS HAS PUT THEM THERE)
        XOR     DX,DX               ; SET OFFSET TO 0 (FOR 
                                    ;  SECTOR ZERO)
        CALL    DISP_BPB            ; DISPLAY THE BPB
        
        MOV     DL,'-'
        MOV     CX,79D
        CALL    WRITE_CHAR_N_TIMES
        CALL    SEND_CRLF


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / SYSTEM ID / +03H / 8 BYTE
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_SID
        CALL    WRITE_STRING
        
        XOR     BX,BX
        MOV     CX,08H              ; WRITE 8 BYTES
L_SID:
        MOV     DL,SECTOR[BX+03H]
        CALL    WRITE_CHAR
        INC     BX
        LOOP    L_SID

        CALL    SEND_CRLF        


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / VOLUME LABEL / +2BH / 11 BYTE
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_VOL
        CALL    WRITE_STRING
        
        XOR     BX,BX
        MOV     CX,11D              ; WRITE 11 BYTES
L_VOL:
        MOV     DL,SECTOR[BX+2BH]
        CALL    WRITE_CHAR
        INC     BX
        LOOP    L_VOL

        CALL    SEND_CRLF        


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / FILE SYSTEM TYPE / +36H / 8 BYTE
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_FST
        CALL    WRITE_STRING
        
        XOR     BX,BX
        MOV     CX,08H              ; WRITE 8 BYTES
L_FST:
        MOV     DL,SECTOR[BX+36H]
        CALL    WRITE_CHAR
        INC     BX
        LOOP    L_FST

        CALL    SEND_CRLF
        
         
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / VOL SER NUMBER / +27H / DWORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_VSN
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
     
        MOV     DL,SECTOR[BX+2AH]
        CALL    WRITE_HEX           ; ONLY 1 BYTE
        MOV     DL,SECTOR[BX+29H]
        CALL    WRITE_HEX           ; ONLY 1 BYTE   
        
        MOV     DL,'-'
        CALL    WRITE_CHAR
   
        MOV     DL,SECTOR[BX+28H]
        CALL    WRITE_HEX           ; ONLY 1 BYTE          
        MOV     DL,SECTOR[BX+27H]
        CALL    WRITE_HEX           ; ONLY 1 BYTE        
        CALL    SEND_CRLF

        
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / MEDIA DESCRIPTOR / +15H / BYTE
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_MDS
        CALL    WRITE_STRING

        XOR     BX,BX
        MOV     DL,SECTOR[BX+15H]
        CALL    WRITE_HEX           ; ONLY 1 BYTE          
        CALL    SEND_CRLF
        
        
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / PHYS DRIVE NUMBER / +24H / BYTE
;-----------------------------------------------------------------
;        MOV     DX,OFFSET CGROUP:S_PDN
;        CALL    WRITE_STRING
;
;        XOR     BX,BX
;        MOV     DL,SECTOR[BX+24H]
;        CALL    WRITE_HEX           ; ONLY 1 BYTE          
;        CALL    SEND_CRLF


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / BYTES PER SECTOR / +0BH / WORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_BPS
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
        MOV     DL,SECTOR[BX+0BH]
        MOV     DH,SECTOR[BX+0CH]
        CALL    WRITE_DECIMAL       ; 2 BYTE / WORD          
        CALL    SEND_CRLF


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / SECTORS PER TRACK / +18H / WORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_SPT
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX     
        MOV     DL,SECTOR[BX+18H]
        MOV     DH,SECTOR[BX+19H]
        CALL    WRITE_DECIMAL       ; 2 BYTE / WORD 
        CALL    SEND_CRLF
        
        
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / NUMBER OF HEADS / +1AH / WORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_NOH
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
        MOV     DL,SECTOR[BX+1AH]
        MOV     DH,SECTOR[BX+1BH]
        CALL    WRITE_DECIMAL       ; 2 BYTE / WORD     
        CALL    SEND_CRLF        


;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / TOTAL SECTORS / +13H / WORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_TLS
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
        MOV     DL,SECTOR[BX+13H]
        MOV     DH,SECTOR[BX+14H]
        CALL    WRITE_DECIMAL       ; 2 BYTE / WORD          
        CALL    SEND_CRLF
        
        
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / ROOT DIR ENTRIES / +11H / WORD
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_RDE
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
        MOV     DL,SECTOR[BX+11H]
        MOV     DH,SECTOR[BX+12H]
        CALL    WRITE_DECIMAL       ; 2 BYTE / WORD          
        CALL    SEND_CRLF
        
        
;-----------------------------------------------------------------
; WRITE INFORMATION ON SCREEN / NUMBER OF FATs / +10H / byte
;-----------------------------------------------------------------
        MOV     DX,OFFSET CGROUP:S_NOF
        CALL    WRITE_STRING

        XOR     DX,DX
        MOV     BX,DX
        MOV     DL,SECTOR[BX+10H]
        CALL    WRITE_HEX           ; ONLY 1 BYTE       
        CALL    SEND_CRLF        


        INT     20H                 ; BACK TO DOS

START   ENDP


;=================================================================
; FINAL END (CODE SEGEMENT AND MAIN PROGRAM)
;=================================================================
CODE_SEG        ENDS
        END     START
;================================================================;
; ATTRIBUTION-NONCOMMERCIAL-SHAREALIKE 4.0 INTERNATIONAL         ;
; (CC BY-NC-SA 4.0)                                              ;
;----------------------------------------------------------------;
; NAMENSNENNUNG - NICHT-KOMMERZIELL - WEITERGABE UNTER GLEICHEN  ; 
; BEDINGUNGEN 4.0 INTERNATIONAL (CC BY-NC-SA 4.0)                ;
;================================================================;