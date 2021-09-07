//
//  RendererCatalog.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import SwiftUI

class RendererCatalog {
    
    static let catalog: [RenderingOption] = [
        RayTracingRenderer,
        SlimeMoldRenderer
    ]
    
    struct RenderingOption: Identifiable {
        var id: String { name }
        
        var name: String
        var description: String
        var images: [Image]
        var sources: [String]
    }
}

extension RendererCatalog {
    static let RayTracingRenderer = RenderingOption(name: "Ray Tracer",
                                                    description: "",
                                                    images: [],
                                                    sources: [])
    static let SlimeMoldRenderer = RenderingOption(name: "Slime Mold Simulation",
                                                   description: "",
                                                   images: [],
                                                   sources: [])
}
