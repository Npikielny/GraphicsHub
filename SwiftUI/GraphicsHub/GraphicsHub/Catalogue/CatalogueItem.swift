//
//  CatalogueItem.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

import SwiftUI

struct CatalogueItem: View {
    
    var renderer: RendererCatalog.RenderingOption
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(renderer.name)
                        .font(.title)
                    Text(renderer.description)
                        .font(.caption)
                }
                .multilineTextAlignment(.leading)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach (0..<renderer.images.count) { index in
                            let image = renderer.images[index]
                            image
                                .renderingMode(.original)
                                .resizable()
                                .frame(width: 155, height: 155)
                                .cornerRadius(5)
                        }
                    }
                }.frame(height: 200)
                .border(Color.primary, width: 3)
                .cornerRadius(5)
            }
//            if let rendererType = renderer.renderer {
//                NavigationLink("Start", destination: RendererDelegate(renderer: <#T##Renderer#>))
//                FIXME: MTLDevice can't be created on startup...
//            }
            if renderer.sources.count > 0 {
                Text("References")
            }
            VStack (alignment: .leading) {
                ForEach(renderer.sources.sorted(by: >), id: \.key) { key, value in
                    if let url = URL(string: value) {
                        Link(key, destination: url)
                    }
                }
            }
        }
        .frame(width: 400)
        .padding()
        .border(Color.primary, width: 3)
        .cornerRadius(5)
    }
    
}

struct CatalogueItem_Previews: PreviewProvider {
    
    static var previews: some View {
        CatalogueItem(renderer: RendererCatalog.catalog[0])
    }
    
}
