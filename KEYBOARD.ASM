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
; FILENAME:             KEYBOARD.ASM                             ;
;----------------------------------------------------------------;
; THIS FILE CONTAINS THE PROCEDURES FOR KEYBOARD INPUT:          ;
;                                                                ;
; READ_CHAR             READ A CHARACTER FROM THE KEYBOARD       ;
; STRING_TO_UPPER       CONVERT A STRING TO UPPERCASE LETTERS    ;
; CHAR_TO_UPPER         CONVERT A CHARACTER TO UPPERCASE         ;
; READ_STRING           READ A STRING                            ;
; READ_DECIMAL          READ A DECIMAL NUMBER                    ;
; READ_BYTE             READ A SINGLE BYTE                       ;
; HEX_TO_BYTE           CONVERT TWO CHARACTERS INTO ONE HEX BYTE ;
; CONVERT_HEX_DIGIT     CONVERT A HEX DIGIT INTO A HALF-BYTE     ;
;================================================================;

;-----------------------------------------------------------------
; LABEL CODE SEGMENT AND DATA SEGMENT AND LINK THEM TO A 'SINGLE' 
; 64 KBYTE SEGMENT WITH THE NAME 'CGROUP'. SEE PNAB, K14, S156
;-----------------------------------------------------------------
CGROUP      GROUP     CODE_SEG, DATA_SEG
            ASSUME    CS:CGROUP, DS:CGROUP
    
BS          EQU  8              ;BACKSPACE
CR          EQU  13             ;CARRIAGE RETURN
ESCAPE      EQU  27             ;ESCAPE

DATA_SEG  SEGMENT PUBLIC
KEY_BOARD_INPUT     LABEL     BYTE
CHAR_NUM_LIMIT      DB   0              ;LŽNGE DES EINGABEPUFFERS
NUM_CHARS_READ      DB   0              ;ANZAHL DER EINGELESENEN ZEICHEN
CHARS               DB   80 DUP (0)     ;BUFFER FšR TASTATUREINGABE
DATA_SEG  ENDS


CODE_SEG  SEGMENT PUBLIC

;================================================================;
    PUBLIC  READ_CHAR
;----------------------------------------------------------------;
; DIESE PROZEDUR LIEST EIN EINZELNES ZEICHEN VON DER TASTATUR,   ;
; OHNE EIN ECHO AN DEN BILDSCHIRM ZU SENDEN.                     ;
;                                                                ;
; ERGEBNIS:    AL   ZEICHEN, ODER 0 FšR SPEZIELLE TASTEN         ;
;              AH   ERWEITERTER CODE DER SPEZIELLEN TASTEN       ;
;                                                                ;
;----------------------------------------------------------------;
READ_CHAR   PROC NEAR
    MOV     AH,7                ;EINGABEANFORDERUNG OHNE ECHO UND
    INT     21H                 ; OHNE šBERPRšFUNG AUF CTRL_BREAK
    OR      AL,AL               ;WAR ES EINE SPEZIELLE TASTE?
    JNZ     DONE_READ_CHAR      ;NEIN: DANN SIND WIR FERTIG
    INT     21H                 ;JA: ERWEITERTEN CODE EINLESEN
    MOV     AH,AL               ;SPEICHERE IHN IN AH
    XOR     AL,AL               ;KENNUNG FšR ERWEITERTEN CODE
DONE_READ_CHAR:
    RET
READ_CHAR ENDP
;================================================================;


;================================================================;
    PUBLIC  STRING_TO_UPPER
;----------------------------------------------------------------;
; DIESE PROZEDUR WANDELT EINE IM DOS FORMAT VORLIEGENDE          ;
; ZEICHENKETTE IN GROáBUCHSTABEN UM.                             ;
;                                                                ;
;    DS:DX     ADRESSE DES PUFFERS DER ZEICHENKETTE              ;
;                                                                ;
; BENUTZT:     CHAR_TO_UPPER                                     ;
;----------------------------------------------------------------;
STRING_TO_UPPER PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    CX
    MOV     BX,DX
    INC     BX                  ;ZEIGE AUF DEN ZEICHENZŽHLER
    MOV     CL,[BX]             ;ANZAHL DER ZEICHEN IM 2. BYTE DES PUFFERS
    XOR     CH,CH               ;OBERES BYTE DES ZŽHLERS L™SCHEN
UPPER_LOOP:
    INC     BX                  ;ZEIGE AUF DAS NŽCHSTE ZEICHEN IM PUFFER
    MOV     AL,[BX]             ;HOLE EIN ZEICHEN DER ZEICHENKETTE
    CALL    CHAR_TO_UPPER       ;IN GROáBUCHSTABEN UMWANDELN
    MOV     [BX],AL             ;SCHREIBE ZEICHEN IN ZEICHENKETTE ZURšCK
    LOOP    UPPER_LOOP
    POP     CX
    POP     BX
    POP     AX
    RET
STRING_TO_UPPER     ENDP
;================================================================;


;================================================================;
    PUBLIC    CHAR_TO_UPPER
;----------------------------------------------------------------;
; DIESE PROZEDUR WANDELT EIN EINZELNES ZEICHEN IN EINEN          ;
; GROáBUCHSTABEN UM.                                             ;
;                                                                ;
; EINGABE:     AL   UMZUWANDELNDES ZEICHEN                       ;
; AUSGABE:     AL   ENTSPRECHENDER GROáBUCHSTABE                 ;
;----------------------------------------------------------------;
CHAR_TO_UPPER   PROC NEAR
    CMP     AL,'A'              ;IST DIES EIN KLEINBUCHSTABE?
    JB      NOT_LOWER           ;NEIN: DANN SIND WIR FERTIG
    CMP     AL,'Z'              ;IST DIES EIN KLEINBUCHSTABE?
    JA      NOT_LOWER           ;NEIN: DANN SIND WIR FERTIG
    ADD     AL,'A'-'A'          ;IN GROáBUCHSTABE UMWANDELN
NOT_LOWER:
    RET
CHAR_TO_UPPER   ENDP
;================================================================;


;================================================================;
    PUBLIC  READ_STRING
    EXTRN   WRITE_CHAR:NEAR
;----------------------------------------------------------------;
; DIESE PROZEDUR ARBEIT ŽHNLICH WIE DIE DOS FUNKTION 0AH.        ;
; ALLERDINGS GIBT SIE EIN BESONDERES ZEICHEN - UND NICHT DEN     ;
; TASTATURSCHLšSSEL - ZURšCK WENN EINE FUNKTIONSTASTE ODER EINE  ;
; TASTE DES CURSOR-BLOCKS BETŽTIGT WURDE. ESC L™SCHT DIE EINGABE ;
; UND FORDERT EIN NEUE EINGABE AN.                               ;
;                                                                ;
;    DS:DX     ADRESSE DES TASTATUR PUFFERS. DAS ERSTE BYTE MUá  ;
;              DIE ANZAHL DER MAXIMAL EINZULESENDEN ZEICHEN      ;
;              (INCL. EIN BYTE FšR DIE [RETURN]) ENTHALTEN. DAS  ;
;              ZWEITE BYTE WIRD VON DER PROZEDUR ZUR RšCKMELDUNG ;
;              BENUTZT:                                          ;
;                   0    KEIN ZEICHEN EINGELESEN                 ;
;                  -1    EIN SPEZIELLES ZEICHEN EINGELESEN       ;
;                   ANSONSTEN ANZAHL DER EINGELESENEN ZEICHEN    ;
;                                                                ;
; BENUTZT:     READ_CHAR, BACK_SPACE, WRITE_CHAR                 ;
;----------------------------------------------------------------;
READ_STRING PROC NEAR
    PUSH    AX
    PUSH    BX
    PUSH    SI
    MOV     SI,DX                    ;BENUTZE SI ALS INDEX-REGISTER UND
START_OVER:
    MOV     BX,2                     ; BX FšR DEN OFFSET ZUM PUFFERSTART
    CALL    READ_CHAR
    OR      AL,AL                    ;ERWEITERTER ASCII CODE?
    JZ      EXTENDED                 ;JA: DEMENTSPRECHEND BEHANDELN
NOT_EXTENDED:
    CMP     AL,CR                    ;IST ZEICHEN CARRIAGE-RETURN
    JE      END_INPUT                ;JA: WIR SIND MIT DER EINGABE FERTIG
    CMP     AL,BS                    ;IST ES EIN BACKSPACE?
    JNE     NOT_BS                   ;NEE
    CALL    BACK_SPACE               ;JA: ZEICHEN L™SCHEN
    CMP     BL,2                     ;IST DER PUFFER LEER?
    JE      START_OVER               ;JA: NOCHMAL ERW. ASCII CODE EINLESEN
    JMP     SHORT READ_NEXT_CHAR     ;NEIN: WIEDER NORMALE ZEICHEN EINLESEN
NOT_BS:     CMP  AL,ESCAPE           ;IST ES EIN ESC ?
    JE      PURGE_BUFFER             ;JA: PUFFER L™SCHEN
    CMP     BL,[SI]                  ;šBERPRšFE, OB DER PUFFER VOLL IST
    JA      BUFFER_FULL              ;PUFFER IST VOLL
    MOV     [SI+BX],AL               ;SONST ZEICHEN IN PUFFER SPEICHERN
    INC     BX                       ;ZEIGE AUF DIE NŽCHSTE FREIE STELLE
    PUSH    DX
    MOV     DL,AL                    ;ECHO DES ZEICHENS ZUM BILDSCHIRM
    CALL    WRITE_CHAR
    POP     DX
READ_NEXT_CHAR:
    CALL    READ_CHAR
    OR      AL,AL                    ;EIN ERWEITERTES ASCII ZEICHEN IST 
                                     ;NUR BEI LEEREM PUFFER ERLAUBT
    JNZ     NOT_EXTENDED             ;ZEICHEN IST GšLTIG
                                     ;ERWEITERTES ZEICHEN, MELDE FEHLER

;----------------------------------------------------------------;
; MELDET DAS AUFTRETEN EINES FEHLER, INDEM ES EINEN SIGNALTON    ;
; ZUM BILDSCHIRM SCHICKT: 07H                                    ;
;----------------------------------------------------------------;
SIGNAL_ERROR:
    PUSH    DX
    MOV     DL,7                     ;BETŽTIGE DEN SUMMER
    MOV     AH,2
    INT     21H
    POP     DX
    JMP     SHORT READ_NEXT_CHAR     ;JETZT NŽCHSTES ZEICHEN EINLESEN

;----------------------------------------------------------------;
; L™SCHT DEN PUFFER DER ZEICHENKETTE UND DIE EINGEGEBENEN        ;
; ZEICHEN AUF DEM BILDSCHIRM.                                    ;
;----------------------------------------------------------------;
PURGE_BUFFER:
    PUSH    CX
    MOV     CL,[SI]
    XOR     CH,CH
PURGE_LOOP:
    CALL    BACK_SPACE  ;BACK_SPACE BEWAHRT DEN CURSOR DAVOR,
    LOOP    PURGE_LOOP  ; ZU WEIT ZURšCK BEWEGT ZU WERDEN

    POP     CX
    JMP     START_OVER  ;JETZT K™NNEN ERWEITERTE ASCII ZEICHEN
                        ; EINGELESEN WERDEN, DA DER PUFFER LEER IST

;----------------------------------------------------------------;
; DER PUFFER WAR VOLL UND SO KONNTEN KEINE WEITEREN ZEICHEN MEHR ;
; EINGELESEN WERDEN. L™SE EINEN SUMMTON AUS, UM DEN BENUTZER ZU  ;
; WARNEN.                                                        ;
;----------------------------------------------------------------;
BUFFER_FULL:
    JMP     SHORT SIGNAL_ERROR  ;WENN PUFFER VOLL IST, SUMMTON AUSL™SEN

;----------------------------------------------------------------;
; LIEST DEN ERWEITERTEN ASCII CODE EIN UND LEGT IHN ALS EINZIGES ;
; ZEICHEN IM PUFFER AB, UND GIBT DANN EINE -1 ALS ANZAHL DER     ;
; EINGELESENEN ZEICHEN ZURšCK.                                   ;
;----------------------------------------------------------------;
EXTENDED:
    MOV     [SI+2],AH           ;PLAZIERT DEN CODE IN DEN PUFFER
    MOV     BL,0FFH             ;-1 ALS KENNUNG FšR SPEZIELLE TASTE
    JMP     SHORT END_STRING

;----------------------------------------------------------------;
; SICHERT DIE ANZAHL DER EINGELESENEN ZEICHEN UND KEHRT ZURšCK.  ;
;----------------------------------------------------------------;
END_INPUT:              ;FERTIG MIT EINLESEN
    SUB     BL,2        ;ANZAHL DER EINGELESENEN ZEICHEN
END_STRING:
    MOV     [SI+1],BL   ;šBERGEBE ANZAHL DER EINGELESENEN ZEICHEN
    POP     SI
    POP     BX
    POP     AX
    RET
READ_STRING     ENDP
;================================================================;


;================================================================;
    PUBLIC    BACK_SPACE
    EXTRN     WRITE_CHAR:NEAR
;----------------------------------------------------------------;
; DIESE PROZEDUR L™SCHT ZEICHEN FšR ZEICHEN AUS DEM PUFFER UND   ;
; VOM BILDSCHIRM, WENN DER PUFFER NICHT LEER IST. SIE KEHRT      ;
; ZURšCK WENN DER PUFFER LEER IST.                               ;
;                                                                ;
;    DS:SI+BX  'JšNGSTE' ZEICHEN IM PUFFER                       ;
;                                                                ;
; BENUTZT:     WRITE_CHAR                                        ;
;----------------------------------------------------------------;
BACK_SPACE     PROC NEAR      ;L™SCHE EIN ZEICHEN
    PUSH    AX
    PUSH    DX
    CMP     BX,2                ;IST DER PUFFER LEER?
    JE      END_BS              ;JA: NŽCHSTES ZEICHEN EINLESEN
    DEC     BX                  ;L™SCHE EIN ZEICHEN AUS DEM PUFFER
    MOV     AH,2                ;L™SCHE EIN ZEICHEN VOM BILDSCHIRM
    MOV     DL,BS
    INT     21H
    MOV     DL,20H              ;SCHREIBE DORT EIN LEERZEICHEN
    CALL    WRITE_CHAR
    MOV     DL,BS               ;GEH WIEDER ZURšCK
    INT     21H
END_BS:     POP  DX
    POP     AX
    RET
BACK_SPACE  ENDP
;================================================================;


;================================================================;
    PUBLIC  READ_DECIMAL
;----------------------------------------------------------------;
; DIESE PROZEDUR WANDELT DIE DEZIMALE ZEICHENKETTE AUS DEM       ;
; AUSGABE-PUFFER VON READ_STRING IN EIN WORT (2 BYTE) UM.        ;
;                                                                ;
;    AX   ERGEBNIS                                               ;
;    CF   WIRD BEI FEHLER GESETZT, SONST GEL™SCHT                ;
;                                                                ;
; BENUTZT:     READ_STRING                                       ;
; LIEST:       KEY_BOARD_INPUT, ETC.                             ;
;----------------------------------------------------------------;
READ_DECIMAL   PROC NEAR
    PUSH    BX
    PUSH    CX
    PUSH    DX
    MOV     CHAR_NUM_LIMIT,6    ;MAXIMAL 5 ZIFFERN (65535)
    LEA     DX,KEY_BOARD_INPUT
    CALL    READ_STRING
    MOV     CL,NUM_CHARS_READ   ;HOLE DIE ANZAHL DER EINGELESENEN ZIFFERN
    XOR     CH,CH               ;OBERES BYTE DES ZŽHLERS L™SCHEN
    CMP     CL,0                ;MELDE FEHLER, FALLS KEINE ZIFFER EINGELESEN
    JLE     BAD_DECIMAL_DIGIT   ;NICHTS EINGELESEN, MELDE FEHLER
    XOR     AX,AX               ;SETZE AX AUF NULL
    XOR     BX,BX               ;STARTE BEIM ANFANG DER ZIFFERNKETTE
CONVERT_DIGIT:
    MOV     DX,10               ;MULTIPLIKATION MIT 10
    MUL     DX                  ;MULTIPLIZIERE AX MIT 10
    JC      BAD_DECIMAL_DIGIT   ;BEI šBERLAUF CARRY-FLAG SETZEN
    MOV     DL,CHARS[BX]        ;HOLE DIE NŽCHSTE ZIFFER
    SUB     DL,'0'              ;ENTFERNE DIE OBERSTEN 4 BIT
    JS      BAD_DECIMAL_DIGIT   ;KEINE ZIFFER FALLS < 0
    CMP     DL,9                ;IST DIES KEINE ZAHL?
    JA      BAD_DECIMAL_DIGIT   ;JA
    ADD     AX,DX               ;NEIN: ZUM ERGEBNIS ADDIEREN
    INC     BX                  ;ZEIGE AUF NŽCHSTES ZEICHEN
    LOOP    CONVERT_DIGIT       ;HOLE DIE NŽCHSTE ZAHL
DONE_DECIMAL:
    POP     DX
    POP     CX
    POP     BX
    RET
BAD_DECIMAL_DIGIT:
    STC                      ;SETZE CARRY-FLAG UM FEHLER ZU MELDEN
    JMP     DONE_DECIMAL
READ_DECIMAL    ENDP
;================================================================;


;================================================================;
    PUBLIC  READ_BYTE
;----------------------------------------------------------------;
; DIESE PROZEDUR LIEST AUCH EIN EINZELNES ASCII ZEICHEN EIN.     ;
; ES IST EINE TESTVERSION VON READ_BYTE !                        ;
;                                                                ;
; ERGEBNIS     AL   ZEICHENSCHLšSSEL (WENN AH <> 0)              ;
;              AH   1 FALLS ASCII ZEICHEN EINGELESEN             ;
;                   0 FALLS KEIN ZEICHEN EINGELESEN WURDE        ;
;                  -1 FALLS SPEZIELLE TASTE EINGELESEN           ;
;                                                                ;
; BENUTZT:     HEX_TO_BYTE, STRING_TO_UPPER, READ_STRING         ;
; LIEST:       KEY_BOARD_INPUT, ETC.                             ;
;----------------------------------------------------------------;
READ_BYTE PROC NEAR
    PUSH    DX
    MOV     CHAR_NUM_LIMIT,3    ;NUR 2 ZEICHEN ERLAUBT (+ CR)
    LEA     DX,KEY_BOARD_INPUT
    CALL    READ_STRING
    CMP     NUM_CHARS_READ,1    ;UNTERSUCHE WIEVIELE ZEICHEN
    JE      ASCII_INPUT         ;NUR EINS, ALS ASCII ZEICHEN BEHANDELN
    JB      NO_CHARACTERS       ;NUR EINGABETASTE BETŽTIGT
    CMP     NUM_CHARS_READ,0FFH ;SPEZIELLE TASTE BETŽTIGT?
    JE      SPECIAL_KEY         ;JA
    CALL    STRING_TO_UPPER     ;NEIN: IN GROáBUCHSTABEN UMWANDELN
    LEA     DX,CHARS            ;ADRESSE DER UMZUWANDELNDEN ZEICHENKETTE
    CALL    HEX_TO_BYTE         ;WANDEL HEX-ZEICHENKETTE IN BYTE UM
    JC      NO_CHARACTERS       ;FEHLER, GEBE 'NICHTS EINGELESEN' ZURšCK
    MOV     AH,1                ;MELDE EIN EINGELESENES ZEICHEN
DONE_READ:
    POP     DX
    RET
NO_CHARACTERS:
    XOR     AH,AH               ;MELDE 'KEIN ZEICHEN EINGELESEN'
    JMP     DONE_READ
ASCII_INPUT:
    MOV     AL,CHARS            ;LADE EINGELESENES ZEICHEN
    MOV     AH,1                ;MELDE EIN EINGELESENES ZEICHEN
    JMP     DONE_READ
SPECIAL_KEY:
    MOV     AL,CHARS[0]         ;šBERGEBE DEN SCAN-CODE
    MOV     AH,0FFH             ;MELDE EINE SPEZIELLE TASTE
    JMP     DONE_READ
READ_BYTE   ENDP
;================================================================;


;================================================================;
    PUBLIC  HEX_TO_BYTE
;----------------------------------------------------------------;
; DIESE PROZEDUR WANDELT ZWEI HEX-ZEICHEN IN EIN BYTE UM.        ;
;                                                                ;
;    DS:DX     ADRESSE DER BEIDEN HEX-ZEICHEN                    ;
;                                                                ;
;    ERGEBNIS: AL   BYTE                                         ;
;              CF   BEI FEHLER GESETZT, SONST GEL™SCHT           ;
;              AH   VERŽNDERT                                    ;
;                                                                ;
; BENUTZT      CONVERT_HEX_DIGIT                                 ;
;----------------------------------------------------------------;
HEX_TO_BYTE    PROC NEAR
    PUSH    BX
    PUSH    CX
    MOV     BX,DX               ;LADE BX UM INDIREKT ZU ADRESSIEREN
    MOV     AL,[BX]             ;HOLE ERSTE ZIFFER
    CALL    CONVERT_HEX_DIGIT
    JC      BAD_HEX             ;KEINE HEX-ZIFFER WENN CARRY GESETZT IST
    MOV     CX,4                ;JETZT MIT 16 MULTIPLIZIEREN
    SHL     AL,CL
    MOV     AH,AL               ;LEGE EIN KOPIE AN
    INC     BX                  ;HOLE DIE ZWEITE ZIFFER
    MOV     AL,[BX]
    CALL    CONVERT_HEX_DIGIT
    JC      BAD_HEX             ;KEINE HEX-ZIFFER WENN CARRY GESETZT IST
    OR      AL,AH               ;FšGE DIE ZWEI HALB-BYTES ZUSAMMEN
    CLC                         ;L™SCHE CARRY-FLAG, DA FEHLERFREI
DONE_HEX:
    POP     CX
    POP     BX
    RET
BAD_HEX:
    STC                         ;SETZE CARRY-FLAG, DA FEHLER AUFGETRETEN
    JMP     DONE_HEX
HEX_TO_BYTE    ENDP
;================================================================;


;================================================================;
    PUBLIC  CONVERT_HEX_DIGIT
;----------------------------------------------------------------;
; DIESE PROZEDUR WANDELT EIN ASCII HEX-ZEICHEN IN EIN HALB-BYTE  ;
; (4 BIT)                                                        ;
; UM.                                                            ;
;                                                                ;
;              AL   UMZUWANDELNDES ZEICHEN                       ;
; ERGEBNIS:    AL   HALB-BYTE                                    ;
;              CF   BEI FEHLER GESETZT, SONST GEL™SCHT           ;
;----------------------------------------------------------------;
CONVERT_HEX_DIGIT   PROC NEAR
    CMP     AL,'0'              ;IST ES EINE ERLAUBTE ZIFFER?
    JB      BAD_DIGIT           ;NEE
    CMP     AL,'9'              ;NOCH NICHT GANZ SICHER
    JA      TRY_HEX             ;K™NNTE NOCH EINE HEX-ZIFFER SEIN
    SUB     AL,'0'              ;ES IST EINE DEZIMALZAHL, UMWANDELN
    CLC                         ;L™SCHE CARRY-FLAG, KEIN FEHLER AUFGETRETEN
    RET
TRY_HEX:
    CMP     AL,'A'              ;NOCH NICHT SICHER
    JB      BAD_DIGIT           ;KEINE HEX-ZIFFER
    CMP     AL,'F'              ;NOCH NICHT SICHER
    JA      BAD_DIGIT           ;KEINE HEX-ZIFFER
    SUB     AL,'A'-10           ;IST HEX-ZIFFER, UMWANDELN
    CLC                         ;L™SCHE CARRY-FLAG, KEIN FEHLER AUFGETRETEN
    RET
BAD_DIGIT:
    STC                         ;SETZE CARRY-FLAG, FEHLER AUFGETRETEN
    RET
CONVERT_HEX_DIGIT   ENDP
;================================================================;


;================================================================;
CODE_SEG    ENDS
        END
;================================================================;
; THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.              ;
; (C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.         ;
;================================================================;