source = src/Joynet.cpp\
		3rdparty/accumulation-dev/src/net/CurrentThread.cpp\
		3rdparty/accumulation-dev/src/net/DataSocket.cpp\
		3rdparty/accumulation-dev/src/net/EventLoop.cpp\
		3rdparty/accumulation-dev/src/net/SocketLibFunction.c\
		3rdparty/accumulation-dev/src/net/TCPService.cpp\
		3rdparty/accumulation-dev/src/utils/buffer.c\
		3rdparty/accumulation-dev/src/utils/connector.cpp\
		3rdparty/accumulation-dev/src/utils/fdset.c\
		3rdparty/accumulation-dev/src/utils/array.c\
		3rdparty/accumulation-dev/src/utils/SHA1.cpp\
		3rdparty/accumulation-dev/src/utils/base64.cpp\
		3rdparty/accumulation-dev/src/utils/ox_file.cpp\
		3rdparty/accumulation-dev/src/utils/systemlib.c\
		3rdparty/accumulation-dev/src/utils/md5calc.cpp\
		3rdparty/accumulation-dev/src/timer/timer.cpp\

LUADIR = /usr/local/include
        
Joynet:
	g++ $(source) -fPIC -shared -I$(LUADIR) -I./3rdparty/sol2 -I./3rdparty/sol2/Catch/include -I./3rdparty/accumulation-dev/src/net -I./3rdparty/accumulation-dev/src/timer -I./3rdparty/accumulation-dev/src/utils -O3 -lpthread -lrt -ldl -o Joynet.so
clean : 
	find ./ -name "*.o"  | xargs rm -f
	rm -f ./Joynet.so
