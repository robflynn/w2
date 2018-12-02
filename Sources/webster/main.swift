import then

protocol API {

}

extension API {

}

struct Website {
    var name: String
}

class Client: API {
    func websites() -> Promise<[Website]> {
        return Promise<[Website]> { resolve, reject in 
            resolve([Website(name: "Google"), Website(name: "Apple")])
        }        
    }
}

// get list of websites
let api = Client()

let websites = try! await(api.websites())

for website in websites {
    print(website.name)
}
