//
//  TCPServer.swift
//  SwiftLibUVTest
//
//  Created by Julius Parishy on 12/5/15.
//  Copyright © 2015 Julius Parishy. All rights reserved.
//

import Foundation
import libuv

#if os(Linux)
import Glibc
#endif

public class TCPServer {
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
        result = uv_tcp_bind(tcp, unsafeBitCast(addr, UnsafeMutablePointer<sockaddr>.self), 0)
#endif
        if result != 0 {
            print("uv_tcp_bind failed.")
        } 
    }
    
    func processRequest(request: NSData?) -> NSData? {
        return nil
    }
    
    func start() {
        let s = unsafeBitCast(tcp, UnsafeMutablePointer<uv_stream_t>.self)
        
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
        let memory: UnsafeMutablePointer<Int8> = unsafeBitCast(calloc(size, 1), UnsafeMutablePointer<Int8>.self)
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
            outBuf.initialize(uv_buf_init(memory, UInt32(data.length)))
            
            let write = UnsafeMutablePointer<uv_write_t>.alloc(1)
            write.memory.data = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
    
            uv_write(write, stream, outBuf, 1, _write_cb)
        }
        
        uv_read_stop(stream)
        free(buf.base)
    }
    
#else

    private func handleAlloc(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
        let memory: UnsafeMutablePointer<Int8> = unsafeBitCast(calloc(size, 1), UnsafeMutablePointer<Int8>.self)
        buf.initialize(uv_buf_init(memory, UInt32(size)))
    }
    
    private struct RequestResponseStruct {
        let tcpServer: TCPServer
        let requestData: NSData
        let stream: UnsafeMutablePointer<uv_stream_t>
    }
    
    private struct WriteStruct {
        let tcpServer: TCPServer
        let buffer: UnsafeMutablePointer<uv_buf_t>
    }
    
    private func handleRead(stream: UnsafeMutablePointer<uv_stream_t>, size: ssize_t, buf: UnsafePointer<uv_buf_t>) {
        if let string = String(CString: buf.memory.base, encoding: NSUTF8StringEncoding) {
            
            let cString = string.swerver_cStringUsingEncoding(NSUTF8StringEncoding)
            let bytes = UnsafeMutablePointer<Int8>(cString)
            let data = NSData(bytes: bytes, length: string.bridge().swerver_lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
            
            let rr = UnsafeMutablePointer<RequestResponseStruct>.alloc(1)
            rr.initialize(RequestResponseStruct(tcpServer: self, requestData: data, stream: stream))
            
            let work = UnsafeMutablePointer<uv_work_t>.alloc(1)
            work.memory.data = unsafeBitCast(rr, UnsafeMutablePointer<Void>.self)
            
            uv_queue_work(self.loop, work, _work_cb, nil)
        }
        
        free(buf.memory.base)
        uv_read_stop(stream)
    }
    
    func handleWork(work: UnsafeMutablePointer<uv_work_t>) {
        let rr = unsafeBitCast(work.memory.data, UnsafeMutablePointer<TCPServer.RequestResponseStruct>.self)
        let data = rr.memory.requestData
        
        let response = processRequest(data)
        if let response = response {
            
            let outBuf = UnsafeMutablePointer<uv_buf_t>.alloc(1)
            
            let responseBytes = response.bytes
            let memory: UnsafeMutablePointer<Int8> = UnsafeMutablePointer(responseBytes)
            outBuf.initialize(uv_buf_init(memory, UInt32(response.length)))
            
            let wd = UnsafeMutablePointer<WriteStruct>.alloc(1)
            wd.initialize(WriteStruct(tcpServer: self, buffer: outBuf))
            
            let write = UnsafeMutablePointer<uv_write_t>.alloc(1)
            write.memory.data = unsafeBitCast(wd, UnsafeMutablePointer<Void>.self)
            
            uv_write(write, rr.memory.stream, outBuf, 1, _write_cb)
        }
        
        rr.destroy()
        rr.dealloc(1)
        
        work.destroy()
        work.dealloc(1)
    }
    
    #endif
    
    private func handleWrite(write: UnsafeMutablePointer<uv_write_t>, status: Int32) {
        
        let wd = unsafeBitCast(write.memory.data, UnsafeMutablePointer<TCPServer.WriteStruct>.self)
        let buf = wd.memory.buffer
        
        free(buf.memory.base)
        
        buf.destroy()
        buf.dealloc(1)
        
        wd.destroy()
        wd.dealloc(1)
        
        let handle = unsafeBitCast(write.memory.handle, UnsafeMutablePointer<uv_handle_t>.self)
        uv_close(handle, nil)
    }
    
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
        
        let stream = unsafeBitCast(client, UnsafeMutablePointer<uv_stream_t>.self)
        result = uv_accept(server, stream)
        if result == 0 {
            uv_read_start(stream, _alloc_cb, _read_cb)
        } else {
            let handle = unsafeBitCast(stream, UnsafeMutablePointer<uv_handle_t>.self)
            uv_close(handle, nil)
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

private func _write_cb(write: UnsafeMutablePointer<uv_write_t>, status: Int32) {
    let wd = unsafeBitCast(write.memory.data, UnsafeMutablePointer<TCPServer.WriteStruct>.self)
    let tcpServer = wd.memory.tcpServer
    tcpServer.handleWrite(write, status: status)
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
    let wd = unsafeBitCast(write.memory.data, UnsafeMutablePointer<TCPServer.WriteStruct>.self)
    let tcpServer = wd.memory.tcpServer
    tcpServer.handleWrite(write, status: status)
}

#endif

private func _work_cb(work: UnsafeMutablePointer<uv_work_t>) {
    let rr = unsafeBitCast(work.memory.data, UnsafeMutablePointer<TCPServer.RequestResponseStruct>.self)
    let tcpServer = rr.memory.tcpServer
    tcpServer.handleWork(work)
}

private func _connection_cb(server: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let tcpServer = unsafeBitCast(server.memory.loop.memory.data, TCPServer.self)
    tcpServer.handleConnection(server, status: status)
}

