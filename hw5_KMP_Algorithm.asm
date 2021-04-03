;The problem to be addressed is actually a string matching problem.
;I implement KMP Algorithm in x86 Assembly to solve the problem
;Time complexity if O(m+n) instead of O(m*n) if implenmented in the naive way

.386
data segment use16
patternLength db 0
fileLength db 4 dup(0)
haveRead db 4 dup(0)
fp dw 0
hex db 100 dup(0) ;buffer for pattern
buf db 1024 dup(0) ;buffer for file
fileName db 100,?,100 dup(0) ;buffer for input filename
charHex db 240,?,240 dup(0) ;buffer for input pattern as ascii code
next db 100 dup(0) ;next[i] records the length of the greatest proper suffix of the string ending with (i-1)-th character which is also a prefix of the whole pattern.
;next[0]=-1
helloMesg1 db "Input file name:", 0Dh, 0Ah, "$"
helloMesg2 db "Input a hex string (at most 100 bytes), e.g. 41 42 43 0D 0A, partitioning each byte with space and ending with return.", 0Dh, 0Ah, "$"
errorMesg db "Format Error! Please input valid string.", 0Dh, 0Ah, "$"
errorFile db "Opening file failed!", 0Dh, 0Ah, "$"
emptyFile db "File is empty!",0Dh,0Ah,"$"
notFound db "Not found.", 0Dh, 0Ah, "$"
found db "found at $"
res db 8 dup(0), 0Dh, 0Ah, "$"
data ends

code segment use16
assume cs:code, ds:data
main:
mov ax, data
mov ds, ax

;input filename
mov ah, 9
mov dx, offset helloMesg1
int 21h
mov ah, 0Ah
mov dx, offset fileName
int 21h
mov ah, 2
mov dl, 0Dh
int 21h
mov ah, 2
mov dl, 0Ah
int 21h
mov al, ds:fileName[1]
cmp al, 0
je error_handler

;load file into memory
mov bx, 0
mov bl, al
add bl, 2
mov ds:fileName[bx], 0
mov ah, 3Dh
mov al, 0
mov dx, offset fileName
add dx, 2
clc
int 21h
jnc open_succeed
open_fail:
mov ah, 9
mov dx, offset errorFile
int 21h
mov ah, 1
int 21h
mov ah, 4Ch
int 21h

;find fileLength
open_succeed:
mov ds:[fp], ax
mov ah, 42h
mov al, 2
mov bx, ds:[fp]
xor cx, cx
xor dx, dx
int 21h
mov word ptr ds:fileLength[0], ax
mov word ptr ds:fileLength[2], dx
cmp dword ptr ds:[fileLength], 0
jg not_empty_file
mov ah, 9
mov dx, offset emptyFile
int 21h
mov ah, 1
int 21h
mov ah, 4Ch 
int 21h

;move file pointer to the beginning of the file
not_empty_file:
mov ah, 42h
mov al, 0
mov bx, ds:[fp]
xor cx, cx
xor dx, dx
int 21h

;input hex string in ascii
mov ah, 9
mov dx, offset helloMesg2
int 21h
mov ah, 0Ah
mov dx, offset charHex
int 21h
mov ah, 2
mov dl, 0Dh
int 21h
mov ah, 2
mov dl, 0Ah
int 21h
mov al, ds:charHex[1]
cmp al, 0
je error_handler

;convert ascii to hex number
mov di, offset charHex
add di, 2
mov si, offset hex
mov cl, 0
mov dl, 0
convert_loop:
	mov al, ds:[di]
	cmp al, '0'
	jb error_handler
	cmp al, '9'
	jbe process_0to9
	cmp al, 'A'
	jb error_handler
	cmp al, 'F'
	jg error_handler
	sub al, 'A'
	add al, 10
	jmp end_of_char_process
	process_0to9:
		sub al, '0'
	end_of_char_process:
	cmp cl, 1
	je low_4_bits
	;the processing ascii represents high 4 bits of a hex number
	mov bl, 10h
	mul bl
	mov dl, al
	jmp end_of_half_byte
	;the processing ascii represents low 4 bits of a hex number
	low_4_bits:
		add dl, al
		mov ds:[si], dl
		inc si
		inc di
		mov al, ds:[di]
		cmp al, 0Dh
		je end_of_convert_loop
		;if bytes are not separated by space, error occurs
		cmp al, 20h
		jne error_handler
	end_of_half_byte:
	inc di
	;when cl==0, process the high 4 bits; when cl==1, process the low 4 bits
	xor cl, 1
	jmp convert_loop

;handle illegal input
error_handler:
mov ah, 9
mov dx, offset errorMesg
int 21h
mov ah, 1
int 21h
mov ah, 4Ch
int 21h

;find patternLength
end_of_convert_loop:
sub si, offset hex
mov bx, si
mov ds:[patternLength], bl

;iteratively find the "next" array of hex
;to find next[di]
;bx=di-1
;while(bl!=-1) {
;if(hex[di-1]==hex[next[bx]]) {next[di]=next[bx]+1; break;}
;else if(bl!=-1) bl=next[bx]; }
mov di, 0
mov ds:next[di], -1
add di, 2
find_next:
	mov al, ds:hex[di]
	cmp al, 0
	je end_of_find_next
	mov bx, di
	dec bx
	mov al, ds:hex[bx]
	inner_find_loop:
		mov bl, ds:next[bx]
		cmp bl, -1
		je after_inner_loop_termination
		mov dl, ds:hex[bx]
		cmp al, dl
		jne inner_find_loop
		after_inner_loop_termination:
		inc bl
		mov ds:next[di], bl
		inc di
		jmp find_next

;prepare for the first pop bx in line 238
end_of_find_next:		
mov bx, 0
push bx

;fileLength stores the unread file length
;read cx chars to buf
match_loop:
mov eax, dword ptr ds:[fileLength]
mov ecx, 1024
cmp eax, ecx
jg read_1024_bytes
mov ecx, eax
read_1024_bytes:
sub eax, ecx
mov dword ptr ds:[fileLength], eax
mov ah, 3Fh
mov bx, ds:[fp]
mov dx, offset buf
int 21h


;match source and pattern using KMP Algorithm
;while(si!=length of buf(){
;if(bl==-1||buf[si]==hex[bx]){ si++; bx++; if(bl==patternLength) success(); continue;}
;else { bl=next[bx];continue;} }
mov si, 0
mov dl, ds:buf[si]
pop bx
pattern_matching:
	cmp bl, -1
	je success
	mov al, ds:hex[bx]
	cmp al, dl
	je success
	mov bl, ds:next[bx]
	jmp pattern_matching
	success:
	inc si
	inc bl
	cmp bl, ds:[patternLength]
	je matchAt
	cmp si, cx
	jne continue_match_buf
	cmp dword ptr ds:[fileLength], 0
	je notMatch
	add dword ptr ds:[haveRead], ecx
	push bx ;protect bx when switching buffer. i.e. keep the pointer of the pattern
	jmp match_loop
	continue_match_buf:
	mov dl, ds:buf[si]
	jmp pattern_matching
	
;matching success
matchAt:
mov ah, 9
mov dx, offset found
int 21h
mov eax, dword ptr ds:[haveRead]
and esi, 0000FFFFh
add eax, esi
movzx ebx, bx
sub eax, ebx
mov di, 8
;convert hex number to ascii code and output
output_loop:
dec di
mov cl, 0Fh
and cl, al
cmp cl, 0Ah
jb convert_0to9
add cl, 'A'
sub cl, 10
jmp after_convert
convert_0to9:
add cl, '0'
after_convert:
shr eax, 4
mov ds:res[di], cl
cmp di, 0
jne output_loop
mov ah, 9
mov dx, offset res
int 21h
jmp termination

;not match
notMatch:
mov ah, 9
mov dx, offset notFound
int 21h

;terminate
termination:
mov ah, 1
int 21h
mov ah, 4Ch
int 21h
code ends
end main