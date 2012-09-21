# Clam Bake

### Synopsis

* `GET /`: Simple test website for manually scanning URLs
* `POST /scan`: Requires: url param, must begin with http(s)? -- will download file at URL and scan with libclamav
* `PUT /reload`: Reload database from disk
