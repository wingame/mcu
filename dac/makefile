.PHONY: clean
#CC=avrasm32.exe
CC=avra.exe
CFLAG=-w
#TARGET = 4399spi
TARGET = 4113_oled


all:$(TARGET).hex
	@echo "*** Done ***"
$(TARGET).hex:$(TARGET).asm
#	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\avrasm32\include" -m $(TARGET).map
	${CC} --define CPU_M48 ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
clean:
	${RM} -rf *.hex *.obj *.eep *.map *.cof
	
