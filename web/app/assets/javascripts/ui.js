
/*
options<a>: {
  save: (-> undefined) -> undefined,
  lookupVersions: ([Version<a>] -> undefined) -> undefined,
  onLoadVersion: a -> undefined,
  panel: { addTab: String, DOM, tabOptions -> undefined }
}

where

Version = {time: String, reviews: [Review], lookup: (a -> undefined) -> undefined}
Review = {lookup: ({(design|correct|comments): String} -> undefined) -> undefined}
*/

function versions(container, options) {

  var versionsList = drawVersionsList(false, []);
  var versionsButton = drawVersionsButton().on("click", function () {
      versionsList.toggle();
    });
  var versionsContainer = drawVersionsContainer(versionsButton, versionsList);
  // NOTE(dbp): When we change to an old version, we save the current work as
  // a revision. However, if we are switching between many versions, we don't want
  // to keep creating new ones (only the first one).
  var onChangeVersionsCreateRevision = true;

  function saveVersion() {
    onChangeVersionsCreateRevision = false;
    setVersionsButtonPending(versionsButton);
    options.save(function() {
        setTimeout(function () {
          setVersionsButtonReady(versionsButton);
          loadVersions();
        }, 1000);
      },
      function (xhr, response) {
        console.error("Saving failed.");
      });
  }

  function loadVersions() {
    versionsList.text("");
    options.lookupVersions(function (versions) {
      if (versions.length === 0) {
        versionsList.append(drawNoVersions());
      }
      versions.forEach(function (v) {
        var b = drawVersionButton(v.time);
        b.on("click", function () {
          if (onChangeVersionsCreateRevision) {
            saveVersion();
          }
          v.lookup(function (response) {
            loadVersions();
            // NOTE(dbp): cache onChange... so changes from loading don't overwrite it
            var oc = onChangeVersionsCreateRevision;
            options.onLoadVersion(response);
            onChangeVersionsCreateRevision = oc;
          },
           function () { console.error("Couldn't find resource from version. This is bad!"); });
        });

        var numReviews = v.reviews.length;
        var revsButton = drawReviewsButton(numReviews);
        if (numReviews > 0) {
          revsButton.on("click", function() {
            var reviewsDiv = drawReviewsDiv(options.name, v.time);
            v.reviews.forEach(function(r) {
              var reviewContainer = drawReviewContainer();
              reviewsDiv.append(reviewContainer);
              r.lookup(function(revData) {
                reviewContainer.append(drawReview(revData));
              });
            });
            options.panel.addTab(options.name + "@" + v.time, reviewsDiv);
            versionsList.toggle();
            return false;
          });
        }

        var versionEntry = drawVersionEntry(revsButton, b);

        versionsList.append(versionEntry);

      });
    });
  }

  loadVersions();

  container.append(versionsContainer);

  return {
    onChange: function() { onChangeVersionsCreateRevision = true; },
    onStartSave: function() { setVersionsButtonPending(versionsButton); },
    onFinishSave: function() { setVersionsButtonReady(versionsButton); },
    saveVersion: saveVersion
  }
}

function showCode(container, getCode, options) {
  if (options.run) {
    var run = drawCodeRunButton();
    run.on("click", function() {
      options.run(cm.getValue(), {}, {check: true});
    });
    container.append(run);
  }
  if (!options.run) { options.run = function() { /* intentional no-op */ }; }

  var cm = makeEditor(container, {
    cmOptions: { readOnly: options.readOnly },
    initial: "(Fetching contents...)",
    run: options.run
  });

  getCode(function(code) {
    cm.setValue(code);
  });
}

function studentCodeReview(container, options) {
  var crContainer = drawCodeReviewContainer();
  container.append(crContainer);
  showCode(
    crContainer,
    options.lookupCode,
    {
      readOnly: true,
      run: options.run
    }
  );
  writeReviews(
    crContainer,
    _.merge(options.reviewOptions, { noResubmit: true })
  );
}

function writeReviews(container, options) {

  var showReview = drawShowWriteReview();
  var reviewContainer = drawWriteReviewContainer();

  var designScores = drawReviewScore(
      "Design",
      "design",
      [1, 2, 3, 4, 5, 6, 7, 8, 9, "10 (best)"],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  var correctScores = drawReviewScore(
      "Correctness",
      "correct",
      [1, 2, 3, 4, 5, 6, 7, 8, 9, "10 (best)"],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  var submitReviewButton = drawSubmitReviewButton()
    .on("click", function(e) {
      var currentDesignScore = getScore(designScores);
      var currentCorrectScore = getScore(correctScores);
      if (currentDesignScore === undefined) {
        markInvalidReviewScore(designScores);
      }
      if (currentCorrectScore === undefined) {
        markInvalidReviewScore(correctScores);
      }
      if (currentDesignScore && currentCorrectScore) {
        markOkReviewScore(designScores);
        markOkReviewScore(correctScores);
        options.reviews.save({
            review: {
              done: true, // NOTE(joe, 25 Jul 2013): This is a client UI hint, not binding
              comments: getReviewText(reviewText),
              design: currentDesignScore,
              correct: currentCorrectScore
            }
          },
          function() {
            if(options.noResubmit) { disableSubmissionUI(); }
            drawSavedNotification(container);
          });
      } else {
        ct_log("Invalid review");
      }
    });

  var reviewText = drawReviewText(false);

  function disableSubmissionUI() {
    submitReviewButton.hide();
    disableReviewText(reviewText);
    disableReviewScore(designScores);
    disableReviewScore(correctScores);
  }

  if (!options.hasReviews) {
    designScores.hide();
    correctScores.hide();
    setReviewText(reviewText, "No versions to review");
  } else {
    options.reviews.lookup(function(rev) {
        enableReviewText(reviewText);
        if (rev !== null) {
          setReviewText(reviewText, rev.review.comments);
          selectReviewScore(designScores, rev.review.design);
          selectReviewScore(correctScores, rev.review.correct);
          if (options.noResubmit && rev.review.done) { disableSubmissionUI(); }
        }
      },
      function(e) {
        console.error(e);
      });
  }

  var textSubmitContainer = drawReviewTextSubmitContainer();
  textSubmitContainer.append(reviewText).append(submitReviewButton);

  reviewContainer.append(designScores)
    .append(correctScores)
    .append(textSubmitContainer);

  container.append(reviewContainer);
}

function repeat(n, s) {
  var str = "";
  for(var i = 0; i < n; i++) {
    str += s;
  }
  return str;
}

function createEditor(cm, uneditables, options) {
  var doc = cm.getDoc();
  var end = doc.setBookmark({line: 0, ch: 0}, {insertLeft: true});
  var i = 0;
  var marks = [];
  var disabled_regions = {};
  function forLines(start, end, f) {
    for (var lineNumber = start; lineNumber < end + 1; lineNumber++) {
      f(lineNumber);
    }
  }
  function disableLines(start, end) {
    forLines(start, end, function(lineNumber) {
      cm.addLineClass(lineNumber, 'background', 'cptteach-fixed');
    });
  }
  function enableLines(start, end) {
    forLines(start, end, function(lineNumber) {
      cm.removeLineClass(lineNumber, 'background', 'cptteach-fixed');
    });
  }
  uneditables.forEach(function(u) {
    var oldEnd = end.find();
    var isFirst = (i === 0);
    var isLast = (i === uneditables.length - 1);
    doc.replaceRange(uneditables[i], end.find());
    var newEnd = end.find();
    var markEnd = { line: newEnd.line, ch: newEnd.ch };
    disableLines(oldEnd.line, markEnd.line);
    marks.push(doc.markText(
      oldEnd,
      markEnd, {
        atomic: true,
        readOnly: true,
        inclusiveLeft: isFirst,
        inclusiveRight: isLast,
        className: 'cptteach-fixed'
      }));
    i += 1;
  });

  function getIndex(indexOrName) {
    var result = useNames ? indexDict[indexOrName] : indexOrName;
    if (result === undefined) { throw "No such index: " + indexOrName; }
    return Number(result);
  }

  function setAt(indexOrName, text) {
    var i = getIndex(indexOrName);
    doc.replaceRange(text, marks[i].find().to, marks[i + 1].find().from);
  }

  function getAt(indexOrName) {
    var i = getIndex(indexOrName);
    var start = marks[i].find().to;
    var end = marks[i + 1].find().from;
    return doc.getRange(start, end);
  }

  function cm_advance_char(doc, pos) {
    var is_eol = (doc.getRange(pos, {line: pos.line}) == "");
    if (is_eol) {
      return {line: pos.line + 1, ch: 0};
    } else {
      return {line: pos.line, ch: pos.ch + 1};
    }
  }

  function cm_retreat_char(doc, pos) {
    if (pos.ch == 0 && pos.line == 0) {
      return pos;
    }
    else if (pos.ch == 0) {
      return {line: pos.line - 1, ch: 0};
    } else {
      return {line: pos.line, ch: pos.ch - 1};
    }
  }

  function lineOf(indexOrName) {
    var i = getIndex(indexOrName);
    var start = marks[i].find().to;
    return cm_advance_char(doc, start).line;
  }
  function enableAt(indexOrName) {
    if (disabled_regions[indexOrName]) {
      var region = disabled_regions[indexOrName];
      enableLines(region.find().from.line, region.find().to.line);
      region.clear()
      delete disabled_regions[indexOrName];
    }
  }

  var readOnlyOptions = {
      readOnly: true,
      inclusiveLeft: true,
      inclusiveRight: true,
      className: 'cptteach-fixed'
    };

  function disableAt(indexOrName) {
    if (disabled_regions[indexOrName] === undefined) {
      var i = getIndex(indexOrName);
      var start = marks[i].find().to;
      var end =  marks[i + 1].find().from;
      var region = doc.markText(start, end, readOnlyOptions);
      disableLines(start.line, end.line);
      disabled_regions[indexOrName] = region;
    }
  }

  var indexDict = {};
  var useNames = options.hasOwnProperty("names");
  if (useNames) {
    if (options.names.length !== marks.length - 1) {
      throw "Wrong number of names for regions: " +
            options.names +
            ", " +
            uneditables;
    }
    var i = 0;
    options.names.forEach(function(n) {
      indexDict[n] = i;
      i += 1;
    });
  }

  var hasInitial = options.hasOwnProperty("initial");
  if (hasInitial) {
    Object.keys(options.initial).forEach(function(k) {
      setAt(k, options.initial[k]);
    });
  }

  var allRegion = false;
  function disableAll() {
    if (!allRegion) {
      var start = marks[0].find().from;
      var end = marks[marks.length - 1].find().to;
      allRegion = doc.markText(start, end, readOnlyOptions);
    }
  }
  function enableAll() {
    if (!allRegion) { return; }
    allRegion.clear();
    allRegion = false;
  }

  var lineWidgets = {};
  function addWidgetAt(indexOrName, dom, options) {
    var i = getIndex(indexOrName);
    var atTop = false;
    if (options && options.atTop) {
      atTop = options.atTop;
    }

    // NOTE(dbp 2013-08-06): `above` changes not only the immediate
    // position, but also the line where the widget is attached.
    var target;
    if (atTop) {
      target = marks[i].find().to.line;
    } else {
      target = marks[i + 1].find().from.line;
    }

    var lw = cm.addLineWidget(target, dom, {above: !atTop});
    if (!lineWidgets[indexOrName]) {
      lineWidgets[indexOrName] = [lw];
    } else {
      lineWidgets[indexOrName].push(lw);
    }
  }

  function clearWidgetAt(indexOrName, widget) {
    if (lineWidgets[indexOrName]) {
      var na = [];
      lineWidgets[indexOrName].forEach(function (lw) {
        if (lw === widget) {
          widget.clear();
        } else {
          na.push(lw);
        }
      });
      lineWidgets[indexOrName] = na;
    }
  }

  function clearAllWidgetsAt(indexOrName) {
    if (lineWidgets[indexOrName]) {
      lineWidgets[indexOrName].forEach(function (lw) {
        lw.clear();
      });
      delete lineWidgets[indexOrName];
    }
  }

  return {
    setAt: setAt,
    getAt: getAt,
    addWidgetAt: addWidgetAt,
    clearWidgetAt: clearWidgetAt,
    clearAllWidgetsAt: clearAllWidgetsAt,
    lineOf: lineOf,
    enableAt: enableAt,
    disableAt: disableAt,
    disableAll: disableAll,
    enableAll: enableAll
  };
}

// push_set wraps up the pattern of appending to an array inside an
// object when the array may not exist yet
function push_set(obj, key, value) {
  if (obj[key]) {
    obj[key].push(value);
  } else {
    obj[key] = [value];
  }
}

function steppedEditor(container, uneditables, options) {

  var currentSectionTitle = drawCurrentStepTitle();
  container.append(currentSectionTitle);

  options.partGutterCallbacks = options.partGutterCallbacks || {};

  var gutterId = "steppedGutter";
  var partGutter = "steppedGutterPart";
  var steps = options.steps || [];
  var pos = 0;
  var cur = 0;
  var done = false;

  var progress = progressBar(container, steps.length);

  var cm = makeEditor(
    $(container),
    {
      initial: "",
      run: options.run,
      cmOptions:  { gutters: [partGutter, gutterId]}
    }
  );

  // NOTE(dbp 2013-08-05): we extract the unedible 'dom' elements, and
  // place them carefully.
  var codeUneditables = [];
  var domUneditables = {};
  var domOffset = 0;
  uneditables.forEach(function (ue, index) {
    if (ue.type === "code") {
      codeUneditables.push(ue.value);
    } else if (ue.type === "dom") {
      // NOTE(dbp 2013-08-05): We get more out of sync with
      // options.names with each dom uneditable.
      domOffset += 1;
      var i;
      if (index === 0) {
        i = 0;
      } else {
        i = index - domOffset;
      }
      push_set(domUneditables, options.names[i], ue.value);
    } else {
      ct_error("steppedEditor: got an uneditable I can't understand: ", ue);
    }
  });

  var editor = createEditor(cm, codeUneditables, {
      names: options.names,
      initial: options.initial
  });

  // NOTE(dbp 2013-7-29): hiding the buttons, for now.

  function switchTo(i) {
    if (i > pos) { pos = i; }
    cur = i;
    if (i === pos) {
      doneButton.show();
    } else {
      doneButton.hide();
    }
    draw();
  }

  var instructionWidgets = [];
  var domUneditableWidgets = [];

  function draw() {
    setCurrentStepTitle(currentSectionTitle, steps[cur]);
    cm.clearGutter(gutterId);
    cm.clearGutter(partGutter);
    progress.set(pos);

    instructionWidgets.forEach(function (iw) {
      editor.clearWidget(iw[0], iw[1]);
    });
    instructionWidgets = [];

    domUneditableWidgets.forEach(function (iw) {
      editor.clearWidgetAt(iw[0], iw[1]);
    });
    domUneditableWidgets = [];

    options.names.forEach(function (e) {
      if (domUneditables[e]) {
        var doms = domUneditables[e];
        doms.forEach(function (dom) {
          var widget = editor.addWidgetAt(e, dom, {above: true});
          domUneditableWidgets.push([e, widget]);
        });
      }
    });

    steps.forEach(function(e, i) {
      if (options.drawPartGutter) {
        options.drawPartGutter(e, function(gutterElement) {
          cm.setGutterMarker(
              editor.lineOf(e),
              partGutter,
              gutterElement
          );
        });
      }
      if (i === cur) {
        var marker = drawCurrentStepGutterMarker();
        cm.setGutterMarker(editor.lineOf(e),
                           gutterId,
                           marker);
        editor.enableAt(e);

        if (options.instructions && options.instructions[e]) {
          var dom = drawInstructionsWidget(options.instructions[e])[0];
          var widget = editor.addWidgetAt(e, dom, {above: true});
          instructionWidgets.push([e, widget]);
        }
      } else {
        if (i <= pos) {
          var marker = drawSwitchToStepGutterMarker(i+1);
          $(marker).on("click", function () {
            switchTo(i);
            return false;
          });
        } else {
          var marker = drawInactiveStepGutterMarker(i+1);
        }
        cm.setGutterMarker(editor.lineOf(e),
                           gutterId,
                           marker);
        editor.disableAt(e);
      }
    });
  };
  draw();

  function resume() {
    if (pos < steps.length - 1) {
      if (cur === pos) {
        cur++;
      }
      pos++;
      draw();
    }
  }
  var doneButton = drawNextStepButton();
  doneButton.on("click", function () {
    if (options.afterHandlers && options.afterHandlers[steps[pos]]) {
      options.afterHandlers[steps[pos]](editor, resume);
    } else {
      resume()
    }
  });

  $(container).append(doneButton);

  return _.merge(editor, {
    resumeAt: function(step) {
      switchTo(_.indexOf(steps, step));
    },
    advanceFrom: function(step) {
      var nextStep = _.indexOf(steps, step) + 1;
      if (nextStep >= steps.length) {
        switchTo(steps.length - 1);
      } else {
        switchTo(nextStep);
      }
    }
  });
}


function progressBar(container, numberSteps) {
  var progressContainer = drawProgressContainer();

  var percentPerStep = 80 / (numberSteps - 1);
  var steps = [];
  _.times(numberSteps, function () {
    var step = drawProgressStep(percentPerStep);
    steps.push(step);
    progressContainer.append(step);
  });

  function setCurrentStep(n) {
    for (var i = 0; i < steps.length; i++) {
      if (i <= n) {
        steps[i].addClass("done");
      } else {
        steps[i].removeClass("done");
      }
    }
  }

  container.append(progressContainer);

  return {
    set: setCurrentStep
  };
}

function reviewTabs(tabPanel, step, resume) {
  function setupReviews(reviewData) {
    var doneCount = 0;
    function incrementDone() {
      doneCount += 1;
      tryFinishReview();
    }
    function tryFinishReview() {
      if(doneCount === reviewData.length) {
        resume();
      }
    }
    tryFinishReview(); // If reviewData is empty, just be done

    reviewData.forEach(function(reviewDatum) {
      reviewDatum.getReview(incrementDone, function(/* notFound */) {
          var reviewsTab = drawReviewsTab();
          var reviewTabHandle =
            tabPanel.addTab("Reviews", reviewsTab, { cannotClose: true });

          var editorContainer = drawReviewEditorContainer();
          reviewsTab.append(editorContainer);
          reviewDatum.attachWorkToReview(editorContainer, function(reviewsInline) {
            writeReviews(reviewsInline, {
                hasReviews: true,
                noResubmit: true,
                reviews: {
                    save: function(val, f) {
                      reviewDatum.saveReview(val, function() {
                          reviewTabHandle.close();
                          incrementDone();
                        },
                        function(e) {
                          // TODO(joe 31 July 2013): Just let them move on if
                          // this fails?
                          ct_error("Saving review failed:", e);
                        });
                    },
                    lookup: function(f) { f(null); }
                  }
              });
          });
        });
    });
  }
  // TODO(joe Aug 1 2013): To consider: is empty reviews the right "not found" behavior?
  step.getReviewData(setupReviews, function() { setupReviews([]); });

}

function makeHighlightingRunCode(codeRunner) {
  var markedLines = [];
  return function(src, uiOptions, options) {
    function highlightingCheckReturn(output) { return function(obj) {
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

      var blockResultsJSON = pyretMaps.pyretToJSON(obj);

      function locToStr(loc) {
        return "Line " + loc.line + ", Column " + loc.column;
      }

      blockResultsJSON.results.map(function(result) {
        result.map(function(checkBlockResult) {
          var container = $("<div>");
          var message = $("<p>");
          var errorLink = $("<a>");
          var name = checkBlockResult.name;
          container.append($("<p>").text(name));
          container.append(message).append(errorLink);
          container.addClass("check-block");
          var messageText = "";
          if (checkBlockResult.err) {
            if (checkBlockResult.err.message) {
              messageText = checkBlockResult.err.message;
            }
            else {
              messageText = checkBlockResult.err;
            }
            var loc = checkBlockResult.err.location;
            errorLink.text(locToStr(loc) + ": " + messageText);
            errorLink.attr("href", "#");
            errorLink.on("click", function(e) {
              clear();
              markedLines.push(loc.line - 1);
              uiOptions.cm.addLineClass(
                  loc.line - 1,
                  'background',
                  'lineError'
              );
              var coords = uiOptions.cm.charCoords({ line: loc.line - 1, ch: loc.column - 1 });
              $("body").animate({
                scrollTop: coords.top - 10
              });
              e.preventDefault();
              return false;
            });
            container.css({
              "background-color": "red"
            });
          }
          checkBlockResult.results.forEach(function(individualResult) {
            if (individualResult.reason) {
              container.append(
                drawFailure(individualResult.name, individualResult.reason));
            } else {
              container.append(drawSuccess(individualResult.name, "Success!"));
            }
          });
          output.append(container);
        });
      });
      return true;
    };}

    function clear() {
      markedLines.forEach(function(l) {
        uiOptions.cm.removeLineClass(l, 'background', 'lineError')
      });
      markedLines = [];
    };
    var theseUIOptions = merge(uiOptions, {
        error: false // highlightingOnError
    });
    if (options.check) {
      theseUIOptions.wrappingReturnHandler = highlightingCheckReturn;
    }
    clear();
    codeRunner(src, theseUIOptions, options);
  }
}
