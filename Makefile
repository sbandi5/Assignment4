##################################################
# Makefile of os423V0x.asm (x=[1,2,3])
##################################################

VER			= V02
ASM			= nasm
ASMFLAGS	= -f bin
IMG			= a.img

MBR			= os423V.asm
LDR			= loaderV.asm
logo		= logo.asm
Date_Time	= datetimeV.asm
MBR_SRC		= $(subst V,$(VER),$(MBR))
MBR_BIN		= $(subst .asm,.bin,$(MBR_SRC))
LDR_SRC		= $(subst V,$(VER),$(LDR))
LDR_BIN		= $(subst .asm,.bin,$(LDR_SRC))
Date_Time_SRC = $(subst V,$(VER),$(Date_Time))
Date_Time_BIN = $(subst .asm,.bin,$(Date_Time_SRC))

.PHONY : everything

everything : $(MBR_BIN) $(LDR_BIN) $(Date_Time_BIN)
 ifneq ($(wildcard $(IMG)), )
else
		dd if=/dev/zero of=$(IMG) bs=512 count=2880
 endif

		dd if=$(MBR_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
		dd if=$(logo) of=$(IMG) bs=512 count=1 seek=50 conv=notrunc
		dd if=$(LDR_BIN) of=$(IMG) bs=512 count=1 seek=5 conv=notrunc
  		dd if=$(Date_Time_BIN) of=$(IMG) bs=512 count=1 seek=6 conv=notrunc

$(MBR_BIN) : $(MBR_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(LDR_BIN) : $(LDR_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@
$(Date_Time_BIN) : $(Date_Time_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

clean :
	rm -f $(MBR_BIN) $(LDR_BIN) $(Date_Time_BIN)

reset:
	rm -f $(MBR_BIN) $(LDR_BIN) $(IMG) $(Date_Time_BIN)
	
blankimg:
	dd if=/dev/zero of=$(IMG) bs=512 count=2880

run:
	dosbox $(IMG)
