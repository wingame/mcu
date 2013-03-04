.PHONY: clean
#CC=as31
CC=asemw
#BATTERY TYPE 1:NIHM 2:LIPO

CFLAG=/COLUMNS /D:NO_UART:1 /D:BATTERY_TYPE:1
TARGET = hw35
#TARGET = phone_charger
#TARGET = exercise
#TARGET = test

all:$(TARGET).hex
	@echo "*** Done ***"
$(TARGET).hex:$(TARGET).asm
#	${CC} ${CFLAG} -fI temp.asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
#	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\mcu_dev\avrasm32\include" -m $(TARGET).map
#	${CC} -l ${TARGET}.asm
	${CC} ${CFLAG} ${TARGET}.asm
clean:
	${RM} -rf *.hex *.obj *.eep *.map *.cof *.lst
	
