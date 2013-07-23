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
      console.log("Versions are: ", versions);
      versions.forEach(function (v) {
        console.log("e.g. ", v);
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
        versionsList.append(b);
        versionsList.append(jQuery("<br>"));
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

  var showReview = drawShowReview();
  var reviewContainer = drawReviewContainer();

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
      }
    });

  var reviewText = drawReviewText(false);

  if (!options.hasReviews) {
    designScores.hide();
    correctScores.hide();
    setReviewText(rt, "No versions to review");
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
