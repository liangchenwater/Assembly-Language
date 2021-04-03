data segment
s db 100 dup(0)
t db 100 dup(0)
errorMessage db "Array size exceeds!",0Dh,0Ah,"$" ;s and t are adjacent, so check arrary size to avoid chaos.(This function can be removed.)
data ends
code segment
assume cs:code,ds:data
main:
mov ax,data
mov ds,ax
mov si,0 ;use si to represent the index of s[]
inputLoop: ; input char to s
mov ah,1
int 21h ; al=getchar()
mov byte ptr s[si], al ; s[si]=al
add si,1
cmp si,101
je outputErrorMessage ; s can carry 100 chars including '\0'
cmp al,0Dh
jne inputLoop ; if return is detected, terminate input.
mov byte ptr s[si-1],00h ; convert return to '\0'
mov si,0 
mov di,0 ;use di to represent the index of t[],reset index of s
convertLoop: ;save char from s to t according to requirements
mov al,s[si]
cmp al,20h
je increment ;if(s[si]==' ') continue;
cmp al,'a'
jb saveElement
cmp al,'z'
ja saveElement
sub al,20h ;if(s[si]>='a'&&s[si]<='z') s[si]+='A'-'a';
saveElement:
mov byte ptr t[di], al
add di,1 ; t[di++]=s[si];
increment:
add si,1 
cmp al,00h
jne convertLoop ;if(s[si-1]==0) break;
mov dl,0Ah
mov ah,2
int 21h
mov di,0 ; reset index of t
outputLoop:
mov dl,t[di]
mov ah,2
add di,1
cmp dl,00h
je outputLoopEnd ;if(t[di-1]==0) break;
int 21h ;putchar(t[di]);
jmp outputLoop 
outputLoopEnd:
mov dl,0Dh
mov ah,2
int 21h
mov dl,0Ah
mov ah,2
int 21h ;putchar('\r\n');
jmp exit
outputErrorMessage: ;output error message
mov dx, offset errorMessage
mov ah,9
int 21h
exit:
mov ah,4Ch
int 21h
code ends
end main