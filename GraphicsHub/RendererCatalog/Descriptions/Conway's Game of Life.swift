//
//  Conway's Game of Life.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import Foundation

extension RendererCatalog {
    static let Conways_Game_Of_life = RenderingOption(description:
        """
        A cellular automata simulation of life. The rules are simple: 
        
        1. Any live cell with fewer than two live neighbours dies, as if by underpopulation.
        2. Any live cell with two or three live neighbours lives on to the next generation.
        3. Any live cell with more than three live neighbours dies, as if by overpopulation.
        4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        (From wikipedia)
        """,
                                                         images: [],
                                                         sources: ["https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life"])
}
