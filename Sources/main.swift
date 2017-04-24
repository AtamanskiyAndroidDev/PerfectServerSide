import PerfectLib
import PerfectHTTPServer
import PerfectHTTP

import StORM
import PostgresStORM

PostgresConnector.host = "localhost"
PostgresConnector.username = "perfect"
PostgresConnector.password = "perfect"
PostgresConnector.database = "perfect_testing"
PostgresConnector.port = 5432

let setupUser = User()
try? setupUser.setup()


let server = HTTPServer()
server.serverPort = 8180

func addUser(request: HTTPRequest, response: HTTPResponse) {
    do {
        guard let json = request.postBodyString,
            let dict = try json.jsonDecode() as? [String: String],
            let name = dict["name"],
            let email = dict["email"],
            let password = dict["password"] else {
                setupErrorBody(with: ["msg": "Wrong key"], response: response)
                return
        }
        if !validate(email: email, password: password) {
            setupErrorBody(with: ["msg": "This user already exist"], response: response)
            return
        }
        let user = User()
        user.name = name
        user.email = email
        user.password = password
        try user.save{ id in
            user.id = id as! Int
        }

        try response.setBody(json: user.asDictionary())
            .setHeader(.contentType, value: "application/json")
            .completed()
    } catch {
        response.setBody(string: "Error handling request \(error)")
        .completed(status: .internalServerError)
    }
}

func setupErrorBody(with message: [String: String], response: HTTPResponse) {
    do {
        try response.setBody(json: message)
            .setHeader(.contentType, value: "application/json")
            .completed(status: .badRequest)
    } catch {
        response.setBody(string: "Error handling request \(error)")
            .completed(status: .internalServerError)
    }
}

func getAll(request: HTTPRequest, response: HTTPResponse) {
    do {
        let getAll = User()
        let params = request.queryParams
        let _ = try params.map{ key, value in
            if key == "limits" {
                if let limits = Int(value) {
                    let cursor = StORMCursor(limit: limits, offset: 0)
                    try getAll.select(whereclause: "true", params: [], orderby: [], cursor: cursor)
                    var usersWithLimits: [[String: Any]] = []
                    for element in getAll.rows() {
                        usersWithLimits.append(element.asDictionary())
                    }
                    try response.setBody(json: usersWithLimits)
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                }
            }

        }

        try getAll.findAll()
        var users: [[String: Any]] = []
        for row in getAll.rows() {
            users.append(row.asDictionary())
        }

        try response.setBody(json: users)
        .setHeader(.contentType, value: "application/json")
        .completed()

    } catch {
        response.setBody(string: "Error handling request \(error)")
            .completed(status: .internalServerError)
    }
}

func login(request: HTTPRequest, response: HTTPResponse) {
    do {
        let user = User()
        let params = request.queryParams
        let _ = try params.map{ key, value in
            guard let email = key.isEqual(v: "email"),
                let password = key.isEqual(v: "password") else {
                    setupErrorBody(with: ["msg": "Wrong key"], response: response)
                    return
            }
            try user.find(["email": email])
            guard let currentUser = user.rows().first else { return }
            if !(currentUser.password == password) {
                setupErrorBody(with: ["msg": "Incorrect email or password"], response: response)
                return
            }
        }
    } catch {
        setupErrorBody(with: ["msg": "Incorrect email or password"], response: response)
        return
    }
    
}

func validate(email: String, password: String) -> Bool {
    do {
        let users = User()
        try users.find(["email" : email])
        return users.rows().count == 0
    } catch {
        return false
    }
}

var routes = Routes()
routes.add(method: .post, uri: "/register", handler: addUser(request:response:))
routes.add(method: .get, uri: "/getAll", handler: getAll(request:response:))
routes.add(method: .get, uri: "/login", handler: login(request:response:))

server.addRoutes(routes)

do {
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err), msg: \(msg)")
}
