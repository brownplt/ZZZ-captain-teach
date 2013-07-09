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

  var prompt = jQuery("<input type='text' id='prompt'>");
  var promptContainer = jQuery("<div id='prompt-container'>");
  promptContainer.append("<span>&gt;&nbsp;</span>");
  var output = jQuery("<div id='output'>");
  var breakButton = jQuery("<img id='break' src='http://localhost:8080/break.png'>");
  
  var clearDiv = jQuery("<div class='clear'>");

  prompt.css({
    'width': '95%'
  });

  promptContainer.append(prompt);
  container.append(output).append(promptContainer).
    append(breakButton).append(clearDiv);

  var write = function(dom) {
    output.append(dom);
    output.get(0).scrollTop = output.get(0).scrollHeight;
  };

  var clear = function() {
    allowInput(prompt, true)();
  };

  var onError = function(err) {
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
        write(jQuery("<span class='repl-output'>").append(pyretMaps.getPrim(result)));
        write(jQuery('<br/>'));
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
    var resultCss = {
      "border": "1px solid black",
      "border-radius": "3px",
      "padding": "10px",
      "margin": "10px"
    };
    function drawSuccess(name, message) {
      return $('<div>').text(name +  ": " + message)
        .css(resultCss)
        .css({ "background-color": "green" })
        .append("<br/>");
    }
    function drawFailure(name, message) {
      return $('<div>').text(name + ": " + message)
        .css(resultCss)
        .css({ "background-color": "red" })
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
        container.css({
          "background-color": "gray",
          "border": "1px solid black",
          "border-radius": "3px",
          "margin": "5px",
          "padding": "5px"
        });
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
    prompt.val('');
    prompt.removeAttr('disabled');
    prompt.css('background-color', 'white');
  };

  
  prompt.attr('disabled', 'true');
  prompt.val('Please wait, initializing...');
  
  var evaluator = makeEvaluator(container, prettyPrint, onError, onReady);

  var runCode = function (src, uiOptions, options) {
    breakButton.show();
    output.empty();
    promptContainer.hide();
    promptContainer.fadeIn(100);
    var defaultReturnHandler = options.check ? checkModePrettyPrint : prettyPrint;
    var thisReturnHandler = uiOptions.handleReturn || defaultReturnHandler;
    var thisWrite = uiOptions.write || write;
    evaluator.run("run", src, clear, thisReturnHandler, thisWrite, options);
  };

  var onBreak = function() { 
    evaluator.requestBreak(clear);
  };


  var allowInput = function(elt, clear) { return function() {
    if (clear) {
      elt.val('');
    }
    elt.removeAttr('disabled');
    elt.css('background-color', 'white');
    breakButton.hide();
  } };

  var onReset = function() { 
    evaluator.requestReset(function() {
      output.empty();
      clear();
    });
  };      
  

  var onExpressionEntered = function(srcElt) {
    var src = srcElt.val();
    write(jQuery('<span>&gt;&nbsp;</span>'));
    write(jQuery('<span>').append(src));
    write(jQuery('<br/>'));
    jQuery(srcElt).val("");
    srcElt.attr('disabled', 'true');
    srcElt.css('background-color', '#eee');
    breakButton.show();
    evaluator.run('interactions',
                  src,
                  clear,
                  prettyPrint,
                  write,
                  {});
  };

  
  breakButton.hide();
  breakButton.click(onBreak);

  prompt.keypress(function(e) {
    if (e.which == 13 && !prompt.attr('disabled')) { 
      onExpressionEntered(prompt);
    }});

  return runCode;

}

function makeEvaluator(container, handleReturnValue, onError, onReady) {
  var repl;
  setWhalesongReturnHandlerLock(handleReturnValue, function() {
    plt.runtime.makeRepl({
      prettyPrint: globalWhalesongReturnHandler,
      write: globalWhalesongWriter,
      // TODO(joe): It's unfortunate that naming is by path here
      language: "root/lang/pyret-lang-whalesong.rkt",
      compilerUrl: "http://localhost:8080/rpc.html"
    }, function (theRepl) {
      repl = theRepl;
      onReady();
    });
    releaseWhalesongReturnHandlerLock();
  })

  var runCode = function(name, src, afterRun, returnHandler, writer, options) {
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

