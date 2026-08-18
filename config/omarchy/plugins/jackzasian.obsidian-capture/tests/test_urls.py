"""Unit tests for URL helpers."""

from obsidian_capture import urls


def test_normalize_strips_tracking_params():
    assert urls.normalize_url("https://example.com/a?gclid=123&utm_source=x&keep=1") == "https://example.com/a?keep=1"


def test_normalize_strips_trailing_punctuation():
    assert urls.normalize_url("https://example.com/path/.") == "https://example.com/path"


def test_normalize_keeps_root_slash():
    assert urls.normalize_url("https://example.com/") == "https://example.com/"


def test_url_key_normalizes_host_and_path():
    k = urls.url_key("https://www.Example.com/Path/")
    assert k == ("example.com", "/path", "")


def test_extract_url_full_match():
    assert urls.extract_url("https://example.com/x") == "https://example.com/x"


def test_extract_url_search():
    assert urls.extract_url("see https://example.com/x now") == "https://example.com/x"


def test_extract_url_none():
    assert urls.extract_url("no url here") is None


def test_md_escape_title():
    assert urls.md_escape_title("a [b]") == "a (b)"


def test_skip_url():
    assert urls.skip_url("about:blank")
    assert urls.skip_url("chrome://extensions")
    assert not urls.skip_url("https://example.com")


def test_clean_title_fallback_to_host():
    assert urls.clean_title("", "https://www.example.com/x") == "example.com"


def test_decode_park_url():
    wrapped = "https://www.example.com/park.html?url=https%3A%2F%2Ftarget.com%2Fpage"
    assert urls.decode_park_url(wrapped) == "https://target.com/page"


def test_fetch_title_host_fallback_when_unreachable():
    title = urls.fetch_title("https://invalid.example.test/nope")
    assert title in ("invalid.example.test", "Untitled")