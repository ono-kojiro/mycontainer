var fs = require('fs');

function loadKeys() {
    // JSONファイルを読み込む
    var text = fs.readFileSync('/etc/nginx/api_key/api_keys.json', 'utf8');

    // JSONをパース
    var data = JSON.parse(text);

    // api_keys 配列を返す
    return data.api_keys;
}

function check(r) {
    var clientKey = r.headersIn['X-API-Key'];
    if (!clientKey) {
        r.return(403);
        return;
    }

    var entries = loadKeys();

    // API Key を照合
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].key === clientKey) {
            // ログにユーザー名を残す
            r.log("API Key matched for user: " + entries[i].user);

            let target = r.uri;
            if (!target.endsWith("/")) {
                target = target + "/"
            }

            // 認証成功 → CouchDB へ内部リダイレクト
            return r.internalRedirect(target);
        }
    }

    // 認証失敗
    r.return(403, "Forbidden");
}

export default {check};

