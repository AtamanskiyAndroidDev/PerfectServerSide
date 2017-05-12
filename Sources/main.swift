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
            let dict = try json.jsonDecode() as? [String: Any],
            let name = dict["name"] as? String,
            let email = dict["email"] as? String,
            let password = dict["password"] as? String else {
                setupErrorBody(with: [
                    "body": ["msg": "Wrong key"],
                    "error": true], response: response)
                return
        }
        if !validate(email: email, password: password) {
            setupErrorBody(with: [
                "body": ["msg": "This user already exist"],
                "error": true], response: response)
            return
        }
        let user = User()
        user.name = name
        user.email = email
        user.password = password
        try user.save{ id in
            user.id = id as! Int
        }
        var dic: [String: Any] = [:]
        dic = ["error": false,
               "body": user.asDictionary()]
        try response.setBody(json: dic)
            .setHeader(.contentType, value: "application/json")
            .completed()
    } catch {
        response.setBody(string: "Error handling request \(error)")
        .completed(status: .internalServerError)
    }
}

func setupErrorBody<T>(with message: [String: T], response: HTTPResponse) {
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
        var email: String?
        var password: String?
        let _ = params.map{ key, value in
            if let _ = key.isEqual(v: "email") {
                email = value
            }
            if let _ = key.isEqual(v: "password") {
                password = value
            }
        }
        guard let userEmail = email,
                let userPassword = password else {
            setupErrorBody(with: ["body": ["msg": "Wrong key"],
                                  "error": true], response: response)
            return
        }
        try user.find(["email": userEmail])
        guard let currentUser = user.rows().first else {
            setupErrorBody(with: ["body": ["msg": "User not found"],
                "error": true], response: response)
            return
        }
        if !(currentUser.password == userPassword) {
            setupErrorBody(with: [
                "body": ["msg": "Incorrect email or password"],
                "error": true], response: response)
            return
        } else {

            var dic: [String: Any] = [:]
            dic = ["error": false,
                "body": currentUser.asDictionary()]
            try response.setBody(json: dic)
            .completed()
        }
    } catch {
        response.setBody(string: "Error handling request \(error)")
            .completed(status: .internalServerError)
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
