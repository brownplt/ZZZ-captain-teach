function makeEditor(container, options) {
    initial = "";
    if (options.hasOwnProperty("initial")) {
        initial = options.initial;
    }

    var textarea = jQuery("<textarea>");
    textarea.val(initial);
    container.append(textarea);

    runFun = function (code, options) {};
    if (options.hasOwnProperty("run")) {
        runFun = function (code, replOptions) {
            options.run(code, replOptions);
        }
    }
    
    var CM = CodeMirror.fromTextArea(textarea[0], {
      extraKeys: {
        "Shift-Enter": function(cm) { runFun(cm.getValue(), {check: true}); },
        "Shift-Ctrl-Enter": function(cm) { runFun(cm.getValue(), {check: false}); },
        "Tab": "indentAuto"
      },
      indentUnit: 2
    });

    return CM;
}

function formatCode(container, src) {
    CodeMirror.runMode(src, "pyret", container);
}

