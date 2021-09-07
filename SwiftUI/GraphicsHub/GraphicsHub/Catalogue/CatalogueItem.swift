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
        HStack {
            VStack(alignment: .leading) {
                Text(renderer.name)
                    .font(.title)
                Text(renderer.description)
                    .font(.caption)
            }
            .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
    }
}

struct CatalogueItem_Previews: PreviewProvider {
    static var previews: some View {
        CatalogueItem(renderer: RendererCatalog.catalog[0])
    }
}
