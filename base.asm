IDEAL
MODEL small
STACK 100h
DATASEG
Clock equ es:6Ch
StartingText db 'Welcome to the nim game', 10, 13, 'The goal is to make the other opponent pick last', 10, 13, 'You may only pick coins from one line only each turn', 10, 13, 'To start the game press S or esc to disconnect', 10, 13, '$'
FinalText db 'Player $'
FinalText2 db ' has won', 10, 13, 'Would you like a rematch? Y - Yes | N - No$'
ExitText db 'Thanks for playing :)$'
filename db 'bg.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10,'$'
Condition db 0 ; 0 if didn't pick, 1 if did
PlayerTurn db 1 ; Moves between 1 and 2
LineOne db 1
LineTwo db 3
LineThree db 5
LineFour db 7
Total db 16
Color db ?
X dw ?
Y dw ?
Xcmp dw ?
Ycmp dw ?
LinePicked db 0
CODESEG
proc OpenFile ; Open file for reading and writing
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
	openerror:
		mov dx, offset ErrorMsg
		mov ah, 9h
		int 21h
		ret
endp OpenFile

proc ReadHeader ; Read BMP file header
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx, offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette ; Read BMP file color palette
	mov ah,3fh
	mov cx,400h
	mov dx, offset Palette
	int 21h
	ret
endp ReadPalette

proc CopyPal ; Copy the colors palette to the video memory 
	mov si, offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	out dx,al
	inc dx
	PalLoop:
	mov al,[si+2]
	shr al,2
	out dx,al
	mov al,[si+1] 
	shr al,2
	out dx,al
	mov al,[si]
	shr al,2
	out dx,al
	add si,4
	loop PalLoop
	ret
endp CopyPal

proc CopyBitmap 
; BMP graphics are saved upside-down.
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
	PrintBMPLoop:
		push cx
		mov di,cx
		shl cx,6
		shl di,8
		add di,cx
		mov ah,3fh
		mov cx,320
		mov dx, offset ScrLine
		int 21h
		cld 
		mov cx,320
		mov si, offset ScrLine
		rep movsb
		pop cx
		loop PrintBMPLoop
		ret
endp CopyBitmap

proc CloseFile
	mov ah,3Eh
	mov bx, [filehandle]
	int 21h
	ret
endp CloseFile

proc CreateBlock ; Creates a block of pixels according to the values given
	push bp
	mov bp, sp
	mov si, [X]
	LineLoop:
	mov di, [Y]
		ColumnLoop:
			mov bh, 0
			mov al, [Color]
			mov cx, di
			mov dx, si
			mov ah, 0Ch
			int 10h
			inc di
			cmp di, [Ycmp]
			JNE ColumnLoop
		inc si
		cmp si, [Xcmp]
		JNE LineLoop
	pop bp
	ret
endp CreateBlock

proc Delay
	push bp
	mov bp, sp
	mov ax, 40h
	mov es, ax
	mov ax, [Clock]
	FirstTick:
		cmp ax, [Clock]
		je FirstTick
		mov cx, 1
		DelayLoop:
			mov ax, [Clock]
			Tick:
				cmp ax, [Clock]
				je Tick
				loop DelayLoop
				pop bp
				ret
endp Delay

proc Sound
	push bp
	mov bp, sp
	in al, 61h
	or al, 00000011b
	out 61h, al
	mov al, 0b6h
	out 43h, al
	mov ax, 2394h
	out 42h, al
	mov al, ah
	out 42h, al
	call Delay
	in al, 61h
	and al, 11111100b
	out 61h, al
	pop bp
	ret
endp Sound

start:
	mov ax, @data
	mov ds, ax
	mov dx, offset StartingText ; Introduction to the game, rules etc...
	mov ah, 9h
	int 21h
	WaitForS: ; Waiting for s to be pressed or esc
		mov ah,0Ch
		mov al,07h
		int 21h
		cmp al, 73h
		JE SPressed
		cmp al, 53h
		JE SPressed
		cmp al, 1Bh
		JE ExitAtStart
		jmp WaitForS
		
	ExitAtStart:
		mov ax, 4c00h
		int 21h
		
	ShortJmpCutExit:
		jmp ExitCut
		
	SPressed: ; Starts the game
		mov [PlayerTurn], 1
		mov [LineOne], 1
		mov [LineTwo], 3
		mov [LineThree], 5
		mov [LineFour], 7
		mov [Total], 16
		mov [LinePicked], 0
		mov [Condition], 0
		mov ax, 13h
		int 10h
		call OpenFile
		call ReadHeader
		call ReadPalette
		call CopyPal
		call CopyBitmap
		mov [X], 35
		mov [Y], 20
		mov [Xcmp], 55
		mov [Ycmp], 40
		mov [Color], 145
		call CreateBlock
		mov [X], 35
		mov [Y], 250
		mov [Xcmp], 55
		mov [Ycmp], 270
		mov [Color], 20
		call CreateBlock
		jmp CheckForKey
		
		ExitCut:
				jmp ExitOne
		
		CheckForKey: ; Waiting for a response from the player
			in al, 64h
			cmp al, 10b
			JE CheckForKey
			in al, 60h
			cmp al, 9Ch
			JE EnterPressed
			cmp al, 82h
			JE OnePressed2
			cmp al, 83h
			JE JmpCutTwo
			cmp al, 84h
			JE JmpCutThree
			cmp al, 85h
			JE JmpCutFour
			jmp CheckForKey
			
			EnterPressed:
				cmp [Condition], 0
				JE CheckForKey
				cmp [Total], 0
				JE ExitCut
				mov [LinePicked], 0
				mov [Condition], 0
				cmp [PlayerTurn], 1
				JE PlayerOne
				mov [X], 35
				mov [Y], 20
				mov [Xcmp], 55
				mov [Ycmp], 40
				mov [Color], 145
				call CreateBlock
				mov [X], 35
				mov [Y], 250
				mov [Xcmp], 55
				mov [Ycmp], 270
				mov [Color], 20
				call CreateBlock
				mov [PlayerTurn], 1
				call Sound
				jmp CheckForKey
				
				JmpCutThree:
					jmp ThreePressed
				
				OnePressed2:
					jmp OnePressed
					
				JmpCutTwo:
					jmp TwoPressed
					
				JmpCutFour:
					jmp FourPressed
				
				PlayerOne:
					mov [X], 35
					mov [Y], 20
					mov [Xcmp], 55
					mov [Ycmp], 40
					mov [Color], 20
					call CreateBlock
					mov [X], 35
					mov [Y], 250
					mov [Xcmp], 55
					mov [Ycmp], 270
					mov [Color], 145
					call CreateBlock
					mov [PlayerTurn], 2
					call Sound
					jmp CheckForKey
			
			CheckForKey2:
				jmp CheckForKey
					
			YPressed4:
				jmp SPressed
					
			JmpCutOne:
				jmp CheckForKey
			
			OnePressed:
				cmp [LineOne], 0
				JE CheckForKey2
				cmp [LinePicked], 0
				JE ChangeLineOne
				cmp [LinePicked], 1
				JNE CheckForKey2
				ChangeLineOne:
					mov [LinePicked], 1
					mov [Condition], 1
					mov [X], 58
					mov [Y], 132
					mov [Xcmp], 85
					mov [Ycmp], 162
					mov [Color], 0
					call CreateBlock
					dec [LineOne]
					dec [Total]
					jmp CheckForKey
					
			YPressed3:
				jmp YPressed4
					
			JmpCutTwo2:
				jmp JmpCutTwo
					
			JmpCutThree2:
				jmp JmpCutThree
				
			JmpCutFour2:
				jmp JmpCutFour
				
			ExitOne:
				jmp ExitTwo
				
			JmpCutOne2:
				jmp JmpCutOne
					
			TwoPressed:
				cmp [LineTwo], 0
				JE JmpCutOne
				cmp [LinePicked], 0
				JE ChangeLineTwo
				cmp [LinePicked], 2
				JNE JmpCutOne
				ChangeLineTwo:
					mov [LinePicked], 2
					mov [Condition], 1
					mov bl, 30
					mov al, [LineTwo]
					mul bl
					mov [X], 94
					add ax, 71
					mov [Y], ax
					mov [Xcmp], 121
					add ax, 30
					mov [Ycmp], ax
					mov [Color], 0
					call CreateBlock
					dec [LineTwo]
					dec [Total]
					mov al, 0
					out 60h, al
					call Delay
					jmp JmpCutOne
					
			JmpCutFour3:
				jmp JmpCutFour2
				
			YPressed2:
				jmp YPressed3
				
			JmpCutOne3:
				jmp JmpCutOne2
			
			ThreePressed:
				cmp [LineThree], 0
				JE JmpCutOne2
				cmp [LinePicked], 0
				JE ChangeLineThree
				cmp [LinePicked], 3
				JNE JmpCutOne2
				ChangeLineThree:
					mov [LinePicked], 3
					mov [Condition], 1
					mov bl, 30
					mov al, [LineThree]
					mul bl
					mov [X], 130
					add ax, 39
					mov [Y], ax
					mov [Xcmp], 158
					add ax, 37
					mov [Ycmp], ax
					mov [Color], 0
					call CreateBlock
					dec [LineThree]
					dec [Total]
					mov al, 0
					out 60h, al
					call Delay
					jmp JmpCutOne
					
			ExitTwo:
				jmp exit
			
			FourPressed:
				cmp [LineFour], 0
				JE JmpCutOne3
				cmp [LinePicked], 0
				JE ChangeLineFour
				cmp [LinePicked], 4
				JNE JmpCutOne3
				ChangeLineFour:
					mov [LinePicked], 4
					mov [Condition], 1
					mov bl, 32
					mov al, [LineFour]
					mul bl
					mov [X], 160
					add ax, 5
					mov [Y], ax
					mov [Xcmp], 190
					add ax, 27
					mov [Ycmp], ax
					mov [Color], 0
					call CreateBlock
					dec [LineFour]
					dec [Total]
					mov al, 0
					out 60h, al
					call Delay
					jmp JmpCutOne
					
			YPressed:
				jmp YPressed2
exit:
	mov ah,  0 ; Text mode
	mov al, 2
	int 10h
	mov ah, 9h
	mov dx, offset FinalText
	int 21h
	cmp [PlayerTurn], 1
	JE PlayerTwoWon
	mov [PlayerTurn], 1
	jmp Continue
	PlayerTwoWon:
		mov [PlayerTurn], 2
		Continue:
			mov bl, [PlayerTurn]
			add bl, 48
			mov dl, bl
			mov ah, 2h
			int 21h
			mov ah, 9h
			mov dx, offset FinalText2
			int 21h
			WaitForKeyFinal:
				mov ah,0Ch
				mov al,07h
				int 21h
				cmp al, 59h
				JE YPressed
				cmp al, 79h
				JE YPressed
				cmp al, 6Eh
				JE EndGame
				cmp al, 4Eh
				JE EndGame
				jmp WaitForKeyFinal
	
			EndGame:
				call CloseFile
				mov ax, 4c00h
				int 21h
END start