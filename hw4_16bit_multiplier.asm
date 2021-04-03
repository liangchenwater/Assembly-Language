.386
data segment use16
mulplier db 16,?,16 dup(0)
mulplicant db 16,?,16 dup(0)
res_decimal db 16 dup(0)
res_hex db 8 dup(0), "h",0Dh,0Ah,"$"
res_binary db 39 dup(0), "B",0Dh,0Ah,"$"
errorMesg db "Please input a decimal number <=65535!",0Dh,0Ah,"A error incurred. The program terminates",0Dh,0Ah,"$"
data ends

code segment use16
assume cs:code, ds:data
main:
mov ax, data
mov ds, ax

;read mulplicant and mulplier, ending with 0Dh
mov ah, 0Ah
mov dx, offset mulplicant
int 21h
mov ah, 2
mov dl, 0Dh
int 21h
mov dl, 0Ah
int 21h
mov ah, 0Ah
mov dx, offset mulplier
int 21h
push dx
mov ah, 2
mov dl, 0Dh
int 21h
mov dl, 0Ah
int 21h
pop bx


;convert mulplicant and mulplier from string to integer
add bx, 2
call convert_to_num
mov dx, offset mulplicant
add dx, 2
push ax
mov bx, dx
call convert_to_num

;calculate res=mulplicant*mulplier. Store res in {dx,ax} temporarily
pop bx
mul bx
push ax
push dx

;convert to binary. Store in res_binary
mov si, 0
mov di, 0 ;use di to judge fill blank or not
mov bx, offset res_binary
begin_of_binary_conversion:
cmp di, 4
jne fill_num
mov byte ptr ds:[bx+si], 20h
mov byte ptr ds:[bx+si+14h], 20h
mov di, 0
jmp incre_si
fill_num:
cmp si, 14h ;shift dx 16 times, and shift ax 16 times. +4 blanks
je end_of_binary_conversion
shl dx, 1
jc dx_fill1
mov byte ptr ds:[bx+si], '0'
jmp judge_ax
dx_fill1:
mov byte ptr ds:[bx+si], '1'
judge_ax:
shl ax, 1
jc ax_fill1
mov byte ptr ds:[bx+si+14h], '0' ;dx stores the high 16 bits and ax stores the low 16 bits.
jmp end_of_fill
ax_fill1:
mov byte ptr ds:[bx+si+14h], '1' 
end_of_fill:
inc di
incre_si:
inc si
jmp begin_of_binary_conversion
end_of_binary_conversion:
dec si
mov byte ptr [bx+si+14h], 'B'
pop dx
pop ax
push ax
push dx

;convert to hex. Store in res_hex
mov bx, offset res_hex
mov si, 3
begin_of_hex_conversion:
;handle dx
mov cx, 000Fh ;use a mask to get the lowest 4 bits. And shift dx and ax 4 bits right each round.
and cx, dx ;store lowest 4 bits in cx (cl)
cmp cx, 0Ah
jb below_ten
sub cl, 10
add cl, 'A' ;cl>=10, convert to letter
jmp end_of_char_conversion
below_ten:
add cl, '0' ;cl<=9, convert to digit
end_of_char_conversion:
mov ds:[bx+si], cl
;handle ax
mov cx, 000Fh
and cx, ax
cmp cx, 0Ah
jb below_ten_1
sub cl, 10
add cl, 'A'
jmp end_of_char_conversion_1
below_ten_1:
add cl, '0'
end_of_char_conversion_1:
mov ds:[bx+si+4], cl
;shift ax and dx 4 bits right to judge the next hex number
mov cl, 4
shr ax, cl
shr dx, cl
cmp si,0
je end_of_hex_conversion
dec si
jmp begin_of_hex_conversion
end_of_hex_conversion:
pop dx
pop ax

;prepare to convert res to decimal (string format). eax={dx:ax}
mov cl, 16
shl edx, cl
add eax, edx
mov edx, 0 ;very important! if edx remains the original value, "divide by zero"(overflow, quotient be 64-bit) error will be incurred!


;convert res to decimal (string format), keep in mind the string is in the inverse order.
mov si, 0
mov bx, offset res_decimal
cmp eax ,0 ;handle with special case when res==0
jne begin_of_decimal_conversion
mov byte ptr ds:[bx+si], '0'
inc si
jmp end_of_decimal_conversion
begin_of_decimal_conversion:
cmp eax, 0 ; 32-bit quotient stored in eax
;and 64-bit dividend is actually 32 bits, stored in {edx:eax} (actually eax)
;when the dividend (the quotient in the last round is 0), break.
je end_of_decimal_conversion
mov ecx, 10
div ecx ; 32-bit quotient stored in eax, 32-bit remainder(0<=remainder<=9) sotred in edx (dl)
add dl, '0'
mov ds:[bx+si], dl ;char=(res%10)+'0'; res=res/10;
inc si
mov edx, 0 ;very important! if edx remains the remainder of last round, "divide by zero"(overflow, quotient be 64-bit) error will be incurred!
jmp begin_of_decimal_conversion
end_of_decimal_conversion:

;reserve the maximum index of res_decimal
dec si
push si

;output mulplicant and mulplier
mov bx, offset mulplicant
add bx, 2
call puts
mov dl, '*'
mov ah, 2
int 21h
mov bx, offset mulplier
add bx, 2
call puts
mov dl, '='
int 21h
mov dl, 0Dh
int 21h
mov dl, 0Ah
int 21h

;output res_decimal, from tail to head!
pop si
mov bx, offset res_decimal
begin_of_res_decimal_output:
mov dl, ds:[bx+si]
int 21h
cmp si, 0
je end_of_res_decimal_output
dec si
jmp begin_of_res_decimal_output
end_of_res_decimal_output:
mov dl, 0Dh
int 21h
mov dl, 0Ah
int 21h

;output res_hex and res_binary
mov dx, offset res_hex
mov ah, 9
int 21h
mov dx, offset res_binary
int 21h

;termination
mov ah, 1
int 21h
mov ah, 4Ch
int 21h

;atoi
convert_to_num proc
mov di, 0
mov dx, 0
mov eax, 0
begin_of_convert_to_num:
mov dl, ds:[bx+di]
cmp dl, 0Dh
je end_of_fconvert
cmp dl, '0'
jb handle_error
cmp dl, '9'
jg handle_error ;if dl>'9' or dl<'1', output error message and terminate.
push dx ; prepare for mul, 32-bit (actually 16-bit) result in {dx:ax} (actually ax, and dx=0)
mov cx, 10
mul cx
mov cl, 10h
shl edx, cl
add eax, edx ; eax={dx:ax}
pop dx
sub dl, '0'
add ax, dx ;ax=ax*10+(dx-'0')
cmp eax, 0FFFFh
jg handle_error ; if the input number >=65536, output error message and terminate.
inc di
jmp begin_of_convert_to_num
end_of_fconvert:
ret
convert_to_num endp

;use to put mulplicant and mulplier. When current char==0Dh, break.
puts proc
mov si, 0
begin_of_puts:
mov dl, ds:[bx+si]
cmp dl, 0Dh
je end_of_fputs
mov ah,2
int 21h
inc si
jmp begin_of_puts
end_of_fputs:
ret
puts endp

;handle illegal input other than 0-9
handle_error:
mov ah, 9
mov dx, offset errorMesg
int 21h
mov ah, 1
int 21h
mov ah, 4Ch
int 21h

code ends
end main