//
//  ContentView.swift
//  MacGraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
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
    
}

struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
    
}
