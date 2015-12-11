//
//  bridge.c
//  SwiftLibUVTest
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

#include "bridge.h"

struct sockaddr_in * cast_sockaddr(struct sockaddr *s)
{
    return (struct sockaddr_in *)s;
}

uv_stream_t * cast_tcp_to_stream(uv_tcp_t *tcp)
{
    return (uv_stream_t *)tcp;
}

uv_handle_t * cast_stream_to_handle(uv_stream_t *stream)
{
    return (uv_handle_t *)stream;
}
