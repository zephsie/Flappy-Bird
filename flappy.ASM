org 100h

width = 320
height = 200

BirdHeight = 15
BirdWidth = 15

ClFont = 00h or 0fh
Esc = 27

ObstacleW = 30
SpaceBetweenObstacles = 50

Step = 5

BirdX = 100

FloorH = 8
GrassH = 4
SandH  = 16

Start:

        mov     dx, 0331h
        mov     al, $FF
        out     dx, al
        mov     al, 3fh
        out     dx, al
        mov     al, $0F
        int     10h

        mov     [BOldMode], al
        mov     [BOldPage], bh
        mov     ax, 0013h
        int     10h

        mov     ax, cs
        add     ax, 1000h
        mov     es, ax

        mov     ah, 2ch
        int     21h
        mov     [PrevRandom], dx

Init:

        mov     dx, 0330h
        mov     cx, midi2.length
        mov     si, midi2
        rep     outsb

        mov     [ScoreStr+2], '0'
        mov     [ScoreStr+1], '0'
        mov     [ScoreStr], '0'
        mov     [isFalling], 1
        mov     [BirdY], (height-BirdWidth)/2
        mov     [a], 0
        mov     [iter], 0

GenObs1:

        push    height - SpaceBetweenObstacles - FloorH - SandH - GrassH
        call    RandomNum
        mov     [Hei], ax
        mov     [OShift], width

Draw:

BackGround:

        push    0
        push    0
        push    width
        push    height - FloorH
        push    $4E
        call    DrawRect

Obstacles:

        cmp    [iter], 0
        je     Yay

        push   [HeiPrev]
        push   [iter]
        push   0
        call   DrawObstacles
        sub    [iter], Step

        jmp     Bird

Yay:

        lea     ax, [width-ObstacleW]
        cmp     ax, [OShift]
        jng     R
        jmp     Ord

R:

        push    [Hei]
        mov     ax, width
        sub     ax, [OShift]
        push    ax
        push    [OShift]
        call    DrawObstacles
        mov     ax, Step
        sub     [OShift], ax
        jmp     Bird

Ord:

        push    [Hei]
        push    ObstacleW
        push    [OShift]
        call    DrawObstacles
        mov     ax, Step
        sub     [OShift], ax
        jng     Idk
        jmp     Bird

Idk:

        mov     [iter], ObstacleW
        mov     ax, [Hei]
        mov     [HeiPrev], ax
        jmp     GenObs1

Bird:

        push    0
        push    height-FloorH-SandH
        push    width
        push    SandH
        push    6
        call    DrawRect

        push    0
        push    height-FloorH-SandH-GrassH
        push    width
        push    GrassH
        push    $2F
        call    DrawRect

        push    [BirdY]
        cmp     [Bool],1
        je      Up
        push    BirdX
        call    DrawBird
        jmp     Buf

Up:

        call    DrawBirdUp
        mov     [Bool],0

Buf:

        push    ds es
        mov     ax,es
        mov     ds,ax
        push    $A000
        pop     es
        mov     cx, width*(height-FloorH)
        xor     si, si
        xor     di, di
        rep     movsw
        pop     es ds

PrintText:

        xor     dx,dx
        mov     dx,[OShift]
        add     dx,ObstacleW
        cmp     dx, 100
        jne     Ok
        inc     [ScoreStr+2]
        cmp     [ScoreStr+2],'9'
        jbe     Ok
        mov     [ScoreStr+2],'0'
        inc     [ScoreStr+1]

Ok:

                mov     ah, 02h
                xor     bh, bh
                mov     dl, 0
                mov     dh, 24
                int     10h
                xor     si, si

                .DrawText:

                mov     ah, 0eh
                mov     al, [ScoreMes+si]
                mov     bl, ClFont
                int     10h
                inc     si
                cmp     si, 5
                jle     .DrawText
                xor     si,si

                .DrawNumb:

                mov     ah, 0eh
                mov     al, [ScoreStr+si]
                mov     bl, ClFont
                int     10h
                inc     si
                cmp     si, 2
                jle     .DrawNumb

PressKey:

        mov     ah, 01h
        int     16h
        jz      SkipRead

        mov     ah, 00h
        int     16h

        cmp     al, Esc
        je      Finish

Jump:

        cmp     al, ' '
        jne     SkipRead
        add     [a], 10
        push    [BirdY]
        call    DrawBirdUp
        mov     [Bool], 1

SkipRead:

        mov     ah, 2ch
        int     21h
        cmp     dl, [PrevT]
        je      PressKey

        mov     [PrevT], dl

        xor     [isFalling], 1
        cmp     [isFalling], 1
        je      Check

        mov     ax, [a]
        sub     [BirdY], ax
        sub     [a], 1

Check:

        mov     ax, [BirdY]
        test    ax, ax
        jl      Finish

        add     ax, BirdHeight
        cmp     ax, height - FloorH - SandH - GrassH
        jg      Finish

        mov     ax, [OShift]
        add     ax, ObstacleW
        cmp     ax, BirdX
        jl      Passed

        mov     ax, [OShift]
        sub     ax, BirdWidth
        cmp     ax, BirdX
        jg      Passed

LastCheck:

        mov     ax, [BirdY]
        cmp     ax, [Hei]
        jl      Finish

        add     ax, BirdHeight
        mov     bx, [Hei]
        add     bx, SpaceBetweenObstacles
        cmp     ax, bx
        jg      Finish

Passed:

        jmp     Draw

Finish:

        mov     dx, 0330h
        mov     cx, midi.length
        mov     si, midi
        rep     outsb
        push    es
        push    $A000
        pop     es

        xor     di, di
        mov     cx, width*(height-FloorH)
        mov     al, 0
        rep     stosb

        mov     ah, 02h
        xor     bh, bh
        mov     dl, 15
        mov     dh, 12
        int     10h
        xor     si, si

DrawFin:

        mov     ah, 0eh
        mov     al, [FinMes+si]
        mov     bl, ClFont
        int     10h
        inc     si
        cmp     si, 8
        jle     DrawFin

        mov     ah, 02h
        xor     bh, bh
        mov     dl, 2
        mov     dh, 20
        int     10h
        xor     si, si

FinMe:
        mov     ah, 0eh
        mov     al, [Mes+si]
        mov     bl, ClFont
        int     10h
        inc     si
        cmp     si, 33
        jle     FinMe

        pop     es
        mov     ax, 0c08h
        int     21h
        test    al, al
        jnz     @f
        mov     ah, 08h
        int     21h
        @@:
        cmp     al, Esc
        je      FinishFinal

        cmp     al, ' '
        je      Init

FinishFinal:

        movzx   ax, [BOldMode]
        int     10h
        mov     ah, $05
        mov     al, [BOldPage]
        int     10h
        int     20h

DrawRect:

        push    bp
        mov     bp, sp

        mov     ax, [bp+10]
        mov     dx, width
        mul     dx
        mov     di, ax
        add     di, [bp+12]
        mov     al, [bp+4]
        mov     cx, [bp+6]

        .hs:
        push    cx
        mov     cx, [bp+8]
        rep     stosb
        add     di, width
        sub     di, [bp+8]
        pop     cx
        loop    .hs

        mov     sp, bp
        pop     bp
        ret     10

RandomNum:

        push    bp
        mov     bp, sp

        mov     ax, [PrevRandom]
        rol     ax, 7
        add     ax, 23
        mov     [PrevRandom], ax
        mov     cx, [bp+4]
        xor     dx, dx
        div     cx
        mov     ax, dx

        mov     sp, bp
        pop     bp
        ret     2

DrawObstacles:

        push    bp
        mov     bp, sp

        push    word [bp+4]
        push    0
        push    word [bp+6]
        push    word [bp+8]
        push    8
        call    DrawRect

        mov     ax,[bp+8]
        push    word [bp+4]
        add     ax, SpaceBetweenObstacles
        push    ax
        push    word [bp+6]
        mov     bx, ax
        mov     ax, height
        sub     ax, bx
        sub     ax, 28
        push    ax
        push    8
        call    DrawRect

        mov     sp, bp
        pop     bp
        ret     6

DrawBird:

       push bp
       mov bp,sp

       mov ax,[bp+6]
       mov bx,[bp+4]
       mov cx,320
       mul cx
       add ax,bx

       mov di,ax
       mov cx,6
       mov al,00
       rep stosb

       add di,312
       mov cx,2
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,310

       mov cx,1
       rep stosb

       mov cx,5
       mov al,2bh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,307
       mov al,00
       mov cx,4
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov cx,2
       mov al,0fh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,305
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,2bh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov cx,2
       mov al,0fh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,305
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,5
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov cx,3
       mov al,2bh
       rep stosb

       mov cx,1
       mov al,00
       rep stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,305
       mov al,00
       mov cx,1
       rep stosb

       mov al,2bh
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,2bh
       mov cx,1
       rep stosb

       mov cx,1
       mov al,00
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov cx,5
       mov al,00
       rep stosb

       add di,305
       mov al,00
       mov cx,1
       rep stosb

       mov al,2bh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,29h
       mov cx,5
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di, 305
       mov cx,3
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,29h
       mov cx,1
       rep stosb

       mov al,00
       mov cx,5
       rep stosb

       add di,308
       inc cx
       rep stosb

       mov al,2bh
       mov cx,5
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,29h
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,309
       mov cx,2
       rep stosb

       mov cx,4
       mov al,2bh
       rep stosb

       mov al,00
       mov cx,5
       rep stosb

       add di,311
       mov cx,4
       rep stosb

       pop bp
       ret 2

DrawBirdUp:

       push bp
       mov bp,sp

       mov ax,[bp+4]
       mov cx,320
       mul cx
       add ax,100

       mov di,ax
       mov cx,6
       mov al,00
       rep stosb

       add di,312
       mov cx,2
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,310

       mov cx,1
       rep stosb

       mov cx,5
       mov al,2bh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,308
       mov al,00
       stosb

       mov al,2bh
       mov cx,6
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov cx,2
       mov al,0fh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,307
       stosb

       mov al,2bh
       mov cx,6
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov cx,2
       mov al,0fh
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,0fh
       mov cx,1
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,307
        stosb
       mov cx,7
       mov al,2bh
       rep stosb

       mov cx,1
       mov al,00
       rep stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,306
       mov cx,4
       rep stosb

       mov al,2bh
       mov cx,2
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov cx,5
       mov al,00
       rep stosb

       add di,304
       stosb

       mov al,0fh
       mov cx,4
       rep stosb

       xor al,al
       stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,29h
       mov cx,5
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di, 303
       stosb

       mov al,0fh
       mov cx,5
       rep stosb

       mov al,00
       stosb

       mov al,2bh
       mov cx,2
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       mov al,29h
       mov cx,1
       rep stosb

       mov al,00
       mov cx,5
       rep stosb

       add di,304
       stosb

       mov al,2bh
       stosb

       mov al,0fh
       mov cx,3
       rep stosb

       mov al,2bh
       stosb
       mov al,00
       stosb

       mov al,2bh
       mov cx,3
       rep  stosb

       mov al,00
       stosb

       mov al,29h
       mov cx,4
       rep stosb

       mov al,00
       mov cx,1
       rep stosb

       add di,305
       stosb

       mov cx,3
       mov al,2bh
       rep stosb

       mov al,00
       mov cx,2
       rep stosb

       mov al,2bh
       mov cx,4
       rep stosb

       mov al,00
       mov cx,5
       rep stosb

       add di,306
       mov cx,3
       rep stosb

       inc di
       inc di

       mov cx,4
       rep stosb
       pop bp
       ret 2

iter            dw ?
isFalling       db ?
a               dw ?
BirdY           dw ?
PrevT           db ?
Hei             dw ?
HeiPrev         dw ?
BOldMode        db ?
BOldPage        db ?
PrevRandom      dw ?
OShift          dw ?
Bool            db ?
midi            db $c0,73h,90h,40h,7fh,$f7
Mes             db 'Space - play            Esc - exit'
FinMes          db 'Game over'
ScoreMes        db 'Score:'
ScoreStr        db '000'
midi2           db $c0,7dh,90h,40h,29h,$f7
midi.length     = $ - midi
midi2.length    = $ - midi2