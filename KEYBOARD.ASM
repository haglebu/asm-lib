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
    
CODE_SEG    SEGMENT PUBLIC
BS      EQU  8              ;Backspace-Zeichen
CR      EQU  13             ;Wagenr¸cklauf-Zeichen (Carriage return)
ESCAPE  EQU  27             ;Flucht-Zeichen (Escape)

DATA_SEG  SEGMENT PUBLIC
KEY_BOARD_INPUT     LABEL     BYTE
CHAR_NUM_LIMIT      DB   0              ;L‰nge des Eingabepuffers
NUM_CHARS_READ      DB   0              ;Anzahl der eingelesenen Zeichen
CHARS               DB   80 DUP (0)     ;Buffer f¸r Tastatureingabe
DATA_SEG  ENDS


CODE_SEG  SEGMENT PUBLIC

;================================================================;
     PUBLIC    READ_CHAR
;----------------------------------------------------------------;
; Diese Prozedur liest ein einzelnes Zeichen von der Tastatur,   ;
; ohne ein Echo an den Bildschirm zu senden.                     ;
;                                                                ;
; Ergebnis:    AL   Zeichen, oder 0 fÅr spezielle Tasten         ;
;              AH   Erweiterter Code der speziellen Tasten       ;
;                                                                ;
;----------------------------------------------------------------;
READ_CHAR PROC NEAR
     MOV  AH,7                ;Eingabeanforderung ohne Echo und
     INT  21h                 ; ohne öberprÅfung auf CTRL_BREAK
     OR   AL,AL               ;War es eine spezielle Taste?
     JNZ  DONE_READ_CHAR      ;Nein: dann sind wir fertig
     INT  21h                 ;Ja: erweiterten Code einlesen
     MOV  AH,AL               ;Speichere ihn in AH
     XOR  AL,AL               ;Kennung fÅr erweiterten Code
DONE_READ_CHAR:
     RET
READ_CHAR ENDP
;================================================================;


;================================================================;
     PUBLIC    STRING_TO_UPPER
;----------------------------------------------------------------;
; Diese Prozedur wandelt eine im DOS Format vorliegende          ;
; Zeichenkette in Gro·buchstaben um.                             ;
;                                                                ;
;    DS:DX     Adresse des Puffers der Zeichenkette              ;
;                                                                ;
; Benutzt:     CHAR_TO_UPPER                                     ;
;----------------------------------------------------------------;
STRING_TO_UPPER          PROC NEAR
     PUSH AX
     PUSH BX
     PUSH CX
     MOV  BX,DX
     INC  BX                  ;Zeige auf den ZeichenzÑhler
     MOV  CL,[BX]             ;Anzahl der Zeichen im 2. Byte des Puffers
     XOR  CH,CH               ;Oberes Byte des ZÑhlers lîschen
UPPER_LOOP:
     INC  BX                  ;Zeige auf das nÑchste Zeichen im Puffer
     MOV  AL,[BX]             ;Hole ein Zeichen der Zeichenkette
     CALL CHAR_TO_UPPER       ;In Gro·buchstaben umwandeln
     MOV  [BX],AL             ;Schreibe Zeichen in Zeichenkette zurÅck
     LOOP UPPER_LOOP
     POP  CX
     POP  BX
     POP  AX
     RET
STRING_TO_UPPER          ENDP
;================================================================;


;================================================================;
     PUBLIC    CHAR_TO_UPPER
;----------------------------------------------------------------;
; Diese Prozedur wandelt ein einzelnes Zeichen in einen          ;
; Gro·buchstaben um.                                             ;
;                                                                ;
; Eingabe:     AL   umzuwandelndes Zeichen                       ;
; Ausgabe:     AL   entsprechender Gro·buchstabe                 ;
;----------------------------------------------------------------;
CHAR_TO_UPPER  PROC NEAR
     CMP  AL,'a'              ;Ist dies ein Kleinbuchstabe?
     JB   NOT_LOWER           ;Nein: dann sind wir fertig
     CMP  AL,'z'              ;Ist dies ein Kleinbuchstabe?
     JA   NOT_LOWER           ;Nein: dann sind wir fertig
     ADD  AL,'A'-'a'          ;In Gro·buchstabe umwandeln
NOT_LOWER:
     RET
CHAR_TO_UPPER  ENDP
;================================================================;


;================================================================;
     PUBLIC    READ_STRING
     EXTRN     WRITE_CHAR:NEAR
;----------------------------------------------------------------;
; Diese Prozedur arbeit Ñhnlich wie die DOS Funktion 0AH.        ;
; Allerdings gibt sie ein besonderes Zeichen - und nicht den     ;
; TastaturschlÅssel - zurÅck wenn eine Funktionstaste oder eine  ;
; Taste des Cursor-Blocks betÑtigt wurde. ESC lîscht die Eingabe ;
; und fordert ein neue Eingabe an.                               ;
;                                                                ;
;    DS:DX     Adresse des Tastatur Puffers. Das erste Byte mu·  ;
;              die Anzahl der maximal einzulesenden Zeichen      ;
;              (incl. ein Byte fÅr die [RETURN]) enthalten. Das  ;
;              zweite Byte wird von der Prozedur zur RÅckmeldung ;
;              benutzt:                                          ;
;                   0    Kein Zeichen eingelesen                 ;
;                  -1    Ein spezielles Zeichen eingelesen       ;
;                   ansonsten Anzahl der eingelesenen Zeichen    ;
;                                                                ;
; Benutzt:     READ_CHAR, BACK_SPACE, WRITE_CHAR                 ;
;----------------------------------------------------------------;
READ_STRING    PROC NEAR
     PUSH AX
     PUSH BX
     PUSH SI
     MOV  SI,DX                    ;Benutze SI als Index-Register und
START_OVER:
     MOV  BX,2                     ; BX fÅr den Offset zum Pufferstart
     CALL READ_CHAR
     OR   AL,AL                    ;Erweiterter ASCII Code?
     JZ   EXTENDED                 ;Ja: dementsprechend behandeln
NOT_EXTENDED:
     CMP  AL,CR                    ;Ist Zeichen Carriage-Return
     JE   END_INPUT                ;Ja: wir sind mit der Eingabe fertig
     CMP  AL,BS                    ;Ist es ein Backspace?
     JNE  NOT_BS                   ;Nee
     CALL BACK_SPACE               ;Ja: Zeichen lîschen
     CMP  BL,2                     ;Ist der Puffer leer?
     JE   START_OVER               ;Ja: Nochmal erw. ASCII Code einlesen
     JMP  SHORT READ_NEXT_CHAR     ;Nein: wieder normale Zeichen einlesen
NOT_BS:   CMP  AL,ESCAPE           ;Ist es ein ESC ?
     JE   PURGE_BUFFER             ;Ja: Puffer lîschen
     CMP  BL,[SI]                  ;öberprÅfe, ob der Puffer voll ist
     JA   BUFFER_FULL              ;Puffer ist voll
     MOV  [SI+BX],AL               ;Sonst Zeichen in Puffer speichern
     INC  BX                       ;Zeige auf die nÑchste freie Stelle
     PUSH DX
     MOV  DL,AL                    ;Echo des Zeichens zum Bildschirm
     CALL WRITE_CHAR
     POP  DX
READ_NEXT_CHAR:
     CALL READ_CHAR
     OR   AL,AL                    ;Ein erweitertes ASCII Zeichen ist 
                                   ;nur bei leerem Puffer erlaubt
     JNZ  NOT_EXTENDED             ;Zeichen ist gÅltig
                                   ;erweitertes Zeichen, melde Fehler

;----------------------------------------------------------------;
; Meldet das Auftreten eines Fehler, indem es einen Signalton    ;
; zum Bildschirm schickt: 07H                                    ;
;----------------------------------------------------------------;
SIGNAL_ERROR:
     PUSH DX
     MOV  DL,7                     ;BetÑtige den Summer
     MOV  AH,2
     INT  21H
     POP  DX
     JMP  SHORT READ_NEXT_CHAR     ;Jetzt nÑchstes Zeichen einlesen

;----------------------------------------------------------------;
; Lîscht den Puffer der Zeichenkette und die eingegebenen        ;
; Zeichen auf dem Bildschirm.                                    ;
;----------------------------------------------------------------;
PURGE_BUFFER:
     PUSH CX
     MOV  CL,[SI]
     XOR  CH,CH
PURGE_LOOP:
     CALL BACK_SPACE          ;BACK_SPACE bewahrt den Cursor davor,
     LOOP PURGE_LOOP          ; zu weit zurÅck bewegt zu werden

     POP  CX
     JMP  START_OVER          ;Jetzt kînnen erweiterte ASCII Zeichen
                              ; eingelesen werden, da der Puffer leer ist

;----------------------------------------------------------------;
; Der Puffer war voll und so konnten keine weiteren Zeichen mehr ;
; eingelesen werden. Lîse einen Summton aus, um den Benutzer zu  ;
; warnen.                                                        ;
;----------------------------------------------------------------;
BUFFER_FULL:
     JMP  SHORT SIGNAL_ERROR  ;Wenn Puffer voll ist, Summton auslîsen

;----------------------------------------------------------------;
; Liest den erweiterten ASCII Code ein und legt ihn als einziges ;
; Zeichen im Puffer ab, und gibt dann eine -1 als Anzahl der     ;
; eingelesenen Zeichen zurÅck.                                   ;
;----------------------------------------------------------------;
EXTENDED:
     MOV  [SI+2],AH           ;Plaziert den Code in den Puffer
     MOV  BL,0FFH             ;-1 als Kennung fÅr spezielle Taste
     JMP  SHORT END_STRING

;----------------------------------------------------------------;
; Sichert die Anzahl der eingelesenen Zeichen und kehrt zurÅck.  ;
;----------------------------------------------------------------;
END_INPUT:                    ;Fertig mit einlesen
     SUB  BL,2                ;Anzahl der eingelesenen Zeichen
END_STRING:
     MOV  [SI+1],BL           ;öbergebe Anzahl der eingelesenen Zeichen
     POP  SI
     POP  BX
     POP  AX
     RET
READ_STRING    ENDP
;================================================================;


;================================================================;
     PUBLIC    BACK_SPACE
     EXTRN     WRITE_CHAR:NEAR
;----------------------------------------------------------------;
; Diese Prozedur lîscht Zeichen fÅr Zeichen aus dem Puffer und   ;
; vom Bildschirm, wenn der Puffer nicht leer ist. Sie kehrt      ;
; zurÅck wenn der Puffer leer ist.                               ;
;                                                                ;
;    DS:SI+BX  'jÅngste' Zeichen im Puffer                       ;
;                                                                ;
; Benutzt:     WRITE_CHAR                                        ;
;----------------------------------------------------------------;
BACK_SPACE     PROC NEAR      ;Lîsche ein Zeichen
     PUSH AX
     PUSH DX
     CMP  BX,2                ;Ist der Puffer leer?
     JE   END_BS              ;Ja: nÑchstes Zeichen einlesen
     DEC  BX                  ;lîsche ein Zeichen aus dem Puffer
     MOV  AH,2                ;lîsche ein Zeichen vom Bildschirm
     MOV  DL,BS
     INT  21H
     MOV  DL,20H              ;Schreibe dort ein Leerzeichen
     CALL WRITE_CHAR
     MOV  DL,BS               ;geh wieder zurÅck
     INT  21H
END_BS:   POP  DX
     POP  AX
     RET
BACK_SPACE     ENDP
;================================================================;


;================================================================;
     PUBLIC    READ_DECIMAL
;----------------------------------------------------------------;
; Diese Prozedur wandelt die dezimale Zeichenkette aus dem       ;
; Ausgabe-Puffer von READ_STRING in ein Wort (2 Byte) um.        ;
;                                                                ;
;    AX   Ergebnis                                               ;
;    CF   wird bei Fehler gesetzt, sonst gelîscht                ;
;                                                                ;
; Benutzt:     READ_STRING                                       ;
; Liest:       KEY_BOARD_INPUT, etc.                             ;
;----------------------------------------------------------------;
READ_DECIMAL   PROC NEAR
     PUSH BX
     PUSH CX
     PUSH DX
     MOV  CHAR_NUM_LIMIT,6    ;Maximal 5 Ziffern (65535)
     LEA  DX,KEY_BOARD_INPUT
     CALL READ_STRING
     MOV  CL,NUM_CHARS_READ   ;Hole die Anzahl der eingelesenen Ziffern
     XOR  CH,CH               ;Oberes Byte des ZÑhlers lîschen
     CMP  CL,0                ;melde Fehler, falls keine Ziffer eingelesen
     JLE  BAD_DECIMAL_DIGIT   ;nichts eingelesen, melde Fehler
     XOR  AX,AX               ;Setze AX auf Null
     XOR  BX,BX               ;Starte beim Anfang der Ziffernkette
CONVERT_DIGIT:
     MOV  DX,10               ;Multiplikation mit 10
     MUL  DX                  ;Multipliziere AX mit 10
     JC   BAD_DECIMAL_DIGIT   ;bei öberlauf Carry-Flag setzen
     MOV  DL,CHARS[BX]        ;Hole die nÑchste Ziffer
     SUB  DL,'0'              ;Entferne die obersten 4 Bit
     JS   BAD_DECIMAL_DIGIT   ;Keine Ziffer falls < 0
     CMP  DL,9                ;Ist dies keine Zahl?
     JA   BAD_DECIMAL_DIGIT   ;Ja
     ADD  AX,DX               ;Nein: zum Ergebnis addieren
     INC  BX                  ;Zeige auf nÑchstes Zeichen
     LOOP CONVERT_DIGIT       ;Hole die nÑchste Zahl
DONE_DECIMAL:
     POP  DX
     POP  CX
     POP  BX
     RET
BAD_DECIMAL_DIGIT:
     STC                      ;Setze Carry-Flag um Fehler zu melden
     JMP  DONE_DECIMAL
READ_DECIMAL   ENDP
;================================================================;


;================================================================;
     PUBLIC    READ_BYTE
;----------------------------------------------------------------;
; Diese Prozedur liest auch ein einzelnes ASCII Zeichen ein.     ;
; Es ist eine Testversion von READ_BYTE !                        ;
;                                                                ;
; Ergebnis     AL   ZeichenschlÅssel (wenn AH <> 0)              ;
;              AH   1 falls ASCII Zeichen eingelesen             ;
;                   0 falls kein Zeichen eingelesen wurde        ;
;                  -1 falls spezielle Taste eingelesen           ;
;                                                                ;
; Benutzt:     HEX_TO_BYTE, STRING_TO_UPPER, READ_STRING         ;
; Liest:       KEY_BOARD_INPUT, etc.                             ;
;----------------------------------------------------------------;
READ_BYTE PROC NEAR
     PUSH DX
     MOV  CHAR_NUM_LIMIT,3    ;Nur 2 Zeichen erlaubt (+ CR)
     LEA  DX,KEY_BOARD_INPUT
     CALL READ_STRING
     CMP  NUM_CHARS_READ,1    ;Untersuche wieviele Zeichen
     JE   ASCII_INPUT         ;nur eins, als ASCII Zeichen behandeln
     JB   NO_CHARACTERS       ;Nur Eingabetaste betÑtigt
     CMP  NUM_CHARS_READ,0FFH ;Spezielle Taste betÑtigt?
     JE   SPECIAL_KEY         ;Ja
     CALL STRING_TO_UPPER     ;Nein: in Gro·buchstaben umwandeln
     LEA  DX,CHARS            ;Adresse der umzuwandelnden Zeichenkette
     CALL HEX_TO_BYTE         ;Wandel Hex-Zeichenkette in Byte um
     JC   NO_CHARACTERS       ;Fehler, gebe 'nichts eingelesen' zurÅck
     MOV  AH,1                ;Melde ein eingelesenes Zeichen
DONE_READ:
     POP  DX
     RET
NO_CHARACTERS:
     XOR  AH,AH               ;Melde 'kein Zeichen eingelesen'
     JMP  DONE_READ
ASCII_INPUT:
     MOV  AL,CHARS            ;Lade eingelesenes Zeichen
     MOV  AH,1                ;Melde ein eingelesenes Zeichen
     JMP  DONE_READ
SPECIAL_KEY:
     MOV  AL,CHARS[0]         ;öbergebe den Scan-Code
     MOV  AH,0FFH             ;Melde eine spezielle Taste
     JMP  DONE_READ
READ_BYTE ENDP
;================================================================;


;================================================================;
     PUBLIC    HEX_TO_BYTE
;----------------------------------------------------------------;
; Diese Prozedur wandelt zwei Hex-Zeichen in ein Byte um.        ;
;                                                                ;
;    DS:DX     Adresse der beiden Hex-Zeichen                    ;
;                                                                ;
;    Ergebnis: AL   Byte                                         ;
;              CF   Bei Fehler gesetzt, sonst gelîscht           ;
;              AH   verÑndert                                    ;
;                                                                ;
; Benutzt      CONVERT_HEX_DIGIT                                 ;
;----------------------------------------------------------------;
HEX_TO_BYTE    PROC NEAR
     PUSH BX
     PUSH CX
     MOV  BX,DX               ;Lade BX um indirekt zu adressieren
     MOV  AL,[BX]             ;Hole erste Ziffer
     CALL CONVERT_HEX_DIGIT
     JC   BAD_HEX             ;Keine Hex-Ziffer wenn Carry gesetzt ist
     MOV  CX,4                ;jetzt mit 16 multiplizieren
     SHL  AL,CL
     MOV  AH,AL               ;lege ein Kopie an
     INC  BX                  ;Hole die zweite Ziffer
     MOV  AL,[BX]
     CALL CONVERT_HEX_DIGIT
     JC   BAD_HEX             ;Keine Hex-Ziffer wenn Carry gesetzt ist
     OR   AL,AH               ;FÅge die zwei Halb-Bytes zusammen
     CLC                      ;Lîsche Carry-Flag, da fehlerfrei
DONE_HEX:
     POP  CX
     POP  BX
     RET
BAD_HEX:
     STC                      ;Setze Carry-Flag, da Fehler aufgetreten
     JMP  DONE_HEX
HEX_TO_BYTE    ENDP
;================================================================;


;================================================================;
     PUBLIC    CONVERT_HEX_DIGIT
;----------------------------------------------------------------;
; Diese Prozedur wandelt ein ASCII HEX-Zeichen in ein Halb-Byte  ;
; (4 Bit)                                                        ;
; um.                                                            ;
;                                                                ;
;              AL   umzuwandelndes Zeichen                       ;
; Ergebnis:    AL   Halb-Byte                                    ;
;              CF   Bei Fehler gesetzt, sonst gelîscht           ;
;----------------------------------------------------------------;
CONVERT_HEX_DIGIT   PROC NEAR
     CMP  AL,'0'              ;ist es eine erlaubte Ziffer?
     JB   BAD_DIGIT           ;Nee
     CMP  AL,'9'              ;Noch nicht ganz sicher
     JA   TRY_HEX             ;Kînnte noch eine Hex-Ziffer sein
     SUB  AL,'0'              ;Es ist eine Dezimalzahl, umwandeln
     CLC                      ;Lîsche Carry-Flag, kein Fehler aufgetreten
     RET
TRY_HEX:
     CMP  AL,'A'              ;Noch nicht sicher
     JB   BAD_DIGIT           ;Keine Hex-Ziffer
     CMP  AL,'F'              ;Noch nicht sicher
     JA   BAD_DIGIT           ;Keine Hex-Ziffer
     SUB  AL,'A'-10           ;Ist Hex-Ziffer, umwandeln
     CLC                      ;Lîsche Carry-Flag, kein Fehler aufgetreten
     RET
BAD_DIGIT:
     STC                      ;Setze Carry-Flag, Fehler aufgetreten
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

