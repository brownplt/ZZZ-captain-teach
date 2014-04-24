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

  function getPrim(pyretValue) {
    return pyretValue._fields[4];
  }

  function isPrim(pyretValue) {
    return pyretValue._fields.hasOwnProperty("4");
  }

  function map(dict, f) {
    if(hasKey(dict, "first")) {
      return [f(get(dict, "first"))].concat(map(toDictionary(get(dict, "rest")), f));
    } else {
      return [];
    }
  }

  function toArray(dict) {
    return map(dict, function(val) { return val; });
  }

  function pyretToJSON(pyretVal) {
    var avoidConstructors = ["p-method", "p-fun", "p-opaque"];
    function avoid(val) {
      return avoidConstructors.indexOf(val._constructorName.val) >= 0;
    }
    // TODO(joe 05 Aug 2013): Better list detection (brands?)
    function isList(dict) {
      return (hasKey(dict, "first") && hasKey(dict, "rest")) ||
              (hasKey(dict, "append") && hasKey(dict, "sort-by"));
    }
    if(isPrim(pyretVal)) {
      return getPrim(pyretVal);
    }
    if (!avoid(pyretVal)) {
      var pvalDict = toDictionary(pyretVal);
      if(isList(pvalDict)) {
        return toArray(pvalDict)
          .map(pyretToJSON)
          .filter(function(v) { return v !== undefined });
      } else {
        var ret = {};
        getKeys(pvalDict).forEach(function(k) {
          var fieldVal = get(pvalDict, k);
          if(!avoid(fieldVal)) {
            ret[k] = pyretToJSON(fieldVal);
          }
        });
        return ret;
      }
    }
    else if (isOpaque(pyretVal)) {
      return pyretVal;
    }
  }


  return {
    toDictionary: toDictionary,
    get: get,
    getPrim: getPrim,
    isPrim: isPrim,
    hasKey: hasKey,
    getKeys: getKeys,
    map: map,
    pyretToJSON: pyretToJSON
  };
}());

