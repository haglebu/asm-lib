# asm-lib
My assembler programs and library files. I use the Microsoft Assembler MASM version 5.10.

# Program Files
## mi.asm
Display media information (MI) about floppy disk in drive A:. The drive is currently static; maybe this will be changed later.

<img width="589" alt="mi" src="https://user-images.githubusercontent.com/52176362/120019902-4c1a2880-bfe9-11eb-97e1-3d1a3985ce7c.png">

## bpb.asm
Display BIOS parameter block information (BPB) of a floppy disk. The complete first sector is read into the RAM and then interpreted.

You will be prompted to enter the number of the floppy drive. Please enter:
- 00 --> drive A:
- 01 --> drive B:

No input validation takes place! So please only enter 00 or 01.

<img width="691" alt="Bildschirmfoto" src="https://user-images.githubusercontent.com/52176362/120079611-fb700180-c0b4-11eb-8c53-731354da0c93.png">

# Library Files
## media.asm
This file contains the procedures for displaying drive media information on the screen:
- media descriptor byte
- bytes per sector
- total number of clusters
- sectors per cluster

## sector.asm
This file contains the procedures for displaying a sector on the screen.

## cursor.asm
This file contains the procedures for controlling the cursor.

## video.asm
This file contains the procedures for the screen output.

## keyboard.asm
This files contains the procedures for the keyboard input.

# Used Source Code
## sector.asm, cursor.asm, video.asm, keyboard.asm

PETER NORTON'S ASSEMBLERBUCH (PNAB)<br>
MARKT & TECHNIK VERLAG AG, 1988<br>
ISBN 3-89090-624-9<br>

THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.<br>
(C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.<br>

SECTOR.ASM: NEW FILE CREATED BY ME, BUT WITH VARIOUS SOURCECODE FROM PNAB
