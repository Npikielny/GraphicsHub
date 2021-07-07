//
//  Accelerated Ray Tracing.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import Foundation

extension RendererCatalog {
    static let Accelerated_Ray_Tracing = RenderingOption(description:
        """
        An implementation of ray tracing us the Metal Performance Shaders framework to accelerate intersections. Work in progress...
        """,
                                                         images: [],
                                                         sources: [])
}
