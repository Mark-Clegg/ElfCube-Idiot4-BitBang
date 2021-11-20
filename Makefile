all: idiot.idi

idiot.idi:	idiot4.asm
	asmx -l idiot4.lst -o idiot4.hex -e -w idiot4.asm
	idiothex idiot4.hex
	sed -i '$$ s/;//' idiot4.idi
	
install:
	screen -X slowpaste 5
	screen -X readreg p "`pwd`/idiot4.idi"
	screen -X paste p

clean:
	rm idiot4.lst idiot4.hex idiot4.idi
