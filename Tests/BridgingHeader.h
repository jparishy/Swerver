//
//  BridgingHeader.h
//  Swerver
//
//  Created by Julius Parishy on 12/23/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

#ifndef BridgingHeader_h
#define BridgingHeader_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>

#include <uv.h>

#if LINUX
#include <postgresql/libpq-fe.h>
#else
#include <libpq-fe.h>
#endif

#endif /* BridgingHeader_h */
