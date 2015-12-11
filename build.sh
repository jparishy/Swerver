#!/usr/bin/env sh

MODULE_NAME=Swerver

clang -c ./Sources/Bridge.c
swiftc ./Sources/*.swift -Xlinker Bridge.o -import-objc-header ./Sources/BridgingHeader.h -Xcc -I/usr/include -Xcc -I/usr/include/x86_64-linux-gnu -Xcc -iquote -module-name $MODULE_NAME -Xcc -working-directory`pwd` -Xcc -I`pwd`/Swerver -Xcc -Werror -luv
