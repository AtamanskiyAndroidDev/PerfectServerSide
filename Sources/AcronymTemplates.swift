import StORM
import PostgresStORM

protocol AcronymTemplates {

    var id: Int { get }
    var short: String { get }
    var long: String { get }

}

extension AcronymTemplates where Self: PostgresStORM {

    func asDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "short": self.short,
            "long": self.long
        ]
    }

//    func rows() -> [Self] {
//        var rows = [Self]()
//        for i in 0..<self.results.rows.count {
//            let row = Self()
//            row.to(self.results.rows[i])
//            rows.append(row)
//        }
//        return rows
//    }

}
