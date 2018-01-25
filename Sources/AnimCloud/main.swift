import Foundation
import Dispatch
import PerfectHTTP
import PerfectHTTPServer
/* 第一步，json格式标准化
 {
 "anime":{
 "name":"",
 "picUrl":"", // a url to the anime's pic (JPEG format, 200px*200px)
 "picCopyright":"" // a description of the copyright info of the pic, e.g. "pixiv, pidXXX", "Offical LOGO, http://xxx.png"
 },
 "characters":[ // an array which includes all the characters in the anime
 {
 "name":"",
 "birth":"", // the birth of the character, "MM-dd" formatted. e.g. "09-06" for Sept.6
 "picUrl":"", // a url to the anime's pic (JPEG format, 200px*200px)
 "picCopyright":"" // a description of the copyright info of the pic, e.g. "pixiv, pidXXX", "CHARACTERS | 「妹さえいればいい。」\nhttp://.../chara_itsuki.png"
 }
 ]
 }

 以下是上述json的实现数据结构
 */

public struct Animation: Codable {

  public struct Anime: Codable {
    public var name = ""
    public var picUrl = ""
    public var picCopyright = ""
    public init() { }
  }

  public struct AnimeCharacter: Codable {
    public var name = ""
    public var birth = ""
    public var picUrl = ""
    public var picCopyright = ""
    public init() { }
  }

  public var anime = Anime()
  public var characters: [AnimeCharacter] = []
  public init() {}
}

// 示范如何使用结构数据
var saintSeiya = Animation()
saintSeiya.anime.name = "『聖闘士星矢』（セイントセイヤ、SAINT SEIYA"
saintSeiya.anime.picUrl = "https://gss2.bdstatic.com/-fo3dSag_xI4khGkpoWK1HF6hhy/baike/h%3D250/sign=fb27507909f41bd5c553eff161db81a0/8718367adab44aeda84a09b6b41c8701a18bfb58.jpg"
saintSeiya.anime.picCopyright = "車田正美 東映動畫 百度百科"

var athena = Animation.AnimeCharacter()
athena.name = "城戸 沙織"
athena.birth = "1973-09-01"
athena.picUrl = "https://gss0.bdstatic.com/94o3dSag_xI4khGkpoWK1HF6hhy/baike/c0%3Dbaike72%2C5%2C5%2C72%2C24/sign=aefe3e040b33874488c8272e3066b29c/a71ea8d3fd1f4134cfd0652a221f95cad0c85efa.jpg"
athena.picCopyright = "車田正美 東映動畫 百度百科"

var pegasus = Animation.AnimeCharacter()
pegasus.name = "天馬星座の星矢"
pegasus.birth = "1973-12-01"
pegasus.picUrl = "https://gss1.bdstatic.com/9vo3dSag_xI4khGkpoWK1HF6hhy/baike/w%3D268/sign=c870739fca11728b302d8b24f0fdc3b3/0eb30f2442a7d933d1e5187daa4bd11373f0016a.jpg"
pegasus.picCopyright = "車田正美 東映動畫 百度百科"

saintSeiya.characters = [athena, pegasus]

// 定义一个用于服务器返回的结构
public struct ServerResult: Codable {
  public var success = true
  public init() { }
}

//  iOS 部分：把数据发送到服务器上
guard let url = URL(string: "http://localhost:8383/api/anime")  else { exit(-1) }
var req = URLRequest(url: url)
req.httpMethod = "POST"
// 记住哈，jsonData是从Codabale用JSONEncoder编码出来的
req.httpBody = try? JSONEncoder().encode(saintSeiya)
let session = URLSession(configuration: URLSessionConfiguration.default)
let task = session.dataTask(with: req) { data, _, _ in
  guard let dat = data,
    let ret = try? JSONDecoder().decode(ServerResult.self, from: dat)
    else {
    print("服务器访问失败")
    exit(-4)
  }
  print("------- iOS接收服务器返回：", ret.success ? "成功" : "失败", "--------" )
  exit(0)
}
// 等服务器启动（几秒钟）后
let que = DispatchQueue(label: "ios")
que.asyncAfter(deadline: .now() + 2.0) {
  task.resume()
}

//  服务器部分
let server = HTTPServer()
server.serverPort = 8383
var routes = Routes()
// 接收json请求
routes.add(Route(method: .post, uri: "/api/anime", handler: {
  request, response in
  response.setHeader(.contentType, value: "text/json")
  let json = Data(bytes: request.postBodyBytes ?? [])
  var result = ServerResult()
  if let ani = try? JSONDecoder().decode(Animation.self, from: json) {
    result.success = true
    print("服务器收到内容并解码：")
    print("=================")
    print(ani)
    print("=================")
  }else {
    result.success = false
  }
  guard let resultJSON = try? JSONEncoder().encode(result),
    let reply = String(bytes: resultJSON, encoding: .utf8)
    else {
      response.completed(status: .internalServerError)
      return
  }
  response.setBody(string: reply)
  response.completed()
}))
server.addRoutes(routes)
// 启动服务器
try? server.start()
