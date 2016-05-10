PYVERSION=2.7
PYPREFIX=/usr
INCLUDES=-I$(PYPREFIX)/include/python$(PYVERSION) -I./
LINK=-lpython$(PYVERSION) 


all : app_router

app_router: main.o forward.so database.so rx.so 
	$(CC) -o $@ $^ $(INCLUDES) $(LINK)

main.o: main.c
	$(CC) -c $^ $(INCLUDES) $(LINK) 

forward.so: forward.c
	$(CC) $(INCLUDES) $(LINK) -shared -o forward.so -fPIC forward.c

database.so: database.c
	$(CC) $(INCLUDES) $(LINK) -shared -o database.so -fPIC database.c

rx.so: rx.c
	$(CC) $(INCLUDES) $(LINK) -shared -o rx.so -fPIC rx.c

forward.c: forward.pyx 
	cython forward.pyx

database.c: database.pyx 
	cython database.pyx 

main.c: main.pyx 
	cython --embed main.pyx 

rx.c: rx.pyx 
	cython rx.pyx 

clean: 
	@rm -rf *.c *.o *.so app_router 2> /dev/null 
 
