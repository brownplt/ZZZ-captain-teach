function makeEditor(container, options) {
    initial = "";
    if (options.hasOwnProperty("initial")) {
        initial = options.initial;
    }

    var textarea = jQuery("<textarea>");
    textarea.val(initial);
    container.append(textarea);

    runFun = function (cm) {};
    if (options.hasOwnProperty("run")) {
        runFun = function (cm) {
            options.run(cm.getValue());
        }
    }
    
    var CM = CodeMirror.fromTextArea(textarea[0], {
        extraKeys: {
            "Shift-Enter": runFun
        }
    });

    return CM;
}

function formatCode(container, src) {
    CodeMirror.runMode(src, "pyret", container);
}

