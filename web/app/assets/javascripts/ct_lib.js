"use strict";
var LOG = true;
function merge(obj, extension) {
  return _.merge(_.clone(obj), extension);
}

var TUndefined = "undefined";
var TString = "string";
var TNumber = "number";
var TBoolean = "boolean";
var TFunction = "function";
var TObject = "object";

function ctC(name, types, fun) {
  return function(/* varargs */) {
    var al = arguments.length;
    var tl = types.length;
    if (al !== tl) {
      ct_exn(
          name + ": Arity mismatch, expected " + tl + ", got " + al,
          name,
          types,
          arguments
        );
    }
    var mismatches = [];
    var theArgs = arguments;
    types.forEach(function(thisType, ix) {
      var arg = theArgs[ix];
      if(typeof thisType === "string") {
        if(typeof arg !== thisType) {
          mismatches.push({
              expected: thisType,
              actual: arg
            });
        }
      }
      else if(typeof thisType === "object") {
        if(thisType.hasField) {
          if(!arg[thisType.hasField]) {
            mismatches.push({
                expected: thisType,
                actual: arg
              });
          }
        }
      }
      else {
        ct_exn(name + ": Unknown annotation: " + types[ix], types[ix]);
      }
    });
    if(mismatches.length !== 0) {
      var mismatchStrs = mismatches.map(function(m) {
        return "Expected " + m.expected + ", got " + m.actual;
      });
      ct_exn(name + ": Contracts failed " + mismatchStrs.join("\n"), mismatches);
    }

    return fun.apply(this, arguments);
  };
}

function ct_log(/* varargs */) {
  if (window.console && LOG) {
    console.log.apply(console, arguments);
  }
}
function ct_error(/* varargs */) {
  if (window.console && LOG) {
    console.error.apply(console, arguments);
  }
}
function CTException(message) {
  return {
    message: message,
    info: [].slice.call(arguments, 1)
  };
}
function ct_exn(/* varargs */) {
  ct_error(arguments);
  throw CTException.apply(arguments);
}

function ct_confirm(message) {
  return window.confirm(message);
}
