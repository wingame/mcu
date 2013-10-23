.equ	SOUND_VOL =	 10	;SOUND_VOL/255
beep_c:
	ldi		r20,SOUND_ON1
	ldi		r21,SOUND_OFF1
	ldi		r_temp1,18
	ldi		r_temp2,14
	rjmp	beep_cycle
beep_b:
	ldi		r20,SOUND_ON1
	ldi		r21,SOUND_OFF1
	ldi		r_temp1,24
	ldi		r_temp2,10
	rjmp	beep_cycle
beep_a:
	ldi		r20,SOUND_ON1
	ldi		r21,SOUND_OFF1
	ldi		r_temp1,30
	ldi		r_temp2,8
	rjmp	beep_cycle

beep_cycle:
; P capacity charge
.if	P_CHARGE1>0
	ldi		r_temp4,P_CHARGE1
	out		PORTD,r_temp4
	ldi		r_temp4,50
p_charge_1:
	dec		r_temp4
	brne	p_charge_1
	out		PORTD,r_temp4		; r_temp4 = 0
.endif
beep_cycle_1:

	ldi		r27,255				; cycle times
beep_s:
	mov		r26,r_temp1
beep_0:
	ldi		r_temp3,200			; off period
beep_1:
	dec		r_temp3				; 1 * 200 * temp1
	brne	beep_1				; 2 * 200 * temp1
	dec		r26					; 1 * temp1
	brne	beep_0				; 2 * temp1
	ldi		r26,70				; on period
	out		PORTD,r20
beep_2:
	dec		r26					; 1
	brne	beep_2				; 2
	out		PORTD,r21
;	out		PORTD,zero
	dec		r27
	brne	beep_s
	dec		r_temp2
	brne	beep_cycle_1


; P capacity charge again
;	ldi		r_temp4,P_CHARGE
;	out		PORTD,r_temp4
;	ldi		r_temp4,50
;p_charge_2:
;	dec		r_temp4
;	brne	p_charge_2
;	out		PORTD,zero
	ret

short_delay:
	ldi		r17,255
d1:
	ldi		r16,255
d2:
	dec		r16
	brne	d2
	dec		r17
	brne	d1
	ret

beep_delay:
	push	r_temp1
	mov		r_temp1,r_temp2		; 8
bd1:
	dec		r_temp1
	brne	bd1
	pop		r_temp1
	ret



sound_d:
	ldi		r_temp2,8
	rjmp	b_cycle
sound_e:
	ldi		r_temp2,6
	rjmp	b_cycle
sound_f:
	ldi		r_temp2,4


b_cycle:
	inc		state_index
	mov		r_temp1,state_index
	cpi		r_temp1,6
	brcs	bc_start
	clr		state_index
bc_start:
	rcall	set_state
	ldi		r_temp1,low(500)
	sts		mem_temp1,r_temp1
	ldi		r_temp1,high(500)
	sts		mem_temp1+1,r_temp1


bc_1:
.if	P_CHARGE1>0
p_charge_3:
	ldi		r_temp1,P_CHARGE2
	out		PORTD,r_temp1
	ldi		r_temp1,5
p_charge_4:
	dec		r_temp1
	brne	p_charge_4
	out		PORTD,r_temp1		; r_temp1 = 0
.endif

	ldi		r_temp1,SOUND_VOL
	out		PORTD,state_on
bc_2:
	rcall	beep_delay
	dec		r_temp1
	brne	bc_2
	out		PORTD,state_off
	ldi		r_temp1,256-SOUND_VOL
bc_3:
	rcall	beep_delay
	dec		r_temp1
	brne	bc_3


	lds		r_temp1,mem_temp1
	dec		r_temp1
	sts		mem_temp1,r_temp1
	brne	bc_1
	lds		r_temp1,mem_temp1+1
	and		r_temp1,r_temp1
	breq	bc_exit
	dec		r_temp1
	sts		mem_temp1+1,r_temp1
	rjmp	bc_1
bc_exit:
	ret
set_state:
	clr		r0

	ldi		yl,low(mem_states)
	ldi		yh,high(mem_states)
	mov		r_temp1,state_index
	add		r_temp1,r_temp1
	add		yl,r_temp1
	adc		yh,r0
	ld		state_on,Y+
	ld		state_off,Y
	ret
