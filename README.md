# AppUpdateChecker

本仓库包含了 `PGYER` (蒲公英) 检查更新功能的代码片段，适用 `Android App` 、 `iOS App` 和 `uni-app`。

通过使用相应的代码片段, 可以在目标 `App` 中快速集成 `PGYER` (蒲公英) 检查更新功能。

### 实现细节

通过调用 `UpdateChecker` 的 `check` 方法, 间接调用 `PGYER` (蒲公英) 的后端 API。

具体参照:
[PGYER API 2.0: 检测 App 是否有更新](https://www.pgyer.com/doc/view/api#appUpdate)

### 使用方式

1. 根据项目类型拷贝 `iOS` / `Android` / `uni-app` 目录下的文件 (目录内只有一个文件) 到项目相应位置。
1. 按照下方代码示例在业务层面需要调用检查更新的地方添加调用代码即可。

- Android 项目调用示例 (Java)

```java
import <code_path>.UpdateChecker;
...
new UpdateChecker("<API_KEY>")
  .check(
    "<APP_KEY>",
    String.valueOf(BuildConfig.VERSION_CODE),
    null, // 未使用蒲公英生成的自增 Build 号
    null, // 未指定渠道
    new UpdateChecker.Callback() {
      @Override
      public void result(UpdateChecker.UpdateInfo updateInfo) {
      }

      @Override
      public void error(String message) {
      }
    }
  );
```

> Android 代码调用时, 如果无需传递可选参数，用 null 代替即可。

Android 的第二个参数 `buildVersion` 推荐传入**当前已安装 App** 的 `versionCode`，如上例的 `String.valueOf(BuildConfig.VERSION_CODE)`。请使用应用模块的 `BuildConfig`。

接口对纯数字字符串按 `versionCode` 比较；对 `1.2.3` 这类非纯数字字符串兼容按 `versionName` 比较。如果版本名称不变、只增加 `versionCode`，仅按名称比较无法识别更新。纯数字的 `versionName`（如 `"123"`）也会被当作 `versionCode`，因此推荐统一传 `versionCode`。

请求参数与响应字段的含义不同：

| 字段 | Android 中的含义 |
| ---- | ---- |
| 请求 `buildVersion` | 推荐传当前已安装 App 的 `versionCode` 字符串 |
| 响应 `buildVersion` | 服务端返回版本的 `versionName` |
| 响应 `buildVersionNo` | 服务端返回版本的 `versionCode` |
| `buildBuildVersion` | 蒲公英生成的自增 Build 号，不是 Android `versionCode`；请求时填写当前已安装版本对应的值，未使用时传 `null` |

- iOS 项目调用示例 (Swift)

```swift
UpdateChecker(_api_key: "<API_KEY>")
  .check(
    appKey: "<APP_KEY>",
    buildVersion: "<(可选)APP版本号>",
    buildBuildVersion: <(可选)(Int)使用蒲公英生成的自增 Build 版本号>,
    channelKey: "<(可选)渠道 KEY>",
    success: { info in
        print(info)
    },
    fail: { error in
        print(error)
    }
  )
```

- uni-app 项目调用示例 (JS)

```js
import UpdateChecker from '<code_path>/UpdateChecker.js';
...
new UpdateChecker("<API_KEY>")
  .check(
    "<APP_KEY>",
    "<(可选)APP版本号>",
    "<(可选)使用蒲公英生成的自增 Build 版本号>",
    "<(可选)渠道 KEY>",
    updateInfo => {
    },
    error => {
    },
  );
```

### 注意事项

1. 代码片段经过详细注释, 大部分 `IDE` 均可识别并用于类型提示和代码补全。
1. 代码片段中的代码不需要依赖任何第三方内容, 直接复制到项目中即可使用。
1. 使用此代码片段需要网络支持。
1. 对于字段内容存疑可以参照 API 文档 [PGYER API 2.0: 检测 App 是否有更新](https://www.pgyer.com/doc/view/api#appUpdate) 或者登录 PGYER 后在页面右下角的浮窗里联系技术支持即可。
1. `API Key` 需要在 `PGYER` 后台 `账户设置` -> `API 信息` 页面获得。
1. `App Key` 需要在 `PGYER` 后台 `应用管理` -> `应用` -> `安装设置` 页面获得。
