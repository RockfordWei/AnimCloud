# AnimCloud

本程序用于回答@Jackyyu关于如何使用iOS发送JSON到服务器的有关问题。

## 快速上手

打开终端命令行，执行

```
git clone https://github.com/RockfordWei/AnimCloud.git
cd AnimCloud && swift run
```

如果成功，应该看到结果：

```
[INFO] Starting HTTP server  on 0.0.0.0:8383
服务器收到内容并解码：
=================
Animation(anime: AnimCloud.Animation.Anime(name:
"『聖闘士星矢』（セイントセイヤ、SAINT SEIYA", picUrl:
"https://gss2.bdstatic.com/-fo3dSag_xI4khGkpoWK1HF6hhy/baike/h%3D250/sign=fb27507909f41bd5c553eff161db81a0/8718367adab44aeda84a09b6b41c8701a18bfb58.jpg",
picCopyright: "車田正美 東映動畫 百度百科"), characters:
[AnimCloud.Animation.AnimeCharacter(name: "城戸 沙織", birth: "1973-09-01",
picUrl: "https://gss0.bdstatic.com/94o3dSag_xI4khGkpoWK1HF6hhy/baike/c0%3Dbaike72%2C5%2C5%2C72%2C24/sign=aefe3e040b33874488c8272e3066b29c/a71ea8d3fd1f4134cfd0652a221f95cad0c85efa.jpg",
picCopyright: "車田正美 東映動畫 百度百科"), AnimCloud.Animation.AnimeCharacter(name:
"天馬星座の星矢", birth: "1973-12-01", picUrl: "https://gss1.bdstatic.com/9vo3dSag_xI4khGkpoWK1HF6hhy/baike/w%3D268/sign=c870739fca11728b302d8b24f0fdc3b3/0eb30f2442a7d933d1e5187daa4bd11373f0016a.jpg",
picCopyright: "車田正美 東映動畫 百度百科")])
=================
------- iOS接收服务器返回： 成功 --------
```

## JSON 格式

来自@Jackyyu原文：
``` json
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
```

Swift  结构设计（在iOS和Perfect服务器上共享代码）：

``` swift
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
```

除了上传用的结构之外，移动端和服务器还需要共同的反馈结构：

``` swift
// 定义一个用于服务器返回的结构
public struct ServerResult: Codable {
  public var success = true
  public init() { }
}
```

## iOS 移动端

移动端上传数据分三步：

1: 填写数据,
2: 编码,
3: 发送

### 填写数据

请参考源代码学习如何手工填写数据，关于自动填写数据如网络粘贴、用户输入等，不在本项目范围内。

### 编码

假定有一个Animation的实例`anime`，则编码过程为：

``` swift
let json = try JSONEncoder().encode(anime)
```

其中的JSONEncoder编码器实例建议在应用程序中单例即可，即 `let jsonEncoder = JSONEncoder()`

### 上传数据

``` swift
var req = URLRequest(url: url) // url 应该指向 /api/anime ，与服务器一致
req.httpMethod = "POST"
// 记住哈，json是从Codabale用JSONEncoder编码出来的
req.httpBody = json
let session = URLSession(configuration: URLSessionConfiguration.default)
let task = session.dataTask(with: req) { data, _, _ in
  guard let dat = data,
  let ret = try? JSONDecoder().decode(ServerResult.self, from: dat)
  else {
    // 服务器访问失败
  }
  // 服务器返回成功，请检查 ret.success
}
task.resume()
```

## 服务器接收

``` swift
routes.add(Route(method: .post, uri: "/api/anime", handler: {
  request, response in
  response.setHeader(.contentType, value: "text/json")
  let json = Data(bytes: request.postBodyBytes ?? [])
  var result = ServerResult()
  if let ani = try? JSONDecoder().decode(Animation.self, from: json) {
    // 内容收悉，解码成功
    result.success = true
  }else {
    // 失败
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
```
