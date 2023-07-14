function UpdateChecker(apiKey) {
    const APP_CHECK_URL = 'https://www.pgyer.com/apiv2/app/check';
    this.apiKey = apiKey;
    this.check = function (appKey, buildVersion, buildBuildVersion, channelKey, success, error) {
        uni.request({
            url: APP_CHECK_URL,
            method: 'POST',
            header: {
                'content-type': 'application/x-www-form-urlencoded',
            },
            data: {
                _api_key: this.apiKey,
                appKey: appKey,
                buildVersion: buildVersion || '',
                buildBuildVersion: buildBuildVersion || '',
                channelKey: channelKey || '',
            },
            /**
             * success 响应数据
             * buildBuildVersion Integer 蒲公英生成的用于区分历史版本的build号
             * forceUpdateVersion String  强制更新版本号（未设置强置更新默认为空）
             * forceUpdateVersionNo String 强制更新的版本编号
             * needForceUpdate Boolean 是否强制更新
             * downloadURL String 应用安装地址
             * buildHaveNewVersion Boolean 是否有新版本
             * buildVersionNo String 上传包的版本编号，默认为1 (即编译的版本号，一般来说，编译一次会变动一次这个版本号, 在 Android 上叫 Version Code。对于 iOS 来说，是字符串类型；对于 Android 来说是一个整数。例如：1001，28等。)
             * buildVersion String 版本号, 默认为1.0 (是应用向用户宣传时候用到的标识，例如：1.1、8.2.1等。)
             * buildShortcutUrl String 应用短链接
             * buildUpdateDescription String 应用更新说明
             */
            success: data => {
                const result = data.data;
                if (result.code != 0) {
                    error(result.message);
                    return false;
                }

                success(result.data);
            },
            fail: result => {
                error('network error');
            },
        });
    }
}

export default UpdateChecker
