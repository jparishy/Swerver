//
//  TCPServer.swift
//  SwiftLibUVTest
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

class TCPServer {
    private var loop: UnsafeMutablePointer<uv_loop_t>
    private var tcp: UnsafeMutablePointer<uv_tcp_t>
    private var addr: UnsafeMutablePointer<sockaddr>
    
    let backlogSize = 128
    
    init(bindAddress: String = "0.0.0.0", port: Int = 8080) {
        loop = uv_default_loop()
        
        tcp = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
        var result = uv_tcp_init(loop, tcp)
        if result != 0 {
            print("uv_tcp_init failed.")
        }
        
        addr = UnsafeMutablePointer<sockaddr>.alloc(1)
        let addr_in = unsafeBitCast(addr, UnsafeMutablePointer<sockaddr_in>.self)
        result = uv_ip4_addr(bindAddress, Int32(port), addr_in)
        if result != 0 {
            print("uv_ip4_addr failed.")
        }
        
        result = uv_tcp_bind(tcp, addr, 0)
        if result != 0 {
            print("uv_tcp_bind failed.")
        }
    }
    
    func processRequest(request: NSData?) -> NSData? {
        return nil
    }
    
    func start() {
        let s = cast_tcp_to_stream(tcp)
        
        let result = uv_listen(s, Int32(backlogSize), _connection_cb)
        if result != 0 {
            print("Listen error: \(uv_strerror(result))")
            exit(result)
        }
        
        loop.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        tcp.memory.data  = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        uv_run(loop, UV_RUN_DEFAULT)
    }
    
    // pragma mark - Internal Callbacks
    
    private func handleAlloc(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
        let memory: UnsafeMutablePointer<Int8> = unsafeBitCast(malloc(size), UnsafeMutablePointer<Int8>.self)
        buf.memory = uv_buf_init(memory, UInt32(size))
    }
    
    private func handleRead(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: UnsafePointer<uv_buf_t>) {
        if let string = String(CString: buf.memory.base, encoding: NSUTF8StringEncoding) {
            
            let cString = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
            let bytes = UnsafePointer<Int8>(cString)
            let data = NSData(bytes: bytes, length: string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
            
            if let response = processRequest(data),
                responseStr = NSString(bytes: response.bytes, length: response.length, encoding: NSUTF8StringEncoding) as? String,
                repsonseCString = responseStr.cStringUsingEncoding(NSUTF8StringEncoding) {
                
                let outBuf = UnsafeMutablePointer<uv_buf_t>.alloc(1)
                let memory: UnsafeMutablePointer<Int8> = UnsafeMutablePointer(repsonseCString)
                outBuf.memory = uv_buf_init(memory, UInt32(responseStr.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)))
                
                let write = UnsafeMutablePointer<uv_write_t>.alloc(1)
                uv_write(write, stream, outBuf, 1, nil)
            }
        }
        
        uv_read_stop(stream)
        uv_close(cast_stream_to_handle(stream), nil)
        
        free(buf.memory.base)
    }
    
    private func handleConnection(server: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
        if status < 0 {
            print("Error receiving data")
            return
        }
        
        let client = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
        var result = uv_tcp_init(loop, client)
        if result != 0 {
            print("uv_tcp_init failed: \(uv_strerror(result))")
        }
        
        let stream = cast_tcp_to_stream(client)
        result = uv_accept(server, stream)
        if result == 0 {
            uv_read_start(stream, _alloc_cb, _read_cb)
        } else {
            uv_close(cast_stream_to_handle(stream), nil)
        }
    }
}

private func _alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    let tcpServer = unsafeBitCast(handle.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleAlloc(handle, size: size, buf: buf)
}

private func _read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: UnsafePointer<uv_buf_t>) {
    let tcpServer = unsafeBitCast(stream.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleRead(stream, size: size, buf: buf)
}

private func _connection_cb(server: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let tcpServer = unsafeBitCast(server.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleConnection(server, status: status)
}
