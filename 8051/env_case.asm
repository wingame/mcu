; 生物安全柜需求
; 考虑到时间存储的不是很合理，考虑修改成为以秒为单位的存储方式
; 有2种，1 设备启动的时间，2 系统时钟，用于任务的运行安排
; 在进行修改之前做一个提交保存进度
; 提交之后发现，存储时间的方式改变并没有使代码复杂程度降低。放弃


; 2013-11-11
; 经讨论，业务调整



; 加压，进出风扇同时加功率
; 减压，进风扇不变，出风扇加功率，


; 函数描述:
; c_tft_cmd 执行flash中的tft命令
; cputs 显示flash的字符串，中文以gbk编码
; iputs 显示xram中的文字

; 6 p1.7 fan1
; 7 fan_out
; 8 p1.5 fan2
; 9 fan2_out
; 10 p1.3 press sense 1
; 11 p1.2 press sense 2
; 12 light 照明
; 13 l2 杀菌
; 14 报警
$NOPAGING
$NOTABS

$include(c8051f336.inc)
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


; screen command code

K_PRESSURE		equ 1		; 压力
K_BLOW			equ 2		; 风量
K_LIGHT1		equ 3		; 照明
K_LIGHT2		equ 4		; 杀菌
K_CLOCK			equ 5		; 时钟
K_OK			equ 6		; 确定
K_SWITCH		equ 7		; 启动/停止
K_UP			equ 8		; UP
K_C				equ 9		; 取消
K_LEFT			equ 10		; left
K_DOWN			equ 11		; down
K_RIGHT			equ 12		; right



;green_led	bit p1.3
;red_led		bit	p1.4

H1				equ p1.1
H2				equ p1.0
BEEP			equ	p0.7
FANO2			equ p1.4
FANO1			equ p1.6

TFT_BUSY		equ p0.6


CUR_START_X		equ 380
CUR_START_Y		equ 160


temp1		equ	30h
temp2		equ	31h
temp3		equ	32h


; 0 idle
; 1 command start
; 2 command id	(include 0x78-press 0x79-release)
; 3 cc
; 4	data1
; 5	data2
; 6 33
; 7 c3
; 8 3c
buf_first		equ	33h
buf_last		equ	34h
;@f_buf_empty		bit	20h.0


xl				equ	35h
xh				equ	36h
yl				equ	37h
yh				equ	38h

; 设备启动时间
run_hour		equ	39h
run_minute		equ	3ah
run_second		equ	3bh
; 2 byte
day				equ	3ch		;3dh
; 内部时钟的计数器，每次算到8就是1秒，这个设定误差巨大。需要改进
tick			equ	3eh

run_timing_idx	equ	3fh
; 当second有更新，标志设1，然后计算一次minute和hour
;@f_clock_tick	bit	20h.1



recv_cmd_idx	equ 40h
recv_cmd		equ 41h
;@f_recv_cmd_ready	bit	20h.2


; 系统时钟
tm_hour			equ 42h
tm_minute		equ 43h
tm_second		equ 44h

; 入风电机开始转动延时计数器
fan_delay		equ 45h		; 45h,46h


; task start timing
;task_start_h	equ 45h
;task_start_m	equ 46h
;task_start_s	equ 47h

; task end timing
;task_end_h		equ 48h
;task_end_m		equ 49h
;task_end_s		equ 4ah

;输入框的光标位置,0~11, 0~5 开始时间， 6~11 结束时间
cursor_idx		equ 4bh



; bit definition
f_buf_empty		bit	20h.0
f_clock_tick		bit	20h.1
f_recv_cmd_ready	bit	20h.2

f_fans_running	bit 20h.3
f_fans_startup	bit 20h.4

;flag_func		equ 21h
;func_halt_b	bit flag_func.0
;func_setting_b	bit flag_func.1

; debug flag
f_debug			bit 2fh.0

; uart buffer definition
PIPO_TOP		equ 0d0h
PIPO_BUTTON		equ	0c0h





	cseg	at 0
;
	ljmp	start
org 0bh
	push	acc
	sjmp	t0overflow_int
org 23h
	ljmp	uart0_int
org 7bh
t0overflow_int:
	inc		tick
	mov		a,tick
	cjne	a,#7,t0ovf_1
; 重新设置tl时需要先停止时钟，根据336的PDF 182页的文档,倒数第二段
; 8300 9小时快了30秒
; 8200 11小时快了15秒
	clr		tr0
	mov		tl0,#low(7580)
	mov		th0,#high(7580)
	setb	tr0
	sjmp	t0ovf_exit
t0ovf_1:
	cjne	a,#8,t0ovf_exit
	mov		tick,#0
	setb	f_clock_tick
; update fan_delay
	inc		fan_delay
	mov		a,fan_delay
	jnz		t0ovf_3
	inc		fan_delay+1
t0ovf_3:
; update running clock
	inc		run_second
	mov		a,run_second
	cjne	a,#60,t0ovf_2
	mov		run_second,#0
	inc		run_minute
	mov		a,run_minute
	cjne	a,#60,t0ovf_2
	mov		run_minute,#0
	inc		run_hour
	mov		a,run_hour
	cjne	a,#24,t0ovf_2
	mov		run_hour,#0
	inc		day
	mov		a,day
	jnz		t0ovf_2
	inc		day+1
; update runtime clock
t0ovf_2:
	inc		tm_second
	mov		a,tm_second
	cjne	a,#60,t0ovf_exit
	mov		tm_second,#0
	inc		tm_minute
	mov		a,tm_minute
	cjne	a,#60,t0ovf_exit
	mov		tm_minute,#0
	inc		tm_hour
	mov		a,tm_hour
	cjne	a,#24,t0ovf_exit
	mov		tm_hour,#0


t0ovf_exit:
	pop		acc
	reti



func_proc:


	mov		a,recv_cmd
	clr		c
	subb	a,#20
	jnc		next1
	mov		a,recv_cmd
	clr		c
	subb	a,#10
	mov		r0,cursor_idx
	movx	@r0,a
	jc		next1
; time input
	lcall	show_digital



	mov		a,cursor_idx
	clr		c
	subb	a,#12
	jz		next1
	inc		cursor_idx
; time input end
next1:
	ret
func_ok:

	ret
func_c:

	lcall	close_cursor
	ret

start:
	clr		ea
	mov		sp,#0cfh
	mov		psw,#0

	lcall	init
	lcall	init_timer_01
	lcall	init_port
	lcall	init_uart_02
	lcall	init_final
	lcall	long_long_delay

	clr		a
	mov		day,a
	mov		day+1,a
	mov		run_hour,a
	mov		run_second,a
	mov		run_minute,a
	mov		tick,a

; debug ----------------------------------------------
	mov		tm_hour,#18
	mov		tm_minute,#05
	mov		tm_second,#50
	
;	mov		run_hour,#23
;	mov		run_minute,#59
;	mov		run_second,#50
; debug end ------------------------------------------
	
	mov		recv_cmd_idx,a
	
;	mov		flag_func,#0
;	setb	show_sys_clock
	
;	setb	H1
;	setb	H2
;	setb	BEEP
;	setb	FANO2
	lcall	long_delay

;	lcall	read_uart
	mov		a,#PIPO_BUTTON
	mov		buf_first,a
	mov		buf_last,a
	
	lcall	long_long_delay
	lcall	long_long_delay
	mov		dptr,#set_background
	lcall	c_tft_cmd
	mov		dptr,#pic_start
	lcall	c_tft_cmd

	lcall	main_screen

;	lcall	show_pic
	setb	ea

main_loop:
	lcall	read_uart
	jb		f_buf_empty,check_clock
	lcall	parse_cmd
	jnb		f_recv_cmd_ready,check_clock
	clr		f_recv_cmd_ready

	mov		a,recv_cmd
; 启动/停止 功能
	cjne	a,#K_SWITCH,check_clock
	cpl		f_fans_running
	setb	f_fans_startup
	mov		dptr,#pic_stop
	jb		f_fans_running,mloop_1
	mov		dptr,#pic_start
mloop_1:
	lcall	c_tft_cmd

	clr		a
	clr		ea
	mov		fan_delay,a
	mov		fan_delay+1,a
	setb	ea

; 奇怪现象，这里的显示不能正常显示，但是程序绝对跑到这里的
; 可能是因为按下去的时候，tft_busy信号，导致命令显示屏命令无法传递
; 原文档的错误描述，导致使用了按下命令作为有效命令。导致屏幕显示命令
; 无法正常工作
	mov		xh,#0
	mov		xl,#165+24
	mov		yh,#0
	mov		yl,#85+33
	mov		dptr,#off
	clr		FANO2
	jnb		f_fans_running,mloop_2
	mov		dptr,#on
	setb	FANO2
mloop_2:
	lcall	cputs32

check_clock:
	jnb		f_clock_tick,main_loop
	clr		f_clock_tick

	lcall	fans_control
	lcall	show_run_clock
	lcall	show_tm_clock
	sjmp	main_loop

; 启动/停止 业务
fans_control:
	jb		f_fans_running,fans_control_1
	ret
fans_control_1:
	clr		ea
	mov		a,fan_delay
	sub
	mov		a,fan_delay+1
	setb	ea
	ret
main_screen:
; main screen
; (20,80),(550,400)
	mov		dptr,#rect1
	acall	c_tft_cmd
;	lcall	long_long_delay
	
	mov		xh,#0
	mov		xl,#24
	mov		yh,#0
	mov		yl,#85
	mov		dptr,#in_pressure
	acall	cputs32

	mov		xh,#0
	mov		xl,#24
	mov		yh,#0
	mov		yl,#85+33
	mov		dptr,#out_pressure
	acall	cputs32
; main screen end
	ret
close_cursor:
	mov		r2,#0	; cursor disable
	sjmp	cursor_sw
set_cursor:
	mov		r2,#1	; cursor enable
cursor_sw:
	mov		a,#44h	; 光标显示
	acall	send_uart
	mov		a,r2
	acall	send_uart
	mov		a,xh	; xh
	acall	send_uart
	mov		a,xl	; xl
	acall	send_uart
	mov		a,yh	; yh
	acall	send_uart
	mov		a,yl	; yl
	acall	send_uart

	mov		a,#0fh	; cursor width
	acall	send_uart
	mov		a,#0fh	; cursor hight
	acall	send_uart
	mov		a,#01h	; cursor_blink_en
	acall	send_uart
	mov		a,#80h	; blink time
	acall	send_uart
	ajmp	iputs_exit

day_conv:
	mov		a,day
	clr		c
	subb	a,#low(10000)
	mov		a,day+1
	subb	a,#high(10000)
	mov		r0,run_timing_idx

	jc		day_conv_lbl1
	mov		a,#'9'
	movx	@r0,a
	inc		r0
	movx	@r0,a
	inc		r0
	movx	@r0,a
	inc		r0
	movx	@r0,a
	ljmp	day_conv_ret
day_conv_lbl1:
	mov		r1,#0
	mov		r4,day
	mov		r5,day+1
day_conv_lbl2:
	mov		a,r4
	clr		c
	subb	a,#low(1000)
	mov		a,r5
	subb	a,#high(1000)
	jc		day_conv_lbl3
	inc		r1
	mov		a,r4
	clr		c
	subb	a,#low(1000)
	mov		r4,a
	mov		a,r5
	subb	a,#high(1000)
	mov		r5,a
	sjmp	day_conv_lbl2
day_conv_lbl3:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	mov		r1,#0
	inc		r0
dc_lbl_51:
	mov		a,r4
	clr		c
	subb	a,#100
	mov		a,r5
	subb	a,#0
	jc		dc_lbl6
	mov		a,r4
	clr		c
	subb	a,#100
	mov		r4,a
	mov		a,r5
	subb	a,#0
	mov		r5,a
	inc		r1
	sjmp	dc_lbl_51
dc_lbl6:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a

	mov		r1,#0
	inc		r0
dc_lbl9:
	mov		a,r4
	clr		c
	subb	a,#10
	jc		dc_lbl10
	mov		r4,a
	inc		r1
	sjmp	dc_lbl9
dc_lbl10:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	inc		r0
	mov		a,r4
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
day_conv_ret:
	inc		r0
	mov		run_timing_idx,r0
	ret
show_digital:
; 从输入读取的按键值转换成ASCII码保持着xram中12位移地址，以0结尾的字符串方式存放
; 然后显示出来。
	mov		r0,#12
	add		a,#30h
	movx	@r0,a
	inc		r0
	clr		a
	movx	@r0,a
	mov		r0,#12
	mov		xl,#low(CUR_START_X)
	mov		xh,#high(CUR_START_X)
	mov		yl,#low(CUR_START_Y)
	mov		yh,#high(CUR_START_Y)
	mov		a,cursor_idx
	mov		b,#13
	mul		ab
	clr		c
	addc	a,xl
	mov		xl,a
	mov		a,b
	addc	a,xh
	mov		xh,a
	lcall	iputs24

	ret
;update_tm_clock:
;	mov		a,tm_second
;	cjne	a,#60,uc_show_tm_clock
;	mov		tm_second,#0
;	inc		tm_minute
;	mov		a,tm_minute
;	cjne	a,#60,uc_show_tm_clock
;	mov		tm_minute,#0
;	inc		tm_hour
;	mov		a,tm_hour
;	cjne	a,#24,uc_show_tm_clock
;	mov		tm_hour,#0
;uc_show_tm_clock:
;	mov		a,flag_func
;	jz		uc_show_tm_clock_1
;	ret
show_tm_clock:
	mov		r0,#0
	mov		r2,tm_hour
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,tm_minute
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,tm_second
	acall	hex_bcdascii
	inc		r0
	clr		a
	movx	@r0,a
	mov		xl,#low(350)
	mov		xh,#high(350)
	mov		yl,#low(440)
	mov		yh,#high(440)
	mov		r0,#0
	lcall	iputs24
	ret
;update_run_clock:
;	mov		a,run_second
;	cjne	a,#60,uc_show_clock
;	mov		run_second,#0
;	inc		run_minute
;	mov		a,run_minute
;	cjne	a,#60,uc_show_clock
;	mov		run_minute,#0
;	inc		run_hour
;	mov		a,run_hour
;	cjne	a,#24,uc_show_clock
;	mov		run_hour,#0
;	inc		day
;	mov		a,day
;	jnz		uc_show_clock
;	inc		day+1
;uc_show_clock:
;	mov		a,flag_func
;	jz		uc_show_clock_1
;	ret
show_run_clock:
	mov		run_timing_idx,#0
	
	; 判断日期是否为0
	mov		a,day+1
	jz		skip_1
	sjmp	skip_2
skip_1:
	mov		a,day
	jz		skip_3
skip_2:
	acall	day_conv
; 0xccec = 天
	mov		a,#0cch
	movx	@r0,a
	inc		r0
	mov		a,#0ech
	movx	@r0,a
	inc		r0
	mov		run_timing_idx,r0
skip_3:
	
	mov		r0,run_timing_idx
	mov		r2,run_hour
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,run_minute
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,run_second
	acall	hex_bcdascii
	inc		r0
	clr		a
	movx	@r0,a

	mov		xl,#2
	mov		xh,#0
	mov		yl,#low(450)
	mov		yh,#high(450)
	mov		r0,#0
	lcall	iputs16
	ret

;[in] r2
;[out] @r0
hex_bcdascii:
	mov		a,r2
	mov		r5,#0
	mov		r4,a
hbcd_1:
	clr		c
	subb	a,#10
	jc		hbcd_exit
	inc		r5
	mov		r4,a
	sjmp	hbcd_1
hbcd_exit:
	mov		a,r5
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	mov		a,r4
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	inc		r0
	movx	@r0,a
	ret
cputs32:
	mov		r2,#55h
	sjmp	cputs
cputs24:
	mov		r2,#6fh
	sjmp	cputs
cputs16:
	mov		r2,#54h
; print string in flash
;[in] r2 command code 0x55 32,0x54 16, 0x6f 24
;@dptr string
cputs:
	mov		a,#0aah
	lcall	send_uart
	mov		a,r2
	lcall	send_uart
	mov		a,xh
	lcall	send_uart
	mov		a,xl
	lcall	send_uart
	mov		a,yh
	lcall	send_uart
	mov		a,yl
	lcall	send_uart
	mov		r0,#0
cputs_1:
	mov		a,r0
	movc	a,@a+dptr
	jz		iputs_exit
	acall	send_uart
	inc		r0
	sjmp	cputs_1

; iputs[xx] = 32 24 16, 在指定位置显示以0结束的字符串 字符串开始位置由r0指定
iputs32:
	mov		r2,#55h
	sjmp	iputs
iputs24:
	mov		r2,#6fh
	sjmp	iputs
iputs16:
	mov		r2,#54h
	
; print string in i-ram
;[in] r2 command code 0x55 32,0x54 16, 0x6f 24
;@r0 string
iputs:
	mov		a,#0aah
	lcall	send_uart
	mov		a,r2
	lcall	send_uart
	mov		a,xh
	lcall	send_uart
	mov		a,xl
	lcall	send_uart
	mov		a,yh
	lcall	send_uart
	mov		a,yl
	lcall	send_uart
iputs_lbl1:
	movx	a,@r0
	jz		iputs_exit
	lcall	send_uart
	inc		r0
	sjmp	iputs_lbl1
iputs_exit:
	mov		a,#0cch
	lcall	send_uart
	mov		a,#33h
	lcall	send_uart
	mov		a,#0c3h
	lcall	send_uart
	mov		a,#3ch
	lcall	send_uart
ret_label:
	ret

c_tft_cmd:
	mov		a,#0aah
	lcall	send_uart
	clr		a
	mov		r0,#1
	
	movc	a,@a+dptr
	mov		temp1,a
xtft_cmd_1:
	mov		a,r0
	cjne	a,temp1,xtft_cmd_2
	ajmp	iputs_exit
xtft_cmd_2:
	movc	a,@a+dptr
	lcall	send_uart
	inc		r0
	sjmp	xtft_cmd_1
;receive command function **********************************************************************
; 只处理按键抬起时的事件。
parse_cmd:
	mov		r2,a
	mov		a,recv_cmd_idx
	mov		dptr,#cmd_operate
	rl		a
	jmp		@a+dptr
cmd_operate:
	sjmp	byte1
	sjmp	byte2
	sjmp	byte3
	sjmp	byte4
	sjmp	byte5
	sjmp	byte6
	sjmp	byte7
;	sjmp	byte8
;byte8:
	cjne	r2,#3ch,bad_cmd
	setb	f_recv_cmd_ready
	mov		recv_cmd_idx,#0
	ret
byte1:

	cjne	r2,#0aah,bad_cmd
	sjmp	byte3
byte2:
; 原文档的说明是错误的。
	cjne	r2,#79h,bad_cmd		; 取消78h处理（按钮按下的操作）,只处理离开的操作
byte3:
	inc		recv_cmd_idx			; 假设按键的定义是0~255,高位永远是0
	ret
byte4:
	mov		recv_cmd,r2
	sjmp	byte3
byte5:
	cjne	r2,#0cch,bad_cmd
	sjmp	byte3
byte6:
	cjne	r2,#33h,bad_cmd
	sjmp	byte3
byte7:
	cjne	r2,#0c3h,bad_cmd
	sjmp	byte3
bad_cmd:
	mov		recv_cmd_idx,#0
	clr		f_recv_cmd_ready
	ret
; receive command function end ******************************************************************

; uart funciont *********************************************************************************
read_uart:
; atom operate
	clr		ea
	mov		a,buf_first
	cjne	a,buf_last,ru_1
	setb	f_buf_empty
	setb	ea
; atom operate end
;	setb	red_led
	ret
ru_1:
	clr		f_buf_empty
; atom operate end
	setb	ea
	mov		r0,a
	inc		a

	cjne	a,#PIPO_TOP,ru_2
	mov		a,#PIPO_BUTTON
ru_2:
	mov		buf_first,a
	mov		a,@r0
	ret
uart0_int:
	jb		ri,uart_int_read
	reti
uart_int_read:
	clr		ri
	push	psw
	push	acc
	push	dpl
	push	dph
	setb	rs1
	setb	rs0
	mov		r0,buf_last
	mov		@r0,sbuf
	inc		r0
	mov		a,r0
	cjne	a,#PIPO_TOP,int_1
	mov		r0,#PIPO_BUTTON
int_1:
	mov		buf_last,r0
;	clr		red_led
int_exit:
	pop		dph
	pop		dpl
	pop		acc
	pop		psw
	reti
init_uart_02:
	; 8BIT START 1 STOP 1 
	; S0MODE =0
	; MCE0 = 1 
	; ren0 = 1 receive enable
;[S0MODE|-|MCE0|REN0|TB80|RB80|TI0|RI0]
	mov		scon,#00010000b

	; T1 mode 2
	; C/T1 = 0
	; T1M = 10 MODE 2 8bit counter/timer with auto-reload
	; 使用24.5Mhz,TH1=0x96 即可是uart0的baud rate=115200
	mov		a,tmod
	anl		a,#00001111b
	setb	acc.5
	mov		tmod,a
	
;	mov		tmod,#00100000b
	; TR1 timer 1 is enabled
	; [TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT0]
;	mov		TCON,#40h
	mov		a,TCON
	anl		a,#00110011b
	setb	acc.6
	mov		TCON,a
	;T1 = 1 uses the system clock
	mov		a,CKCON
	setb	acc.3
	mov		CKCON,a
;	mov		CKCON,#00001000b
	
	mov		TH1,#96h
;	mov		TL1,#96h
	
	; tx和rx使用crossbar
	mov		a,P0SKIP
	clr		acc.4
	clr		acc.5
	mov		P0SKIP,a
; p0.5 rx
; p0.4 tx
	mov		a,P0MDIN
	setb	acc.4
	setb	acc.5
	mov		P0MDIN,a
	mov		a,P0MDOUT
	setb	acc.4
	clr		acc.5
	mov		P0MDOUT,a

	; enable uart interrupt
	setb	es
	ret
send_uart:
	jnb		TFT_BUSY,$
	mov		sbuf,a
	jnb		ti,$
	clr		ti
	ret

; uart function end *********************************************************************
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
	
;	mov		a,#0
;	mov		r0,a
;init_1:
;	movx	@r0,a
;	djnz	r0,init_1
	ret
init_final:

	mov		P1,#0
	
	mov		P0,#01000000b
	
	mov		XBR0,#1
	mov		XBR1,#40h			; enable Crossbar and weak pull-ups
	ret
init_port:
	mov		a,P1MDIN
;	setb	acc.0
;	setb	acc.1
;	setb	acc.4
	orl		a,#00010011b
	mov		P1MDIN,a

	mov		a,P1MDOUT
	orl		a,#00010011b
;	setb	acc.0
;	setb	acc.1
;	setb	acc.4
	mov		P1MDOUT,a
	
	mov		a,P0MDIN
	orl		a,#11000000b
	mov		P0MDIN,a
	mov		a,P0MDOUT
	setb	acc.7
	clr		acc.6
	mov		P0MDOUT,a
	ret
init_timer_01:
;16位的计数器溢出7次然后额外数 10923 次为 1秒(1024*1024)
; 如果按照1000×1000算就是 51665
	; set timer0 to mode 1 16bit
	; C/T0 =0
	; GATE0=0
	mov		tmod,#1
	mov		tcon,#0
	;timer0 use /48 prescaler
	mov		ckcon,#2

	; enable timer0 overflow flag
	setb	et0
	setb	tr0

	ret
; hex to charaters
; [in] r2
;[out] r4,r5
htoc:
	mov		dptr,#hex_buf
	mov		a,r2
	swap	a
	anl		a,#0fh
	movc	a,@a+dptr
	mov		r4,a

	mov		dptr,#hex_buf
	mov		a,r2
	anl		a,#0fh
	movc	a,@a+dptr
	mov		r5,a

	ret
hex_buf:
	db "0123456789ABCDEF"
; "运行时间："
running_time:
	db 0d4h,0cbh,0d0h,0d0h,0cah,0b1h,0bch,0e4h,0a3h,0bah,0
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
pic_start:
;         id ,Xs  ,Ys ,Xe  ,Ye  ,X                 ,Y
db pic_stop-$,71h,0,1,0,0 ,0,0,0,56,0,56,high(562),low(562),0,242
pic_stop:
db set_background-$,71h,0,1,0,57,0,0,0,113,0,56,high(562),low(562),0,242
set_background:
db rect1-$,42h,0,10,0,10
; (20,80),(550,390)
rect1:
db clear_rect-$,59h
db 0,20,0,80
db high(550),low(550), high(390),low(390)	;	x2	y2

clear_rect:
db in_pressure-$,5ah
db 0,21,0,81
db high(549),low(549), high(389),low(389)	;	x2	y2


; 欢迎使用
;db 0bbh,0b6h,0d3h,0adh,0cah,0b9h,0d3h,0c3h,0

; 进风压力
in_pressure:
db 0bdh,0f8h,0b7h,0e7h,0d1h,0b9h,0c1h,0a6h,0a3h,0bah,0
;出风压力
out_pressure:
db 0b3h,0f6h,0b7h,0e7h,0d1h,0b9h,0c1h,0a6h,0a3h,0bah,0
;电机转速
motor_rpm:
db 0b5h,0e7h,0bbh,0fah,0d7h,0aah,0cbh,0d9h,0a3h,0bah,0
;开
on:
db 0bfh,0aah,0
;关
off:
db 0b9h,0d8h,0
;照明
light1:
db 0d5h,0d5h,0c3h,0f7h,0
;杀菌
light2:
db 0c9h,0b1h,0beh,0fah,0
end
