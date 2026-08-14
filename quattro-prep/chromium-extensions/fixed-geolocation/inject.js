(() => {
  const LAT = 39.9075;
  const LNG = 116.3972;
  const ACC = 100;
  const pos = () => ({
    coords: {
      latitude: LAT,
      longitude: LNG,
      accuracy: ACC,
      altitude: null,
      altitudeAccuracy: null,
      heading: null,
      speed: null
    },
    timestamp: Date.now()
  });
  const geo = {
    getCurrentPosition: (ok) => ok(pos()),
    watchPosition: (ok) => { ok(pos()); return 1; },
    clearWatch: () => {}
  };
  try {
    Object.defineProperty(Navigator.prototype, "geolocation", {
      get: () => geo,
      configurable: true
    });
  } catch (_) {}
})();
