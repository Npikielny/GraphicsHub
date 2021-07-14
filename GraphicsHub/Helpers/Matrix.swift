//
//  Matrix.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import SceneKit

// FIXME: There must be a better way to solve this
protocol Divisable: Numeric, _ExpressibleByBuiltinIntegerLiteral {
    static func / (lhs: Self, rhs: Self) -> Self
}
extension Double: Divisable {}
extension Float: Divisable {}
extension Int: Divisable {}

class Matrix<T: Divisable>: NSObject {
    
    
    // MARK: Properties
    var values: [SIMD2<Int>: T]
    var dimension: SIMD2<Int>
    
    // MARK: Inits
    init(Rows: [T], Width: Int) {
        var Values: [SIMD2<Int>: T] = [:]
        for (index,i) in Rows.enumerated() {
            Values[SIMD2<Int>(index % Width, index / Width)] = i
        }
        self.values = Values
        self.dimension = SIMD2<Int>(Width, 1+Values.max(by: {$0.key.y < $1.key.y})!.key.y)
        super.init()
        do {
            try catchInitError()
        } catch {
            print(error)
            fatalError()
        }
    }
    
    init(Columns: [T], Height: Int) {
        var Values: [SIMD2<Int>: T] = [:]
        for (index,i) in Columns.enumerated() {
            Values[SIMD2<Int>(index / Height,index % Height)] = i
        }
        self.values = Values
        self.dimension = SIMD2<Int>(Values.max(by: {$0.key.x < $1.key.x})!.key.x+1,Height)
        super.init()
        do {
            try catchInitError()
        } catch {
            print(error)
            fatalError()
        }
    }
    
    init(Rows: [[T]]) {
        var Values: [SIMD2<Int>: T] = [:]
        for y in 0..<Rows.count {
            for x in 0..<Rows[0].count {
                Values[SIMD2<Int>(x,y)] = Rows[y][x]
            }
        }
        self.values = Values
        self.dimension = SIMD2<Int>(Rows[0].count,Rows.count)
        super.init()
        do {
            try catchInitError()
        } catch {
            print(error)
            fatalError()
        }
    }
    
    private init(Values: [SIMD2<Int>: T]) {
        self.values = Values
        let last = Values.keys.max(by: {$0.x+$0.y < $1.x+$1.y})!
        self.dimension = SIMD2<Int>(last.x+1,last.y+1)
        super.init()
        do {
            try catchInitError()
        } catch {
            print(error)
            fatalError()
        }
    }
    
    private func catchInitError() throws {
        if self.values.count != self.dimension.x * self.dimension.y {
            print("Value Count: ", self.values.count)
            print("Dimensions: ", self.dimension)
            throw MatrixError.invalidSize
        }
    }
    
    enum MatrixError: Error {
        case invalidSize
        case Inconsistent
    }
    
    // MARK: Computed Properties
    private func compartmentalize(List: [Any], Width: Int) -> [[Any]]{
        var Values = [[Any]]()
        var compartment = [Any]()
        for (index,i) in List.enumerated() {
            compartment.append(i)
            if index % Width == Width - 1 {
                Values.append(compartment)
                compartment = [Any]()
            }
        }
        return Values
    }
    
    override var description: String { repr() }
    
    var rows: [[T]] {
        get {
            let unorganizedRows = ((compartmentalize(List: self.values.sorted(by: { if $0.key.y == $1.key.y { return $0.key.x < $1.key.x} else { return $0.key.y < $1.key.y } }).map({return ($0.key.x,$0.value)}), Width: self.dimension.x) as! [[(Int, T)]]) )
            return unorganizedRows.map({row in (row.sorted(by: {$0.0 < $1.0})).map({$0.1})})
        }
    }
    
    var columns: [[T]] {
        get {
            let unorganizedColumn = ((compartmentalize(List: self.values.sorted(by: { if $0.key.x == $1.key.x { return $0.key.y < $1.key.y} else { return $0.key.x < $1.key.x } }).map({return ($0.key.x, $0.value)}), Width: self.dimension.y) as! [[(Int, T)]]) )
            return unorganizedColumn.map({column in (column.sorted(by: {$0.0 < $1.0})).map({$0.1})})
        }
    }
    
    var transpose: Matrix<T> {
        var Values: [SIMD2<Int>: T] = [:]
        for i in values {
            Values[SIMD2<Int>(i.key.y,i.key.x)] = i.value
        }
        return Matrix(Values: Values)
    }
    
    var reduce: Matrix<T> {
        var Rows = rows
        for i in 0..<Rows.count {
            if Rows[i][i] == T(integerLiteral: 0) {
                if i != Rows.count - 1 {
                    if let firstRowIndex = Rows.enumerated().first(where: {$0.element[i] != T(integerLiteral: 0) && $0.offset > i})?.offset {
                        let tempRow = Rows[i]
                        Rows[i] = Rows[firstRowIndex]
                        Rows[firstRowIndex] = tempRow
                    }
                }
            }
            if Rows[i][i] != T(integerLiteral: 0) {
                let first = Rows[i][i]
                Rows[i] = Rows[i].map({$0 / first})
                for row in 0..<Rows.count {
                    if row != i {
                        let firstCoefficient = Rows[row][i]
                        for column in 0..<Rows[0].count {
                            Rows[row][column] = Rows[row][column] - Rows[i][column] * firstCoefficient
                        }
                    }
                }
            }
        }
        return Matrix(Rows: Rows)
    }
    
    // MARK: Statics
    static func + (left: Matrix, right: Matrix)  -> Matrix {
        for x in 0..<left.dimension.x {
            for y in 0..<left.dimension.y {
                left.values[SIMD2<Int>(x,y)] = left.values[SIMD2<Int>(x,y)]! + right.values[SIMD2<Int>(x,y)]!
            }
        }
        return left
        
    }
    
    static func - (left: Matrix, right: Matrix)  -> Matrix {
        for x in 0..<left.dimension.x {
            for y in 0..<left.dimension.y {
                left.values[SIMD2<Int>(x,y)] = left.values[SIMD2<Int>(x,y)]! - right.values[SIMD2<Int>(x,y)]!
            }
        }
        return left
        
    }
    
    static func * (left: Matrix<T>, right: Matrix<T>) -> Matrix<T> {
        var Output = [[T]]()
        for y in 0..<left.dimension.y {
            var Values = [T]()
            for x in 0..<right.dimension.x {
                var value = T(integerLiteral: 0)
                for j in 0..<right.dimension.y {
                    value = value + left.values[SIMD2<Int>(j,y)]! * right.values[SIMD2<Int>(x,j)]!
                }
                Values.append(value)
            }
            Output.append(Values)
        }
        return Matrix(Rows: Output)
    }
    
    static func * (left: Matrix<T>, right: T) -> Matrix<T> {
        var Output = [[T]]()
        for x in 0..<left.dimension.x {
            var values = [T]()
            for y in 0..<left.dimension.y {
                values.append(left.values[SIMD2(x, y)]! * right)
            }
            Output.append(values)
        }
        return Matrix(Rows: Output)
    }
    
    static func identity(_ Degree: Int) -> Matrix {
        var Values = [[T]]()
        var Row = [T]()
        for i in 0..<Degree {
            Row.append(contentsOf: Array(repeating: T(integerLiteral: 0), count: i))
            Row.append(T(integerLiteral: 1))
            Row.append(contentsOf: Array(repeating: T(integerLiteral: 0), count: Degree - i - 1))
            Values.append(Row)
            Row = [T]()
        }
        return Matrix(Rows: Values)
    }
    
    func displayMatrix() {
        for i in rows {
            print(i.map{"\($0), "}.reduce("[ ", +) + "]")
        }
    }
    
    func augment(_ results: [T]) throws -> Matrix {
        if results.count != self.dimension.y {
            throw MatrixError.invalidSize
        }
        var Values = values
        for (index,i) in results.enumerated() {
            Values[SIMD2<Int>(self.dimension.x,index)] = i
        }
        return Matrix(Values: Values)
    }
    func augment(_ matrices: Matrix<T>...) throws -> Matrix<T> {
        var Values = self.values
        var shift = self.dimension.x
        for i in matrices {
            for k in i.values {
                Values[SIMD2<Int>(k.key.x+shift,k.key.y)] = k.value
            }
            shift += i.dimension.x
        }
        return Matrix(Values: Values)
    }
    func solve() -> [T] {
        return reduce.columns.last!
    }
    
    func repr() -> String {
        var Rows = rows.map({$0.map({ "\($0)"})})
        for i in 0..<Rows[0].count {
            let maxSize = Rows.map({$0[i].count}).max()!+1
            for k in 0..<Rows.count {
                Rows[k][i] += Array(repeating: " ", count: maxSize - Rows[k][i].count)
            }
        }
        var output = ""
        for (index,i) in Rows.enumerated() {
            if index == 0 {
                output += i.reduce("⎡",+)+"⎤\n"
            }else if index == Rows.count - 1 {
                output += i.reduce("⎣",+)+"⎦\n"
            }else {
                output += i.reduce("⎢",+)+"⎢\n"
            }
        }
        return output
    }
    
    static func rotationMatrix(rotation: SIMD3<Float>) -> Matrix<Float> {
        let Rx = Matrix<Float>(Rows: [[1, 0, 0],
                                      [0, cos(rotation.x), -1 * sin(rotation.x)],
                                      [0, sin(rotation.x), cos(rotation.x)]])
        let Ry = Matrix<Float>(Rows: [[cos(rotation.y), 0, sin(rotation.y)],
                                      [0, 1, 0],
                                      [-sin(rotation.y), 0, cos(rotation.y)]])
        let Rz = Matrix<Float>(Rows: [[cos(rotation.z), -sin(rotation.z), 0],
                                      [sin(rotation.z), cos(rotation.z), 0],
                                      [0, 0, 1]]);
        return Rx * Ry * Rz;
    }
    
    static func rotationMatrix(rotation: SIMD3<Float>) -> float3x3 {
        let matrix: Matrix<Float> = rotationMatrix(rotation: rotation)
        return float3x3(rows: matrix.rows.map({
            SIMD3<Float>($0[0], $0[1], $0[2])
        }))
    }

}
