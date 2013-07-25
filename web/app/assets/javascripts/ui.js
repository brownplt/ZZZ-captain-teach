
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

function teacherReviews(container, options) {

  var showReview = drawShowTeacherReview();
  var reviewContainer = drawTeacherReviewContainer();

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
              comments: reviewText.val(),
              design: currentDesignScore,
              correct: currentCorrectScore
            }
          },
          function() {
            // TODO(joe 22 July 2013): Give some feedback
          });
      } else {
        console.log("Invalid review");
      }
    });

  var reviewText = drawReviewText(false);

  if (!options.hasReviews) {
    designScores.hide();
    correctScores.hide();
    setReviewText(reviewText, "No versions to review");
  } else {
    options.reviews.lookup(function(rev) {
        enableReviewText(reviewText);
        if (rev !== null) {
          setReviewText(rev.review.comments);
          selectReviewScore(designScores, rev.review.design);
          selectReviewScore(correctScores, rev.review.correct);
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
    getAt: getAt
  };
}
