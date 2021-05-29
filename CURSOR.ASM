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
; FILENAME:             CURSOR.ASM                               ;
;----------------------------------------------------------------;
; THIS FILE CONTAINS THE PROCEDURES FOR CONTROLLING THE CURSOR:  ;
;                                                                ;
; GOTO_XY               REPOSITIONING THE CURSOR                 ;
; SEND_CRLF             MOVE THE CURSOR TO THE BEGINNING OF THE  ;
;                       NEXT LINE.                               ;
; CURSOR_RIGHT          MOVE CURSOR ONE COLUMN TO THE RIGHT      ;
; READ_CURSOR_POSITION  READ CURRENT CURSOR POSITION             ;
; CLEAR_TO_END_OF_LINE  DELETE ALL CHARACTERS AFTER THE CURSOR   ;
; CLEAR_SCREEN          CLEAR SCREEN                             ;
;================================================================;


;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP      GROUP     CODE_SEG, DATA_SEG
            ASSUME    CS:CGROUP, DS:CGROUP

DATA_SEG    SEGMENT PUBLIC
DATA_SEG    ENDS

CODE_SEG    SEGMENT PUBLIC



;-----------------------------------------------------------------
; DEFINE CONSTANTS
;-----------------------------------------------------------------
CR      EQU  13        ;CARRIAGE RETURN
LF      EQU  10        ;LINE FEED


;================================================================;
     PUBLIC    GOTO_XY
;----------------------------------------------------------------;
; DIESE PROZEDUR BEWEGT DEN CURSOR                               ;
;                                                                ;
;   DH      ZEILE (Y)                                            ;
;   DL      SPALTE (X)                                           ;
;----------------------------------------------------------------;
GOTO_XY     PROC NEAR
    PUSH    AX
    PUSH    BX
    MOV     BH,0        ;BILDSCHIRM-SEITE 0 EINSCHALTEN
    MOV     AH,2        ;DER CURSOR SOLL POSITIONIERT WERDEN
    INT     10H         ;DIE ARBEIT MACHT DAS ROM BIOS
    POP     BX
    POP     AX
    RET
GOTO_XY     ENDP
;================================================================;


;================================================================;
    PUBLIC  SEND_CRLF
;----------------------------------------------------------------;
; DIESE PROZEDUR SCHICKT LEDIGLICH EIN WAGENRCKLAUF-ZEICHEN (CR);
; UND EIN ZEILENVORSCHUB-ZEICHEN (LF) ZUM BILDSCHIRM. DURCH DAS  ;
; BENUTZEN DER DOS ROUTINE IST GEWHRLEISTET, DA  DAS            ;
; BILDSCHIRMSCROLLEN KORREKT ARBEITET                            ;
;----------------------------------------------------------------;
SEND_CRLF   PROC NEAR
    PUSH    AX
    PUSH    DX
    MOV     AH,2        ;ES SOLL EIN ZEICHEN AUSGEGEBEN WERDEN
    MOV     DL,CR       ;SENDE DAS WAGENRUECKLAUF-ZEICHEN
    INT     21H
    MOV     DL,LF       ;SENDE DAS ZEILENVORSCHUB-ZEICHEN
    INT     21H
    POP     DX
    POP     AX
    RET
SEND_CRLF   ENDP
;================================================================;


;================================================================;
     PUBLIC    CURSOR_RIGHT
;----------------------------------------------------------------;
; DIESE PROZEDUR BEWEGT DEN CURSOR EINE POSITION NACH RECHTS.    ;
; STAND DER CURSOR AM ENDE EINER ZEILE, SO WIRD ER AN DEN ANFANG ;
; DER FOLGENDEN ZEILE GESETZT                                    ;
;                                                                ;
; BENUTZT:          SEND_CRLF                                    ;
;----------------------------------------------------------------;
CURSOR_RIGHT   PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    MOV     AH,3           ;AKTUELLE POSITION DES CURSORS LESEN
    MOV     BH,0           ;AUF BILDSCHIRMSEITE 0 
    INT     10H            ;BIOS FUNKTION ARBEITET
    MOV     AH,2           ;CURSOR NEU POSITIONIEREN
    INC     DL             ;UM EINE SPALTE NACH RECHTS
    CMP     DL,79          ;SPALTE 79 UEBERSCHRITTEN ?
    JBE     MOVE_CURSOR    ;NEIN, DANN CURSOR WEITERRUECKEN
    CALL    SEND_CRLF      ;JA, IN DIE NAECHTSTE ZEILE GEHEN
    JMP     DONE_CURSOR_RIGHT
MOVE_CURSOR:
    INT     10H            ;CURSOR BEWEGEN
DONE_CURSOR_RIGHT:
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
CURSOR_RIGHT    ENDP
;================================================================;


;================================================================;
     PUBLIC    READ_CURSOR_POSITION
;--------------------------------------------------------------;
; DIESE PROZDDUR FOLGT NICHT DEN VEREINBARUNGEN, INFORMATIONEN ;
; IM AX-REGISTER ZURCKZUGEBEN.                                ;
; DAHER KANN SIE EINFACH MIT GOTO_XY BENUTZT WERDEN.           ;
;                                                              ;
; RESULTATE:   DH,DL     ZEILE, SPALTE DER CURSERPOSITION      ;
;--------------------------------------------------------------;
READ_CURSOR_POSITION     PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    CX
    MOV     AH,3           ;AKTUELLE CURSOR-POSITION BESIMMEN
    MOV     BH,0           ;AUF SEITE 0
    INT     10H            ;GEBE RESULTAT IN DX ZURUECK
    POP     CX
    POP     BX
    POP     AX
    RET
READ_CURSOR_POSITION     ENDP
;================================================================;


;================================================================;
     PUBLIC    CLEAR_TO_END_OF_LINE
;----------------------------------------------------------------;
; DIESE PROZEDUR LSCHT DIE ZEILE AB DER AKTUELLEN CURSOR-       ;
; POSITION                                                       ;
;----------------------------------------------------------------;
CLEAR_TO_END_OF_LINE     PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    MOV     AH,3           ;BESTIMME AKTUELLE CURSOR-POSITION
    XOR     BH,BH          ;AUF SEITE 0
    INT     10H            ;JETZT STEHEN (X,Y) IN DL, DH
    MOV     AH,6           ;INITIALISIEREN DES LOESCHVORGANGS
    XOR     AL,AL          ;FENSTER LOESCHEN
    MOV     CH,DH          ;NUR DIESE ZEILE
    MOV     CL,DL          ;BEGINNE BEI DER CURSOR-POSITION
    MOV     DL,79          ;UND STOPPE AM ENDE DER ZEILE
    MOV     BH,7           ;BENUTZE DAS NORMALE ATTRIBUT
    INT     10H
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
CLEAR_TO_END_OF_LINE     ENDP
;================================================================;


;================================================================;
     PUBLIC    CLEAR_SCREEN
;----------------------------------------------------------------;
;  DIESE PROZEDUR L™SCHT DEN GESAMTEN BILDSCHIRM                ;
;----------------------------------------------------------------;
CLEAR_SCREEN   PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    XOR     AL,AL          ;GESAMMTES FENSTER LOESCHEN
    XOR     CX,CX          ;ECKE OBEN LINKS   : ( 0, 0)
    MOV     DH,24          ;ECKE UNTEN RECHTS : (24,79)
    MOV     DL,79
    MOV     BH,7           ;BENUTZE NORMALES ATTRIBUT 
    MOV     AH,6           ;AUFRUF DER SROLL-FUNKTION
    INT     10H            ;ROM BIOS ERLEDIGT DIE ARBEIT
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
CLEAR_SCREEN   ENDP
;================================================================;


;================================================================;
CODE_SEG  ENDS
     END
;================================================================;
; THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.              ;
; (C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.         ;
;================================================================;     