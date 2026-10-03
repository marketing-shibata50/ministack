# サンプル。中身は FastAPI / Express / Go など何に差し替えても良い
# 条件は「PORT で待ち受け」「/health が 200 を返す」の 2 つだけ
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = {"lang": "container", "path": self.path, "db_host": os.environ.get("DB_HOST")}
        if self.path == "/health":
            body = {"status": "ok"}
        data = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("content-type", "application/json")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
