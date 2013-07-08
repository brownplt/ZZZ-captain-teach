window.pyretMaps = (function() {
  function toDictionary(pyretValue) {
    return pyretValue._fields[1].dict;
  }

  function get(dict, str) {
    return plt.runtime.jsMap.getElement(dict, str);
  }

  function hasKey(dict, str) {
    return plt.runtime.jsMap.hasKey(dict, str);
  }

  function getKeys(dict, str) {
    return plt.runtime.jsMap.getKeys(dict);
  }

  function map(dict, f) {
    console.log("Mapping over ", dict);
    if(hasKey(dict, "first")) {
      return [f(get(dict, "first"))].concat(map(toDictionary(get(dict, "rest")), f));
    } else {
      return [];
    }
  }

  return {
    toDictionary: toDictionary,
    get: get,
    hasKey: hasKey,
    getKeys: getKeys,
    map: map
  };
}());

