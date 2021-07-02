//
//  TestInputRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 5/20/21.
//

import MetalKit

class TestInputRenderer: Renderer {
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size, inputManager: TestInputManager(imageSize: size), name: "Test Input Renderer")
    }
    
}

class TestInputManager: BasicInputManager {
    
    
}
