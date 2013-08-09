function makeEditor(container, options) {
  var initial = "";
  if (options.hasOwnProperty("initial")) {
    initial = options.initial;
  }

  var runButton = drawRunButton();
  if (options.run && !options.simpleEditor) {
    container.append(runButton);
    container.append(drawClearFix());
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

  var useLineNumbers = !options.simpleEditor;

  var cmOptions = {
    extraKeys: {
      "Shift-Enter": function(cm) { runFun(cm.getValue(), {check: true, "type-env": !options.simpleEditor }); },
      "Shift-Ctrl-Enter": function(cm) { runFun(cm.getValue(), {check: false, "type-env": !options.simpleEditor}); },
      "Tab": "indentAuto"
    },
    indentUnit: 2,
    viewportMargin: Infinity,
    lineNumbers: useLineNumbers,
    matchBrackets: true
  };

  cmOptions = _.merge(cmOptions, options.cmOptions);

  var CM = CodeMirror.fromTextArea(textarea[0], cmOptions);

  if (options.run) {
    runButton.on("click", function () {
      runFun(CM.getValue(), {check: true});
    });
  }


  return CM;
}

function formatCode(container, src) {
  CodeMirror.runMode(src, "pyret", container);
}
