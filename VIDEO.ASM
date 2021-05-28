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
; FILENAME:             VIDEO.ASM                                ;
;----------------------------------------------------------------;
; THIS FILE CONTAINS THE PROCEDURES FOR THE SCREEN OUTPUT:       ;
;                                                                ;
; WRITE_HEX          OUTPUT 2-DIGIT HEX NUMBER TO CURSOR POS.    ;
; WRITE_HEX_DIGIT    1-DIGIT HEX NUMBER ... OUTPUT               ;
; WRITE_CHAR         OUTPUT CHARACTER                            ;
; WRITE_CHAR_N_TIMES OUTPUT CHARACTER N-TIMES                    ;
; WRITE_STRING       OUTPUT STRING (LAST CHARACTER 0H)           ;
; WRITE_DECIMAL      OUTPUT 16-BIT NUMBER DECIMAL                ;
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



;================================================================;
    PUBLIC  WRITE_HEX
;----------------------------------------------------------------;
; DIESE PROZEDUR KONVERTIERT DAS BYTE IM DL-REGISTER NACH HEX    ;
; GIBT DIE ZWEISTELLIGE HEXZAHL AN DER AKTUELLEN CURSORPOSITION  ;
; AUS.                                                           ;
;                                                                ;
;        DL     BYTE DAS NACH HEX KONVERTIERT WERDEN SOLL.       ;
; VERWENDET:    WRITE_HEX_DIGIT                                  ;
;----------------------------------------------------------------;
WRITE_HEX       PROC NEAR        ;STARTPUNKT DER PROZEDUR
        PUSH    CX               ;SICHERN DER BENUTZTEN REGISTER
        PUSH    DX
        MOV     DH,DL            ;KOPIE DES BYTES ERSTELLEN 
        MOV     CX,4             ;HOLE DEN OBEREN TEIL VON DL
        SHR     DL,CL
        CALL    WRITE_HEX_DIGIT  ;AUSGABE DES 1. HEXZEICHENS
        MOV     DL,DH            ;HOLE DEN UNTEREN TEIL VON DL
        AND     DL,0FH           ;EINLADEN DES OBEREN TEILS
        CALL    WRITE_HEX_DIGIT  ;AUSGABE DES 2. HEXZEICHENS
        POP     DX
        POP     CX
        RET
WRITE_HEX       ENDP
;================================================================;



;================================================================;
    PUBLIC  WRITE_HEX_DIGIT
;----------------------------------------------------------------;
; DIESE PROZEDUR KONVERTIERT DIE VIER NIEDERWERTIGEN BIT AUS DL  ;
; IN EINE HEXZIFFER UND GIBT DIESES ZEICHEN AUF DEN BILDSCHIRM   ;
;                                                                ;
;        DL   DIE UNTEREN VIER BIT ENTHALTEN DAS AUSZUGEBENDE    ;
; VERWENDET:  WRITE_CHAR                                         ;
;----------------------------------------------------------------;
WRITE_HEX_DIGIT     PROC NEAR       
        PUSH    DX                ;SICHERN DES BENUTZEN REGISTERS
        CMP     DL,10             ;IST DIESER TEIL <10          
        JAE     HEX_LETTER        ;NEIN, KONVERTIERE IN BUCHSTABEN  
        ADD     DL,"0"            ;JA, KONVERTIERE IN ZAHL
        JMP     SHORT WRITE_DIGIT ;SCHREIBE ZEICHEN
HEX_LETTER:
        ADD     DL,"A"-10         ;KONVERTIERE IN HEXBUCHSTABEN
WRITE_DIGIT:
        CALL    WRITE_CHAR        ;BILDSCHIRMAUSGABE
        POP     DX                ;REGISTER WIEDER HERSTELLEN
        RET
WRITE_HEX_DIGIT ENDP
;================================================================;


;================================================================;
    PUBLIC      WRITE_CHAR
;----------------------------------------------------------------;
; Diese Prozedur gibt mit einem DOS-Funktionsaufruf ein Zeichen  ;
; auf den Bildschirm aus. Die ASCII-Zeichen 0 bis 1Fh werden     ;
; durch einen Punkt ersetzt.                                     ;
;                                                                ;
;       DL      auszugebendes Zeichen                            ;
;----------------------------------------------------------------;
WRITE_CHAR      PROC NEAR
        PUSH    AX               ;AX sichern
        PUSH    DX
        CMP     DL,32            ;ein ASCII-Wert vor dem Blank
        JAE     IS_PRINTABLE     ;Nein, dann Ausgabe
        MOV     DL,'.'           ;Ja, ersetze Zeichen durch Punkt
IS_PRINTABLE:
        MOV     AH,02            ;Funktion 02=Zeichenausgabe
        INT     21h              ;Ausgabe des Zeichens in DL
        POP     DX
        POP     AX               ;AX wieder herstellen
        RET                      ;Rckkehr
WRITE_CHAR      ENDP    
;================================================================;



;================================================================;
     PUBLIC    WRITE_CHAR_N_TIMES
;----------------------------------------------------------------;
; DIESE PROZEDUR SCHREIBT MEHR ALS EINE KOPIE EINES ZEICHENS.    ;
;                                                                ;
;    DL   ZEICHEN CODE                                           ;
;    CX   ANZAHL DER KOPIEN                                      ;
;                                                                ;
; BENUTZT:     WRITE_CHAR                                        ;
;----------------------------------------------------------------;
WRITE_CHAR_N_TIMES  PROC NEAR
        PUSH    CX
N_TIMES:
        CALL    WRITE_CHAR      ;SCHREIBE EINE KOPIE DES ZEICHENS
        LOOP    N_TIMES         ;SCHREIBEN N MAL WIEDERHOLEN
        POP     CX
        RET
WRITE_CHAR_N_TIMES  ENDP
;================================================================;



;================================================================;
     PUBLIC     WRITE_STRING
;----------------------------------------------------------------;
; DIESE PROZEDUR SCHREIBT EINE ZEICHENKETTE AUF DEN BILDSCHIRM.  ;
; DER STRING MU  ALS LETZTES ZEICHEN 0H ENTHALTEN.               ;
;                                                                ;
;    DS:DX      ADRESSE DER ZEICHENKETTE                         ;
;                                                                ;
; BENUTZT:      WRITE_CHAR                                       ;
;----------------------------------------------------------------;
WRITE_STRING    PROC NEAR
        PUSH    AX
        PUSH    DX
        PUSH    SI
        PUSHF                    ;RICHTUNGSFLAG SICHERN
        CLD                      ;RICHTUNG AUF VORWAERTS EINSTELLEN
        MOV     SI,DX            ;ADRESSE DES STRINGS NACH SI HOLEN
STRING_LOOP:
        LODSB                    ;HOLE EIN ZEICHEN INS AL-REGISTER
        OR      AL,AL            ;HABEN WIR DIE NULL GEFUNDEN?
        JZ      END_OF_STRING    ;JA: FERTIG MIT SCHREIBEN
        MOV     DL,AL            ;NEIN: ZEICHEN AUSGEBEN
        CALL    WRITE_CHAR       ;ZEICHEN AUSGEBEN
        JMP     STRING_LOOP      ;NAECHSTES ZEICHEN EINLESEN
END_OF_STRING:
        POPF                     ;RICHTUNGSFLAG WIEDERHERSTELLEN
        POP     SI
        POP     DX
        POP     AX
        RET
WRITE_STRING    ENDP
;================================================================;



; ===============================================================;
     PUBLIC     WRITE_DECIMAL
;----------------------------------------------------------------;
; DIESE PROZEDUR GIBT EINE 16-BIT ZAHL (VORZEICHENLOS) IN DER    ;
; DEZIMALSCHREIBWEISE AUS.                                       ;
;                                                                ;
;   DX   N :    16-BIT, VORZEICHENLOSE ZAHL                         ;
; VERWENDET:    WRITE_HEX_DIGIT                                     ;
;----------------------------------------------------------------;
WRITE_DECIMAL   PROC NEAR
        PUSH    AX              ;SICHERN DER BENUTZTEN REGISTER
        PUSH    CX
        PUSH    DX
        PUSH    SI
        MOV     AX,DX
        MOV     SI,10           ;DIVISION DURCH 10 (IN SI)
        XOR     CX,CX           ;ZAEHLER FUER ZIFFERN AUF DEM STACK
NON_ZERO:
        XOR     DX,DX           ;OBERES WORT VON N NACH 0 SETZEN
        DIV     SI              ;BERECHNE N/10 UND (N MOD 10)
        PUSH    DX              ;PUSHE EINE ZIFFER AUF DEN STACK
        INC     CX              ;ZAEHLER MITSTELLEN
        OR      AX,AX           ;IST N = 0 ?
        JNE     NON_ZERO        ;NEIN, WEITERMACHEN
WRITE_DIGIT_LOOP:
        POP     DX              ;HOLE DIE ZIFFERN IN UMGEKEHRTER REIHENFOLGE
        CALL    WRITE_HEX_DIGIT
        LOOP    WRITE_DIGIT_LOOP
END_DECIMAL:
        POP     SI
        POP     DX
        POP     CX
        POP     AX
        RET
WRITE_DECIMAL   ENDP
;================================================================;



;================================================================;
CODE_SEG    ENDS
        END
;================================================================;
; THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.              ;
; (C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.         ;
;================================================================;