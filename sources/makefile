.PHONY:	all clean run

all:	out
	sdas8051 -og -o out/ivt.rel ivt.asm
	sdas8051 -og -o out/dfu.rel dfu.asm
	sdld -ni -b CSEG=0 -b DSEG=0 -g START=512 out/dfu.ihx out/ivt.rel out/dfu.rel
	packihx out/dfu.ihx > out/dfu.hex 2>&0
	makebin -p out/dfu.ihx out/dfu.bin
	rm -fr out/*.r*
out:
	mkdir $@
clean:
	rm -fr out
run:
	..\tools\versaloon\vsprog -V"tvcc.set 3300" -cc8051f32xL -mc -oe -owf -I out/dfu.bin
	..\tools\versaloon\vsprog -V"spi.init" -V"spi.config 1 0 0" -V"spi.io 1 0x00" -V"spi.fini" 1>&0
