.PHONY:	all run clean

all:	out
	sdcc -D_XPRINTF_ --no-xinit-opt -c -o out/main.rel main.c
	sdcc --code-loc 512 -o out/main.ihx out/main.rel xprintf.lib
	makebin -p out/main.ihx out/main.bin
	srec_cat out/main.bin -binary -crop 512 -offset -512 -o out/main.bin -binary
	rm -fr out/*.a* out/*.i* out/*.l* out/*.m* out/*.r* out/*.s*
out:
	mkdir $@
clean:
	rm -fr out
run:
	..\tools\dfu-util\dfu-util -D out/main.bin 1>&0 2>&0
