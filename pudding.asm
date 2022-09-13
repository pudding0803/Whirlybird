TITLE Pudding Forever        (pudding.ASM)

INCLUDE Irvine32.inc

main EQU start@0

COORDINATE STRUCT
	x BYTE ?
	y SBYTE ?
COORDINATE ENDS

BOARD STRUCT
	pos COORDINATE <>
	category BYTE 0
	show BYTE 1
	touchable BYTE 1
	direction SBYTE 0
	hasHat BYTE 0
BOARD ENDS

BoardStructSize = 7
BoxWidth = 30
BoxHeight = 30
DelayTime = 80
JumpingTime = 14
BoundingTime = 24
FlyingTime = 60
UpperBoundY = 11
LowerBoundY = 24
StageHeight = 100

print PROTO,
	pos: COORDINATE,
	object: PTR BYTE

printHat PROTO,
	pos: COORDINATE,
	object: BYTE

getRandom PROTO,
	min: BYTE,
	max: BYTE

.data
outputHandle DWORD 0
windowRect SMALL_RECT <0, 0, BoxWidth - 1, BoxHeight>

titleStr BYTE "Whirlybird", 0
startStr BYTE "Press space key to start...", 0
startStrPos COORDINATE <1, 15>
hintStr BYTE "Hint: Use <- and -> to move", 0
hintStrPos COORDINATE <1, 17>
boxTop BYTE ' ', (BoxWidth - 2) DUP('-'), ' ', 0
boxBody BYTE '|', (BoxWidth - 2) DUP(' '), '|', 0
boxBottom BYTE ' ', (BoxWidth - 2) DUP('-'), ' ', 0
scoreArea BYTE BoxWidth DUP(' '), 0
xBound BYTE BoxWidth
initialplayerPosY DWORD 15
playerPos COORDINATE <BoxWidth / 2, BoxHeight / 2>
playerStyle BYTE 'A'
flyingStatus BYTE 0
isBounding BYTE 0
isWithHat BYTE 0
emptyStyle BYTE 3 DUP(' '), 0
score SDWORD 0
scoreGoal SDWORD 100
backgroundPos COORDINATE <0, 0>
backgroundStyle BYTE 0
scoreStr BYTE "Score:", 0
scoreStrPos COORDINATE <0, BoxHeight>
scorePos COORDINATE <7, BoxHeight>
gameOverStr BYTE "GAME OVER", 0
gameOverPos COORDINATE <11, 15>
gameOverCount BYTE 0
exitStr BYTE "Press ESC key to exit...", 0
exitStrPos COORDINATE <4, 16>
bombardedStyle BYTE "\|/", 0, "- -", 0, "/|\", 0
boardStyle BYTE "---", 0, "<=>", 0, "===", 0, "III", 0,
				"---", 0, "OOO", 0, "^^^", 0
movableBoardTimer BYTE 0
invisibleBoardTimer BYTE 0
boardStage1 BYTE 0, 0, 0, 0, 0, 1, 2, 2, 3, 3, 4, 4, 5
boardStage2 BYTE 0, 1, 1, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5, 6
boardArray BOARD <<0, 3>, 0, 1>,
				 <<0, 6>, 0, 1>,
				 <<0, 9>, 0, 1>,
				 <<0, 12>, 0, 1>,
				 <<0, 15>, 0, 1>,
				 <<0, 18>, 0, 1>,
				 <<0, 21>, 0, 1>,
				 <<14, 24>, 0, 1>

.code
main PROC
	call ClrScr
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov outputHandle, eax
	INVOKE SetConsoleWindowInfo, outputHandle, TRUE, ADDR windowRect
	INVOKE SetConsoleTitle, ADDR titleStr

	mov ecx, 7
	mov esi, 0
	call Randomize
setBoardsPosY:
	INVOKE getRandom, 2, BoxWidth - 5
	mov boardArray[esi].pos.x, al
	add esi, BoardStructSize

	LOOP setBoardsPosY

	INVOKE print, startStrPos, OFFSET startStr
	INVOKE print, hintStrPos, OFFSET hintStr
startGame:
	call ReadKey
	.IF ax == 3920h
        jmp printBoxTop
    .ENDIF
	jmp startGame

printBoxTop:
	INVOKE print, backgroundPos, OFFSET boxTop

	mov ecx, BoxHeight - 2
printBoxBody:
	inc backgroundPos.y
	INVOKE print, backgroundPos, OFFSET boxBody

	LOOP printBoxBody

printBoxBottom:
	inc backgroundPos.y
	INVOKE print, backgroundPos, OFFSET boxBottom

printScore:
	INVOKE print, scoreStrPos, OFFSET scoreArea
	INVOKE print, scoreStrPos, OFFSET scoreStr

gameLoop:
	mov ecx, 8
    mov esi, 0
    drawBoards:
		.IF boardArray[esi].pos.y > 1
			.IF boardArray[esi].category == 1
				.IF movableBoardTimer == 3
					mov al, boardArray[esi].direction
					add boardArray[esi].pos.x, al
					.IF boardArray[esi].pos.x <= 2
						mov boardArray[esi].pos.x, 2
						mov boardArray[esi].direction, 1
					.ELSEIF boardArray[esi].pos.x >= BoxWidth - 5
						mov boardArray[esi].pos.x, BoxWidth - 5
						mov boardArray[esi].direction, -1
					.ENDIF
				.ENDIF
			.ENDIF
			.IF boardArray[esi].category == 4
				.IF invisibleBoardTimer < 4
					mov boardArray[esi].show, 1
				.ELSE
					mov boardArray[esi].show, 0
				.ENDIF
			.ENDIF
			.IF boardArray[esi].show == 1
				movzx edi, boardArray[esi].category
				shl edi, 2
				INVOKE print, boardArray[esi].pos, ADDR boardStyle[edi]
				.IF boardArray[esi].hasHat == 1
					INVOKE printHat, boardArray[esi].pos, '*'
				.ENDIF
			.ENDIF
		.ENDIF
		add esi, BoardStructSize
	dec ecx
	.IF ecx > 0
		jmp drawBoards
	.ENDIF
    call drawPlayer
	inc invisibleBoardTimer
	.IF invisibleBoardTimer == 20
		mov invisibleBoardTimer, 0
	.ENDIF
	inc movableBoardTimer
	.IF movableBoardTimer == 4
		mov movableBoardTimer, 0
	.ENDIF
    mov eax, DelayTime
    call Delay
	mov ecx, 8
    mov esi, 0
    clearBoards:
		.IF boardArray[esi].pos.y > 1
			INVOKE print, boardArray[esi].pos, ADDR emptyStyle
			.IF boardArray[esi].hasHat == 1
				INVOKE printHat, boardArray[esi].pos, ' '
			.ENDIF
		.ENDIF
		add esi, BoardStructSize
    LOOP clearBoards
    call clearPlayer
    call ReadKey
    .IF ax == 4B00h
        dec playerPos.x
		.IF playerPos.x == 0
			mov al, xBound
			sub al, 2
			mov playerPos.x, al
		.ENDIF
    .ENDIF
    .IF ax == 4D00h
        inc playerPos.x
		mov al, xBound
		dec al
		.IF playerPos.x == al
			mov playerPos.x, 1
		.ENDIF
    .ENDIF
    .IF flyingStatus == 0
		mov isBounding, 0
		mov isWithHat, 0
        .IF playerPos.y >= LowerBoundY
            mov ecx, 8
            mov esi, 0
            moveUpBoard:
                dec boardArray[esi].pos.y
                add esi, BoardStructSize
            LOOP moveUpBoard
			dec initialplayerPosY
			mov ecx, 8
            mov esi, 0
			mov gameOverCount, 0
            checkGameOver:
                .IF boardArray[esi].pos.y < 0
					inc gameOverCount
				.ENDIF
                add esi, BoardStructSize
            LOOP checkGameOver
			.IF gameOverCount == 6
				mov playerStyle, 'Q'
			.ELSEIF gameOverCount == 8
				jmp falling
			.ENDIF
        .ENDIF
        .IF playerPos.y < LowerBoundY
            inc playerPos.y
        .ENDIF
		mov ecx, 8
		mov esi, 0
		checkCollision:
			mov al, boardArray[esi].pos.y
			mov ah, boardArray[esi].pos.x
			.IF boardArray[esi].hasHat == 1
				mov bl, al
				sub bl, 1
				mov bh, ah
				add bh, 1
				.IF playerPos.y == bl
					.IF playerPos.x == bh
						mov boardArray[esi].hasHat, 0
						mov flyingStatus, FlyingTime
						mov isWithHat, 1
					.ENDIF
				.ENDIF
			.ENDIF
			.IF playerPos.y == al
				.IF playerPos.x >= ah
					add ah, 3
					.IF playerPos.x < ah
						.IF boardArray[esi].touchable != 0
							.IF boardArray[esi].category == 2
								mov flyingStatus, BoundingTime
								mov isBounding, 1
							.ELSE
								mov flyingStatus, JumpingTime
							.ENDIF
							dec playerPos.y
						.ENDIF
						.IF boardArray[esi].category == 3
							mov boardArray[esi].show, 0
							mov boardArray[esi].touchable, 0
						.ELSEIF boardArray[esi].category == 5
							mov boardArray[esi].show, 0
						.ELSEIF boardArray[esi].category == 6
							jmp bombard
						.ENDIF
					.ENDIF
				.ENDIF
			.ENDIF
		add esi, BoardStructSize
		dec ecx
		.IF ecx > 0
			jmp checkCollision
		.ENDIF
    .ENDIF
    .IF flyingStatus > 0
		dec flyingStatus
        .IF playerPos.y <= UpperBoundY
            mov ecx, 8
            mov esi, 0
            moveDownBoard:
                inc boardArray[esi].pos.y
                .IF boardArray[esi].pos.y == 27
                    mov boardArray[esi].pos.y, 3
					mov boardArray[esi].show, 1
                    INVOKE getRandom, 2, BoxWidth - 5
                    mov boardArray[esi].pos.x, al
					.IF score <= StageHeight
						INVOKE getRandom, 0, LENGTHOF boardStage1
						movzx edi, al
						mov al, boardStage1[edi]
					.ELSE
						INVOKE getRandom, 0, LENGTHOF boardStage2
						movzx edi, al
						mov al, boardStage2[edi]
					.ENDIF
					mov boardArray[esi].category, al
					.IF boardArray[esi].category == 5
						mov boardArray[esi].touchable, 0
					.ELSE
						mov boardArray[esi].touchable, 1
					.ENDIF
					.IF boardArray[esi].category == 1
						INVOKE getRandom, 0, 1
						.IF al == 0
							sub al, 1
						.ENDIF
                    	mov boardArray[esi].direction, al
					.ELSE
						mov boardArray[esi].direction, 0
					.ENDIF
					mov boardArray[esi].hasHat, 0
					.IF boardArray[esi].category <= 1
						.IF score <= StageHeight
							INVOKE getRandom, 0, 8
						.ELSE
							INVOKE getRandom, 0, 10
						.ENDIF
						.IF al == 0
							mov boardArray[esi].hasHat, 1
						.ENDIF
					.ENDIF
                .ENDIF
                add esi, BoardStructSize
			dec ecx
			.IF ecx > 0
				jmp moveDownBoard
			.ENDIF
            inc initialplayerPosY
        .ENDIF
        .IF playerPos.y > UpperBoundY
            dec playerPos.y
        .ENDIF
    .ENDIF
    mov eax, initialplayerPosY
	movzx ebx, playerPos.y
    sub eax, ebx
    .IF eax > score
        mov score, eax
    .ENDIF
	call updateScore
	mov ebx, scoreGoal
	.IF score >= ebx
		.IF backgroundStyle == 0
			mov eax, 0 + 15 * 16
			inc backgroundStyle
		.ELSEIF backgroundStyle == 1
			mov eax, 15 + 0 * 16
			dec backgroundStyle
		.ENDIF
		add scoreGoal, 100
		call SetTextColor
		mov backgroundPos.y, 0
		jmp printBoxTop
    .ENDIF
    jmp gameLoop

	falling:
		.IF playerPos.y < 28
			call clearPlayer
			inc playerPos.y
			call drawPlayer
			mov eax, DelayTime
			call Delay
		.ELSE
			jmp exitGame
		.ENDIF
		jmp falling

	bombard:
		mov ecx, 8
		mov esi, 0
		drawFinalBoards:
			.IF boardArray[esi].pos.y > 0
				.IF boardArray[esi].show == 1
					movzx edi, boardArray[esi].category
					shl edi, 2
					INVOKE print, boardArray[esi].pos, ADDR boardStyle[edi]
				.ENDIF
			.ENDIF
			add esi, BoardStructSize
		LOOP drawFinalBoards

		mov ecx, 3
		mov esi, 0
		dec playerPos.x
		dec playerPos.y
		drawBombarded:
			INVOKE print, playerPos, ADDR bombardedStyle[esi]
			inc playerPos.y
			add esi, 4
		LOOP drawBombarded
		mov eax, DelayTime * 20
		call Delay

		jmp exitGame

	exitGame:
		call ClrScr
		INVOKE print, gameOverPos, OFFSET gameOverStr
		INVOKE print, scoreStrPos, OFFSET scoreStr
		call updateScore
		INVOKE print, exitStrPos, OFFSET exitStr

	waitESC:
		call ReadKey
		.IF ax == 011bh
			exit
		.ENDIF
		jmp waitESC
main ENDP

print PROC,
	pos: COORDINATE,
	object: PTR BYTE

	mov dl, pos.x
	mov dh, pos.y
	call Gotoxy
	mov edx, object
	call WriteString
	ret
print ENDP

printHat PROC,
	pos: COORDINATE,
	object: BYTE

	mov dl, pos.x
	add dl, 1
	mov dh, pos.y
	sub dh, 1
	call Gotoxy
	mov al, object
	call WriteChar
	ret
printHat ENDP

getRandom PROC USES ebx,
	min: BYTE,
	max: BYTE

	movzx eax, max
	movzx ebx, min
	sub eax, ebx
	call RandomRange
	add al, min
	ret
getRandom ENDP

drawPlayer PROC
	mov dl, playerPos.x
	mov dh, playerPos.y
	call Gotoxy
	mov al, playerStyle
	call WriteChar
	.IF isBounding == 1
	add dh, 1
	call Gotoxy
	mov al, '|'
	call WriteChar
	.ELSEIF isWithHat == 1
	sub dh, 1
	call Gotoxy
	mov al, '*'
	call WriteChar
	.ENDIF
	ret
drawPlayer ENDP

clearPlayer PROC
	mov dl, playerPos.x
	mov dh, playerPos.y
	call Gotoxy
	mov al, ' '
	call WriteChar
	add dh, 1
	call Gotoxy
	mov al, ' '
	call WriteChar
	sub dh, 2
	call Gotoxy
	mov al, ' '
	call WriteChar
	ret
clearPlayer ENDP

updateScore PROC
	mov dl, scorePos.x
	mov dh, scorePos.y
	call Gotoxy
	mov eax, score
	call WriteDec
	ret
updateScore ENDP

END main
