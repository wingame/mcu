.PHONY: clean
#CC=avrasm32.exe
CC=avra.exe
CFLAG=-w
TARGET = brushless
#TARGET = bi_direct
#TARGET = test
TARGET = r20a

all:$(TARGET).hex
	@echo "*** Done ***"
$(TARGET).hex:$(TARGET).asm
#	${CC} ${CFLAG} -fI temp.asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
#	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\mcu_dev\avrasm32\include" -m $(TARGET).map
	${CC} --define debug ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
clean:
	${RM} -rf *.hex *.obj *.eep *.map *.cof
	
