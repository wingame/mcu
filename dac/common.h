/*
	file: common.h
*/
#ifndef COMMON_H
#define COMMON_H

/* io configs */
#define sbi(io,bit)		(  io |=  (1<<bit) )
#define cbi(io,bit)		(  io &= ~(1<<bit) )
#define gbi(pin ,bit)	( pin &   (1<<bit) )

#define NOP __asm__ volatile ("nop" "\n\t"::)
void EEP_write(uint16_t addr,uint8_t data){
	/* 等待上一次写操作结束 */
	while(EECR & (1<<EEWE));
	/* 设置地址和数据寄存器*/
	EEAR = addr;
	EEDR = data;
	/* 置位EEMWE */
	sbi(EECR,EEMWE);
	/* 置位EEWE 以启动写操作*/
	sbi(EECR,EEWE);
}


uint8_t EEP_read(uint16_t addr){
	/* 等待上一次写操作结束 */
	while(gbi(EECR,EEWE));
	/* 设置地址寄存器*/
	EEAR = addr;
	/* 设置EERE 以启动读操作*/
	sbi(EECR,EERE);
	/* 自数据寄存器返回数据 */
	return EEDR;
}

#define delay50ms(__ms__) _delay_ms(50 * __ms__)
#define delay50us(__us__) _delay_us(50 * __us__)

#endif