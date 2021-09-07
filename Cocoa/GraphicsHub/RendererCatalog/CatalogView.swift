//
//  CatalogView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

import SwiftUI

struct CatalogView: View {
    var renderer: RendererCatalog.RenderingOption
    var body: some View {
        HStack {
            VStack {
                Text(renderer.name)
            }
        }
    }
}

struct CatalogView_Previews: PreviewProvider {
    static var previews: some View {
        CatalogView(renderer: RendererCatalog.RayTracingRenderer)
    }
}
