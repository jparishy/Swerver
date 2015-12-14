//
//  TCPServer.swift
//  SwiftLibUVTest
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation

#if os(Linux)
import Glibc
#endif

class TCPServer {
    private var loop: UnsafeMutablePointer<uv_loop_t>
    private var tcp: UnsafeMutablePointer<uv_tcp_t>
    private var addr: UnsafeMutablePointer<sockaddr_in>
    
    let backlogSize = 128
    
    init(bindAddress: String = "0.0.0.0", port: Int = 8080) {
        loop = uv_default_loop()
        
        tcp = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
        var result = uv_tcp_init(loop, tcp)
        if result != 0 {
            print("uv_tcp_init failed.")
        }
        
        addr = UnsafeMutablePointer<sockaddr_in>.alloc(1)
#if os(Linux)
        addr.memory = uv_ip4_addr(bindAddress, Int32(port))
#else
        result = uv_ip4_addr(bindAddress, Int32(port), addr)
#endif

        if result != 0 {
            print("uv_ip4_addr failed.")
        }
       	
#if os(Linux)
        result = uv_tcp_bind(tcp, addr.memory)
#else
        result = uv_tcp_bind(tcp, cast_sockaddr_in(addr), 0)
#endif
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
            print("Listen error: \(result)")
            exit(result)
        }
        
        loop.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        tcp.memory.data  = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
        
        print("Server is running.")
        uv_run(loop, UV_RUN_DEFAULT)
    }
    
    // pragma mark - Internal Callbacks
    
    /*
     * The libuv Interface is different on Linux, so we need to change the method
     * signatures per platform. Annoying but necessary.
     */
#if os(Linux)

    private func handleAlloc(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t) -> uv_buf_t {
        let memory: UnsafeMutablePointer<Int8> = unsafeBitCast(malloc(size), UnsafeMutablePointer<Int8>.self)
        memset(memory, 0, Int(size))
        return uv_buf_init(memory, UInt32(size))
    }
    
    private func handleRead(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: uv_buf_t) {
	    let inBytes: [Int8] = Array(UnsafeBufferPointer(start: buf.base, count: buf.len))
	    let string = String(inBytes.map { b in Character(UnicodeScalar(UInt8(b))) } )
    
        let cString = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
        let bytes = UnsafePointer<Int8>(cString)
        let data = NSData(bytes: bytes, length: string.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let response = processRequest(data)
        if let data = response {
        
            let outBuf = UnsafeMutablePointer<uv_buf_t>.alloc(1)
            
            let bytes = data.bytes
            let memory: UnsafeMutablePointer<Int8> = UnsafeMutablePointer(bytes)
            outBuf.memory = uv_buf_init(memory, UInt32(data.length))
            
            let write = UnsafeMutablePointer<uv_write_t>.alloc(1)
            uv_write(write, stream, outBuf, 1, nil)
        }
        
        uv_read_stop(stream)
        uv_close(cast_stream_to_handle(stream), nil)
        
        free(buf.base)
    }
    
#else

    private func handleAlloc(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
        let memory: UnsafeMutablePointer<Int8> = unsafeBitCast(malloc(size), UnsafeMutablePointer<Int8>.self)
        buf.memory = uv_buf_init(memory, UInt32(size))
    }
    
    private func handleRead(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: UnsafePointer<uv_buf_t>) {
        if let string = String(CString: buf.memory.base, encoding: NSUTF8StringEncoding) {
            
            let cString = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
            let bytes = UnsafePointer<Int8>(cString)
            let data = NSData(bytes: bytes, length: string.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
            
            let response = processRequest(data)
            if let response = response {
            
                let outBuf = UnsafeMutablePointer<uv_buf_t>.alloc(1)
                
                let responseBytes = response.bytes
                let memory: UnsafeMutablePointer<Int8> = UnsafeMutablePointer(responseBytes)
                outBuf.memory = uv_buf_init(memory, UInt32(response.length))
                
                let write = UnsafeMutablePointer<uv_write_t>.alloc(1)
                write.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
                
                uv_write(write, stream, outBuf, 1, _write_cb)
            }
        }
        
        uv_read_stop(stream)
        free(buf.memory.base)
    }
    
    private func handleWrite(write: UnsafeMutablePointer<uv_write_t>, status: Int32) {
        let stream = write.memory.handle
        uv_close(cast_stream_to_handle(stream), nil)
    }
    
#endif
    
    private func handleConnection(server: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
        if status < 0 {
            print("Error receiving data")
            return
        }
        
        let client = UnsafeMutablePointer<uv_tcp_t>.alloc(1)
        var result = uv_tcp_init(loop, client)
        if result != 0 {
            print("uv_tcp_init failed: \(result)")
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

#if os(Linux)

private func _alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t) -> uv_buf_t {
    let tcpServer = unsafeBitCast(handle.memory.loop.memory.data, TCPServer.self)
    return tcpServer.handleAlloc(handle, size: size)
}

private func _read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: uv_buf_t) {
    let tcpServer = unsafeBitCast(stream.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleRead(stream, size: size, buf: buf)
}

#else

private func _alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    let tcpServer = unsafeBitCast(handle.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleAlloc(handle, size: size, buf: buf)
}

private func _read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: UnsafePointer<uv_buf_t>) {
    let tcpServer = unsafeBitCast(stream.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleRead(stream, size: size, buf: buf)
}

private func _write_cb(write: UnsafeMutablePointer<uv_write_t>, status: Int32) {
    let tcpServer = unsafeBitCast(write.memory.data, TCPServer.self)
    tcpServer.handleWrite(write, status: status)
}

#endif

private func _connection_cb(server: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let tcpServer = unsafeBitCast(server.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleConnection(server, status: status)
}
