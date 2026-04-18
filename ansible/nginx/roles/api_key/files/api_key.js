var fs = require('fs');

function loadKeys() {
    // JSONファイルを読み込む
    var text = fs.readFileSync('/etc/nginx/keys/api_keys.json', 'utf8');

    // JSONをパース
    var data = JSON.parse(text);

    // api_keys 配列を返す
    return data.api_keys;
}

function check(r) {
    var entries = loadKeys();
    var clientKey = r.headersIn['X-API-Key'];

    // API Key を照合
    for (var i = 0; i < entries.length; i++) {
        if (entries[i].key === clientKey) {
            // ログにユーザー名を残す
            r.log("API Key matched for user: " + entries[i].user);

            // 認証成功 → CouchDB へ内部リダイレクト
            return r.internalRedirect('@proxy');
        }
    }

    // 認証失敗
    r.return(403, "Forbidden");
}

export default {check};

