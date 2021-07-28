//
//  RendererCatalog.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import Cocoa

class RendererCatalog {
    
    static let catalog: [(String, RendererInfo.Type)] = [("Boid Simullation", BoidRenderer.self),
//                                                         ("Perlin Visualizer", PerlinNoiseRenderer.self),
                                                         ("Whirl Noise Visualizer", WhirlNoiseRenderer.self),
                                                         ("Slime Mold Simulation", SlimeMoldRenderer.self),
                                                         ("Conway's Game of Life",ConwayRenderer.self),
                                                         ("Complex Image Generator",ComplexRenderer.self),
                                                         ("Ray Marching", CappedRayMarchingRenderer.self),
                                                         ("Path Tracing", CustomPathRenderer.self),
                                                         ("Ray Tracing", CustomRayTraceRenderer.self),
                                                         ("Accelerated Ray Tracing", AcceleratedRayTraceRenderer.self),
                                                  //("Fluid Simulation", FlatFluidRenderer.self),
                                                  // ("Cornell Box", CornellBox.self),
                                                  // ("Tester",TesterBaseRenderer.self),
                                                  // ("Tester Capped Renderer",TesterCappedRenderer.self),
                                                  // ("Testing Inputs", TestInputRenderer.self)
    ]
    
    struct RenderingOption {
        var description: String
        var images: [NSImage]
        var sources: [String]
    }
}
