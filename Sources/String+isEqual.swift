import Foundation

extension String {
    
    func isEqual(v: String) -> String? {
        let res = self == v ? self : nil
        return res
    }
    
}
