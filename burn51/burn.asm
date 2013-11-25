$include(c8051f336.inc)
; 1s = 1,000,000,000ns
;  Trd > 20000ns = 503 clock 24Mh/1
;  Tsd > 2000ns  = 50
;  Tcl > 20ns    < 1 clock
;  Tch > 20ns
C2D			equ	5
C2CK		equ	2
p_c2		equ	p1
p_c2d		bit p_c2.C2D
p_c2ck		bit	p_c2.C2CK
C2_MDIN		equ	P1MDIN
C2_MDOUT	equ	P1MDOUT


outready	equ	0
inbusy		equ 1

green_led	bit p1.3
red_led		bit	p1.4
;wait_timeout	bit 20h.0

LED_MDIN	equ	P1MDIN
LED_MDOUT	equ	P1MDOUT

;memory define

temp1		equ	30h
temp2		equ	31h
temp3		equ	32h
;wait_count	equ	33h


strobe_c2ck	macro
	setb	p_c2ck
	clr		p_c2ck
	clr		p_c2ck
	setb	p_c2ck
	setb	p_c2ck
	setb	p_c2ck
endm

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


	cseg	at 0
;
	ljmp	start

org 7bh

start:
	clr		ea
	mov		sp,#0cfh
	mov		psw,#0


	acall	init
	acall	init_led
	acall	init_c2
	acall	init_final

	lcall	long_long_delay
	
	clr		red_led
;	clr		green_led

	acall	c2_reset
	lcall	read_id
;	mov		r2,#1
;	acall	c2_addr_write
;	acall	delay_20ns
	acall	test_read_id_4time
;	acall	test_pi_status
	
;	lcall	test_first_read

	lcall	long_long_delay
;	lcall	c2_reset
label_1:
	cpl		green_led
	acall	long_long_delay
	sjmp	label_1

break_point:
has_error:
	cpl		red_led
	acall	long_long_delay
	sjmp	break_point

test_pi_status:
	mov		r2,#2
	acall	c2_addr_write

	mov		r2,#0b4h
	acall	c2_data_write

	acall	c2_data_read
	mov		a,r2
	mov		r0,#0
	movx	@r0,a


	
	

	ret
test_read_id_4time:
;	mov		r2,#0
;	lcall	c2_addr_write

	lcall	c2_addr_read
	mov		a,r2
	mov		r0,#0				;0
	movx	@r0,a

	mov		r2,#0
	lcall	c2_addr_write
;	lcall	c2_data_write
	lcall	c2_data_read
	mov		a,r2
	mov		r0,#1				;1
	movx	@r0,a

	mov		r2,#1
	lcall	c2_addr_write
	lcall	c2_data_read
	mov		a,r2
	mov		r0,#2				;2
	movx	@r0,a
	
	
	mov		r2,#2
	lcall	c2_data_write
	mov		r2,#0b4h
	lcall	c2_data_write

	lcall	c2_data_read
	mov		a,r2
	mov		r0,#3				;3
	movx	@r0,a
	
	mov		r2,#0b4h
	acall	c2_addr_write

	acall	c2_data_read
	mov		a,r2
	mov		r0,#4				;4
	movx	@r0,a


	mov		r2,#0
	acall	c2_addr_write
	acall	c2_data_read
	mov		a,r2
	mov		r0,#5
	movx	@r0,a


	ret

pi_delay:
	mov		temp3,#4
	sjmp	lld_1
long_long_delay:
	mov		temp3,#16
lld_1:
	lcall	long_delay
	djnz	temp3,lld_1

long_delay:
	mov		temp2,#0
ld_1:
	lcall	delay
	djnz	temp2,ld_1
delay:
	mov		temp1,#0
	djnz	temp1,$
	ret
init:
	; set Internal oscillator
	; OSCICN [IOSCEN|IFRDY|SUSPEND|STSYNC|-|-|IFCN1|IFCN0]
	; IOSCEN 1:Internal High-Frequency Oscillator enabled
	; IFCN[1:0] 11:SYSCLK DERIVED FROM INTERNAL H-F OSCILLATOR divided by 1
	mov		OSCICN,#83h	; 3c3c   75 b2 81   u2.
	; SET oscillator source, use internal H-F Oscilator
	mov		CLKSEL,#0		; 3c3f   75 a9 00   u).

	; set Vdd Monitor Contorl
	mov		VDM0CN,#80h		; 3c42   75 ff 80   u..
	; TURN OFF WATCHDOG
	; PCA0MD[CIDL|WDTE|WDLCK|-|CPS2|CPS1+CPS-|ECF]
	; WDTE was set to 0
	anl		PCA0MD,#0bfh	; 3c45   53 d9 bf   SY?


	mov		a,#0ffh
	mov		P0SKIP,a
	mov		P1SKIP,a
	mov		P2SKIP,a
	
	mov		a,#0
	mov		r0,a
init_1:
	movx	@r0,a
	djnz	r0,init_1
	ret
init_final:
	mov		XBR0,#0				; disable UART0
	mov		XBR1,#40h			; enable Crossbar and weak pull-ups
	ret
init_led:
	mov		a,LED_MDIN
	setb	acc.3
	setb	acc.4
	mov		LED_MDIN,a
	mov		a,LED_MDOUT
	setb	acc.3
	setb	acc.4
	mov		LED_MDOUT,a
	ret
init_c2:
	mov		a,C2_MDIN
	setb	acc.C2D
	setb	acc.C2CK
	mov		C2_MDIN,a
	mov		a,C2_MDOUT
	clr		acc.C2D
;	setb	acc.C2D
	setb	acc.C2CK
	mov		C2_MDOUT,a
	setb	p_c2ck
	ret
	
read_id:

	lcall	c2_data_read
	mov		r0,#0ffh
	mov		a,r2
	movx	@r0,a
	ret
c2_reset:
	clr		p_c2ck
	lcall	delay_20000ns
	setb	p_c2ck		; reset
	lcall	delay_2000ns
	ret
; [in] r2  data
c2_addr_write:
	strobe_c2ck			;start field
	
	setb	p_c2d		; ins 11
	strobe_c2ck
	strobe_c2ck

	mov		a,r2
	mov		c,acc.0
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.1
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.2
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.3
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.4
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.5
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.6
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.7
	mov		p_c2d,c
	strobe_c2ck
	
	setb	p_c2d
	strobe_c2ck			; stop
	
	ret
; [in] r2
c2_data_write:
	strobe_c2ck			; start
	
	setb	p_c2d		; ins 01
	strobe_c2ck
	clr		p_c2d
	strobe_c2ck

;	clr		p_c2d		; length 00
	strobe_c2ck
;	clr		p_c2d
	strobe_c2ck

	mov		a,r2

	mov		c,acc.0
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.1
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.2
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.3
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.4
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.5
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.6
	mov		p_c2d,c
	strobe_c2ck

	mov		c,acc.7
	mov		p_c2d,c
	strobe_c2ck
	
	setb	p_c2d		;wait
	
dw_wait:
	strobe_c2ck
	jnb		p_c2d,dw_wait
	
	strobe_c2ck			; stop field
	ret

	
; [out] r2
c2_addr_read:
	strobe_c2ck			; start field
	
	clr		p_c2d		; ins 10
	strobe_c2ck
	setb	p_c2d
	strobe_c2ck
	
;	setb	p_c2d		; set 1 for C2D for input
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.0,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.1,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.2,c
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.3,c
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.4,c
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.5,c
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.6,c
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.7,c
	mov		r2,a
	strobe_c2ck			; stop field
	ret


c2_data_read:
;	clr		wait_timeout
	strobe_c2ck			; start field

	clr		p_c2d		; ins 00
	strobe_c2ck
;	clr		p_c2d		; ins 00
	strobe_c2ck
	
;	clr		p_c2d		; 00 for length
	strobe_c2ck
;	clr		p_c2d
	strobe_c2ck



	setb	p_c2d			; set 1 for C2D for input
;	lcall	delay_1000ns
dr_wait:
	strobe_c2ck
	jnb		p_c2d,dr_wait
	
	strobe_c2ck
	mov		c,p_c2d
	mov		acc.0,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.1,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.2,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.3,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.4,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.5,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.6,c

	strobe_c2ck
	mov		c,p_c2d
	mov		acc.7,c

	mov		r2,a
	
	strobe_c2ck			; stop

	ret
;delay_pi:
;	lcall	long_delay
;	ljmp	long_delay

delay_20000ns:
	mov		temp1,#0ffh
d20_1:
	nop
	nop
	djnz	temp1,d20_1
	ret

delay_1000ns:
	mov		temp1,#12
	sjmp	delay_l1
delay_2000ns:
	mov		temp1,#25
delay_l1:
	djnz	temp1,$
	ret
test_first_read:
	lcall	c2_reset

	mov		r2,#2				; FPCTL
	lcall	c2_addr_write
	mov		r2,#2				; enable flash programming
	lcall	c2_data_write
	mov		r2,#1
	lcall	c2_data_write
	lcall	pi_delay
	
	mov		r2,#0b4h			; FPDAT
	lcall	c2_addr_write
	mov		r2,#6				; flash read command
	lcall	write_inbusy

	lcall	read_outready
	cjne	r2,#0dh,fr_l1
	sjmp	fr_l2
fr_l1:
	ljmp	has_error
fr_l2:

	mov		r2,#0				; high byte of address
	lcall	write_inbusy


	mov		r2,#0				; low byte of address
	lcall	write_inbusy
	mov		r2,#3				; length of data
	lcall	write_inbusy

	lcall	read_outready
	mov		a,r2
	mov		r0,#0
	movx	@r0,a

	lcall	read_outready
	mov		a,r2
	mov		r0,#1
	movx	@r0,a

	lcall	read_outready
	mov		a,r2
	mov		r0,#2
	movx	@r0,a

	ret

write_inbusy:
	lcall	c2_data_write
r_inbusy:
	lcall	c2_addr_read
	mov		a,r2
	jb		acc.inbusy,r_inbusy
	ret

read_outready:
; poll OutReady
	lcall	c2_addr_read
	mov		a,r2
	jnb		acc.outready,read_outready
	lcall	c2_data_read
	ret

end