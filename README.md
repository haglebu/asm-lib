# asm-lib
My assembler programs and library files. I use the Microsoft Assembler MASM version 5.10.

# Program Files
## mi.asm
Display media information (MI) about drive A:. The drive is currently static; this will be changed later.

<img width="589" alt="mi" src="https://user-images.githubusercontent.com/52176362/120019902-4c1a2880-bfe9-11eb-97e1-3d1a3985ce7c.png">

## bpb.asm
Display BIOS parameter block information (BPB) about drive A:. The drive is currently static; this will be changed later. Here the complete first sector of drive A is read into the RAM and then interpreted.

<img width="596" alt="bpb" src="https://user-images.githubusercontent.com/52176362/120019548-e168ed00-bfe8-11eb-8eb8-463229004d99.png">

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

# Used Source Code
## video.asm, cursor.asm, sector.asm

PETER NORTON'S ASSEMBLERBUCH (PNAB)<br>
MARKT & TECHNIK VERLAG AG, 1988<br>
ISBN 3-89090-624-9<br>

THE COMMERCIAL USE OF THIS CODE IS NOT PERMITTED.<br>
(C) 1988 BY MARKT & TECHNIK VERLAG AKTIENGESELLSCHAFT.<br>

SECTOR.ASM: NEW FILE CREATED BY ME, BUT WITH VARIOUS SOURCECODE FROM PNAB
