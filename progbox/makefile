.PHONY: clean
#CC=avrasm32.exe
CC=avra.exe
CFLAG=-w
TARGET = rcp
#TARGET = progbox

all:$(TARGET).hex
	@echo "*** Done ***"
$(TARGET).hex:$(TARGET).asm
#temp.asm:$(TARGET).asm
#	utf8_eli $(TARGET).asm>temp.asm
#$(TARGET).hex:temp.asm
#	${CC} ${CFLAG} -fI temp.asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I . -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
#	${CC} ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
	${CC} --define CPU_M48 ${CFLAG} -fI $(TARGET).asm -o $(TARGET).hex -d $(TARGET).obj -e $(TARGET).eep -I "D:\lx\mcu_dev\avrasm32\include" -m $(TARGET).map
clean:
	${RM} -rf *.hex *.obj *.eep *.map
	
