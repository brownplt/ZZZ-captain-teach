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


function drawReviewScore(title, name, labels, values) {
  var radioContainer = $("<div>");
  radioContainer.append($("<div>").text(title + ":").addClass("reviewScoreTitle"));
  var id;
  _.times(labels.length, function (i) {
    id = name + i;
    radioContainer.append(
      $("<div>")
        .addClass("reviewButton")
        .append($("<label for='" + id + "'>").text(labels[i]))
        .append("<br>")
        .append($("<input type='radio' id='" + id + "' name='" + name + "'>")
                .attr("value", values[i])));
  });
  return radioContainer.addClass("reviewScore reviewScore-" + name);
}

function drawReviewTextSubmitContainer() {
  return $("<div>").addClass("reviewTextSubmit");
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
    .text("Submit review")
    .css({float: 'right'})
    .addClass("submitReview");
}

function drawReviewText(enabled) {
  return $("<div>")
    .append($("<h4>").text("Comments:"))
    .append($("<textarea>")
            .addClass("reviewText")
            .prop("disabled", !enabled));
}

function disableReviewText(rt) {
  rt.find("textarea").prop("disabled", true);
}

function enableReviewText(rt) {
  rt.find("textarea").prop("disabled", false);
}

function disableReviewScore(score) {
  score.find("input").prop("disabled", true);
}

function setReviewText(rt, text) {
  rt.find("textarea").val(text);
}

function getReviewText(rt) {
  return rt.find("textarea").val();
}


function drawReviewsButton(count) {
  if (count === 0) {
    return $("<div></div>");
  }
  else {
    return $("<div>" + count + "*</div>")
      .attr("title", count + " reviews")
      .addClass("reviewLink");
  }
}

function drawReviewsDiv(name, time) {
  var rd = $("<div>");
  rd.append($("<h3>").text("Review for " + name + " at " + time));
  return rd;
}

function drawReviewsDivName(name, part) {
  var rd = $("<div>");
  rd.append($("<h3>").text("Review for " + part + " of " + name));
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

function drawCurrentStepGutterMarker(isSubmittable) {
  var b = $("<span>").addClass("gutterButton active");
  if (isSubmittable) {
      b.addClass("submittable").html("submit");
  } else {
    b.html("&rarr;");
  }
  return b;
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
  var tabs = [];
  var titleRow = $("<div>").addClass("tabTitles");
  function switchToCurrent() {
    tabContainer.find(".tab").hide();
    tabContainer.find(".tabTitle").removeClass("currentTab");
    if (current.tab && current.title) {
      current.tab.show();
      current.title.addClass("currentTab");
    }
  }
  tabContainer.append(titleRow).append(panelRow);
  container.append(tabContainer);
  return {
    addTab: function(title, dom, inputOptions)
    /*: String, Dom, { cannotClose: Bool, prioritize: Bool } -> Undef */
    {
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
      var tabData = {title: title, tab: tab, index: tabs.length};
      if (options.prioritize) {
        tabData.prioritize = true;
      } else {
        tabData.prioritize = false;
      }
      tabs.push(tabData);
      function close() {
        tab.remove();
        title.remove();
        ct_log("tabs: ", tabs);
        tabs = tabs.filter(function (tabStructure) {
          return tabStructure.tab !== tab;
        });

        if (current.tab.length > 0 && current.tab[0] === tab[0]) {
          var newTab = _.find(tabs,
                              function (t) { return t.prioritize });
          ct_log("tab: ", newTab);
          if (!newTab) {
            newTab = tabs[0];
          }
          newTab = newTab || {};
          current = {
            tab: newTab.tab,
            title: newTab.title
          };
          switchToCurrent();
        }
      }
      if(!options.cannotClose) {
        var closeButton = $("<span>×</span>").addClass("closeTab").on("click", close);
        title.append(closeButton);
      }

      titleRow.append(title);
      panelRow.append(tab);

      switchHere();

      return { close: close };
    }
  };
}

function drawEditorContainer() {
  return $("<div>").addClass("editorContainer");
}

function drawReviewsTab() {
  return $("<div>").addClass("reviewsTab");
}

function drawReviewEditorContainer() {
  return $("<div>").addClass("reviewEditorContainer");
}

function drawInstructionsWidget(html) {
  var visible = true;
  var instr = $("<div>")
    .addClass("toggleInstructions");
  function setInstrMessage() {
    if (visible) {
      instr.text("click to hide");
    } else {
      instr.text("click to show");
    }
  }
  setInstrMessage();

  var content = $("<div>")
    .addClass("instructionsContent")
    .html(html);

  var container = $("<div>")
    .addClass("instructionsWidget");

  var dom = container
    .append(instr)
    .append(content)
    .append($("<div>").addClass("clearfix"));

  dom.on("click", function () {
    if (visible) {
      visible = false;
      content.hide();
      setInstrMessage();
      container.addClass("hidden");
    } else {
      visible = true;
      content.show();
      setInstrMessage();
      container.removeClass("hidden");
    }
  });

  return dom;
}

function drawSaveContainer() {
  return $("<div>").addClass("saveIndicator");
}
