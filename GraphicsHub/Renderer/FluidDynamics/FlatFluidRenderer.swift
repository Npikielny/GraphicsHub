//
//  FlatFluidRenderer.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/25/21.
//

import MetalKit

class FlatFluidRenderer: Renderer {
    
    required init(device: MTLDevice, size: CGSize) {
        super.init(device: device, size: size)
    }
    
}