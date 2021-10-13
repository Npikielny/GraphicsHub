//
//  ContentView.swift
//  GraphicsHub
//
//  Created b@y Noah Pikielny on 9/7/21.
//

import SwiftUI

struct ContentView: View {
    
    var renderer: Renderer? = nil

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach (RendererCatalog.catalog) { renderer in
                    CatalogueItem(renderer: renderer)
                        .padding()
                }
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
    
}
