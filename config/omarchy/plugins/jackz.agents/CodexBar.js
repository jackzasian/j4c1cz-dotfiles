// Codex collector labels are derived from windowDurationMins, never slot order.
function weeklyLimit(providers) {
  for (var i = 0; i < providers.length; i++) {
    if (providers[i].providerId !== "codex") continue
    if (providers[i].usageStatusText) return null
    var limits = providers[i].limits || []
    for (var j = 0; j < limits.length; j++) {
      var limit = limits[j]
      if (/week|7-day|seven/i.test(String(limit.label || ""))
          && typeof limit.percent === "number" && isFinite(limit.percent) && limit.percent >= 0)
        return limit
    }
  }
  return null
}

function label(limit, nowMs) {
  if (!limit) return "—"
  var left = Math.round(Math.max(0, Math.min(1, 1 - limit.percent)) * 100)
  var resetMs = Date.parse(limit.resetsAt || "")
  var reset = "reset unknown"
  if (isFinite(resetMs)) {
    var minutes = Math.max(1, Math.ceil((resetMs - nowMs) / 60000))
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    reset = resetMs <= nowMs ? "refreshing" : days > 0 ? days + "d " + hours % 24 + "h"
      : hours > 0 ? hours + "h " + minutes % 60 + "m" : minutes + "m"
  }
  return left + "% · " + reset
}
