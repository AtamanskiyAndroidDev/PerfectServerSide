import StORM
import PostgresStORM

protocol AcronymTemplates {
    func asDictionary() -> [String: Any]
}

extension AcronymTemplates where Self: PostgresStORM {

    func rows() -> [Self] {
        var rows = [Self]()
        for i in 0..<self.results.rows.count {
            let row = Self()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }
    
}
