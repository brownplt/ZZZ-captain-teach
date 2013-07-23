function drawNoVersions() {
  return $("<span>No versions</span>");
}

function drawVersionButton(time) {
  var b = $("<button>").addClass("versionButton").text(time);
  return b;
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
    .append("<div>").addClass("clearfix")
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
  reviewScore.find("input[value=" + value + "]").click();
}

function drawShowReview() {
  return $("<button>").css({float: "right"}).text("Review");
}

function drawReviewContainer() {
  return $("<div>").addClass("reviewContainer");
}

function drawSubmitReviewButton() {
  return $("<button>")
    .text("Save this review")
    .css({float: 'right'})
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

function setReviewText(rt, text) {
  rt.val(text);
}
