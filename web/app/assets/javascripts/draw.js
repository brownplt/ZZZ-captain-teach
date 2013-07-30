function drawNoVersions() {
  return $("<span>No versions</span>");
}

function drawVersionButton(time) {
  var b = $("<button>").addClass("versionButton").text(time);
  return b;
}

function drawVersionEntry(reviewsButton, versionButton) {
  return $("<div>").append(reviewsButton).append(versionButton);
}

function drawVersionsButton() {
  return $("<button>+</button>").addClass("versionsButton");
}

function setVersionsButtonPending(b) {
  b.html("<img src='/assets/spinner.gif'/>");
}

function setVersionsButtonReady(b) {
  b.text("+");
}

function drawVersionsContainer(versionsButton, versionsList) {
  return $("<div>")
    .append(versionsButton)
    .append($("<div>").addClass("clearfix"))
    .append(versionsList)
    .addClass("versionsContainer");
}

function drawVersionsList(visible, initialButtons) {
  var versions = $("<div>").css("display", visible ? "block" : "none");
  initialButtons.forEach(function(b) {
    versions.append(b);
  });
  return versions;
}


function drawReviewScore(name, labels, values) {
  var radioContainer = $("<div>");
  var id;
  for(var i = 0; i < labels.length; i++) {
    id = name + i;
    radioContainer.append($("<label for='" + id + "'>")
      .text(labels[i])
      .append($("<input type='radio' id='" + id + "' name='" + name + "'>")
      .attr("value", values[i])));
  }
  return radioContainer.addClass("reviewScore reviewScore-" + name);
}

function getScore(reviewScore) {
  return reviewScore.find("input:checked").val();
}

function markInvalidReviewScore(reviewScore) {
  reviewScore.addClass('invalidScore');
}

function markOkReviewScore(reviewScore) {
  reviewScore.removeClass('invalidScore');
}

function selectReviewScore(reviewScore, value) {
  reviewScore.find("input[value=" + value + "]").click().prop("checked", true);
}

function drawShowWriteReview() {
  return $("<button>").css({float: "right"}).text("Review").addClass("writeReview");
}

function drawCodeRunButton() {
  return $("<button>").css({float: "right"}).text("Run");
}

function drawCodeReviewContainer() {
  return $("<div>").addClass("codeReviewContainer");
}

function drawReviewContainer() {
  return $("<div>").addClass("reviewContainer");
}

function drawWriteReviewContainer() {
  return $("<div>").addClass("reviewContainer");
}

function drawSubmitReviewButton() {
  return $("<button>")
    .text("Save this review")
    .css({float: 'right'})
    .addClass("submitReview");
}

function drawReviewText(enabled) {
  return $("<textarea>")
    .addClass("reviewText")
    .prop("disabled", !enabled);
}

function disableReviewText(rt) {
  rt.prop("disabled", true);
}

function enableReviewText(rt) {
  rt.prop("disabled", false);
}

function disableReviewScore(score) {
  score.find("input").prop("disabled", true);
}

function setReviewText(rt, text) {
  rt.val(text);
}

function drawReviewsButton(count) {
  if (count === 0) {
    return $("<span></span>");
  }
  else {
    return $("<a href='#'>R:" + count + "</a>").addClass("reviewLink");
  }
}

function drawReviewsDiv(name, time) {
  var rd = $("<div>");
  rd.append($("<h3>").text("Review for " + name + " at " + time));
  return rd;
}

function drawReviewContainer() {
  return $("<div>");
}

function drawReview(revData) {
  return $("<div>").addClass("reviewContents")
    .append($("<p>").text("Design score: " + revData.review.design))
    .append($("<p>").text("Correctness score: " + revData.review.correct))
    .append($("<p>").text("Comments: " + revData.review.comments));
}

function drawSavedNotification(container) {
  var saved = $("<span>Saved</span>");
  container.append(saved);
  saved.fadeOut(2000);
}

function drawNextStepButton() {
  return $("<button>").text("Next Step");
}

function drawStepsContainer() {
  return $("<div>").addClass("stepsContainer");
}

function drawStepButton(text) {
  return $("<button>").text(text);
}

function drawCurrentStepGutterMarker() {
  return $("<span>").addClass("gutterButton active").html("&rarr;")[0];
}

function drawSwitchToStepGutterMarker(n) {
  return $("<span>").addClass("gutterButton").text(n)[0];
}

function drawInactiveStepGutterMarker(n) {
  return $("<span>").addClass("gutterButton inactive").text(n)[0];
}

function drawProgressContainer() {
  return $("<div>").addClass("progressContainer");
}

function drawProgressStep(width) {
  return $("<span>").addClass("progressStep").css("width", width + "%");
}

function drawCurrentStepTitle() {
  return $("<h3>");
}

function setCurrentStepTitle(dom, title) {
  dom.text(title);
}

function createTabPanel(container) {
  var tabContainer = $("<div>").addClass("tabPanel");
  var panelRow = $("<div>").addClass("tabPanels");
  var current = false;
  var titleRow = $("<div>").addClass("tabTitles");
  function switchToCurrent() {
    tabContainer.find(".tab").hide();
    tabContainer.find(".tabTitle").removeClass("currentTab");
    current.tab.show();
    current.title.addClass("currentTab");
  }
  tabContainer.append(titleRow).append(panelRow);
  container.append(tabContainer);
  return {
    addTab: function(title, dom, inputOptions) {
      var options = inputOptions ? inputOptions : {};
      function switchHere() {
        current = { tab: tab, title: title };
        switchToCurrent();
      }
      var tab = $("<div>").addClass("tab").append(dom);
      var title = $("<div>")
        .addClass("tabTitle")
        .text(title)
        .on("click", switchHere);
      if(!options.cannotClose) {
        var closeButton = $("<span>×</span>").addClass("closeTab")
          .on("click", function(e) {
            tab.remove();
            title.remove();
            if (current.tab.length > 0 && current.tab[0] === tab[0]) {
              current = {
                tab: $(tabContainer.find(".tab")[0]),
                title: $(tabContainer.find(".tabTitle")[0])
              };
              switchToCurrent();
            }
          });
        title.append(closeButton);
      }

      titleRow.append(title);
      panelRow.append(tab);

      switchHere();
    }
  };
}
