beep_c:
	ldi		r20,SOUND_ON
	ldi		r21,SOUND_OFF
	ldi		r_temp1,9
	ldi		r_temp2,7
	rjmp	beep_cycle
beep_b:
	ldi		r20,SOUND_ON
	ldi		r21,SOUND_OFF
	ldi		r_temp1,12
	ldi		r_temp2,5
	rjmp	beep_cycle
beep_a:
	ldi		r20,SOUND_ON
	ldi		r21,SOUND_OFF
	ldi		r_temp1,15
	ldi		r_temp2,4
	rjmp	beep_cycle

beep_cycle:
; P capacity charge
.if	P_CHARGE>0
	ldi		r_temp4,P_CHARGE
	out		PORTD,r_temp4
	ldi		r_temp4,50
p_charge_1:
	dec		r_temp4
	brne	p_charge_1
	out		PORTD,r_temp4		; r_temp4 = 0
.endif
beep_cycle_1:

	ldi		r27,120				; cycle times
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

test_fet:
	ldi		r_temp1,15
	ldi		r_temp2,4
	rjmp	beep_cycle

test_fets:
	ldi		r20,STATE_1
	ldi		r21,STATE_2
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	
	ldi		r20,STATE_3
	ldi		r21,STATE_4
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	
	ldi		r20,STATE_5
	ldi		r21,STATE_6
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	
	ldi		r20,STATE_7
	ldi		r21,STATE_8
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	
	ldi		r20,STATE_9
	ldi		r21,STATE_a
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	
	ldi		r20,STATE_b
	ldi		r21,STATE_c
	rcall	test_fet
	rcall	short_delay
	rcall	short_delay
	rjmp	test_fets