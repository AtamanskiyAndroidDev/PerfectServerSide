import PostgresStORM
import StORM

class User: PostgresStORM, AcronymTemplates {
    
    var id: Int = 0
    var name: String = ""
    var email: String = ""
    var password: String = ""
    
    override open func table() -> String { return "users" }
    override func to(_ this: StORMRow) {
        id = this.data["id"] as? Int ?? 0
        name = this.data["name"] as? String ?? ""
        email = this.data["email"] as? String ?? ""
        password = this.data["password"] as? String ?? ""
    }
    
    func asDictionary() -> [String: Any] {
        return [
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "password": self.password,
        ]
    }
    
}
