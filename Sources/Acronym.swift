import StORM
import PostgresStORM

class Acronym: PostgresStORM, AcronymTemplates {
    var id: Int = 0
    var short: String = ""
    var long: String = ""

    override open func table() -> String { return "acronyms" }
    override func to(_ this: StORMRow) {
        id = this.data["id"] as? Int ?? 0
        short = this.data["short"] as? String ?? ""
        long = this.data["long"] as? String ?? ""
    }

    func rows() -> [Acronym] {
        var rows = [Acronym]()
        for i in 0..<self.results.rows.count {
            let row = Acronym()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }

    func some()  {
       // self.results.rows.map { ($0, Acronym()) }.forEach{ $0.1.to($0.) }
    }

}
