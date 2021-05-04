//
//  TextureOutput.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/2/21.
//

import MetalKit
import Metal
import Cocoa


struct RGBA32 {
    var color: UInt32
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }
    
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    
    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
        return lhs.color == rhs.color
    }
    
    var redComponent: UInt8 {
        return UInt8((color >> 24) & 255)
    }

    var greenComponent: UInt8 {
        return UInt8((color >> 16) & 255)
    }

    var blueComponent: UInt8 {
        return UInt8((color >> 8) & 255)
    }

    var alphaComponent: UInt8 {
        return UInt8((color >> 0) & 255)
    }
    
    var colorComponents: (UInt8,UInt8,UInt8,UInt8) {
        return (self.redComponent,self.greenComponent,self.blueComponent,self.alphaComponent)
    }
    
}

extension Renderer {
    func copyToBuffer(commandBuffer: MTLCommandBuffer?, buffer: MTLBuffer?) -> NSImage? {
        let copyFunction = createFunctions(names: "toRGB32")[0]!
        let copyPipeline = try! device.makeComputePipelineState(function: copyFunction)
        
        let copyEncoder = commandBuffer?.makeComputeCommandEncoder()
        copyEncoder?.setComputePipelineState(copyPipeline)
        let pixelBuffer = device.makeBuffer(length: MemoryLayout<RGBA32>.stride, options: .storageModeManaged)!
        copyEncoder?.setBuffer(pixelBuffer, offset: 0, index: 0)
        copyEncoder?.setBytes([Int32(outputImage.width)], length: MemoryLayout<Int32>.stride, index: 1)
        copyEncoder?.setTexture(outputImage, index: 0)
        copyEncoder?.dispatchThreadgroups(getImageGroupSize(), threadsPerThreadgroup: MTLSize(width: 8, height: 8, depth: 1))
        copyEncoder?.endEncoding()
        commandBuffer?.commit()
        
        let byteCount = outputImage.width * outputImage.height * 16
        let output = (pixelBuffer.contents().bindMemory(to: RGBA32.self, capacity: byteCount))
        
        let context = CGContext(data: output,
                                width: outputImage.width,
                                height: outputImage.height,
                                bitsPerComponent: 32,
                                bytesPerRow: Int(16 * outputImage.width),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: RGBA32.bitmapInfo)
        
        let finalImage = NSImage(cgImage: (context?.makeImage()!)!, size: NSSize(width: CGFloat(outputImage.width), height: CGFloat(outputImage.height)))
        return finalImage
        
//        let bytesPerPixel = 16
//        let imageByteCount = outputImage.width * outputImage.height * bytesPerPixel
//        var imageBytes = malloc(imageByteCount)!
//        outputImage.getBytes(imageBytes,
//                         bytesPerRow: outputImage.width * bytesPerPixel,
//                         from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: outputImage.width, height: outputImage.height, depth: 1)),
//                         mipmapLevel: 0)
////        let provider = CGDataProvider(dataInfo: nil,
////                                      data: imageBytes,
////                                      size: imageByteCount) { data, info, size in free(data) }
////        let colorspace = CGColorSpace(name: CGColorSpace.linearSRGB)
//////        let bitmapInfo: CGBitmapInfo = CGBitmapInfo([kColorSyncAlphaPremultipliedLast, kColorSyncByteOrder32Big])
//////        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(arrayLiteral: kColorSyncAlphaPremultipliedLast, kColorSyncByteOrder32Big)
//
//        let context = CGContext(data: imageBytes,
//                                width: outputImage.width,
//                                height: outputImage.height,
//                                bitsPerComponent: 32,
//                                bytesPerRow: 16 * outputImage.width,
//                                space: CGColorSpace(name: CGColorSpace.linearSRGB)!,
//                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//        if let cgimage = context?.makeImage() {
//            let image = NSImage(cgImage: cgimage, size: NSSize(width: CGFloat(outputImage.width), height: CGFloat(outputImage.height)))
//            return image
////            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
////            let imageURL = desktopURL.appendingPathComponent(names[k] + "=" + String(value) + ".tiff")
////
////            try! image.tiffRepresentation?.write(to: imageURL)
//        }
//        return nil
//
//
////        let context2 = CGContext(data: Output, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(8*width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
////        let finalImage = NSImage(cgImage: (context2?.makeImage()!)!, size: NSSize(width: width, height: height))
////        self.imageHolder.image = finalImage
////        return finalImage
//
    }
}


//
//extension Renderer {
//    func toImage() -> NSImage? {
//        let bytesPerPixel = 16
//        let imageByteCount = outputImage.width * outputImage.height * bytesPerPixel
//        var imageBytes = malloc(imageByteCount)!
//        outputImage.getBytes(imageBytes,
//                         bytesPerRow: outputImage.width * bytesPerPixel,
//                         from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: outputImage.width, height: outputImage.height, depth: 1)),
//                         mipmapLevel: 0)
////        let provider = CGDataProvider(dataInfo: nil,
////                                      data: imageBytes,
////                                      size: imageByteCount) { data, info, size in free(data) }
////        let colorspace = CGColorSpace(name: CGColorSpace.linearSRGB)
//////        let bitmapInfo: CGBitmapInfo = CGBitmapInfo([kColorSyncAlphaPremultipliedLast, kColorSyncByteOrder32Big])
//////        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(arrayLiteral: kColorSyncAlphaPremultipliedLast, kColorSyncByteOrder32Big)
//
//        let context = CGContext(data: imageBytes,
//                                width: outputImage.width,
//                                height: outputImage.height,
//                                bitsPerComponent: 32,
//                                bytesPerRow: 16 * outputImage.width,
//                                space: CGColorSpace(name: CGColorSpace.linearSRGB)!,
//                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//        if let cgimage = context?.makeImage() {
//            let image = NSImage(cgImage: cgimage, size: NSSize(width: CGFloat(outputImage.width), height: CGFloat(outputImage.height)))
//            return image
////            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
////            let imageURL = desktopURL.appendingPathComponent(names[k] + "=" + String(value) + ".tiff")
////
////            try! image.tiffRepresentation?.write(to: imageURL)
//        }
//        return nil
//
//
////        let context2 = CGContext(data: Output, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: Int(8*width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: RGBA32.bitmapInfo)
////        let finalImage = NSImage(cgImage: (context2?.makeImage()!)!, size: NSSize(width: width, height: height))
////        self.imageHolder.image = finalImage
////        return finalImage
//
//    }
//}
