//
//  bridge.h
//  SwiftLibUVTest
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

#ifndef bridge_h
#define bridge_h

#include <stdio.h>
#include <uv.h>

struct sockaddr_in * cast_sockaddr(struct sockaddr *s);

uv_stream_t * cast_tcp_to_stream(uv_tcp_t *tcp);
uv_handle_t * cast_stream_to_handle(uv_stream_t *stream);

#endif /* bridge_h */
