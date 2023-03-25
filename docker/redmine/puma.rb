port 3000

ssl_bind '0.0.0.0', '3000', {
  cert_pem: "/usr/src/redmine/redmine.crt",
  key_pem:  "/usr/src/redmine/redmine.key",
  verify_mode: "none"
}

