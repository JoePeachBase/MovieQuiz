import Foundation

struct GameResult {
    let correct: Int
    let total: Int
    let date: Date
    
    func isBetterThan(of another: GameResult) -> Bool {
        correct > another.correct
    }
}
