function format(deadline, now) {
  if (!isFinite(deadline)) return "";
  var seconds = Math.ceil((deadline - now) / 1000);
  if (seconds <= 0) return "awaiting";
  var minutes = Math.ceil(seconds / 60);
  var hours = Math.floor(minutes / 60);
  if (hours >= 24) return Math.floor(hours / 24) + "d " + hours % 24 + "h";
  return hours ? hours + "h " + minutes % 60 + "m" : minutes + "m";
}
