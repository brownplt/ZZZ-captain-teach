
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
                ct_log("Revdata: ", revData);
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

  showReview.on("click", function(_) { reviewContainer.toggle(); })

  var designScores = drawReviewScore(
      "design",
      ["(Worst design) 1", 2, 3, 4, 5, 6, 7, 8, 9, "10 (Best design)"],
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  var correctScores = drawReviewScore(
      "correct",
      ["(Completely incorrect) 1", 2, 3, 4, 5, 6, 7, 8, 9, "10 (Completely correct)"],
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
              comments: reviewText.val(),
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

  reviewContainer.append(designScores)
    .append(correctScores)
    .append(reviewText)
    .append(submitReviewButton);

  container.append(showReview).append(reviewContainer);
  reviewContainer.hide();
}

function repeat(n, s) {
  var str = "";
  for(var i = 0; i < n; i++) {
    str += s;
  }
  return str;
}

function createEditor(doc, uneditables, options) {
  var end = doc.setBookmark({line: 0, ch: 0}, {insertLeft: true});
  var i = 0;
  var marks = [];
  var disabled_regions = {};
  uneditables.forEach(function(u) {
    var oldEnd = end.find();
    var isFirst = (i === 0);
    var isLast = (i === uneditables.length - 1);
    doc.replaceRange(uneditables[i], end.find());
    var newEnd = end.find();
    var markEnd = { line: newEnd.line, ch: newEnd.ch };
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

  function enableAt(indexOrName) {
    if (disabled_regions[indexOrName]) {
      disabled_regions[indexOrName].clear()
    }
  }

  function disableAt(indexOrName) {
    var i = getIndex(indexOrName);
    var start = marks[i].find().to;
    var end =  marks[i + 1].find().from;
    var region = doc.markText(start, end, {readOnly: true,
                                          inclusiveLeft: true,
                                          inclusiveRight: true});
    disabled_regions[indexOrName] = region;
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

  return {
    setAt: setAt,
    getAt: getAt,
    enableAt: enableAt,
    disableAt: disableAt
  };
}


function steppedEditor(doc, container, uneditables, options) {
  var cm = makeEditor(
    $(container),
    {
      initial: "",
      run: options.run
    }
  );
  var sequence = options.steps || [];
  var pos = 0;
  var editor = createEditor(cm.getDoc(), uneditables, {
      names: options.names,
      initial: options.initial
  });

  var mark_enabled = function() {
    for(var i = 0; i < sequence.length; i++) {
      if (i <= pos) {
        editor.enableAt(sequence[i]);
      } else {
        editor.disableAt(sequence[i]);
      }
    }
  };
  mark_enabled();
  var doneButton = drawNextStepButton();
  doneButton.on("click", function () {
    if (pos < sequence.length) {
      pos++;
      mark_enabled();
    }
  });

  $(container).append(doneButton);

  return editor;
}
