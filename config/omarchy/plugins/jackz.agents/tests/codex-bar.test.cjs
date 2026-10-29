const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const bar = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname, "../CodexBar.js"), "utf8"), bar);
const now = Date.parse("2026-10-30T00:00:00Z");
const weekly = {label: "Weekly (7-day)", percent: .58, resetsAt: "2026-11-02T02:00:00Z"};
for (const limits of [[weekly, {label: "5h window", percent: .9}], [{label: "5h window", percent: .9}, weekly]]) {
  assert.equal(bar.weeklyLimit([{providerId: "codex", limits}]), weekly);
}
assert.equal(bar.weeklyLimit([{providerId: "claude", limits: [weekly]}]), null);
assert.equal(bar.weeklyLimit([{providerId: "codex", limits: [{label: "Weekly (7-day)", percent: NaN}]}]), null);
assert.equal(bar.weeklyLimit([{providerId: "codex", usageStatusText: "Codex limits unavailable", limits: [weekly]}]), null);
assert.equal(bar.label(weekly, now), "42% · 3d 2h");
assert.equal(bar.label(weekly, Date.parse(weekly.resetsAt)), "42% · refreshing");
assert.equal(bar.label({...weekly, resetsAt: "bad"}, now), "42% · reset unknown");
assert.equal(bar.label({...weekly, percent: 1.01}, now), "0% · 3d 2h");
assert.equal(bar.label(null, now), "—");
console.log("Codex bar selection/countdown checks passed");
