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

let setupObj = Acronym()
try? setupObj.setup()


let server = HTTPServer()
server.serverPort = 8180

func addUser(request: HTTPRequest, responce: HTTPResponse) {
    do {
        guard let json = request.postBodyString,
            let dict = try json.jsonDecode() as? [String: String],
            let short = dict["short"],
            let long = dict["long"] else {
                responce.completed(status: .badRequest)
                return
        }

        let acronym = Acronym()
        acronym.short = short
        acronym.long = long
        try acronym.save{ id in
            acronym.id = id as! Int
        }

        try responce.setBody(json: acronym.asDictionary())
            .setHeader(.contentType, value: "application/json")
            .completed()
    } catch {
        responce.setBody(string: "Error handling request \(error)")
        .completed(status: .internalServerError)
    }
}

func getAll(request: HTTPRequest, responce: HTTPResponse) {
    do {
        let getAll = Acronym()
        let params = request.queryParams
        let _ = try params.map{ key, value in
            if key == "limits" {
                if let limits = Int(value) {
                    let cursor = StORMCursor(limit: limits, offset: 0)
                    try getAll.select(whereclause: "true", params: [], orderby: [], cursor: cursor)
                    var acronymsWithLimits: [[String: Any]] = []
                    for element in getAll.rows() {
                        acronymsWithLimits.append(element.asDictionary())
                    }
                    try responce.setBody(json: acronymsWithLimits)
                        .setHeader(.contentType, value: "application/json")
                        .completed()
                }
            }

        }

        try getAll.findAll()
        var acronyms: [[String: Any]] = []
        for row in getAll.rows() {
            acronyms.append(row.asDictionary())
        }

        try responce.setBody(json: acronyms)
        .setHeader(.contentType, value: "application/json")
        .completed()

    } catch {
        responce.setBody(string: "Error handling request \(error)")
            .completed(status: .internalServerError)
    }
}

var routes = Routes()
routes.add(method: .post, uri: "/add", handler: addUser(request:responce:))
routes.add(method: .get, uri: "getAll", handler: getAll(request:responce:))
//routes.add(method: .get, uri: "", handler: <#T##RequestHandler##RequestHandler##(HTTPRequest, HTTPResponse) -> ()#>)

server.addRoutes(routes)

do {
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err), msg: \(msg)")
}
