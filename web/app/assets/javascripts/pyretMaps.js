function pyretValueToDictionary(pyretValue) {
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
