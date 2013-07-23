function drawNoVersions() {
  return $("<span>No versions</span>");
}

function drawVersionButton(time) {
  var b = $("<button>").addClass("versionButton").text(time);
  return b;
}

function drawVersionsButton(click) {
  return $("<button>+</button>").addClass("versionsButton").click(click);
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

