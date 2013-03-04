.PHONY: clean
#CC=avrasm32.exe
CC=avra.exe
CFLAG=-w
TARGET = test
#TARGET = t50k
#TARGET = fireboat
all:$(TARGET).hex
	@echo "*** Done ***"
#temp.asm:$(TARGET).asm
#	utf8_eli $(TARGET).asm>temp.asm
$(TARGET).hex:$(TARGET).asm
	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
#	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\avrasm32\include" -m $(TARGET).map
#	${CC} --define debug ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\avrasm32\include" -m $(TARGET).map
clean:
	${RM} -rf *.hex *.obj *.eep *.map
