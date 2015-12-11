#!/usr/bin/env sh

MODULE_NAME=Swerver
SOURCES_DIR=./Swerver
OUTPUT_NAME=app

if [ ! -f .build/ ]; then
	mkdir .build/
fi

clang -c $SOURCES_DIR/Bridge.c -o .build/Bridge.o

swiftc $SOURCES_DIR/*.swift -Xlinker .build/Bridge.o -import-objc-header $SOURCES_DIR/BridgingHeader.h -Xcc -I/usr/include -Xcc -I/usr/include/x87_64-linux-gnu -Xcc -iquote -module-name $MODULE_NAME -Xcc -working-directory"`pwd`" -Xcc -I"`pwd`/$SOURCES_DIR" -Xcc -Werror -luv -o $OUTPUT_NAME
