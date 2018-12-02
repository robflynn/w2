import then
import Commander

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

func listWebsites() {
    let websites = try! await(api.websites()) 

    for website in websites {
        print(website.name)
    }
}

// get list of websites
let api = Client()



print("hi. i'm webster. /\\oo/\\")
print("")

Group {
    $0.command("list") { listWebsites() }
}.run()
