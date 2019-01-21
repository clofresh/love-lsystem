matrix.so: matrix.o
	ld -Bshareable -o $@ $<

matrix.o: matrix.c
	gcc -O2 -DTESTS -ansi -W -Wall -I/usr/include/luajit-2.0 -fPIC -c -o $@ $<

clean:
	rm -f matrix.o matrix.so
