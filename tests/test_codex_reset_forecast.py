"""Offline fixtures for public reset parsing and cache behavior."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "home/.local/bin/omarchy-codex-reset-forecast"
loader = importlib.machinery.SourceFileLoader("reset_forecast", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class ForecastTests(unittest.TestCase):
    def setUp(self):
        self.now = 1800000000
        self.forecast = {"updated_at": module.stamp(self.now),
            "probabilities": {"rounded_24h": 46, "rounded_48h": 71}, "confidence": "low"}
        self.feed = {"fetched_at": module.stamp(self.now), "stale": False,
            "signal": {"active": False, "summary": "tomorrow", "url": "https://x.com/thsottiaux/status/123"}}

    def test_inactive_signal_and_estimates_are_not_timers(self):
        result = module.normalize(self.forecast, self.feed, self.now)
        self.assertEqual(result["p24"], 46)
        self.assertIsNone(result["signal"])
        self.feed["signal"]["active"] = True
        result = module.normalize(self.forecast, self.feed, self.now)
        self.assertIsNone(result["signal"]["deadline"])
        self.feed["signal"]["deadline"] = module.stamp(self.now + 3600)
        self.assertEqual(module.normalize(self.forecast, self.feed, self.now)["signal"]["deadline"], module.stamp(self.now + 3600))

    def test_freshness_and_invalid_percentages(self):
        self.assertTrue(module.normalize(self.forecast, self.feed, self.now + 1801)["stale"])
        self.feed["stale"] = True
        self.assertTrue(module.normalize(self.forecast, self.feed, self.now)["stale"])
        self.forecast["probabilities"]["rounded_24h"] = True
        with self.assertRaises(ValueError):
            module.normalize(self.forecast, self.feed, self.now)

    def test_failure_preserves_old_data_and_throttles(self):
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory) / "state.json"
            cache.write_text(json.dumps(module.normalize(self.forecast, self.feed, self.now)))
            with patch.object(module, "fetch", side_effect=OSError("offline")) as fetch:
                result = module.collect(cache, self.now + 301)
                self.assertTrue(result["stale"])
                self.assertEqual(result["p24"], 46)
                self.assertIsNotNone(result["error"])
                module.collect(cache, self.now + 302)
                self.assertEqual(fetch.call_count, 1)


if __name__ == "__main__":
    unittest.main()
