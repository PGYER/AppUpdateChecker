
//
//  UpdateChecker.swift
//

import Foundation

/** PGYER 检测APP版本更新.*/

struct UpdateChecker {
    var _api_key: String

    /**
     检测App是否有更新.
          
         示例:
         UpdateChecker(_api_key: "<API_KEY>")
            .check(
                 appKey: "<APP_KEY>",
                 buildVersion: "<(选填)APP版本号>",
                 buildBuildVersion: <(选填)(Int)使用蒲公英生成的自增 Build 版本号>,
                 channelKey: "<(选填)渠道 KEY>",
                 success: { info in
                     print(info)
                 }, fail: { error in
                     print(error)
                 }
             )
     
     - Parameter appKey: (必填)(String) appKey.
     - Parameter buildVersion: (选填)(String) 使用 App 本身的 Build 版本号.
     - Parameter buildBuildVersion: (选填)(Int) 使用蒲公英生成的自增 Build 版本号.
     - Parameter channelKey: (选填)(String) 渠道 KEY.
     - Parameter success: (必填)获取数据成功回调.
     - Parameter fail: (必填)获取数据失败回调.
     
     [参考文档：https://www.pgyer.com/doc/view/api#appUpdate](https://www.pgyer.com/doc/view/api#appUpdate)
    */
    

    func check (
        appKey: String,
        buildVersion: String = "",
        buildBuildVersion: Int = 0,
        channelKey: String = "",
        success: @escaping (UpdateInfo) -> (),
        fail: @escaping ((
            code: Int,
            message: String
            )) -> ()
    ) {
        let url = URL(string: "https://p.frontjs.com/apiv2/app/check")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBuildQuery([
            "_api_key": _api_key,
            "appKey": appKey,
            "buildVersion": buildVersion,
            "buildBuildVersion": buildBuildVersion,
            "channelKey": channelKey
        ]).data(using: .utf8)


        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                fail ((501, "Error: \(error.localizedDescription)"))
                return
            }

            guard let data = data else {
                fail ((404, "Error: response empty"))
                return
            }
            

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let json = jsonObject as? [String: Any] {
                       let code = json["code"] as? Int ?? 0
                    if code != 0 {
                        let message = json["message"]
                        fail ((404, "Error: \(String(describing: message))"))
                           return
                    }

                    if let data = json["data"] as? [String: Any] {
                        success(UpdateInfo(
                            buildBuildVersion: Int(data["buildBuildVersion"] as? String ?? "0") ?? 0,
                            forceUpdateVersion: data["forceUpdateVersion"] as? String ?? "",
                            forceUpdateVersionNo: data["forceUpdateVersionNo"] as? String ?? "",
                            needForceUpdate: data["needForceUpdate"] as? Bool ?? false,
                            downloadURL: data["downloadURL"] as? String ?? "",
                            buildHaveNewVersion: data["buildHaveNewVersion"] as? Bool ?? false,
                            buildVersionNo: data["buildVersionNo"] as? String ?? "",
                            buildVersion: data["buildVersion"] as? String ?? "",
                            buildShortcutUrl: data["buildShortcutUrl"] as? String ?? "",
                            buildUpdateDescription: data["buildUpdateDescription"] as? String ?? ""
                        ))
                        return
                    } else {
                        fail ((404, "Error: no data"))
                        return
                    }
                }

                   fail ((404, "Error: response data parse fail"))
                return
            } catch {
                fail ((404, "Error: response data parse fail"))
                return
            }
        }

    task.resume()
    }
    
    /** 检测更新数据 */
    struct UpdateInfo {
        /** 蒲公英生成的用于区分历史版本的build号 */
        var buildBuildVersion: Int
        /** 强制更新版本号（未设置强置更新默认为空）*/
        var forceUpdateVersion: String
        /** 强制更新的版本编号*/
        var forceUpdateVersionNo: String
        /**是否强制更新*/
        var needForceUpdate: Bool
        /** 应用安装地址*/
        var downloadURL: String
        /** 是否有新版本*/
        var buildHaveNewVersion: Bool
        /** 上传包的版本编号，默认为1*/
        var buildVersionNo: String
        /** 版本号, 默认为1.0 (是应用向用户宣传时候用到的标识，例如：1.1、8.2.1等。)*/
        var buildVersion: String
        /** 应用短链接*/
        var buildShortcutUrl: String
        /** 应用更新说明*/
        var buildUpdateDescription: String
    }
    
    private func httpBuildQuery(_ parameters: [String: Any]) -> String {
        var components = URLComponents()
        components.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: "\(value)")
        }
        guard let str = components.percentEncodedQuery else {
            return ""
        }
        return str
    }
}
