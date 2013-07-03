(function(global) {
  var LOCKED = false;
  var currentWhalesongWriter;
  var globalWhalesongWriter = function(str) {
    currentWhalesongWriter(str);
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
  global.setWhalesongWriteLock = setWhalesongWriteLock;
  global.releaseWhalesongWriteLock = releaseWhalesongWriteLock;
  global.globalWhalesongWriter = globalWhalesongWriter;
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
        write(jQuery("<span>").append(result._fields[3]).append("<br/>"))
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

  var onReady = function () {
    prompt.val('');
    prompt.removeAttr('disabled');
    prompt.css('background-color', 'white');
  };

  
  prompt.attr('disabled', 'true');
  prompt.val('Please wait, initializing...');
  
  var evaluator = makeEvaluator(container, prettyPrint, onError, onReady);

  var runCode = function (src, options) {
    breakButton.show();
    output.empty();
    promptContainer.hide();
    promptContainer.fadeIn(100);
    evaluator.run("run",src,clear,write,options);
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
  plt.runtime.makeRepl({
    prettyPrint: handleReturnValue,
    write: globalWhalesongWriter,
    // TODO(joe): It's unfortunate that naming is by path here
    language: "root/lang/pyret-lang-whalesong.rkt",
    compilerUrl: "http://localhost:8080/rpc.html"
  }, function (theRepl) {
    repl = theRepl;
    onReady();
  });

  var runCode = function(name, src, afterRun, writer, options) {
    setWhalesongWriteLock(writer, function() {
      repl.compileAndExecuteProgram(name, src, options, afterRun, onError);
      releaseWhalesongWriteLock();
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

