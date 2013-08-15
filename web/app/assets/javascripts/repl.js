// NOTE(dbp): There can only be one instance of whalesong,
// and the place that whalesong uses for stdout is set at
// the machine level, so if we want the appearance of having
// many instances on a single page, we need a mechanism of
// switching what the whalesong writer is pointing to. Hence,
// our simple mutex.

(function(global) {
  var LOCKED = false;
  var currentWhalesongWriter;
  var globalWhalesongWriter = function(str) {
    return currentWhalesongWriter(str);
  }
  function setWhalesongWriteLock(f, k) {
    if(!LOCKED) {
      LOCKED = true;
      currentWhalesongWriter = f;
      k();
    } else {
      setTimeout(function() {
        setWhalesongWriteLock(f, k);
      }, 0);
    }
  }
  function releaseWhalesongWriteLock() {
    LOCKED = false;
  }
  var currentWhalesongReturnHandler;
  var globalWhalesongReturnHandler = function(str) {
    return currentWhalesongReturnHandler(str);
  }
  function setWhalesongReturnHandlerLock(f, k) {
    if(!LOCKED) {
      LOCKED = true;
      currentWhalesongReturnHandler = f;
      k();
    } else {
      setTimeout(function() {
        setWhalesongReturnHandlerLock(f, k);
      }, 0);
    }
  }
  function releaseWhalesongReturnHandlerLock() {
    LOCKED = false;
  }
  global.setWhalesongWriteLock = setWhalesongWriteLock;
  global.releaseWhalesongWriteLock = releaseWhalesongWriteLock;
  global.globalWhalesongWriter = globalWhalesongWriter;
  global.setWhalesongReturnHandlerLock = setWhalesongReturnHandlerLock;
  global.releaseWhalesongReturnHandlerLock = releaseWhalesongReturnHandlerLock;
  global.globalWhalesongReturnHandler = globalWhalesongReturnHandler;
}(window));

//: -> (code -> printing it on the repl)
function makeRepl(container) {
  var items = [];
  var pointer = -1;
  var current = "";
  function loadItem() {
    CM.setValue(items[pointer]);
  }
  function saveItem() {
    items.unshift(CM.getValue());
  }
  function prevItem() {
    if (pointer === -1) {
      current = CM.getValue();
    }
    if (pointer < items.length - 1) {
      pointer++;
      loadItem();
    }
  }
  function nextItem() {
    if (pointer >= 1) {
      pointer--;
      loadItem();
    } else if (pointer === 0) {
      CM.setValue(current);
      pointer--;
    }
  }



  var promptContainer = jQuery("<div id='prompt-container'>");
  var prompt = jQuery("<div>").addClass("repl-prompt");
  promptContainer.append($("<span>&gt;&nbsp;</span>")).append(prompt);



  var output = jQuery("<div id='output' class='cm-s-default'>");
  var breakButton = jQuery("<img id='break' src='" + WHALESONG_URL + "/break.png'>");

  var clearDiv = jQuery("<div class='clear'>");

  var clearRepl = function() {
    output.empty();
    promptContainer.hide();
    promptContainer.fadeIn(100);
    lastNameRun = 'interactions';
    lastEditorRun = null;
  };

  var clearButton = $("<button>").addClass("blueButton").text("Clear")
    .click(clearRepl);

  container.append(clearButton).append(output).append(promptContainer).
    append(breakButton).append(clearDiv);


  var runCode = function (src, uiOptions, options) {
    breakButton.show();
    CM.setOption("readOnly", "nocursor");
    CM.getDoc().eachLine(function (line) {
      CM.addLineClass(line, 'background', 'cptteach-fixed');
    });
    output.empty();
    promptContainer.hide();
    promptContainer.fadeIn(100);
    var defaultReturnHandler = options.check ? checkModePrettyPrint : prettyPrint;
    var thisReturnHandler;
    if (uiOptions.wrappingReturnHandler) {
      thisReturnHandler = uiOptions.wrappingReturnHandler(output);
    } else {
      thisReturnHandler = uiOptions.handleReturn || defaultReturnHandler;
    }
    var thisError;
    if (uiOptions.wrappingOnError) {
      thisError = uiOptions.wrappingOnError(output);
    } else {
      thisError = uiOptions.error || onError;
    }
    var thisWrite = uiOptions.write || write;
    lastNameRun = uiOptions.name || "interactions";
    lastEditorRun = uiOptions.cm || null;
    evaluator.run(uiOptions.name || "run", src, clear, enablePrompt(thisReturnHandler), thisWrite, enablePrompt(thisError), options);
  };

  var enablePrompt = function (handler) { return function (result) {
      breakButton.hide();
      CM.setValue("");
      CM.setOption("readOnly", false);
      CM.getDoc().eachLine(function (line) {
        CM.removeLineClass(line, 'background', 'cptteach-fixed');
      });
      return handler(result);
    };
  }

  var CM = makeEditor(prompt, {
    simpleEditor: true,
    run: function(code, opts, replOpts){
      items.unshift(code);
      pointer = -1;
      write(jQuery('<span>&gt;&nbsp;</span>'));
      var echoContainer = $("<div>");
      var echo = $("<textarea class='repl-echo CodeMirror'>");
      echoContainer.append(echo);
      write(echoContainer);
      var echoCM = CodeMirror.fromTextArea(echo[0], { readOnly: 'nocursor' });
      echoCM.setValue(code);
      write(jQuery('<br/>'));
      breakButton.show();
      CM.setOption("readOnly", "nocursor");
      CM.getDoc().eachLine(function (line) {
        CM.addLineClass(line, 'background', 'cptteach-fixed');
      });
      makeHighlightingRunCode(function(src, uiOptions, options) {
        evaluator.run('interactions',
                    src,
                    clear,
                    prettyPrint,
                    write,
                    enablePrompt(uiOptions.wrappingOnError(output)),
                    merge(options, _.merge(replOpts, {check: false})));
      })(code, merge(opts, {name: lastNameRun, cm: lastEditorRun || echoCM}), replOpts);
    },
    initial: "",
    cmOptions: {
      extraKeys: {
        'Ctrl-Up': function(cm) {
          prevItem();
        },
        'Ctrl-Down': function(cm) {
          nextItem();
        }
      }
    }
  });

  var lastNameRun = 'interactions';
  var lastEditorRun = null;

  var write = function(dom) {
    output.append(dom);
    output.get(0).scrollTop = output.get(0).scrollHeight;
  };

  var clear = function() {
    allowInput(CM, true)();
  };

  var onError = function(err, editor) {
    ct_log("onError: ", err);
    if (err.message) {
      write(jQuery('<span/>').css('color', 'red').append(err.message));
      write(jQuery('<br/>'));
    }
    clear();
  };

  var prettyPrint = function(result) {
    if (result.hasOwnProperty('_constructorName')) {
      switch(result._constructorName.val) {
      case 'p-num':
      case 'p-bool':
      case 'p-str':
      case 'p-object':
      case 'p-fun':
      case 'p-method':
        whalesongFFI.callPyretFun(
            whalesongFFI.getPyretLib("torepr"),
            [result],
            function(s) {
              var str = pyretMaps.getPrim(s);
              write(jQuery("<span class='repl-output'>").text(str));
              write(jQuery('<br/>'));
            }, function(e) {
              ct_err("Failed to tostring: ", result);
            });
        return true;
      case 'p-nothing':
        return true;
      default:
        return false;
      }
    } else {
      console.log(result);
      return false;
    }
  };

  var checkModePrettyPrint = function(obj) {
    function drawSuccess(name, message) {
      return $("<div>").text(name +  ": " + message)
        .addClass("check check-success")
        .append("<br/>");
    }
    function drawFailure(name, message) {
      return $('<div>').text(name + ": " + message)
        .addClass("check check-failure")
        .append("<br/>");
    }
    var dict = pyretMaps.toDictionary(obj);
    var blockResults = pyretMaps.toDictionary(pyretMaps.get(dict, "results"));
    function getPrimField(v, field) {
      return pyretMaps.getPrim(pyretMaps.get(pyretMaps.toDictionary(v), field));
    }

    pyretMaps.map(blockResults, function(result) {
      pyretMaps.map(pyretMaps.toDictionary(result), function(checkBlockResult) {
        var cbDict = pyretMaps.toDictionary(checkBlockResult);
        var container = $("<div>");
        var message = $("<p>");
        var name = getPrimField(checkBlockResult, "name");
        container.append("<p>").text(name);
        container.append(message);
        container.addClass("check-block");
        if (pyretMaps.hasKey(cbDict, "err")) {
          var messageText = pyretMaps.get(cbDict, "err");
          if (pyretMaps.hasKey(pyretMaps.toDictionary(messageText), "message")) {
            messageText = getPrimField(pyretMaps.get(cbDict, "err"), "message");
          } else {
            messageText = pyretMaps.getPrim(pyretMaps.get(cbDict, "err"));
          }
          message.text("Check block ended in error: " + messageText);
          container.css({
            "background-color": "red"
          });
        }


        pyretMaps.map(pyretMaps.toDictionary(pyretMaps.get(pyretMaps.toDictionary(checkBlockResult), "results")), function(individualResult) {
          if (pyretMaps.hasKey(pyretMaps.toDictionary(individualResult), "reason")) {
            container.append(drawFailure(
                getPrimField(individualResult, "name"),
                getPrimField(individualResult, "reason")));
          } else {
            container.append(drawSuccess(
                getPrimField(individualResult, "name"),
                "Success!"));
          }
        });
        output.append(container);
      });
    });
    return true;
  }

  var onReady = function () {
  /*  prompt.val('');
    prompt.removeAttr('disabled');
    prompt.css('background-color', 'white');*/
  };

  var evaluator = makeEvaluator(container, prettyPrint, onReady);


  var onBreak = function() {
    evaluator.requestBreak(clear);
  };


  var allowInput = function(CM, clear) { return function() {
    if (clear) {
      CM.setValue("");
    }

    CM.setOption("readOnly", false);;
    CM.getDoc().eachLine(function (line) {
      CM.removeLineClass(line, 'background', 'cptteach-fixed');
    });
    breakButton.hide();

    CM.focus();
  } };

  var onReset = function() {
    evaluator.requestReset(function() {
      output.empty();
      clear();
    });
  };


  var onExpressionEntered = function(srcElt) {
    var src = CM.getDoc().getValue();
    write(jQuery('<span>&gt;&nbsp;</span>'));
    write(jQuery('<span>').append(src));
    write(jQuery('<br/>'));
    breakButton.show();
    evaluator.run('interactions',
                  src,
                  clear,
                  prettyPrint,
                  write,
                  onError,
                  {});
  };


  breakButton.hide();
  breakButton.click(onBreak);

  return runCode;
}

function makeEvaluator(container, handleReturnValue, onReady) {
  var repl;
  setWhalesongReturnHandlerLock(handleReturnValue, function() {
    plt.runtime.makeRepl({
      prettyPrint: globalWhalesongReturnHandler,
      write: globalWhalesongWriter,
      // TODO(joe): It's unfortunate that naming is by path here
      language: "root/lang/pyret-lang-whalesong.rkt",
      compilerUrl: WHALESONG_URL + "/rpc.html"
    }, function (theRepl) {
      repl = theRepl;
      onReady();
    });
    releaseWhalesongReturnHandlerLock();
  })

  var runCode = function(name, src, afterRun, returnHandler, writer, onError, options) {
    setWhalesongReturnHandlerLock(returnHandler, function() {
      setWhalesongWriteLock(writer, function() {
        repl.compileAndExecuteProgram(name, src, options, afterRun, onError);
        releaseWhalesongWriteLock();
      });
      releaseWhalesongReturnHandlerLock();
    });
  };

  var breakFun = function(afterBreak) {
    repl.requestBreak(afterBreak);
  };

  var resetFun = function(afterReset) {
    repl.reset(afterReset);
  };

  return {run: runCode, requestBreak: breakFun, requestReset: resetFun};
}

function namedRunner(runFun, name) {
  return function(src, uiOptions, langOptions) {
    runFun(src, merge(uiOptions, { name: name }), langOptions);
  };
}
