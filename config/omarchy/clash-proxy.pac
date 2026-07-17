// Omarchy PAC — Strava and related hosts bypass Clash (real CN IP for location checks).
// Other traffic uses Clash mixed port. Updated by proxyfix.
function hostMatchesStrava(host) {
  host = host.toLowerCase();
  if (host === "localhost" || host === "127.0.0.1" || host === "::1")
    return true;
  if (dnsDomainIs(host, ".strava.com") || host === "strava.com")
    return true;
  if (host.indexOf("strava") !== -1)
    return true;
  var cdn = [
    "d3nn82uaxijpm6.cloudfront.net",
    "dgtzuqphqg23d.cloudfront.net",
    "dgalywyr863hv.cloudfront.net",
    "d3o5xota0a1fcr.cloudfront.net",
    "d21y75miwcfqoq.cloudfront.net",
    "d3u3hkafyj3iak.cloudfront.net"
  ];
  for (var i = 0; i < cdn.length; i++)
    if (host === cdn[i])
      return true;
  return false;
}

function FindProxyForURL(url, host) {
  if (hostMatchesStrava(host))
    return "DIRECT";
  return "PROXY 127.0.0.1:7897; SOCKS5 127.0.0.1:7897; DIRECT;";
}
