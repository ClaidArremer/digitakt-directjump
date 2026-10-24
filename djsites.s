| SPDX-License-Identifier: GPL-2.0-or-later
| DIRECT JUMP (Digitakt mk1, OS 1.54): the sequencer's two sites and the
| SETTINGS rows. ColdFire V4; addresses from mod.json's defsym.
|
| Each row's four callbacks follow the SETTINGS menu's MenuItem conventions as
| digihealth's SYSTEM INFO row does (irpina/digihealth, sysinfo.s,
| GPL-2.0-or-later), from which they are adapted, as PUMP's row is.

        .equ    SQ_LEN_OVR, 0x4199ed4c          | s16: the source's master length
        .equ    SQ_PENDING, 0x4199ecc2          | u16: tracks waiting for their step

        .section .run, "ax"

| ---- site A: 0x40070e26, over `mvs.w 0x4199ed4c,d1` (6 bytes) ---------------
| The tick interrupt, two ticks into a master step, while playing, after the
| pattern source's next entry was peeked into 92(sp): d0 = its pattern, d3 =
| nonzero when song mode changes the source. dj_peek arms the change itself
| when a pattern was just picked (1), or holds a start until its bar (2); then
| the stock end-of-pattern test and its arm are skipped: back to where the
| stock arm goes on (DJ_ARMED_RET). Else
| back to the stock with d1 as the instruction left it. Keeps all registers
| but d1, and the stock reads no flags from it.
        .globl  dj_site_peek
dj_site_peek:
        mvs.w   SQ_LEN_OVR, %d1         | the instruction this replaced
        lea     -16(%sp), %sp
        movem.l %d0-%d1/%a0-%a1, (%sp)
        pea     112(%sp)                | the entry: 92 + 4 (return) + 16
        move.l  %d3, -(%sp)             | song
        move.l  %d0, -(%sp)             | next
        jsr     dj_peek
        lea     12(%sp), %sp
        tst.l   %d0
        movem.l (%sp), %d0-%d1/%a0-%a1  | movem and lea keep the flags
        lea     16(%sp), %sp
        beq.s   1f
        move.l  #DJ_ARMED_RET, (%sp)    | armed: on after the stock arm
1:      rts

| ---- site B: 0x4007124e, over `move.w d4,0x4199ecc2` (6 bytes) --------------
| The tick interrupt, on the switch path, after each track's step was worked
| out: d4 = the pending mask (16 tracks). dj_switched redoes the steps after a
| jump and gives the mask to store. d4 is not read after this (the code that
| follows loads it afresh); the site sits between the pushes of a call's
| arguments, which this routine leaves as it found them.
        .globl  dj_site_switch
dj_site_switch:
        lea     -16(%sp), %sp
        movem.l %d0-%d1/%a0-%a1, (%sp)
        move.l  %d4, -(%sp)
        jsr     dj_switched
        addq.l  #4, %sp
        move.l  %d0, %d4
        movem.l (%sp), %d0-%d1/%a0-%a1
        lea     16(%sp), %sp
        move.w  %d4, SQ_PENDING         | the instruction this replaced
        rts

| ---- SETTINGS > DIRECT JUMP and RESTART PATTERN: checkboxes --------------------
| ev_settings handler: the rows, after the stock ones (and other mods')
        .globl  dj_settings
dj_settings:
        pea     dj_row
        move.l  8(%sp), -(%sp)          | the menu
        jsr     core_additem
        addq.l  #8, %sp
        pea     dj_row2
        move.l  8(%sp), -(%sp)
        jsr     core_additem
        addq.l  #8, %sp
        rts

| One row's callbacks; FLAG is its byte in dj_data, STR its label.
        .macro  ROW name, flag, str
| label() -> std::string, returned through a0
\name\()_label:
        link    %a6, #-4
        move.l  %d2, -(%sp)
        pea     -1(%a6)
        pea     \str
        move.l  %a0, %d2
        move.l  %a0, -(%sp)
        jsr     STR_CTOR
        lea     12(%sp), %sp
        move.l  %d2, %d0
        move.l  -8(%a6), %d2
        unlk    %a6
        rts

| select(payload, item): YES toggles it, then the menu redraws
\name\()_select:
        movea.l 4(%sp), %a0
        movea.l (%a0), %a0
        moveq   #0, %d0
        tst.b   \flag
        seq     %d0
        andi.l  #1, %d0
        move.b  %d0, \flag
        lea     0x38(%a0), %a0
        move.l  %a0, 4(%sp)
        jmp     INVALIDATE

| change(payload, item, delta): RIGHT ticks it, LEFT unticks it
\name\()_change:
        movea.l 4(%sp), %a0
        movea.l (%a0), %a0
        move.l  12(%sp), %d0
        beq.s   1f
        sgt     %d0
        andi.l  #1, %d0
        move.b  %d0, \flag
        lea     0x38(%a0), %a0
        move.l  %a0, 4(%sp)
        jmp     INVALIDATE
1:      rts

| draw(payload, item, bmp, x, y): the checkbox, ticked while on
\name\()_draw:
        moveq   #0, %d0
        tst.b   \flag
        beq.s   1f
        moveq   #0x1c, %d0
1:      add.l   CHECKBOXES, %d0
        move.l  12(%sp), %d1
        move.l  %d1, 4(%sp)
        move.l  %d0, 8(%sp)
        move.l  16(%sp), %d1
        move.l  %d1, 12(%sp)
        move.l  20(%sp), %d1
        move.l  %d1, 16(%sp)
        clr.l   20(%sp)
        jmp     BLIT
        .endm

        ROW     dj, dj_data, dj_str
        ROW     dj2, dj_data+1, dj_str2

        .balign 4
dj_row:  .long  dj_label, dj_select, dj_draw, dj_change
dj_row2: .long  dj2_label, dj2_select, dj2_draw, dj2_change
dj_str:  .asciz "DIRECT JUMP"
dj_str2: .asciz "START ON BAR"
        .balign 4
