;
;  D52 V3.4.1 8052 Disassembly of hw.bin
;  2012/09/13 11:04
;

; NOTE:code page 0090h was accessed by program, IT'S REALLY CONFUSE ME.
; 自适应行程，高杆和低杆不启动，直到中杆位置出现50个RCP周期，SETTING键无效化

; 压缩版，程序体积小与8k

; 2013-3-7, break_point处让红色LED闪烁
; x25cc_start_loop 开始根据 motor_status 选择马达的行为，
; 这个值由 x2e69_verify_rcp 方法中根据杆位改变

$NOPAGING
$NOTABS


;NO_UART		equ		1


; P0.5 RCP input pin
; P2.0 system config button
; p0.1	fb_a
; p0.7	fb_b
; p0.3	fb_c

; p1.7	system voltage
; p0.0	temperature

$include(c8051f336.inc)

PACK	equ 1
PACK_DATA_ADDR	equ	1800h
;
;	Register/Memory Equates
;
rb0r0	equ	0
rb0r1	equ	1
rb0r2	equ	2
rb0r3	equ	3
rb0r4	equ	4
rb0r5	equ	5
rb0r6	equ	6
rb0r7	equ	7
rb1r0	equ	8
rb1r1	equ	9
rb1r2	equ	0ah
rb1r3	equ	0bh
rb1r4	equ	0ch
rb1r5	equ	0dh
rb1r6	equ	0eh
rb1r7	equ	0fh
rb2r0	equ	10h
rb2r1	equ	11h
rb2r2	equ	12h
rb2r3	equ	13h
rb2r4	equ	14h
rb2r6	equ	16h
rb2r7	equ	17h
rb3r0	equ	18h
rb3r1	equ	19h
rb3r2	equ	1ah
rb3r3	equ	1bh
rb3r4	equ	1ch
rb3r5	equ	1dh
rb3r6	equ	1eh
rb3r7	equ	1fh


; 0x3830 16bytes stores in internal ram 0x60

; rcp high/nuetral/low was store in first 6 bytes
; 0x3800 6bytes stores in internal ram 0x70


; P0.5 not analog mode, open-drain, skip crossbar



green_led	bit p1.3
red_led		bit	p1.4

fet_ap	bit		p1.6
fet_an	bit		p1.5
fet_bp	bit		p0.6
fet_bn	bit		p1.2
fet_cp	bit		p1.0
fet_cn	bit		p1.1



rcp_t0_ready		bit	20h.0
fresh_red			bit	22h.6
zc_point			bit	21h.1
stay_idle			bit	20h.1
forwarding				bit	20h.3
uart0_store_0b8h	bit	25h.0
skip_check_btn		bit	25h.4
sysvol_even			bit	23h.1
; fetch system temperture even time
temper_even			bit	23h.2
exchange_dir		bit	25h.5
dir_reverse			bit	21h.2
low_rcp				bit	21h.7
hi_pwm				bit	22h.2
fb_adc_timeout		bit 20h.5
go_run			bit	23h.6
temper1volt0		bit 23h.7

debug_flag			bit 20h.4
run_braking_cnt		equ	53h


ea_save				bit	25h.2
; program store erase flag
ps_erase			bit	25h.3

adc_busy			bit	26h.3
sum_code_err		bit 26h.5
rcp_x_8				bit 27h.1

first_3state		bit	25h.7
first_state			bit	22h.0

;constant variables
pb_param1			equ	5a0h



; memory address
forward_rcp_zone	equ	2ch
reverse_rcp_zone	equ	2dh
accelate_factor		equ	2eh
dead_rcp_zone		equ	3fh
motor_status		equ	59h

temp_sysvol			equ	51h
current_pwm			equ	35h

t3count_x			equ	48h
t3count_h			equ	47h

burden_volt			equ 40h
power_fail_volt		equ	36h
temp_temper			equ	42h
temper				equ	41h
temper_fail_time	equ	43h
startup_count			equ	4fh
state_index			equ	29h
rcp_l				equ	2ah
rcp_h				equ	2bh

rcp_max				equ	70h
rcp_nuetral			equ	72h
rcp_min				equ	74h

state_timeout			equ	44h

	cseg	at 0
;
X0000:
	ljmp	X3c34		; 0000   02 3c 34   .<4
;	ljmp	X0200		; 0003   02 02 00   ...
	push	psw
	ljmp	x1c79_int0
;	ajmp	X007b		; 0006   01 7b      .{
;	db	0a5h		; 0008   a5         %
;	ajmp	X007b		; 0009   01 7b      .{
org 0bh
	ljmp	X0203		; 000b   02 02 03   ...
;	ajmp	X007b		; 000e   01 7b      .{
;	db	0a5h		; 0010   a5         %
;	ajmp	X007b		; 0011   01 7b      .{
org 13h
	ljmp	X0206		; 0013   02 02 06   ...
;	ajmp	X007b		; 0016   01 7b      .{
;	db	0a5h		; 0018   a5         %
;	ajmp	X007b		; 0019   01 7b      .{
org 1bh
	ljmp	X0209		; 001b   02 02 09   ...
;	ajmp	X007b		; 001e   01 7b      .{
;	db	0a5h		; 0020   a5         %
;	ajmp	X007b		; 0021   01 7b      .{
org 23h
	ljmp	X020c		; 0023   02 02 0c   ...
;	ajmp	X007b		; 0026   01 7b      .{
;	db	0a5h		; 0028   a5         %
;	ajmp	X007b		; 0029   01 7b      .{
org 2bh
	ljmp	X020f		; 002b   02 02 0f   ...
;	ajmp	X007b		; 002e   01 7b      .{
;	db	0a5h		; 0030   a5         %
;	ajmp	X007b		; 0031   01 7b      .{
org 33h
	ljmp	X0212		; 0033   02 02 12   ...
;	ajmp	X007b		; 0036   01 7b      .{
;	db	0a5h		; 0038   a5         %
;	ajmp	X007b		; 0039   01 7b      .{
org 3bh
	ljmp	X0215		; 003b   02 02 15   ...
;	ajmp	X007b		; 003e   01 7b      .{
;	db	0a5h		; 0040   a5         %
;	ajmp	X007b		; 0041   01 7b      .{
org 43h
	ljmp	X0218		; 0043   02 02 18   ...
;	ajmp	X007b		; 0046   01 7b      .{
;	db	0a5h		; 0048   a5         %
;	ajmp	X007b		; 0049   01 7b      .{
org 4bh
	ljmp	X021b		; 004b   02 02 1b   ...
;	ajmp	X007b		; 004e   01 7b      .{
;	db	0a5h		; 0050   a5         %
;	ajmp	X007b		; 0051   01 7b      .{
org 53h
	ljmp	X021e		; 0053   02 02 1e   ...
;	ajmp	X007b		; 0056   01 7b      .{
;	db	0a5h		; 0058   a5         %
;	ajmp	X007b		; 0059   01 7b      .{
	ljmp	X0221		; 005b   02 02 21   ..!
org 5bh
	ajmp	X007b		; 005e   01 7b      .{
;	db	0a5h		; 0060   a5         %
;	ajmp	X007b		; 0061   01 7b      .{
org 63h
	ljmp	X0224		; 0063   02 02 24   ..$
;	ajmp	X007b		; 0066   01 7b      .{
;	db	0a5h		; 0068   a5         %
;	ajmp	X007b		; 0069   01 7b      .{
org 6bh
	ljmp	X0227		; 006b   02 02 27   ..'
;	ajmp	X007b		; 006e   01 7b      .{
;	db	0a5h		; 0070   a5         %
;	ajmp	X007b		; 0071   01 7b      .{
org 73h
;	ljmp	X022a		; 0073   02 02 2a   ..*
	push	psw
	push	acc
	ljmp	x1c94_t3ovfl
;	ajmp	X007b		; 0076   01 7b      .{
;
;	db	0a5h		; 0078   a5         %
;
;	ajmp	X007b		; 0079   01 7b      .{
;
org 7bh
X007b:	ajmp	X0000		; 007b   01 00      ..
;
X007d:
	push	dph		; 007d   c0 83      @.
	push	dpl		; 007f   c0 82      @.
	movx	a,@dptr		; 0081   e0         `
	mov		r6,a		; 0082   fe         ~
	inc		dptr		; 0083   a3         #
	movx	a,@dptr		; 0084   e0         `
	mov		r7,a		; 0085   ff         .
	clr	a		; 0086   e4         d
	mov	r4,a		; 0087   fc         |
	mov	r5,a		; 0088   fd         }
	mov	r0,a		; 0089   f8         x
	mov	a,r0		; 008a   e8         h
	mov	b,r7		; 008b   8f f0      .p
	mul	ab		; 008d   a4         $
	xch	a,r4		; 008e   cc         L
	mov	b,r3		; 008f   8b f0      .p

	mul	ab		; 0091   a4         $
	add	a,r4		; 0092   2c         ,
	mov	r4,a		; 0093   fc         |
	mov	a,r1		; 0094   e9         i
	mov	b,r6		; 0095   8e f0      .p
	mul	ab		; 0097   a4         $
	add	a,r4		; 0098   2c         ,
	mov	r4,a		; 0099   fc         |
	mov	b,r2		; 009a   8a f0      .p
	mov	a,r5		; 009c   ed         m
	mul	ab		; 009d   a4         $
	add	a,r4		; 009e   2c         ,
	mov	r4,a		; 009f   fc         |
	mov	a,r2		; 00a0   ea         j
	mov	b,r6		; 00a1   8e f0      .p
	mul	ab		; 00a3   a4         $
	xch	a,r5		; 00a4   cd         M
	mov	r0,b		; 00a5   a8 f0      (p
	mov	b,r3		; 00a7   8b f0      .p
	mul	ab		; 00a9   a4         $
	add	a,r5		; 00aa   2d         -
	xch	a,r4		; 00ab   cc         L
	addc	a,r0		; 00ac   38         8
	add	a,b		; 00ad   25 f0      %p
	mov	r5,a		; 00af   fd         }
	mov	a,r1		; 00b0   e9         i
	mov	b,r7		; 00b1   8f f0      .p
	mul	ab		; 00b3   a4         $
	add	a,r4		; 00b4   2c         ,
	xch	a,r5		; 00b5   cd         M
	addc	a,b		; 00b6   35 f0      5p
	mov	r4,a		; 00b8   fc         |
	mov	a,r3		; 00b9   eb         k
	mov	b,r6		; 00ba   8e f0      .p
	mul	ab		; 00bc   a4         $
	mov	r6,a		; 00bd   fe         ~
	mov	r1,b		; 00be   a9 f0      )p
	mov	a,r3		; 00c0   eb         k
	mov	b,r7		; 00c1   8f f0      .p
	mul	ab		; 00c3   a4         $
	xch	a,r7		; 00c4   cf         O
	xch	a,b		; 00c5   c5 f0      Ep
	add	a,r6		; 00c7   2e         .
	xch	a,r5		; 00c8   cd         M
	addc	a,r1		; 00c9   39         9
	mov	r6,a		; 00ca   fe         ~
	clr	a		; 00cb   e4         d
	addc	a,r4		; 00cc   3c         <
	mov	r4,a		; 00cd   fc         |
	mov	a,r2		; 00ce   ea         j
	mul	ab		; 00cf   a4         $
	add	a,r5		; 00d0   2d         -
	xch	a,r6		; 00d1   ce         N
	addc	a,b		; 00d2   35 f0      5p
	mov	r5,a		; 00d4   fd         }
	clr	a		; 00d5   e4         d
	addc	a,r4		; 00d6   3c         <
	mov	r4,a		; 00d7   fc         |
	clr	c		; 00d8   c3         C
	mov	a,#7fh		; 00d9   74 7f      t.
	subb	a,r6		; 00db   9e         .
	jnc	X00df		; 00dc   50 01      P.
	inc	r5		; 00de   0d         .
X00df:	pop	dpl		; 00df   d0 82      P.
	pop	dph		; 00e1   d0 83      P.
	mov	a,r4		; 00e3   ec         l
	movx	@dptr,a		; 00e4   f0         p
	inc	dptr		; 00e5   a3         #
	mov	a,r5		; 00e6   ed         m
	movx	@dptr,a		; 00e7   f0         p
	ret			; 00e8   22         "
;db	2eh,63h,6fh,6dh,2eh,63h,6eh		;.com.cn
;db	68h,6fh,62h,62h,79h,77h,69h,6eh,67h,2eh,63h,6fh,6dh,2eh,63h,6eh				;hobbywing.com.cn
;db	63h,7ch,77h,7bh,0f2h,6bh,6fh,0c5h,30h,01h,67h,2bh,0feh,0d7h,0abh,76h		;c|w{.ko.0.g+...v
;db	0cah,82h,0c9h,7dh,0fah,59h,47h,0f0h,0adh,0d4h,0a2h,0afh,9ch,0a4h,72h,0c0h	;...}.YG.......r.
;db	0b7h,0fdh,93h,26h,36h,3fh,0f7h,0cch,34h,0a5h,0e5h,0f1h,71h,0d8h,31h,15h		;...&6?..4...q.1.
;db	04h,0c7h,23h,0c3h,18h,96h,05h,9ah,07h,12h,80h,0e2h,0ebh,27h,0b2h,75h		;..#..........'.u
;db	09h,83h,2ch,1ah,1bh,6eh,5ah,0a0h,52h,3bh,0d6h,0b3h,29h,0e3h,2fh,84h			;..,..nZ.R;..)./.
;db	53h,0d1h,00h,0edh,20h,0fch,0b1h,5bh,6ah,0cbh,0beh,39h,4ah,4ch,58h,0cfh		;S... ..[j..9JLX.
;db	0d0h,0efh,0aah,0fbh,43h,4dh,33h,85h,45h,0f9h,02h,7fh,50h,3ch,9fh,0a8h		;....CM3.E..P<..
;db	51h,0a3h,40h,8fh,92h,9dh,38h,0f5h,0bch,0b6h,0dah,21h,10h,0ffh,0f3h,0d2h		;Q.@...8....!....
;db	0cdh,0ch,13h,0ech,5fh,97h,44h,17h,0c4h,0a7h,7eh,3dh,64h,5dh,19h,73h			;...._.D...~=d].s
;db	60h,81h,4fh,0dch,22h,2ah,90h,88h,46h,0eeh,0b8h,14h,0deh,5eh,0bh,0dbh		;`.O."*..F....^..
;db	0e0h,32h,3ah,0ah,49h,06h,24h,5ch,0c2h,0d3h,0ach,62h,91h,95h,0e4h,79h		;.2:.I.$\...b...y
;db	0e7h,0c8h,37h,6dh,8dh,0d5h,4eh,0a9h,6ch,56h,0f4h,0eah,65h,7ah,0aeh,08h		;..7m..N.lV..ez..
;db	0bah,78h,25h,2eh,1ch,0a6h,0b4h,0c6h,0e8h,0ddh,74h,1fh,4bh,0bdh,8bh,8ah		;.x%.......t.K...
;db	70h,3eh,0b5h,66h,48h,03h,0f6h,0eh,61h,35h,57h,0b9h,86h,0c1h,1dh,9eh			;p>.fH...a5W.....
;db	0e1h,0f8h,98h,11h,69h,0d9h,8eh,94h,9bh,1eh,87h,0e9h,0ceh,55h,28h,0dfh		;....i........U(.
;db	8ch,0a1h,89h,0dh,0bfh,0e6h,42h,68h,41h,99h,2dh,0fh,0b0h,54h,0bbh,16h		;......BhA.-..T..
break_point:
	mov		P1SKIP,#0ffh
	lcall	X2561_all_fet_off
	clr		ea
break_point_1:
	setb	red_led
	clr		green_led
	lcall	x31c2_longlonglong_delay
	setb	green_led
	clr		red_led
	lcall	x31c2_longlonglong_delay
	sjmp	break_point_1

test_code:
	lcall	x2e69_verify_rcp
	mov		a,motor_status
	sjmp	test_code

;	clr		ea
;	mov		dptr,#X3800
;	lcall	x1ecc_erase_page
;	lcall	x1e83_write_to_3800h
;	setb	green_led
;	lcall	x31c2_longlonglong_delay
;	clr		green_led
;	setb	red_led
;	sjmp	$

org		200h
X0200:	ljmp	x1c79_int0		; 0200   02 1c 79   ..y
X0203:	ljmp	X007b		; 0203   02 00 7b   ..{
X0206:	ljmp	X007b		; 0206   02 00 7b   ..{
X0209:	ljmp	X007b		; 0209   02 00 7b   ..{
if	PACK=0
X020c:	ljmp	x02ee_uart0		; 020c   02 02 ee   ..n
else
X020c:	ljmp	X007b
endif
X020f:	ljmp	X007b		; 020f   02 00 7b   ..{
X0212:	ljmp	X007b		; 0212   02 00 7b   ..{
X0215:	ljmp	X007b		; 0215   02 00 7b   ..{
X0218:	ljmp	X007b		; 0218   02 00 7b   ..{
X021b:	ljmp	X007b		; 021b   02 00 7b   ..{
X021e:	ljmp	X007b		; 021e   02 00 7b   ..{
X0221:	ljmp	X007b		; 0221   02 00 7b   ..{
X0224:	ljmp	X007b		; 0224   02 00 7b   ..{
X0227:	ljmp	X007b		; 0227   02 00 7b   ..{
X022a:	ljmp	x1c94_t3ovfl		; 022a   02 1c 94   ...
if	PACK=0
X022d:	ljmp	X0243		; 022d   02 02 43   ..C
endif
X0230:	ljmp	X1c00		; 0230   02 1c 00   ...
;db "V2.00_090310a_U "
if PACK=0
X0243:
	clr		ea		; 0243   c2 af      B/
	clr		a		; 0245   e4         d
	djnz	acc,$	; 0246   d5 e0 fd   U`}
	mov		sp,#0cfh	; 0249   75 81 cf   u.O
	mov		psw,#0		; 024c   75 d0 00   uP.
	mov		OSCICN,#0c1h	; 024f   75 b2 c1   u2A
	mov		CLKSEL,#0		; 0252   75 a9 00   u).
	mov		VDM0CN,#80h		; 0255   75 ff 80   u..
	anl		PCA0MD,#0bfh	; 0258   53 d9 bf   SY?
	mov		EMI0CN,#0		; 025b   75 aa 00   u*.
	mov		OSCICN,#0c3h	; 025e   75 b2 c3   u2C
	mov		EIE1,#0		; 0261   75 e6 00   uf.
	mov		EIP1,#0		; 0264   75 f6 00   uv.
	setb	uart0_store_0b8h		; 0267   d2 28      R(
	clr	25h.1		; 0269   c2 29      B)
	push	EMI0CN		; 026b   c0 aa      @*
	mov	EMI0CN,#1		; 026d   75 aa 01   u*.
	lcall	X112e		; 0270   12 11 2e   ...
	pop	EMI0CN		; 0273   d0 aa      P*
	push	EMI0CN		; 0275   c0 aa      @*
	mov	EMI0CN,#1		; 0277   75 aa 01   u*.
	mov	r3,#0ffh	; 027a   7b ff      {.
	mov	r2,#3ch		; 027c   7a 3c      z<
	mov	r1,#40h		; 027e   79 40      y@
	mov	rcp_min+1,#0ffh	; 0280   75 75 ff   uu.
	mov	76h,#3ch	; 0283   75 76 3c   uv<
	mov	77h,#50h	; 0286   75 77 50   uwP
	lcall	X130f		; 0289   12 13 0f   ...
	pop	EMI0CN		; 028c   d0 aa      P*
	mov	dptr,#X3c60	; 028e   90 3c 60   .<`
	lcall	X06dc		; 0291   12 06 dc   ..\ 
	lcall	X0a1a		; 0294   12 0a 1a   ...
	setb	red_led		; 0297   d2 94      R.
	lcall	X0940		; 0299   12 09 40   ..@
	lcall	X0a1a		; 029c   12 0a 1a   ...
	setb	uart0_store_0b8h		; 029f   d2 28      R(
	clr	25h.1		; 02a1   c2 29      B)
	mov	dptr,#X3810	; 02a3   90 38 10   .8.
	mov	a,#0		; 02a6   74 00      t.
	movc	a,@a+dptr	; 02a8   93         .
	mov	b,a		; 02a9   f5 f0      up
	mov	a,#2		; 02ab   74 02      t.
	clr	c		; 02ad   c3         C
	subb	a,b		; 02ae   95 f0      .p
	jc	X02b7		; 02b0   40 05      @.
	mov	reverse_rcp_zone,b		; 02b2   85 f0 2d   .p-
	ajmp	X02c1		; 02b5   41 c1      AA
;
X02b7:	mov	dptr,#X3730	; 02b7   90 37 30   .70
	mov	a,#0		; 02ba   74 00      t.
	movc	a,@a+dptr	; 02bc   93         .
	mov	reverse_rcp_zone,a		; 02bd   f5 2d      u-
	acall	X0790		; 02bf   f1 90      q.
X02c1:	lcall	X09ff		; 02c1   12 09 ff   ...
	lcall	X09f1		; 02c4   12 09 f1   ..q
	ajmp	X02c9		; 02c7   41 c9      AI
;
X02c9:	mov	XBR0,#1		; 02c9   75 e1 01   ua.
	mov	XBR1,#40h	; 02cc   75 e2 40   ub@
	anl	P0MDOUT,#0cfh	; 02cf   53 a4 cf   S$O
	anl	p0,#0cfh	; 02d2   53 80 cf   S.O
	lcall	X09c8		; 02d5   12 09 c8   ..H
	lcall	X09e8		; 02d8   12 09 e8   ..h
	acall	X0363		; 02db   71 63      qc
X02dd:	acall	X0322		; 02dd   71 22      q"
	jnb	27h.0,X02dd	; 02df   30 38 fb   08{
	acall	X036a		; 02e2   71 6a      qj
X02e4:	acall	X040b		; 02e4   91 0b      ..
	jb	27h.2,X02e4	; 02e6   20 3a fb    :{
	lcall	X09e8		; 02e9   12 09 e8   ..h
;	ajmp	X02dd		; 02ec   41 dd      A]
	sjmp	X02dd
;
x02ee_uart0:
	jb		uart0_store_0b8h,X02f4	; 02ee   20 28 03    (.
	ljmp	X1cf9		; 02f1   02 1c f9   ..y
X02f4:
	push	psw		; 02f4   c0 d0      @P
	push	acc		; 02f6   c0 e0      @`
	mov		20h,r0		; 02f8   88 20      . 
	clr		ti		; 02fa   c2 99      B.
	jnb		ri,X031b	; 02fc   30 98 1c   0..
	clr		ri		; 02ff   c2 98      B.
	jb		27h.0,X031b	; 0301   20 38 17    8.
	mov		a,#0d1h		; 0304   74 d1      tQ
	clr		c		; 0306   c3         C
	subb	a,rb2r6		; 0307   95 16      ..
	jc		X0316		; 0309   40 0b      @.
	mov		r0,rb2r6	; 030b   a8 16      (.
	mov		@r0,sbuf	; 030d   a6 99      &.
	inc		rb2r6		; 030f   05 16      ..
	mov		accelate_factor,#0		; 0311   75 2e 00   u..
	ajmp	X031b		; 0314   61 1b      a.
;
X0316:
	mov		rb2r6,#0b8h	; 0316   75 16 b8   u.8
	clr		27h.0		; 0319   c2 38      B8
X031b:
	mov		r0,20h		; 031b   a8 20      ( 
	pop		acc		; 031d   d0 e0      P`
	pop		psw		; 031f   d0 d0      PP
	reti			; 0321   32         2
;
X0322:
	jnb		tf1,X0362	; 0322   30 8f 3d   0.=
	clr		tf1		; 0325   c2 8f      B.
	jnb		red_led,X032e	; 0327   30 94 04   0..
	clr		red_led		; 032a   c2 94      B.
	ajmp	X0332		; 032c   61 32      a2
;
X032e:
	setb	red_led		; 032e   d2 94      R.
	ajmp	X0332		; 0330   61 32      a2
;
X0332:
	inc		accelate_factor		; 0332   05 2e      ..
	mov		a,#0c0h		; 0334   74 c0      t@
	clr		c		; 0336   c3         C
	subb	a,accelate_factor		; 0337   95 2e      ..
	jnc		X0362		; 0339   50 27      P'
	acall	X0366		; 033b   71 66      qf
	inc		2fh		; 033d   05 2f      ./
	mov		a,#0fah		; 033f   74 fa      tz
	clr		c		; 0341   c3         C
	subb	a,2fh		; 0342   95 2f      ./
	jnc		X0348		; 0344   50 02      P.
	acall	X0363		; 0346   71 63      qc
X0348:
	mov		a,rb2r6		; 0348   e5 16      e.
	clr		c		; 034a   c3         C
	subb	a,#0bch		; 034b   94 bc      .<
	jc		X035d		; 034d   40 0e      @.
	setb	27h.0		; 034f   d2 38      R8
	clr	ri		; 0351   c2 98      B.
	clr	ti		; 0353   c2 99      B.
	clr	ren		; 0355   c2 9c      B.
	clr	es		; 0357   c2 ac      B,
	setb	rcp_x_8		; 0359   d2 39      R9
	ajmp	X0362		; 035b   61 62      ab
;
X035d:
	mov	rb2r6,#0b8h	; 035d   75 16 b8   u.8
	clr	27h.0		; 0360   c2 38      B8
X0362:	ret			; 0362   22         "
;
X0363:
	mov	2fh,#0		; 0363   75 2f 00   u/.
X0366:
	mov	accelate_factor,#0		; 0366   75 2e 00   u..
	ret			; 0369   22         "
;
X036a:	jb	rcp_x_8,X036f	; 036a   20 39 02    9.
	ajmp	X0408		; 036d   81 08      ..
;
X036f:	acall	X0363		; 036f   71 63      qc
	mov	r0,#0b8h	; 0371   78 b8      x8
	cjne	@r0,#0a5h,X038b	; 0373   b6 a5 15   6%.
	mov	r0,rb2r6	; 0376   a8 16      (.
	dec	r0		; 0378   18         .
	cjne	@r0,#5ah,X038b	; 0379   b6 5a 0f   6Z.
	mov	a,rb2r6		; 037c   e5 16      e.
	clr	c		; 037e   c3         C
	subb	a,#0b8h		; 037f   94 b8      .8
	jc	X038b		; 0381   40 08      @.
	mov	r0,a		; 0383   f8         x
	clr	c		; 0384   c3         C
	subb	a,#19h		; 0385   94 19      ..
	jnc	X038b		; 0387   50 02      P.
	ajmp	X038d		; 0389   61 8d      a.
;
X038b:	ajmp	X0405		; 038b   81 05      ..
;
X038d:	mov	r0,#0b9h	; 038d   78 b9      x9
	mov	a,#0dh		; 038f   74 0d      t.
	clr	c		; 0391   c3         C
	subb	a,@r0		; 0392   96         .
	jc	X038b		; 0393   40 f6      @v
	mov	a,@r0		; 0395   e6         f
	inc	r0		; 0396   08         .
	mov	rcp_l,a		; 0397   f5 2a      u*
	mov	dptr,#X039e	; 0399   90 03 9e   ...
	rl	a		; 039c   23         #
	jmp	@a+dptr		; 039d   73         s
;
X039e:	ajmp	X03ba		; 039e   61 ba      a:
	ajmp	X0405		; 03a0   81 05      ..
	ajmp	X03c2		; 03a2   61 c2      aB
	ajmp	X03c7		; 03a4   61 c7      aG
	ajmp	X03cc		; 03a6   61 cc      aL
	ajmp	X0405		; 03a8   81 05      ..
	ajmp	X0405		; 03aa   81 05      ..
	ajmp	X03cc		; 03ac   61 cc      aL
	ajmp	X03cc		; 03ae   61 cc      aL
	ajmp	X03cc		; 03b0   61 cc      aL
	ajmp	X03cc		; 03b2   61 cc      aL
	ajmp	X0405		; 03b4   81 05      ..
	ajmp	X03cc		; 03b6   61 cc      aL
	ajmp	X0405		; 03b8   81 05      ..
X03ba:
	cjne	@r0,#0ffh,X0405	; 03ba   b6 ff 48   6.H
	lcall	X09ca		; 03bd   12 09 ca   ..J
	ajmp	X0401		; 03c0   81 01      ..
;
X03c2:
	cjne	@r0,#0fdh,X0405	; 03c2   b6 fd 40   6}@
	ajmp	X0401		; 03c5   81 01      ..
;
X03c7:
	cjne	@r0,#0fch,X0405	; 03c7   b6 fc 3b   6|;
	ajmp	X0401		; 03ca   81 01      ..
;
X03cc:	clr	26h.0		; 03cc   c2 30      B0
	clr	26h.1		; 03ce   c2 31      B1
	cjne	@r0,#0,X03d5	; 03d0   b6 00 02   6..
	setb	26h.0		; 03d3   d2 30      R0
X03d5:	mov	a,#10h		; 03d5   74 10      t.
	clr	c		; 03d7   c3         C
	subb	a,@r0		; 03d8   96         .
	jc	X0405		; 03d9   40 2a      @*
	jnz	X03df		; 03db   70 02      p.
	setb	26h.1		; 03dd   d2 31      R1
X03df:	mov	rcp_h,@r0		; 03df   86 2b      .+
	inc	r0		; 03e1   08         .
	mov	rb1r0,@r0	; 03e2   86 08      ..
	inc	r0		; 03e4   08         .
	mov	rb1r1,@r0	; 03e5   86 09      ..
	lcall	X082d		; 03e7   12 08 2d   ..-
	jb	26h.2,X0405	; 03ea   20 32 18    2.
	lcall	X083d		; 03ed   12 08 3d   ..=
	lcall	X084c		; 03f0   12 08 4c   ..L
	mov	r0,#0b8h	; 03f3   78 b8      x8
	mov	a,rcp_h		; 03f5   e5 2b      e+
	add	a,#5		; 03f7   24 05      $.
	mov	rb3r6,a		; 03f9   f5 1e      u.
	lcall	X0958		; 03fb   12 09 58   ..X
	jb	sum_code_err,X0405	; 03fe   20 35 04    5.
X0401:	setb	27h.2		; 0401   d2 3a      R:
	ajmp	X0408		; 0403   81 08      ..
;
X0405:	lcall	X09b6		; 0405   12 09 b6   ..6
X0408:	clr	rcp_x_8		; 0408   c2 39      B9
	ret			; 040a   22         "
;
X040b:	jb	27h.2,X0410	; 040b   20 3a 02    :.
	ajmp	X043d		; 040e   81 3d      .=
;
X0410:	mov	a,#0dh		; 0410   74 0d      t.
	clr	c		; 0412   c3         C
	subb	a,28h		; 0413   95 28      .(
	jc	X043a		; 0415   40 23      @#
	mov	a,28h		; 0417   e5 28      e(
	mov	dptr,#X041e	; 0419   90 04 1e   ...
	rl	a		; 041c   23         #
	jmp	@a+dptr		; 041d   73         s
;
X041e:	ajmp	X043e		; 041e   81 3e      .>
	ajmp	X043a		; 0420   81 3a      .:
	ajmp	X043a		; 0422   81 3a      .:
	ajmp	X043a		; 0424   81 3a      .:
	ajmp	X0441		; 0426   81 41      .A
	ajmp	X043a		; 0428   81 3a      .:
	ajmp	X043a		; 042a   81 3a      .:
	ajmp	X0444		; 042c   81 44      .D
	ajmp	X0441		; 042e   81 41      .A
	ajmp	X0444		; 0430   81 44      .D
	ajmp	X043e		; 0432   81 3e      .>
	ajmp	X043a		; 0434   81 3a      .:
	ajmp	X0441		; 0436   81 41      .A
	ajmp	X043a		; 0438   81 3a      .:
;
X043a:	lcall	X09b6		; 043a   12 09 b6   ..6
X043d:	ret			; 043d   22         "
;
X043e:	acall	X0447		; 043e   91 47      .G
	ret			; 0440   22         "
;
X0441:	acall	X04a8		; 0441   91 a8      .(
	ret			; 0443   22         "
;
X0444:	acall	X0546		; 0444   b1 46      1F
	ret			; 0446   22         "
;
X0447:	mov	dptr,#X044c	; 0447   90 04 4c   ..L
	ajmp	X063d		; 044a   c1 3d      A=
;
X044c:	ajmp	X0459		; 044c   81 59      .Y
;
	ajmp	X0486		; 044e   81 86      ..
;
	ajmp	X0454		; 0450   81 54      .T
;
	ajmp	X0454		; 0452   81 54      .T
;
X0454:	lcall	X09b6		; 0454   12 09 b6   ..6
	ajmp	X04a7		; 0457   81 a7      .'
;
X0459:	mov	a,rcp_l		; 0459   e5 2a      e*
	cjne	a,28h,X0454	; 045b   b5 28 f6   5(v
	mov	a,28h		; 045e   e5 28      e(
	cjne	a,#0,X0465	; 0460   b4 00 02   4..
	ajmp	X046a		; 0463   81 6a      .j
;
X0465:	cjne	a,#0ah,X0454	; 0465   b4 0a ec   4.l
	ajmp	X0474		; 0468   81 74      .t
;
X046a:	lcall	x08e9_send_x3c25_to_uart		; 046a   12 08 e9   ..i
	setb	25h.1		; 046d   d2 29      R)
	lcall	X09d9		; 046f   12 09 d9   ..Y
	ajmp	X04a7		; 0472   81 a7      .'
;
X0474:	jnb	adc_busy,X0454	; 0474   30 33 dd   03]
	jb	26h.0,X0454	; 0477   20 30 da    0Z
	mov	a,rcp_h		; 047a   e5 2b      e+
	cjne	a,#1,X0454	; 047c   b4 01 d5   4.U
	acall	X0790		; 047f   f1 90      q.
	mov	state_index,#1		; 0481   75 29 01   u).
	ajmp	X04a7		; 0484   81 a7      .'
;
X0486:	mov	a,28h		; 0486   e5 28      e(
	cjne	a,#0,X048d	; 0488   b4 00 02   4..
	ajmp	X0492		; 048b   81 92      ..
;
X048d:	cjne	a,#0ah,X0454	; 048d   b4 0a c4   4.D
	ajmp	X04a4		; 0490   81 a4      .$
;
X0492:	mov	a,rcp_l		; 0492   e5 2a      e*
	clr	c		; 0494   c3         C
	subb	a,#4		; 0495   94 04      ..
	jc	X0454		; 0497   40 bb      @;
	lcall	X09ce		; 0499   12 09 ce   ..N
	mov	rb1r2,rb1r0	; 049c   85 08 0a   ...
	mov	rb1r3,rb1r1	; 049f   85 09 0b   ...
	ajmp	X04a7		; 04a2   81 a7      .'
;
X04a4:	lcall	X09d7		; 04a4   12 09 d7   ..W
X04a7:	ret			; 04a7   22         "
;
X04a8:	mov	dptr,#X04ad	; 04a8   90 04 ad   ..-
	ajmp	X063d		; 04ab   c1 3d      A=
;
X04ad:	ajmp	X04ba		; 04ad   81 ba      .:
	ajmp	X04c4		; 04af   81 c4      .D
	ajmp	X04cf		; 04b1   81 cf      .O
	ajmp	X04dc		; 04b3   81 dc      .\
X04b5:	lcall	X09b6		; 04b5   12 09 b6   ..6
	ajmp	X0545		; 04b8   a1 45      !E
;
X04ba:	mov	a,rcp_l		; 04ba   e5 2a      e*
	cjne	a,28h,X04b5	; 04bc   b5 28 f6   5(v
	jnb	adc_busy,X04b5	; 04bf   30 33 f3   03s
	ajmp	X050c		; 04c2   a1 0c      !.
;
X04c4:	lcall	x08f0_send_x3c2a_to_uart		; 04c4   12 08 f0   ..p
	mov	state_index,#2		; 04c7   75 29 02   u).
	lcall	X09e1		; 04ca   12 09 e1   ..a
	ajmp	X0545		; 04cd   a1 45      !E
;
X04cf:	mov	a,rcp_l		; 04cf   e5 2a      e*
	cjne	a,28h,X04b5	; 04d1   b5 28 e1   5(a
	jb	26h.4,X050c	; 04d4   20 34 35    45
	jb	27h.3,X050c	; 04d7   20 3b 32    ;2
	ajmp	X04b5		; 04da   81 b5      .5
;
X04dc:	mov	a,28h		; 04dc   e5 28      e(
	cjne	a,#0ch,X04e3	; 04de   b4 0c 02   4..
	ajmp	X04f5		; 04e1   81 f5      .u
;
X04e3:	cjne	a,#4,X04e8	; 04e3   b4 04 02   4..
	ajmp	X0501		; 04e6   a1 01      !.
;
X04e8:	cjne	a,#8,X04b5	; 04e8   b4 08 ca   4.J
	jb	25h.6,X04f0	; 04eb   20 2e 02    ..
	ajmp	X04b5		; 04ee   81 b5      .5
;
X04f0:	lcall	X0794		; 04f0   12 07 94   ...
	ajmp	X0507		; 04f3   a1 07      !.
;
X04f5:	mov	rb3r7,#2	; 04f5   75 1f 02   u..
	lcall	X3caa		; 04f8   12 3c aa   .<*
	lcall	X09d7		; 04fb   12 09 d7   ..W
	ljmp	X3c79		; 04fe   02 3c 79   .<y
;
X0501:	mov	rb3r7,#0	; 0501   75 1f 00   u..
	lcall	X3caa		; 0504   12 3c aa   .<*
X0507:	lcall	X09d7		; 0507   12 09 d7   ..W
	ajmp	X0545		; 050a   a1 45      !E
;
X050c:	jb	26h.0,X0536	; 050c   20 30 27    0'
	jnb	26h.1,X04b5	; 050f   30 31 a3   01#
	mov	a,28h		; 0512   e5 28      e(
	cjne	a,#0ch,X0519	; 0514   b4 0c 02   4..
	ajmp	X0523		; 0517   a1 23      !#
;
X0519:	cjne	a,#4,X051e	; 0519   b4 04 02   4..
	ajmp	X0523		; 051c   a1 23      !#
;
X051e:	cjne	a,#8,X04b5	; 051e   b4 08 94   4..
	ajmp	X0534		; 0521   a1 34      !4
;
X0523:	jnb	26h.4,X052e	; 0523   30 34 08   04.
	anl	state_index,#3		; 0526   53 29 03   S).
	mov	a,state_index		; 0529   e5 29      e)
	cjne	a,#0,X0536	; 052b   b4 00 08   4..
X052e:	acall	X0644		; 052e   d1 44      QD
	acall	X0739		; 0530   f1 39      q9
	ajmp	X0536		; 0532   a1 36      !6
;
X0534:	acall	X0765		; 0534   f1 65      qe
X0536:	mov	rb1r2,rb1r0	; 0536   85 08 0a   ...
	mov	rb1r3,rb1r1	; 0539   85 09 0b   ...
	mov	state_index,#1		; 053c   75 29 01   u).
	jb	26h.1,X0545	; 053f   20 31 03    1.
	mov	state_index,#3		; 0542   75 29 03   u).
X0545:	ret			; 0545   22         "
;
X0546:	mov	dptr,#X054b	; 0546   90 05 4b   ..K
	ajmp	X063d		; 0549   c1 3d      A=
;
X054b:	ajmp	X0558		; 054b   a1 58      !X
;
	ajmp	X0574		; 054d   a1 74      !t
;
	ajmp	X05cb		; 054f   a1 cb      !K
;
	ajmp	X05e9		; 0551   a1 e9      !i
;
X0553:	lcall	X09b6		; 0553   12 09 b6   ..6
	ajmp	X063c		; 0556   c1 3c      A<
;
X0558:	mov	a,rcp_l		; 0558   e5 2a      e*
	cjne	a,28h,X0553	; 055a   b5 28 f6   5(v
	jnb	adc_busy,X0553	; 055d   30 33 f3   03s
	mov	a,28h		; 0560   e5 28      e(
	cjne	a,#7,X056a	; 0562   b4 07 05   4..
	jnb	26h.0,X0553	; 0565   30 30 eb   00k
	ajmp	X056f		; 0568   a1 6f      !o
;
X056a:	mov	a,rcp_h		; 056a   e5 2b      e+
	cjne	a,#1,X0553	; 056c   b4 01 e4   4.d
X056f:	mov	state_index,#1		; 056f   75 29 01   u).
	ajmp	X063c		; 0572   c1 3c      A<
;
X0574:	clr	26h.6		; 0574   c2 36      B6
	mov	a,28h		; 0576   e5 28      e(
	cjne	a,#7,X057d	; 0578   b4 07 02   4..
	ajmp	X0582		; 057b   a1 82      !.
;
X057d:	cjne	a,#9,X0553	; 057d   b4 09 d3   4.S
	ajmp	X0593		; 0580   a1 93      !.
;
X0582:	mov	r6,#0		; 0582   7e 00      ~.
	mov	r7,#0		; 0584   7f 00      ..
	mov	rb1r4,r6	; 0586   8e 0c      ..
	mov	rb1r5,r7	; 0588   8f 0d      ..
	mov	rb1r6,r6	; 058a   8e 0e      ..
	mov	rb1r7,r7	; 058c   8f 0f      ..
	mov	state_index,#2		; 058e   75 29 02   u).
	ajmp	X063c		; 0591   c1 3c      A<
;
X0593:	mov	r6,#0		; 0593   7e 00      ~.
	mov	r7,#0		; 0595   7f 00      ..
	mov	rb1r4,r6	; 0597   8e 0c      ..
	mov	rb1r5,r7	; 0599   8f 0d      ..
	mov	rb1r6,r6	; 059b   8e 0e      ..
	mov	rb1r7,r7	; 059d   8f 0f      ..
	mov	r0,#0bdh	; 059f   78 bd      x=
	mov	a,@r0		; 05a1   e6         f
	cjne	a,#0ffh,X05a7	; 05a2   b4 ff 02   4..
	ajmp	X05b8		; 05a5   a1 b8      !8
;
X05a7:	mov	b,a		; 05a7   f5 f0      up
	mov	a,#2		; 05a9   74 02      t.
	clr	c		; 05ab   c3         C
	subb	a,b		; 05ac   95 f0      .p
	jc	X0553		; 05ae   40 a3      @#
	mov	reverse_rcp_zone,b		; 05b0   85 f0 2d   .p-
	lcall	X0794		; 05b3   12 07 94   ...
	ajmp	X05c6		; 05b6   a1 c6      !F
;
X05b8:	mov	dptr,#X3800	; 05b8   90 38 00   .8.
	mov	r0,#0		; 05bb   78 00      x.
	mov	EMI0CN,#0		; 05bd   75 aa 00   u*.
	lcall	X3d08		; 05c0   12 3d 08   .=.
	lcall	X0ad8		; 05c3   12 0a d8   ..X
X05c6:	mov	state_index,#2		; 05c6   75 29 02   u).
	ajmp	X063c		; 05c9   c1 3c      A<
;
X05cb:	mov	a,28h		; 05cb   e5 28      e(
	cjne	a,#7,X05d2	; 05cd   b4 07 02   4..
	ajmp	X05d7		; 05d0   a1 d7      !W
;
X05d2:	cjne	a,#9,X05e7	; 05d2   b4 09 12   4..
	ajmp	X05dc		; 05d5   a1 dc      !\
;
X05d7:	lcall	X0873		; 05d7   12 08 73   ..s
	ajmp	X05df		; 05da   a1 df      !_
;
X05dc:	lcall	X0880		; 05dc   12 08 80   ...
X05df:	mov	state_index,#3		; 05df   75 29 03   u).
	lcall	X09e1		; 05e2   12 09 e1   ..a
	ajmp	X063c		; 05e5   c1 3c      A<
;
X05e7:	ajmp	X0553		; 05e7   a1 53      !S
;
X05e9:	mov	a,rcp_l		; 05e9   e5 2a      e*
	cjne	a,#2,X0633	; 05eb   b4 02 45   4.E
	mov	a,28h		; 05ee   e5 28      e(
	cjne	a,#7,X05f5	; 05f0   b4 07 02   4..
	ajmp	X05fa		; 05f3   a1 fa      !z
;
X05f5:	cjne	a,#9,X0631	; 05f5   b4 09 39   4.9
	ajmp	X0600		; 05f8   c1 00      A.
;
X05fa:	mov	r6,#3		; 05fa   7e 03      ~.
	mov	r7,#0		; 05fc   7f 00      ..
	ajmp	X0604		; 05fe   c1 04      A.
;
X0600:	mov	r6,#0fh		; 0600   7e 0f      ~.
	mov	r7,#0		; 0602   7f 00      ..
X0604:	mov	dpl,rb1r4	; 0604   85 0c 82   ...
	mov	rb1r6,dpl	; 0607   85 82 0e   ...
	mov	dph,rb1r5	; 060a   85 0d 83   ...
	mov	rb1r7,dph	; 060d   85 83 0f   ...
	inc	dptr		; 0610   a3         #
	mov	rb1r4,dpl	; 0611   85 82 0c   ...
	mov	rb1r5,dph	; 0614   85 83 0d   ...
	mov	a,r6		; 0617   ee         n
	cjne	a,dpl,X0621	; 0618   b5 82 06   5..
	mov	a,r7		; 061b   ef         o
	cjne	a,dph,X0621	; 061c   b5 83 02   5..
	setb	26h.6		; 061f   d2 36      R6
X0621:	clr	c		; 0621   c3         C
	mov	a,r6		; 0622   ee         n
	subb	a,dpl		; 0623   95 82      ..
	mov	a,r7		; 0625   ef         o
	subb	a,dph		; 0626   95 83      ..
	jc	X062c		; 0628   40 02      @.
	ajmp	X05cb		; 062a   a1 cb      !K
;
X062c:	lcall	X09d9		; 062c   12 09 d9   ..Y
	ajmp	X063c		; 062f   c1 3c      A<
;
X0631:	ajmp	X0553		; 0631   a1 53      !S
;
X0633:	mov	rb1r4,rb1r6	; 0633   85 0e 0c   ...
	mov	rb1r5,rb1r7	; 0636   85 0f 0d   ...
	mov	state_index,#2		; 0639   75 29 02   u).
X063c:	ret			; 063c   22         "
;
X063d:	anl	state_index,#3		; 063d   53 29 03   S).
	mov	a,state_index		; 0640   e5 29      e)
	rl	a		; 0642   23         #
	jmp	@a+dptr		; 0643   73         s
;
X0644:	clr	exchange_dir		; 0644   c2 2d      B-
	mov	a,#1fh		; 0646   74 1f      t.
	anl	a,rb1r0		; 0648   55 08      U.
	mov	r2,a		; 064a   fa         z
	cjne	r2,#0fh,X0650	; 064b   ba 0f 02   :..
	setb	exchange_dir		; 064e   d2 2d      R-
X0650:	clr	26h.7		; 0650   c2 37      B7
	mov	a,#0		; 0652   74 00      t.
	anl	a,rb1r1		; 0654   55 09      U.
	mov	r3,a		; 0656   fb         {
	mov	a,#0fh		; 0657   74 0f      t.
	anl	a,rb1r0		; 0659   55 08      U.
	mov	r2,a		; 065b   fa         z
	cjne	r2,#0fh,X0661	; 065c   ba 0f 02   :..
	setb	26h.7		; 065f   d2 37      R7
X0661:	lcall	x3d9c_dptr_r3r2x10h		; 0661   12 3d 9c   .=.
	mov	a,#0		; 0664   74 00      t.
	add	a,dpl		; 0666   25 82      %.
	mov	dpl,a		; 0668   f5 82      u.
	mov	a,#0		; 066a   74 00      t.
	addc	a,dph		; 066c   35 83      5.
	mov	dph,a		; 066e   f5 83      u.
	jnb	adc_busy,X06b8	; 0670   30 33 45   03E
	mov	a,28h		; 0673   e5 28      e(
	cjne	a,#0ch,X06b8	; 0675   b4 0c 40   4.@
	mov	r3,dph		; 0678   ab 83      +.
	mov	r2,dpl		; 067a   aa 82      *.
	mov	rb3r7,#1	; 067c   75 1f 01   u..
	lcall	X3caa		; 067f   12 3c aa   .<*
	mov	dph,r3		; 0682   8b 83      ..
	mov	dpl,r2		; 0684   8a 82      ..
	mov	r0,#0bdh	; 0686   78 bd      x=
	mov	r7,rcp_h		; 0688   af 2b      /+
X068a:	mov	a,@r0		; 068a   e6         f
	swap	a		; 068b   c4         D
	cpl	a		; 068c   f4         t
	mov	@r0,a		; 068d   f6         v
	movx	@dptr,a		; 068e   f0         p
	inc	r0		; 068f   08         .
	inc	dptr		; 0690   a3         #
	djnz	r7,X068a	; 0691   df f7      _w
	push	EMI0CN		; 0693   c0 aa      @*
	mov	EMI0CN,#1		; 0695   75 aa 01   u*.
	mov	r3,#0ffh	; 0698   7b ff      {.
	mov	r2,#0		; 069a   7a 00      z.
	mov	r1,#70h		; 069c   79 70      yp
	mov	rcp_min+1,#0ffh	; 069e   75 75 ff   uu.
	mov	76h,#0		; 06a1   75 76 00   uv.
	mov	77h,#80h	; 06a4   75 77 80   uw.
	lcall	X130f		; 06a7   12 13 0f   ...
	pop	EMI0CN		; 06aa   d0 aa      P*
	mov	dptr,#90h	; 06ac   90 00 90   ...
	lcall	X06dc		; 06af   12 06 dc   ..\ 
	acall	X0702		; 06b2   f1 02      q.
	acall	X0712		; 06b4   f1 12      q.
	ajmp	X06db		; 06b6   c1 db      A[
;
X06b8:	push	dph		; 06b8   c0 83      @.
	push	dpl		; 06ba   c0 82      @.
	push	EMI0CN		; 06bc   c0 aa      @*
	mov	EMI0CN,#1		; 06be   75 aa 01   u*.
	mov	r3,#0		; 06c1   7b 00      {.
	mov	r2,#0		; 06c3   7a 00      z.
	mov	r1,#0bdh	; 06c5   79 bd      y=
	mov	run_braking_cnt,#0		; 06c7   75 53 00   uS.
	mov	54h,#0		; 06ca   75 54 00   uT.
	mov	55h,#0bdh	; 06cd   75 55 bd   uU=
	lcall	X11f0		; 06d0   12 11 f0   ..p
	pop	EMI0CN		; 06d3   d0 aa      P*
	pop	dpl		; 06d5   d0 82      P.
	pop	dph		; 06d7   d0 83      P.
	acall	X0727		; 06d9   f1 27      q'
X06db:	ret			; 06db   22         "
;
X06dc:
	mov	r0,dph		; 06dc   a8 83      (.
	mov	r1,dpl		; 06de   a9 82      ).
	mov	r2,#high(1f0h)		; 06e0   7a 01      z.
	mov	r3,#low(1f0h)	; 06e2   7b f0      {p
	mov	b,#10h		; 06e4   75 f0 10   up.
X06e7:	mov	dph,r0		; 06e7   88 83      ..
	mov	dpl,r1		; 06e9   89 82      ..
	clr	a		; 06eb   e4         d
	movc	a,@a+dptr	; 06ec   93         .
	inc	dptr		; 06ed   a3         #
	mov	r0,dph		; 06ee   a8 83      (.
	mov	r1,dpl		; 06f0   a9 82      ).
	mov	dph,r2		; 06f2   8a 83      ..
	mov	dpl,r3		; 06f4   8b 82      ..
	swap	a		; 06f6   c4         D
	cpl	a		; 06f7   f4         t
	movx	@dptr,a		; 06f8   f0         p
	inc	dptr		; 06f9   a3         #
	mov	r2,dph		; 06fa   aa 83      *.
	mov	r3,dpl		; 06fc   ab 82      +.
	djnz	b,X06e7		; 06fe   d5 f0 e6   Upf
	ret			; 0701   22         "
;
X0702:	mov	dptr,#X0000	; 0702   90 00 00   ...
	mov	r0,#0a0h	; 0705   78 a0      x 
	mov	r7,rcp_h		; 0707   af 2b      /+
X0709:	mov	a,#0		; 0709   74 00      t.
	movc	a,@a+dptr	; 070b   93         .
	mov	@r0,a		; 070c   f6         v
	inc	dptr		; 070d   a3         #
	inc	r0		; 070e   08         .
	djnz	r7,X0709	; 070f   df f8      _x
	ret			; 0711   22         "
;
X0712:	mov	dptr,#X0000	; 0712   90 00 00   ...
	mov	r0,#0a0h	; 0715   78 a0      x 
	mov	r1,#90h		; 0717   79 90      y.
	mov	r7,rcp_h		; 0719   af 2b      /+
X071b:	movx	a,@dptr		; 071b   e0         `
	mov	b,@r0		; 071c   86 f0      .p
	xrl	a,b		; 071e   65 f0      ep
	mov	@r1,a		; 0720   f7         w
	inc	r0		; 0721   08         .
	inc	dptr		; 0722   a3         #
	inc	r1		; 0723   09         .
	djnz	r7,X071b	; 0724   df f5      _u
	ret			; 0726   22         "
;
X0727:	mov	r0,#0bdh	; 0727   78 bd      x=
	mov	r1,#90h		; 0729   79 90      y.
	mov	r7,rcp_h		; 072b   af 2b      /+
X072d:	mov	a,@r0		; 072d   e6         f
	mov	b,@r1		; 072e   87 f0      .p
	xrl	a,b		; 0730   65 f0      ep
	movx	@dptr,a		; 0732   f0         p
	inc	r0		; 0733   08         .
	inc	r1		; 0734   09         .
	inc	dptr		; 0735   a3         #
	djnz	r7,X072d	; 0736   df f5      _u
	ret			; 0738   22         "
;
X0739:	jnb	26h.7,X0764	; 0739   30 37 28   07(
	clr	26h.7		; 073c   c2 37      B7
	mov	r3,rb1r1	; 073e   ab 09      +.
	mov	a,#0f0h		; 0740   74 f0      tp
	anl	a,rb1r0		; 0742   55 08      U.
	mov	r2,a		; 0744   fa         z
	lcall	x3d9c_dptr_r3r2x10h		; 0745   12 3d 9c   .=.
	mov	a,#0		; 0748   74 00      t.
	add	a,dpl		; 074a   25 82      %.
	mov	dpl,a		; 074c   f5 82      u.
	mov	a,#1ch		; 074e   74 1c      t.
	addc	a,dph		; 0750   35 83      5.
	mov	dph,a		; 0752   f5 83      u.
	jnb	exchange_dir,X075c	; 0754   30 2d 05   0-.
	clr	exchange_dir		; 0757   c2 2d      B-
	lcall	x3d13_ps_erase0		; 0759   12 3d 13   .=.
X075c:	mov	r0,#0		; 075c   78 00      x.
	mov	EMI0CN,#0		; 075e   75 aa 00   u*.
	lcall	X3d62		; 0761   12 3d 62   .=b
X0764:	ret			; 0764   22         "
;
X0765:	clr	25h.6		; 0765   c2 2e      B.
	mov	a,#0		; 0767   74 00      t.
	anl	a,rb1r1		; 0769   55 09      U.
	mov	r3,a		; 076b   fb         {
	mov	a,#7		; 076c   74 07      t.
	anl	a,rb1r0		; 076e   55 08      U.
	mov	r2,a		; 0770   fa         z
	cjne	r2,#3,X0776	; 0771   ba 03 02   :..
	setb	25h.6		; 0774   d2 2e      R.
X0776:	lcall	x3d9c_dptr_r3r2x10h		; 0776   12 3d 9c   .=.
	mov	a,#0		; 0779   74 00      t.
	add	a,dpl		; 077b   25 82      %.
	mov	dpl,a		; 077d   f5 82      u.
	mov	a,#1		; 077f   74 01      t.
	addc	a,dph		; 0781   35 83      5.
	mov	dph,a		; 0783   f5 83      u.
	mov	r0,#0bdh	; 0785   78 bd      x=
	mov	r7,rcp_h		; 0787   af 2b      /+
X0789:	mov	a,@r0		; 0789   e6         f
	movx	@dptr,a		; 078a   f0         p
	inc	r0		; 078b   08         .
	inc	dptr		; 078c   a3         #
	djnz	r7,X0789	; 078d   df fa      _z
	ret			; 078f   22         "
;
X0790:	lcall	X0794		; 0790   12 07 94   ...
	ret			; 0793   22         "
;
X0794:	mov	dptr,#X3a00	; 0794   90 3a 00   .:.
	lcall	x3d13_ps_erase0		; 0797   12 3d 13   .=.
	mov	dptr,#X3800	; 079a   90 38 00   .8.
	mov	r0,#0		; 079d   78 00      x.
	mov	EMI0CN,#0		; 079f   75 aa 00   u*.
	lcall	X3d08		; 07a2   12 3d 08   .=.
	mov	a,28h		; 07a5   e5 28      e(
	cjne	a,#8,X07af	; 07a7   b4 08 05   4..
	lcall	X0a6b		; 07aa   12 0a 6b   ..k
	sjmp	X07da		; 07ad   80 2b      .+
;
X07af:	cjne	a,#9,X07b7	; 07af   b4 09 05   4..
	lcall	X0ad8		; 07b2   12 0a d8   ..X
	sjmp	X07da		; 07b5   80 23      .#
;
X07b7:	cjne	a,#0ah,X07d7	; 07b7   b4 0a 1d   4..
	mov	rb2r1,#40h	; 07ba   75 11 40   u.@
	mov	rb2r0,#37h	; 07bd   75 10 37   u.7
	lcall	X0a45		; 07c0   12 0a 45   ..E
	mov	rb2r3,#20h	; 07c3   75 13 20   u. 
	mov	rb2r2,#0	; 07c6   75 12 00   u..
	lcall	X0a58		; 07c9   12 0a 58   ..X
	mov	dpl,rb2r1	; 07cc   85 11 82   ...
	mov	dph,rb2r0	; 07cf   85 10 83   ...
	lcall	X081d		; 07d2   12 08 1d   ...
	sjmp	X07da		; 07d5   80 03      ..
;
X07d7:	ljmp	X007b		; 07d7   02 00 7b   ..{
;
X07da:	lcall	X080b		; 07da   12 08 0b   ...
	mov	dptr,#X3900	; 07dd   90 39 00   .9.
	mov	r0,#0		; 07e0   78 00      x.
	mov	EMI0CN,#0		; 07e2   75 aa 00   u*.
	lcall	X3d08		; 07e5   12 3d 08   .=.
	mov	dptr,#X3b00	; 07e8   90 3b 00   .;.
	mov	r0,#0		; 07eb   78 00      x.
	mov	EMI0CN,#0		; 07ed   75 aa 00   u*.
	lcall	X3d62		; 07f0   12 3d 62   .=b
	mov	dptr,#X3a00	; 07f3   90 3a 00   .:.
	mov	r2,dpl		; 07f6   aa 82      *.
	mov	r3,dph		; 07f8   ab 83      +.
	mov	dptr,#X3800	; 07fa   90 38 00   .8.
	mov	r4,dpl		; 07fd   ac 82      ,.
	mov	r5,dph		; 07ff   ad 83      -.
	lcall	x3d13_ps_erase0		; 0801   12 3d 13   .=.
	lcall	X3ce3		; 0804   12 3c e3   .<c
	lcall	X3ce3		; 0807   12 3c e3   .<c
	ret			; 080a   22         "
;
X080b:	mov	a,reverse_rcp_zone		; 080b   e5 2d      e-
	mov	dptr,#10h	; 080d   90 00 10   ...
	movx	@dptr,a		; 0810   f0         p
	mov	dptr,#X3a00	; 0811   90 3a 00   .:.
	mov	r0,#0		; 0814   78 00      x.
	mov	EMI0CN,#0		; 0816   75 aa 00   u*.
	lcall	X3d62		; 0819   12 3d 62   .=b
	ret			; 081c   22         "
;
X081d:	mov	r0,rb2r3	; 081d   a8 13      (.
	mov	EMI0CN,rb2r2	; 081f   85 12 aa   ..*
	mov	r7,#40h		; 0822   7f 40      .@
X0824:	mov	a,#0		; 0824   74 00      t.
	movc	a,@a+dptr	; 0826   93         .
	movx	@r0,a		; 0827   f2         r
	inc	r0		; 0828   08         .
	inc	dptr		; 0829   a3         #
	djnz	r7,X0824	; 082a   df f8      _x
	ret			; 082c   22         "
;
X082d:	clr	26h.2		; 082d   c2 32      B2
	mov	a,#0ffh		; 082f   74 ff      t.
	clr	c		; 0831   c3         C
	subb	a,rb1r0		; 0832   95 08      ..
	mov	a,#0fh		; 0834   74 0f      t.
	subb	a,rb1r1		; 0836   95 09      ..
	jnc	X083c		; 0838   50 02      P.
	setb	26h.2		; 083a   d2 32      R2
X083c:	ret			; 083c   22         "
;
X083d:	clr	adc_busy		; 083d   c2 33      B3
	mov	a,#0		; 083f   74 00      t.
	cjne	a,rb1r0,X084b	; 0841   b5 08 07   5..
	mov	a,#0		; 0844   74 00      t.
	cjne	a,rb1r1,X084b	; 0846   b5 09 02   5..
	setb	adc_busy		; 0849   d2 33      R3
X084b:	ret			; 084b   22         "
;
X084c:	clr	26h.4		; 084c   c2 34      B4
	clr	27h.3		; 084e   c2 3b      B;
	mov	a,rb1r2		; 0850   e5 0a      e.
	cjne	a,rb1r0,X085f	; 0852   b5 08 0a   5..
	mov	a,rb1r3		; 0855   e5 0b      e.
	cjne	a,rb1r1,X085f	; 0857   b5 09 05   5..
	setb	26h.4		; 085a   d2 34      R4
	ljmp	X0872		; 085c   02 08 72   ..r
;
X085f:	mov	dpl,rb1r2	; 085f   85 0a 82   ...
	mov	dph,rb1r3	; 0862   85 0b 83   ...
	inc	dptr		; 0865   a3         #
	mov	a,dpl		; 0866   e5 82      e.
	cjne	a,rb1r0,X0872	; 0868   b5 08 07   5..
	mov	a,dph		; 086b   e5 83      e.
	cjne	a,rb1r1,X0872	; 086d   b5 09 02   5..
	setb	27h.3		; 0870   d2 3b      R;
X0872:	ret			; 0872   22         "
;
X0873:	mov	a,#15h		; 0873   74 15      t.
	mov	rb3r6,a		; 0875   f5 1e      u.
	mov	rb2r6,#18h	; 0877   75 16 18   u..
	mov	2ch,rb2r6	; 087a   85 16 2c   ..,
	acall	X088d		; 087d   11 8d      ..
	ret			; 087f   22         "
;
X0880:	mov	a,#15h		; 0880   74 15      t.
	mov	rb3r6,a		; 0882   f5 1e      u.
	mov	rb2r6,#18h	; 0884   75 16 18   u..
	mov	2ch,rb2r6	; 0887   85 16 2c   ..,
	acall	X088d		; 088a   11 8d      ..
	ret			; 088c   22         "
;
X088d:	mov	r0,#0a1h	; 088d   78 a1      x!
	mov	@r0,28h		; 088f   a6 28      &(
	mov	a,#10h		; 0891   74 10      t.
	jnb	26h.6,X0898	; 0893   30 36 02   06.
	mov	a,#0		; 0896   74 00      t.
X0898:	inc	r0		; 0898   08         .
	mov	@r0,a		; 0899   f6         v
	mov	r7,a		; 089a   ff         .
	inc	r0		; 089b   08         .
	mov	@r0,rb1r4	; 089c   a6 0c      &.
	inc	r0		; 089e   08         .
	mov	@r0,rb1r5	; 089f   a6 0d      &.
	jb	26h.6,X08d4	; 08a1   20 36 30    60
	mov	r3,rb1r5	; 08a4   ab 0d      +.
	mov	r2,rb1r4	; 08a6   aa 0c      *.
	lcall	x3d9c_dptr_r3r2x10h		; 08a8   12 3d 9c   .=.
	mov	a,28h		; 08ab   e5 28      e(
	cjne	a,#7,X08ca	; 08ad   b4 07 1a   4..
	mov	r4,#0f0h	; 08b0   7c f0      |p
	mov	r5,#3bh		; 08b2   7d 3b      };
	mov	a,#0		; 08b4   74 00      t.
	cjne	a,rb1r4,X08c2	; 08b6   b5 0c 09   5..
	mov	a,#0		; 08b9   74 00      t.
	cjne	a,rb1r5,X08c2	; 08bb   b5 0d 04   5..
	mov	r4,#33h		; 08be   7c 33      |3
	mov	r5,#2		; 08c0   7d 02      }.
X08c2:	lcall	x3d90_dptr_plus_r5r4		; 08c2   12 3d 90   .=.
	lcall	X3db0		; 08c5   12 3d b0   .=0
	sjmp	X08d4		; 08c8   80 0a      ..
;
X08ca:	mov	r4,#low(100h)		; 08ca   7c 00      |.
	mov	r5,#high(100h)		; 08cc   7d 01      }.
	lcall	x3d90_dptr_plus_r5r4		; 08ce   12 3d 90   .=.
	lcall	x3db9_load_from_xram		; 08d1   12 3d b9   .=9
X08d4:	jnb	26h.6,X08db	; 08d4   30 36 04   06.
	mov	a,#5		; 08d7   74 05      t.
	mov	rb3r6,a		; 08d9   f5 1e      u.
X08db:	acall	x096a_calc_sum_code		; 08db   31 6a      1j
	mov	rb2r6,2ch	; 08dd   85 2c 16   .,.
	jnb	26h.6,X08e6	; 08e0   30 36 03   06.
	mov	rb2r6,#8	; 08e3   75 16 08   u..
X08e6:	acall	X090a		; 08e6   31 0a      1.
	ret			; 08e8   22         "
;
x08e9_send_x3c25_to_uart:	mov	dptr,#X3c25	; 08e9   90 3c 25   .<%
	lcall	X08fe		; 08ec   12 08 fe   ..~
	ret			; 08ef   22         "
;
x08f0_send_x3c2a_to_uart:	mov	dptr,#X3c2a	; 08f0   90 3c 2a   .<*
	lcall	X08fe		; 08f3   12 08 fe   ..~
	ret			; 08f6   22         "
;
x08f7_send_x3c2f_to_uart:	mov	dptr,#X3c2f	; 08f7   90 3c 2f   .</
	lcall	X08fe		; 08fa   12 08 fe   ..~
	ret			; 08fd   22         "
;
X08fe:	mov	r0,#0a0h	; 08fe   78 a0      x 
	mov	r7,#5		; 0900   7f 05      ..
	lcall	X3db0		; 0902   12 3d b0   .=0
	mov	rb2r6,a		; 0905   f5 16      u.
	acall	X090a		; 0907   31 0a      1.
	ret			; 0909   22         "
;
X090a:	mov	c,ea		; 090a   a2 af      "/
	mov	ea_save,c		; 090c   92 2a      .*
	clr	ea		; 090e   c2 af      B/
	mov	r0,#0a0h	; 0910   78 a0      x 
X0912:	mov	rb2r4,@r0	; 0912   86 14      ..
	lcall	X0920		; 0914   12 09 20   .. 
	inc	r0		; 0917   08         .
	djnz	rb2r6,X0912	; 0918   d5 16 f7   U.w
	mov	c,ea_save		; 091b   a2 2a      "*
	mov	ea,c		; 091d   92 af      ./
	ret			; 091f   22         "
;
X0920:	mov	a,rb2r4		; 0920   e5 14      e.
ifndef NO_UART
	mov	sbuf,a		; 0922   f5 99      u.
	jnb	ti,$	; 0924   30 99 fd   0.}
endif
	clr	ti		; 0927   c2 99      B.
	ret			; 0929   22         "
;
	acall	X092c		; 092a   31 2c      1,
X092c:	acall	X092e		; 092c   31 2e      1.
X092e:	acall	X0930		; 092e   31 30      10
X0930:	acall	X093b		; 0930   31 3b      1;
	acall	X093b		; 0932   31 3b      1;
	acall	X093b		; 0934   31 3b      1;
	acall	X093b		; 0936   31 3b      1;
	acall	X093b		; 0938   31 3b      1;
	ret			; 093a   22         "
;
X093b:	mov	23h,#14h	; 093b   75 23 14   u#.
	ajmp	X0944		; 093e   21 44      !D
;
X0940:	mov	23h,#4		; 0940   75 23 04   u#.
	nop			; 0943   00         .
X0944:	mov	22h,#3ch	; 0944   75 22 3c   u"<
	nop			; 0947   00         .
X0948:	mov	TMR3H,#0		; 0948   75 95 00   u..
	mov	21h,#0ffh	; 094b   75 21 ff   u!.
X094e:	djnz	21h,X094e	; 094e   d5 21 fd   U!}
	djnz	22h,X0948	; 0951   d5 22 f4   U"t
	djnz	23h,X0944	; 0954   d5 23 ed   U#m
	ret			; 0957   22         "
;
X0958:	clr	sum_code_err		; 0958   c2 35      B5
	acall	X0979		; 095a   31 79      1y
	mov	a,@r0		; 095c   e6         f
	cjne	a,rb3r3,X0967	; 095d   b5 1b 07   5..
	inc	r0		; 0960   08         .
	mov	a,@r0		; 0961   e6         f
	cjne	a,rb3r4,X0967	; 0962   b5 1c 02   5..
	ajmp	X0969		; 0965   21 69      !i
;
X0967:	setb	sum_code_err		; 0967   d2 35      R5
X0969:	ret			; 0969   22         "
;
x096a_calc_sum_code:	mov	r0,#0a0h	; 096a   78 a0      x 
	mov	@r0,#0a5h	; 096c   76 a5      v%
	acall	X0979		; 096e   31 79      1y
	mov	@r0,rb3r3	; 0970   a6 1b      &.
	inc	r0		; 0972   08         .
	mov	@r0,rb3r4	; 0973   a6 1c      &.
	inc	r0		; 0975   08         .
	mov	@r0,#5ah	; 0976   76 5a      vZ
	ret			; 0978   22         "
;
X0979:	mov	rb3r3,#0	; 0979   75 1b 00   u..
	mov	rb3r4,#0	; 097c   75 1c 00   u..
X097f:	mov	a,@r0		; 097f   e6         f
	xrl	a,rb3r4		; 0980   65 1c      e.
	mov	rb3r1,a		; 0982   f5 19      u.
	acall	X0995		; 0984   31 95      1.
	mov	a,rb3r0		; 0986   e5 18      e.
	xrl	a,rb3r3		; 0988   65 1b      e.
	mov	rb3r4,a		; 098a   f5 1c      u.
	mov	a,rb2r7		; 098c   e5 17      e.
	mov	rb3r3,a		; 098e   f5 1b      u.
	inc	r0		; 0990   08         .
	djnz	rb3r6,X097f	; 0991   d5 1e eb   U.k
	ret			; 0994   22         "
;
X0995:
	mov		rb2r7,#0	; 0995   75 17 00   u..
	mov		rb3r0,rb3r1	; 0998   85 19 18   ...
	mov		a,#8		; 099b   74 08      t.
	mov		rb3r2,a		; 099d   f5 1a      u.
X099f:
	clr		c		; 099f   c3         C
	mov		a,rb2r7		; 09a0   e5 17      e.
	rlc		a		; 09a2   33         3
	mov		rb2r7,a		; 09a3   f5 17      u.
	mov		a,rb3r0		; 09a5   e5 18      e.
	rlc		a		; 09a7   33         3
	mov		rb3r0,a		; 09a8   f5 18      u.
	jnc		X09b2		; 09aa   50 06      P.
	xrl		rb3r0,#10h	; 09ac   63 18 10   c..
	xrl		rb2r7,#21h	; 09af   63 17 21   c.!
X09b2:
	djnz	rb3r2,X099f	; 09b2   d5 1a ea   U.j
	ret			; 09b5   22         "
;
X09b6:	mov	a,rb3r5		; 09b6   e5 1d      e.
	clr	c		; 09b8   c3         C
	subb	a,#0ah		; 09b9   94 0a      ..
	jc	X09c1		; 09bb   40 04      @.
	acall	X09c8		; 09bd   31 c8      1H
	ajmp	X09c7		; 09bf   21 c7      !G
;
X09c1:	inc	rb3r5		; 09c1   05 1d      ..
	acall	x08f7_send_x3c2f_to_uart		; 09c3   11 f7      .w
	clr	27h.2		; 09c5   c2 3a      B:
X09c7:	ret			; 09c7   22         "
;
X09c8:
	clr		27h.2		; 09c8   c2 3a      B:
X09ca:
	mov		a,#0		; 09ca   74 00      t.
	ajmp	X09d0		; 09cc   21 d0      !P
;
X09ce:
	mov		a,rcp_l		; 09ce   e5 2a      e*
X09d0:
	mov		28h,a		; 09d0   f5 28      u(
	mov		state_index,#0		; 09d2   75 29 00   u).
	ajmp	X09e3		; 09d5   21 e3      !c
;
X09d7:	acall	x08f0_send_x3c2a_to_uart		; 09d7   11 f0      .p
X09d9:	mov	28h,#0		; 09d9   75 28 00   u(.
	mov	state_index,#1		; 09dc   75 29 01   u).
	ajmp	X09e1		; 09df   21 e1      !a
;
X09e1:	clr	27h.2		; 09e1   c2 3a      B:
X09e3:	mov	a,#0		; 09e3   74 00      t.
	mov	rb3r5,a		; 09e5   f5 1d      u.
	ret			; 09e7   22         "
;
X09e8:	clr	ea		; 09e8   c2 af      B/
	clr	ie0		; 09ea   c2 89      B.
	acall	X09f1		; 09ec   31 f1      1q
	setb	ea		; 09ee   d2 af      R/
	ret			; 09f0   22         "
;
X09f1:	mov	rb2r6,#0b8h	; 09f1   75 16 b8   u.8
	clr	27h.0		; 09f4   c2 38      B8
	clr	ri		; 09f6   c2 98      B.
	clr	ti		; 09f8   c2 99      B.
	setb	ren		; 09fa   d2 9c      R.
	setb	es		; 09fc   d2 ac      R,
	ret			; 09fe   22         "
;
X09ff:
	mov		scon,#20h	; 09ff   75 98 20   u. 
	mov		th1,#0cbh	; 0a02   75 8d cb   u.K
	anl		CKCON,#0f4h	; 0a05   53 8e f4   S.t
	mov		tl1,th1		; 0a08   85 8d 8b   ...
	anl		tmod,#0fh	; 0a0b   53 89 0f   S..
	orl		tmod,#20h	; 0a0e   43 89 20   C. 
	setb	tr1		; 0a11   d2 8e      R.
	clr		ri		; 0a13   c2 98      B.
	clr		ti		; 0a15   c2 99      B.
	setb	es		; 0a17   d2 ac      R,
	ret			; 0a19   22         "
;
X0a1a:	mov	OSCICN,#81h	; 0a1a   75 b2 81   u2.
	mov	CLKSEL,#0		; 0a1d   75 a9 00   u).
	mov	VDM0CN,#80h		; 0a20   75 ff 80   u..
	anl	PCA0MD,#0bfh	; 0a23   53 d9 bf   SY?
	lcall	x3d6b_pin_init		; 0a26   12 3d 6b   .=k
	mov	EIE1,#0		; 0a29   75 e6 00   uf.
	mov	EIP1,#0		; 0a2c   75 f6 00   uv.
	mov	ip,#1		; 0a2f   75 b8 01   u8.
	mov	ie,#80h		; 0a32   75 a8 80   u(.
	mov	IT01CF,#00000101b		; 0a35   75 e4 05   ud.
	mov	REF0CN,#0eh	; 0a38   75 d1 0e   uQ.
	mov	RSTSRC,#6		; 0a3b   75 ef 06   uo.
	mov	OSCICN,#83h	; 0a3e   75 b2 83   u2.
	mov	CLKSEL,#0		; 0a41   75 a9 00   u).
	ret			; 0a44   22         "
;
X0a45:	mov	b,#40h		; 0a45   75 f0 40   up@
	mov	a,reverse_rcp_zone		; 0a48   e5 2d      e-
	mul	ab		; 0a4a   a4         $
	add	a,rb2r1		; 0a4b   25 11      %.
	mov	rb2r1,a		; 0a4d   f5 11      u.
	mov	a,#0		; 0a4f   74 00      t.
	addc	a,b		; 0a51   35 f0      5p
	addc	a,rb2r0		; 0a53   35 10      5.
	mov	rb2r0,a		; 0a55   f5 10      u.
	ret			; 0a57   22         "
;
X0a58:	mov	a,reverse_rcp_zone		; 0a58   e5 2d      e-
	mov	b,#40h		; 0a5a   75 f0 40   up@
	mul	ab		; 0a5d   a4         $
	add	a,rb2r3		; 0a5e   25 13      %.
	mov	rb2r3,a		; 0a60   f5 13      u.
	mov	a,#0		; 0a62   74 00      t.
	addc	a,b		; 0a64   35 f0      5p
	addc	a,rb2r2		; 0a66   35 12      5.
	mov	rb2r2,a		; 0a68   f5 12      u.
	ret			; 0a6a   22         "
;
X0a6b:	mov	dptr,#100h	; 0a6b   90 01 00   ...
	mov	rb2r3,dpl	; 0a6e   85 82 13   ...
	mov	rb2r2,dph	; 0a71   85 83 12   ...
	movx	a,@dptr		; 0a74   e0         `
	mov	reverse_rcp_zone,a		; 0a75   f5 2d      u-
	mov	rb2r1,#20h	; 0a77   75 11 20   u. 
	mov	rb2r0,#0	; 0a7a   75 10 00   u..
	acall	X0a45		; 0a7d   51 45      QE
	mov	dptr,#122h	; 0a7f   90 01 22   .."
	acall	X0aa6		; 0a82   51 a6      Q&
	mov	dptr,#124h	; 0a84   90 01 24   ..$
	acall	X0a92		; 0a87   51 92      Q.
	mov	r7,#40h		; 0a89   7f 40      .@
X0a8b:	acall	X0aba		; 0a8b   51 ba      Q:
	acall	X0ac9		; 0a8d   51 c9      QI
	djnz	r7,X0a8b	; 0a8f   df fa      _z
	ret			; 0a91   22         "
;
X0a92:	mov	r3,#69h		; 0a92   7b 69      {i
	mov	r2,#5ch		; 0a94   7a 5c      z\
	mov	r1,#1		; 0a96   79 01      y.
	lcall	X007d		; 0a98   12 00 7d   ..}
	ret			; 0a9b   22         "
;
X0a9c:	mov	r3,#19h		; 0a9c   7b 19      {.
	mov	r2,#0bch	; 0a9e   7a bc      z<
	mov	r1,#0		; 0aa0   79 00      y.
	lcall	X007d		; 0aa2   12 00 7d   ..}
	ret			; 0aa5   22         "
;
X0aa6:	mov	r3,#0cch	; 0aa6   7b cc      {L
	mov	r2,#8ch		; 0aa8   7a 8c      z.
	mov	r1,#2		; 0aaa   79 02      y.
	lcall	X007d		; 0aac   12 00 7d   ..}
	ret			; 0aaf   22         "
;
X0ab0:	mov	r3,#64h		; 0ab0   7b 64      {d
	mov	r2,#64h		; 0ab2   7a 64      zd
	mov	r1,#0		; 0ab4   79 00      y.
	lcall	X007d		; 0ab6   12 00 7d   ..}
	ret			; 0ab9   22         "
;
X0aba:	mov	dpl,rb2r3	; 0aba   85 13 82   ...
	mov	dph,rb2r2	; 0abd   85 12 83   ...
	movx	a,@dptr		; 0ac0   e0         `
	inc	dptr		; 0ac1   a3         #
	mov	rb2r3,dpl	; 0ac2   85 82 13   ...
	mov	rb2r2,dph	; 0ac5   85 83 12   ...
	ret			; 0ac8   22         "
;
X0ac9:	mov	dpl,rb2r1	; 0ac9   85 11 82   ...
	mov	dph,rb2r0	; 0acc   85 10 83   ...
	movx	@dptr,a		; 0acf   f0         p
	inc	dptr		; 0ad0   a3         #
	mov	rb2r1,dpl	; 0ad1   85 82 11   ...
	mov	rb2r0,dph	; 0ad4   85 83 10   ...
	ret			; 0ad7   22         "
;
X0ad8:	mov	rb2r3,#0	; 0ad8   75 13 00   u..
	mov	rb2r2,#1	; 0adb   75 12 01   u..
	mov	rb2r1,#0b0h	; 0ade   75 11 b0   u.0
	mov	rb2r0,#36h	; 0ae1   75 10 36   u.6
	mov	r7,#10h		; 0ae4   7f 10      ..
X0ae6:	acall	X0b52		; 0ae6   71 52      qR
	acall	X0b43		; 0ae8   71 43      qC
	djnz	r7,X0ae6	; 0aea   df fa      _z
	mov	rb2r1,#40h	; 0aec   75 11 40   u.@
	mov	rb2r0,#37h	; 0aef   75 10 37   u.7
	acall	X0a45		; 0af2   51 45      QE
	mov	r7,#40h		; 0af4   7f 40      .@
X0af6:	acall	X0b52		; 0af6   71 52      qR
	acall	X0b43		; 0af8   71 43      qC
	djnz	r7,X0af6	; 0afa   df fa      _z
	mov	rb2r1,#0c0h	; 0afc   75 11 c0   u.@
	mov	rb2r0,#36h	; 0aff   75 10 36   u.6
	mov	r7,#60h		; 0b02   7f 60      .`
X0b04:	acall	X0b52		; 0b04   71 52      qR
	acall	X0b43		; 0b06   71 43      qC
	djnz	r7,X0b04	; 0b08   df fa      _z
	mov	rb2r1,#20h	; 0b0a   75 11 20   u. 
	mov	rb2r0,#38h	; 0b0d   75 10 38   u.8
	acall	X0a45		; 0b10   51 45      QE
	mov	r7,#40h		; 0b12   7f 40      .@
X0b14:	acall	X0b52		; 0b14   71 52      qR
	acall	X0b43		; 0b16   71 43      qC
	djnz	r7,X0b14	; 0b18   df fa      _z
	mov	dptr,#132h	; 0b1a   90 01 32   ..2
	acall	X0ab0		; 0b1d   51 b0      Q0
	mov	dptr,#172h	; 0b1f   90 01 72   ..r
	acall	X0ab0		; 0b22   51 b0      Q0
	mov	dptr,#192h	; 0b24   90 01 92   ...
	acall	X0ab0		; 0b27   51 b0      Q0
	mov	dptr,#1d2h	; 0b29   90 01 d2   ..R
	acall	X0ab0		; 0b2c   51 b0      Q0
	mov	dptr,#134h	; 0b2e   90 01 34   ..4
	acall	X0a9c		; 0b31   51 9c      Q.
	mov	dptr,#174h	; 0b33   90 01 74   ..t
	acall	X0a9c		; 0b36   51 9c      Q.
	mov	dptr,#194h	; 0b38   90 01 94   ...
	acall	X0a9c		; 0b3b   51 9c      Q.
	mov	dptr,#1d4h	; 0b3d   90 01 d4   ..T
	acall	X0a9c		; 0b40   51 9c      Q.
	ret			; 0b42   22         "
;
X0b43:	mov	dpl,rb2r3	; 0b43   85 13 82   ...
	mov	dph,rb2r2	; 0b46   85 12 83   ...
	movx	@dptr,a		; 0b49   f0         p
	inc	dptr		; 0b4a   a3         #
	mov	rb2r3,dpl	; 0b4b   85 82 13   ...
	mov	rb2r2,dph	; 0b4e   85 83 12   ...
	ret			; 0b51   22         "
;
X0b52:	mov	dpl,rb2r1	; 0b52   85 11 82   ...
	mov	dph,rb2r0	; 0b55   85 10 83   ...
	mov	a,#0		; 0b58   74 00      t.
	movc	a,@a+dptr	; 0b5a   93         .
	inc	dptr		; 0b5b   a3         #
	mov	rb2r1,dpl	; 0b5c   85 82 11   ...
	mov	rb2r0,dph	; 0b5f   85 83 10   ...
	ret			; 0b62   22         "
;
X0b63:	mov	67h,r3		; 0b63   8b 67      .g
	mov	68h,r2		; 0b65   8a 68      .h
	mov	69h,r1		; 0b67   89 69      .i
X0b69:	mov	r3,67h		; 0b69   ab 67      +g
	mov	r2,68h		; 0b6b   aa 68      *h
	mov	r1,69h		; 0b6d   a9 69      )i
	push	rb0r3		; 0b6f   c0 03      @.
	push	rb0r2		; 0b71   c0 02      @.
	push	rb0r1		; 0b73   c0 01      @.
	lcall	X0cf6		; 0b75   12 0c f6   ..v
	mov	r7,a		; 0b78   ff         .
	mov	r3,6ah		; 0b79   ab 6a      +j
	mov	r2,6bh		; 0b7b   aa 6b      *k
	mov	r1,6ch		; 0b7d   a9 6c      )l
	lcall	X0cf6		; 0b7f   12 0c f6   ..v
	xrl	a,r7		; 0b82   6f         o
	pop	rb0r1		; 0b83   d0 01      P.
	pop	rb0r2		; 0b85   d0 02      P.
	pop	rb0r3		; 0b87   d0 03      P.
	lcall	X0d0f		; 0b89   12 0d 0f   ...
	mov	a,#1		; 0b8c   74 01      t.
	add	a,69h		; 0b8e   25 69      %i
	mov	69h,a		; 0b90   f5 69      ui
	clr	a		; 0b92   e4         d
	addc	a,68h		; 0b93   35 68      5h
	mov	68h,a		; 0b95   f5 68      uh
	mov	a,#1		; 0b97   74 01      t.
	add	a,6ch		; 0b99   25 6c      %l
	mov	6ch,a		; 0b9b   f5 6c      ul
	clr	a		; 0b9d   e4         d
	addc	a,6bh		; 0b9e   35 6b      5k
	mov	6bh,a		; 0ba0   f5 6b      uk
	djnz	6dh,X0b69	; 0ba2   d5 6d c4   UmD
	ret			; 0ba5   22         "
;
X0ba6:	mov	67h,r3		; 0ba6   8b 67      .g
	mov	68h,r2		; 0ba8   8a 68      .h
	mov	69h,r1		; 0baa   89 69      .i
X0bac:	mov	r3,6ah		; 0bac   ab 6a      +j
	mov	r2,6bh		; 0bae   aa 6b      *k
	mov	r1,6ch		; 0bb0   a9 6c      )l
	lcall	X0cf6		; 0bb2   12 0c f6   ..v
	mov	r3,67h		; 0bb5   ab 67      +g
	mov	r2,68h		; 0bb7   aa 68      *h
	mov	r1,69h		; 0bb9   a9 69      )i
	lcall	X0d0f		; 0bbb   12 0d 0f   ...
	mov	a,#1		; 0bbe   74 01      t.
	add	a,69h		; 0bc0   25 69      %i
	mov	69h,a		; 0bc2   f5 69      ui
	clr	a		; 0bc4   e4         d
	addc	a,68h		; 0bc5   35 68      5h
	mov	68h,a		; 0bc7   f5 68      uh
	mov	a,#1		; 0bc9   74 01      t.
	add	a,6ch		; 0bcb   25 6c      %l
	mov	6ch,a		; 0bcd   f5 6c      ul
	clr	a		; 0bcf   e4         d
	addc	a,6bh		; 0bd0   35 6b      5k
	mov	6bh,a		; 0bd2   f5 6b      uk
	djnz	6dh,X0bac	; 0bd4   d5 6d d5   UmU
	ret			; 0bd7   22         "
;
X0bd8:	mov	r0,#0		; 0bd8   78 00      x.
	movx	a,@r0		; 0bda   e2         b
	mov	r7,a		; 0bdb   ff         .
	clr	a		; 0bdc   e4         d
	mov	r6,a		; 0bdd   fe         ~
X0bde:	mov	a,#1		; 0bde   74 01      t.
	add	a,r6		; 0be0   2e         .
	mov	r0,a		; 0be1   f8         x
	movx	a,@r0		; 0be2   e2         b
	mov	r5,a		; 0be3   fd         }
	mov	a,#0		; 0be4   74 00      t.
	add	a,r6		; 0be6   2e         .
	mov	r0,a		; 0be7   f8         x
	mov	a,r5		; 0be8   ed         m
	movx	@r0,a		; 0be9   f2         r
	inc	r6		; 0bea   0e         .
	cjne	r6,#0efh,X0bde	; 0beb   be ef f0   >op
	mov	r0,#0efh	; 0bee   78 ef      xo
	mov	a,r7		; 0bf0   ef         o
	movx	@r0,a		; 0bf1   f2         r
	ret			; 0bf2   22         "
;
;	org	0c00h
;
X0c00:	mov	a,@r1		; 0c00   e7         g
	inc	r1		; 0c01   09         .
	mov	@r0,a		; 0c02   f6         v
	inc	r0		; 0c03   08         .
	djnz	r7,X0c00	; 0c04   df fa      _z
	sjmp	X0c4e		; 0c06   80 46      .F
;
X0c08:	mov	a,@r1		; 0c08   e7         g
	inc	r1		; 0c09   09         .
	movx	@r0,a		; 0c0a   f2         r
	inc	r0		; 0c0b   08         .
	djnz	r7,X0c08	; 0c0c   df fa      _z
	sjmp	X0c4e		; 0c0e   80 3e      .>
;
X0c10:	mov	dpl,r0		; 0c10   88 82      ..
	mov	dph,r4		; 0c12   8c 83      ..
X0c14:	mov	a,@r1		; 0c14   e7         g
	inc	r1		; 0c15   09         .
	movx	@dptr,a		; 0c16   f0         p
	inc	dptr		; 0c17   a3         #
	djnz	r7,X0c14	; 0c18   df fa      _z
	sjmp	X0c4e		; 0c1a   80 32      .2
;
X0c1c:	movx	a,@r1		; 0c1c   e3         c
	inc	r1		; 0c1d   09         .
	mov	@r0,a		; 0c1e   f6         v
	inc	r0		; 0c1f   08         .
	djnz	r7,X0c1c	; 0c20   df fa      _z
	sjmp	X0c9c		; 0c22   80 78      .x
;
X0c24:	movx	a,@r1		; 0c24   e3         c
	inc	r1		; 0c25   09         .
	movx	@r0,a		; 0c26   f2         r
	inc	r0		; 0c27   08         .
	djnz	r7,X0c24	; 0c28   df fa      _z
	sjmp	X0c9c		; 0c2a   80 70      .p
;
X0c2c:	mov	dpl,r0		; 0c2c   88 82      ..
	mov	dph,r4		; 0c2e   8c 83      ..
X0c30:	movx	a,@r1		; 0c30   e3         c
	inc	r1		; 0c31   09         .
	movx	@dptr,a		; 0c32   f0         p
	inc	dptr		; 0c33   a3         #
	djnz	r7,X0c30	; 0c34   df fa      _z
	sjmp	X0c9c		; 0c36   80 64      .d
;
X0c38:	mov	dpl,r1		; 0c38   89 82      ..
	mov	dph,r2		; 0c3a   8a 83      ..
X0c3c:	movx	a,@dptr		; 0c3c   e0         `
	inc	dptr		; 0c3d   a3         #
	mov	@r0,a		; 0c3e   f6         v
	inc	r0		; 0c3f   08         .
	djnz	r7,X0c3c	; 0c40   df fa      _z
	sjmp	X0c9c		; 0c42   80 58      .X
;
X0c44:	mov	dpl,r1		; 0c44   89 82      ..
	mov	dph,r2		; 0c46   8a 83      ..
X0c48:	movx	a,@dptr		; 0c48   e0         `
	inc	dptr		; 0c49   a3         #
	movx	@r0,a		; 0c4a   f2         r
	inc	r0		; 0c4b   08         .
	djnz	r7,X0c48	; 0c4c   df fa      _z
X0c4e:	sjmp	X0c9c		; 0c4e   80 4c      .L
;
X0c50:	sjmp	X0c24		; 0c50   80 d2      .R
;
	sjmp	X0c4e		; 0c52   80 fa      .z
;
	sjmp	X0c1c		; 0c54   80 c6      .F
;
	sjmp	X0c2c		; 0c56   80 d4      .T
;
	sjmp	X0cc3		; 0c58   80 69      .i
;
	sjmp	X0c4e		; 0c5a   80 f2      .r
;
	sjmp	X0c91		; 0c5c   80 33      .3
;
	sjmp	X0c70		; 0c5e   80 10      ..
;
	sjmp	X0c08		; 0c60   80 a6      .&
;
	sjmp	X0c4e		; 0c62   80 ea      .j
;
	sjmp	X0c00		; 0c64   80 9a      ..
;
	sjmp	X0c10		; 0c66   80 a8      .(
;
	sjmp	X0c44		; 0c68   80 da      .Z
;
	sjmp	X0c4e		; 0c6a   80 e2      .b
;
	sjmp	X0c38		; 0c6c   80 ca      .J
;
	sjmp	X0ca3		; 0c6e   80 33      .3
;
X0c70:	mov	dpl,r1		; 0c70   89 82      ..
	mov	dph,r2		; 0c72   8a 83      ..
	mov	a,r4		; 0c74   ec         l
	mov	r2,a		; 0c75   fa         z
X0c76:	clr	a		; 0c76   e4         d
	movc	a,@a+dptr	; 0c77   93         .
	inc	dptr		; 0c78   a3         #
	xch	a,r0		; 0c79   c8         H
	xch	a,dpl		; 0c7a   c5 82      E.
	xch	a,r0		; 0c7c   c8         H
	xch	a,r4		; 0c7d   cc         L
	xch	a,dph		; 0c7e   c5 83      E.
	xch	a,r4		; 0c80   cc         L
	movx	@dptr,a		; 0c81   f0         p
	inc	dptr		; 0c82   a3         #
	xch	a,r0		; 0c83   c8         H
	xch	a,dpl		; 0c84   c5 82      E.
	xch	a,r0		; 0c86   c8         H
	xch	a,r4		; 0c87   cc         L
	xch	a,dph		; 0c88   c5 83      E.
	xch	a,r4		; 0c8a   cc         L
	djnz	r7,X0c76	; 0c8b   df e9      _i
	djnz	r6,X0c76	; 0c8d   de e7      ^g
	sjmp	X0c9e		; 0c8f   80 0d      ..
;
X0c91:	mov	dpl,r1		; 0c91   89 82      ..
	mov	dph,r2		; 0c93   8a 83      ..
X0c95:	clr	a		; 0c95   e4         d
	movc	a,@a+dptr	; 0c96   93         .
	inc	dptr		; 0c97   a3         #
	mov	@r0,a		; 0c98   f6         v
	inc	r0		; 0c99   08         .
	djnz	r7,X0c95	; 0c9a   df f9      _y
X0c9c:	mov	a,r4		; 0c9c   ec         l
	mov	r2,a		; 0c9d   fa         z
X0c9e:	mov	r1,b		; 0c9e   a9 f0      )p
	mov	a,r5		; 0ca0   ed         m
	mov	r3,a		; 0ca1   fb         {
	ret			; 0ca2   22         "
;
X0ca3:	mov	dpl,r1		; 0ca3   89 82      ..
	mov	dph,r2		; 0ca5   8a 83      ..
	mov	a,r4		; 0ca7   ec         l
	mov	r2,a		; 0ca8   fa         z
X0ca9:	movx	a,@dptr		; 0ca9   e0         `
	inc	dptr		; 0caa   a3         #
	xch	a,r0		; 0cab   c8         H
	xch	a,dpl		; 0cac   c5 82      E.
	xch	a,r0		; 0cae   c8         H
	xch	a,r4		; 0caf   cc         L
	xch	a,dph		; 0cb0   c5 83      E.
	xch	a,r4		; 0cb2   cc         L
	movx	@dptr,a		; 0cb3   f0         p
	inc	dptr		; 0cb4   a3         #
	xch	a,r0		; 0cb5   c8         H
	xch	a,dpl		; 0cb6   c5 82      E.
	xch	a,r0		; 0cb8   c8         H
	xch	a,r4		; 0cb9   cc         L
	xch	a,dph		; 0cba   c5 83      E.
	xch	a,r4		; 0cbc   cc         L
	djnz	r7,X0ca9	; 0cbd   df ea      _j
	djnz	r6,X0ca9	; 0cbf   de e8      ^h
	sjmp	X0c9e		; 0cc1   80 db      .[
;
X0cc3:	mov	dpl,r1		; 0cc3   89 82      ..
	mov	dph,r2		; 0cc5   8a 83      ..
X0cc7:	clr	a		; 0cc7   e4         d
	movc	a,@a+dptr	; 0cc8   93         .
	inc	dptr		; 0cc9   a3         #
	movx	@r0,a		; 0cca   f2         r
	inc	r0		; 0ccb   08         .
	djnz	r7,X0cc7	; 0ccc   df f9      _y
	sjmp	X0c9c		; 0cce   80 cc      .L
;
X0cd0:	mov	b,r0		; 0cd0   88 f0      .p
	mov	a,r7		; 0cd2   ef         o
	jz	X0cd6		; 0cd3   60 01      `.
	inc	r6		; 0cd5   0e         .
X0cd6:	orl	a,r6		; 0cd6   4e         N
	jz	X0c9c		; 0cd7   60 c3      `C
	mov	b,r0		; 0cd9   88 f0      .p
	mov	a,r5		; 0cdb   ed         m
	add	a,#2		; 0cdc   24 02      $.
	cjne	a,#4,X0ce1	; 0cde   b4 04 00   4..
X0ce1:	jnc	X0c9c		; 0ce1   50 b9      P9
	mov	dpl,a		; 0ce3   f5 82      u.
	mov	a,r3		; 0ce5   eb         k
	add	a,#2		; 0ce6   24 02      $.
	cjne	a,#4,X0ceb	; 0ce8   b4 04 00   4..
X0ceb:	jnc	X0c9c		; 0ceb   50 af      P/
	rl	a		; 0ced   23         #
	rl	a		; 0cee   23         #
	orl	a,dpl		; 0cef   45 82      E.
	rl	a		; 0cf1   23         #
	mov	dptr,#X0c50	; 0cf2   90 0c 50   ..P
	jmp	@a+dptr		; 0cf5   73         s
;
X0cf6:	cjne	r3,#1,X0cff	; 0cf6   bb 01 06   ;..
	mov	dpl,r1		; 0cf9   89 82      ..
	mov	dph,r2		; 0cfb   8a 83      ..
	movx	a,@dptr		; 0cfd   e0         `
	ret			; 0cfe   22         "
;
X0cff:	jnc	X0d03		; 0cff   50 02      P.
	mov	a,@r1		; 0d01   e7         g
	ret			; 0d02   22         "
;
X0d03:	cjne	r3,#0feh,X0d08	; 0d03   bb fe 02   ;~.
	movx	a,@r1		; 0d06   e3         c
	ret			; 0d07   22         "
;
X0d08:	mov	dpl,r1		; 0d08   89 82      ..
	mov	dph,r2		; 0d0a   8a 83      ..
	clr	a		; 0d0c   e4         d
	movc	a,@a+dptr	; 0d0d   93         .
	ret			; 0d0e   22         "
;
X0d0f:	cjne	r3,#1,X0d18	; 0d0f   bb 01 06   ;..
	mov	dpl,r1		; 0d12   89 82      ..
	mov	dph,r2		; 0d14   8a 83      ..
	movx	@dptr,a		; 0d16   f0         p
	ret			; 0d17   22         "
;
X0d18:	jnc	X0d1c		; 0d18   50 02      P.
	mov	@r1,a		; 0d1a   f7         w
	ret			; 0d1b   22         "
;
X0d1c:	cjne	r3,#0feh,X0d20	; 0d1c   bb fe 01   ;~.
	movx	@r1,a		; 0d1f   f3         s
X0d20:	ret			; 0d20   22         "
;
X0d21:	mov	67h,r3		; 0d21   8b 67      .g
	mov	68h,r2		; 0d23   8a 68      .h
	mov	69h,r1		; 0d25   89 69      .i
	clr	a		; 0d27   e4         d
	mov	r7,a		; 0d28   ff         .
X0d29:	clr	a		; 0d29   e4         d
	mov	r6,a		; 0d2a   fe         ~
X0d2b:	mov	r3,67h		; 0d2b   ab 67      +g
	inc	69h		; 0d2d   05 69      .i
	mov	a,69h		; 0d2f   e5 69      ei
	mov	r2,68h		; 0d31   aa 68      *h
	jnz	X0d37		; 0d33   70 02      p.
	inc	68h		; 0d35   05 68      .h
X0d37:	dec	a		; 0d37   14         .
	mov	r1,a		; 0d38   f9         y
	lcall	X0cf6		; 0d39   12 0c f6   ..v
	mov	r5,a		; 0d3c   fd         }
	mov	a,r6		; 0d3d   ee         n
	add	a,acc		; 0d3e   25 e0      %`
	add	a,acc		; 0d40   25 e0      %`
	add	a,#30h		; 0d42   24 30      $0
	add	a,r7		; 0d44   2f         /
	mov	r0,a		; 0d45   f8         x
	mov	@r0,rb0r5	; 0d46   a6 05      &.
	inc	r6		; 0d48   0e         .
	cjne	r6,#4,X0d2b	; 0d49   be 04 df   >._
	inc	r7		; 0d4c   0f         .
	cjne	r7,#4,X0d29	; 0d4d   bf 04 d9   ?.Y
	ret			; 0d50   22         "
;
X0d51:
db	0ah,40h,01h,02h,04h,08h,10h,20h,40h,80h,1bh,36h,00h

X0d5e:	ret			; 0d5e   22         "
;
X0d5f:	clr	a		; 0d5f   e4         d
	mov	67h,a		; 0d60   f5 67      ug
X0d62:	mov	r0,#6ah		; 0d62   78 6a      xj
	mov	r4,#0		; 0d64   7c 00      |.
	mov	r5,#0		; 0d66   7d 00      }.
	mov	r3,#0ffh	; 0d68   7b ff      {.
	mov	r2,#11h		; 0d6a   7a 11      z.
	mov	r1,#0		; 0d6c   79 00      y.
	mov	r6,#0		; 0d6e   7e 00      ~.
	mov	r7,#4		; 0d70   7f 04      ..
	lcall	X0cd0		; 0d72   12 0c d0   ..P
	mov	r0,#6eh		; 0d75   78 6e      xn
	mov	r4,#0		; 0d77   7c 00      |.
	mov	r5,#0		; 0d79   7d 00      }.
	mov	r3,#0ffh	; 0d7b   7b ff      {.
	mov	r2,#11h		; 0d7d   7a 11      z.
	mov	r1,#4		; 0d7f   79 04      y.
	mov	r6,#0		; 0d81   7e 00      ~.
	mov	r7,#4		; 0d83   7f 04      ..
	lcall	X0cd0		; 0d85   12 0c d0   ..P
	clr	a		; 0d88   e4         d
	mov	69h,a		; 0d89   f5 69      ui
X0d8b:	clr	a		; 0d8b   e4         d
	mov	68h,a		; 0d8c   f5 68      uh
X0d8e:	mov	a,#6ah		; 0d8e   74 6a      tj
	add	a,69h		; 0d90   25 69      %i
	mov	r0,a		; 0d92   f8         x
	push	rb0r0		; 0d93   c0 00      @.
	mov	a,@r0		; 0d95   e6         f
	mov	r6,a		; 0d96   fe         ~
	push	rb0r6		; 0d97   c0 06      @.
	mov	a,68h		; 0d99   e5 68      eh
	add	a,acc		; 0d9b   25 e0      %`
	add	a,acc		; 0d9d   25 e0      %`
	add	a,#30h		; 0d9f   24 30      $0
	add	a,67h		; 0da1   25 67      %g
	mov	r0,a		; 0da3   f8         x
	mov	a,@r0		; 0da4   e6         f
	mov	r5,a		; 0da5   fd         }
	mov	a,#6eh		; 0da6   74 6e      tn
	add	a,68h		; 0da8   25 68      %h
	mov	r0,a		; 0daa   f8         x
	mov	a,@r0		; 0dab   e6         f
	mov	r7,a		; 0dac   ff         .
	lcall	X12f5		; 0dad   12 12 f5   ..u
	pop	acc		; 0db0   d0 e0      P`
	xrl	a,r7		; 0db2   6f         o
	pop	rb0r0		; 0db3   d0 00      P.
	mov	@r0,a		; 0db5   f6         v
	inc	68h		; 0db6   05 68      .h
	mov	a,68h		; 0db8   e5 68      eh
	clr	c		; 0dba   c3         C
	subb	a,#4		; 0dbb   94 04      ..
	jc	X0d8e		; 0dbd   40 cf      @O
	mov	r7,rcp_max+1		; 0dbf   af 71      /q
	mov	rcp_max+1,rcp_max		; 0dc1   85 70 71   .pq
	mov	rcp_max,6fh		; 0dc4   85 6f 70   .op
	mov	6fh,6eh		; 0dc7   85 6e 6f   .no
	mov	6eh,r7		; 0dca   8f 6e      .n
	inc	69h		; 0dcc   05 69      .i
	mov	a,69h		; 0dce   e5 69      ei
	clr	c		; 0dd0   c3         C
	subb	a,#4		; 0dd1   94 04      ..
	jc	X0d8b		; 0dd3   40 b6      @6
	clr	a		; 0dd5   e4         d
	mov	69h,a		; 0dd6   f5 69      ui
X0dd8:	mov	a,#6ah		; 0dd8   74 6a      tj
	add	a,69h		; 0dda   25 69      %i
	mov	r0,a		; 0ddc   f8         x
	mov	a,@r0		; 0ddd   e6         f
	mov	r7,a		; 0dde   ff         .
	mov	a,69h		; 0ddf   e5 69      ei
	add	a,acc		; 0de1   25 e0      %`
	add	a,acc		; 0de3   25 e0      %`
	add	a,#30h		; 0de5   24 30      $0
	add	a,67h		; 0de7   25 67      %g
	mov	r0,a		; 0de9   f8         x
	mov	@r0,rb0r7	; 0dea   a6 07      &.
	inc	69h		; 0dec   05 69      .i
	mov	a,69h		; 0dee   e5 69      ei
	cjne	a,#4,X0dd8	; 0df0   b4 04 e5   4.e
	inc	67h		; 0df3   05 67      .g
	mov	a,67h		; 0df5   e5 67      eg
	clr	c		; 0df7   c3         C
	subb	a,#4		; 0df8   94 04      ..
	jnc	X0dff		; 0dfa   50 03      P.
	ljmp	X0d62		; 0dfc   02 0d 62   ..b
;
X0dff:	ret			; 0dff   22         "
;
;db	52h,09h,6ah,0d5h,30h,36h,0a5h,38h,0bfh,40h,0a3h,9eh,81h,0f3h,0d7h,0fbh		;R.j.06.8.@......
;db	7ch,0e3h,39h,82h,9bh,2fh,0ffh,87h,34h,8eh,43h,44h,0c4h,0deh,0e9h,0cbh		;|.9../..4.CD....
;db	54h,7bh,94h,32h,0a6h,0c2h,23h,3dh,0eeh,4ch,95h,0bh,42h,0fah,0c3h,4eh		;T{.2..#=.L..B..N
;db	08h,2eh,0a1h,66h,28h,0d9h,24h,0b2h,76h,5bh,0a2h,49h,6dh,8bh,0d1h,25h		;...f(.$.v[.Im..%
;db	72h,0f8h,0f6h,64h,86h,68h,98h,16h,0d4h,0a4h,5ch,0cch,5dh,65h,0b6h,92h		;r..d.h....\.]e..
;db	6ch,70h,48h,50h,0fdh,0edh,0b9h,0dah,5eh,15h,46h,57h,0a7h,8dh,9dh,84h		;lpHP....^.FW....
;db	90h,0d8h,0abh,00h,8ch,0bch,0d3h,0ah,0f7h,0e4h,58h,05h,0b8h,0b3h,45h,06h		;..........X...E.
;db	0d0h,2ch,1eh,8fh,0cah,3fh,0fh,02h,0c1h,0afh,0bdh,03h,01h,13h,8ah,6bh		;.,...?.........k
;db	3ah,91h,11h,41h,4fh,67h,0dch,0eah,97h,0f2h,0cfh,0ceh,0f0h,0b4h,0e6h,73h		;:..AOg.........s
;db	96h,0ach,74h,22h,0e7h,0adh,35h,85h,0e2h,0f9h,37h,0e8h,1ch,75h,0dfh,6eh		;..t"..5...7..u.n
;db	47h,0f1h,1ah,71h,1dh,29h,0c5h,89h,6fh,0b7h,62h,0eh,0aah,18h,0beh,1bh		;G..q.)..o.b.....
;db	0fch,56h,3eh,4bh,0c6h,0d2h,79h,20h,9ah,0dbh,0c0h,0feh,78h,0cdh,5ah,0f4h		;.V>K..y ....x.Z.
;db	1fh,0ddh,0a8h,33h,88h,07h,0c7h,31h,0b1h,12h,10h,59h,27h,80h,0ech,5fh		;...3...1...Y'.._
;db	60h,51h,7fh,0a9h,19h,0b5h,4ah,0dh,2dh,0e5h,7ah,9fh,93h,0c9h,9ch,0efh		;`Q...J.-.z.....
;db	0a0h,0e0h,3bh,4dh,0aeh,2ah,0f5h,0b0h,0c8h,0ebh,0bbh,3ch,83h,53h,99h,61h		;..;M.*.....<.S.a
;db	17h,2bh,04h,7eh,0bah,77h,0d6h,26h,0e1h,69h,14h,63h,55h,21h,0ch,7dh		;.+.~.w.&.i.cU!.}
;db	00h,00h,0c8h,08h,91h,10h,0d0h,36h,5ah,3eh,0d8h,43h,99h,77h,0feh,18h		;.......6Z>.C.w..
;db	23h,20h,07h,70h,0a1h,6ch,0ch,7fh,62h,8bh,40h,46h,0c7h,4bh,0e0h,0eh		;# .p.l.b.@F.K..
;db	0ebh,16h,0e8h,0adh,0cfh,0cdh,39h,53h,6ah,27h,35h,93h,0d4h,4eh,48h,0c3h		;......9Sj'5..NH.
;db	2bh,79h,54h,28h,09h,78h,0fh,21h,90h,87h,14h,2ah,0a9h,9ch,0d6h,74h		;+yT(.x.!...*...t
;db	0b4h,7ch,0deh,0edh,0b1h,86h,76h,0a4h,98h,0e2h,96h,8fh,02h,32h,1ch,0c1h		;.|....v......2..
;db	33h,0eeh,0efh,81h,0fdh,30h,5ch,13h,9dh,29h,17h,0c4h,11h,44h,8ch,80h		;3....0\..)...D..
;db	0f3h,73h,42h,1eh,1dh,0b5h,0f0h,12h,0d1h,5bh,41h,0a2h,0d7h,2ch,0e9h,0d5h		;.sB......[A..,..
;db	59h,0cbh,50h,0a8h,0dch,0fch,0f2h,56h,72h,0a6h,65h,2fh,9fh,9bh,3dh,0bah		;Y.P....Vr.e/..=.
;db	7dh,0c2h,45h,82h,0a7h,57h,0b6h,0a3h,7ah,75h,4fh,0aeh,3fh,37h,6dh,47h		;}.E..W..zuO.?7mG
;db	61h,0beh,0abh,0d3h,5fh,0b0h,58h,0afh,0cah,5eh,0fah,85h,0e4h,4dh,8ah,05h		;a..._.X..^...M..
;db	0fbh,60h,0b7h,7bh,0b8h,26h,4ah,67h,0c6h,1ah,0f8h,69h,25h,0b3h,0dbh,0bdh		;.`.{.&Jg...i%...
;db	66h,0ddh,0f1h,0d2h,0dfh,03h,8dh,34h,0d9h,92h,0dh,63h,55h,0aah,49h,0ech		;f......4...cU.I.
;db	0bch,95h,3ch,84h,0bh,0f5h,0e6h,0e7h,0e5h,0ach,7eh,6eh,0b9h,0f9h,0dah,8eh		;..<.......~n....
;db	9ah,0c9h,24h,0e1h,0ah,15h,6bh,3ah,0a0h,51h,0f4h,0eah,0b2h,97h,9eh,5dh		;..$...k:.Q.....]
;db	22h,88h,94h,0ceh,19h,01h,71h,4ch,0a5h,0e3h,0c5h,31h,0bbh,0cch,1fh,2dh		;".....qL...1...-
;db	3bh,52h,6fh,0f6h,2eh,89h,0f7h,0c0h,68h,1bh,64h,04h,06h,0bfh,83h,38h		;;Ro.....h.d....8
;db	01h,0e5h,4ch,0b5h,0fbh,9fh,0fch,12h,03h,34h,0d4h,0c4h,16h,0bah,1fh,36h		;..L......4.....6
;db	05h,5ch,67h,57h,3ah,0d5h,21h,5ah,0fh,0e4h,0a9h,0f9h,4eh,64h,63h,0eeh		;.\gW:.!Z....Ndc.
;db	11h,37h,0e0h,10h,0d2h,0ach,0a5h,29h,33h,59h,3bh,30h,6dh,0efh,0f4h,7bh		;.7.....)3Y;0m..{
;db	55h,0ebh,4dh,50h,0b7h,2ah,07h,8dh,0ffh,26h,0d7h,0f0h,0c2h,7eh,09h,8ch		;U.MP.*...&...~..
;db	1ah,6ah,62h,0bh,5dh,82h,1bh,8fh,2eh,0beh,0a6h,1dh,0e7h,9dh,2dh,8ah		;.jb.].........-.
;db	72h,0d9h,0f1h,27h,32h,0bch,77h,85h,96h,70h,08h,69h,56h,0dfh,99h,94h		;r..'2.w..p.iV...
;db	0a1h,90h,18h,0bbh,0fah,7ah,0b0h,0a7h,0f8h,0abh,28h,0d6h,15h,8eh,0cbh,0f2h		;.....z....(.....
;db	13h,0e6h,78h,61h,3fh,89h,46h,0dh,35h,31h,88h,0a3h,41h,80h,0cah,17h		;..xa?.F.51..A...
;db	5fh,53h,83h,0feh,0c3h,9bh,45h,39h,0e1h,0f5h,9eh,19h,5eh,0b6h,0cfh,4bh		;_S....E9....^..K
;db	38h,04h,0b9h,2bh,0e2h,0c1h,4ah,0ddh,48h,0ch,0d0h,7dh,3dh,58h,0deh,7ch		;8..+..J.H..}=X.|
;db	0d8h,14h,6bh,87h,47h,0e8h,79h,84h,73h,3ch,0bdh,92h,0c9h,23h,8bh,97h		;..k.G.y.s<...#..
;db	95h,44h,0dch,0adh,40h,65h,86h,0a2h,0a4h,0cch,7fh,0ech,0c0h,0afh,91h,0fdh		;.D..@e.........
;db	0f7h,4fh,81h,2fh,5bh,0eah,0a8h,1ch,02h,0d1h,98h,71h,0edh,25h,0e3h,24h		;.O./[......q.%.$
;db	06h,68h,0b3h,93h,2ch,6fh,3eh,6ch,0ah,0b8h,0ceh,0aeh,74h,0b1h,42h,0b4h		;.h..,o>l....t.B.
;db	1eh,0d3h,49h,0e9h,9ch,0c8h,0c6h,0c7h,22h,6eh,0dbh,20h,0bfh,43h,51h,52h		;..I....."n. .CQR
;db	66h,0b2h,76h,60h,0dah,0c5h,0f3h,0f6h,0aah,0cdh,9ah,0a0h,75h,54h,0eh,01h		;f.v`........uT..
;db	00h,00h,00h,00h,0eh,0bh,0dh,09h			;.........

X1108:	mov	a,r7		; 1108   ef         o
	swap	a		; 1109   c4         D
	anl	a,#0f0h		; 110a   54 f0      Tp
X110c:	mov	r7,a		; 110c   ff         .
	clr	a		; 110d   e4         d
	mov	r6,a		; 110e   fe         ~
X110f:	clr	a		; 110f   e4         d
	mov	r5,a		; 1110   fd         }
X1111:	mov	r4,rb0r7	; 1111   ac 07      ,.
	inc	r7		; 1113   0f         .
	mov	a,#0		; 1114   74 00      t.
	add	a,r4		; 1116   2c         ,
	mov	r0,a		; 1117   f8         x
	movx	a,@r0		; 1118   e2         b
	mov	r4,a		; 1119   fc         |
	mov	a,r5		; 111a   ed         m
X111b:	add	a,acc		; 111b   25 e0      %`
	add	a,acc		; 111d   25 e0      %`
	add	a,#80h		; 111f   24 80      $.
	add	a,r6		; 1121   2e         .
	mov	r0,a		; 1122   f8         x
	mov	@r0,rb0r4	; 1123   a6 04      &.
	inc	r5		; 1125   0d         .
	cjne	r5,#4,X1111	; 1126   bd 04 e8   =.h
	inc	r6		; 1129   0e         .
	cjne	r6,#4,X110f	; 112a   be 04 e2   >.b
	ret			; 112d   22         "

;
X112e:	mov	r0,#30h		; 112e   78 30      x0
	mov	r7,#50h		; 1130   7f 50      .P
	clr	a		; 1132   e4         d
X1133:	movx	@r0,a		; 1133   f2         r
	inc	r0		; 1134   08         .
	djnz	r7,X1133	; 1135   df fc      _|
	mov	dptr,#X0000	; 1137   90 00 00   ...
	mov	r7,#0ffh	; 113a   7f ff      ..
	mov	r6,#2		; 113c   7e 02      ~.
	clr	a		; 113e   e4         d
X113f:	movx	@dptr,a		; 113f   f0         p
	inc	dptr		; 1140   a3         #
	djnz	r7,X113f	; 1141   df fc      _|
	djnz	r6,X113f	; 1143   de fa      ^z
	mov	EMI0CN,#0		; 1145   75 aa 00   u*.
	mov	r0,#0		; 1148   78 00      x.
	mov	r7,#0ffh	; 114a   7f ff      ..
	clr	a		; 114c   e4         d
X114d:	movx	@r0,a		; 114d   f2         r
	inc	r0		; 114e   08         .
	djnz	r7,X114d	; 114f   df fc      _|
	ljmp	X118f		; 1151   02 11 8f   ...
;
X1154:	ljmp	X0d5e		; 1154   02 0d 5e   ..^
;
X1157:	clr	a		; 1157   e4         d
	movc	a,@a+dptr	; 1158   93         .
	inc	dptr		; 1159   a3         #
	mov	r0,a		; 115a   f8         x
X115b:	clr	a		; 115b   e4         d
	movc	a,@a+dptr	; 115c   93         .
	inc	dptr		; 115d   a3         #
	jc	X1163		; 115e   40 03      @.
	mov	@r0,a		; 1160   f6         v
	sjmp	X1164		; 1161   80 01      ..
;
X1163:	movx	@r0,a		; 1163   f2         r
X1164:	inc	r0		; 1164   08         .
	djnz	r7,X115b	; 1165   df f4      _t
	sjmp	X1192		; 1167   80 29      .)
;
X1169:	clr	a		; 1169   e4         d
	movc	a,@a+dptr	; 116a   93         .
	inc	dptr		; 116b   a3         #
	mov	r0,a		; 116c   f8         x
	anl	a,#7		; 116d   54 07      T.
	add	a,#0ch		; 116f   24 0c      $.
	xch	a,r0		; 1171   c8         H
	clr	c		; 1172   c3         C
	rlc	a		; 1173   33         3
	swap	a		; 1174   c4         D
	anl	a,#0fh		; 1175   54 0f      T.
	orl	a,#20h		; 1177   44 20      D 
	xch	a,r0		; 1179   c8         H
	movc	a,@a+pc		; 117a   83         .
	jc	X1181		; 117b   40 04      @.
	cpl	a		; 117d   f4         t
	anl	a,@r0		; 117e   56         V
	sjmp	X1182		; 117f   80 01      ..
;
X1181:	orl	a,@r0		; 1181   46         F
X1182:	mov	@r0,a		; 1182   f6         v
	djnz	r7,X1169	; 1183   df e4      _d
	sjmp	X1192		; 1185   80 0b      ..

	db 1,2,4,8,10h,20h,40h,80h
;
X118f:	mov	dptr,#X0d51	; 118f   90 0d 51   ..Q
X1192:	clr	a		; 1192   e4         d
	mov	r6,#1		; 1193   7e 01      ~.
	movc	a,@a+dptr	; 1195   93         .
	jz	X1154		; 1196   60 bc      `<
	inc	dptr		; 1198   a3         #
	mov	r7,a		; 1199   ff         .
	anl	a,#3fh		; 119a   54 3f      T?
	jnb	acc.5,X11a8	; 119c   30 e5 09   0e.
	anl	a,#1fh		; 119f   54 1f      T.
	mov	r6,a		; 11a1   fe         ~
	clr	a		; 11a2   e4         d
	movc	a,@a+dptr	; 11a3   93         .
	inc	dptr		; 11a4   a3         #
	jz	X11a8		; 11a5   60 01      `.
	inc	r6		; 11a7   0e         .
X11a8:	xch	a,r7		; 11a8   cf         O
	anl	a,#0c0h		; 11a9   54 c0      T@
	add	a,acc		; 11ab   25 e0      %`
	jz	X1157		; 11ad   60 a8      `(
	jc	X1169		; 11af   40 b8      @8
	clr	a		; 11b1   e4         d
	movc	a,@a+dptr	; 11b2   93         .
	inc	dptr		; 11b3   a3         #
	mov	r2,a		; 11b4   fa         z
	clr	a		; 11b5   e4         d
	movc	a,@a+dptr	; 11b6   93         .
	inc	dptr		; 11b7   a3         #
	mov	r0,a		; 11b8   f8         x
X11b9:	clr	a		; 11b9   e4         d
	movc	a,@a+dptr	; 11ba   93         .
	inc	dptr		; 11bb   a3         #
	xch	a,r0		; 11bc   c8         H
	xch	a,dpl		; 11bd   c5 82      E.
	xch	a,r0		; 11bf   c8         H
	xch	a,r2		; 11c0   ca         J
	xch	a,dph		; 11c1   c5 83      E.
	xch	a,r2		; 11c3   ca         J
	movx	@dptr,a		; 11c4   f0         p
	inc	dptr		; 11c5   a3         #
	xch	a,r0		; 11c6   c8         H
	xch	a,dpl		; 11c7   c5 82      E.
	xch	a,r0		; 11c9   c8         H
	xch	a,r2		; 11ca   ca         J
	xch	a,dph		; 11cb   c5 83      E.
	xch	a,r2		; 11cd   ca         J
	djnz	r7,X11b9	; 11ce   df e9      _i
	djnz	r6,X11b9	; 11d0   de e7      ^g
	sjmp	X1192		; 11d2   80 be      .>
;
X11d4:	clr	a		; 11d4   e4         d
	mov	r7,a		; 11d5   ff         .
X11d6:	clr	a		; 11d6   e4         d
	mov	r6,a		; 11d7   fe         ~
X11d8:	mov	a,r7		; 11d8   ef         o
	add	a,acc		; 11d9   25 e0      %`
	add	a,acc		; 11db   25 e0      %`
	add	a,#30h		; 11dd   24 30      $0
	add	a,r6		; 11df   2e         .
	mov	r0,a		; 11e0   f8         x
	mov	a,@r0		; 11e1   e6         f
	mov	dptr,#0e00h	; 11e2   90 0e 00   ...
	movc	a,@a+dptr	; 11e5   93         .
	mov	@r0,a		; 11e6   f6         v
	inc	r6		; 11e7   0e         .
	cjne	r6,#4,X11d8	; 11e8   be 04 ed   >.m
	inc	r7		; 11eb   0f         .
	cjne	r7,#4,X11d6	; 11ec   bf 04 e7   ?.g
	ret			; 11ef   22         "
;
X11f0:	mov	56h,#0eh	; 11f0   75 56 0e   uV.
	lcall	X0d21		; 11f3   12 0d 21   ..!
	mov	6ah,#0		; 11f6   75 6a 00   uj.
	mov	6bh,#0		; 11f9   75 6b 00   uk.
	mov	6ch,#30h	; 11fc   75 6c 30   ul0
	mov	6dh,#10h	; 11ff   75 6d 10   um.
	mov	r3,#0		; 1202   7b 00      {.
	mov	r2,#0		; 1204   7a 00      z.
	mov	r1,#57h		; 1206   79 57      yW
	lcall	X0ba6		; 1208   12 0b a6   ..&
	mov	r7,#0eh		; 120b   7f 0e      ..
	lcall	X1108		; 120d   12 11 08   ...
	lcall	X1274		; 1210   12 12 74   ..t
	mov	56h,#0dh	; 1213   75 56 0d   uV.
X1216:	lcall	X12cc		; 1216   12 12 cc   ..L
	lcall	X11d4		; 1219   12 11 d4   ..T
	mov	r7,56h		; 121c   af 56      /V
	lcall	X1108		; 121e   12 11 08   ...
	lcall	X1274		; 1221   12 12 74   ..t
	lcall	X0d5f		; 1224   12 0d 5f   .._
	dec	56h		; 1227   15 56      .V
	mov	a,56h		; 1229   e5 56      eV
	setb	c		; 122b   d3         S
	subb	a,#0		; 122c   94 00      ..
	jnc	X1216		; 122e   50 e6      Pf
	lcall	X12cc		; 1230   12 12 cc   ..L
	lcall	X11d4		; 1233   12 11 d4   ..T
	clr	a		; 1236   e4         d
	mov	r7,a		; 1237   ff         .
	lcall	X1108		; 1238   12 11 08   ...
	lcall	X1274		; 123b   12 12 74   ..t
	mov	6ah,#1		; 123e   75 6a 01   uj.
	mov	6bh,#1		; 1241   75 6b 01   uk.
	mov	6ch,#0f0h	; 1244   75 6c f0   ulp
	mov	6dh,#10h	; 1247   75 6d 10   um.
	mov	r3,#0		; 124a   7b 00      {.
	mov	r2,#0		; 124c   7a 00      z.
	mov	r1,#30h		; 124e   79 30      y0
	lcall	X0b63		; 1250   12 0b 63   ..c
	mov	r3,run_braking_cnt		; 1253   ab 53      +S
	mov	r2,54h		; 1255   aa 54      *T
	mov	r1,55h		; 1257   a9 55      )U
	lcall	X129c		; 1259   12 12 9c   ...
	mov	6ah,#0		; 125c   75 6a 00   uj.
	mov	6bh,#0		; 125f   75 6b 00   uk.
	mov	6ch,#57h	; 1262   75 6c 57   ulW
	mov	6dh,#10h	; 1265   75 6d 10   um.
	mov	r3,#1		; 1268   7b 01      {.
	mov	r2,#1		; 126a   7a 01      z.
	mov	r1,#0f0h	; 126c   79 f0      yp
	lcall	X0ba6		; 126e   12 0b a6   ..&
	ljmp	X0bd8		; 1271   02 0b d8   ..X
;
X1274:	clr	a		; 1274   e4         d
	mov	r7,a		; 1275   ff         .
X1276:	clr	a		; 1276   e4         d
	mov	r6,a		; 1277   fe         ~
X1278:	mov	a,r7		; 1278   ef         o
	add	a,acc		; 1279   25 e0      %`
	add	a,acc		; 127b   25 e0      %`
	add	a,#30h		; 127d   24 30      $0
	add	a,r6		; 127f   2e         .
	mov	r0,a		; 1280   f8         x
	push	rb0r0		; 1281   c0 00      @.
	mov	a,@r0		; 1283   e6         f
	mov	r5,a		; 1284   fd         }
	mov	a,r7		; 1285   ef         o
	add	a,acc		; 1286   25 e0      %`
	add	a,acc		; 1288   25 e0      %`
	add	a,#80h		; 128a   24 80      $.
	add	a,r6		; 128c   2e         .
	mov	r0,a		; 128d   f8         x
	mov	a,r5		; 128e   ed         m
	xrl	a,@r0		; 128f   66         f
	pop	rb0r0		; 1290   d0 00      P.
	mov	@r0,a		; 1292   f6         v
	inc	r6		; 1293   0e         .
	cjne	r6,#4,X1278	; 1294   be 04 e1   >.a
	inc	r7		; 1297   0f         .
	cjne	r7,#4,X1276	; 1298   bf 04 db   ?.[
	ret			; 129b   22         "
;
X129c:	mov	67h,r3		; 129c   8b 67      .g
	mov	68h,r2		; 129e   8a 68      .h
	mov	69h,r1		; 12a0   89 69      .i
	clr	a		; 12a2   e4         d
	mov	r7,a		; 12a3   ff         .
X12a4:	clr	a		; 12a4   e4         d
	mov	r6,a		; 12a5   fe         ~
X12a6:	mov	a,r6		; 12a6   ee         n
	add	a,acc		; 12a7   25 e0      %`
	add	a,acc		; 12a9   25 e0      %`
	add	a,#30h		; 12ab   24 30      $0
	add	a,r7		; 12ad   2f         /
	mov	r0,a		; 12ae   f8         x
	mov	a,@r0		; 12af   e6         f
	mov	r5,a		; 12b0   fd         }
	mov	r3,67h		; 12b1   ab 67      +g
	inc	69h		; 12b3   05 69      .i
	mov	a,69h		; 12b5   e5 69      ei
	mov	r2,68h		; 12b7   aa 68      *h
	jnz	X12bd		; 12b9   70 02      p.
	inc	68h		; 12bb   05 68      .h
X12bd:	dec	a		; 12bd   14         .
	mov	r1,a		; 12be   f9         y
	mov	a,r5		; 12bf   ed         m
	lcall	X0d0f		; 12c0   12 0d 0f   ...
	inc	r6		; 12c3   0e         .
	cjne	r6,#4,X12a6	; 12c4   be 04 df   >._
	inc	r7		; 12c7   0f         .
	cjne	r7,#4,X12a4	; 12c8   bf 04 d9   ?.Y
	ret			; 12cb   22         "
;
X12cc:	mov	r7,37h		; 12cc   af 37      /7
	mov	37h,power_fail_volt		; 12ce   85 36 37   .67
	mov	power_fail_volt,current_pwm		; 12d1   85 35 36   .56
	mov	current_pwm,34h		; 12d4   85 34 35   .45
	mov	34h,r7		; 12d7   8f 34      .4
	mov	r7,3ah		; 12d9   af 3a      /:
	mov	3ah,38h		; 12db   85 38 3a   .8:
	mov	38h,r7		; 12de   8f 38      .8
	mov	r7,3bh		; 12e0   af 3b      /;
	mov	3bh,39h		; 12e2   85 39 3b   .9;
	mov	39h,r7		; 12e5   8f 39      .9
	mov	r7,3ch		; 12e7   af 3c      /<
	mov	3ch,3dh		; 12e9   85 3d 3c   .=<
	mov	3dh,3eh		; 12ec   85 3e 3d   .>=
	mov	3eh,dead_rcp_zone		; 12ef   85 3f 3e   .?>
	mov	dead_rcp_zone,r7		; 12f2   8f 3f      .?
	ret			; 12f4   22         "
;
X12f5:	mov	a,r5		; 12f5   ed         m
	jnz	X12fa		; 12f6   70 02      p.
	mov	r7,a		; 12f8   ff         .
	ret			; 12f9   22         "
;
X12fa:	mov	a,r5		; 12fa   ed         m
	mov	dptr,#0f00h	; 12fb   90 0f 00   ...
	movc	a,@a+dptr	; 12fe   93         .
	mov	r6,a		; 12ff   fe         ~
	mov	a,r7		; 1300   ef         o
	movc	a,@a+dptr	; 1301   93         .
	add	a,r6		; 1302   2e         .
	mov	r7,a		; 1303   ff         .
	jnb	cy,X1308	; 1304   30 d7 01   0W.
	inc	r7		; 1307   0f         .
X1308:	mov	a,r7		; 1308   ef         o
	mov	dptr,#1000h	; 1309   90 10 00   ...
	movc	a,@a+dptr	; 130c   93         .
	mov	r7,a		; 130d   ff         .
	ret			; 130e   22         "
;
X130f:	mov	rcp_nuetral,r3		; 130f   8b 72      .r
	mov	rcp_nuetral+1,r2		; 1311   8a 73      .s
	mov	rcp_min,r1		; 1313   89 74      .t
	clr	a		; 1315   e4         d
	mov	78h,a		; 1316   f5 78      ux
X1318:	clr	a		; 1318   e4         d
	mov	79h,a		; 1319   f5 79      uy
X131b:	mov	r3,rcp_nuetral		; 131b   ab 72      +r
	inc	rcp_min		; 131d   05 74      .t
	mov	a,rcp_min		; 131f   e5 74      et
	mov	r2,rcp_nuetral+1		; 1321   aa 73      *s
	jnz	X1327		; 1323   70 02      p.
	inc	rcp_nuetral+1		; 1325   05 73      .s
X1327:	dec	a		; 1327   14         .
	mov	r1,a		; 1328   f9         y
	lcall	X0cf6		; 1329   12 0c f6   ..v
	mov	7ah,a		; 132c   f5 7a      uz
	swap	a		; 132e   c4         D
	anl	a,#0f0h		; 132f   54 f0      Tp
	mov	r7,a		; 1331   ff         .
	mov	a,7ah		; 1332   e5 7a      ez
	swap	a		; 1334   c4         D
	anl	a,#0fh		; 1335   54 0f      T.
	orl	a,r7		; 1337   4f         O
	mov	7ah,a		; 1338   f5 7a      uz
	xrl	7ah,#0ffh	; 133a   63 7a ff   cz.
	mov	a,79h		; 133d   e5 79      ey
	dec	a		; 133f   14         .
	jz	X1356		; 1340   60 14      `.
	dec	a		; 1342   14         .
	jz	X1360		; 1343   60 1b      `.
	dec	a		; 1345   14         .
	jz	X136a		; 1346   60 22      `"
	add	a,#3		; 1348   24 03      $.
	jnz	X1376		; 134a   70 2a      p*
	mov	a,78h		; 134c   e5 78      ex
	add	a,acc		; 134e   25 e0      %`
	add	a,acc		; 1350   25 e0      %`
	add	a,#0		; 1352   24 00      $.
	sjmp	X1372		; 1354   80 1c      ..
;
X1356:	mov	a,78h		; 1356   e5 78      ex
	add	a,acc		; 1358   25 e0      %`
	add	a,acc		; 135a   25 e0      %`
	add	a,#1		; 135c   24 01      $.
	sjmp	X1372		; 135e   80 12      ..
;
X1360:	mov	a,78h		; 1360   e5 78      ex
	add	a,acc		; 1362   25 e0      %`
	add	a,acc		; 1364   25 e0      %`
	add	a,#2		; 1366   24 02      $.
	sjmp	X1372		; 1368   80 08      ..
;
X136a:	mov	a,78h		; 136a   e5 78      ex
	add	a,acc		; 136c   25 e0      %`
	add	a,acc		; 136e   25 e0      %`
	add	a,#3		; 1370   24 03      $.
X1372:	mov	r0,a		; 1372   f8         x
	mov	a,7ah		; 1373   e5 7a      ez
	movx	@r0,a		; 1375   f2         r
X1376:	inc	79h		; 1376   05 79      .y
	mov	a,79h		; 1378   e5 79      ey
	xrl	a,#4		; 137a   64 04      d.
	jnz	X131b		; 137c   70 9d      p.
	inc	78h		; 137e   05 78      .x
	mov	a,78h		; 1380   e5 78      ex
	xrl	a,#4		; 1382   64 04      d.
	jnz	X1318		; 1384   70 92      p.
	mov	78h,#4		; 1386   75 78 04   ux.
X1389:	clr	a		; 1389   e4         d
	mov	79h,a		; 138a   f5 79      uy
X138c:	mov	r3,rcp_min+1		; 138c   ab 75      +u
	inc	77h		; 138e   05 77      .w
	mov	a,77h		; 1390   e5 77      ew
	mov	r2,76h		; 1392   aa 76      *v
	jnz	X1398		; 1394   70 02      p.
	inc	76h		; 1396   05 76      .v
X1398:	dec	a		; 1398   14         .
	mov	r1,a		; 1399   f9         y
	lcall	X0cf6		; 139a   12 0c f6   ..v
	mov	7ah,a		; 139d   f5 7a      uz
	swap	a		; 139f   c4         D
	anl	a,#0f0h		; 13a0   54 f0      Tp
	mov	r7,a		; 13a2   ff         .
	mov	a,7ah		; 13a3   e5 7a      ez
	swap	a		; 13a5   c4         D
	anl	a,#0fh		; 13a6   54 0f      T.
	orl	a,r7		; 13a8   4f         O
	mov	7ah,a		; 13a9   f5 7a      uz
	xrl	7ah,#0ffh	; 13ab   63 7a ff   cz.
	mov	a,79h		; 13ae   e5 79      ey
	dec	a		; 13b0   14         .
	jz	X13c7		; 13b1   60 14      `.
	dec	a		; 13b3   14         .
	jz	X13d1		; 13b4   60 1b      `.
	dec	a		; 13b6   14         .
	jz	X13db		; 13b7   60 22      `"
	add	a,#3		; 13b9   24 03      $.
	jnz	X13e7		; 13bb   70 2a      p*
	mov	a,78h		; 13bd   e5 78      ex
	add	a,acc		; 13bf   25 e0      %`
	add	a,acc		; 13c1   25 e0      %`
	add	a,#0		; 13c3   24 00      $.
	sjmp	X13e3		; 13c5   80 1c      ..
;
X13c7:	mov	a,78h		; 13c7   e5 78      ex
	add	a,acc		; 13c9   25 e0      %`
	add	a,acc		; 13cb   25 e0      %`
	add	a,#1		; 13cd   24 01      $.
	sjmp	X13e3		; 13cf   80 12      ..
;
X13d1:	mov	a,78h		; 13d1   e5 78      ex
	add	a,acc		; 13d3   25 e0      %`
	add	a,acc		; 13d5   25 e0      %`
	add	a,#2		; 13d7   24 02      $.
	sjmp	X13e3		; 13d9   80 08      ..
;
X13db:	mov	a,78h		; 13db   e5 78      ex
	add	a,acc		; 13dd   25 e0      %`
	add	a,acc		; 13df   25 e0      %`
	add	a,#3		; 13e1   24 03      $.
X13e3:	mov	r0,a		; 13e3   f8         x
	mov	a,7ah		; 13e4   e5 7a      ez
	movx	@r0,a		; 13e6   f2         r
X13e7:	inc	79h		; 13e7   05 79      .y
	mov	a,79h		; 13e9   e5 79      ey
	xrl	a,#4		; 13eb   64 04      d.
	jnz	X138c		; 13ed   70 9d      p.
	inc	78h		; 13ef   05 78      .x
	mov	a,78h		; 13f1   e5 78      ex
	xrl	a,#8		; 13f3   64 08      d.
	jnz	X1389		; 13f5   70 92      p.
	mov	78h,#8		; 13f7   75 78 08   ux.
X13fa:	mov	a,78h		; 13fa   e5 78      ex
	mov	b,#4		; 13fc   75 f0 04   up.
	mul	ab		; 13ff   a4         $
	add	a,#0fch		; 1400   24 fc      $|
	mov	r1,a		; 1402   f9         y
	clr	a		; 1403   e4         d
	mov	r2,a		; 1404   fa         z
	mov	r3,#0feh	; 1405   7b fe      {~
	mov	r0,#7bh		; 1407   78 7b      x{
	mov	r4,#0		; 1409   7c 00      |.
	mov	r5,a		; 140b   fd         }
	mov	r6,a		; 140c   fe         ~
	mov	r7,#4		; 140d   7f 04      ..
	lcall	X0cd0		; 140f   12 0c d0   ..P
	mov	a,78h		; 1412   e5 78      ex
	anl	a,#7		; 1414   54 07      T.
	mov	r7,a		; 1416   ff         .
	jnz	X144e		; 1417   70 35      p5
	mov	7ah,7bh		; 1419   85 7b 7a   .{z
	mov	7bh,7ch		; 141c   85 7c 7b   .|{
	mov	7ch,7dh		; 141f   85 7d 7c   .}|
	mov	7dh,7eh		; 1422   85 7e 7d   .~}
	mov	7eh,7ah		; 1425   85 7a 7e   .z~
	mov	a,7bh		; 1428   e5 7b      e{
	mov	dptr,#100h	; 142a   90 01 00   ...
	movc	a,@a+dptr	; 142d   93         .
	mov	7bh,a		; 142e   f5 7b      u{
	mov	a,7ch		; 1430   e5 7c      e|
	movc	a,@a+dptr	; 1432   93         .
	mov	7ch,a		; 1433   f5 7c      u|
	mov	a,7dh		; 1435   e5 7d      e}
	movc	a,@a+dptr	; 1437   93         .
	mov	7dh,a		; 1438   f5 7d      u}
	mov	a,7eh		; 143a   e5 7e      e~
	movc	a,@a+dptr	; 143c   93         .
	mov	7eh,a		; 143d   f5 7e      u~
	mov	a,78h		; 143f   e5 78      ex
	rrc	a		; 1441   13         .
	rrc	a		; 1442   13         .
	rrc	a		; 1443   13         .
	anl	a,#1fh		; 1444   54 1f      T.
	add	a,#3fh		; 1446   24 3f      $?
	mov	r0,a		; 1448   f8         x
	mov	a,@r0		; 1449   e6         f
	xrl	7bh,a		; 144a   62 7b      b{
	sjmp	X146a		; 144c   80 1c      ..
;
X144e:	mov	a,r7		; 144e   ef         o
	xrl	a,#4		; 144f   64 04      d.
	jnz	X146a		; 1451   70 17      p.
	mov	a,7bh		; 1453   e5 7b      e{
	mov	dptr,#100h	; 1455   90 01 00   ...
	movc	a,@a+dptr	; 1458   93         .
	mov	7bh,a		; 1459   f5 7b      u{
	mov	a,7ch		; 145b   e5 7c      e|
	movc	a,@a+dptr	; 145d   93         .
	mov	7ch,a		; 145e   f5 7c      u|
	mov	a,7dh		; 1460   e5 7d      e}
	movc	a,@a+dptr	; 1462   93         .
	mov	7dh,a		; 1463   f5 7d      u}
	mov	a,7eh		; 1465   e5 7e      e~
	movc	a,@a+dptr	; 1467   93         .
	mov	7eh,a		; 1468   f5 7e      u~
X146a:	mov	a,78h		; 146a   e5 78      ex
	add	a,acc		; 146c   25 e0      %`
	add	a,acc		; 146e   25 e0      %`
	add	a,#0e0h		; 1470   24 e0      $`
	mov	r0,a		; 1472   f8         x
	movx	a,@r0		; 1473   e2         b
	xrl	a,7bh		; 1474   65 7b      e{
	mov	r7,a		; 1476   ff         .
	mov	a,78h		; 1477   e5 78      ex
	add	a,acc		; 1479   25 e0      %`
	add	a,acc		; 147b   25 e0      %`
	add	a,#0		; 147d   24 00      $.
	mov	r0,a		; 147f   f8         x
	mov	a,r7		; 1480   ef         o
	movx	@r0,a		; 1481   f2         r
	mov	a,78h		; 1482   e5 78      ex
	add	a,acc		; 1484   25 e0      %`
	add	a,acc		; 1486   25 e0      %`
	add	a,#0e1h		; 1488   24 e1      $a
	mov	r0,a		; 148a   f8         x
	movx	a,@r0		; 148b   e2         b
	xrl	a,7ch		; 148c   65 7c      e|
	mov	r7,a		; 148e   ff         .
	mov	a,78h		; 148f   e5 78      ex
	add	a,acc		; 1491   25 e0      %`
	add	a,acc		; 1493   25 e0      %`
	add	a,#1		; 1495   24 01      $.
	mov	r0,a		; 1497   f8         x
	mov	a,r7		; 1498   ef         o
	movx	@r0,a		; 1499   f2         r
	mov	a,78h		; 149a   e5 78      ex
	add	a,acc		; 149c   25 e0      %`
	add	a,acc		; 149e   25 e0      %`
	add	a,#0e2h		; 14a0   24 e2      $b
	mov	r0,a		; 14a2   f8         x
	movx	a,@r0		; 14a3   e2         b
	xrl	a,7dh		; 14a4   65 7d      e}
	mov	r7,a		; 14a6   ff         .
	mov	a,78h		; 14a7   e5 78      ex
	add	a,acc		; 14a9   25 e0      %`
	add	a,acc		; 14ab   25 e0      %`
	add	a,#2		; 14ad   24 02      $.
	mov	r0,a		; 14af   f8         x
	mov	a,r7		; 14b0   ef         o
	movx	@r0,a		; 14b1   f2         r
	mov	a,78h		; 14b2   e5 78      ex
	add	a,acc		; 14b4   25 e0      %`
	add	a,acc		; 14b6   25 e0      %`
	add	a,#0e3h		; 14b8   24 e3      $c
	mov	r0,a		; 14ba   f8         x
	movx	a,@r0		; 14bb   e2         b
	xrl	a,7eh		; 14bc   65 7e      e~
	mov	r7,a		; 14be   ff         .
	mov	a,78h		; 14bf   e5 78      ex
	add	a,acc		; 14c1   25 e0      %`
	add	a,acc		; 14c3   25 e0      %`
	add	a,#3		; 14c5   24 03      $.
	mov	r0,a		; 14c7   f8         x
	mov	a,r7		; 14c8   ef         o
	movx	@r0,a		; 14c9   f2         r
	inc	78h		; 14ca   05 78      .x
	mov	a,78h		; 14cc   e5 78      ex
	xrl	a,#3ch		; 14ce   64 3c      d<
	jz	X14d5		; 14d0   60 03      `.
	ljmp	X13fa		; 14d2   02 13 fa   ..z
;
X14d5:	ret			; 14d5   22         "
;
endif
auto_detect_rcp:
; 43h,52h,53h will be reset later, so it's safety by being used here
	mov		43h,#50
adr_1:
	jnb		rcp_t0_ready,$
	clr		rcp_t0_ready
	clr		ex0
	mov		53h,rcp_h
	mov		52h,rcp_l
	setb	ex0
	mov		a,#low(3968-400)
	clr		c
	subb	a,52h
	mov		a,#high(3968-400)
	subb	a,53h
	jc		auto_detect_rcp
	mov		a,#low(2480+300)
	subb	a,52h
	mov		a,#high(2480+300)
	subb	a,53h
	jnc		auto_detect_rcp
	djnz	43h,adr_1
	mov		rcp_nuetral,52h
	mov		rcp_nuetral+1,53h

	lcall	x3167_flash_green_3
	ret
;	org	1600h
;
X1c00:
;	clr		debug_flag
	clr		ea		; 1c00   c2 af      B/
	clr		uart0_store_0b8h		; 1c02   c2 28      B(
	clr		25h.1		; 1c04   c2 29      B)
	mov		psw,#0		; 1c06   75 d0 00   uP.
	mov		VDM0CN,#80h		; 1c09   75 ff 80   u..
	mov		sp,#0cfh	; 1c0c   75 81 cf   u.O
	lcall	x1d1d_init		; 1c0f   12 1d 1d   ...
	lcall	x31de_delay_1		; 1c12   12 31 de   .1^
	setb	red_led		; 1c15   d2 94      R.
	lcall	x1d92_load_unknown_data		; 1c17   12 1d 92   ...
;	lcall	x1f70_pbox		; 1c1a   12 1f 70   ..p
	lcall	x1f5a_interrupt_conf		; 1c1d   12 1f 5a   ..Z
	; the following function was executed when 'set' button was press
;	lcall	x215a_sys_setting		; 1c20   12 21 5a   .!Z
	clr		red_led		; 1c23   c2 94      B.
	lcall	x23ee_audit_sys_voltage		; 1c25   12 23 ee   .#n
;	lcall	detect_battery

	; set Internal oscillator
	; OSCICN [IOSCEN|IFRDY|SUSPEND|STSYNC|-|-|IFCN1|IFCN0]
	; IOSCEN 1:Internal High-Frequency Oscillator enabled
	; IFRDY 1:Internal H-F Oscillator is running at programmed frequency
	; IFCN[1:0] 11:SYSCLK DERIVED FROM INTERNAL H-F OSCILLATOR divided by 1
	mov		OSCICN,#0c3h	; 1c28   75 b2 c3   u2C
	mov		CLKSEL,#0		; 1c2b   75 a9 00   u).
	lcall	x1c51_delay_of_rcp		; 1c2e   12 1c 51   ..Q
	lcall	x24fa_enable_interrupt		; 1c31   12 24 fa   .$z
	setb	ex0		; 1c34   d2 a8      R(
	clr		skip_check_btn		; 1c36   c2 2c      B,
	acall	auto_detect_rcp
X1c38:
	lcall	x21ae_calc_rcp_zone		; 1c38   12 21 ae   .!.
	clr		dir_reverse		; 1c3b   c2 0a      B.
	clr		first_state		; 1c3d   c2 10      B.
	clr		22h.1		; 1c3f   c2 11      B.
;	clr		25h.6		; 1c41   c2 2e      B.
	clr		go_run		; 1c43   c2 1e      B.
	mov		5ch,#0		; 1c45   75 5c 00   u\.
	mov		temper_fail_time,#0		; 1c48   75 43 00   uC.
	mov		45h,#0		; 1c4b   75 45 00   uE.
	ljmp	X27a0		; 1c4e   02 27 a0   .' 
;wait until a over 5000ms high rcp signal or 32000ms
x1c51_delay_of_rcp:
	lcall	x2808_t2_reset		; 1c51   12 28 08   .(.
	lcall	x2121_t3_reset		; 1c54   12 21 21   .!!
X1c57:
	jb		TMR2CN.7,X1c69	; 1c57   20 cf 0f    O.
	mov		a,TMR3H		; 1c5a   e5 95      e.
	clr		c		; 1c5c   c3         C
	subb	a,#28h		; 1c5d   94 28      .(
	jnc		X1c69		; 1c5f   50 08      P.
	jb		p0.5,X1c57	; 1c61   20 85 f3    .s
	lcall	x2121_t3_reset		; 1c64   12 21 21   .!!
	sjmp	X1c57		; 1c67   80 ee      .n
X1c69:
	mov		30h,#4		; 1c69   75 30 04   u0.
	mov	31h,#0		; 1c6c   75 31 00   u1.
	mov	32h,#0ffh	; 1c6f   75 32 ff   u2.
	mov	33h,#0		; 1c72   75 33 00   u3.
	mov	34h,#0		; 1c75   75 34 00   u4.
	ret			; 1c78   22         "
;
x1c79_int0:
;	push	psw		; 1c79   c0 d0      @P
	jb		rcp_t0_ready,X1c89	; 1c7b   20 00 0b    ..
	jbc		tf0,X1c89	; 1c7e   10 8d 08   ...
	mov		rcp_l,tl0		; 1c81   85 8a 2a   ..*
	mov		rcp_h,th0		; 1c84   85 8c 2b   ..+
	setb	rcp_t0_ready		; 1c87   d2 00      R.
X1c89:
	mov		th0,#0		; 1c89   75 8c 00   u..
	mov		tl0,#0		; 1c8c   75 8a 00   u..
	clr		tf0		; 1c8f   c2 8d      B.
	pop		psw		; 1c91   d0 d0      PP
	reti			; 1c93   32         2
;
x1c94_t3ovfl:
;	push	psw		; 1c94   c0 d0      @P
;	push	acc		; 1c96   c0 e0      @`
	jnb		22h.3,X1ca5	; 1c98   30 13 0a   0..
	djnz	3ah,X1cee	; 1c9b   d5 3a 50   U:P
	clr		22h.3		; 1c9e   c2 13      B.
	mov		3ah,#1		; 1ca0   75 3a 01   u:.
	sjmp	X1cee		; 1ca3   80 49      .I
;
X1ca5:
	djnz	3ah,X1cee	; 1ca5   d5 3a 46   U:F
	jnb		22h.5,X1cad	; 1ca8   30 15 02   0..
	cpl		green_led		; 1cab   b2 93      2.
X1cad:
	jnb		fresh_red,X1cb2	; 1cad   30 16 02   0..
	cpl		red_led		; 1cb0   b2 94      2.
X1cb2:
	cpl		fet_bp		; 1cb2   b2 86      2.
	jb		22h.7,X1ce5	; 1cb4   20 17 2e    ..
	mov		a,7dh		; 1cb7   e5 7d      e}
	jz		X1cc0		; 1cb9   60 05      `.
	djnz	7dh,X1cda	; 1cbb   d5 7d 1c   U}.
	sjmp	X1cda		; 1cbe   80 1a      ..
;
X1cc0:	mov	a,7ch		; 1cc0   e5 7c      e|
	jz	X1cc7		; 1cc2   60 03      `.
	djnz	7ch,X1ce5	; 1cc4   d5 7c 1e   U|.
X1cc7:	clr	green_led		; 1cc7   c2 93      B.
	clr	red_led		; 1cc9   c2 94      B.
	clr	fet_bp		; 1ccb   c2 86      B.
	mov	7ch,7eh		; 1ccd   85 7e 7c   .~|
	mov	7dh,7fh		; 1cd0   85 7f 7d   ..}
	setb	22h.3		; 1cd3   d2 13      R.
	mov	3ah,#19h	; 1cd5   75 3a 19   u:.
	sjmp	X1cee		; 1cd8   80 14      ..
;
X1cda:	mov	3ah,#5		; 1cda   75 3a 05   u:.
	jb	fet_bp,X1cee	; 1cdd   20 86 0e    ..
	mov	3ah,#2		; 1ce0   75 3a 02   u:.
	sjmp	X1cee		; 1ce3   80 09      ..
;
X1ce5:	mov	3ah,#1		; 1ce5   75 3a 01   u:.
	jb	fet_bp,X1cee	; 1ce8   20 86 03    ..
	mov	3ah,#2		; 1ceb   75 3a 02   u:.
X1cee:	mov	a,TMR3CN		; 1cee   e5 91      e.
	anl	a,#1fh		; 1cf0   54 1f      T.
	mov	TMR3CN,a		; 1cf2   f5 91      u.
	pop	acc		; 1cf4   d0 e0      P`
	pop	psw		; 1cf6   d0 d0      PP
	reti			; 1cf8   32         2
;
X1cf9:	push	psw		; 1cf9   c0 d0      @P
	push	acc		; 1cfb   c0 e0      @`
	push	rb0r0		; 1cfd   c0 00      @.
	jb	ri,X1d06	; 1cff   20 98 04    ..
	clr	ti		; 1d02   c2 99      B.
	sjmp	X1d16		; 1d04   80 10      ..
;
X1d06:	clr	ri		; 1d06   c2 98      B.
	mov	a,#35h		; 1d08   74 35      t5
	clr	c		; 1d0a   c3         C
	subb	a,30h		; 1d0b   95 30      .0
	mov	r0,a		; 1d0d   f8         x
	mov	@r0,sbuf	; 1d0e   a6 99      &.
	djnz	30h,X1d16	; 1d10   d5 30 03   U0.
	mov	30h,#4		; 1d13   75 30 04   u0.
X1d16:	pop	rb0r0		; 1d16   d0 00      P.
	pop	acc		; 1d18   d0 e0      P`
	pop	psw		; 1d1a   d0 d0      PP
	reti			; 1d1c   32         2
;
x1d1d_init:
;OSCICN[IOSCEN|IFRDY|SUSPEND|STSYNC|-|-|IFCN1|IFCN0]
; IOSCEN 1:internal H-F oscillator enable
; IFRDY(readonly) 1: Internal H-F oscillator is running at programmed frequency
; IFCN[1:0]=01: SYSCLK DRIVED FROM INTERNAL H-F oscillator divided by 4
	mov		OSCICN,#0c1h	; 1d1d   75 b2 c1   u2A
	mov		CLKSEL,#0		; 1d20   75 a9 00   u).
	mov		VDM0CN,#80h		; 1d23   75 ff 80   u..
	; WDTE set to 0 for disable watchdog timer
	anl		PCA0MD,#10111111b	; 1d26   53 d9 bf   SY?

	mov		P0MDIN,#01110000b	; 1d29   75 f1 70   uqp
	mov		P0MDOUT,#11001111b	; 1d2c   75 a4 cf   u$O
	mov		p0,#10111111b	; 1d2f   75 80 bf   u.?
	mov		P1MDIN,#7fh	; 1d32   75 f2 7f   ur.
	mov		P1MDOUT,#0ffh	; 1d35   75 a5 ff   u%.
	; an=1,ap=0 p1.5,p1.6
	; bn=1,bp=0 p1.2,p0.6
	; cn=1,cp=0 p1.1,p1.0
	mov	p1,#10100110b	; 1d38   75 90 a6   u.&
	mov	P2MDOUT,#0ffh	; 1d3b   75 a6 ff   u&.
	mov	p2,#1		; 1d3e   75 a0 01   u .
	mov	P0SKIP,#0ffh	; 1d41   75 d4 ff   uT.
	mov	P1SKIP,#0fdh	; 1d44   75 d5 fd   uU}    ; p1.1 cn
	mov	XBR0,#0		; 1d47   75 e1 00   ua.
	mov	XBR1,#41h	; 1d4a   75 e2 41   ubA
	mov	EIE1,#0		; 1d4d   75 e6 00   uf.
	mov	EIP1,#0		; 1d50   75 f6 00   uv.
	mov	ip,#1		; 1d53   75 b8 01   u8.
	mov	ie,#80h		; 1d56   75 a8 80   u(.
	;IN0PL 0: /int0 input is active low
	;p0.5 was selected as trigger source
	mov	IT01CF,#00000101b		; 1d59   75 e4 05   ud.
	mov	REF0CN,#0eh	; 1d5c   75 d1 0e   uQ.
	mov	RSTSRC,#6		; 1d5f   75 ef 06   uo.
	ret			; 1d62   22         "
;
;x1d63_set_default_rcp_range:
;	lcall	x2808_t2_reset		; 1d63   12 28 08   .(.
;	mov		50h,#0		; 1d66   75 50 00   uP.
;X1d69:
;	jb		p2.0,X1d91	; 1d69   20 a0 25     %
;	jnb		TMR2CN.7,X1d69	; 1d6c   30 cf fa   0Oz
;	clr		TMR2CN.7		; 1d6f   c2 cf      BO
;	inc		50h		; 1d71   05 50      .P
;	mov		a,50h		; 1d73   e5 50      eP
;	clr		c		; 1d75   c3         C
;	subb	a,#0fh		; 1d76   94 0f      ..
;	jc		X1d69		; 1d78   40 ef      @o
;	lcall	X1dc7		; 1d7a   12 1d c7   ..G
;	mov		r0,#3		; 1d7d   78 03      x.
;X1d7f:
;	setb	green_led		; 1d7f   d2 93      R.
;	setb	red_led		; 1d81   d2 94      R.
;	lcall	x31c5_longlong_delay		; 1d83   12 31 c5   .1E
;	clr		green_led		; 1d86   c2 93      B.
;	clr		red_led		; 1d88   c2 94      B.
;	lcall	x31c5_longlong_delay		; 1d8a   12 31 c5   .1E
;	djnz	r0,X1d7f	; 1d8d   d8 f0      Xp
;	setb	skip_check_btn		; 1d8f   d2 2c      R,
;X1d91:
;	ret			; 1d91   22         "
;
x1d92_load_unknown_data:
;	lcall	X1df5		; 1d92   12 1d f5   ..u
;	mov		37h,#0		; 1d95   75 37 00   u7.
;X1d98:
;	mov		a,#60h		; 1d98   74 60      t`
;	add		a,37h		; 1d9a   25 37      %7
;	mov		r1,a		; 1d9c   f9         y
;	mov		a,@r1		; 1d9d   e7         g
;	mov		r0,a		; 1d9e   f8         x
;	mov		dptr,#X36d0	; 1d9f   90 36 d0   .6P
;	mov		a,37h		; 1da2   e5 37      e7
;	movc	a,@a+dptr	; 1da4   93         .
;	clr		c		; 1da5   c3         C
;	subb	a,r0		; 1da6   98         .
;	jc		X1dc7		; 1da7   40 1e      @.
;	mov		a,#10h		; 1da9   74 10      t.
;	subb	a,r0		; 1dab   98         .
;	jc		X1dc7		; 1dac   40 19      @.
;	inc		37h		; 1dae   05 37      .7
;	mov		a,37h		; 1db0   e5 37      e7
;	cjne	a,#0fh,X1d98	; 1db2   b4 0f e3   4.c
;	mov		dptr,#X3830	; 1db5   90 38 30   .80
;	movc	a,@a+dptr	; 1db8   93         .
;	cjne	a,#9,X1dc7	; 1db9   b4 09 0b   4..
;	mov		dptr,#X36d0	; 1dbc   90 36 d0   .6P
;	mov		a,37h		; 1dbf   e5 37      e7
;	movc	a,@a+dptr	; 1dc1   93         .
;	cjne	a,#55h,X1dc7	; 1dc2   b4 55 02   4U.
;	sjmp	X1df5		; 1dc5   80 2e      ..
;copy 256bytes on 3720h to 3800h
;X1dc7:
;	lcall	x1e40_load_3800h		; 1dc7   12 1e 40   ..@
;	mov		dptr,#X3800	; 1dca   90 38 00   .8.
;	lcall	x1ecc_erase_page		; 1dcd   12 1e cc   ..L
;	mov		37h,#0		; 1dd0   75 37 00   u7.
;X1dd3:
;	mov		dptr,#x3720_default_rcp_value	; 1dd3   90 37 20   .7 
;	mov		a,37h		; 1dd6   e5 37      e7
;	movc	a,@a+dptr	; 1dd8   93         .
;	mov		38h,a		; 1dd9   f5 38      u8
;	mov		dptr,#X0000	; 1ddb   90 00 00   ...
;	mov		a,dpl		; 1dde   e5 82      e.
;	add		a,37h		; 1de0   25 37      %7
;	mov		dpl,a		; 1de2   f5 82      u.
;	mov		a,38h		; 1de4   e5 38      e8
;	movx	@dptr,a		; 1de6   f0         p
;	mov		a,37h		; 1de7   e5 37      e7
;	cjne	a,#0ffh,X1df1	; 1de9   b4 ff 05   4..
;	lcall	x1e83_write_to_3800h		; 1dec   12 1e 83   ...
;	sjmp	x1d92_load_unknown_data		; 1def   80 a1      .!
;
;X1df1:	inc	37h		; 1df1   05 37      .7
;	sjmp	X1dd3		; 1df3   80 de      .^
;
X1df5:
;	mov		dptr,#X3810	; 1df5   90 38 10   .8.
;	clr		a		; 1df8   e4         d
;	movc	a,@a+dptr	; 1df9   93         .
;	mov		38h,a		; 1dfa   f5 38      u8
;	clr		c		; 1dfc   c3         C
;	subb	a,#3		; 1dfd   94 03      ..
;	jnc		X1dc7		; 1dff   50 c6      PF
;	mov		a,38h		; 1e01   e5 38      e8
;	jz		X1e12		; 1e03   60 0d      `.
;	cjne	a,#1,X1e0d	; 1e05   b4 01 05   4..
;	mov		dptr,#X3870	; 1e08   90 38 70   .8p
;	sjmp	X1e17		; 1e0b   80 0a      ..
;
;X1e0d:
;	mov		dptr,#X38b0	; 1e0d   90 38 b0   .80
;	sjmp	X1e17		; 1e10   80 05      ..
;
;X1e12:
	mov		dptr,#X3830	; 1e12   90 38 30   .80
;	sjmp	X1e17		; 1e15   80 00      ..
;
;X1e17:
	mov		37h,#0		; 1e17   75 37 00   u7.
	mov		r0,#60h		; 1e1a   78 60      x`
X1e1c:
	mov		a,37h		; 1e1c   e5 37      e7
	movc	a,@a+dptr	; 1e1e   93         .
	mov		@r0,a		; 1e1f   f6         v
	inc		r0		; 1e20   08         .
	inc		37h		; 1e21   05 37      .7
	mov		a,37h		; 1e23   e5 37      e7
	cjne	a,#10h,X1e1c	; 1e25   b4 10 f4   4.t
	mov		37h,#0		; 1e28   75 37 00   u7.
	mov		r0,#rcp_max		; 1e2b   78 70      xp
X1e2d:
	mov		dptr,#X3800	; 1e2d   90 38 00   .8.
	mov		a,37h		; 1e30   e5 37      e7
	movc	a,@a+dptr	; 1e32   93         .
	mov		@r0,a		; 1e33   f6         v
	inc		r0		; 1e34   08         .
	inc		37h		; 1e35   05 37      .7
	mov		a,37h		; 1e37   e5 37      e7
	cjne	a,#6,X1e2d	; 1e39   b4 06 f1   4.q
	lcall	x1e40_load_3800h		; 1e3c   12 1e 40   ..@
	ret			; 1e3f   22         "
;
x1e40_load_3800h:
	mov		37h,#0		; 1e40   75 37 00   u7.
X1e43:
	mov		dptr,#X3800	; 1e43   90 38 00   .8.
	mov		a,37h		; 1e46   e5 37      e7
	movc	a,@a+dptr	; 1e48   93         .
	mov		38h,a		; 1e49   f5 38      u8
	mov		dptr,#X0000	; 1e4b   90 00 00   ...
	mov		a,dpl		; 1e4e   e5 82      e.
	add		a,37h		; 1e50   25 37      %7
	mov		dpl,a		; 1e52   f5 82      u.
	mov		a,38h		; 1e54   e5 38      e8
	movx	@dptr,a		; 1e56   f0         p
	mov		a,37h		; 1e57   e5 37      e7
	cjne	a,#0ffh,X1e5e	; 1e59   b4 ff 02   4..
	sjmp	X1e62		; 1e5c   80 04      ..
;
X1e5e:	inc	37h		; 1e5e   05 37      .7
	sjmp	X1e43		; 1e60   80 e1      .a
;
X1e62:	mov	37h,#0		; 1e62   75 37 00   u7.
X1e65:	mov	dptr,#X3900	; 1e65   90 39 00   .9.
	mov	a,37h		; 1e68   e5 37      e7
	movc	a,@a+dptr	; 1e6a   93         .
	mov	38h,a		; 1e6b   f5 38      u8
	mov	dptr,#100h	; 1e6d   90 01 00   ...
	mov	a,dpl		; 1e70   e5 82      e.
	add	a,37h		; 1e72   25 37      %7
	mov	dpl,a		; 1e74   f5 82      u.
	mov	a,38h		; 1e76   e5 38      e8
	movx	@dptr,a		; 1e78   f0         p
	mov	a,37h		; 1e79   e5 37      e7
	cjne	a,#0ffh,X1e7f	; 1e7b   b4 ff 01   4..
	ret			; 1e7e   22         "
;
X1e7f:	inc	37h		; 1e7f   05 37      .7
	sjmp	X1e65		; 1e81   80 e2      .b
;
x1e83_write_to_3800h:	mov	37h,#0		; 1e83   75 37 00   u7.
X1e86:	mov	dptr,#X0000	; 1e86   90 00 00   ...
	mov	a,dpl		; 1e89   e5 82      e.
	add	a,37h		; 1e8b   25 37      %7
	mov	dpl,a		; 1e8d   f5 82      u.
	movx	a,@dptr		; 1e8f   e0         `
	mov	r0,a		; 1e90   f8         x
	mov	dptr,#X3800	; 1e91   90 38 00   .8.
	mov	a,dpl		; 1e94   e5 82      e.
	add	a,37h		; 1e96   25 37      %7
	mov	dpl,a		; 1e98   f5 82      u.
	lcall	x1ede_flash_write		; 1e9a   12 1e de   ..^
	mov	a,37h		; 1e9d   e5 37      e7
	cjne	a,#0ffh,X1ea4	; 1e9f   b4 ff 02   4..
	sjmp	X1ea8		; 1ea2   80 04      ..
;
X1ea4:	inc	37h		; 1ea4   05 37      .7
	sjmp	X1e86		; 1ea6   80 de      .^
;
X1ea8:
	mov		37h,#0		; 1ea8   75 37 00   u7.
X1eab:
	mov		dptr,#100h	; 1eab   90 01 00   ...
	mov		a,dpl		; 1eae   e5 82      e.
	add		a,37h		; 1eb0   25 37      %7
	mov		dpl,a		; 1eb2   f5 82      u.
	movx	a,@dptr		; 1eb4   e0         `
	mov		r0,a		; 1eb5   f8         x
	mov		dptr,#X3900	; 1eb6   90 39 00   .9.
	mov		a,dpl		; 1eb9   e5 82      e.
	add		a,37h		; 1ebb   25 37      %7
	mov		dpl,a		; 1ebd   f5 82      u.
	lcall	x1ede_flash_write		; 1ebf   12 1e de   ..^
	mov		a,37h		; 1ec2   e5 37      e7
	cjne	a,#0ffh,X1ec8	; 1ec4   b4 ff 01   4..
	ret			; 1ec7   22         "
;
X1ec8:
	inc		37h		; 1ec8   05 37      .7
	sjmp	X1eab		; 1eca   80 df      ._
;
x1ecc_erase_page:
	clr		ea		; 1ecc   c2 af      B/
	mov		PSCTL,#0ffh	; 1ece   75 8f ff   u..
	mov		FLKEY,#0a5h	; 1ed1   75 b7 a5   u7%
	mov		FLKEY,#0f1h	; 1ed4   75 b7 f1   u7q
	movx	@dptr,a		; 1ed7   f0         p
	anl		PSCTL,#0		; 1ed8   53 8f 00   S..
	setb	ea		; 1edb   d2 af      R/
	ret			; 1edd   22         "
;
x1ede_flash_write:
	clr		ea		; 1ede   c2 af      B/
	mov		PSCTL,#1		; 1ee0   75 8f 01   u..
	mov		FLKEY,#0a5h	; 1ee3   75 b7 a5   u7%
	mov		FLKEY,#0f1h	; 1ee6   75 b7 f1   u7q
	mov		a,r0		; 1ee9   e8         h
	movx	@dptr,a		; 1eea   f0         p
	mov		PSCTL,#0		; 1eeb   75 8f 00   u..
	setb	ea		; 1eee   d2 af      R/
	ret			; 1ef0   22         "
;
X1ef1:
	lcall	x1e40_load_3800h		; 1ef1   12 1e 40   ..@
	mov		dptr,#X3810	; 1ef4   90 38 10   .8.
	clr		a			; 1ef7   e4         d
	movc	a,@a+dptr	; 1ef8   93         .
	jz		X1f08		; 1ef9   60 0d      `.
	cjne	a,#1,X1f03	; 1efb   b4 01 05   4..
	mov		dptr,#70h	; 1efe   90 00 70   ..p
	sjmp	X1f0d		; 1f01   80 0a      ..
X1f03:
	mov		dptr,#0b0h	; 1f03   90 00 b0   ..0
	sjmp	X1f0d		; 1f06   80 05      ..
X1f08:
	mov		dptr,#30h	; 1f08   90 00 30   ..0
	sjmp	X1f0d		; 1f0b   80 00      ..
X1f0d:
	mov		38h,dpl		; 1f0d   85 82 38   ..8
	mov		37h,#0		; 1f10   75 37 00   u7.
X1f13:
	mov		a,#60h		; 1f13   74 60      t`
	add		a,37h		; 1f15   25 37      %7
	mov		r1,a		; 1f17   f9         y
	mov		a,@r1		; 1f18   e7         g
	mov		r0,a		; 1f19   f8         x
	mov		a,38h		; 1f1a   e5 38      e8
	add		a,37h		; 1f1c   25 37      %7
	mov		dpl,a		; 1f1e   f5 82      u.
	mov		a,r0		; 1f20   e8         h
	movx	@dptr,a		; 1f21   f0         p
	mov		a,37h		; 1f22   e5 37      e7
	cjne	a,#0bh,X1f29	; 1f24   b4 0b 02   4..
	sjmp	X1f2d		; 1f27   80 04      ..
;
X1f29:
	inc		37h		; 1f29   05 37      .7
	sjmp	X1f13		; 1f2b   80 e6      .f
;
X1f2d:	mov	37h,#0		; 1f2d   75 37 00   u7.
X1f30:	mov	a,#70h		; 1f30   74 70      tp
	add	a,37h		; 1f32   25 37      %7
	mov	r1,a		; 1f34   f9         y
	mov	a,@r1		; 1f35   e7         g
	mov	r0,a		; 1f36   f8         x
	mov	dptr,#X0000	; 1f37   90 00 00   ...
	mov	a,dpl		; 1f3a   e5 82      e.
	add	a,37h		; 1f3c   25 37      %7
	mov	dpl,a		; 1f3e   f5 82      u.
	mov	a,r0		; 1f40   e8         h
	movx	@dptr,a		; 1f41   f0         p
	mov	a,37h		; 1f42   e5 37      e7
	cjne	a,#5,X1f49	; 1f44   b4 05 02   4..
	sjmp	X1f4d		; 1f47   80 04      ..
;
X1f49:	inc	37h		; 1f49   05 37      .7
	sjmp	X1f30		; 1f4b   80 e3      .c
;
X1f4d:
	mov		dptr,#X3800	; 1f4d   90 38 00   .8.
	lcall	x1ecc_erase_page		; 1f50   12 1e cc   ..L
	lcall	x1e83_write_to_3800h		; 1f53   12 1e 83   ...
	lcall	x1d92_load_unknown_data		; 1f56   12 1d 92   ...
	ret			; 1f59   22         "
;
x1f5a_interrupt_conf:
; t0 use gate0 and mode1 16-bit counter/timer
; int0 already set to active low
	mov		tmod,#00011001b	; 1f5a   75 89 19   u..
; t0 use system clock divided by 12
	mov	CKCON,#0		; 1f5d   75 8e 00   u..
; tcon[TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT0]
; IT0 1: edge triggered
; TR0 1: timer0 enable
	mov	tcon,#00010001b	; 1f60   75 88 11   u..
	mov	th0,#0		; 1f63   75 8c 00   u..
	mov	tl0,#0		; 1f66   75 8a 00   u..
	clr	tf0		; 1f69   c2 8d      B.
	clr	ie0		; 1f6b   c2 89      B.
	setb	ex0		; 1f6d   d2 a8      R(
	ret			; 1f6f   22         "
;
if PACK=0
x1f70_pbox:
	mov	77h,#high(pb_param1)		; 1f70   75 77 05   uw.
	mov	78h,#low(pb_param1)	; 1f73   75 78 a0   ux 
	mov	37h,#19h	; 1f76   75 37 19   u7.
X1f79:	lcall	x2808_t2_reset		; 1f79   12 28 08   .(.
X1f7c:	jnb	p0.5,X1f87	; 1f7c   30 85 08   0..
	jnb	TMR2CN.7,X1f7c	; 1f7f   30 cf fa   0Oz
	djnz	37h,X1f79	; 1f82   d5 37 f4   U7t
	sjmp	X1f88		; 1f85   80 01      ..
;
X1f87:	ret			; 1f87   22         "
;
X1f88:	mov	a,6ah		; 1f88   e5 6a      ej
	mov	69h,a		; 1f8a   f5 69      ui
	mov	37h,#0		; 1f8c   75 37 00   u7.
X1f8f:	mov	a,#60h		; 1f8f   74 60      t`
	add	a,37h		; 1f91   25 37      %7
	mov	r0,a		; 1f93   f8         x
	mov	a,@r0		; 1f94   e6         f
	mov	r1,a		; 1f95   f9         y
	mov	dptr,#X36a0	; 1f96   90 36 a0   .6 
	mov	a,37h		; 1f99   e5 37      e7
	movc	a,@a+dptr	; 1f9b   93         .
	clr	c		; 1f9c   c3         C
	subb	a,r1		; 1f9d   99         .
	jnc	X1fa2		; 1f9e   50 02      P.
	mov	@r0,#0		; 1fa0   76 00      v.
X1fa2:	inc	37h		; 1fa2   05 37      .7
	mov	a,37h		; 1fa4   e5 37      e7
	cjne	a,#0ch,X1f8f	; 1fa6   b4 0c e6   4.f
	mov	7ah,#0		; 1fa9   75 7a 00   uz.
X1fac:	mov	a,7ah		; 1fac   e5 7a      ez
	cjne	a,#10h,X1fb3	; 1fae   b4 10 02   4..
	sjmp	X1fc2		; 1fb1   80 0f      ..
;
X1fb3:	mov	a,#60h		; 1fb3   74 60      t`
	add	a,7ah		; 1fb5   25 7a      %z
	mov	r0,a		; 1fb7   f8         x
	mov	a,@r0		; 1fb8   e6         f
	mov	79h,a		; 1fb9   f5 79      uy
	lcall	x20e7_reply_to_pb		; 1fbb   12 20 e7   . g
	inc	7ah		; 1fbe   05 7a      .z
	sjmp	X1fac		; 1fc0   80 ea      .j
;
X1fc2:	mov	7ah,#0		; 1fc2   75 7a 00   uz.
	mov	dptr,#X3810	; 1fc5   90 38 10   .8.
	clr	a		; 1fc8   e4         d
	movc	a,@a+dptr	; 1fc9   93         .
	jz	X1fd4		; 1fca   60 08      `.
	cjne	a,#1,X1fd9	; 1fcc   b4 01 0a   4..
	mov	dptr,#X3790	; 1fcf   90 37 90   .7.
	sjmp	X1fde		; 1fd2   80 0a      ..
;
X1fd4:	mov	dptr,#X3750	; 1fd4   90 37 50   .7P
	sjmp	X1fde		; 1fd7   80 05      ..
;
X1fd9:	mov	dptr,#X37d0	; 1fd9   90 37 d0   .7P
	sjmp	X1fde		; 1fdc   80 00      ..
;
X1fde:	mov	a,7ah		; 1fde   e5 7a      ez
	cjne	a,#0fh,X1fe5	; 1fe0   b4 0f 02   4..
	sjmp	X1fef		; 1fe3   80 0a      ..
;
X1fe5:	movc	a,@a+dptr	; 1fe5   93         .
	mov	79h,a		; 1fe6   f5 79      uy
	lcall	x20e7_reply_to_pb		; 1fe8   12 20 e7   . g
	inc	7ah		; 1feb   05 7a      .z
	sjmp	X1fde		; 1fed   80 ef      .o
;
X1fef:	mov	7ah,#0		; 1fef   75 7a 00   uz.
X1ff2:	mov	a,7ah		; 1ff2   e5 7a      ez
	cjne	a,#10h,X1ff9	; 1ff4   b4 10 02   4..
	sjmp	X2006		; 1ff7   80 0d      ..
;
X1ff9:	mov	dptr,#X36a0	; 1ff9   90 36 a0   .6 
	movc	a,@a+dptr	; 1ffc   93         .
	mov	79h,a		; 1ffd   f5 79      uy
	lcall	x20e7_reply_to_pb		; 1fff   12 20 e7   . g
	inc	7ah		; 2002   05 7a      .z
	sjmp	X1ff2		; 2004   80 ec      .l
;
X2006:	setb	p0.5		; 2006   d2 85      R.
	mov	37h,#0fh	; 2008   75 37 0f   u7.
X200b:	lcall	x2808_t2_reset		; 200b   12 28 08   .(.
X200e:	jnb	p0.5,X2018	; 200e   30 85 07   0..
	jnb	TMR2CN.7,X200e	; 2011   30 cf fa   0Oz
	djnz	37h,X200b	; 2014   d5 37 f4   U7t
	ret			; 2017   22         "
;
X2018:	lcall	X2090		; 2018   12 20 90   . .
	jb	ea_save,X2025	; 201b   20 2a 07    *.
	mov	a,79h		; 201e   e5 79      ey
	cjne	a,#55h,X2025	; 2020   b4 55 02   4U.
	sjmp	X2029		; 2023   80 04      ..
;
X2025:	lcall	X1df5		; 2025   12 1d f5   ..u
	ret			; 2028   22         "
;
X2029:	setb	p0.5		; 2029   d2 85      R.
X202b:	jb	p0.5,X202b	; 202b   20 85 fd    .}
	mov	7bh,#60h	; 202e   75 7b 60   u{`
X2031:	lcall	X2090		; 2031   12 20 90   . .
	jb	ea_save,X204f	; 2034   20 2a 18    *.
	mov	r0,7bh		; 2037   a8 7b      ({
	mov	@r0,79h		; 2039   a6 79      &y
	inc	7bh		; 203b   05 7b      .{
	mov	a,7bh		; 203d   e5 7b      e{
	cjne	a,#70h,X2044	; 203f   b4 70 02   4p.
	sjmp	X2064		; 2042   80 20      . 
;
X2044:	lcall	x2149_load_tmr2_77h78h		; 2044   12 21 49   .!I
X2047:	jb	TMR2CN.7,X2064	; 2047   20 cf 1a    O.
	jnb	p0.5,X2031	; 204a   30 85 e4   0.d
	sjmp	X2047		; 204d   80 f8      .x
;
X204f:	ljmp	X2025		; 204f   02 20 25   . %
;
	lcall	x2808_t2_reset		; 2052   12 28 08   .(.
X2055:	jnb	p0.5,X204f	; 2055   30 85 f7   0.w
	jnb	TMR2CN.7,X2055	; 2058   30 cf fa   0Oz
	mov	79h,#0aah	; 205b   75 79 aa   uy*
	lcall	x20e7_reply_to_pb		; 205e   12 20 e7   . g
	ljmp	X2029		; 2061   02 20 29   . )
;
X2064:	mov	a,60h		; 2064   e5 60      e`
	subb	a,#4		; 2066   94 04      ..
	jc	X206d		; 2068   40 03      @.
	ljmp	X2025		; 206a   02 20 25   . %
;
X206d:	mov	a,6fh		; 206d   e5 6f      eo
	cjne	a,#55h,X204f	; 206f   b4 55 dd   4U]
	mov	a,69h		; 2072   e5 69      ei
	mov	6ah,a		; 2074   f5 6a      uj
	mov	69h,#0		; 2076   75 69 00   ui.
	lcall	X1ef1		; 2079   12 1e f1   ..q
	setb	p0.5		; 207c   d2 85      R.
X207e:
	lcall	x2808_t2_reset		; 207e   12 28 08   .(.
X2081:
	jnb	p0.5,X207e	; 2081   30 85 fa   0.z
	jnb	TMR2CN.7,X2081	; 2084   30 cf fa   0Oz
	mov	79h,#55h	; 2087   75 79 55   uyU
	lcall	x20e7_reply_to_pb		; 208a   12 20 e7   . g
	ljmp	X2029		; 208d   02 20 29   . )
;
X2090:	clr	ea_save		; 2090   c2 2a      B*
	setb	p0.5		; 2092   d2 85      R.
	lcall	x2808_t2_reset		; 2094   12 28 08   .(.
X2097:	jnb	p0.5,X2097	; 2097   30 85 fd   0.}
	lcall	X322b		; 209a   12 32 2b   .2+
	jnb	p0.5,X2097	; 209d   30 85 f7   0.w
X20a0:	jb	p0.5,X20a0	; 20a0   20 85 fd    .}
	lcall	X322b		; 20a3   12 32 2b   .2+
	jb	p0.5,X20a0	; 20a6   20 85 f7    .w
	jnb	TMR2CN.7,X20ae	; 20a9   30 cf 02   0O.
	sjmp	X20e4		; 20ac   80 36      .6
;
X20ae:	mov	a,TMR2H		; 20ae   e5 cd      eM
	clr	c		; 20b0   c3         C
	rrc	a		; 20b1   13         .
	mov	77h,a		; 20b2   f5 77      uw
	mov	a,TMR2L		; 20b4   e5 cc      eL
	rrc	a		; 20b6   13         .
	mov	78h,a		; 20b7   f5 78      ux
	mov	79h,#0		; 20b9   75 79 00   uy.
	mov	37h,#8		; 20bc   75 37 08   u7.
	lcall	X2131		; 20bf   12 21 31   .!1
X20c2:	jnb	TMR2CN.7,X20c2	; 20c2   30 cf fd   0O}
	jb	p0.5,X20e4	; 20c5   20 85 1c    ..
X20c8:	lcall	x2149_load_tmr2_77h78h		; 20c8   12 21 49   .!I
X20cb:	jnb	TMR2CN.7,X20cb	; 20cb   30 cf fd   0O}
	clr	c		; 20ce   c3         C
	jnb	p0.5,X20d3	; 20cf   30 85 01   0..
	setb	c		; 20d2   d3         S
X20d3:	mov	a,79h		; 20d3   e5 79      ey
	rrc	a		; 20d5   13         .
	mov	79h,a		; 20d6   f5 79      uy
	djnz	37h,X20c8	; 20d8   d5 37 ed   U7m
	lcall	x2149_load_tmr2_77h78h		; 20db   12 21 49   .!I
X20de:	jnb	TMR2CN.7,X20de	; 20de   30 cf fd   0O}
	jb	p0.5,X20e6	; 20e1   20 85 02    ..
X20e4:	setb	ea_save		; 20e4   d2 2a      R*
X20e6:	ret			; 20e6   22         "
; send reply to pbox
x20e7_reply_to_pb:	clr	p0.5		; 20e7   c2 85      B.
	lcall	x2149_load_tmr2_77h78h		; 20e9   12 21 49   .!I
	jnb	TMR2CN.7,$	; 20ec   30 cf fd   0O}
	setb	p0.5		; 20ef   d2 85      R.
	lcall	x2149_load_tmr2_77h78h		; 20f1   12 21 49   .!I
	jnb	TMR2CN.7,$	; 20f4   30 cf fd   0O}
	clr	p0.5		; 20f7   c2 85      B.
	lcall	x2149_load_tmr2_77h78h		; 20f9   12 21 49   .!I
	jnb	TMR2CN.7,$	; 20fc   30 cf fd   0O}
	mov	37h,#8		; 20ff   75 37 08   u7.
X2102:	mov	a,79h		; 2102   e5 79      ey
	rrc	a		; 2104   13         .
	mov	79h,a		; 2105   f5 79      uy
	jc	X210d		; 2107   40 04      @.
	clr	p0.5		; 2109   c2 85      B.
	sjmp	X210f		; 210b   80 02      ..
;
X210d:
	setb	p0.5		; 210d   d2 85      R.
X210f:
	lcall	x2149_load_tmr2_77h78h		; 210f   12 21 49   .!I
	jnb	TMR2CN.7,$	; 2112   30 cf fd   0O}
	djnz	37h,X2102	; 2115   d5 37 ea   U7j
	setb	p0.5		; 2118   d2 85      R.
	lcall	x2149_load_tmr2_77h78h		; 211a   12 21 49   .!I
	jnb	TMR2CN.7,$	; 211d   30 cf fd   0O}
	ret			; 2120   22         "
endif
;
x2121_t3_reset:
	mov	TMR3RLH,#0		; 2121   75 93 00   u..
	mov	TMR3RLL,#0		; 2124   75 92 00   u..
	mov	TMR3H,#0		; 2127   75 95 00   u..
	mov	TMR3L,#0		; 212a   75 94 00   u..
; TMR3CN[TF3H|TF3L|TF3LEN|TF3CEN|T3SPLIT|TR3|-|T3XCLK]
; T3XCLK 0: t3 external clock selection is the system clock divided by 12
; TR3 1: T3 enabled
; T3SPLIT 0: T3 operates in 16bit auto-reload mode
	mov	TMR3CN,#4		; 212d   75 91 04   u..
	ret			; 2130   22         "
;
X2131:	lcall	x2808_t2_reset		; 2131   12 28 08   .(.
	mov	a,77h		; 2134   e5 77      ew
	clr	c		; 2136   c3         C
	rrc	a		; 2137   13         .
	mov	r0,a		; 2138   f8         x
	mov	a,78h		; 2139   e5 78      ex
	rrc	a		; 213b   13         .
	mov	r1,a		; 213c   f9         y
	mov	a,r0		; 213d   e8         h
	cpl	a		; 213e   f4         t
	mov	TMR2H,a		; 213f   f5 cd      uM
	mov	a,r1		; 2141   e9         i
	cpl	a		; 2142   f4         t
	mov	TMR2L,a		; 2143   f5 cc      uL
	mov	TMR2CN,#4	; 2145   75 c8 04   uH.
	ret			; 2148   22         "
;
x2149_load_tmr2_77h78h:
	lcall	x2808_t2_reset		; 2149   12 28 08   .(.
	mov	a,77h		; 214c   e5 77      ew
	cpl	a		; 214e   f4         t
	mov	TMR2H,a		; 214f   f5 cd      uM
	mov	a,78h		; 2151   e5 78      ex
	cpl	a		; 2153   f4         t
	mov	TMR2L,a		; 2154   f5 cc      uL
	mov	TMR2CN,#4	; 2156   75 c8 04   uH.
	ret			; 2159   22         "
;
if	PACK=0
x215a_sys_setting:
	jb		p2.0,X21d2	; 215a   20 a0 75     u
	lcall	x31e3_delay_4		; 215d   12 31 e3   .1c
	jb		p2.0,X21d2	; 2160   20 a0 6f     o
	; clear red in function
	lcall	x2367_pca0cp0_setting		; 2163   12 23 67   .#g
	lcall	x2808_t2_reset		; 2166   12 28 08   .(.
	mov		50h,#0		; 2169   75 50 00   uP.
X216c:
	jnb		TMR2CN.7,X217d	; 216c   30 cf 0e   0O.
	clr		TMR2CN.7		; 216f   c2 cf      BO
	inc		50h		; 2171   05 50      .P
	mov		a,50h		; 2173   e5 50      eP
	clr		c		; 2175   c3         C
	subb	a,#28h		; 2176   94 28      .(
	jc		X217d		; 2178   40 03      @.
	ljmp	x229b_long_press_button		; 217a   02 22 9b   .".
X217d:
	jnb		p2.0,X216c	; 217d   30 a0 ec   0 l
	lcall	x31e3_delay_4		; 2180   12 31 e3   .1c
	jnb		p2.0,X216c	; 2183   30 a0 e6   0 f
	; 进行高/中/低 3档设置
	mov		78h,#3		; 2186   75 78 03   ux.
X2189:
	jb		p2.0,$	; 2189   20 a0 fd     }
	lcall	x31e3_delay_4		; 218c   12 31 e3   .1c
	jb		p2.0,X2189	; 218f   20 a0 f7     w
	; stop t3
	mov		EIE1,#0		; 2192   75 e6 00   uf.
	clr		red_led		; 2195   c2 94      B.
	clr		green_led		; 2197   c2 93      B.
	lcall	X2204		; 2199   12 22 04   .".
	; wait until 'set' button was press
X219c:
	jnb		p2.0,$	; 219c   30 a0 fd   0 }
	lcall	x31e3_delay_4		; 219f   12 31 e3   .1c
	jnb		p2.0,X219c	; 21a2   30 a0 f7   0 w
	djnz	78h,X2189	; 21a5   d5 78 e1   Uxa
	lcall	X1ef1		; 21a8   12 1e f1   ..q
	lcall	x31c2_longlonglong_delay		; 21ab   12 31 c2   .1B
endif
x21ae_calc_rcp_zone:

;	setb	exchange_dir		; 21ae   d2 2d      R-
	clr		c		; 21b0   c3         C
	; rcp high
	mov		a,rcp_max		; 21b1   e5 70      ep
	; rcp neutral
	subb	a,rcp_nuetral		; 21b3   95 72      .r
	mov		r0,a		; 21b5   f8         x
	mov		a,rcp_max+1		; 21b6   e5 71      eq
	subb	a,rcp_nuetral+1		; 21b8   95 73      .s
	jc		X21d3		; 21ba   40 17      @.
	
	mov		r1,a		; 21bc   f9         y
	lcall	X21f6		; 21bd   12 21 f6   .!v
	mov		forward_rcp_zone,r0		; 21c0   88 2c      .,
	clr		c			; 21c2   c3         C
	mov		a,rcp_nuetral		; 21c3   e5 72      er
	subb	a,rcp_min		; 21c5   95 74      .t
	mov		r0,a		; 21c7   f8         x
	mov		a,rcp_nuetral+1		; 21c8   e5 73      es
	subb	a,rcp_min+1		; 21ca   95 75      .u
	mov		r1,a		; 21cc   f9         y
	lcall	X21f6		; 21cd   12 21 f6   .!v
	mov		reverse_rcp_zone,r0		; 21d0   88 2d      .-
X21d2:
	ret					; 21d2   22         "
;
X21d3:
	
	clr		exchange_dir		; 21d3   c2 2d      B-
	clr	c		; 21d5   c3         C
	mov	a,rcp_nuetral		; 21d6   e5 72      er
	subb	a,rcp_max		; 21d8   95 70      .p
	mov	r0,a		; 21da   f8         x
	mov	a,rcp_nuetral+1		; 21db   e5 73      es
	subb	a,rcp_max+1		; 21dd   95 71      .q
	mov	r1,a		; 21df   f9         y
	lcall	X21f6		; 21e0   12 21 f6   .!v
	mov	forward_rcp_zone,r0		; 21e3   88 2c      .,
	clr	c		; 21e5   c3         C
	mov	a,rcp_min		; 21e6   e5 74      et
	subb	a,rcp_nuetral		; 21e8   95 72      .r
	mov	r0,a		; 21ea   f8         x
	mov	a,rcp_min+1		; 21eb   e5 75      eu
	subb	a,rcp_nuetral+1		; 21ed   95 73      .s
	mov	r1,a		; 21ef   f9         y
	lcall	X21f6		; 21f0   12 21 f6   .!v
	mov	reverse_rcp_zone,r0		; 21f3   88 2d      .-
	ret			; 21f5   22         "
;
X21f6:
	mov		b,#4		; 21f6   75 f0 04   up.
X21f9:
	clr		c		; 21f9   c3         C
	mov		a,r1		; 21fa   e9         i
	rrc		a		; 21fb   13         .
	mov		r1,a		; 21fc   f9         y
	mov		a,r0		; 21fd   e8         h
	rrc		a		; 21fe   13         .
	mov		r0,a		; 21ff   f8         x
	djnz	b,X21f9		; 2200   d5 f0 f6   Upv
	ret			; 2203   22         "

;
X2204:
	; 8 times rcp
	mov		77h,#8		; 2204   75 77 08   uw.
	mov		r3,#0		; 2207   7b 00      {.
X2209:
	jnb		rcp_t0_ready,$	; 2209   30 00 fd   0.}
	clr		ex0			; 220c   c2 a8      B(
	mov		r0,rcp_h		; 220e   a8 2b      (+
	mov		r1,rcp_l		; 2210   a9 2a      )*
	setb	ex0		; 2212   d2 a8      R(
	clr		rcp_t0_ready		; 2214   c2 00      B.
	mov		37h,#2		; 2216   75 37 02   u7.
X2219:
; SYSCLK is divided by 4, RCP must multple 4
	clr		c		; 2219   c3         C
	mov	a,r1		; 221a   e9         i
	rlc	a		; 221b   33         3
	mov	r1,a		; 221c   f9         y
	mov	a,r0		; 221d   e8         h
	rlc	a		; 221e   33         3
	mov	r0,a		; 221f   f8         x
	djnz	37h,X2219	; 2220   d5 37 f6   U7v
	mov	a,r0		; 2223   e8         h
	clr	c		; 2224   c3         C
	subb	a,#4		; 2225   94 04      ..
	jc	X2204		; 2227   40 db      @[
	mov	a,r0		; 2229   e8         h
	subb	a,#15h		; 222a   94 15      ..
	jnc	X2204		; 222c   50 d6      PV
	cjne	r3,#0,X2239	; 222e   bb 00 08   ;..
	mov	a,r0		; 2231   e8         h
	mov	r3,a		; 2232   fb         {
	mov	r5,a		; 2233   fd         }
	mov	a,r1		; 2234   e9         i
	mov	r4,a		; 2235   fc         |
	mov	r6,a		; 2236   fe         ~
	sjmp	X2261		; 2237   80 28      .(
;
X2239:	clr	c		; 2239   c3         C
	mov	a,r4		; 223a   ec         l
	subb	a,r1		; 223b   99         .
	mov	b,a		; 223c   f5 f0      up
	mov	a,r3		; 223e   eb         k
	subb	a,r0		; 223f   98         .
	jnc	X224c		; 2240   50 0a      P.
	cpl	a		; 2242   f4         t
	mov	37h,a		; 2243   f5 37      u7
	mov	a,b		; 2245   e5 f0      ep
	cpl	a		; 2247   f4         t
	mov	b,a		; 2248   f5 f0      up
	mov	a,37h		; 224a   e5 37      e7
X224c:	cjne	a,#0,X2204	; 224c   b4 00 b5   4.5
	mov	a,b		; 224f   e5 f0      ep
	subb	a,#14h		; 2251   94 14      ..
	jnc	X2204		; 2253   50 af      P/
	mov	a,r0		; 2255   e8         h
	mov	r3,a		; 2256   fb         {
	mov	a,r1		; 2257   e9         i
	mov	r4,a		; 2258   fc         |
	mov	a,r6		; 2259   ee         n
	add	a,r4		; 225a   2c         ,
	mov	r6,a		; 225b   fe         ~
	mov	a,r5		; 225c   ed         m
	addc	a,r3		; 225d   3b         ;
	mov	r5,a		; 225e   fd         }
	jc	X2204		; 225f   40 a3      @#
X2261:
	djnz	77h,X2209	; 2261   d5 77 a5   Uw%
; RCP fetch successful.
	mov		b,#3		; 2264   75 f0 03   up.
X2267:
	clr		c		; 2267   c3         C
	mov		a,r5		; 2268   ed         m
	rrc		a		; 2269   13         .
	mov		r5,a		; 226a   fd         }
	mov		a,r6		; 226b   ee         n
	rrc		a		; 226c   13         .
	mov		r6,a		; 226d   fe         ~
	djnz	b,X2267		; 226e   d5 f0 f6   Upv
	mov		a,r5		; 2271   ed         m
	mov		b,r6		; 2272   8e f0      .p
	mov		r0,78h		; 2274   a8 78      (x
	cjne	r0,#3,X2282	; 2276   b8 03 09   8..
	mov		rcp_nuetral+1,a		; 2279   f5 73      us
	mov		rcp_nuetral,b		; 227b   85 f0 72   .pr
	lcall	x316c_flash_green		; 227e   12 31 6c   .1l
	ret			; 2281   22         "
;
X2282:	cjne	r0,#2,X228e	; 2282   b8 02 09   8..
	mov	rcp_max+1,a		; 2285   f5 71      uq
	mov	rcp_max,b		; 2287   85 f0 70   .pp
	lcall	x316a_flash_green_2		; 228a   12 31 6a   .1j
	ret			; 228d   22         "
;
X228e:	cjne	r0,#1,X229a	; 228e   b8 01 09   8..
	mov	rcp_min+1,a		; 2291   f5 75      uu
	mov	rcp_min,b		; 2293   85 f0 74   .pt
	lcall	x3167_flash_green_3		; 2296   12 31 67   .1g
	ret			; 2299   22         "
;
X229a:	ret			; 229a   22         "
;
if PACK=0
x229b_long_press_button:
	mov		a,6ah		; 229b   e5 6a      ej
	mov		69h,a		; 229d   f5 69      ui
	mov		EIE1,#0		; 229f   75 e6 00   uf.
	lcall	X2561_all_fet_off		; 22a2   12 25 61   .%a
	clr		red_led		; 22a5   c2 94      B.
	clr		green_led		; 22a7   c2 93      B.
	lcall	x31c2_longlonglong_delay		; 22a9   12 31 c2   .1B
	mov		7ah,#0		; 22ac   75 7a 00   uz.
	setb	22h.4		; 22af   d2 14      R.
	lcall	x238a_menu		; 22b1   12 23 8a   .#.
	lcall	x2808_t2_reset		; 22b4   12 28 08   .(.
	mov		50h,#0		; 22b7   75 50 00   uP.
X22ba:
	jnb		TMR2CN.7,X22df	; 22ba   30 cf 22   0O"
	clr		TMR2CN.7		; 22bd   c2 cf      BO
	inc		50h		; 22bf   05 50      .P
	mov		a,50h		; 22c1   e5 50      eP
	clr		c		; 22c3   c3         C
	subb	a,#16h		; 22c4   94 16      ..
	jc		X22df		; 22c6   40 17      @.
	lcall	x2808_t2_reset		; 22c8   12 28 08   .(.
	mov		50h,#0		; 22cb   75 50 00   uP.
	inc		7ah		; 22ce   05 7a      .z
	mov		a,7ah		; 22d0   e5 7a      ez
	clr		c		; 22d2   c3         C
	subb	a,#9		; 22d3   94 09      ..
	jc		X22dc		; 22d5   40 05      @.
	jz		X22dc		; 22d7   60 03      `.
	mov		7ah,#0		; 22d9   75 7a 00   uz.
X22dc:
	lcall	x238a_menu		; 22dc   12 23 8a   .#.
X22df:
	jnb		p2.0,X22ba	; 22df   30 a0 d8   0 X
	lcall	x31e3_delay_4		; 22e2   12 31 e3   .1c
	jnb		p2.0,X22ba	; 22e5   30 a0 d2   0 R
	mov		EIE1,#80h	; 22e8   75 e6 80   uf.
	lcall	X230d		; 22eb   12 23 0d   .#.
	lcall	X235f		; 22ee   12 23 5f   .#_
	clr	22h.4		; 22f1   c2 14      B.
X22f3:	jb	p2.0,X22f3	; 22f3   20 a0 fd     }
	lcall	x31e3_delay_4		; 22f6   12 31 e3   .1c
	jb	p2.0,X22f3	; 22f9   20 a0 f7     w
	lcall	X230d		; 22fc   12 23 0d   .#.
	lcall	X235f		; 22ff   12 23 5f   .#_
X2302:	jnb	p2.0,X2302	; 2302   30 a0 fd   0 }
	lcall	x31e3_delay_4		; 2305   12 31 e3   .1c
	jnb	p2.0,X2302	; 2308   30 a0 f7   0 w
	sjmp	X22f3		; 230b   80 e6      .f
;
X230d:
	mov		a,7ah		; 230d   e5 7a      ez
	mov		dptr,#X36a0	; 230f   90 36 a0   .6 
	movc	a,@a+dptr	; 2312   93         .
	mov		r1,a		; 2313   f9         y
	mov		a,#60h		; 2314   74 60      t`
	add		a,7ah		; 2316   25 7a      %z
	mov		r0,a		; 2318   f8         x
	mov		a,@r0		; 2319   e6         f
	mov		7bh,a		; 231a   f5 7b      u{
	jb		22h.4,X2334	; 231c   20 14 15    ..
	clr		c		; 231f   c3         C
	subb	a,r1		; 2320   99         .
	jnc		X2326		; 2321   50 03      P.
	inc		@r0		; 2323   06         .
	sjmp	X2328		; 2324   80 02      ..
;
X2326:
	mov		@r0,#0		; 2326   76 00      v.
X2328:
	mov		7bh,@r0		; 2328   86 7b      .{
	mov		a,69h		; 232a   e5 69      ei
	mov		6ah,a		; 232c   f5 6a      uj
	mov		69h,#0		; 232e   75 69 00   ui.
	lcall	X1ef1		; 2331   12 1e f1   ..q
X2334:	ret			; 2334   22         "
;
	clr	fresh_red		; 2335   c2 16      B.
	setb	22h.5		; 2337   d2 15      R.
	mov	a,7ah		; 2339   e5 7a      ez
endif

X233b:
	clr		22h.7		; 233b   c2 17      B.
X233d:
	inc	a		; 233d   04         .
	mov	b,#5		; 233e   75 f0 05   up.
	div	ab		; 2341   84         .
	mov	r0,b		; 2342   a8 f0      (p
	mov	b,#2		; 2344   75 f0 02   up.
	mul	ab		; 2347   a4         $
	mov	7dh,a		; 2348   f5 7d      u}
	mov	7fh,a		; 234a   f5 7f      u.
	mov	a,r0		; 234c   e8         h
	mov	b,#2		; 234d   75 f0 02   up.
	mul	ab		; 2350   a4         $
	mov	7ch,a		; 2351   f5 7c      u|
	mov	7eh,a		; 2353   f5 7e      u~
	lcall	x236f_pca0cp0_set_10h		; 2355   12 23 6f   .#o
	clr	green_led		; 2358   c2 93      B.
	clr	red_led		; 235a   c2 94      B.
	clr	fet_bp		; 235c   c2 86      B.
	ret			; 235e   22         "
;
X235f:	clr	22h.5		; 235f   c2 15      B.
	setb	fresh_red		; 2361   d2 16      R.
	mov	a,7bh		; 2363   e5 7b      e{
	sjmp	X233b		; 2365   80 d4      .T
;

x2367_pca0cp0_setting:
	setb	22h.7		; 2367   d2 17      R.
	setb	fresh_red		; 2369   d2 16      R.
	clr		22h.5		; 236b   c2 15      B.
	sjmp	X233d		; 236d   80 ce      .N
;
x236f_pca0cp0_set_10h:
	lcall	x24d6_pca0cp0_set_5		; 236f   12 24 d6   .$V
	mov	PCA0CPL0,#10h	; 2372   75 fb 10   u{.
	mov	PCA0CPH0,#10h	; 2375   75 fc 10   u|.
	mov	P0SKIP,#0ffh	; 2378   75 d4 ff   uT.
	mov	P1SKIP,#0fdh	; 237b   75 d5 fd   uU}  ; p1.1 cn
	clr	22h.3		; 237e   c2 13      B.
	mov	3ah,#1		; 2380   75 3a 01   u:.
	lcall	x2121_t3_reset		; 2383   12 21 21   .!!
	; timer 3 enable
	mov	EIE1,#80h	; 2386   75 e6 80   uf.
	ret			; 2389   22         "
;
x238a_menu:
	mov	a,7ah		; 238a   e5 7a      ez
	mov	b,#2		; 238c   75 f0 02   up.
	mul	ab		; 238f   a4         $
	mov	dptr,#X2394	; 2390   90 23 94   .#.
	jmp	@a+dptr		; 2393   73         s
;
X2394:
	sjmp	X23e4		; 2394   80 4e      .N
	sjmp	X23e1		; 2396   80 49      .I
	sjmp	X23de		; 2398   80 44      .D
	sjmp	X23db		; 239a   80 3f      .?
	sjmp	X23d7		; 239c   80 39      .9
	sjmp	X23d2		; 239e   80 32      .2
	sjmp	X23cd		; 23a0   80 2b      .+
	sjmp	X23c8		; 23a2   80 24      .$
	sjmp	X23c3		; 23a4   80 1d      ..
	sjmp	X23bc		; 23a6   80 14      ..
	sjmp	X23b4		; 23a8   80 0a      ..
	sjmp	X23ac		; 23aa   80 00      ..
;
X23ac:
	lcall	x31a4_long_light_green		; 23ac   12 31 a4   .1$
	lcall	x31a4_long_light_green		; 23af   12 31 a4   .1$
	sjmp	X23e1		; 23b2   80 2d      .-
;
X23b4:
	lcall	x31a4_long_light_green		; 23b4   12 31 a4   .1$
	lcall	x31a4_long_light_green		; 23b7   12 31 a4   .1$
	sjmp	X23e4		; 23ba   80 28      .(
;
X23bc:
	lcall	x31a4_long_light_green		; 23bc   12 31 a4   .1$
	lcall	x31a4_long_light_green		; 23bf   12 31 a4   .1$
	ret			; 23c2   22         "
;
X23c3:
	lcall	x31a4_long_light_green		; 23c3   12 31 a4   .1$
	sjmp	X23db		; 23c6   80 13      ..
;
X23c8:
	lcall	x31a4_long_light_green		; 23c8   12 31 a4   .1$
	sjmp	X23de		; 23cb   80 11      ..
;
X23cd:
	lcall	x31a4_long_light_green		; 23cd   12 31 a4   .1$
	sjmp	X23e1		; 23d0   80 0f      ..
;
X23d2:
	lcall	x31a4_long_light_green		; 23d2   12 31 a4   .1$
	sjmp	X23e4		; 23d5   80 0d      ..
;
X23d7:
	lcall	x31a4_long_light_green		; 23d7   12 31 a4   .1$
	ret			; 23da   22         "
;
X23db:	lcall	x3189_short_light_green		; 23db   12 31 89   .1.
X23de:	lcall	x3189_short_light_green		; 23de   12 31 89   .1.
X23e1:	lcall	x3189_short_light_green		; 23e1   12 31 89   .1.
X23e4:	lcall	x3189_short_light_green		; 23e4   12 31 89   .1.
	ret			; 23e7   22         "
;
X23e8:
	; system voltage failure
	lcall	x316a_flash_green_2		; 23e8   12 31 6a   .1j
	lcall	x31c2_longlonglong_delay		; 23eb   12 31 c2   .1B
x23ee_audit_sys_voltage:
	mov		79h,#2		; 23ee   75 79 02   uy.
X23f1:
	lcall	x2475_number_of_battery		; 23f1   12 24 75   .$u
	mov		a,62h		; 23f4   e5 62      eb
	jz		X23fe		; 23f6   60 06      `.
	cjne	r0,#0,X23fe	; 23f8   b8 00 03   8..
	ljmp	X23e8		; 23fb   02 23 e8   .#h
;
X23fe:
; system voltage is failed, try 2 times
	lcall	x31e3_delay_4		; 23fe   12 31 e3   .1c
	djnz	79h,X23f1	; 2401   d5 79 ed   Uym

	mov		a,r7		; 2404   ef         o
	clr		c		; 2405   c3         C
	subb	a,#32h		; 2406   94 32      .2
	jnc		X240d		; 2408   50 03      P.
	lcall	x316a_flash_green_2		; 240a   12 31 6a   .1j
X240d:
	mov		a,r7
	clr		c
	subb	a,#79h		; 9V 作为2S和3S分界
	jc		battery2s
	mov		a,r7
	subb	a,#0b4h		; 13V 3S和4S分界
	jc		battery3s
	; 4s battery
	mov		burden_volt,#170-6
	mov		power_fail_volt,#170	; 12.5v
	sjmp	X246b
battery3s:
	; 3s battery
	mov		burden_volt,#128-5
	mov		power_fail_volt,#128	; 9.5v
	sjmp	X246b
battery2s:
	mov		burden_volt,#88-4 		; 6.5v
	mov		power_fail_volt,#88
;	sjmp	X246b
	; 原来的电压保护不合理。因此不用了
;	mov		a,62h		; 240d   e5 62      eb
;	cjne	a,#6,X243b	; 240f   b4 06 29   4.)
; 无设置功能，因此，上面的条件永久成立。
;	mov		dptr,#X3810	; 2412   90 38 10   .8.
;	clr		a		; 2415   e4         d
;	movc	a,@a+dptr	; 2416   93         .
;	jz		X2421		; 2417   60 08      `.
;	cjne	a,#1,X2421	; 2419   b4 01 05   4..
;	mov		dptr,#X3880	; 241c   90 38 80   .8.
;	sjmp	X242b		; 241f   80 0a      ..
;
;X2421:
;	mov		dptr,#X3840	; 2421   90 38 40   .8@
;	sjmp	X242b		; 2424   80 05      ..
;
;	mov		dptr,#X38c0	; 2426   90 38 c0   .8@
;	sjmp	X242b		; 2429   80 00      ..
;
;X242b:
;	mov		a,#5		; 242b   74 05      t.
;	movc	a,@a+dptr	; 242d   93         .
;	mov		burden_volt,a		; 242e   f5 40      u@
;	clr		c		; 2430   c3         C
;	add		a,#5		; 2431   24 05      $.
;	jnc		X2437		; 2433   50 02      P.
;	mov		a,#0ffh		; 2435   74 ff      t.
;X2437:
;	mov		power_fail_volt,a		; 2437   f5 36      u6
;	sjmp	X246b		; 2439   80 30      .0
;
;X243b:

;	mov		dptr,#X246f	; 243b   90 24 6f   .$o
;	mov		a,62h		; 243e   e5 62      eb
;	movc	a,@a+dptr	; 2440   93         .
;	mov		r1,a		; 2441   f9         y
;	mov		a,r7		; 2442   ef         o
;	clr		c		; 2443   c3         C
;	subb	a,#79h		; 2444   94 79      .y
;	jc		X2458		; 2446   40 10      @.
;	mov		a,r7		; 2448   ef         o
;	clr		c		; 2449   c3         C
;	subb	a,#0b6h		; 244a   94 b6      .6
;	jc	X2453		; 244c   40 05      @.
;	mov	b,#4		; 244e   75 f0 04   up.
;	sjmp	X245b		; 2451   80 08      ..
;
;X2453:	mov	b,#3		; 2453   75 f0 03   up.
;	sjmp	X245b		; 2456   80 03      ..
;
;X2458:	mov	b,#2		; 2458   75 f0 02   up.
;X245b:	mov	power_fail_volt,b		; 245b   85 f0 36   .p6
;	mov	a,r1		; 245e   e9         i
;	mul	ab		; 245f   a4         $
;	mov	burden_volt,a		; 2460   f5 40      u@
;	mov	a,r1		; 2462   e9         i
;	add	a,#4		; 2463   24 04      $.
;	mov	b,power_fail_volt		; 2465   85 36 f0   .6p
;	mul	ab		; 2468   a4         $
;	mov	power_fail_volt,a		; 2469   f5 36      u6
X246b:
	mov	5dh,#90h	; 246b   75 5d 90   u].
	ret			; 246e   22         "
;
X246f:
;	nop			; 246f   00         .
;	rl	a		; 2470   23         #
;	add	a,@r0		; 2471   26         &
;	add	a,r1		; 2472   29         )
;	add	a,r4		; 2473   2c         ,
;	add	a,r6		; 2474   2e         .
db	0,23h,26h,29h,2ch,2eh
x2475_number_of_battery:
	;ADC0CF[AD0SC(4:0)|AD0LJST|-|-]
	;AD0LJST 1: ADC0H:ADC0L registers are left-justified
	mov		ADC0CF,#0fch	; 2475   75 bc fc   u<|
	; AMX0N: AMUX0 NEGATIVE CHANNEL SELECT
	; GND was selected as negative channel.
	mov		AMX0N,#11h	; 2478   75 ba 11   u:.
	; AMX0P: AMUX0 POSTIVE CHANNEL SELECT
	; p1.7 was selected as postive channel.
	mov		AMX0P,#0fh	; 247b   75 bb 0f   u;.
	; AD0CM[2:0] 000: ADC0 start of conversion source is write of '1' to AD0BUSY
	mov		ADC0CN,#80h	; 247e   75 e8 80   uh.
	lcall	x2494_get_sys_voltage		; 2481   12 24 94   .$.
	mov		dptr,#X24af	; 2484   90 24 af   .$/
	mov		r0,#0		; 2487   78 00      x.
X2489:
	mov		a,r0		; 2489   e8         h
	movc	a,@a+dptr	; 248a   93         .
	clr		c		; 248b   c3         C
	subb	a,r7		; 248c   9f         .
	jnc		X2493		; 248d   50 04      P.
	inc		r0		; 248f   08         .
	ljmp	X2489		; 2490   02 24 89   .$.
;
X2493:	ret			; 2493   22         "
; take 2 times of system voltage.
; take again if the absolute value of first time minus second time great & equal than 2
; result: r7,51h
x2494_get_sys_voltage:
	lcall	x31f8_delay_18h		; 2494   12 31 f8   .1x
	lcall	X24b4		; 2497   12 24 b4   .$4
	mov		51h,r7		; 249a   8f 51      .Q
	lcall	x31f8_delay_18h		; 249c   12 31 f8   .1x
	lcall	X24b4		; 249f   12 24 b4   .$4
	mov		a,r7		; 24a2   ef         o
	clr		c		; 24a3   c3         C
	subb	a,51h		; 24a4   95 51      .Q
	jnc		X24a9		; 24a6   50 01      P.
	cpl		a		; 24a8   f4         t
X24a9:
	clr		c		; 24a9   c3         C
	subb	a,#2		; 24aa   94 02      ..
	jnc		x2494_get_sys_voltage		; 24ac   50 e6      Pf
	ret			; 24ae   22         "
;
X24af:
db 44h,51h,7ah,0a3h,0ffh
X24b4:
	clr		AD0INT		; 24b4   c2 ed      Bm
	setb	AD0BUSY		; 24b6   d2 ec      Rl
	jnb		AD0INT,$	; 24b8   30 ed fd   0m}
	clr		AD0INT		; 24bb   c2 ed      Bm
	setb	AD0BUSY		; 24bd   d2 ec      Rl
	jnb		AD0INT,$	; 24bf   30 ed fd   0m}
	mov		a,ADC0L		; 24c2   e5 bd      e=
	mov		r7,ADC0H		; 24c4   af be      />
	clr		AD0INT		; 24c6   c2 ed      Bm
	setb	AD0BUSY		; 24c8   d2 ec      Rl
	jnb		AD0INT,$	; 24ca   30 ed fd   0m}
	mov		a,ADC0L		; 24cd   e5 bd      e=
	mov		a,ADC0H		; 24cf   e5 be      e>
	clr		c		; 24d1   c3         C
	addc	a,r7		; 24d2   3f         ?
	rrc		a		; 24d3   13         .
	mov		r7,a		; 24d4   ff         .
	ret			; 24d5   22         "
;
x24d6_pca0cp0_set_5:
; PCA0MD[CIDL|WDTE|WDLCK|-|CPS2|CPS1|CPS0|ECF]
; CPS[2:0] 000: SYSTE CLOCK DIVIDED BY 12
; ECF 0: disable the CF interrupt
; CIDL 0:PCA continues to function normally while the system controller is in idle mode
; WDTE 0: Watchdog timer disabled
; WDLCK 0:Watchdog Timer enable unlock
	mov	PCA0MD,#0	; 24d6   75 d9 00   uY.
; PCA0CN[CF|CR|-|-|-|CCF2|CCF1|CCF0]
; CF PCA counter/timer overflow flag. This bit is not automatically
;    cleared by hardware and must be cleared by software
; CR 1: PCA Counter/Timer enabled
; CCFn PCA module n capture/compare flag
	mov	PCA0CN,#01000000b	; 24d9   75 d8 40   uX@
	mov	PCA0MD,#0	; 24dc   75 d9 00   uY.
; PCA0CPMn[PWM16n|ECOMn|CAPPn|CAPNn|MATn|TOGn|PWMn|ECCFn]
; PWM16n 0: 8 to 11-bit PWM selected
; ECOMn 1: comparator function enable
; CAPPn 0: capture postive function disable
; CAPNn 0: capture negative function disable
; MATn  0: MATCH FUNCTION DISABLE
; TOGn  0: Toggle function enable
; PWMn  1: PWM mode enable
; ECCFn 0: CAPTURE/COMPARE Flag interrupt disable
	mov	PCA0CPM0,#01000010b	; 24df   75 da 42   uZB
	mov	PCA0CPL0,#5		; 24e2   75 fb 05   u{.
	mov	PCA0CPH0,#5		; 24e5   75 fc 05   u|.
	ret			; 24e8   22         "
;
x24e9_set_pwm0_duty:
; timebase source for sysclk divided by 12
; ECF was set 0 for PCA C/T OVERFLOW interrupt request
	mov		PCA0MD,#0	; 24e9   75 d9 00   uY.
; CR was set 1 for PCA enable.
	mov		PCA0CN,#40h	; 24ec   75 d8 40   uX@
	mov		PCA0MD,#0	; 24ef   75 d9 00   uY.
; ECOMn was set 1 for comparator function n enable
; PWMn was set 1
	mov		PCA0CPM0,#42h	; 24f2   75 da 42   uZB
	mov		PCA0CPL0,r2		; 24f5   8a fb      .{
	mov		PCA0CPH0,r2		; 24f7   8a fc      .|
	ret			; 24f9   22         "
;
x24fa_enable_interrupt:
;	mov	P0SKIP,#0cfh	; 24fa   75 d4 cf   uTO
	mov	P1SKIP,#0fdh	; 24fd   75 d5 fd   uU}  ; p1.1 cn
	mov	XBR0,#1		; 2500   75 e1 01   ua.
	mov	XBR1,#41h	; 2503   75 e2 41   ubA
	mov	tcon,#1		; 2506   75 88 01   u..
	mov	tmod,#00101001b	; 2509   75 89 29   u.)
	mov	CKCON,#0		; 250c   75 8e 00   u..
	mov	tl0,#0		; 250f   75 8a 00   u..
	mov	th0,#0		; 2512   75 8c 00   u..
	mov	th1,#0cbh	; 2515   75 8d cb   u.K
	mov	tl1,#0cbh	; 2518   75 8b cb   u.K
	mov	scon,#20h	; 251b   75 98 20   u. 
	mov	tcon,#51h	; 251e   75 88 51   u.Q
	setb	ex0		; 2521   d2 a8      R(
	setb	ren		; 2523   d2 9c      R.
	setb	es		; 2525   d2 ac      R,
	ret			; 2527   22         "
;
x2528_check_ready_rcp:
	jnb		rcp_t0_ready,X252e	; 2528   30 00 03   0..
	lcall	x2e69_verify_rcp		; 252b   12 2e 69   ..i
X252e:
	ret			; 252e   22         "
;
X252f:
	mov		a,accelate_factor		; 252f   e5 2e      e.
	subb	a,5dh		; 2531   95 5d      .]
	jnc		X2557		; 2533   50 22      P"
	mov		a,4ah		; 2535   e5 4a      eJ
	jnz		X2544		; 2537   70 0b      p.
	clr		c		; 2539   c3         C
	mov		a,49h		; 253a   e5 49      eI
	subb	a,#50h		; 253c   94 50      .P
	jc		X2556		; 253e   40 16      @.
	mov		49h,a		; 2540   f5 49      uI
	sjmp	X254f		; 2542   80 0b      ..
X2544:
	clr		c		; 2544   c3         C
	mov		a,49h		; 2545   e5 49      eI
	subb	a,#50h		; 2547   94 50      .P
	mov		49h,a		; 2549   f5 49      uI
	jnc		X254f		; 254b   50 02      P.
	dec		4ah		; 254d   15 4a      .J
X254f:
	mov		a,accelate_factor		; 254f   e5 2e      e.
	clr		c		; 2551   c3         C
	add		a,54h		; 2552   25 54      %T
	mov		accelate_factor,a		; 2554   f5 2e      u.
X2556:
	ret			; 2556   22         "
;
X2557:
	mov		accelate_factor,5dh		; 2557   85 5d 2e   .].
	mov		4ah,#0		; 255a   75 4a 00   uJ.
	mov		49h,#0		; 255d   75 49 00   uI.
	ret			; 2560   22         "
;
X2561_all_fet_off:
	anl	PCA0CPM0,#0	; 2561   53 da 00   SZ.
	anl	PCA0CPM1,#0	; 2564   53 db 00   S[.
	anl	PCA0CPM2,#0		; 2567   53 dc 00   S\.
	clr	fet_bp		; 256a   c2 86      B.
	clr	fet_cp		; 256c   c2 90      B.
	clr	fet_ap		; 256e   c2 96      B.
	setb	fet_bn		; 2570   d2 92      R.
	setb	fet_cn		; 2572   d2 91      R.
	setb	fet_an		; 2574   d2 95      R.
	ret			; 2576   22         "
;
x2577_change_4bh:
	mov		a,4bh		; 2577   e5 4b      eK
	cjne	a,#0ffh,X257d	; 2579   b4 ff 01   4..
	ret			; 257c   22         "
;
X257d:
	mov		a,4ah		; 257d   e5 4a      eJ
	jnz		X258c		; 257f   70 0b      p.
	clr		c		; 2581   c3         C
	mov		a,49h		; 2582   e5 49      eI
	subb	a,#5		; 2584   94 05      ..
	jc		X25a2		; 2586   40 1a      @.
	mov		49h,a		; 2588   f5 49      uI
	sjmp	X2597		; 258a   80 0b      ..
;
X258c:	clr	c		; 258c   c3         C
	mov	a,49h		; 258d   e5 49      eI
	subb	a,#5		; 258f   94 05      ..
	mov	49h,a		; 2591   f5 49      uI
	jnc	X2597		; 2593   50 02      P.
	dec	4ah		; 2595   15 4a      .J
X2597:	mov	a,4bh		; 2597   e5 4b      eK
	clr	c		; 2599   c3         C
	add	a,#2		; 259a   24 02      $.
	jnc	X25a0		; 259c   50 02      P.
	mov	a,#0ffh		; 259e   74 ff      t.
X25a0:	mov	4bh,a		; 25a0   f5 4b      uK
X25a2:	ret			; 25a2   22         "
;
x25a3_control_start:
	lcall	X2561_all_fet_off		; 25a3   12 25 61   .%a
	lcall	x321f_delay_4		; 25a6   12 32 1f   .2.
	mov		r2,#5		; 25a9   7a 05      z.
	mov		XBR1,#43h	; 25ab   75 e2 43   ubC
	mov		P1SKIP,#0ffh
;	lcall	x274c_brake_pwm_r2		; 25ae   12 27 4c   .'L
	mov		OSCICN,#0c0h	; 25b1   75 b2 c0   u2@
	lcall	x2121_t3_reset		; 25b4   12 21 21   .!!
	lcall	x2808_t2_reset		; 25b7   12 28 08   .(.
	mov		state_timeout,#0		; 25ba   75 44 00   uD.
	mov		4ah,#0		; 25bd   75 4a 00   uJ.
	mov		49h,#0		; 25c0   75 49 00   uI.
	mov		4bh,#30h	; 25c3   75 4b 30   uK0
	setb	rcp_x_8		; 25c6   d2 39      R9
	clr		forwarding	; 25c8   c2 03      B.
	clr		20h.6		; 25ca   c2 06      B.
x25cc_start_loop:
	lcall	x2a90_t3_sum		; 25cc   12 2a 90   .*.
	mov		a,motor_status		; 25cf   e5 59      eY
	cjne	a,#1,X25dd	; 25d1   b4 01 09   4..
	jnb		go_run,X25da	; 25d4   30 1e 03   0..
	ljmp	x26ea_brake_motor		; 25d7   02 26 ea   .&j
;
X25da:
	ljmp	X26a8		; 25da   02 26 a8   .&(
;
X25dd:
	cjne	a,#11h,X25e3	; 25dd   b4 11 03   4..
	ljmp	X26a8		; 25e0   02 26 a8   .&(
;
X25e3:
	cjne	a,#12h,X25f4	; 25e3   b4 12 0e   4..
	mov		run_braking_cnt,#0		; 25e6   75 53 00   uS.
	mov		a,60h		; 25e9   e5 60      e`
	cjne	a,#2,X25f1	; 25eb   b4 02 03   4..
	ljmp	x26ea_brake_motor		; 25ee   02 26 ea   .&j
;
X25f1:
	ljmp	X26b3		; 25f1   02 26 b3   .&3
;
X25f4:
	cjne	a,#2,X2641	; 25f4   b4 02 4a   4.J
	mov		run_braking_cnt,#0		; 25f7   75 53 00   uS.
	; 60h = 1
	mov		a,60h		; 25fa   e5 60      e`
	cjne	a,#2,X2608	; 25fc   b4 02 09   4..
	jnb		go_run,X2605	; 25ff   30 1e 03   0..
	ljmp	X26aa		; 2602   02 26 aa   .&*
;
X2605:
	ljmp	x26ea_brake_motor		; 2605   02 26 ea   .&j
;
X2608:	jnb	21h.6,X2611	; 2608   30 0e 06   0..
	jnb	go_run,X2611	; 260b   30 1e 03   0..
	ljmp	X26aa		; 260e   02 26 aa   .&*
;
X2611:	jb	first_state,X2617	; 2611   20 10 03    ..
	ljmp	X26b3		; 2614   02 26 b3   .&3
;
X2617:	jb	21h.6,X261d	; 2617   20 0e 03    ..
	ljmp	X26b3		; 261a   02 26 b3   .&3
;
X261d:
	lcall	X2561_all_fet_off		; 261d   12 25 61   .%a
	mov	AMX0P,#2		; 2620   75 bb 02   u;.
	mov	AMX0N,#11h	; 2623   75 ba 11   u:.
	mov	ADC0CF,#64h	; 2626   75 bc 64   u<d
	mov	ADC0CN,#80h	; 2629   75 e8 80   uh.
	mov	r3,#5		; 262c   7b 05      {.
X262e:	clr	AD0INT		; 262e   c2 ed      Bm
	setb	AD0BUSY		; 2630   d2 ec      Rl
X2632:	jnb	AD0INT,X2632	; 2632   30 ed fd   0m}
	mov	a,ADC0H		; 2635   e5 be      e>
	clr	c		; 2637   c3         C
	subb	a,#0ah		; 2638   94 0a      ..
	jnc	X26b3		; 263a   50 77      Pw
	djnz	r3,X262e	; 263c   db f0      [p
	ljmp	X26aa		; 263e   02 26 aa   .&*
;
X2641:	cjne	a,#22h,X2655	; 2641   b4 22 11   4".

	mov	a,60h		; 2644   e5 60      e`
	cjne	a,#2,X264c	; 2646   b4 02 03   4..
	ljmp	X26aa		; 2649   02 26 aa   .&*
;
X264c:	jnb	go_run,X26b6	; 264c   30 1e 67   0.g
	jnb	21h.6,X26b6	; 264f   30 0e 64   0.d
	ljmp	X26aa		; 2652   02 26 aa   .&*
;
X2655:
	cjne	a,#21h,X2661	; 2655   b4 21 09   4!.
	jb		go_run,X265e	; 2658   20 1e 03    ..
	ljmp	X26a8		; 265b   02 26 a8   .&(
;
X265e:
	ljmp	x26ea_brake_motor		; 265e   02 26 ea   .&j
;
X2661:
	mov		run_braking_cnt,#0		; 2661   75 53 00   uS.
;	jb	skip_check_btn,X2673	; 2664   20 2c 0c    ,.
;	jb	p2.0,X2673	; 2667   20 a0 09     .
;	lcall	x1d63_set_default_rcp_range		; 266a   12 1d 63   ..c
;	jnb	skip_check_btn,X2673	; 266d   30 2c 03   0,.
;	ljmp	X1c38		; 2670   02 1c 38   ..8
;
;X2673:
;	mov		a,61h		; 2673   e5 61      ea
;	cjne	a,#8,X2695	; 2675   b4 08 1d   4..
;	mov		dptr,#X3810	; 2678   90 38 10   .8.
;	clr		a		; 267b   e4         d
;	movc	a,@a+dptr	; 267c   93         .
;	jz	X2687		; 267d   60 08      `.
;	cjne	a,#1,X268c	; 267f   b4 01 0a   4..
;	mov	dptr,#X3880	; 2682   90 38 80   .8.
;	sjmp	X2691		; 2685   80 0a      ..
;
;X2687:	mov	dptr,#X3840	; 2687   90 38 40   .8@
;	sjmp	X2691		; 268a   80 05      ..
;
;X268c:	mov	dptr,#X38c0	; 268c   90 38 c0   .8@
;	sjmp	X2691		; 268f   80 00      ..
;
;X2691:	mov	a,#3		; 2691   74 03      t.
;	sjmp	X269a		; 2693   80 05      ..
;
;X2695:


;61h=2
	mov		dptr,#X28f2	; 2695   90 28 f2   .(r
	mov		a,61h		; 2698   e5 61      ea
;X269a:
	movc	a,@a+dptr	; 269a   93         .
	mov		r2,a		; 269b   fa         z
;	lcall	x274c_brake_pwm_r2		; 269c   12 27 4c   .'L
	jnb		rcp_t0_ready,X26a5	; 269f   30 00 03   0..
	lcall	x2e69_verify_rcp		; 26a2   12 2e 69   ..i
X26a5:
	ljmp	x25cc_start_loop		; 26a5   02 25 cc   .%L
;
X26a8:
	clr		dir_reverse		; 26a8   c2 0a      B.
X26aa:
	lcall	x2816_cfg_according_params		; 26aa   12 28 16   .(.
	mov		OSCICN,#0c3h	; 26ad   75 b2 c3   u2C
	ljmp	X27f4		; 26b0   02 27 f4   .'t
;
X26b3:
	lcall	x274c_brake_pwm_r2		; 26b3   12 27 4c   .'L
X26b6:
	lcall	x274c_brake_pwm_r2		; 26b6   12 27 4c   .'L
	jb		rcp_t0_ready,X26bf	; 26b9   20 00 03    ..
	ljmp	x25cc_start_loop		; 26bc   02 25 cc   .%L
;
X26bf:
	lcall	x2e69_verify_rcp		; 26bf   12 2e 69   ..i
; R2+[3dh]
	lcall	X2789		; 26c2   12 27 89   .'.
	lcall	x274c_brake_pwm_r2		; 26c5   12 27 4c   .'L
	clr		c		; 26c8   c3         C
	mov		a,current_pwm		; 26c9   e5 35      e5
	subb	a,#60h		; 26cb   94 60      .`
	jc		X26e4		; 26cd   40 15      @.
	inc		run_braking_cnt		; 26cf   05 53      .S
	mov		a,run_braking_cnt		; 26d1   e5 53      eS
	clr		c		; 26d3   c3         C
	subb	a,#5		; 26d4   94 05      ..
	jc		X26e7		; 26d6   40 0f      @.
	jb		first_state,X26df	; 26d8   20 10 04    ..
	setb	first_state		; 26db   d2 10      R.
	sjmp	X26e4		; 26dd   80 05      ..
;
X26df:
;	jnb		25h.6,X26b6	; 26df   30 2e d4   0.T
	sjmp	X26b6
;	setb	22h.1		; 26e2   d2 11      R.
X26e4:
	mov		run_braking_cnt,#0		; 26e4   75 53 00   uS.
X26e7:
	ljmp	x25cc_start_loop		; 26e7   02 25 cc   .%L
;
x26ea_brake_motor:	mov	4bh,#0ffh	; 26ea   75 4b ff   uK.
	mov	r2,#80h		; 26ed   7a 80      z.
	mov	a,65h		; 26ef   e5 65      ee
	clr	c		; 26f1   c3         C
	subb	a,#2		; 26f2   94 02      ..
	jnc	X26fa		; 26f4   50 04      P.
	mov	r3,#40h		; 26f6   7b 40      {@
	sjmp	X26fc		; 26f8   80 02      ..
;
X26fa:	mov	r3,#40h		; 26fa   7b 40      {@
X26fc:	lcall	x274c_brake_pwm_r2		; 26fc   12 27 4c   .'L
	lcall	x31de_delay_1		; 26ff   12 31 de   .1^
	mov	a,r2		; 2702   ea         j
	clr	c		; 2703   c3         C
	add	a,r3		; 2704   2b         +
	mov	r2,a		; 2705   fa         z
	jnc	X26fc		; 2706   50 f4      Pt
	mov	a,#0ffh		; 2708   74 ff      t.
	mov	r2,a		; 270a   fa         z
	lcall	x274c_brake_pwm_r2		; 270b   12 27 4c   .'L
X270e:	mov	r2,#0ffh	; 270e   7a ff      z.
	lcall	x274c_brake_pwm_r2		; 2710   12 27 4c   .'L
	lcall	x31de_delay_1		; 2713   12 31 de   .1^
	lcall	X2561_all_fet_off		; 2716   12 25 61   .%a
	lcall	X3205		; 2719   12 32 05   .2.
	lcall	X3205		; 271c   12 32 05   .2.
	mov	AMX0P,#2		; 271f   75 bb 02   u;.
	mov	AMX0N,#11h	; 2722   75 ba 11   u:.
	mov	ADC0CF,#64h	; 2725   75 bc 64   u<d
	mov	ADC0CN,#80h	; 2728   75 e8 80   uh.
	mov	r3,#5		; 272b   7b 05      {.
X272d:	clr	AD0INT		; 272d   c2 ed      Bm
	setb	AD0BUSY		; 272f   d2 ec      Rl
X2731:	jnb	AD0INT,X2731	; 2731   30 ed fd   0m}
	mov	a,ADC0H		; 2734   e5 be      e>
	clr	c		; 2736   c3         C
	subb	a,#0ah		; 2737   94 0a      ..
	jnc	X270e		; 2739   50 d3      PS
	djnz	r3,X272d	; 273b   db f0      [p
	mov	a,60h		; 273d   e5 60      e`
	cjne	a,#2,X2745	; 273f   b4 02 03   4..
	ljmp	X26aa		; 2742   02 26 aa   .&*
;
X2745:	ljmp	X26a8		; 2745   02 26 a8   .&(
;
X2748:
db	40h,80h,0c0h,0ffh
x274c_brake_pwm_r2:
	lcall	x2577_change_4bh		; 274c   12 25 77   .%w
;	mov		P0SKIP,#0cfh	; 274f   75 d4 cf   uTO
	mov		P1SKIP,#0d9h	; 2752   75 d5 d9   uUY   ; p1.1 p1.2 p1.5 an bn cn
	mov		a,r2		; 2755   ea         j
	clr		c		; 2756   c3         C
	subb	a,4bh		; 2757   95 4b      .K
	jc		X275d		; 2759   40 02      @.
	mov		r2,4bh		; 275b   aa 4b      *K
X275d:
	mov		PCA0CPH0,r2		; 275d   8a fc      .|
	mov		PCA0CPH1,r2	; 275f   8a ea      .j
	mov		PCA0CPH2,r2		; 2761   8a ec      .l
; following settings are enable all 8bit pwm module, 
;I accsum that it turn on all nfet on pwm.

;PCA0CPMn[PWM16n|ECOMn|CAPPn|CAPPn|CAPNn|MATn|TOGn|PWMn|ECCFn]
; PWM16n: 16bit pwm is unselected
; ECOMn: Comparator function enable
; PWMn: When enabled, a pulse width modulated signal is output on the CEXn pin.
	mov		PCA0CPM0,#42h	; 2763   75 da 42   uZB
	mov		PCA0CPM1,#42h	; 2766   75 db 42   u[B
	mov		PCA0CPM2,#42h	; 2769   75 dc 42   u\B
	cjne	r2,#0ffh,X2783	; 276c   ba ff 14   :..
	mov		PCA0CPH0,r2		; 276f   8a fc      .|
	mov		PCA0CPH1,r2	; 2771   8a ea      .j
	mov		PCA0CPH2,r2		; 2773   8a ec      .l
; clear ECOMn, comparator function disabled
	anl		PCA0CPM0,#0bfh	; 2775   53 da bf   SZ?
	anl		PCA0CPM1,#0bfh	; 2778   53 db bf   S[?
	anl		PCA0CPM2,#0bfh	; 277b   53 dc bf   S\?
	setb	green_led		; 277e   d2 93      R.
	setb	red_led		; 2780   d2 94      R.
	ret			; 2782   22         "
;
X2783:
	jnb		hi_pwm,X2788	; 2783   30 12 02   0..
	setb	red_led		; 2786   d2 94      R.
X2788:
	ret			; 2788   22         "
;
X2789:
	clr		c		; 2789   c3         C
	mov		a,r2		; 278a   ea         j
	add		a,3dh		; 278b   25 3d      %=
	mov		r2,a		; 278d   fa         z
	jnc		X2792		; 278e   50 02      P.
	mov		r2,#0ffh	; 2790   7a ff      z.
X2792:
	mov		dptr,#X2748	; 2792   90 27 48   .'H
	;64h=3
	mov		a,64h		; 2795   e5 64      ed
	movc	a,@a+dptr	; 2797   93         .
	mov		b,a		; 2798   f5 f0      up
	subb	a,r2		; 279a   9a         .
	jnc		X279f		; 279b   50 02      P.
	mov		r2,b		; 279d   aa f0      *p
X279f:
	ret			; 279f   22         "

X27a0:
	clr		adc_busy		; 27a0   c2 33      B3
X27a2:
	lcall	x24d6_pca0cp0_set_5		; 27a2   12 24 d6   .$V
	lcall	x2816_cfg_according_params		; 27a5   12 28 16   .(.
	lcall	X2561_all_fet_off		; 27a8   12 25 61   .%a
	mov		XBR1,#41h	; 27ab   75 e2 41   ubA			; CEX0 routed to port pin
;	mov		P0SKIP,#0cfh	; 27ae   75 d4 cf   uTO
	mov		P1SKIP,#0fdh	; 27b1   75 d5 fd   uU}			; p1.1 cn
	mov		OSCICN,#0c3h	; 27b4   75 b2 c3   u2C
	clr		rcp_t0_ready		; 27b7   c2 00      B.
X27b9:
;	mov		a,31h		; 27b9   e5 31      e1
;	cjne	a,#0a5h,X27d0	; 27bb   b4 a5 12   4%.
;	mov		a,32h		; 27be   e5 32      e2
;	cjne	a,#0,X27d0	; 27c0   b4 00 0d   4..
;	mov		a,33h		; 27c3   e5 33      e3
;	cjne	a,#0ffh,X27d0	; 27c5   b4 ff 08   4..
;	mov		a,34h		; 27c8   e5 34      e4
;	cjne	a,#5ah,X27d0	; 27ca   b4 5a 03   4Z.
;	ljmp	X022d		; 27cd   02 02 2d   ..-
;
;X27d0:
;	jb		skip_check_btn,X27df	; 27d0   20 2c 0c    ,.
;	jb		p2.0,X27df	; 27d3   20 a0 09     .
;	lcall	x1d63_set_default_rcp_range		; 27d6   12 1d 63   ..c
;	jnb		skip_check_btn,X27df	; 27d9   30 2c 03   0,.
;	ljmp	X1c38		; 27dc   02 1c 38   ..8
;
X27df:
	jnb		rcp_t0_ready,X27b9	; 27df   30 00 d7   0.W
	lcall	x2528_check_ready_rcp		; 27e2   12 25 28   .%(
	jnb		stay_idle,X27eb	; 27e5   30 01 03   0..
	ljmp	x25a3_control_start		; 27e8   02 25 a3   .%#
;
X27eb:
	jnb		hi_pwm,X27b9	; 27eb   30 12 cb   0.K
	jb		first_state,X27f4	; 27ee   20 10 03    ..
	ljmp	x25a3_control_start		; 27f1   02 25 a3   .%#
;
X27f4:
	setb	forwarding		; 27f4   d2 03      R.
	lcall	X2561_all_fet_off		; 27f6   12 25 61   .%a
	mov		XBR1,#41h	; 27f9   75 e2 41   ubA		; only CEX0 routed to port pin
;	mov		P0SKIP,#0cfh	; 27fc   75 d4 cf   uTO
	mov		P1SKIP,#0fdh	; 27ff   75 d5 fd   uU}
	lcall	X2561_all_fet_off		; 2802   12 25 61   .%a
	ljmp	x2912_to_run		; 2805   02 29 12   .).
;
x2808_t2_reset:
	mov		a,#0		; 2808   74 00      t.
	mov		TMR2RLL,a	; 280a   f5 ca      uJ
	mov		TMR2RLH,a	; 280c   f5 cb      uK
	mov		TMR2L,a		; 280e   f5 cc      uL
	mov		TMR2H,a		; 2810   f5 cd      uM
	mov		TMR2CN,#4	; 2812   75 c8 04   uH.
	ret			; 2815   22         "
; init global variables/flags
x2816_cfg_according_params:
	mov		a,#0		; 2816   74 00      t.
	mov		startup_count,a		; 2818   f5 4f      uO
	mov		r5,a		; 281a   fd         }
	mov		4eh,a		; 281b   f5 4e      uN
	mov		r3,a		; 281d   fb         {
	mov		motor_status,a		; 281e   f5 59      uY
	mov		5ah,a		; 2820   f5 5a      uZ
	mov		state_timeout,a		; 2822   f5 44      uD
	mov		4ah,a		; 2824   f5 4a      uJ
	mov		49h,a		; 2826   f5 49      uI
	mov		run_braking_cnt,a		; 2828   f5 53      uS
	mov		52h,a		; 282a   f5 52      uR
	mov		46h,a		; 282c   f5 46      uF
	mov		t3count_x,a		; 282e   f5 48      uH
	mov		t3count_h,a		; 2830   f5 47      uG
	lcall	x2121_t3_reset		; 2832   12 21 21   .!!
	mov		5eh,#0		; 2835   75 5e 00   u^.
	clr		stay_idle		; 2838   c2 01      B.
	clr		rcp_t0_ready		; 283a   c2 00      B.
	clr		forwarding		; 283c   c2 03      B.
	clr		23h.4		; 283e   c2 1c      B.
	clr		23h.3		; 2840   c2 1b      B.
	clr		sysvol_even		; 2842   c2 19      B.
	clr		rcp_x_8		; 2844   c2 39      B9
	clr		hi_pwm		; 2846   c2 12      B.
	mov		accelate_factor,#30h	; 2848   75 2e 30   u.0
;	clr		21h.6		; 284b   c2 0e      B.
;	mov		a,60h		; 284d   e5 60      e`
;	jz		X2853		; 284f   60 02      `.
	setb	21h.6		; 2851   d2 0e      R.
;X2853:
;	mov		a,66h		; 2853   e5 66      ef
;	jnz		X28a4		; 2855   70 4d      pM
;	mov		a,61h		; 2857   e5 61      ea
;	cjne	a,#8,X2892	; 2859   b4 08 36   4.6
;	mov		dptr,#X3810	; 285c   90 38 10   .8.
;	clr		a			; 285f   e4         d
;	movc	a,@a+dptr	; 2860   93         .
;	jz		X286b		; 2861   60 08      `.
;	cjne	a,#1,X2870	; 2863   b4 01 0a   4..
;	mov		dptr,#X3880	; 2866   90 38 80   .8.
;	sjmp	X2875		; 2869   80 0a      ..
;X286b:
;	mov		dptr,#X3840	; 286b   90 38 40   .8@
;	sjmp	X2875		; 286e   80 05      ..
;X2870:
;	mov		dptr,#X38c0	; 2870   90 38 c0   .8@
;	sjmp	X2875		; 2873   80 00      ..
;X2875:
;	mov		a,#3		; 2875   74 03      t.
;	movc	a,@a+dptr	; 2877   93         .
;	mov		3dh,a		; 2878   f5 3d      u=
;	mov		3ch,#10h	; 287a   75 3c 10   u<.
;	mov		37h,#0		; 287d   75 37 00   u7.
;X2880:
;	mov		dptr,#X28de	; 2880   90 28 de   .(^
;	mov		a,37h		; 2883   e5 37      e7
;	movc	a,@a+dptr	; 2885   93         .
;	clr		c		; 2886   c3         C
;	subb	a,3dh		; 2887   95 3d      .=
;	jnc		X28b4		; 2889   50 29      P)
;	inc	37h		; 288b   05 37      .7
;	djnz	3ch,X2880	; 288d   d5 3c f0   U<p
;	sjmp	X28b4		; 2890   80 22      ."
;X2892:
	mov		dptr,#X28d6	; 2892   90 28 d6   .(V
	mov		a,61h		; 2895   e5 61      ea
	movc	a,@a+dptr	; 2897   93         .
	mov		3ch,a		; 2898   f5 3c      u<
	mov		dptr,#X28f2	; 289a   90 28 f2   .(r
	mov		a,61h		; 289d   e5 61      ea
	movc	a,@a+dptr	; 289f   93         .
	mov		3dh,a		; 28a0   f5 3d      u=
;	sjmp	X28b4		; 28a2   80 10      ..
;X28a4:	mov	dptr,#X28d3	; 28a4   90 28 d3   .(S
;	dec	a		; 28a7   14         .
;	movc	a,@a+dptr	; 28a8   93         .
;	mov	3ch,a		; 28a9   f5 3c      u<
;	mov	dptr,#X28ef	; 28ab   90 28 ef   .(o
;	mov	a,66h		; 28ae   e5 66      ef
;	dec	a		; 28b0   14         .
;	movc	a,@a+dptr	; 28b1   93         .
;	mov	3dh,a		; 28b2   f5 3d      u=
;X28b4:
	mov	dptr,#X28fa	; 28b4   90 28 fa   .(z
	mov	a,67h		; 28b7   e5 67      eg
	movc	a,@a+dptr	; 28b9   93         .
	mov	3eh,a		; 28ba   f5 3e      u>
	mov	a,67h		; 28bc   e5 67      eg
	add	a,#3		; 28be   24 03      $.
	movc	a,@a+dptr	; 28c0   93         .
	mov	dead_rcp_zone,a		; 28c1   f5 3f      u?
	mov	dptr,#X2900	; 28c3   90 29 00   .).
	mov	a,63h		; 28c6   e5 63      ec
	movc	a,@a+dptr	; 28c8   93         .
	mov	54h,a		; 28c9   f5 54      uT
	mov	a,63h		; 28cb   e5 63      ec
	add	a,#9		; 28cd   24 09      $.
	movc	a,@a+dptr	; 28cf   93         .
	mov	55h,a		; 28d0   f5 55      uU
	ret			; 28d2   22         "
;
X28d3:
db 10h,0dh,0bh
;	org	28d6h
;
X28d6:
db 10h,0fh,0eh,0ch,0ah,07h,03h,01h
X28de:
db 0,10h
db 20h,30h,40h,50h,60h,70h,80h,90h,0a0h,0b0h,0c0h,0d0h,0e0h,0f0h,0ffh		; 0@P`p.........

X28ef:
	db 0,33h,66h

;	org	28f2h
;
X28f2:
	db	0,0dh,19h,40h,66h,99h,0cch,0ffh
X28fa:
	db	0fh,19h,23h,0ch,16h,20h

X2900:	rr	a		; 2900   03         .
	inc	a		; 2901   04         .
	inc	rb0r6		; 2902   05 06      ..
	inc	r0		; 2904   08         .
	inc	r3		; 2905   0b         .
	inc	r7		; 2906   0f         .
	dec	rb3r6		; 2907   15 1e      ..
	inc	@r0		; 2909   06         .
	inc	r0		; 290a   08         .
	inc	r2		; 290b   0a         .
	inc	r7		; 290c   0f         .
	dec	a		; 290d   14         .
	dec	r6		; 290e   1e         .
	add	a,r0		; 290f   28         (
	reti			; 2910   32         2
;
	addc	a,r4		; 2911   3c         <
x2912_to_run:
	mov		ADC0GTH,#0		; 2912   75 c4 00   uD.
	mov		ADC0GTL,#80h	; 2915   75 c3 80   uC.
	mov		ADC0LTH,#0ffh	; 2918   75 c6 ff   uF.
	mov		ADC0LTL,#80h	; 291b   75 c5 80   uE.
	lcall	x2808_t2_reset		; 291e   12 28 08   .(.
	mov		56h,#0		; 2921   75 56 00   uV.
X2924:
	mov		a,56h		; 2924   e5 56      eV
	mov		dptr,#X292a	; 2926   90 29 2a   .)*
	jmp		@a+dptr		; 2929   73         s
;
X292a:
	sjmp	x2930_b		; 292a   80 04      ..
	sjmp	X2938_c		; 292c   80 0a      ..
	sjmp	X2940_a		; 292e   80 10      ..
x2930_b:
	lcall	x2cd9_feedback_b		; 2930   12 2c d9   .,Y
	mov		56h,#2		; 2933   75 56 02   uV.
	sjmp	X2948		; 2936   80 10      ..
;
X2938_c:
	lcall	x2cde_feedback_c		; 2938   12 2c de   .,^
	mov		56h,#4		; 293b   75 56 04   uV.
	sjmp	X2948		; 293e   80 08      ..
;
X2940_a:
	lcall	x2ce3_feedback_a		; 2940   12 2c e3   .,c
	mov		56h,#6		; 2943   75 56 06   uV.
;	sjmp	X2948		; 2946   80 00      ..
X2948:	mov	r0,#4		; 2948   78 04      x.
X294a:	mov	a,TMR2H		; 294a   e5 cd      eM
	subb	a,#0ffh		; 294c   94 ff      ..
	jnc	X2998		; 294e   50 48      PH
	jb	TMR2CN.7,X2998	; 2950   20 cf 45    OE
	lcall	x2df9_zero_cross_x0		; 2953   12 2d f9   .-y
	jb	zc_point,X295d	; 2956   20 09 04    ..
	djnz	r0,X294a	; 2959   d8 ef      Xo
	sjmp	X2980		; 295b   80 23      .#
;
X295d:	mov	r0,#4		; 295d   78 04      x.
X295f:	jb	TMR2CN.7,X2998	; 295f   20 cf 36    O6
	lcall	x2df9_zero_cross_x0		; 2962   12 2d f9   .-y
	jnb	zc_point,X2948	; 2965   30 09 e0   0.`
	djnz	r0,X295f	; 2968   d8 f5      Xu
	lcall	x2808_t2_reset		; 296a   12 28 08   .(.
X296d:	mov	r0,#3		; 296d   78 03      x.
X296f:	mov	a,TMR2H		; 296f   e5 cd      eM
	subb	a,#0ffh		; 2971   94 ff      ..
	jnc	X2998		; 2973   50 23      P#
	jb	TMR2CN.7,X2998	; 2975   20 cf 20    O 
	lcall	x2df9_zero_cross_x0		; 2978   12 2d f9   .-y
	jb	zc_point,X296d	; 297b   20 09 ef    .o
	djnz	r0,X296f	; 297e   d8 ef      Xo
X2980:
	lcall	x2808_t2_reset		; 2980   12 28 08   .(.
X2983:
	mov		r0,#3		; 2983   78 03      x.
X2985:
	mov		a,TMR2H		; 2985   e5 cd      eM
	subb	a,#0ffh		; 2987   94 ff      ..
	jnc		X2998		; 2989   50 0d      P.
	jb		TMR2CN.7,X2998	; 298b   20 cf 0a    O.
	lcall	x2df9_zero_cross_x0		; 298e   12 2d f9   .-y
	jnb		zc_point,X2983	; 2991   30 09 ef   0.o
	djnz	r0,X2985	; 2994   d8 ef      Xo
	sjmp	X29a7		; 2996   80 0f      ..
; 马达无惯性从停止开始
X2998:
	; GT =1
	mov	ADC0GTH,#0		; 2998   75 c4 00   uD.
	mov	ADC0GTL,#40h	; 299b   75 c3 40   uC@
	; LT =-1
	mov	ADC0LTH,#0ffh	; 299e   75 c6 ff   uF.
	mov	ADC0LTL,#0c0h	; 29a1   75 c5 c0   uE@
	ljmp	X2adf		; 29a4   02 2a df   .*_
; 初步判断马达正在惯性转动，计算换相时间以后进入马达转动状态

X29a7:	lcall	x2808_t2_reset		; 29a7   12 28 08   .(.
X29aa:	mov	r0,#3		; 29aa   78 03      x.
X29ac:	mov	a,TMR2H		; 29ac   e5 cd      eM
	subb	a,#0ffh		; 29ae   94 ff      ..
	jnc	X2998		; 29b0   50 e6      Pf
	jb	TMR2CN.7,X2998	; 29b2   20 cf e3    Oc
	lcall	x2df9_zero_cross_x0		; 29b5   12 2d f9   .-y
	jb	zc_point,X29aa	; 29b8   20 09 ef    .o
	djnz	r0,X29ac	; 29bb   d8 ef      Xo
	mov	r4,TMR2L		; 29bd   ac cc      ,L
	mov	r3,TMR2H		; 29bf   ab cd      +M
	lcall	x2808_t2_reset		; 29c1   12 28 08   .(.
X29c4:	mov	r0,#3		; 29c4   78 03      x.
X29c6:	mov	a,TMR2H		; 29c6   e5 cd      eM
	subb	a,#0ffh		; 29c8   94 ff      ..
	jnc	X2998		; 29ca   50 cc      PL
	jb	TMR2CN.7,X2998	; 29cc   20 cf c9    OI
	lcall	x2df9_zero_cross_x0		; 29cf   12 2d f9   .-y
	jnb	zc_point,X29c4	; 29d2   30 09 ef   0.o
	djnz	r0,X29c6	; 29d5   d8 ef      Xo

	

	mov	r6,TMR2L		; 29d7   ae cc      .L
	mov	r5,TMR2H		; 29d9   ad cd      -M
	mov	a,r5		; 29db   ed         m
	mov	r0,a		; 29dc   f8         x
	mov	a,r6		; 29dd   ee         n
	clr	c		; 29de   c3         C
	add	a,r6		; 29df   2e         .
	mov	r1,a		; 29e0   f9         y
	mov	a,r0		; 29e1   e8         h
	addc	a,r5		; 29e2   3d         =
	mov	r0,a		; 29e3   f8         x
	clr	c		; 29e4   c3         C
	subb	a,r3		; 29e5   9b         .
	jc	X2998		; 29e6   40 b0      @0
	jnz	X29ee		; 29e8   70 04      p.
	mov	a,r1		; 29ea   e9         i
	subb	a,r4		; 29eb   9c         .
	jc	X2998		; 29ec   40 aa      @*
X29ee:	mov	a,r3		; 29ee   eb         k
	mov	r0,a		; 29ef   f8         x
	mov	a,r4		; 29f0   ec         l
	clr	c		; 29f1   c3         C
	add	a,r4		; 29f2   2c         ,
	mov	r1,a		; 29f3   f9         y
	mov	a,r0		; 29f4   e8         h
	addc	a,r3		; 29f5   3b         ;
	mov	r0,a		; 29f6   f8         x
	clr	c		; 29f7   c3         C
	subb	a,r5		; 29f8   9d         .
	jc	X2998		; 29f9   40 9d      @.
	jnz	X2a01		; 29fb   70 04      p.
	mov	a,r1		; 29fd   e9         i
	subb	a,r6		; 29fe   9e         .
	jc	X2998		; 29ff   40 97      @.
X2a01:	mov	a,56h		; 2a01   e5 56      eV
	cjne	a,#6,X2a08	; 2a03   b4 06 02   4..
	sjmp	X2a0b		; 2a06   80 03      ..
;
X2a08:	ljmp	X2924		; 2a08   02 29 24   .)$
;
X2a0b:	clr	c		; 2a0b   c3         C
	mov	a,r4		; 2a0c   ec         l
	add	a,r6		; 2a0d   2e         .
	mov	r0,a		; 2a0e   f8         x
	mov	a,r3		; 2a0f   eb         k
	addc	a,r5		; 2a10   3d         =
	rrc	a		; 2a11   13         .
	mov	r5,a		; 2a12   fd         }
	mov	a,r0		; 2a13   e8         h
	rrc	a		; 2a14   13         .
	mov	r6,a		; 2a15   fe         ~
	mov	r1,#3		; 2a16   79 03      y.
X2a18:	clr	c		; 2a18   c3         C
	mov	a,r5		; 2a19   ed         m
	rrc	a		; 2a1a   13         .
	mov	r5,a		; 2a1b   fd         }
	mov	a,r6		; 2a1c   ee         n
	rrc	a		; 2a1d   13         .
	mov	r6,a		; 2a1e   fe         ~
	djnz	r1,X2a18	; 2a1f   d9 f7      Yw
	clr	c		; 2a21   c3         C
	mov	a,r5		; 2a22   ed         m
	rrc	a		; 2a23   13         .
	mov	r0,a		; 2a24   f8         x
	mov	a,r6		; 2a25   ee         n
	rrc	a		; 2a26   13         .
	mov	r1,a		; 2a27   f9         y
	mov	a,r6		; 2a28   ee         n
	add	a,r1		; 2a29   29         )
	mov	r6,a		; 2a2a   fe         ~
	mov	a,r5		; 2a2b   ed         m
	addc	a,r0		; 2a2c   38         8
	mov	r5,a		; 2a2d   fd         }
	mov	a,r5		; 2a2e   ed         m
	mov	r3,a		; 2a2f   fb         {
	mov	4eh,a		; 2a30   f5 4e      uN
	mov	a,r6		; 2a32   ee         n
	mov	r4,a		; 2a33   fc         |
	mov	4dh,a		; 2a34   f5 4d      uM
	clr	c		; 2a36   c3         C
	mov	a,r5		; 2a37   ed         m
	rrc	a		; 2a38   13         .
	mov	r0,a		; 2a39   f8         x
	mov	a,r6		; 2a3a   ee         n
	rrc	a		; 2a3b   13         .
	mov	r1,a		; 2a3c   f9         y
	lcall	x2808_t2_reset		; 2a3d   12 28 08   .(.
X2a40:	mov	a,TMR2H		; 2a40   e5 cd      eM
	clr	c		; 2a42   c3         C
	subb	a,r0		; 2a43   98         .
	jc	X2a40		; 2a44   40 fa      @z
X2a46:	mov	a,TMR2L		; 2a46   e5 cc      eL
	clr	c		; 2a48   c3         C
	subb	a,r1		; 2a49   99         .
	jc	X2a46		; 2a4a   40 fa      @z
	mov	r2,#40h		; 2a4c   7a 40      z@
	lcall	x24e9_set_pwm0_duty		; 2a4e   12 24 e9   .$i
	mov	state_index,#0ch	; 2a51   75 29 0c   u).
	mov	a,r5		; 2a54   ed         m
	subb	a,#9		; 2a55   94 09      ..
	jnc	X2a73		; 2a57   50 1a      P.
	mov	a,r5		; 2a59   ed         m
	jz	X2a6b		; 2a5a   60 0f      `.
X2a5c:	lcall	x2808_t2_reset		; 2a5c   12 28 08   .(.
	mov	4ah,#0		; 2a5f   75 4a 00   uJ.
	mov	49h,#0		; 2a62   75 49 00   uI.
	mov	accelate_factor,#60h	; 2a65   75 2e 60   u.`
	ljmp	X2a7b		; 2a68   02 2a 7b   .*{
;
X2a6b:	mov	a,r6		; 2a6b   ee         n
	subb	a,#14h		; 2a6c   94 14      ..
	jnc	X2a5c		; 2a6e   50 ec      Pl
	ljmp	X2998		; 2a70   02 29 98   .).
;
X2a73:	mov	a,r5		; 2a73   ed         m
	subb	a,#1eh		; 2a74   94 1e      ..
	jc	X2a7b		; 2a76   40 03      @.
	ljmp	X2998		; 2a78   02 29 98   .).
;
X2a7b:	mov	ADC0GTH,#0		; 2a7b   75 c4 00   uD.
	mov	ADC0GTL,#40h	; 2a7e   75 c3 40   uC@
	mov	ADC0LTH,#0ffh	; 2a81   75 c6 ff   uF.
	mov	ADC0LTL,#0c0h	; 2a84   75 c5 c0   uE@
	mov	accelate_factor,#60h	; 2a87   75 2e 60   u.`
	mov	startup_count,#40h	; 2a8a   75 4f 40   uO@
	
	ljmp	X2ae5		; 2a8d   02 2a e5   .*e
; 读取T3的高位，并加到 t3count_x:t3_count_h, 4ah:49h,然后重置T3
; 48h用于计算关机电压，温度过高的持续时间
x2a90_t3_sum:	mov	b,TMR3H		; 2a90   85 95 f0   ..p
	mov	TMR3H,#0		; 2a93   75 95 00   u..
	clr	c		; 2a96   c3         C
	mov	a,b		; 2a97   e5 f0      ep
	add	a,t3count_h		; 2a99   25 47      %G
	mov	t3count_h,a		; 2a9b   f5 47      uG
	jnc	X2aa1		; 2a9d   50 02      P.
	inc	t3count_x		; 2a9f   05 48      .H
X2aa1:	mov	a,b		; 2aa1   e5 f0      ep
	clr	c		; 2aa3   c3         C
	add	a,49h		; 2aa4   25 49      %I
	mov	49h,a		; 2aa6   f5 49      uI
	jnc	X2aac		; 2aa8   50 02      P.
	inc	4ah		; 2aaa   05 4a      .J
X2aac:	mov	a,temper_fail_time		; 2aac   e5 43      eC
	add	a,t3count_x		; 2aae   25 48      %H
	mov	temper_fail_time,a		; 2ab0   f5 43      uC
	mov	a,45h		; 2ab2   e5 45      eE
	add	a,t3count_x		; 2ab4   25 48      %H
	mov	45h,a		; 2ab6   f5 45      uE
	mov	a,state_timeout		; 2ab8   e5 44      eD
	add	a,t3count_x		; 2aba   25 48      %H
	mov	state_timeout,a		; 2abc   f5 44      uD
	mov	a,46h		; 2abe   e5 46      eF
	add	a,t3count_x		; 2ac0   25 48      %H
	mov	46h,a		; 2ac2   f5 46      uF
	mov	t3count_x,#0		; 2ac4   75 48 00   uH.
	clr	c		; 2ac7   c3         C
	mov	a,TMR3CN		; 2ac8   e5 91      e.
	subb	a,#80h		; 2aca   94 80      ..
	jc	X2ade		; 2acc   40 10      @.
	mov	a,TMR3CN		; 2ace   e5 91      e.
	anl	a,#7fh		; 2ad0   54 7f      T.
	mov	TMR3CN,a		; 2ad2   f5 91      u.
	inc	temper_fail_time		; 2ad4   05 43      .C
	inc	45h		; 2ad6   05 45      .E
	inc	state_timeout		; 2ad8   05 44      .D
	inc	4ah		; 2ada   05 4a      .J
	inc	46h		; 2adc   05 46      .F
X2ade:	ret			; 2ade   22         "
; STARTING MOTOR
X2adf:
; startup_count 中初始值为0
	mov		state_index,#0		; 2adf   75 29 00   u).
	lcall	x24d6_pca0cp0_set_5		; 2ae2   12 24 d6   .$V
X2ae5:
; startup_count 中初始值为40h
	mov		4ah,#0		; 2ae5   75 4a 00   uJ.
	mov		49h,#0		; 2ae8   75 49 00   uI.
	lcall	x2121_t3_reset		; 2aeb   12 21 21   .!!
	mov		5fh,#0feh	; 2aee   75 5f fe   u_~
X2af1:
	mov		a,5fh		; 2af1   e5 5f      e_
	clr		c		; 2af3   c3         C
	subb	a,#40h		; 2af4   94 40      .@
	jnc		X2afc		; 2af6   50 04      P.
X2af8:
	mov	a,#80h		; 2af8   74 80      t.
	sjmp	X2b03		; 2afa   80 07      ..
;
X2afc:	mov	a,5fh		; 2afc   e5 5f      e_
	clr	c		; 2afe   c3         C
	subb	a,#10h		; 2aff   94 10      ..
	jc	X2af8		; 2b01   40 f5      @u
X2b03:	mov	5fh,a		; 2b03   f5 5f      u_
	clr	c		; 2b05   c3         C
	mov	a,startup_count		; 2b06   e5 4f      eO
	subb	a,#80h		; 2b08   94 80      ..
	jc	X2b0f		; 2b0a   40 03      @.
	ljmp	x3273_state_start		; 2b0c   02 32 73   .2s
;
X2b0f:
;	ljmp	break_point
	lcall	x306a_sw_state		; 2b0f   12 30 6a   .0j
	lcall	x2808_t2_reset		; 2b12   12 28 08   .(.
	clr	c		; 2b15   c3         C
	; r1:r0=(r5:r6 + 4eh:4dh)/2
	; r3,r5,4eh 最初在x2816_cfg_according_params中被设置为0,
	mov	a,r6		; 2b16   ee         n
	add	a,4dh		; 2b17   25 4d      %M
	mov	r0,a		; 2b19   f8         x
	mov	a,r5		; 2b1a   ed         m
	addc	a,4eh		; 2b1b   35 4e      5N
	rrc	a		; 2b1d   13         .
	mov	r1,a		; 2b1e   f9         y
	mov	a,r0		; 2b1f   e8         h
	rrc	a		; 2b20   13         .
	mov	r0,a		; 2b21   f8         x
	; r1:r0 = r1:r0/2
	clr	c		; 2b22   c3         C
	mov	a,r1		; 2b23   e9         i
	rrc	a		; 2b24   13         .
	mov	r1,a		; 2b25   f9         y
	mov	a,r0		; 2b26   e8         h
	rrc	a		; 2b27   13         .
	mov	r0,a		; 2b28   f8         x
	jb	temper1volt0,X2b39	; 2b29   20 1f 0d    ..
	setb	temper1volt0		; 2b2c   d2 1f      R.
	lcall	x2d74_exam_volt		; 2b2e   12 2d 74   .-t
	jnb	stay_idle,X2b44	; 2b31   30 01 10   0..
	ljmp	X2ddc		; 2b34   02 2d dc   .-\
;
	sjmp	X2b44		; 2b37   80 0b      ..
;
X2b39:
	clr		temper1volt0		; 2b39   c2 1f      B.
	lcall	x2cf0_fetch_temper		; 2b3b   12 2c f0   .,p
	jnb		stay_idle,X2b44	; 2b3e   30 01 03   0..
	ljmp	X2d38		; 2b41   02 2d 38   .-8
;
X2b44:
	mov		a,state_timeout		; 2b44   e5 44      eD
	clr		c		; 2b46   c3         C
	subb	a,#0ah		; 2b47   94 0a      ..
	jc		X2b51		; 2b49   40 06      @.
; 在从启动就急加速度时候有可能会跳到这里。
	ljmp	break_point
	lcall	x2816_cfg_according_params		; 2b4b   12 28 16   .(.
	ljmp	x25a3_control_start		; 2b4e   02 25 a3   .%#
;
X2b51:
	lcall	x2a90_t3_sum		; 2b51   12 2a 90   .*.
X2b54:
	mov		a,TMR2H		; 2b54   e5 cd      eM
	clr		c		; 2b56   c3         C
	subb	a,r1		; 2b57   99         .
	jc		X2b54		; 2b58   40 fa      @z
X2b5a:
	mov		a,TMR2L		; 2b5a   e5 cc      eL
	clr		c		; 2b5c   c3         C
	subb	a,r0		; 2b5d   98         .
	jc		X2b5a		; 2b5e   40 fa      @z
	lcall	X252f		; 2b60   12 25 2f   .%/
	mov		a,state_index		; 2b63   e5 29      e)
	mov		dptr,#X2b69	; 2b65   90 2b 69   .+i
	jmp		@a+dptr		; 2b68   73         s
;
X2b69:
	ljmp	X2b7b		; 2b69   02 2b 7b   .+{
	ljmp	X2bb4		; 2b6c   02 2b b4   .+4
	ljmp	X2beb		; 2b6f   02 2b eb   .+k
	ljmp	X2c2b		; 2b72   02 2c 2b   .,+
	ljmp	X2c62		; 2b75   02 2c 62   .,b
	ljmp	X2c99		; 2b78   02 2c 99   .,.
X2b7b:
	clr		27h.4		; 2b7b   c2 3c      B<
	lcall	x2ce3_feedback_a		; 2b7d   12 2c e3   .,c
	jb		fet_cn,X2b9e	; 2b80   20 91 1b    ..
X2b83:
	mov		a,TMR2H		; 2b83   e5 cd      eM
	clr		c		; 2b85   c3         C
	subb	a,5fh		; 2b86   95 5f      ._
	jnc		X2b8d		; 2b88   50 03      P.
	jnb		TMR2CN.7,X2b90	; 2b8a   30 cf 03   0O.
X2b8d:
	ljmp	X3043		; 2b8d   02 30 43   .0C
;
X2b90:
	lcall	x2528_check_ready_rcp		; 2b90   12 25 28   .%(
	jnb		stay_idle,X2b99	; 2b93   30 01 03   0..
	ljmp	x25a3_control_start		; 2b96   02 25 a3   .%#
;
X2b99:
	jb	fet_cn,X2b9e	; 2b99   20 91 02    ..
	sjmp	X2b99		; 2b9c   80 fb      .{
;
X2b9e:	lcall	X3213		; 2b9e   12 32 13   .2.
X2ba1:	mov	r0,#3		; 2ba1   78 03      x.
X2ba3:	jnb	fet_cn,X2b83	; 2ba3   30 91 dd   0.]
	lcall	x2e34_zero_cross_i0		; 2ba6   12 2e 34   ..4
	jb	zc_point,X2ba1	; 2ba9   20 09 f5    .u
	djnz	r0,X2ba3	; 2bac   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2bae   12 2f e5   ./e
	ljmp	X3019		; 2bb1   02 30 19   .0.
;
X2bb4:	lcall	x2cde_feedback_c		; 2bb4   12 2c de   .,^
	jb	fet_an,X2bd5	; 2bb7   20 95 1b    ..
X2bba:	mov	a,TMR2H		; 2bba   e5 cd      eM
	clr	c		; 2bbc   c3         C
	subb	a,5fh		; 2bbd   95 5f      ._
	jnc	X2bc4		; 2bbf   50 03      P.
	jnb	TMR2CN.7,X2bc7	; 2bc1   30 cf 03   0O.
X2bc4:	ljmp	X3043		; 2bc4   02 30 43   .0C
;
X2bc7:	lcall	x2528_check_ready_rcp		; 2bc7   12 25 28   .%(
	jnb	stay_idle,X2bd0	; 2bca   30 01 03   0..
	ljmp	x25a3_control_start		; 2bcd   02 25 a3   .%#
;
X2bd0:	jb	fet_an,X2bd5	; 2bd0   20 95 02    ..
	sjmp	X2bd0		; 2bd3   80 fb      .{
;
X2bd5:	lcall	X3213		; 2bd5   12 32 13   .2.
X2bd8:	mov	r0,#3		; 2bd8   78 03      x.
X2bda:	jnb	fet_an,X2bba	; 2bda   30 95 dd   0.]
	lcall	x2df9_zero_cross_x0		; 2bdd   12 2d f9   .-y
	jnb	zc_point,X2bd8	; 2be0   30 09 f5   0.u
	djnz	r0,X2bda	; 2be3   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2be5   12 2f e5   ./e
	ljmp	X3019		; 2be8   02 30 19   .0.
;
X2beb:	jb	27h.4,X2bf4	; 2beb   20 3c 06    <.
	mov	a,5eh		; 2bee   e5 5e      e^
	jz	X2bf4		; 2bf0   60 02      `.
	dec	5eh		; 2bf2   15 5e      .^
X2bf4:	lcall	x2cd9_feedback_b		; 2bf4   12 2c d9   .,Y
	jb	fet_an,X2c15	; 2bf7   20 95 1b    ..
X2bfa:	mov	a,TMR2H		; 2bfa   e5 cd      eM
	clr	c		; 2bfc   c3         C
	subb	a,5fh		; 2bfd   95 5f      ._
	jnc	X2c04		; 2bff   50 03      P.
	jnb	TMR2CN.7,X2c07	; 2c01   30 cf 03   0O.
X2c04:	ljmp	X3043		; 2c04   02 30 43   .0C
;
X2c07:	lcall	x2528_check_ready_rcp		; 2c07   12 25 28   .%(
	jnb	stay_idle,X2c10	; 2c0a   30 01 03   0..
	ljmp	x25a3_control_start		; 2c0d   02 25 a3   .%#
;
X2c10:	jb	fet_an,X2c15	; 2c10   20 95 02    ..
	sjmp	X2c10		; 2c13   80 fb      .{
;
X2c15:	lcall	X3213		; 2c15   12 32 13   .2.
X2c18:	mov	r0,#3		; 2c18   78 03      x.
X2c1a:	jnb	fet_an,X2bfa	; 2c1a   30 95 dd   0.]
	lcall	x2e34_zero_cross_i0		; 2c1d   12 2e 34   ..4
	jb	zc_point,X2c18	; 2c20   20 09 f5    .u
	djnz	r0,X2c1a	; 2c23   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2c25   12 2f e5   ./e
	ljmp	X3019		; 2c28   02 30 19   .0.
;
X2c2b:	lcall	x2ce3_feedback_a		; 2c2b   12 2c e3   .,c
	jb	fet_bn,X2c4c	; 2c2e   20 92 1b    ..
X2c31:	mov	a,TMR2H		; 2c31   e5 cd      eM
	clr	c		; 2c33   c3         C
	subb	a,5fh		; 2c34   95 5f      ._
	jnc	X2c3b		; 2c36   50 03      P.
	jnb	TMR2CN.7,X2c3e	; 2c38   30 cf 03   0O.
X2c3b:	ljmp	X3043		; 2c3b   02 30 43   .0C
;
X2c3e:	lcall	x2528_check_ready_rcp		; 2c3e   12 25 28   .%(
	jnb	stay_idle,X2c47	; 2c41   30 01 03   0..
	ljmp	x25a3_control_start		; 2c44   02 25 a3   .%#
;
X2c47:	jb	fet_bn,X2c4c	; 2c47   20 92 02    ..
	sjmp	X2c47		; 2c4a   80 fb      .{
;
X2c4c:	lcall	X3213		; 2c4c   12 32 13   .2.
X2c4f:	mov	r0,#3		; 2c4f   78 03      x.
X2c51:	jnb	fet_bn,X2c31	; 2c51   30 92 dd   0.]
	lcall	x2df9_zero_cross_x0		; 2c54   12 2d f9   .-y
	jnb	zc_point,X2c4f	; 2c57   30 09 f5   0.u
	djnz	r0,X2c51	; 2c5a   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2c5c   12 2f e5   ./e
	ljmp	X3019		; 2c5f   02 30 19   .0.
;
X2c62:	lcall	x2cde_feedback_c		; 2c62   12 2c de   .,^
	jb	fet_bn,X2c83	; 2c65   20 92 1b    ..
X2c68:	mov	a,TMR2H		; 2c68   e5 cd      eM
	clr	c		; 2c6a   c3         C
	subb	a,5fh		; 2c6b   95 5f      ._
	jnc	X2c72		; 2c6d   50 03      P.
	jnb	TMR2CN.7,X2c75	; 2c6f   30 cf 03   0O.
X2c72:	ljmp	X3043		; 2c72   02 30 43   .0C
;
X2c75:	lcall	x2528_check_ready_rcp		; 2c75   12 25 28   .%(
	jnb	stay_idle,X2c7e	; 2c78   30 01 03   0..
	ljmp	x25a3_control_start		; 2c7b   02 25 a3   .%#
;
X2c7e:	jb	fet_bn,X2c83	; 2c7e   20 92 02    ..
	sjmp	X2c7e		; 2c81   80 fb      .{
;
X2c83:	lcall	X3213		; 2c83   12 32 13   .2.
X2c86:	mov	r0,#3		; 2c86   78 03      x.
X2c88:	jnb	fet_bn,X2c68	; 2c88   30 92 dd   0.]
	lcall	x2e34_zero_cross_i0		; 2c8b   12 2e 34   ..4
	jb	zc_point,X2c86	; 2c8e   20 09 f5    .u
	djnz	r0,X2c88	; 2c91   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2c93   12 2f e5   ./e
	ljmp	X3019		; 2c96   02 30 19   .0.
;
X2c99:	jb	27h.4,X2ca2	; 2c99   20 3c 06    <.
	mov	a,5eh		; 2c9c   e5 5e      e^
	jz	X2ca2		; 2c9e   60 02      `.
	dec	5eh		; 2ca0   15 5e      .^
X2ca2:	lcall	x2cd9_feedback_b		; 2ca2   12 2c d9   .,Y
	jb	fet_cn,X2cc3	; 2ca5   20 91 1b    ..
X2ca8:	mov	a,TMR2H		; 2ca8   e5 cd      eM
	clr	c		; 2caa   c3         C
	subb	a,5fh		; 2cab   95 5f      ._
	jnc	X2cb2		; 2cad   50 03      P.
	jnb	TMR2CN.7,X2cb5	; 2caf   30 cf 03   0O.
X2cb2:	ljmp	X3043		; 2cb2   02 30 43   .0C
;
X2cb5:
	lcall	x2528_check_ready_rcp		; 2cb5   12 25 28   .%(
	jnb		stay_idle,X2cbe	; 2cb8   30 01 03   0..
	ljmp	x25a3_control_start		; 2cbb   02 25 a3   .%#
;
X2cbe:
	jb		fet_cn,X2cc3	; 2cbe   20 91 02    ..
	sjmp	X2cbe		; 2cc1   80 fb      .{
;
X2cc3:	lcall	X3213		; 2cc3   12 32 13   .2.
X2cc6:	mov	r0,#3		; 2cc6   78 03      x.
X2cc8:	jnb	fet_cn,X2ca8	; 2cc8   30 91 dd   0.]
	lcall	x2df9_zero_cross_x0		; 2ccb   12 2d f9   .-y
	jnb	zc_point,X2cc6	; 2cce   30 09 f5   0.u
	djnz	r0,X2cc8	; 2cd1   d8 f5      Xu
	lcall	x2fe5_calc_com		; 2cd3   12 2f e5   ./e
	ljmp	X3019		; 2cd6   02 30 19   .0.
;
x2cd9_feedback_b:
	mov		AMX0P,#7		; 2cd9   75 bb 07   u;.
	sjmp	X2ce6		; 2cdc   80 08      ..
;
x2cde_feedback_c:
	mov		AMX0P,#3		; 2cde   75 bb 03   u;.
	sjmp	X2ce6		; 2ce1   80 03      ..
;
x2ce3_feedback_a:	mov	AMX0P,#1		; 2ce3   75 bb 01   u;.
X2ce6:	mov	AMX0N,#2		; 2ce6   75 ba 02   u:.
	mov	ADC0CF,#3ch	; 2ce9   75 bc 3c   u<<
	mov	ADC0CN,#80h	; 2cec   75 e8 80   uh.
	ret			; 2cef   22         "
;
x2cf0_fetch_temper:	clr	stay_idle		; 2cf0   c2 01      B.
	mov	a,6ah		; 2cf2   e5 6a      ej
	jz	x2cf7		; 2cf4   60 01      `.
	ret			; 2cf6   22         "
;
x2cf7:
	; p0.0 as postive adc input
	mov		AMX0P,#0		; 2cf7   75 bb 00   u;.
	; GND as negetive adc input
	mov		AMX0N,#11h	; 2cfa   75 ba 11   u:.
	; AD0SC = 00111, left justify selected
	mov		ADC0CF,#00111100b	; 2cfd   75 bc 3c   u<<
	mov		ADC0CN,#80h	; 2d00   75 e8 80   uh.
	clr		AD0INT		; 2d03   c2 ed      Bm
	setb	AD0BUSY		; 2d05   d2 ec      Rl
	jnb		AD0INT,$	; 2d07   30 ed fd   0m}
	clr		AD0INT		; 2d0a   c2 ed      Bm
	setb	AD0BUSY		; 2d0c   d2 ec      Rl
	jnb		AD0INT,$	; 2d0e   30 ed fd   0m}
	jnb		temper_even,X2d32	; 2d11   30 1a 1e   0..
	mov		a,ADC0H		; 2d14   e5 be      e>
	clr		c		; 2d16   c3         C
	add		a,temp_temper		; 2d17   25 42      %B
	rrc		a		; 2d19   13         .
	mov		temper,a		; 2d1a   f5 41      uA
	clr		temper_even		; 2d1c   c2 1a      B.
	clr		c		; 2d1e   c3         C
	mov		a,temper		; 2d1f   e5 41      eA
	subb	a,#4fh		; 2d21   94 4f      .O
	jnc		X2d2e		; 2d23   50 09      P.
	mov		a,temper_fail_time		; 2d25   e5 43      eC
	subb	a,#64h		; 2d27   94 64      .d
	jc		X2d2d		; 2d29   40 02      @.
	setb	stay_idle		; 2d2b   d2 01      R.
X2d2d:
	ret			; 2d2d   22         "
;
X2d2e:
	mov		temper_fail_time,#0		; 2d2e   75 43 00   uC.
	ret		; 2d31   22         "
;
X2d32:
	mov		temp_temper,ADC0H	; 2d32   85 be 42   .>B
	setb	temper_even		; 2d35   d2 1a      R.
	ret			; 2d37   22         "
;
X2d38:
	lcall	X2561_all_fet_off		; 2d38   12 25 61   .%a
X2d3b:
	clr		red_led		; 2d3b   c2 94      B.
	setb	green_led		; 2d3d   d2 93      R.
	lcall	x31c5_longlong_delay		; 2d3f   12 31 c5   .1E
	clr		green_led		; 2d42   c2 93      B.
	lcall	X31bf		; 2d44   12 31 bf   .1?
	mov		AMX0P,#0		; 2d47   75 bb 00   u;.
	mov		AMX0N,#11h	; 2d4a   75 ba 11   u:.
	mov		ADC0CF,#3ch	; 2d4d   75 bc 3c   u<<
	mov		ADC0CN,#80h	; 2d50   75 e8 80   uh.
	clr		AD0INT		; 2d53   c2 ed      Bm
	setb	AD0BUSY		; 2d55   d2 ec      Rl
X2d57:
	jnb		AD0INT,X2d57	; 2d57   30 ed fd   0m}
	mov		temp_temper,ADC0H	; 2d5a   85 be 42   .>B
	clr		AD0INT		; 2d5d   c2 ed      Bm
	setb	AD0BUSY		; 2d5f   d2 ec      Rl
X2d61:
	jnb		AD0INT,X2d61	; 2d61   30 ed fd   0m}
	mov		a,ADC0H		; 2d64   e5 be      e>
	clr		c		; 2d66   c3         C
	add		a,temp_temper		; 2d67   25 42      %B
	rrc		a		; 2d69   13         .
	clr		c		; 2d6a   c3         C
	mov		temper,a		; 2d6b   f5 41      uA
	subb	a,#59h		; 2d6d   94 59      .Y
	jc		X2d3b		; 2d6f   40 ca      @J
	ljmp	X27a2		; 2d71   02 27 a2   .'"
;
x2d74_exam_volt:	clr	stay_idle		; 2d74   c2 01      B.
	jnb	adc_busy,X2d95	; 2d76   30 33 1c   03.
	clr	c		; 2d79   c3         C
	mov	a,accelate_factor		; 2d7a   e5 2e      e.
	subb	a,#92h		; 2d7c   94 92      ..
	jc	X2d8b		; 2d7e   40 0b      @.
	mov	a,45h		; 2d80   e5 45      eE
	jz	X2d94		; 2d82   60 10      `.
	dec	45h		; 2d84   15 45      .E
	dec	accelate_factor		; 2d86   15 2e      ..
	dec	accelate_factor		; 2d88   15 2e      ..
	ret			; 2d8a   22         "
;
X2d8b:	clr	c		; 2d8b   c3         C
	mov	a,45h		; 2d8c   e5 45      eE
;	subb	a,#0f8h		; 2d8e   94 f8      .x
	subb	a,#100
	jc	X2d94		; 2d90   40 02      @.
	setb	stay_idle		; 2d92   d2 01      R.
X2d94:	ret			; 2d94   22         "
;
X2d95:	mov	a,burden_volt		; 2d95   e5 40      e@
	jz	X2dd1		; 2d97   60 38      `8
	mov	AMX0P,#0fh	; 2d99   75 bb 0f   u;.
	mov	AMX0N,#11h	; 2d9c   75 ba 11   u:.
	mov	ADC0CF,#3ch	; 2d9f   75 bc 3c   u<<
	mov	ADC0CN,#80h	; 2da2   75 e8 80   uh.
	clr	AD0INT		; 2da5   c2 ed      Bm
	setb	AD0BUSY		; 2da7   d2 ec      Rl
X2da9:	jnb	AD0INT,X2da9	; 2da9   30 ed fd   0m}
	clr	AD0INT		; 2dac   c2 ed      Bm
	setb	AD0BUSY		; 2dae   d2 ec      Rl
X2db0:	jnb	AD0INT,X2db0	; 2db0   30 ed fd   0m}
	jnb	sysvol_even,X2dd6	; 2db3   30 19 20   0. 
	mov	a,ADC0H		; 2db6   e5 be      e>
	clr	c		; 2db8   c3         C
	add	a,51h		; 2db9   25 51      %Q
	rrc	a		; 2dbb   13         .
	mov	r7,a		; 2dbc   ff         .
	clr	sysvol_even		; 2dbd   c2 19      B.
	clr	c		; 2dbf   c3         C
	mov	a,r7		; 2dc0   ef         o
	subb	a,burden_volt		; 2dc1   95 40      .@
	jnc	X2dd2		; 2dc3   50 0d      P.
	mov	a,45h		; 2dc5   e5 45      eE
	clr	c		; 2dc7   c3         C
	subb	a,#3ch		; 2dc8   94 3c      .<
	jc	X2dd1		; 2dca   40 05      @.
	setb	adc_busy		; 2dcc   d2 33      R3
	mov	45h,#0		; 2dce   75 45 00   uE.
X2dd1:	ret			; 2dd1   22         "
;
X2dd2:	mov	45h,#0		; 2dd2   75 45 00   uE.
	ret			; 2dd5   22         "
;
X2dd6:	mov	51h,ADC0H	; 2dd6   85 be 51   .>Q
	setb	sysvol_even		; 2dd9   d2 19      R.
	ret			; 2ddb   22         "
;
X2ddc:
	lcall	X2561_all_fet_off		; 2ddc   12 25 61   .%a
X2ddf:
	clr		green_led		; 2ddf   c2 93      B.
	setb	red_led		; 2de1   d2 94      R.
	lcall	x31c5_longlong_delay		; 2de3   12 31 c5   .1E
	clr		red_led		; 2de6   c2 94      B.
	lcall	x31c2_longlonglong_delay		; 2de8   12 31 c2   .1B
	lcall	x2475_number_of_battery		; 2deb   12 24 75   .$u
	mov		a,r7		; 2dee   ef         o
	clr		c		; 2def   c3         C
	subb	a,power_fail_volt		; 2df0   95 36      .6
	jc		X2ddf		; 2df2   40 eb      @k
	clr		adc_busy		; 2df4   c2 33      B3

	ljmp	X27a2		; 2df6   02 27 a2   .'"
;
x2df9_zero_cross_x0:
	;jnb		exchange_dir,X2e2a	; 2df9   30 2d 2e   0-.
	jb		dir_reverse,X2e3a	; 2dfc   20 0a 3b    .;
X2dff:
	clr		AD0WINT		; 2dff   c2 eb      Bk
	clr		AD0INT		; 2e01   c2 ed      Bm
	setb	AD0BUSY		; 2e03   d2 ec      Rl
	clr		zc_point		; 2e05   c2 09      B.
	clr		fb_adc_timeout		; 2e07   c2 05      B.
X2e09:
	jb		TMR2CN.7,X2e65	; 2e09   20 cf 59    OY
	jnb		AD0INT,X2e09	; 2e0c   30 ed fa   0mz
	jnb		AD0WINT,X2e1b	; 2e0f   30 eb 09   0k.
	mov		a,ADC0H		; 2e12   e5 be      e>
	clr		c		; 2e14   c3         C
	subb	a,#80h		; 2e15   94 80      ..
	jc		X2e1b		; 2e17   40 02      @.
	setb	zc_point		; 2e19   d2 09      R.
X2e1b:
	jnb	dir_reverse,X2e24	; 2e1b   30 0a 06   0..
;	jnb	exchange_dir,X2e23	; 2e1e   30 2d 02   0-.
	cpl	zc_point		; 2e21   b2 09      2.
X2e23:	ret			; 2e23   22         "
;
X2e24:
;	jb	exchange_dir,X2e23	; 2e24   20 2d fc    -|
	sjmp	X2e23
;	cpl	zc_point		; 2e27   b2 09      2.
;	ret			; 2e29   22         "
;
;X2e2a:	jb	dir_reverse,X2dff	; 2e2a   20 0a d2    .R
;	sjmp	X2e3a		; 2e2d   80 0b      ..
;
;X2e2f:	jb	dir_reverse,X2e3a	; 2e2f   20 0a 08    ..
;	sjmp	X2dff		; 2e32   80 cb      .K
;
x2e34_zero_cross_i0:
;	jnb	exchange_dir,X2e2f	; 2e34   30 2d f8   0-x
	jb		dir_reverse,X2dff	; 2e37   20 0a c5    .E
X2e3a:
	clr		AD0WINT		; 2e3a   c2 eb      Bk
	clr		AD0INT		; 2e3c   c2 ed      Bm
	setb	AD0BUSY		; 2e3e   d2 ec      Rl
	setb	zc_point		; 2e40   d2 09      R.
	clr		fb_adc_timeout		; 2e42   c2 05      B.
X2e44:
	jb		TMR2CN.7,X2e65	; 2e44   20 cf 1e    O.
	jnb		AD0INT,X2e44	; 2e47   30 ed fa   0mz
	jnb		AD0WINT,X2e56	; 2e4a   30 eb 09   0k.
	mov		a,ADC0H		; 2e4d   e5 be      e>
	clr		c		; 2e4f   c3         C
	subb	a,#80h		; 2e50   94 80      ..
	jnc		X2e56		; 2e52   50 02      P.
	clr		zc_point		; 2e54   c2 09      B.
X2e56:
	jnb		dir_reverse,X2e5f	; 2e56   30 0a 06   0..
;	jnb	exchange_dir,X2e5e	; 2e59   30 2d 02   0-.
	cpl		zc_point		; 2e5c   b2 09      2.
X2e5e:
	ret			; 2e5e   22         "
;
X2e5f:
;	jb	exchange_dir,X2e5e	; 2e5f   20 2d fc    -|
	sjmp	X2e5e
;	cpl	zc_point		; 2e62   b2 09      2.
;	ret			; 2e64   22         "
;
X2e65:	setb	fb_adc_timeout		; 2e65   d2 05      R.
	ret			; 2e67   22         "
;
X2e68:	ret			; 2e68   22         "
;
x2e69_verify_rcp:
	clr		ex0		; 2e69   c2 a8      B(
	mov		r0,rcp_h		; 2e6b   a8 2b      (+
	mov		r1,rcp_l		; 2e6d   a9 2a      )*
	setb	ex0		; 2e6f   d2 a8      R(
	clr		rcp_t0_ready		; 2e71   c2 00      B.
	jnb		rcp_x_8,X2e87	; 2e73   30 39 11   09.
	; r0:r1 x 8
	mov		a,r1		; 2e76   e9         i
	mov		b,#8		; 2e77   75 f0 08   up.
	mul		ab		; 2e7a   a4         $
	mov		r1,a		; 2e7b   f9         y
	mov		37h,b		; 2e7c   85 f0 37   .p7
	mov		a,r0		; 2e7f   e8         h
	mov		b,#8		; 2e80   75 f0 08   up.
	mul		ab		; 2e83   a4         $
	add		a,37h		; 2e84   25 37      %7
	mov		r0,a		; 2e86   f8         x
X2e87:
	mov		a,r0		; 2e87   e8         h
	clr		c		; 2e88   c3         C
	subb	a,#14h		; 2e89   94 14      ..
	jnc		X2e68		; 2e8b   50 db      P[
	mov		a,r0		; 2e8d   e8         h
	clr		c		; 2e8e   c3         C
	subb	a,#6		; 2e8f   94 06      ..
	jc		X2e68		; 2e91   40 d5      @U
	mov		state_timeout,#0		; 2e93   75 44 00   uD.
	clr		stay_idle		; 2e96   c2 01      B.
	clr		low_rcp		; 2e98   c2 0f      B.
	clr		hi_pwm		; 2e9a   c2 12      B.
	mov		3bh,#10h	; 2e9c   75 3b 10   u;.
	mov		38h,forward_rcp_zone		; 2e9f   85 2c 38   .,8
	; the flag exchange_dir is obslated
;	jb		exchange_dir,X2eb2	; 2ea2   20 2d 0d    -.
;	clr		c		; 2ea5   c3         C
;	mov		a,rcp_nuetral		; 2ea6   e5 72      er
;	subb	a,r1		; 2ea8   99         .
;	mov		r1,a		; 2ea9   f9         y
;	mov		a,rcp_nuetral+1		; 2eaa   e5 73      es
;	subb	a,r0		; 2eac   98         .
;	mov		r0,a		; 2ead   f8         x
;	jnc		X2ece		; 2eae   50 1e      P.
;	sjmp	X2ebd		; 2eb0   80 0b      ..
X2eb2:
	clr		c		; 2eb2   c3         C
	mov		a,r1		; 2eb3   e9         i
	subb	a,rcp_nuetral		; 2eb4   95 72      .r
	mov		r1,a		; 2eb6   f9         y
	mov		a,r0		; 2eb7   e8         h
	subb	a,rcp_nuetral+1		; 2eb8   95 73      .s
	mov		r0,a		; 2eba   f8         x
	jnc		X2ece		; 2ebb   50 11      P.
X2ebd:
	setb	low_rcp		; 2ebd   d2 0f      R.
	mov		38h,reverse_rcp_zone		; 2ebf   85 2d 38   .-8
	mov	a,r1		; 2ec2   e9         i
	cpl	a		; 2ec3   f4         t
	mov	r1,a		; 2ec4   f9         y
	mov	a,r0		; 2ec5   e8         h
	cpl	a		; 2ec6   f4         t
	mov	r0,a		; 2ec7   f8         x
	jnb	first_state,X2ece	; 2ec8   30 10 03   0..
	mov	3bh,3ch		; 2ecb   85 3c 3b   .<;
X2ece:	mov	a,r1		; 2ece   e9         i
	mov	b,3bh		; 2ecf   85 3b f0   .;p
	mul	ab		; 2ed2   a4         $
	mov	r1,a		; 2ed3   f9         y
	mov	37h,b		; 2ed4   85 f0 37   .p7
	mov	a,r0		; 2ed7   e8         h
	mov	b,3bh		; 2ed8   85 3b f0   .;p
	mul	ab		; 2edb   a4         $
	add	a,37h		; 2edc   25 37      %7
	mov	r0,a		; 2ede   f8         x
	subb	a,38h		; 2edf   95 38      .8
	jc	X2ee8		; 2ee1   40 05      @.
	mov	a,#0ffh		; 2ee3   74 ff      t.
	mov	r2,a		; 2ee5   fa         z
	sjmp	X2f06		; 2ee6   80 1e      ..
;
X2ee8:	mov	37h,#8		; 2ee8   75 37 08   u7.
X2eeb:	clr	c		; 2eeb   c3         C
	mov	a,r1		; 2eec   e9         i
	rlc	a		; 2eed   33         3
	mov	r1,a		; 2eee   f9         y
	mov	a,r0		; 2eef   e8         h
	rlc	a		; 2ef0   33         3
	mov	r0,a		; 2ef1   f8         x
	mov	f0,c		; 2ef2   92 d5      .U
	clr	c		; 2ef4   c3         C
	mov	a,r0		; 2ef5   e8         h
	subb	a,38h		; 2ef6   95 38      .8
	jb	f0,X2efd	; 2ef8   20 d5 02    U.
	jc	X2eff		; 2efb   40 02      @.
X2efd:	mov	r0,a		; 2efd   f8         x
	inc	r1		; 2efe   09         .
X2eff:	djnz	37h,X2eeb	; 2eff   d5 37 e9   U7i
	mov	a,r1		; 2f02   e9         i
	mov	r2,a		; 2f03   fa         z
	mov	current_pwm,a		; 2f04   f5 35      u5
X2f06:	clr	c		; 2f06   c3         C
	subb	a,dead_rcp_zone		; 2f07   95 3f      .?
	jnc	X2f10		; 2f09   50 05      P.
	mov	5bh,#0		; 2f0b   75 5b 00   u[.
	sjmp	X2f2a		; 2f0e   80 1a      ..
;
X2f10:
	mov		a,r2		; 2f10   ea         j
	clr		c		; 2f11   c3         C
	subb	a,3eh		; 2f12   95 3e      .>
	jnc		X2f1f		; 2f14   50 09      P.
	mov		a,5ah		; 2f16   e5 5a      eZ
	jnz		X2f21		; 2f18   70 07      p.
	mov		5bh,#0		; 2f1a   75 5b 00   u[.
	sjmp	X2f2a		; 2f1d   80 0b      ..
;
X2f1f:
	setb	hi_pwm		; 2f1f   d2 12      R.
X2f21:	mov	5bh,#1		; 2f21   75 5b 01   u[.
	jnb	low_rcp,X2f2a	; 2f24   30 0f 03   0..
	mov	5bh,#2		; 2f27   75 5b 02   u[.
X2f2a:	mov	a,5bh		; 2f2a   e5 5b      e[
	cjne	a,5ah,X2f31	; 2f2c   b5 5a 02   5Z.
	sjmp	X2f41		; 2f2f   80 10      ..
;
X2f31:	cjne	a,#1,X2f36	; 2f31   b4 01 02   4..
	sjmp	X2f41		; 2f34   80 0b      ..
;
X2f36:	cjne	a,5ch,X2f3b	; 2f36   b5 5c 02   5\.
	sjmp	X2f41		; 2f39   80 06      ..
;
X2f3b:	mov	5ch,a		; 2f3b   f5 5c      u\ 
	mov	r2,2fh		; 2f3d   aa 2f      */
	sjmp	X2f50		; 2f3f   80 0f      ..
;
X2f41:	mov	2fh,r2		; 2f41   8a 2f      ./
	mov	a,5ah		; 2f43   e5 5a      eZ
	swap	a		; 2f45   c4         D
	orl	a,5bh		; 2f46   45 5b      E[
	mov	motor_status,a		; 2f48   f5 59      uY
	mov	5ah,5bh		; 2f4a   85 5b 5a   .[Z
	mov	5ch,5bh		; 2f4d   85 5b 5c   .[\ 
X2f50:	mov	a,motor_status		; 2f50   e5 59      eY
	cjne	a,#1,X2f57	; 2f52   b4 01 02   4..
	sjmp	X2f99		; 2f55   80 42      .B
;
X2f57:	cjne	a,#2,X2f5c	; 2f57   b4 02 02   4..
	sjmp	X2f6d		; 2f5a   80 11      ..
;
X2f5c:	cjne	a,#11h,X2f61	; 2f5c   b4 11 02   4..
	sjmp	X2f99		; 2f5f   80 38      .8
;
X2f61:	cjne	a,#22h,X2f66	; 2f61   b4 22 02   4".
	sjmp	X2f6d		; 2f64   80 07      ..
;
X2f66:
	setb	stay_idle		; 2f66   d2 01      R.
	clr		green_led		; 2f68   c2 93      B.
	clr		red_led		; 2f6a   c2 94      B.
	ret			; 2f6c   22         "
;
X2f6d:	jb	21h.6,X2f76	; 2f6d   20 0e 06    ..
	clr	first_state		; 2f70   c2 10      B.
	clr	22h.1		; 2f72   c2 11      B.
;	clr	25h.6		; 2f74   c2 2e      B.
X2f76:	setb	dir_reverse		; 2f76   d2 0a      R.
	jb	rcp_x_8,X2f80	; 2f78   20 39 05    9.
	mov	b,65h		; 2f7b   85 65 f0   .ep
	sjmp	X2f83		; 2f7e   80 03      ..
;
X2f80:	mov	b,64h		; 2f80   85 64 f0   .dp
X2f83:	inc	b		; 2f83   05 f0      .p
	mov	a,r2		; 2f85   ea         j
	mul	ab		; 2f86   a4         $
	mov	r0,a		; 2f87   f8         x
	mov	r1,b		; 2f88   a9 f0      )p
	mov	a,r1		; 2f8a   e9         i
	clr	c		; 2f8b   c3         C
	rrc	a		; 2f8c   13         .
	mov	r1,a		; 2f8d   f9         y
	mov	a,r0		; 2f8e   e8         h
	rrc	a		; 2f8f   13         .
	mov	r0,a		; 2f90   f8         x
	clr	c		; 2f91   c3         C
	mov	a,r1		; 2f92   e9         i
	rrc	a		; 2f93   13         .
	mov	a,r0		; 2f94   e8         h
	rrc	a		; 2f95   13         .
	mov	r2,a		; 2f96   fa         z
	sjmp	X2f9b		; 2f97   80 02      ..
;
X2f99:	clr	dir_reverse		; 2f99   c2 0a      B.
X2f9b:	jnb	forwarding,X2fd5	; 2f9b   30 03 37   0.7
	clr	c		; 2f9e   c3         C
	mov	a,r2		; 2f9f   ea         j
	add	a,5eh		; 2fa0   25 5e      %^
	jnc	X2fa6		; 2fa2   50 02      P.
	mov	a,#0ffh		; 2fa4   74 ff      t.
X2fa6:	mov	r2,a		; 2fa6   fa         z
	mov	current_pwm,a		; 2fa7   f5 35      u5
	clr	c		; 2fa9   c3         C
	subb	a,accelate_factor		; 2faa   95 2e      ..
	jc	X2fb6		; 2fac   40 08      @.
	mov	a,accelate_factor		; 2fae   e5 2e      e.
	subb	a,#0fch		; 2fb0   94 fc      .|
	jnc	X2fda		; 2fb2   50 26      P&
	mov	r2,accelate_factor		; 2fb4   aa 2e      *.
X2fb6:	clr	c		; 2fb6   c3         C
	mov	a,accelate_factor		; 2fb7   e5 2e      e.
	subb	a,r2		; 2fb9   9a         .
	jc	X2fce		; 2fba   40 12      @.
	subb	a,55h		; 2fbc   95 55      .U
	jc	X2fce		; 2fbe   40 0e      @.
	subb	a,55h		; 2fc0   95 55      .U
	jc	X2fce		; 2fc2   40 0a      @.
	mov	a,r2		; 2fc4   ea         j
	clr	c		; 2fc5   c3         C
	add	a,55h		; 2fc6   25 55      %U
	jnc	X2fcc		; 2fc8   50 02      P.
	mov	a,#0ffh		; 2fca   74 ff      t.
X2fcc:	mov	accelate_factor,a		; 2fcc   f5 2e      u.
X2fce:	mov	PCA0CPH0,r2		; 2fce   8a fc      .|
	setb	red_led		; 2fd0   d2 94      R.
	clr	green_led		; 2fd2   c2 93      B.
	ret			; 2fd4   22         "
;
X2fd5:	clr	green_led		; 2fd5   c2 93      B.
	clr	red_led		; 2fd7   c2 94      B.
	ret			; 2fd9   22         "
;
X2fda:	mov	r2,#0ffh	; 2fda   7a ff      z.
	mov	PCA0CPH0,#0ffh	; 2fdc   75 fc ff   u|.
	anl	PCA0CPM0,#0bfh	; 2fdf   53 da bf   SZ?
	setb	green_led		; 2fe2   d2 93      R.
;	setb	debug_flag
	ret			; 2fe4   22         "
;
x2fe5_calc_com:	mov	4dh,r6		; 2fe5   8e 4d      .M
	mov	4eh,r5		; 2fe7   8d 4e      .N
	mov	r4,TMR2L		; 2fe9   ac cc      ,L
	mov	r3,TMR2H		; 2feb   ab cd      +M
	mov	a,r4		; 2fed   ec         l
	clr	c		; 2fee   c3         C
	add	a,r6		; 2fef   2e         .
	mov	r0,a		; 2ff0   f8         x
	mov	a,r3		; 2ff1   eb         k
	addc	a,r5		; 2ff2   3d         =
	rrc	a		; 2ff3   13         .
	mov	r5,a		; 2ff4   fd         }
	mov	a,r0		; 2ff5   e8         h
	rrc	a		; 2ff6   13         .
	mov	r6,a		; 2ff7   fe         ~
	mov	a,r5		; 2ff8   ed         m
	clr	c		; 2ff9   c3         C
	rrc	a		; 2ffa   13         .
	mov	r0,a		; 2ffb   f8         x
	mov	r5,a		; 2ffc   fd         }
	mov	a,r6		; 2ffd   ee         n
	rrc	a		; 2ffe   13         .
	mov	r1,a		; 2fff   f9         y
	mov	r6,a		; 3000   fe         ~
	clr	c		; 3001   c3         C
	mov	a,r0		; 3002   e8         h
	rrc	a		; 3003   13         .
	mov	b,a		; 3004   f5 f0      up
	mov	a,r1		; 3006   e9         i
	rrc	a		; 3007   13         .
	mov	r1,a		; 3008   f9         y
	mov	a,r0		; 3009   e8         h
	cpl	a		; 300a   f4         t
	mov	r0,a		; 300b   f8         x
	mov	a,r1		; 300c   e9         i
	cpl	a		; 300d   f4         t
	mov	r1,a		; 300e   f9         y
	mov	TMR2H,r0		; 300f   88 cd      .M
	mov	TMR2L,r1		; 3011   89 cc      .L
;	mov	TMR2CN,#64h	; 3013   75 c8 64   uHd
	setb	tr2
	clr	20h.2		; 3016   c2 02      B.
	ret			; 3018   22         "
;
X3019:
	setb	20h.2		; 3019   d2 02      R.
;	jnb	20h.2,X302c	; 301b   30 02 0e   0..
	mov	a,r3		; 301e   eb         k
	clr	c		; 301f   c3         C
	subb	a,#23h		; 3020   94 23      .#
	jnc	X302c		; 3022   50 08      P.
	mov	a,r3		; 3024   eb         k
	clr	c		; 3025   c3         C
	subb	a,#1eh		; 3026   94 1e      ..
	jnc	X303d		; 3028   50 13      P.
	sjmp	X303b		; 302a   80 0f      ..
;
X302c:	mov	a,startup_count		; 302c   e5 4f      eO
	subb	a,#5		; 302e   94 05      ..
	jc	X3036		; 3030   40 04      @.
	mov	startup_count,a		; 3032   f5 4f      uO
	sjmp	X303d		; 3034   80 07      ..
;
X3036:	mov	startup_count,#0		; 3036   75 4f 00   uO.
	sjmp	X303d		; 3039   80 02      ..
;
X303b:	inc	startup_count		; 303b   05 4f      .O
X303d:	jnb	TMR2CN.7,$	; 303d   30 cf fd   0O}
	ljmp	X2af1		; 3040   02 2a f1   .*q
;
X3043:
	setb	27h.4		; 3043   d2 3c      R<
	mov		a,#10h		; 3045   74 10      t.
	mov		r3,a		; 3047   fb         {
	mov		r5,a		; 3048   fd         }
	mov		4eh,a		; 3049   f5 4e      uN
	mov		startup_count,#0		; 304b   75 4f 00   uO.
	mov		a,accelate_factor		; 304e   e5 2e      e.
	clr		c		; 3050   c3         C
	subb	a,5dh		; 3051   95 5d      .]
	jnc		X305b		; 3053   50 06      P.
	mov		a,accelate_factor		; 3055   e5 2e      e.
	add		a,54h		; 3057   25 54      %T
	mov		accelate_factor,a		; 3059   f5 2e      u.
X305b:
	mov		a,5eh		; 305b   e5 5e      e^
	subb	a,#10h		; 305d   94 10      ..
	jnc		X3067		; 305f   50 06      P.
	mov		a,5eh		; 3061   e5 5e      e^
	add		a,#2		; 3063   24 02      $.
	mov		5eh,a		; 3065   f5 5e      u^
X3067:
	ljmp	X2af1		; 3067   02 2a f1   .*q
;
x306a_sw_state:
	setb	first_3state		; 306a   d2 2f      R/
	clr	c		; 306c   c3         C
	mov	a,52h		; 306d   e5 52      eR
	subb	a,#3		; 306f   94 03      ..
	jnc	X3077		; 3071   50 04      P.
	clr	first_3state		; 3073   c2 2f      B/
	inc	52h		; 3075   05 52      .R
X3077:
;	jb	exchange_dir,X3084	; 3077   20 2d 0a    -.
;	jnb	dir_reverse,X3092	; 307a   30 0a 15   0..
;	jnb	first_3state,X30cb	; 307d   30 2f 4b   0/K
;	setb	go_run		; 3080   d2 1e      R.
;	sjmp	X30cb		; 3082   80 47      .G
;
;X3084:
	jnb	dir_reverse,X30c0	; 3084   30 0a 39   0.9
	jnb	first_3state,X309d	; 3087   30 2f 13   0/.
	setb	go_run		; 308a   d2 1e      R.
	clr	first_state		; 308c   c2 10      B.
	clr	22h.1		; 308e   c2 11      B.
	sjmp	X309d		; 3090   80 0b      ..
;
;X3092:
;	jnb	first_3state,X309d	; 3092   30 2f 08   0/.
;	clr	go_run		; 3095   c2 1e      B.
;	clr	first_state		; 3097   c2 10      B.
;	clr	22h.1		; 3099   c2 11      B.
;	clr	25h.6		; 309b   c2 2e      B.
X309d:
	mov	a,state_index		; 309d   e5 29      e)
	mov	dptr,#X30a3	; 309f   90 30 a3   .0#
	jmp	@a+dptr		; 30a2   73         s
;
X30a3:
	ljmp	x30e3_state0		; 30a3   02 30 e3   .0c
	ljmp	x30f9_state1		; 30a6   02 30 f9   .0y
	ljmp	x310f_state2		; 30a9   02 31 0f   .1.
	ljmp	x3125_state3		; 30ac   02 31 25   .1%
	ljmp	x313b_state4		; 30af   02 31 3b   .1;
	ljmp	x3151_state5		; 30b2   02 31 51   .1Q
; seems never reach here
;	jnb		first_3state,X30cb	; 30b5   30 2f 13   0/.
;	setb	go_run		; 30b8   d2 1e      R.
;	clr		first_state		; 30ba   c2 10      B.
;	clr		22h.1		; 30bc   c2 11      B.
;	sjmp	X30cb		; 30be   80 0b      ..
;
X30c0:
	jnb		first_3state,X30cb	; 30c0   30 2f 08   0/.
	clr		go_run		; 30c3   c2 1e      B.
	clr		first_state		; 30c5   c2 10      B.
	clr		22h.1		; 30c7   c2 11      B.
;	clr		25h.6		; 30c9   c2 2e      B.
X30cb:
	mov		a,state_index		; 30cb   e5 29      e)
	mov		dptr,#X30d1	; 30cd   90 30 d1   .0Q
	jmp		@a+dptr		; 30d0   73         s
;
X30d1:
	ljmp	x313b_state4		; 30d1   02 31 3b   .1;
	ljmp	x3151_state5		; 30d4   02 31 51   .1Q
	ljmp	x30e3_state0		; 30d7   02 30 e3   .0c
	ljmp	x30f9_state1		; 30da   02 30 f9   .0y
	ljmp	x310f_state2		; 30dd   02 31 0f   .1.
	ljmp	x3125_state3		; 30e0   02 31 25   .1%
;
x30e3_state0:	clr	fet_cp		; 30e3   c2 90      B.
	clr	fet_ap		; 30e5   c2 96      B.
	setb	fet_bp		; 30e7   d2 86      R.
	setb	fet_bn		; 30e9   d2 92      R.
	setb	fet_cn		; 30eb   d2 91      R.
	setb	fet_an		; 30ed   d2 95      R.
;	mov	P0SKIP,#0cfh	; 30ef   75 d4 cf   uTO
	mov	P1SKIP,#0dfh	; 30f2   75 d5 df   uU_		; p1.5 an
	mov	state_index,#3		; 30f5   75 29 03   u).
	ret			; 30f8   22         "
;
x30f9_state1:	clr	fet_bp		; 30f9   c2 86      B.
	clr	fet_ap		; 30fb   c2 96      B.
	setb	fet_cp		; 30fd   d2 90      R.
	setb	fet_bn		; 30ff   d2 92      R.
	setb	fet_cn		; 3101   d2 91      R.
	setb	fet_an		; 3103   d2 95      R.
;	mov	P0SKIP,#0cfh	; 3105   75 d4 cf   uTO
	mov	P1SKIP,#0dfh	; 3108   75 d5 df   uU_
	mov	state_index,#6		; 310b   75 29 06   u).
	ret			; 310e   22         "
;
x310f_state2:	clr	fet_bp		; 310f   c2 86      B.
	clr	fet_ap		; 3111   c2 96      B.
	setb	fet_cp		; 3113   d2 90      R.
	setb	fet_bn		; 3115   d2 92      R.
	setb	fet_cn		; 3117   d2 91      R.
	setb	fet_an		; 3119   d2 95      R.
;	mov	P0SKIP,#0cfh	; 311b   75 d4 cf   uTO
	mov	P1SKIP,#0fbh	; 311e   75 d5 fb   uU{		; p1.2 bn
	mov	state_index,#9		; 3121   75 29 09   u).
	ret			; 3124   22         "
;
x3125_state3:	clr	fet_bp		; 3125   c2 86      B.
	clr	fet_cp		; 3127   c2 90      B.
	setb	fet_ap		; 3129   d2 96      R.
	setb	fet_bn		; 312b   d2 92      R.
	setb	fet_cn		; 312d   d2 91      R.
	setb	fet_an		; 312f   d2 95      R.
;	mov	P0SKIP,#0cfh	; 3131   75 d4 cf   uTO
	mov	P1SKIP,#0fbh	; 3134   75 d5 fb   uU{
	mov	state_index,#0ch	; 3137   75 29 0c   u).
	ret			; 313a   22         "
;
x313b_state4:	clr	fet_bp		; 313b   c2 86      B.
	clr	fet_cp		; 313d   c2 90      B.
	setb	fet_ap		; 313f   d2 96      R.
	setb	fet_bn		; 3141   d2 92      R.
	setb	fet_cn		; 3143   d2 91      R.
	setb	fet_an		; 3145   d2 95      R.
;	mov	P0SKIP,#0cfh	; 3147   75 d4 cf   uTO
	mov	P1SKIP,#0fdh	; 314a   75 d5 fd   uU}		; p1.1 cn
	mov	state_index,#0fh	; 314d   75 29 0f   u).
	ret			; 3150   22         "
;
x3151_state5:	clr	fet_cp		; 3151   c2 90      B.
	clr	fet_ap		; 3153   c2 96      B.
	setb	fet_bp		; 3155   d2 86      R.
	setb	fet_bn		; 3157   d2 92      R.
	setb	fet_cn		; 3159   d2 91      R.
	setb	fet_an		; 315b   d2 95      R.
;	mov	P0SKIP,#0cfh	; 315d   75 d4 cf   uTO
	mov	P1SKIP,#0fdh	; 3160   75 d5 fd   uU}
	mov	state_index,#0		; 3163   75 29 00   u).
	ret			; 3166   22         "
;
x3167_flash_green_3:
	lcall	x316c_flash_green		; 3167   12 31 6c   .1l
x316a_flash_green_2:
	acall	x316c_flash_green		; 316a   31 6c      1l
x316c_flash_green:
	clr		red_led		; 316c   c2 94      B.
	setb	green_led		; 316e   d2 93      R.
	mov		r2,#10h		; 3170   7a 10      z.
	lcall	x24e9_set_pwm0_duty		; 3172   12 24 e9   .$i
	mov		P0SKIP,#0ffh	; 3175   75 d4 ff   uT.
	mov		P1SKIP,#0fdh	; 3178   75 d5 fd   uU}			; p1.1 cn
	setb	fet_bp		; 317b   d2 86      R.
	lcall	x31d1_delay_5_2		; 317d   12 31 d1   .1Q
	clr		green_led		; 3180   c2 93      B.
	lcall	X2561_all_fet_off		; 3182   12 25 61   .%a
	lcall	x31ce_delay_5_3		; 3185   12 31 ce   .1N
	ret			; 3188   22         "
;
x3189_short_light_green:
	setb	green_led		; 3189   d2 93      R.
	mov		r2,#10h		; 318b   7a 10      z.
	lcall	x24e9_set_pwm0_duty		; 318d   12 24 e9   .$i
	mov		P0SKIP,#0ffh	; 3190   75 d4 ff   uT.
	mov		P1SKIP,#0fdh	; 3193   75 d5 fd   uU}
	setb	fet_bp		; 3196   d2 86      R.
	lcall	x31d1_delay_5_2		; 3198   12 31 d1   .1Q
	clr		green_led		; 319b   c2 93      B.
	lcall	X2561_all_fet_off		; 319d   12 25 61   .%a
	lcall	x31ce_delay_5_3		; 31a0   12 31 ce   .1N
	ret			; 31a3   22         "
;
x31a4_long_light_green:
	setb	green_led		; 31a4   d2 93      R.
	mov		r2,#10h		; 31a6   7a 10      z.
	lcall	x24e9_set_pwm0_duty		; 31a8   12 24 e9   .$i
	mov		P0SKIP,#0ffh	; 31ab   75 d4 ff   uT.
	mov		P1SKIP,#0fdh	; 31ae   75 d5 fd   uU}
	setb	fet_bp		; 31b1   d2 86      R.
	lcall	x31c5_longlong_delay		; 31b3   12 31 c5   .1E
	clr		green_led		; 31b6   c2 93      B.
	lcall	X2561_all_fet_off		; 31b8   12 25 61   .%a
	lcall	X31cb		; 31bb   12 31 cb   .1K
	ret			; 31be   22         "
;
X31bf:
	lcall	x31c2_longlonglong_delay		; 31bf   12 31 c2   .1B
x31c2_longlonglong_delay:
	lcall	x31c5_longlong_delay		; 31c2   12 31 c5   .1E
x31c5_longlong_delay:
	lcall	x31c8_long_delay		; 31c5   12 31 c8   .1H
x31c8_long_delay:
	lcall	x31d8_delay_5		; 31c8   12 31 d8   .1X
X31cb:	lcall	x31d8_delay_5		; 31cb   12 31 d8   .1X
x31ce_delay_5_3:	lcall	x31d8_delay_5		; 31ce   12 31 d8   .1X
x31d1_delay_5_2:	lcall	x31d8_delay_5		; 31d1   12 31 d8   .1X
	lcall	x31d8_delay_5		; 31d4   12 31 d8   .1X
	ret			; 31d7   22         "
;
x31d8_delay_5:
	mov		39h,#5		; 31d8   75 39 05   u9.
	ljmp	X31e7		; 31db   02 31 e7   .1g
;
x31de_delay_1:
	mov		39h,#1		; 31de   75 39 01   u9.
	sjmp	X31e7		; 31e1   80 04      ..
;
x31e3_delay_4:
	mov		39h,#4		; 31e3   75 39 04   u9.
	nop			; 31e6   00         .
X31e7:
	mov		38h,#3ch	; 31e7   75 38 3c   u8<
	nop			; 31ea   00         .
X31eb:	mov	37h,#0ffh	; 31eb   75 37 ff   u7.
	djnz	37h,$	; 31ee   d5 37 fd   U7}
	djnz	38h,X31eb	; 31f1   d5 38 f7   U8w
	djnz	39h,X31e7	; 31f4   d5 39 f0   U9p
	ret			; 31f7   22         "
;
x31f8_delay_18h:	mov	38h,#18h	; 31f8   75 38 18   u8.
X31fb:	mov	37h,#0ffh	; 31fb   75 37 ff   u7.
	djnz	37h,$	; 31fe   d5 37 fd   U7}
	djnz	38h,X31fb	; 3201   d5 38 f7   U8w
	ret			; 3204   22         "
;
X3205:	mov	38h,#3		; 3205   75 38 03   u8.
	sjmp	X31fb		; 3208   80 f1      .q
;
	lcall	X3219		; 320a   12 32 19   .2.
	lcall	X3219		; 320d   12 32 19   .2.
	lcall	X3219		; 3210   12 32 19   .2.
X3213:	lcall	X3219		; 3213   12 32 19   .2.
	lcall	X3219		; 3216   12 32 19   .2.
X3219:	lcall	X3228		; 3219   12 32 28   .2(
	lcall	X3225		; 321c   12 32 25   .2%
x321f_delay_4:
	lcall	X322b		; 321f   12 32 2b   .2+
	lcall	X322b		; 3222   12 32 2b   .2+
X3225:
	lcall	X322b		; 3225   12 32 2b   .2+
X3228:
	lcall	X322b		; 3228   12 32 2b   .2+
X322b:	ljmp	X322e		; 322b   02 32 2e   .2.
X322e:	ljmp	X3231		; 322e   02 32 31   .21
X3231:	ljmp	X3234		; 3231   02 32 34   .24
X3234:	ljmp	X3237		; 3234   02 32 37   .27
;
X3237:	ret			; 3237   22         "
;
X3238:	lcall	X2561_all_fet_off		; 3238   12 25 61   .%a
	ljmp	X27a2		; 323b   02 27 a2   .'"
;
X323e:	jb	adc_busy,X3272	; 323e   20 33 31    31
	mov	a,accelate_factor		; 3241   e5 2e      e.
	cjne	a,#0ffh,X324d	; 3243   b4 ff 07   4..
	mov	4ah,#0		; 3246   75 4a 00   uJ.
	mov	49h,#0		; 3249   75 49 00   uI.
	ret			; 324c   22         "
;
X324d:	mov	a,4ah		; 324d   e5 4a      eJ
	jnz	X325c		; 324f   70 0b      p.
	clr	c		; 3251   c3         C
	mov	a,49h		; 3252   e5 49      eI
	subb	a,#50h		; 3254   94 50      .P
	jc	X3272		; 3256   40 1a      @.
	mov	49h,a		; 3258   f5 49      uI
	sjmp	X3267		; 325a   80 0b      ..
;
X325c:	clr	c		; 325c   c3         C
	mov	a,49h		; 325d   e5 49      eI
	subb	a,#50h		; 325f   94 50      .P
	mov	49h,a		; 3261   f5 49      uI
	jnc	X3267		; 3263   50 02      P.
	dec	4ah		; 3265   15 4a      .J
X3267:	mov	a,accelate_factor		; 3267   e5 2e      e.
	clr	c		; 3269   c3         C
	add	a,55h		; 326a   25 55      %U
	jnc	X3270		; 326c   50 02      P.
	mov	a,#0ffh		; 326e   74 ff      t.
X3270:	mov	accelate_factor,a		; 3270   f5 2e      u.
X3272:	ret			; 3272   22         "
;
x3273_state_start:
	lcall	x306a_sw_state		; 3273   12 30 6a   .0j
	lcall	x2808_t2_reset		; 3276   12 28 08   .(.
	mov		a,r2		; 3279   ea         j
	subb	a,#0c0h		; 327a   94 c0      .@
	jc		X328c		; 327c   40 0e      @.
	mov		ADC0GTH,#2		; 327e   75 c4 02   uD.
	mov		ADC0GTL,#0		; 3281   75 c3 00   uC.
	mov		ADC0LTH,#0fdh	; 3284   75 c6 fd   uF}
	mov		ADC0LTL,#0ffh	; 3287   75 c5 ff   uE.
	sjmp	X329a		; 328a   80 0e      ..
;
X328c:	mov	ADC0GTH,#1		; 328c   75 c4 01   uD.
	mov	ADC0GTL,#0		; 328f   75 c3 00   uC.
	mov	ADC0LTH,#0feh	; 3292   75 c6 fe   uF~
	mov	ADC0LTL,#0ffh	; 3295   75 c5 ff   uE.
;	sjmp	X329a		; 3298   80 00      ..
;
X329a:	mov	a,5eh		; 329a   e5 5e      e^
	clr	c		; 329c   c3         C
	subb	a,#8		; 329d   94 08      ..
	jnc	X32a3		; 329f   50 02      P.
	mov	a,#0		; 32a1   74 00      t.
X32a3:	mov	5eh,a		; 32a3   f5 5e      u^
	clr	c		; 32a5   c3         C
	mov	a,r4		; 32a6   ec         l
	add	a,4dh		; 32a7   25 4d      %M
	mov	r0,a		; 32a9   f8         x
	mov	a,r3		; 32aa   eb         k
	addc	a,4eh		; 32ab   35 4e      5N
	mov	r1,a		; 32ad   f9         y
	rrc	a		; 32ae   13         .
	mov	r1,a		; 32af   f9         y
	mov	a,r0		; 32b0   e8         h
	rrc	a		; 32b1   13         .
	mov	r0,a		; 32b2   f8         x
	clr	c		; 32b3   c3         C
	mov	a,r1		; 32b4   e9         i
	rrc	a		; 32b5   13         .
	mov		r1,a		; 32b6   f9         y
	mov		a,r0		; 32b7   e8         h
	rrc		a		; 32b8   13         .
	mov		r0,a		; 32b9   f8         x
	lcall	X323e		; 32ba   12 32 3e   .2>
	jb		temper1volt0,X32cd	; 32bd   20 1f 0d    ..
	setb	temper1volt0		; 32c0   d2 1f      R.
	lcall	x2d74_exam_volt		; 32c2   12 2d 74   .-t
	jnb		stay_idle,X32d8	; 32c5   30 01 10   0..
	ljmp	X2ddc		; 32c8   02 2d dc   .-\
;
	sjmp	X32d8		; 32cb   80 0b      ..
;
X32cd:
	clr		temper1volt0		; 32cd   c2 1f      B.
	lcall	x2cf0_fetch_temper		; 32cf   12 2c f0   .,p
	jnb		stay_idle,X32d8	; 32d2   30 01 03   0..
	ljmp	X2d38		; 32d5   02 2d 38   .-8
;
X32d8:
	mov		a,TMR2H		; 32d8   e5 cd      eM
	clr		c		; 32da   c3         C
	subb	a,r1		; 32db   99         .
	jc		X32d8		; 32dc   40 fa      @z
X32de:
	mov		a,TMR2L		; 32de   e5 cc      eL
	clr		c		; 32e0   c3         C
	subb	a,r0		; 32e1   98         .
	jc		X32de		; 32e2   40 fa      @z
	mov		a,state_index		; 32e4   e5 29      e)
	mov		dptr,#X32ea	; 32e6   90 32 ea   .2j
	jmp		@a+dptr		; 32e9   73         s
;
X32ea:
	ljmp	X32fc		; 32ea   02 32 fc   .2|
	ljmp	X3341		; 32ed   02 33 41   .3A
	ljmp	X337c		; 32f0   02 33 7c   .3|
	ljmp	X33b4		; 32f3   02 33 b4   .34
	ljmp	X33ec		; 32f6   02 33 ec   .3l
	ljmp	X3424		; 32f9   02 34 24   .4$
;
X32fc:
	lcall	x2ce3_feedback_a		; 32fc   12 2c e3   .,c
	mov		r0,#3		; 32ff   78 03      x.
	jb		fet_cn,X332c	; 3301   20 91 28    .(
X3304:
	mov		a,state_timeout		; 3304   e5 44      eD
	clr		c		; 3306   c3         C
	subb	a,#0ah		; 3307   94 0a      ..
	jc		X3311		; 3309   40 06      @.
	lcall	x2816_cfg_according_params		; 330b   12 28 16   .(.
	ljmp	x25a3_control_start		; 330e   02 25 a3   .%#
;
X3311:	lcall	X3228		; 3311   12 32 28   .2(
	sjmp	X3318		; 3314   80 02      ..
;
X3316:	mov	r0,#3		; 3316   78 03      x.
X3318:	jb	fet_cn,X332c	; 3318   20 91 11    ..
	lcall	x2e34_zero_cross_i0		; 331b   12 2e 34   ..4
	jnb	fb_adc_timeout,X3324	; 331e   30 05 03   0..
	ljmp	X3238		; 3321   02 32 38   .28
;
X3324:	jb	zc_point,X3316	; 3324   20 09 ef    .o
	djnz	r0,X3318	; 3327   d8 ef      Xo
	ljmp	X345c		; 3329   02 34 5c   .4\
;
X332c:	lcall	X3228		; 332c   12 32 28   .2(
	sjmp	X3333		; 332f   80 02      ..
;
X3331:	mov	r0,#3		; 3331   78 03      x.
X3333:	jnb	fet_cn,X3304	; 3333   30 91 ce   0.N
	lcall	x2e34_zero_cross_i0		; 3336   12 2e 34   ..4
	jb	zc_point,X3331	; 3339   20 09 f5    .u
	djnz	r0,X3333	; 333c   d8 f5      Xu
	ljmp	X345c		; 333e   02 34 5c   .4\
;
X3341:	lcall	x2cde_feedback_c		; 3341   12 2c de   .,^
	mov	r0,#3		; 3344   78 03      x.
	jb	fet_an,X3367	; 3346   20 95 1e    ..
X3349:
	lcall	x2a90_t3_sum		; 3349   12 2a 90   .*.
	lcall	X322b		; 334c   12 32 2b   .2+
	sjmp	X3353		; 334f   80 02      ..
;
X3351:	mov	r0,#3		; 3351   78 03      x.
X3353:	jb	fet_an,X3367	; 3353   20 95 11    ..
	lcall	x2df9_zero_cross_x0		; 3356   12 2d f9   .-y
	jnb	fb_adc_timeout,X335f	; 3359   30 05 03   0..
	ljmp	X3238		; 335c   02 32 38   .28
;
X335f:	jnb	zc_point,X3351	; 335f   30 09 ef   0.o
	djnz	r0,X3353	; 3362   d8 ef      Xo
	ljmp	X345c		; 3364   02 34 5c   .4\
;
X3367:	lcall	X3228		; 3367   12 32 28   .2(
	sjmp	X336e		; 336a   80 02      ..
;
X336c:	mov	r0,#3		; 336c   78 03      x.
X336e:	jnb	fet_an,X3349	; 336e   30 95 d8   0.X
	lcall	x2df9_zero_cross_x0		; 3371   12 2d f9   .-y
	jnb	zc_point,X336c	; 3374   30 09 f5   0.u
	djnz	r0,X336e	; 3377   d8 f5      Xu
	ljmp	X345c		; 3379   02 34 5c   .4\
;
X337c:	lcall	x2cd9_feedback_b		; 337c   12 2c d9   .,Y
	mov	r0,#3		; 337f   78 03      x.
	jb	fet_an,X339f	; 3381   20 95 1b    ..
X3384:	lcall	X3228		; 3384   12 32 28   .2(
	sjmp	X338b		; 3387   80 02      ..
;
X3389:	mov	r0,#3		; 3389   78 03      x.
X338b:	jb	fet_an,X339f	; 338b   20 95 11    ..
	lcall	x2e34_zero_cross_i0		; 338e   12 2e 34   ..4
	jnb	fb_adc_timeout,X3397	; 3391   30 05 03   0..
	ljmp	X3238		; 3394   02 32 38   .28
;
X3397:	jb	zc_point,X3389	; 3397   20 09 ef    .o
	djnz	r0,X338b	; 339a   d8 ef      Xo
	ljmp	X345c		; 339c   02 34 5c   .4\
;
X339f:	lcall	X3228		; 339f   12 32 28   .2(
	sjmp	X33a6		; 33a2   80 02      ..
;
X33a4:	mov	r0,#3		; 33a4   78 03      x.
X33a6:	jnb	fet_an,X3384	; 33a6   30 95 db   0.[
	lcall	x2e34_zero_cross_i0		; 33a9   12 2e 34   ..4
	jb	zc_point,X33a4	; 33ac   20 09 f5    .u
	djnz	r0,X33a6	; 33af   d8 f5      Xu
	ljmp	X345c		; 33b1   02 34 5c   .4\
;
X33b4:	lcall	x2ce3_feedback_a		; 33b4   12 2c e3   .,c
	mov	r0,#3		; 33b7   78 03      x.
	jb	fet_bn,X33d7	; 33b9   20 92 1b    ..
X33bc:	lcall	X3228		; 33bc   12 32 28   .2(
	sjmp	X33c3		; 33bf   80 02      ..
;
X33c1:	mov	r0,#3		; 33c1   78 03      x.
X33c3:	jb	fet_bn,X33d7	; 33c3   20 92 11    ..
	lcall	x2df9_zero_cross_x0		; 33c6   12 2d f9   .-y
	jnb	fb_adc_timeout,X33cf	; 33c9   30 05 03   0..
	ljmp	X3238		; 33cc   02 32 38   .28
;
X33cf:	jnb	zc_point,X33c1	; 33cf   30 09 ef   0.o
	djnz	r0,X33c3	; 33d2   d8 ef      Xo
	ljmp	X345c		; 33d4   02 34 5c   .4\
;
X33d7:	lcall	X3228		; 33d7   12 32 28   .2(
	sjmp	X33de		; 33da   80 02      ..
;
X33dc:	mov	r0,#3		; 33dc   78 03      x.
X33de:	jnb	fet_bn,X33bc	; 33de   30 92 db   0.[
	lcall	x2df9_zero_cross_x0		; 33e1   12 2d f9   .-y
	jnb	zc_point,X33dc	; 33e4   30 09 f5   0.u
	djnz	r0,X33de	; 33e7   d8 f5      Xu
	ljmp	X345c		; 33e9   02 34 5c   .4\
;
X33ec:	lcall	x2cde_feedback_c		; 33ec   12 2c de   .,^
	mov	r0,#3		; 33ef   78 03      x.
	jb	fet_bn,X340f	; 33f1   20 92 1b    ..
X33f4:	lcall	X3228		; 33f4   12 32 28   .2(
	sjmp	X33fb		; 33f7   80 02      ..
;
X33f9:	mov	r0,#3		; 33f9   78 03      x.
X33fb:	jb	fet_bn,X340f	; 33fb   20 92 11    ..
	lcall	x2e34_zero_cross_i0		; 33fe   12 2e 34   ..4
	jnb	fb_adc_timeout,X3407	; 3401   30 05 03   0..
	ljmp	X3238		; 3404   02 32 38   .28
;
X3407:	jb	zc_point,X33f9	; 3407   20 09 ef    .o
	djnz	r0,X33fb	; 340a   d8 ef      Xo
	ljmp	X345c		; 340c   02 34 5c   .4\
;
X340f:	lcall	X3228		; 340f   12 32 28   .2(
	sjmp	X3416		; 3412   80 02      ..
;
X3414:	mov	r0,#3		; 3414   78 03      x.
X3416:	jnb	fet_bn,X33f4	; 3416   30 92 db   0.[
	lcall	x2e34_zero_cross_i0		; 3419   12 2e 34   ..4
	jb	zc_point,X3414	; 341c   20 09 f5    .u
	djnz	r0,X3416	; 341f   d8 f5      Xu
	ljmp	X345c		; 3421   02 34 5c   .4\
;
X3424:	lcall	x2cd9_feedback_b		; 3424   12 2c d9   .,Y
	mov	r0,#3		; 3427   78 03      x.
	jb	fet_cn,X3447	; 3429   20 91 1b    ..
X342c:	lcall	X3228		; 342c   12 32 28   .2(
	sjmp	X3433		; 342f   80 02      ..
;
X3431:	mov	r0,#3		; 3431   78 03      x.
X3433:	jb	fet_cn,X3447	; 3433   20 91 11    ..
	lcall	x2df9_zero_cross_x0		; 3436   12 2d f9   .-y
	jnb	fb_adc_timeout,X343f	; 3439   30 05 03   0..
	ljmp	X3238		; 343c   02 32 38   .28
;
X343f:	jnb	zc_point,X3431	; 343f   30 09 ef   0.o
	djnz	r0,X3433	; 3442   d8 ef      Xo
	ljmp	X345c		; 3444   02 34 5c   .4\
;
X3447:	lcall	X3228		; 3447   12 32 28   .2(
	sjmp	X344e		; 344a   80 02      ..
;
X344c:	mov	r0,#3		; 344c   78 03      x.
X344e:	jnb	fet_cn,X342c	; 344e   30 91 db   0.[
	lcall	x2df9_zero_cross_x0		; 3451   12 2d f9   .-y
	jnb	zc_point,X344c	; 3454   30 09 f5   0.u
	djnz	r0,X344e	; 3457   d8 f5      Xu
	ljmp	X345c		; 3459   02 34 5c   .4\
;
X345c:	mov	r4,TMR2L		; 345c   ac cc      ,L
	mov	r3,TMR2H		; 345e   ab cd      +M
	jnb	TMR2CN.7,x3466_zc_happen	; 3460   30 cf 03   0O.
	;ljmp	break_point
	ljmp	X3238		; 3463   02 32 38   .28
;
x3466_zc_happen:	lcall	x2808_t2_reset		; 3466   12 28 08   .(.
	mov	a,r4		; 3469   ec         l
	clr	c		; 346a   c3         C
	addc	a,r6		; 346b   3e         >
	mov	r0,a		; 346c   f8         x
	mov	a,r3		; 346d   eb         k
	addc	a,r5		; 346e   3d         =
	rrc	a		; 346f   13         .
	mov	r5,a		; 3470   fd         }
	mov	a,r0		; 3471   e8         h
	rrc	a		; 3472   13         .
	mov	r6,a		; 3473   fe         ~
	mov	4dh,r6		; 3474   8e 4d      .M
	mov	4eh,r5		; 3476   8d 4e      .N
	mov	a,r5		; 3478   ed         m
	mov	r0,a		; 3479   f8         x
	mov	a,r6		; 347a   ee         n
	mov	r1,a		; 347b   f9         y
	mov	37h,#3		; 347c   75 37 03   u7.
X347f:	clr	c		; 347f   c3         C
	mov	a,r0		; 3480   e8         h
	rrc	a		; 3481   13         .
	mov	r0,a		; 3482   f8         x
	mov	a,r1		; 3483   e9         i
	rrc	a		; 3484   13         .
	mov	r1,a		; 3485   f9         y
	djnz	37h,X347f	; 3486   d5 37 f6   U7v
	mov	a,r1		; 3489   e9         i
	mov	b,68h		; 348a   85 68 f0   .hp
	mul	ab		; 348d   a4         $
	mov	r1,a		; 348e   f9         y
	mov	38h,b		; 348f   85 f0 38   .p8
	mov	a,r0		; 3492   e8         h
	mov	b,68h		; 3493   85 68 f0   .hp
	mul	ab		; 3496   a4         $
	add	a,38h		; 3497   25 38      %8
	mov		r0,a		; 3499   f8         x
	clr		c		; 349a   c3         C
	mov		a,r6		; 349b   ee         n
	subb	a,r1		; 349c   99         .
	mov		r6,a		; 349d   fe         ~
	mov		a,r5		; 349e   ed         m
	subb	a,r0		; 349f   98         .
	mov		r5,a		; 34a0   fd         }
	jnb		rcp_t0_ready,X34ad	; 34a1   30 00 09   0..
	lcall	x2e69_verify_rcp		; 34a4   12 2e 69   ..i
	jnb		stay_idle,X34ad	; 34a7   30 01 03   0..
	ljmp	x25a3_control_start		; 34aa   02 25 a3   .%#
;
X34ad:
	mov		a,TMR2H		; 34ad   e5 cd      eM
	clr		c		; 34af   c3         C
	subb	a,r5		; 34b0   9d         .
	jc		X34ad		; 34b1   40 fa      @z
X34b3:
	mov		a,TMR2L		; 34b3   e5 cc      eL
	clr		c		; 34b5   c3         C
	subb	a,r6		; 34b6   9e         .
	jc		X34b3		; 34b7   40 fa      @z
	ljmp	x3273_state_start		; 34b9   02 32 73   .2s


flash_red_3:
	lcall	flash_red
flash_red_2:
	acall	flash_red
flash_red:
	clr		green_led
	setb	red_led
	mov		r2,#10h
	lcall	x24e9_set_pwm0_duty
	mov		P0SKIP,#0ffh
	mov		P1SKIP,#0fdh
	setb	fet_bp
	lcall	x31d1_delay_5_2
	clr		red_led
	lcall	X2561_all_fet_off
	lcall	x31ce_delay_5_3
	ret


;
;	org	PACK_DATA_ADDR
;X3600:
;	mov	r7,a		; 3600   ff         .
	db 0ffh
;	org	3680h
;
;X3680:	nop			; 3680   00         .

;	org 3690h
;db	68h,6fh,62h,62h,79h,77h,69h,6eh,67h,2eh,63h,6fh,6dh,2eh,63h,6eh		;hobbywing.com.cn
;db "0123456789abcdef"
;X36a0:
;db	02h,07h,05h,08h,03h,03h,03h,02h,07h,01h,01h,03h,03h,03h,03h,55h		;...............U
;db	2,0bh
;	org	36c0h
;db	00h,01h,01h,00h,00h,00h,00h,00h,00h,00h,00h
;	org	36d0h
X36d0:
db	02h,08h,06h,08h,03h,03h,03h,02h,07h,00h,01h,03h,03h,03h,03h,55h		;...............U
;	org X36d0+12h
;	db 0,0,0,2fh
;	org X36d0+32h
;	db 0,0ffh,0
;	org	X36d0+50h
x3720_default_rcp_value:
db 80h,0fh,41h,0ch,0b0h,09h

;	org	372fh
;db	55h
;X3730:	nop			; 3730   00         .
;	org 3740h
;db 00h,70h,72h,6fh,66h,69h,6ch,65h,5fh,6fh,6eh,5fh,72h,6fh,61h,64h		;.profile_on_road
;db "0123456789abcdef"
;	org	3750h
;
;X3750:
;db 01h,02h,00h,06h,03h,01h,00h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
;	org 3762h
;	db 00h,33h,00h,54h
;	org 3780h
;db 01h,70h,72h,6fh,66h,69h,6ch,65h,5fh,6fh,66h,66h,72h,6fh,61h,64h		;.profile_offroad
;	org	3790h
;X3790:
;db 01h,01h,00h,03h,03h,01h,01h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
;	org 37a2h
;	db 00h,33h,00h,54h
;	org 37c0h
db 02h,70h,72h,6fh,66h,69h,6ch,65h,5fh,63h,72h,61h,77h,6ch,65h,72h		;.profile_crawler
;	org	37d0h
X37d0:
db 02h,07h,00h,04h,03h,01h,01h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
;	org 37e2h
;	db 00h,33h,00h,54h
;

	org	PACK_DATA_ADDR
; after throttle setting, bellow values were put into program code
; e6 0f 62 0c 9b 08
; 3950  3170  2203
X3800:
	db 80h,0fh,41h,0ch,0b0h,09h
	org PACK_DATA_ADDR+0fh
	db 55h
	org	PACK_DATA_ADDR+10h
;
;X3810:	nop			; 3810   00         .
X3810:
	db	0
	org PACK_DATA_ADDR+20h
db	00h,70h,72h,6fh,66h,69h,6ch,65h,5fh,6fh,6eh,5fh,72h,6fh,61h,64h		;.profile_on_road
X3830:
db 01h,02h,00h,06h,03h,01h,00h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
X3840:
db 0ffh,0ffh,00h,33h,00h,54h
org	PACK_DATA_ADDR+060h
db 01h,70h,72h,6fh,66h,69h,6ch,65h,5fh,6fh,66h,66h,72h,6fh,61h,64h		;.profile_offroad
X3870:
db 01h,01h,00h,03h,03h,01h,01h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
X3880:
db 0ffh,0ffh,00h,33h,00h,54h
org PACK_DATA_ADDR+0a0h
db 02h,70h,72h,6fh,66h,69h,6ch,65h,5fh,63h,72h,61h,77h,6ch,65h,72h		;.profile_crawler
	org	PACK_DATA_ADDR+0b0h
X38b0:
db 02h,07h,00h,04h,03h,01h,01h,01h,04h,00h,00h,00h,00h,00h,00h,09h		;................
X38c0:
db 0ffh,0ffh,00h,33h,00h,54h
org PACK_DATA_ADDR+0e0h
;db "hobbywing.com.cn"
;db "hobbywing.com.cn"
;db "0123456789abcdef"
;db "0123456789abcdef"
org	PACK_DATA_ADDR+100h
X3900:
org	PACK_DATA_ADDR+1ffh
db	7fh
;rept 16
;db "hobbywing.com.cn"
;db "0123456789abcdef"
;endm
;org	PACK_DATA_ADDR+200h
;X3a00:
;org	PACK_DATA_ADDR+300h
;X3b00:
;rept 32
;db "hobbywing.com.cn"
;db "0123456789abcdef"
;endm
;db "HW407_V2.0      "
;db "CAR_ESC         "
;db "0123456789abcdef"
;db "0123456789abcdef"
;org	PACK_DATA_ADDR+400h
;db 0a5h,00h,0ffh,5ah,04h
X3c25:
db 0a5h,01h,0feh,5ah,04h
X3c2a:
db 0a5h,02h,0fdh,5ah,04h
X3c2f:
db 0a5h,3,0fch,5ah,4
;	org	3c34h
;
X3c34:
	clr		ea		; 3c34   c2 af      B/
	mov		sp,#0cfh	; 3c36   75 81 cf   u.O
	mov		psw,#0		; 3c39   75 d0 00   uP.
	; set Internal oscillator
	; OSCICN [IOSCEN|IFRDY|SUSPEND|STSYNC|-|-|IFCN1|IFCN0]
	; IOSCEN 1:Internal High-Frequency Oscillator enabled
	; IFCN[1:0] 01:SYSCLK DERIVED FROM INTERNAL H-F OSCILLATOR divided by 4
	mov		OSCICN,#81h	; 3c3c   75 b2 81   u2.
	; SET oscillator source
	mov		CLKSEL,#0		; 3c3f   75 a9 00   u).

	; set Vdd Monitor Contorl
	mov		VDM0CN,#80h		; 3c42   75 ff 80   u..
	; TURN OFF WATCHDOG
	; PCA0MD[CIDL|WDTE|WDLCK|-|CPS2|CPS1+CPS-|ECF]
	; WDTE was set to 0
	anl		PCA0MD,#0bfh	; 3c45   53 d9 bf   SY?
	acall	x3d6b_pin_init		; 3c48   b1 6b      1k
	acall	x3d6b_pin_init		; 3c4a   b1 6b      1k
	clr		ea		; 3c4c   c2 af      B/

;	3680h+0保存了0，因此直接跳X0230
	ljmp	X0230
if PACK=0
	mov		a,#0		; 3c4e   74 00      t.
	mov		dptr,#X3680	; 3c50   90 36 80   .6.
	movc	a,@a+dptr	; 3c53   93         .
	mov		rb3r7,a		; 3c54   f5 1f      u.
	clr		c		; 3c56   c3         C
	subb	a,#4		; 3c57   94 04      ..
	jc		X3c62		; 3c59   40 07      @.
	mov		rb3r7,#3	; 3c5b   75 1f 03   u..
	acall	X3caa		; 3c5e   91 aa      .*
X3c60:
	ajmp	X3c71		; 3c60   81 71      .q

X3c62:
	mov		a,rb3r7		; 3c62   e5 1f      e.
	mov		dptr,#X3c69	; 3c64   90 3c 69   .<i
	rl		a		; 3c67   23         #
	jmp		@a+dptr		; 3c68   73         s

X3c69:
	ajmp	X3c76		; 3c69   81 76      .v
	ajmp	X3c71		; 3c6b   81 71      .q
	ajmp	X3c79		; 3c6d   81 79      .y
	ajmp	X3c71		; 3c6f   81 71      .q
X3c71:
	setb	25h.1		; 3c71   d2 29      R)
	ljmp	X022d		; 3c73   02 02 2d   ..-
X3c76:
	ljmp	X0230		; 3c76   02 02 30   ..0
X3c79:
	clr		ea		; 3c79   c2 af      B/
	mov		dptr,#X1c00	; 3c7b   90 1c 00   ...
	mov	r3,dph		; 3c7e   ab 83      +.
	mov	r2,dpl		; 3c80   aa 82      *.
	mov	dptr,#X0200	; 3c82   90 02 00   ...
	mov	r5,dph		; 3c85   ad 83      -.
	mov	r4,dpl		; 3c87   ac 82      ,.
X3c89:	mov	dpl,r4		; 3c89   8c 82      ..
	mov	dph,r5		; 3c8b   8d 83      ..
	acall	x3d13_ps_erase0		; 3c8d   b1 13      1.
	acall	X3ce3		; 3c8f   91 e3      .c
	acall	X3ce3		; 3c91   91 e3      .c
	mov	r7,#1bh		; 3c93   7f 1b      ..
	mov	r6,#0ffh	; 3c95   7e ff      ~.
	clr	c		; 3c97   c3         C
	mov	a,r6		; 3c98   ee         n
	subb	a,dpl		; 3c99   95 82      ..
	mov	a,r7		; 3c9b   ef         o
	subb	a,dph		; 3c9c   95 83      ..
	jc	X3ca2		; 3c9e   40 02      @.
	ajmp	X3c89		; 3ca0   81 89      ..
;
X3ca2:	mov	rb3r7,#3	; 3ca2   75 1f 03   u..
	acall	X3caa		; 3ca5   91 aa      .*
	ljmp	X0000		; 3ca7   02 00 00   ...

;
X3caa:	push	rb0r2		; 3caa   c0 02      @.
	push	rb0r3		; 3cac   c0 03      @.
	push	rb0r4		; 3cae   c0 04      @.
	push	rb0r5		; 3cb0   c0 05      @.
	mov	dptr,#X3600	; 3cb2   90 36 00   .6.
	mov	r2,dpl		; 3cb5   aa 82      *.
	mov	r3,dph		; 3cb7   ab 83      +.
	mov	dptr,#X3a00	; 3cb9   90 3a 00   .:.
	mov	r4,dpl		; 3cbc   ac 82      ,.
	mov	r5,dph		; 3cbe   ad 83      -.
	acall	x3d13_ps_erase0		; 3cc0   b1 13      1.
	acall	X3ce3		; 3cc2   91 e3      .c
	acall	X3ce3		; 3cc4   91 e3      .c
	mov	dptr,#X3a00	; 3cc6   90 3a 00   .:.
	mov	r2,dpl		; 3cc9   aa 82      *.
	mov	r3,dph		; 3ccb   ab 83      +.
	mov	dptr,#X3600	; 3ccd   90 36 00   .6.
	mov	r4,dpl		; 3cd0   ac 82      ,.
	mov	r5,dph		; 3cd2   ad 83      -.
	acall	x3d13_ps_erase0		; 3cd4   b1 13      1.
	acall	X3ce3		; 3cd6   91 e3      .c
	acall	X3ce3		; 3cd8   91 e3      .c
	pop	rb0r5		; 3cda   d0 05      P.
	pop	rb0r4		; 3cdc   d0 04      P.
	pop	rb0r3		; 3cde   d0 03      P.
	pop	rb0r2		; 3ce0   d0 02      P.
	ret			; 3ce2   22         "
;
X3ce3:	mov	r7,#0		; 3ce3   7f 00      ..
X3ce5:	mov	dpl,r2		; 3ce5   8a 82      ..
	mov	dph,r3		; 3ce7   8b 83      ..
	mov	a,#0		; 3ce9   74 00      t.
	movc	a,@a+dptr	; 3ceb   93         .
	mov	r0,a		; 3cec   f8         x
	cjne	r2,#80h,X3cf5	; 3ced   ba 80 05   :..
	cjne	r3,#36h,X3cf5	; 3cf0   bb 36 02   ;6.
	mov	r0,rb3r7	; 3cf3   a8 1f      (.
X3cf5:	inc	dptr		; 3cf5   a3         #
	mov	r2,dpl		; 3cf6   aa 82      *.
	mov	r3,dph		; 3cf8   ab 83      +.
	mov	dpl,r4		; 3cfa   8c 82      ..
	mov	dph,r5		; 3cfc   8d 83      ..
	acall	x3d1d_write_byte		; 3cfe   b1 1d      1.
	inc	dptr		; 3d00   a3         #
	mov	r4,dpl		; 3d01   ac 82      ,.
	mov	r5,dph		; 3d03   ad 83      -.
	djnz	r7,X3ce5	; 3d05   df de      _^
	ret			; 3d07   22         "
;
X3d08:	mov	r7,#0		; 3d08   7f 00      ..
X3d0a:	mov	a,#0		; 3d0a   74 00      t.
	movc	a,@a+dptr	; 3d0c   93         .
	movx	@r0,a		; 3d0d   f2         r
	inc	dptr		; 3d0e   a3         #
	inc	r0		; 3d0f   08         .
	djnz	r7,X3d0a	; 3d10   df f8      _x
	ret			; 3d12   22         "
;
x3d13_ps_erase0:	setb	ps_erase		; 3d13   d2 2b      R+
	ajmp	X3d21		; 3d15   a1 21      !!
;
x3d17_ps_write:	clr	skip_check_btn		; 3d17   c2 2c      B,
	clr	ps_erase		; 3d19   c2 2b      B+
	ajmp	X3d21		; 3d1b   a1 21      !!
;
x3d1d_write_byte:	setb	skip_check_btn		; 3d1d   d2 2c      R,
	clr	ps_erase		; 3d1f   c2 2b      B+
X3d21:
	mov		c,ea		; 3d21   a2 af      "/
	mov		ea_save,c		; 3d23   92 2a      .*
	clr		ea		; 3d25   c2 af      B/
	mov		VDM0CN,#80h		; 3d27   75 ff 80   u..
	mov		RSTSRC,#2		; 3d2a   75 ef 02   uo.
	mov		FLKEY,#0a5h	; 3d2d   75 b7 a5   u7%
	mov		FLKEY,#0f1h	; 3d30   75 b7 f1   u7q
	jnb		ps_erase,X3d3e	; 3d33   30 2b 08   0+.
	mov		PSCTL,#3		; 3d36   75 8f 03   u..
	mov		a,#0		; 3d39   74 00      t.
	movx	@dptr,a		; 3d3b   f0         p
	ajmp	X3d47		; 3d3c   a1 47      !G
;
X3d3e:	mov	PSCTL,#1		; 3d3e   75 8f 01   u..
	movx	a,@r0		; 3d41   e2         b
	jnb	skip_check_btn,X3d46	; 3d42   30 2c 01   0,.
	mov	a,r0		; 3d45   e8         h
X3d46:	movx	@dptr,a		; 3d46   f0         p
X3d47:	mov	PSCTL,#0		; 3d47   75 8f 00   u..
	mov	c,ea_save		; 3d4a   a2 2a      "*
	mov	ea,c		; 3d4c   92 af      ./
	jb	ps_erase,X3d53	; 3d4e   20 2b 02    +.
	acall	X3d54		; 3d51   b1 54      1T
X3d53:	ret			; 3d53   22         "
;
X3d54:	mov	b,a		; 3d54   f5 f0      up
	mov	a,#0		; 3d56   74 00      t.
	movc	a,@a+dptr	; 3d58   93         .
	cjne	a,b,X3d5e	; 3d59   b5 f0 02   5p.
	ajmp	X3d61		; 3d5c   a1 61      !a
; write program store failed, jump reset
X3d5e:	ljmp	X007b		; 3d5e   02 00 7b   ..{
;
X3d61:	ret			; 3d61   22         "
;
X3d62:	mov	r7,#0		; 3d62   7f 00      ..
X3d64:	acall	x3d17_ps_write		; 3d64   b1 17      1.
	inc	dptr		; 3d66   a3         #
	inc	r0		; 3d67   08         .
	djnz	r7,X3d64	; 3d68   df fa      _z
	ret			; 3d6a   22         "
;
endif

x3d6b_pin_init:
	mov		P0MDIN,#01110000b	; 3d6b   75 f1 70   uqp
	mov		P0MDOUT,#0efh	; 3d6e   75 a4 ef   u$o
	mov		p0,#0bfh	; 3d71   75 80 bf   u.?
	mov		P1MDIN,#7fh	; 3d74   75 f2 7f   ur.
	mov		P1MDOUT,#0ffh	; 3d77   75 a5 ff   u%.
	mov		p1,#0a6h	; 3d7a   75 90 a6   u.&
	mov		P2MDOUT,#0ffh	; 3d7d   75 a6 ff   u&.
	mov		p2,#1		; 3d80   75 a0 01   u .
;	mov		P0SKIP,#0cfh	; 3d83   75 d4 cf   uTO
	mov		P1SKIP,#0fdh	; 3d86   75 d5 fd   uU}
	mov		XBR0,#1		; 3d89   75 e1 01   ua.
	mov		XBR1,#0c1h	; 3d8c   75 e2 c1   ubA
	ret			; 3d8f   22         "
if	PACK=0
;
x3d90_dptr_plus_r5r4:	mov	a,r4		; 3d90   ec         l
	add	a,dpl		; 3d91   25 82      %.
	mov	dpl,a		; 3d93   f5 82      u.
	mov	a,r5		; 3d95   ed         m
	addc	a,dph		; 3d96   35 83      5.
	mov	dph,a		; 3d98   f5 83      u.
	inc	r0		; 3d9a   08         .
	ret			; 3d9b   22         "
; dptr=r3r2 x 10h
x3d9c_dptr_r3r2x10h:	mov	r7,#10h		; 3d9c   7f 10      ..
	mov	a,r2		; 3d9e   ea         j
	mov	b,r7		; 3d9f   8f f0      .p
	mul	ab		; 3da1   a4         $
	mov	dpl,a		; 3da2   f5 82      u.
	mov	dph,b		; 3da4   85 f0 83   .p.
	mov	a,r3		; 3da7   eb         k
	mov	b,r7		; 3da8   8f f0      .p
	mul	ab		; 3daa   a4         $
	add	a,dph		; 3dab   25 83      %.
	mov	dph,a		; 3dad   f5 83      u.
	ret			; 3daf   22         "
;
X3db0:	mov	a,#0		; 3db0   74 00      t.
	movc	a,@a+dptr	; 3db2   93         .
	mov	@r0,a		; 3db3   f6         v
	inc	dptr		; 3db4   a3         #
	inc	r0		; 3db5   08         .
	djnz	r7,X3db0	; 3db6   df f8      _x
	ret			; 3db8   22         "
;
x3db9_load_from_xram:	movx	a,@dptr		; 3db9   e0         `
	mov	@r0,a		; 3dba   f6         v
	inc	dptr		; 3dbb   a3         #
	inc	r0		; 3dbc   08         .
	djnz	r7,x3db9_load_from_xram	; 3dbd   df fa      _z
	ret			; 3dbf   22         "
endif
;org 3dffh
;db 0e1h
;
	end
;

