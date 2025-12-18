
//
//  UpdateChecker.swift
//

import Foundation

/** PGYER 检测APP版本更新.*/

struct UpdateChecker {
    var _api_key: String
    
    let HOSTS: [String] = [
        "www.xcxwo.com",
        "www.pgyerapp.com",
    ]

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
        // 构建参数
        let parameters: [String: Any] = [
            "_api_key": _api_key,
            "appKey": appKey,
            "buildVersion": buildVersion,
            "buildBuildVersion": buildBuildVersion,
            "channelKey": channelKey
        ]
        
        // 从第一个 HOST 开始尝试
        self.tryCheck(hostIndex: 0, parameters: parameters, success: success, fail: fail)
    }
    
    /// 尝试 HOST 列表中的服务器，如果失败则尝试下一个
    private func tryCheck(
        hostIndex: Int,
        parameters: [String: Any],
        success: @escaping (UpdateInfo) -> (),
        fail: @escaping ((code: Int, message: String)) -> ()
    ) {
        // 如果所有 HOST 都尝试过了，返回失败
        guard hostIndex < HOSTS.count else {
            fail((503, "Error: 所有服务器都无法访问"))
            return
        }
        
        let host = HOSTS[hostIndex]
        guard let url = URL(string: "https://\(host)/apiv2/app/check") else {
            // URL 构建失败，尝试下一个
            tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
            return
        }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBuildQuery(parameters).data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 处理网络错误
            if let _ = error {
                // 尝试下一个 HOST
                self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
                return
            }

            // 处理 HTTP 状态码错误
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    // 尝试下一个 HOST
                    self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
                    return
                }
            }

            guard let data = data else {
                // 尝试下一个 HOST
                self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
                return
            }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let json = jsonObject as? [String: Any] {
                    let code = json["code"] as? Int ?? 0
                    
                    // 如果返回的业务错误码不为 0，可能是参数错误，不切换 HOST
                    if code != 0 {
                        let message = json["message"] as? String ?? "未知错误"
                        fail((code, "Error: \(message)"))
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
                        // 尝试下一个 HOST
                        self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
                        return
                    }
                } else {
                    // 尝试下一个 HOST
                    self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
                    return
                }
            } catch {
                // 尝试下一个 HOST
                self.tryCheck(hostIndex: hostIndex + 1, parameters: parameters, success: success, fail: fail)
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
