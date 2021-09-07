//
//  RendererCatalogue.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
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
                                                    description: "Uses light transport simulation to create hyper-realistic images",
                                                    images: [],
                                                    sources: [])
    static let SlimeMoldRenderer = RenderingOption(name: "Slime Mold Simulation",
                                                   description: "Slimey boys",
                                                   images: [],
                                                   sources: [])
}

