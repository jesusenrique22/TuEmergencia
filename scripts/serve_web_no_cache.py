#!/usr/bin/env python3
"""Sirve build/web + proxy API :3000 y gateway/socket.io :3001 (un túnel :8088)."""
from __future__ import annotations

import argparse
import gzip
import http.client
import mimetypes
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

API_HOST = "127.0.0.1"
API_PORT = 3000
GATEWAY_PORT = 3001

_DEV_SW_CLEANUP = b"""<script>
(function(){if(!('serviceWorker'in navigator))return;
navigator.serviceWorker.getRegistrations().then(function(r){r.forEach(function(x){x.unregister();});});
if('caches'in window){caches.keys().then(function(k){k.forEach(function(n){caches.delete(n);});});}
})();</script>
"""


class TunnelWebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **getattr(SimpleHTTPRequestHandler, "extensions_map", {}),
        ".otf": "font/otf",
        ".ttf": "font/ttf",
        ".woff": "font/woff",
        ".woff2": "font/woff2",
    }

    _gzip_types = {".js", ".json", ".wasm", ".html", ".css", ".svg"}

    def _resolve_proxy(self) -> tuple[int, str] | None:
        """Devuelve (puerto_local, ruta_con_query) o None si es archivo estático."""
        path_only = self.path.split("?", 1)[0]
        if path_only.startswith("/socket.io"):
            return GATEWAY_PORT, self.path
        if path_only == "/gateway-health":
            query = ""
            if "?" in self.path:
                query = "?" + self.path.split("?", 1)[1]
            return GATEWAY_PORT, "/health" + query
        if path_only.startswith("/api") or path_only == "/health":
            return API_PORT, self.path
        return None

    def _should_gzip(self, fs_path: str) -> bool:
        if not os.path.isfile(fs_path):
            return False
        if Path(fs_path).suffix.lower() not in self._gzip_types:
            return False
        if "gzip" not in self.headers.get("Accept-Encoding", "").lower():
            return False
        return os.path.getsize(fs_path) >= 1024

    def _write_gzip_file(self, fs_path: str) -> None:
        with open(fs_path, "rb") as src:
            raw = src.read()
        compressed = gzip.compress(raw, compresslevel=6)
        self.send_response(200)
        ctype, _ = mimetypes.guess_type(fs_path)
        if ctype:
            self.send_header("Content-Type", ctype)
        self.send_header("Content-Encoding", "gzip")
        self.send_header("Content-Length", str(len(compressed)))
        self.send_header("Vary", "Accept-Encoding")
        self.end_headers()
        self.wfile.write(compressed)

    def _proxy(self, method: str) -> None:
        target = self._resolve_proxy()
        if target is None:
            self.send_error(404)
            return
        port, path = target
        length = int(self.headers.get("Content-Length", 0) or 0)
        body = self.rfile.read(length) if length else None
        headers = {
            k: v
            for k, v in self.headers.items()
            if k.lower() not in ("host", "connection", "content-length")
        }
        conn = http.client.HTTPConnection(API_HOST, port, timeout=15)
        try:
            conn.request(method, path, body=body, headers=headers)
            resp = conn.getresponse()
            data = resp.read()
            self.send_response(resp.status)
            for key, value in resp.getheaders():
                kl = key.lower()
                if kl in ("transfer-encoding", "connection", "etag", "last-modified"):
                    continue
                self.send_header(key, value)
            path_only = self.path.split("?", 1)[0]
            if path_only in ("/health", "/gateway-health") or path_only.startswith(
                "/socket.io"
            ):
                self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.end_headers()
            if data and method != "HEAD":
                self.wfile.write(data)
        except OSError as exc:
            label = "Gateway" if port == GATEWAY_PORT else "API"
            self.send_error(502, f"{label} :{port} no disponible: {exc}")
        finally:
            conn.close()

    def do_OPTIONS(self) -> None:
        if self._resolve_proxy() is not None:
            self.send_response(204)
            origin = self.headers.get("Origin", "*")
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Credentials", "true")
            self.send_header(
                "Access-Control-Allow-Headers",
                "Content-Type, Authorization, Accept, Origin, X-Requested-With",
            )
            self.send_header(
                "Access-Control-Allow-Methods",
                "GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS",
            )
            self.end_headers()
            return
        super().do_OPTIONS()

    def _dev_service_worker_js(self) -> bytes:
        """SW passthrough: sin caché agresiva en desarrollo (túneles / localhost)."""
        return b"""'use strict';
self.addEventListener('install', function(e) { self.skipWaiting(); });
self.addEventListener('activate', function(e) {
  e.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', function(e) {
  e.respondWith(fetch(e.request));
});
"""

    def _serve_index_html(self, fs_path: str) -> None:
        try:
            with open(fs_path, "rb") as src:
                raw = src.read()
        except OSError:
            self.send_error(404, "File not found")
            return
        marker = b"<body>"
        if marker in raw:
            raw = raw.replace(marker, marker + _DEV_SW_CLEANUP, 1)
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:
        path_only = self.path.split("?", 1)[0]
        if path_only == "/flutter_service_worker.js":
            body = self._dev_service_worker_js()
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.end_headers()
            self.wfile.write(body)
            return
        if self._resolve_proxy() is not None:
            self._proxy("GET")
            return
        fs_path = self.translate_path(self.path)
        if path_only in ("", "/", "/index.html") and fs_path.endswith("index.html"):
            self._serve_index_html(fs_path)
            return
        if self._should_gzip(fs_path):
            try:
                self._write_gzip_file(fs_path)
            except OSError:
                self.send_error(404, "File not found")
            return
        super().do_GET()

    def do_HEAD(self) -> None:
        if self._resolve_proxy() is not None:
            self._proxy("HEAD")
            return
        fs_path = self.translate_path(self.path)
        if self._should_gzip(fs_path):
            try:
                with open(fs_path, "rb") as src:
                    size = len(gzip.compress(src.read(), compresslevel=6))
                self.send_response(200)
                ctype, _ = mimetypes.guess_type(fs_path)
                if ctype:
                    self.send_header("Content-Type", ctype)
                self.send_header("Content-Encoding", "gzip")
                self.send_header("Content-Length", str(size))
                self.send_header("Vary", "Accept-Encoding")
                self.end_headers()
            except OSError:
                self.send_error(404, "File not found")
            return
        super().do_HEAD()

    def do_POST(self) -> None:
        if self._resolve_proxy() is not None:
            self._proxy("POST")
        else:
            super().do_POST()

    def do_PUT(self) -> None:
        if self._resolve_proxy() is not None:
            self._proxy("PUT")
        else:
            super().do_PUT()

    def do_PATCH(self) -> None:
        if self._resolve_proxy() is not None:
            self._proxy("PATCH")
        else:
            super().do_PATCH()

    def do_DELETE(self) -> None:
        if self._resolve_proxy() is not None:
            self._proxy("DELETE")
        else:
            super().do_DELETE()

    def end_headers(self) -> None:
        path = self.path.split("?", 1)[0]
        if path.endswith((".otf", ".ttf", ".woff", ".woff2")):
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "public, max-age=86400")
        elif path in ("", "/", "/index.html") or path.endswith(
            (
                ".html",
                ".js",
                ".json",
                "flutter_bootstrap.js",
                "flutter_service_worker.js",
            )
        ):
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.send_header("Pragma", "no-cache")
            self.send_header("Expires", "0")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8088)
    parser.add_argument(
        "--directory",
        default="build/web",
        help="Carpeta del build Flutter web",
    )
    args = parser.parse_args()
    os.chdir(args.directory)
    server = ThreadingHTTPServer(("0.0.0.0", args.port), TunnelWebHandler)
    print(
        f"Serving {os.getcwd()} on http://0.0.0.0:{args.port} "
        f"(gzip, proxy /api→:{API_PORT}, /socket.io→:{GATEWAY_PORT})"
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
