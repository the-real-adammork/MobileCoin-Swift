//
//  Copyright (c) 2020-2021 MobileCoin. All rights reserved.
//

import Foundation

extension Data {
    public func crc32(seed: UInt32? = nil, reflect: Bool = true) -> Data {
        Data( Checksum.crc32(bytes, seed: seed, reflect: reflect).bytes())
    }
    
    public var bytes: Array<UInt8> {
      Array(self)
    }
}

extension FixedWidthInteger {
  @inlinable
  func bytes(totalBytes: Int = MemoryLayout<Self>.size) -> Array<UInt8> {
    arrayOfBytes(value: self.littleEndian, length: totalBytes)
    // TODO: adjust bytes order
    // var value = self.littleEndian
    // return withUnsafeBytes(of: &value, Array.init).reversed()
  }
}

/// Array of bytes. Caution: don't use directly because generic is slow.
///
/// - parameter value: integer value
/// - parameter length: length of output array. By default size of value type
///
/// - returns: Array of bytes
@_specialize(where T == Int)
@_specialize(where T == UInt)
@_specialize(where T == UInt8)
@_specialize(where T == UInt16)
@_specialize(where T == UInt32)
@_specialize(where T == UInt64)
@inlinable
func arrayOfBytes<T: FixedWidthInteger>(value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
  let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
  valuePointer.pointee = value

  let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
  var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
  for j in 0..<min(MemoryLayout<T>.size, totalBytes) {
    bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
  }

  valuePointer.deinitialize(count: 1)
  valuePointer.deallocate()

  return bytes
}
