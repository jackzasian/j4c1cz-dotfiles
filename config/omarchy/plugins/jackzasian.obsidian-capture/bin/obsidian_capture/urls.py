"""URL helpers shared by link capture and Zen bookmark sync."""

from __future__ import annotations

import html
import re
import urllib.error
import urllib.parse
import urllib.request

URL_RE = re.compile(r"https?://[^\s<>\]\"']+")
MD_LINK_RE = re.compile(r"\[([^\]]*)\]\((https?://[^)]+)\)")
TRACKING = {"gclid", "fbclid", "ref", "spm_id_from", "vd_source", "from_source", "search_source"}

USER_AGENT = "obsidian-capture/1.0"


def normalize_url(url: str) -> str:
    url = html.unescape(url.strip().rstrip(".,;)]}>\"'"))
    try:
        p = urllib.parse.urlparse(url)
        q = urllib.parse.parse_qs(p.query, keep_blank_values=True)
        q = {
            k: v
            for k, v in q.items()
            if not k.lower().startswith("utm_") and k not in TRACKING
        }
        query = urllib.parse.urlencode({k: v[0] for k, v in q.items()}) if q else ""
        path = p.path.rstrip("/") if p.path != "/" else p.path
        return urllib.parse.urlunparse((p.scheme, p.netloc, path, "", query, ""))
    except Exception:
        return url.rstrip("/")


def url_key(url: str) -> tuple:
    u = normalize_url(url)
    p = urllib.parse.urlparse(u)
    return (p.netloc.lower().removeprefix("www."), p.path.rstrip("/").lower(), p.query)


def extract_url(text: str) -> str | None:
    if not text:
        return None
    text = text.strip()
    if re.fullmatch(r"https?://\S+", text):
        return text
    m = URL_RE.search(text)
    return m.group(0) if m else None


def fetch_title(url: str) -> str:
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": USER_AGENT},
            method="GET",
        )
        with urllib.request.urlopen(req, timeout=2) as resp:
            raw = resp.read(65536)
            ctype = (resp.headers.get("Content-Type") or "").lower()
        if "html" not in ctype and b"<title" not in raw[:2048].lower():
            raise ValueError("not html")
        text = raw.decode("utf-8", errors="ignore")
        m = re.search(r"<title[^>]*>(.*?)</title>", text, re.I | re.S)
        if not m:
            raise ValueError("no title")
        title = html.unescape(re.sub(r"\s+", " ", m.group(1))).strip()
        title = re.sub(r"\s*[|\-–—]\s*.*$", "", title).strip() or title
        if len(title) > 90:
            title = title[:87] + "…"
        if title:
            return title
    except Exception:
        pass
    host = urllib.parse.urlparse(url).netloc.removeprefix("www.")
    return host or "Untitled"


def md_escape_title(title: str) -> str:
    return title.replace("[", "(").replace("]", ")")


def decode_park_url(url: str) -> str:
    """Unwrap Zen's park.html redirect wrapper, if present."""
    if "park.html" in url and "url=" in url:
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(url).query)
        if "url" in qs:
            return urllib.parse.unquote(qs["url"][0])
    return url


def skip_url(url: str) -> bool:
    if not url:
        return True
    u = url.lower()
    return u.startswith(("place:", "about:", "chrome:", "resource:"))


def clean_title(title: str, url: str) -> str:
    t = (title or "").strip()
    t = re.sub(r"^\(\d+\)\s*", "", t)
    t = re.sub(r"\s*-\s*YouTube$", "", t)
    t = html.unescape(t)
    t = re.sub(r"\s+", " ", t).strip()
    if not t or t in ("x", "New chat") or "ççç" in t:
        host = urllib.parse.urlparse(url).netloc.removeprefix("www.")
        return host or "Untitled"
    if len(t) > 90:
        t = t[:87] + "…"
    return t