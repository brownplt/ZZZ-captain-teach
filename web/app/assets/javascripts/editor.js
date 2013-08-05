function makeEditor(container, options) {
  var initial = "";
  if (options.hasOwnProperty("initial")) {
    initial = options.initial;
  }

  var textarea = jQuery("<textarea>");
  textarea.val(initial);
  container.append(textarea);

  var runFun = function (code, options) {};
  if (options.hasOwnProperty("run")) {
    runFun = function (code, replOptions) {
      options.run(code, {cm: CM}, replOptions);
    }
  }

  var cmOptions = {
    extraKeys: {
      "Shift-Enter": function(cm) { runFun(cm.getValue(), {check: true}); },
      "Shift-Ctrl-Enter": function(cm) { runFun(cm.getValue(), {check: false}); },
      "Tab": "indentAuto"
    },
    indentUnit: 2,
    viewportMargin: Infinity,
    lineNumbers: true
  };

  cmOptions = _.merge(cmOptions, options.cmOptions);
  
  var CM = CodeMirror.fromTextArea(textarea[0], cmOptions);

  return CM;
}

function formatCode(container, src) {
  CodeMirror.runMode(src, "pyret", container);
}

