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
        SlimeMoldRenderer,
        ComplexRenderer,
        // FIXME: Hide
        UVRendererOption
    ]
    
    struct RenderingOption: Identifiable {
        var id: String { name }
        
        var name: String
        var description: String
        var images: [Image]
        var sources: [String : String] // Website name : URL
        var renderer: Renderer.Type? = nil
    }
    
}

extension RendererCatalog {
    
    static let RayTracingRenderer = RenderingOption(name: "Ray Tracer",
                                                    description: "Uses light transport simulation to create hyper-realistic images",
                                                    images: [
                                                        Image("BoxyBoysToo!"),
                                                        Image("RayTracingWebsite")
                                                    ],
                                                    sources: [
                                                        "GPU Ray Tracing in Unity" : "http://three-eyed-games.com/2018/05/03/gpu-ray-tracing-in-unity-part-1/"
                                                    ])
    
    static let SlimeMoldRenderer = RenderingOption(name: "Slime Mold Simulation",
                                                   description: "Slimey boys",
                                                   images: [],
                                                   sources: [:])
    
    static let ComplexRenderer = RenderingOption(name: "Complex Renderer",
                                                 description: "Graphs fractals of convergence and divergence of Numbers in the complex plane",
                                                 images: [
                                                    Image("HeaderBG"),
                                                    Image("MandelBrotWebsite")
                                                 ],
                                                 sources: [:])
    
    static let UVRendererOption = RenderingOption(name: "UV Renderer",
                                            description: "Draws the UV coordinates of a texture",
                                            images: [],
                                            sources: [:],
                                            renderer: UVRenderer.self
    )

}

