#!/usr/bin/env sh
clang -c ./Sources/Bridge.c
swiftc ./Sources/*.swift -Xlinker Bridge.o -import-objc-header ./Sources/BridgingHeader.h -Xcc -I/usr/include -Xcc -I/usr/include/x86_64-linux-gnu -Xcc -iquote -module-name Swerver -Xcc -working-directory/home/jp/code/swerver -Xcc -I/home/jp/code/swerver/Sources -Xcc -Werror -luv
