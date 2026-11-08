pragma Singleton
import QtQml

QtObject {
  property var leases: []
  function add(lease) { leases = leases.concat([lease]) }
  function remove(lease) { leases = leases.filter(function(item) { return item !== lease }) }
  function owner(target) {
    if (!target) return null
    for (var i = 0; i < leases.length; i++) {
      if (leases[i].target === target) return leases[i]
    }
    return null
  }
}
