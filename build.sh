#!/usr/bin/env sh

MODULE_NAME=Swerver
SOURCES_DIR=./Swerver
OUTPUT_NAME=app

if [ ! -d .build/ ]; then
	mkdir .build/
fi

clang -c $SOURCES_DIR/Server/Base/Bridge.c -I/usr/include -DLINUX -o .build/Bridge.o

SWIFT_SOURCES="./Swerver/Helpers/SwiftStdlibAdditions/JSON.swift ./Swerver/Helpers/SwiftStdlibAdditions/_JSONReading.swift ./Swerver/Helpers/SwiftStdlibAdditions/_JSONWriting.swift ./Swerver/Helpers/SwiftStdlibAdditions/String.swift ./Swerver/Server/App/Controllers/Resource.swift ./Swerver/Server/Database/Database.swift ./Swerver/Server/HTTP/HTTPServer.swift ./TestApp/Controllers/NotesController.swift ./Swerver/main.swift ./Swerver/Server/App/Models/Model.swift ./Swerver/Server/Database/ModelQuery.swift ./Swerver/Server/HTTP/HTTP.swift ./TestApp/Models/Note.swift ./Swerver/Server/App/Controllers/Controller.swift ./Swerver/Server/Base/TCPServer.swift ./Swerver/Server/HTTP/HTTP11.swift ./Swerver/Server/HTTP/Router.swift"
swiftc $SWIFT_SOURCES -Xlinker .build/Bridge.o -import-objc-header $SOURCES_DIR/Helpers/BridgingHeader.h -Xcc -DLINUX -Xcc -I/usr/include -Xcc -I/usr/include/x87_64-linux-gnu -Xcc -I"`pwd`/$SOURCES_DIR/Server/Base" -Xcc -iquote -module-name $MODULE_NAME -Xcc -working-directory"`pwd`" -Xcc -I"`pwd`/$SOURCES_DIR" -Xcc -Werror -luv -lpq -o $OUTPUT_NAME $1
