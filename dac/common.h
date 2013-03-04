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
	/* �ȴ���һ��д�������� */
	while(EECR & (1<<EEWE));
	/* ���õ�ַ�����ݼĴ���*/
	EEAR = addr;
	EEDR = data;
	/* ��λEEMWE */
	sbi(EECR,EEMWE);
	/* ��λEEWE ������д����*/
	sbi(EECR,EEWE);
}


uint8_t EEP_read(uint16_t addr){
	/* �ȴ���һ��д�������� */
	while(gbi(EECR,EEWE));
	/* ���õ�ַ�Ĵ���*/
	EEAR = addr;
	/* ����EERE ������������*/
	sbi(EECR,EERE);
	/* �����ݼĴ����������� */
	return EEDR;
}

#define delay50ms(__ms__) _delay_ms(50 * __ms__)
#define delay50us(__us__) _delay_us(50 * __us__)

#endif