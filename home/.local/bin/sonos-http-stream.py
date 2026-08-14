#!/usr/bin/env python3
"""Serve the sonos_stream sink monitor as a live HTTP MP3 stream for the Sonos Roam."""
import queue
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MONITOR = "sonos_stream.monitor"
PORT = 8071
SAMPLE_RATE = 44100
BITRATE = "192k"

FFMPEG_CMD = [
    "ffmpeg", "-hide_banner", "-loglevel", "error",
    "-f", "pulse", "-i", MONITOR,
    "-ar", str(SAMPLE_RATE), "-ac", "2",
    "-c:a", "libmp3lame", "-b:a", BITRATE,
    "-f", "mp3", "pipe:1",
]


class MP3Stream:
    def __init__(self):
        self._lock = threading.Lock()
        self._clients = {}
        self._next_id = 0
        self._ffmpeg = None
        self._start_ffmpeg()

    def _start_ffmpeg(self):
        self._ffmpeg = subprocess.Popen(
            FFMPEG_CMD, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
        )
        threading.Thread(target=self._pump, daemon=True).start()

    def _pump(self):
        while True:
            chunk = self._ffmpeg.stdout.read(8192)
            if not chunk:
                break
            with self._lock:
                for q in list(self._clients.values()):
                    try:
                        q.put_nowait(chunk)
                    except queue.Full:
                        pass
        with self._lock:
            self._clients.clear()
        self._start_ffmpeg()

    def subscribe(self):
        with self._lock:
            cid = self._next_id
            self._next_id += 1
            q = queue.Queue(maxsize=32)
            self._clients[cid] = q
            return cid, q

    def unsubscribe(self, cid):
        with self._lock:
            self._clients.pop(cid, None)


STREAM = MP3Stream()


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        if self.path.split("?")[0] not in ("/sonos.mp3", "/stream", "/"):
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", "audio/mpeg")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.send_header("Accept-Ranges", "none")
        self.end_headers()
        cid, q = STREAM.subscribe()
        try:
            while True:
                chunk = q.get(timeout=15)
                if chunk is None:
                    break
                self.wfile.write(chunk)
                self.wfile.flush()
        except (queue.Empty, BrokenPipeError, ConnectionResetError, OSError):
            pass
        finally:
            STREAM.unsubscribe(cid)

    def log_message(self, fmt, *args):
        sys.stderr.write("[sonos-stream] %s\n" % (fmt % args))


def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"Sonos stream server listening on :{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
