data segment
col db 0h ;col is the counter to the current column
a db 0h ;a is current character
mk db 0h ;mk is the mask to extract low 4 bit and high 4 bit of a
data ends

code segment
assume cs:code,ds:data
main:
mov ax,data
mov ds,ax
mov ax,0B800h 
mov es,ax ;es:bx is the current pointer to the screen
mov ax,3h
int 10h ;set video mode to 80*25 text mode and refresh the screen
columnLoop: ;print a column
cmp col,11 ;for(col=0;col<11;col++) 11 columns in total
jne Cont
jmp Done
Cont:
mov bx,0h 
mov al,col
findPtrLoop:
cmp al,0
je rowLoop
add bx,14
dec al
jmp findPtrLoop  ;bx+=col*14
rowLoop: ;print a row
cmp al,25 ; al(row) stores the counter to the current row, for(row=0;row<25;row++), and al==0 for each column before coming into the rowLoop.
je endRowLoop
mov dl,a
mov es:[bx],dl; dl stores the current character. set the character.
mov byte ptr es:[bx+1],0Ch; set the color to be red
mov dl,a
mov mk,0F0h
and dl,mk
mov cl,4 ;keep in mind that "ror dl,4" is wrong!
ror dl,cl ;now dl keeps the high 4 bit of the current character
cmp dl,0Ah 
jb addNum
add dl,37h ;dl+='A'-A
jmp endAdd
addNum:
add dl,30h ;dl+='0'-0
endAdd: ;now dl keeps the ascii code of the high 4 bit of the current character
mov es:[bx+2],dl ;set hex[0]
mov byte ptr es:[bx+3],0Ah ;set the color to be green
mov dl,a
mov mk,0Fh
and dl,mk ;now dl keeps the low 4 bit of the current character
cmp dl,0Ah
jb addNum1
add dl,37h ;dl+='A'-A
jmp endAdd1
addNum1:
add dl,30h ;dl+='0'-0
endAdd1: ;now dl keeps the ascii code of the low 4 bit of the current character
mov es:[bx+4],dl ;set hex[1]
mov byte ptr es:[bx+5],0Ah ;set the color to be green
inc a
cmp a,0
je Done ;a++; if((int)a>256) break;
inc al
add bx,160 ;calculate the pointer to the next row in current colunm
jmp rowLoop
endRowLoop:
inc col
jmp columnLoop
Done:
mov ah,0
int 16h
mov ah,4Ch
int 21h
code ends
end main