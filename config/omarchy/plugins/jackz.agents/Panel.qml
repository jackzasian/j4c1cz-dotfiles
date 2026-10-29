import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "CodexBar.js" as CodexBar

// Forked from omarchy.agents 2026-09-05 to stop paging between subscriptions:
// every enabled agent with data renders on one scrollable page instead of
// one provider at a time behind a tab switcher. Reworked later the same day
// into an at-a-glance summary (name, plan, 5h + weekly %) over each
// provider's full detail, collapsed by default -- the first stacked layout
// put every provider's full hero/status/balance/limits/tokens-by-day/
// tokens-by-model on screen at once, which buried the two numbers that
// actually matter under a wall of history. See README.md for the story (and
// the Codex rate-limit fix this shipped alongside).
Panel {
  id: root
  readonly property bool menuOnly: setting("menuOnly", false) === true
  readonly property real openPanelIndicatorWidth: root.menuOnly ? 0.4 : 0
  readonly property real openPanelIndicatorHeight: root.menuOnly ? 0.4 : 0
  ipcTarget: "omarchy.agents"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color surface: Color.popups.background
  readonly property color track: Style.selectedFillFor(foreground, Color.accent)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var providers: usage.enabledProviders
  readonly property var codexWeekly: CodexBar.weeklyLimit(providers)

  // Countdowns and "updated" read this instead of Date.now() so the
  // panel keeps telling the truth while it sits open.
  property double nowMs: Date.now()

  // The bar icon lights up if ANY enabled subscription is running low, not
  // just whichever one happened to be open last -- there is no longer a
  // "last selected" provider to special-case.
  readonly property bool alarming: {
    for (var i = 0; i < providers.length; i++) {
      var p = providers[i]
      var headline = bindingWindow(p)
      if (headline && headline.percent >= 0.9) return true
      var bal = p.balance || null
      if (bal && bal.funded > 0 && bal.remaining / bal.funded <= 0.1) return true
    }
    return false
  }

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  // Which providers' full detail (hero/status/balance/limits/tokens) is
  // expanded below the at-a-glance summary. Everything starts collapsed --
  // the whole point of the glance row is that you shouldn't have to open
  // anything to read the two numbers that matter.
  property var expandedProviders: ({})

  function providerKey(p) {
    return p ? String(p.providerId || p.providerName || "") : ""
  }

  function isProviderExpanded(p) {
    return expandedProviders[providerKey(p)] === true
  }

  function toggleProviderExpanded(p) {
    var key = providerKey(p)
    if (key === "") return
    var next = {}
    for (var k in expandedProviders) next[k] = expandedProviders[k]
    next[key] = !next[key]
    expandedProviders = next
  }

  function refreshNow() {
    usage.refreshAll(true)
  }

  function launchAgent() {
    if (root.bar) root.bar.run("omarchy-agent --pick")
    root.close()
  }

  // ---------------------------------------------------------------- limits
  //
  // Both providers report the same two shapes: a short rolling session window
  // and a long weekly one. Everything below normalizes them into one record so
  // the meters and the hero speak a single language.

  // Claude spells its windows out ("Session (5-hour)"), Codex abbreviates
  // them ("5h window", "30m window"). Both have to land on the same record.
  function windowIsLong(text) {
    return text.indexOf("week") >= 0 || text.indexOf("7-day") >= 0 || text.indexOf("seven") >= 0
      || text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0
  }

  function windowSpanMs(label) {
    var text = String(label || "").toLowerCase()
    if (text.indexOf("month") >= 0 || text.indexOf("30-day") >= 0) return 30 * 24 * 3600 * 1000
    if (windowIsLong(text)) return 7 * 24 * 3600 * 1000
    var hours = text.match(/(\d+)\s*-?\s*h(?:our)?\b/)
    if (hours) return Number(hours[1]) * 3600 * 1000
    var minutes = text.match(/(\d+)\s*-?\s*m(?:in(?:ute)?s?)?\b/)
    if (minutes) return Number(minutes[1]) * 60 * 1000
    return 0
  }

  function windowTitle(label) {
    var text = String(label || "").toLowerCase()
    if (text.indexOf("month") >= 0) return "Monthly"
    if (windowIsLong(text)) return "Weekly"
    if (text.indexOf("session") >= 0 || windowSpanMs(label) > 0) return "Session"
    var plain = String(label || "").replace(/\s*\(.*\)\s*/, "").trim()
    return plain === "" ? "Limit" : plain
  }

  // A collector that already knows which window a limit belongs to says so,
  // and that beats reading it back out of the label: a model-scoped limit is
  // titled after its model, and a name like "Opus 5 (1M context)" would parse
  // as a one-minute window.
  function limitWindow(label, percent, resetAt, title) {
    return {
      title: String(title || "") !== "" ? String(title) : windowTitle(label),
      percent: Number(percent),
      resetAt: String(resetAt || "")
    }
  }

  // Every window a collector reports rides straight through: Claude and Codex
  // each hand back a short session/5h window and a weekly one (see their
  // collectors' limits arrays), and this keeps every entry rather than
  // picking a "primary" one -- the panel below renders the whole list.
  function limitWindows(p) {
    if (!p) return []
    var out = []
    var list = p.limits || []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i] || {}
      var percent = Number(entry.percent)
      if (percent >= 0) out.push(limitWindow(entry.label, percent, entry.resetsAt, entry.title))
    }
    return out
  }

  // The window that decides how much room is left — the fullest one, since
  // that is what stops the next prompt. Used only for the bar icon's alarm
  // state, which needs one number per provider, not the full list.
  function bindingWindow(p) {
    var windows = limitWindows(p)
    var best = null
    for (var i = 0; i < windows.length; i++) {
      if (!best || windows[i].percent > best.percent) best = windows[i]
    }
    return best
  }

  // The at-a-glance row's numbers: every limit window this provider
  // reports (5h/session + weekly, generically whatever the collector
  // hands back), or -- for a prepaid agent with no windows at all -- a
  // single balance chip so the summary still shows *something* rather
  // than an empty row. Percent here always means "how full", so a
  // balance's remaining/funded gets inverted to match the limit windows'
  // sense of the number.
  function glanceEntries(p) {
    var windows = limitWindows(p)
    if (windows.length > 0) return windows
    var bal = p ? (p.balance || null) : null
    if (bal && bal.funded > 0)
      return [{ title: "Balance", percent: clamp(1 - (bal.remaining / bal.funded), 0, 1), resetAt: "" }]
    return []
  }

  function resetMsFor(w) {
    if (!w || w.resetAt === "") return -1
    var ms = new Date(w.resetAt).getTime()
    return isFinite(ms) ? ms - root.nowMs : -1
  }

  function formatDuration(ms) {
    if (!(ms > 0)) return "now"
    var minutes = Math.floor(ms / 60000)
    var hours = Math.floor(minutes / 60)
    var days = Math.floor(hours / 24)
    if (days > 0) return days + "d " + (hours % 24) + "h"
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    return Math.max(1, minutes) + "m"
  }

  // ---------------------------------------------------------------- balance
  //
  // Prepaid agents report a credit ledger instead of rate-limit windows: the
  // record's balance object carries remaining, funded, and spent amounts.

  function currencyPrefix(currency) {
    var code = String(currency || "USD").toUpperCase()
    if (code === "USD") return "$"
    if (code === "EUR") return "€"
    if (code === "GBP") return "£"
    return code + " "
  }

  function formatMoney(value, currency) {
    var amount = Number(value)
    if (!isFinite(amount)) amount = 0
    return currencyPrefix(currency) + amount.toFixed(2)
  }

  function balanceDetailText(b) {
    if (!b || !(b.funded > 0)) return ""
    var text = formatMoney(b.spent, b.currency) + " spent of " + formatMoney(b.funded, b.currency) + " funded"
    if (b.estimated) text += " · estimated"
    return text
  }

  // ---------------------------------------------------------------- content

  // The plan you pay for, under the name of the tool it pays for. Limits live
  // in their own section; the hero just says what this is.
  function heroMeta(p) {
    if (!p) return ""
    if (String(p.usageStatusText || "") !== "") return p.usageStatusText
    var tier = String(p.tierLabel || "")
    if (tier === "") return "Subscription"
    return tier.charAt(0).toUpperCase() + tier.slice(1)
  }

  // Local calendar date, recomputed from nowMs so a panel left open across
  // midnight moves the "Today" row with the clock.
  function todayDate() {
    var now = new Date(root.nowMs)
    return now.getFullYear()
      + "-" + String(now.getMonth() + 1).padStart(2, "0")
      + "-" + String(now.getDate()).padStart(2, "0")
  }

  function dayName(date) {
    var parsed = new Date(String(date || "") + "T00:00:00")
    if (isNaN(parsed.getTime())) return String(date || "")
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][parsed.getDay()]
  }

  function dayLabel(date, today) {
    if (today) return "Today"
    return dayName(date)
  }

  // Takes the owning provider explicitly now: with every subscription
  // stacked on the same page there is no single implicit "current" provider
  // left to read prompt/session counts off of.
  function dayTooltip(day, today, p) {
    if (!day) return ""
    var parsed = new Date(String(day.date) + "T00:00:00")
    var label = isNaN(parsed.getTime())
      ? String(day.date)
      : dayName(day.date) + " " + (parsed.getMonth() + 1) + "/" + parsed.getDate()
    var text = label + " · " + usage.formatTokenCount(Number(day.messageCount || 0)) + " tokens"
    // Prompt and session counts only exist for today, so they ride along here
    // instead of taking a section of their own. Billing-API agents never
    // count prompts, and "0 prompts" would read as a quiet day, not a gap.
    if (today && p && p.hasPromptStats !== false)
      text += " · " + Number(p.todayPrompts || 0) + " prompts · "
        + Number(p.todaySessions || 0) + " sessions"
    return text
  }

  function weekPeak(p) {
    var days = p ? (p.recentDays || []) : []
    var peak = 0
    for (var i = 0; i < days.length; i++) peak = Math.max(peak, Number(days[i].messageCount || 0))
    return peak
  }

  function modelRows(p) {
    var usageByModel = p ? (p.modelUsage || {}) : {}
    var rows = []
    for (var id in usageByModel) {
      var bucket = usageByModel[id] || {}
      var input = Number(bucket.inputTokens || 0)
      var output = Number(bucket.outputTokens || 0)
      var cacheRead = Number(bucket.cacheReadInputTokens || 0)
      var cacheWrite = Number(bucket.cacheCreationInputTokens || 0)
      rows.push({
        name: usage.friendlyModelName(id),
        total: input + output + cacheRead + cacheWrite,
        input: input,
        output: output,
        cacheRead: cacheRead,
        cacheWrite: cacheWrite
      })
    }
    rows.sort(function(a, b) { return b.total - a.total })
    return rows.slice(0, 4)
  }

  function modelTooltip(row) {
    if (!row) return ""
    return "In " + usage.formatTokenCount(row.input)
      + " · out " + usage.formatTokenCount(row.output)
      + " · cache read " + usage.formatTokenCount(row.cacheRead)
      + " · cache write " + usage.formatTokenCount(row.cacheWrite)
  }

  // Sync-layer problems (bad folder, write failure) apply to the whole
  // widget, not one provider, so this speaks once for the page rather than
  // once per stacked section.
  function globalFooterText() {
    return usage.syncStatusText !== "" ? usage.syncStatusText : ""
  }

  // Only speaks up when this provider's own numbers cover more than this
  // machine.
  function providerFooterText(p) {
    if (p && p.syncEnabled && p.syncDeviceCount > 0)
      return "Merged from " + p.syncDeviceCount + " device" + (p.syncDeviceCount === 1 ? "" : "s")
    return ""
  }

  // Agents that ship a white mark carry an `assets/<id>-light.svg` twin for
  // light surfaces; marks that work on both (Claude's brand-orange) ship one
  // file. The luminance check decides which candidate to try first.
  function colorChannelLuminance(value) {
    var channel = Number(value)
    if (!isFinite(channel)) return 0
    return channel <= 0.03928 ? channel / 12.92 : Math.pow((channel + 0.055) / 1.055, 2.4)
  }

  function colorLuminance(color) {
    return 0.2126 * colorChannelLuminance(color.r)
      + 0.7152 * colorChannelLuminance(color.g)
      + 0.0722 * colorChannelLuminance(color.b)
  }

  // Marks resolve by convention, so a new agent's data file needs nothing
  // from this panel: assets/<id>.svg if it ships one, the module's bar glyph
  // if it doesn't.
  function iconCandidatesForProvider(p, surfaceColor) {
    if (!p) return []
    var candidates = []
    if (colorLuminance(surfaceColor || Color.background) >= 0.5)
      candidates.push(Qt.resolvedUrl("assets/" + p.providerId + "-light.svg"))
    candidates.push(Qt.resolvedUrl("assets/" + p.providerId + ".svg"))
    return candidates
  }

  // Nothing to report, nothing in the bar: Bar.qml collapses a slot whose
  // item is invisible, so the icon appears the moment the first scan finds
  // usage and stays away entirely on a machine that has never run either CLI.
  visible: providers.length > 0
  implicitWidth: root.menuOnly ? 0 : button.implicitWidth
  implicitHeight: root.menuOnly ? 0 : button.implicitHeight

  onOpenedChanged: if (opened) {
    nowMs = Date.now()
    if (panelFlick) panelFlick.contentY = 0
    usage.refreshLimits()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  Main {
    id: usage
    settings: root.settings
  }

  // Cheap enough to keep running: it only re-evaluates text bindings, and a
  // stale "resets in 2h" on a panel that is open is worse than a timer.
  Timer {
    interval: 30000
    running: root.opened || !root.menuOnly
    repeat: true
    onTriggered: root.nowMs = Date.now()
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { root.refreshNow(); return "ok" }
    // Every subscription now renders on the same page, so there is nothing
    // left to page to -- kept as an alias for "open" so an old binding or
    // script calling this still does something reasonable.
    function next(): string { root.open(); return "ok" }
  }

  WidgetButton {
    id: button
    visible: !root.menuOnly
    anchors.fill: parent
    bar: root.bar
    text: CodexBar.label(root.codexWeekly, root.nowMs)
    tooltipText: root.codexWeekly
      ? "Codex weekly allowance remaining · resets " + root.codexWeekly.resetsAt
      : "Codex weekly limit unavailable · click to inspect usage"
    active: root.codexWeekly !== null && root.codexWeekly.percent >= 0.9
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.launchAgent()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    // Taller than the control panels on purpose: this one is a dashboard.
    // With every provider collapsed to a glance row by default the page
    // itself is short; it only grows past this cap once you expand detail
    // sections, at which point scrolling (j/k, or the wheel) takes over.
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (dy !== 0)
          panelFlick.contentY = root.clamp(panelFlick.contentY + dy * Style.space(56), 0,
                                           Math.max(0, panelFlick.contentHeight - panelFlick.height))
      }
      onActivateRequested: root.refreshNow()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { if (t === "r" || t === "R") root.refreshNow() }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(16)

          Text {
            visible: root.providers.length === 0
            width: parent.width
            topPadding: Style.space(24)
            text: "No AI coding subscriptions found.\nAgents show up here once you've used them."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }

          // ---------- At-a-glance: one compact row per subscription ----------
          //
          // The thing Jack actually opens this panel to read: name, plan,
          // and both rate-limit windows (5h/session + weekly), for every
          // enabled provider, with no scrolling and nothing expanded. Click
          // a row (or its chevron) to open that provider's full detail
          // below -- see ProviderSection.
          Column {
            id: glanceStack
            visible: root.providers.length > 0
            width: parent.width
            spacing: Style.space(14)

            Repeater {
              model: root.providers

              GlanceRow {
                required property var modelData
                width: glanceStack.width
                provider: modelData
              }
            }
          }

          // ---------- Full detail, one section per subscription, collapsed ----------
          //
          // Claude, Codex, and any other enabled agent with data render
          // here, top to bottom -- no tab, no switcher, nothing to page
          // between -- but only the providers expanded from the glance row
          // above actually take up space (Column skips invisible children).
          // Each section is fully self-contained (hero, status, balance,
          // limits, tokens by day, tokens by model) and only ever reads its
          // own provider's record.
          Repeater {
            model: root.providers

            ProviderSection {
              required property var modelData

              width: column.width
              provider: modelData
              visible: root.isProviderExpanded(modelData)
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: text !== ""
            width: parent.width
            topPadding: Style.space(2)
            text: root.globalFooterText()
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  // One compact row per subscription: mark, name, plan, and every limit
  // window's percentage with a thin meter -- the two numbers Jack actually
  // opens the panel for (5h/session + weekly), never buried under a
  // day-by-day chart or model breakdown. The whole row is a disclosure
  // control for the matching ProviderSection below.
  component GlanceRow: Item {
    id: glance
    property var provider: null

    readonly property var entries: root.glanceEntries(provider)
    readonly property bool expanded: root.isProviderExpanded(provider)
    readonly property real chipsGap: Style.space(8)

    implicitHeight: glanceHeader.implicitHeight + (chipsRow.visible ? chipsGap + chipsRow.implicitHeight : 0)

    MouseArea {
      id: glanceMouse
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggleProviderExpanded(glance.provider)

      Item {
        id: glanceHeader
        width: parent.width
        implicitHeight: Math.max(glanceIcon.height, glanceLabels.implicitHeight, chevron.implicitHeight)

        Item {
          id: glanceIcon
          width: Style.font.title
          height: Style.font.title
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter

          property var candidates: root.iconCandidatesForProvider(glance.provider, root.surface)
          // See the identical comment on the hero's icon walker below --
          // restart the fallback only when the candidate URLs actually
          // change, not just because a refresh rebuilt the provider object.
          property string candidatesKey: candidates.join("\n")
          property int candidateIndex: 0
          onCandidatesKeyChanged: candidateIndex = 0

          Image {
            id: glanceIconImage
            anchors.fill: parent
            source: glanceIcon.candidateIndex < glanceIcon.candidates.length ? glanceIcon.candidates[glanceIcon.candidateIndex] : ""
            sourceSize.width: Style.font.title * 2
            sourceSize.height: Style.font.title * 2
            fillMode: Image.PreserveAspectFit
            onStatusChanged: if (status === Image.Error && glanceIcon.candidateIndex < glanceIcon.candidates.length)
              Qt.callLater(function() { glanceIcon.candidateIndex++ })
          }

          Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            visible: glanceIconImage.status !== Image.Ready
            text: "󱚣"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
          }
        }

        Column {
          id: glanceLabels
          anchors.left: glanceIcon.right
          anchors.leftMargin: Style.space(10)
          anchors.right: chevron.left
          anchors.rightMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(1)

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: glance.provider ? glance.provider.providerName : ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: text !== ""
            text: root.heroMeta(glance.provider)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }
        }

        // Disclosure triangle -- same glyph convention as the collapsible
        // Docker group headers (djjeane.docker-monitor's Panel.qml).
        Text {
          id: chevron
          textFormat: Text.PlainText
          text: glance.expanded ? "▾" : "▸"
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }

      Row {
        id: chipsRow
        visible: glance.entries.length > 0
        anchors.top: glanceHeader.bottom
        anchors.topMargin: glance.chipsGap
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Style.space(12)

        Repeater {
          model: glance.entries

          GlanceChip {
            required property var modelData
            width: (chipsRow.width - chipsRow.spacing * (glance.entries.length - 1)) / Math.max(1, glance.entries.length)
            entry: modelData
          }
        }
      }
    }
  }

  // A single window's percentage as a title + value line over a thin
  // meter -- the same shape as LimitRow below, minus the reset countdown,
  // so it reads at a glance instead of asking for a second look.
  component GlanceChip: Column {
    id: chip
    property var entry: null
    readonly property bool alarming: chip.entry && chip.entry.percent >= 0.9

    spacing: Style.space(4)

    Item {
      width: parent.width
      implicitHeight: Math.max(chipTitle.implicitHeight, chipValue.implicitHeight)

      Text {
        id: chipTitle
        textFormat: Text.PlainText
        text: chip.entry ? chip.entry.title : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: chipValue.left
        anchors.rightMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: chipValue
        textFormat: Text.PlainText
        text: chip.entry && chip.entry.percent >= 0 ? Math.round(chip.entry.percent * 100) + "%" : "—"
        color: chip.alarming ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Meter {
      width: parent.width
      value: chip.entry ? chip.entry.percent : -1
      alarming: chip.alarming
    }
  }

  // Everything one subscription needs to show itself: hero, auth/status
  // card, balance or limits, the week of token history, and the model
  // breakdown. One instance per enabled provider, stacked by the Repeater
  // above -- nothing here reaches outside its own `provider`.
  component ProviderSection: Column {
    id: section
    property var provider: null

    readonly property var limits: root.limitWindows(provider)
    readonly property var models: root.modelRows(provider)
    readonly property var balance: provider ? (provider.balance || null) : null
    // A prepaid account runs low the way a subscription window fills up: the
    // last 10% of the funded credits lights the same alarm.
    readonly property bool balanceAlarming: !!balance && balance.funded > 0
      && balance.remaining / balance.funded <= 0.1

    width: parent.width
    spacing: Style.space(12)

    // Always shown when this section is expanded -- there is always
    // something above it now (the glance stack, or another expanded
    // provider's detail), never the bare top of the page.
    PanelSeparator {
      foreground: root.foreground
    }

    // ---------- Hero: provider mark · name · plan ----------
    PanelHero {
      id: hero
      visible: !!section.provider
      width: parent.width
      title: section.provider ? section.provider.providerName : ""
      meta: root.heroMeta(section.provider)
      foreground: root.foreground
      fontFamily: root.fontFamily

      iconComponent: Component {
        Item {
          id: heroMark
          property var candidates: root.iconCandidatesForProvider(section.provider, root.surface)
          // Provider objects are rebuilt on every refresh, which churns the
          // array's identity without changing its content. Restart the fallback
          // walk only when the URLs change: re-pointing source at a URL whose
          // load already failed emits no statusChanged, so an identity-only
          // reset would strand the walker on a missing -light twin.
          property string candidatesKey: candidates.join("\n")
          property int candidateIndex: 0
          onCandidatesKeyChanged: candidateIndex = 0

          width: Style.font.display
          height: Style.font.display

          Image {
            id: heroMarkImage
            anchors.fill: parent
            source: heroMark.candidateIndex < heroMark.candidates.length ? heroMark.candidates[heroMark.candidateIndex] : ""
            sourceSize.width: Style.font.display * 2
            sourceSize.height: Style.font.display * 2
            fillMode: Image.PreserveAspectFit
            // Advancing source from inside its own status change trips the
            // binding-loop detector; defer the step one tick.
            onStatusChanged: if (status === Image.Error && heroMark.candidateIndex < heroMark.candidates.length)
              Qt.callLater(function() { heroMark.candidateIndex++ })
          }

          Text {
            textFormat: Text.PlainText
            anchors.centerIn: parent
            visible: heroMarkImage.status !== Image.Ready
            text: "󱚣"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
          }
        }
      }
    }

    // ---------- Status ----------
    BorderSurface {
      visible: !!section.provider && String(section.provider.usageStatusText || "") !== ""
      width: parent.width
      implicitHeight: statusText.implicitHeight + Style.spacing.xl * 2
      color: root.alpha(root.urgent, 0.10)
      borderSpec: Border.flat(root.alpha(root.urgent, 0.35), 1)
      radius: Style.cornerRadius

      Text {
        id: statusText
        textFormat: Text.PlainText
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Style.space(12)
        anchors.rightMargin: Style.space(12)
        text: section.provider ? String(section.provider.authHelpText || "") : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }

    // ---------- Balance / limits ----------
    PanelSeparator {
      visible: balanceSection.visible || limitsSection.visible
      foreground: root.foreground
    }

    Column {
      id: balanceSection
      visible: !!section.balance
      width: parent.width
      spacing: Style.space(10)

      // The meter shows what is left, not what is used: a prepaid
      // account drains toward empty rather than filling toward a cap.
      readonly property real ratio: section.balance && section.balance.funded > 0
        ? root.clamp(section.balance.remaining / section.balance.funded, 0, 1)
        : -1

      PanelSectionHeader {
        width: parent.width
        text: "BALANCE"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Item {
        width: parent.width
        implicitHeight: Math.max(balanceLabel.implicitHeight, balanceValue.implicitHeight)

        Text {
          id: balanceLabel
          text: "Prepaid credits"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: balanceValue
          textFormat: Text.PlainText
          text: section.balance ? root.formatMoney(section.balance.remaining, section.balance.currency) : ""
          color: section.balanceAlarming ? root.urgent : root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Meter {
        visible: balanceSection.ratio >= 0
        width: parent.width
        value: balanceSection.ratio
        alarming: section.balanceAlarming
      }

      Text {
        textFormat: Text.PlainText
        visible: text !== ""
        width: parent.width
        text: root.balanceDetailText(section.balance)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    // Every window the collector reported for this provider -- a short
    // session/5h window and a weekly one for Claude and Codex alike -- not
    // just the fullest one.
    Column {
      id: limitsSection
      visible: section.limits.length > 0
      width: parent.width
      spacing: Style.space(10)

      PanelSectionHeader {
        text: "LIMITS"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: section.limits

        LimitRow {
          required property var modelData
          width: limitsSection.width
          window: modelData
        }
      }
    }

    // ---------- Usage ----------
    PanelSeparator {
      visible: usageSection.visible
      foreground: root.foreground
    }

    Column {
      id: usageSection
      visible: !!section.provider && section.provider.recentDays && section.provider.recentDays.length > 0
      width: parent.width
      spacing: Style.spacing.md

      readonly property var days: section.provider ? (section.provider.recentDays || []) : []
      readonly property real peak: Math.max(1, root.weekPeak(section.provider))

      PanelSectionHeader {
        width: parent.width
        text: "TOKENS BY DAY"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: usageSection.days

        DayRow {
          required property var modelData
          required property int index

          width: usageSection.width
          day: modelData
          provider: section.provider
          ratio: Number(modelData.messageCount || 0) / usageSection.peak
          // By date, not by position: the Claude stats-cache fallback can
          // hand us a window that stops short of today.
          today: String(modelData.date || "") === root.todayDate()
        }
      }
    }

    // ---------- Models ----------
    PanelSeparator {
      visible: modelSection.visible
      foreground: root.foreground
    }

    Column {
      id: modelSection
      visible: section.models.length > 0
      width: parent.width
      spacing: Style.spacing.md

      PanelSectionHeader {
        width: parent.width
        text: "TOKENS BY MODEL"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Repeater {
        model: section.models

        ModelRow {
          required property var modelData
          width: modelSection.width
          row: modelData
          // Scaled to the heaviest model, so the top row is always full —
          // the same scale-to-peak the weekly chart uses for its busiest day.
          share: modelData.total / Math.max(1, section.models[0].total)
        }
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: text !== ""
      width: parent.width
      topPadding: Style.space(2)
      text: root.providerFooterText(section.provider)
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }

  // A limit window: label and percentage, meter, and reset countdown.
  component LimitRow: Column {
    id: limitRow
    property var window: null

    readonly property bool alarming: window && window.percent >= 0.9

    spacing: Style.space(6)

    Item {
      width: parent.width
      implicitHeight: Math.max(limitLabel.implicitHeight, limitValue.implicitHeight)

      Text {
        id: limitLabel
        textFormat: Text.PlainText
        // A model-scoped window is titled after its model, and those names run
        // long enough to reach the percentage, so the title gives way first.
        text: limitRow.window ? limitRow.window.title : ""
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
        anchors.left: parent.left
        anchors.right: limitValue.left
        anchors.rightMargin: Style.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: limitValue
        textFormat: Text.PlainText
        text: limitRow.window && limitRow.window.percent >= 0
          ? Math.round(limitRow.window.percent * 100) + "%"
          : "—"
        color: limitRow.alarming ? root.urgent : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Meter {
      width: parent.width
      value: limitRow.window ? limitRow.window.percent : -1
      alarming: limitRow.alarming
    }

    Text {
      id: resetText
      textFormat: Text.PlainText
      width: parent.width
      text: {
        var remainingMs = root.resetMsFor(limitRow.window)
        return remainingMs > 0 ? "Resets in " + root.formatDuration(remainingMs) : ""
      }
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // Rounded track showing the percentage of the allowance used.
  component Meter: Item {
    id: meter
    property real value: -1
    property bool alarming: false
    property real thickness: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))

    implicitHeight: thickness

    Rectangle {
      id: meterTrack
      anchors.fill: parent
      radius: height / 2
      color: root.track
    }

    Rectangle {
      anchors.left: meterTrack.left
      anchors.verticalCenter: meterTrack.verticalCenter
      height: meterTrack.height
      radius: meterTrack.radius
      width: meterTrack.width * root.clamp(meter.value, 0, 1)
      color: meter.alarming ? root.urgent : root.foreground

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }

  }

  // One row per day: label, bar, tokens. Today is picked out in full
  // foreground so the week reads as a run-up to right now.
  component DayRow: Item {
    id: dayRow
    property var day: null
    property var provider: null
    property real ratio: 0
    property bool today: false

    implicitHeight: Math.max(dayLabel.implicitHeight, dayValue.implicitHeight) + Style.spacing.sm

    Text {
      id: dayLabel
      textFormat: Text.PlainText
      text: root.dayLabel(dayRow.day ? dayRow.day.date : "", dayRow.today)
      color: dayRow.today ? root.foreground : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: dayRow.today
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
    }

    Rectangle {
      id: dayTrack
      anchors.left: dayLabel.right
      anchors.right: dayValue.left
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      height: Math.max(Style.space(4), Math.round(Style.spacing.controlHeight * 0.14))
      radius: height / 2
      color: root.track

      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        radius: parent.radius
        width: parent.width * root.clamp(dayRow.ratio, 0, 1)
        color: dayRow.today ? root.foreground : root.alpha(root.foreground, 0.55)

        Behavior on width {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
      }
    }

    Text {
      id: dayValue
      textFormat: Text.PlainText
      text: usage.formatTokenCount(dayRow.day ? Number(dayRow.day.messageCount || 0) : 0)
      color: dayRow.today ? root.foreground : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      horizontalAlignment: Text.AlignRight
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(52)
    }

    MouseArea {
      id: dayHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    PanelToolTip {
      visible: dayHover.containsMouse
      text: root.dayTooltip(dayRow.day, dayRow.today, dayRow.provider)
      fontFamily: root.fontFamily
    }
  }

  // Model rows read as a table: the share bar fills the row behind the label
  // instead of stacking under it, which keeps the whole dashboard on one screen.
  component ModelRow: Item {
    id: modelRow
    property var row: null
    property real share: 0

    implicitHeight: modelName.implicitHeight + Style.spacing.lg

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: root.alpha(root.foreground, 0.05)
    }

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: parent.width * root.clamp(modelRow.share, 0, 1)
      radius: Style.cornerRadius
      color: root.alpha(root.foreground, 0.14)

      Behavior on width {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }
    }

    Text {
      id: modelName
      textFormat: Text.PlainText
      text: modelRow.row ? modelRow.row.name : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.right: modelTokens.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: modelTokens
      textFormat: Text.PlainText
      text: modelRow.row ? usage.formatTokenCount(modelRow.row.total) : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
      id: modelHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }

    PanelToolTip {
      visible: modelHover.containsMouse
      text: root.modelTooltip(modelRow.row)
      fontFamily: root.fontFamily
    }
  }
}
