import contextlib
import io
import runpy
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

DAEMON = Path(__file__).resolve().parents[1] / "home/.local/bin/omarchy-auto-brightness"


class BrightnessCooldown(unittest.TestCase):
    def test_new_adjustment_extends_hold_and_steady_value_expires(self):
        main = runpy.run_path(str(DAEMON))["main"]
        clock = Mock()
        clock.sleep.side_effect = [None] * 6 + [StopIteration]
        clock.time.side_effect = clock.monotonic.side_effect = [0, 1, 5, 8, 11, 18]
        cfg = dict(main.__globals__["DEFAULT_CONFIG"], override_cooldown_sec=10, studio_enabled=False)
        set_panel = Mock()
        output = io.StringIO()
        with patch.dict(main.__globals__, {
            "time": clock, "STATE_DIR": Mock(), "PAUSE_FILE": Mock(exists=lambda: False),
            "load_config": lambda: cfg, "read_als_lux": lambda: 500,
            "panel_current_percent": Mock(side_effect=[40, 60, 60, 70, 70, 70]), "set_panel": set_panel,
        }), contextlib.redirect_stdout(output), self.assertRaises(StopIteration):
            main()
        self.assertEqual(output.getvalue().count("manual override detected"), 2)
        self.assertEqual([call.args for call in set_panel.call_args_list], [(40,), (40,)])
        self.assertIn("panel now 70%", output.getvalue())


if __name__ == "__main__":
    unittest.main()
