#include <avr/io.h>
#include <util/delay.h>
#include "common.h"

#define SET_COAX_LED sbi(PORTB,0)
#define CLR_COAX_LED cbi(PORTB,0)

#define SET_OPT_LED sbi(PORTC,2)
#define CLR_OPT_LED cbi(PORTC,2)

#define SET_COAX_UNLOCK_LED sbi(PORTD,7)
#define CLR_COAX_UNLOCK_LED cbi(PORTD,7)

#define SET_OPT_UNLOCK_LED sbi(PORTC,1)
#define CLR_OPT_UNLOCK_LED cbi(PORTC,1)

#define IS_UNLOCK gbi(PIND,1)

#define SELECT_COAX cbi(PORTD,2)
#define SELECT_OPT  sbi(PORTD,2)

#define NOT_PRESS_COAX gbi(PINB,1)
#define NOT_PRESS_OPT  gbi(PINC,0)

#define COAX 0x44
#define OPTICAL 0x88

#define delay50ms(__ms__) _delay_ms(50 * __ms__)
#define delay50us(__us__) _delay_us(50 * __us__)




#define READ_LAST_SELECTED() EEP_read(0)
#define WRITE_CURRENT_SELECTED(dat) EEP_write(0,dat)


void update_unlock(uint8_t status){

	if(IS_UNLOCK){
		if(status==OPTICAL){
			CLR_OPT_LED;
			SET_OPT_UNLOCK_LED;
			CLR_COAX_LED;
			CLR_COAX_UNLOCK_LED;
		}else {
			CLR_COAX_LED;
			SET_COAX_UNLOCK_LED;
			CLR_OPT_LED;
			CLR_OPT_UNLOCK_LED;
		}
	} else {
		if(status==OPTICAL){
			SET_OPT_LED;
			CLR_OPT_UNLOCK_LED;
			CLR_COAX_LED;
			CLR_COAX_UNLOCK_LED;
		}else {
			SET_COAX_LED;
			CLR_COAX_UNLOCK_LED;
			CLR_OPT_LED;
			CLR_OPT_UNLOCK_LED;
		}
	}
}

int main(void){

	// initializing

	// 定义输入输出  PD1 UNLOCK 输入
	DDRD = _BV(0)+_BV(2)+_BV(3)+_BV(4)+_BV(5)+_BV(6)+_BV(7);
	// 定义输入输出，PB1 同轴选择输入
	DDRB = _BV(0)+_BV(2)+_BV(3)+_BV(4)+_BV(5)+_BV(6)+_BV(7);
	// 定义输入输出，PC0 光纤选择输入
	DDRC = _BV(1)+_BV(2)+_BV(3)+_BV(4)+_BV(5)+_BV(6)+_BV(7);
	
	PORTB = PORTC = PORTD = 0;
	// end initilizing

	// main logic start
	uint8_t changed=0;
	uint8_t status=READ_LAST_SELECTED();
	if(status == OPTICAL){
		SELECT_OPT;
	} else {
		SELECT_COAX;
	}
	delay50ms(10);
	for(;;){
		
		update_unlock(status);
		if(!NOT_PRESS_OPT){
			changed=1;
			status=OPTICAL;
			SELECT_OPT;
			delay50ms(2);
		}
		if(!NOT_PRESS_COAX){
			changed=1;
			status=COAX;
			SELECT_COAX;
			delay50ms(2);
		}

		if(changed) {
			changed=0;
			WRITE_CURRENT_SELECTED(status);

		}
		
		
	}
}

