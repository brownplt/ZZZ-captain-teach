mockReviewTable = {};
// mapping from resource to json
mockBlobTable = {};
// mapping from resource to list of gitref, json pairs, most recent first
mockPathTable = {};
// mapping from resource to [activity_id, resource, submission_time, type]
mockSubmittedTable = {};

AUTOSAVE_ENABLED = false;

var GIT_ID = 0;

function resetMockServer() {
  mockBlobTable = {};
  mockPathTable = {};
  mockSubmittedTable = {};
}
function setMockReviewTable(table) {
  mockReviewTable = table || {};
}

function lookupInTable(table, type, resource, present, absent, error, postProcess) {
  if (typeof postProcess === 'undefined') {
    postProcess = function (x) { return x; };
  }

  if (table.hasOwnProperty(resource)) {
    console.log("Mock server fetching ", type, ", ",
                resource, table);
    present(postProcess(table[resource]));
  } else {
    console.log("Mock server missed ", type, ", ",
                resource, table);
    absent();
  }
}

window.lookupResource = function(resource, present, absent, error) {
  var wrapFile = function(file) {
    return {file: JSON.stringify(file)}
  };
  if (resource[0] === 'b') {
    lookupInTable(mockBlobTable, "blob", resource,
                  present, absent, error, function (b) {
                    return JSON.stringify(b);
                  });
  } else if (resource[0] === 'p') {
    var latest = function (gitRefList) {
      return wrapFile(gitRefList[0][1]);
    };
    lookupInTable(mockPathTable, "path",
                  resource, present,
                  absent, error,
                  latest);
  } else if (resource[0] === 'g') {
    var isPresent = false;
    Object.keys(mockPathTable).forEach(function (k) {
      mockPathTable[k].forEach(function (gitRefPair) {
        if (gitRefPair[0] === resource) {
          console.log("Mock server fetching gitref, ",
                      resource);
          present(wrapFile(gitRefPair[1]));
          isPresent = true;
        }
      });
    });
    if (!isPresent) {
      console.log("Mock server missed gitref, ", resource, mockPathTable);
      absent();
    }
  } else {
    console.error("Mock server presented with resource it didn't understand: ", resource);
  }
};

window.lookupVersions = function(resource, callback, error) {
  if (resource[0] !== 'p') {
    callback([{time: "", resource: resource}]);
  } else {
    if (mockPathTable.hasOwnProperty(resource)) {
      callback(mockPathTable[resource].map(function (gitRefPair) {
        return {time: gitRefPair[0], resource: gitRefPair[0], reviews: []};
      }));
    } else {
      console.log("Mock server missed versions on pathref ", resource, mockPathTable);
    }
  }
}

function getReviewId(review) { return review.substr(review.lastIndexOf("/")); }

window.lookupReview = function(review, present, error) {
  var reviewId = getReviewId(review);
  if (mockReviewTable.hasOwnProperty(reviewId)) {
    console.log("Mock server fetching review, ", reviewId, mockReviewTable);
    present(mockReviewTable[reviewId]);
  } else {
    console.log("Mock server missed review, ", reviewId, mockReviewTable);
    present(null);
  }
};

function parseResource(resource) {
  var parseRe = /([gpb]):([crwv]+):([-a-zA-Z0-9\/]+):([0-9]+)/;
  var matches = resource.match(parseRe);
  if (matches) {
    console.log(matches);
    return {
      type: matches[1],
      permissions: matches[2],
      activityId: matches[3],
      userId: matches[4]
    };
  } else {
    throw "Couldn't parse resource: " + resource;
  }
}

function getActivityId(resource) {
  var parsed = parseResource(resource);
  return parsed.activityId;
}

function getUser(resource) {
  var parsed = parseResource(resource);
  return parsed.userId;
}

describe("getActivityId", function() {
  it("should fetch activity ids from reasonable resources", function() {
    expect(getActivityId("g:r:1234:1")).toEqual("1234");
    expect(getActivityId("p:rw:abcd/1234:1")).toEqual("abcd/1234");
  });

  it("should blow up on unreasonable resources", function() {
    expect(function() {
      getActivityId("hello!");
    }).toThrow("Couldn't parse resource: hello!");
  });
});

window.submitResource = function(resource, data, success, failure) {
  console.log("Mock server submitting: ", resource, data);
  var existing = mockSubmittedTable[resource] || [];
  existing.push({
    activityId: getActivityId(resource),
    user: getUser(resource),
    time: Date.now(),
    type: data.type
  });
  mockSubmittedTable[resource] = existing;
  saveResource(resource, data, success, failure);
};

window.getSubmittedForResource = function(resource) {
  return mockSubmittedTable[resource];
}

window.saveResource = function(resource, data, success, failure) {
  console.log("Mock server saving, ", resource, data);

  if (resource[0] === 'g') {
    // can't save a gitref
    failure();
  } else if (resource[0] === 'p') {
    // a pathref
    var uid = resource[resource.length-1];
    var newRef = ["g:r:" + GIT_ID++ + ":" + uid, data];
    if (mockPathTable.hasOwnProperty(resource)) {
      mockPathTable[resource].unshift(newRef);
    } else {
      mockPathTable[resource] = [newRef];
    }
    success();
  } else if (resource[0] === 'b' ){
    mockBlobTable[resource] = data;
    success();
  } else {
    console.error("Mock server presented with resource it didn't understand: ", resource);
    failure();
  }
};

window.saveReview = function(review, data, success, failure) {
  var reviewId = getReviewId(review);
  console.log("Mock server saving review, ", reviewId, data, mockReviewTable);
  mockReviewTable[reviewId] = data;
  success();
};

window.getReviewStatus = function(reviewStatus, success, failure) {

};

window.fail = function() {
  expect(false).toBe(true);
};

describe("mock server", function() {
  it("should submit resources", function() {
    var submitted = false;
    var r = "b:rw:my-id:1";
    submitResource(r, { type: 'done' }, function() {
        submitted = true;
      },
      function() {
        fail();
      });
    expect(submitted).toBe(true);
    var vals = getSubmittedForResource(r)[0];
    expect(vals.activityId).toEqual("my-id");
    expect(vals.user).toEqual("1");
    expect(vals.type).toEqual("done");
    expect(typeof vals.time).toBe("number");
  });

  it("should append to the list when submiting multiple resources", function() {
    var submitted = 0;
    var r = "b:rw:my-id:1";
    submitResource(r, { type: 'round1' }, function() {
        submitted += 1;
      }, fail);
    submitResource(r, { type: 'done' }, function() {
        submitted += 1;
      }, fail);
    expect(submitted).toBe(2);
    var val1 = getSubmittedForResource(r)[1];
    expect(val1.activityId).toEqual("my-id");
    expect(val1.user).toEqual("1");
    expect(val1.type).toEqual("round1");
    expect(typeof val1.time).toBe("number");
    var val2 = getSubmittedForResource(r)[0];
    expect(val2.activityId).toEqual("my-id");
    expect(val2.user).toEqual("1");
    expect(val2.type).toEqual("done");
    expect(typeof val2.time).toBe("number");

    expect(val2.time < val1.time).toBe(true);
  });
});

describe("function activities", function() {
  var functionPathRef = "p:rw:my-id:1";
  var functionBlobRef = "b:rw:my-id:1";
  var functionData;
  var functionArgs = {includes: [], check: "checkers.check-equals(my_foo(),...)", header: "fun my_foo():"};
  beforeEach(function() {
    resetMockServer();
    functionData = builders["function"]($("<div>"), {path: functionPathRef, blob: functionBlobRef}, functionArgs);
  });

  it("should create codemirror", function () {
    expect(functionData.container.find(".CodeMirror").length).not.toEqual(0);
  });
  it("should have header in codemirror, but not check", function () {
    var cm = functionData.activityData.codemirror;
    expect(cm.getValue()).toContainStr(functionArgs.header);
    expect(cm.getValue()).not.toContainStr(functionArgs.check);
  });

  it("should have a submit button", function () {
    console.log("submit button:", functionData.container);
    expect(functionData.container.find("button.submit").length).toBe(1);
  });

  it("when you click submit, should create a new version", function () {
    functionData.container.find("button.submit").click();
    expect(mockPathTable[functionPathRef].length).toBe(1);
  });

  it("when you switch to a version, it should put the contents in the editor", function () {
    resetMockServer();
    mockPathTable[functionPathRef] = [
      ["g:r:1:1", {body: 'my new program', userChecks: ''}]
      ,["g:r:0:1", {body: 'my cool program', userChecks: ''}]
    ];

    var container = $("<div>");
    container.hide();
    $("body").append(container);
    functionData = builders["function"](container, {path: functionPathRef, blob: functionBlobRef}, functionArgs);

    var versionButtons = functionData.container.find("button.versionButton");
    console.log(versionButtons);
    $(versionButtons[1]).click();
    expect(functionData.activityData
           .codemirror.getDoc().getValue())
      .toContainStr("my cool program");
    window.CM = functionData.activityData.codemirror;
  });

  describe("grading activities", function() {
    var functionData, c, reviewContainer;
    beforeEach(function() {
      setMockReviewTable();
      functionData = builders["function"]($("<div>"), {
          path: "p:rw:my-id:1",
          blob: "b:rw:my-id:1",
          reviews: {
            path: {
              versions: [{ save: "save/42", lookup: "lookup/42" }],
              review: { save: "save/47", lookup: "lookup/47" }
            }
          }
        }, functionArgs)
      c = functionData.container;
      reviewContainer = c.find(".reviewContainer");
    });

    it("should add a review div if versions present to review", function () {

      var reviewText = c.find(".reviewText");
      expect(reviewText.text()).toEqual("");

      expect(reviewContainer.css("display")).not.toEqual("none");
    });

    it("should save a review", function() {
      var reviewText = c.find(".reviewText");
      var comments = "My review body"
      reviewText.text(comments);

      var reviewButton = c.find("button.writeReview");
      reviewButton.click();

      var dScore = '5';
      var cScore = '7';
      var revD = c.find(".reviewScore-design");
      var revC = c.find(".reviewScore-correct");

      // NOTE(dbp): on Firefox, for me, the "click()" alone did not
      // result in them being checked.
      revD.find("input[value=" + dScore + "]")
        .prop("checked", true)
        .click();
      revC.find("input[value=" + cScore + "]")
        .prop("checked", true)
        .click();

      var submitButton = c.find("button.submitReview");
      submitButton.click();

      lookupReview("lookup/42", function(r) {
        expect(r.review.comments).toEqual(comments);
        expect(r.review.design).toEqual(dScore);
        expect(r.review.correct).toEqual(cScore);
      });

    });
  });

});

describe("multiple-choice activities", function() {
  var preDiv;
  var option1;
  var option2;
  var mc;
  var rcId = "b:rc:mc-id:user-id";
  var id1;
  var id2;

  var idCounter = 0;
  function mkId(base) {
    return base + idCounter++;
  }

  beforeEach(function() {
    resetMockServer();
    id1 = mkId("option1");
    id2 = mkId("option2");
    preDiv = $("<div>");
    option1 = $("<div>").attr("id", id1);
    option2 = $("<div>").attr("id", id2);
    preDiv.append(option1).append(option2);
    mc = multipleChoice(preDiv, {blob: rcId}, {
        choices: [{type: "choice-correct", name: id1},
                  {type: "choice-incorrect", name: id2}],
        id: "mc-id"
      },
      {});
  });

  it("should create labels and checkboxes", function() {
    expect(preDiv.find("input[type=radio]").length).toBe(2);
    expect(preDiv.find("label").length).toBe(2);
    expect(preDiv.find("button").length).toBe(1);

    function okInit(_, opt) {
      opt = $(opt);
      expect(opt.css("background-color")).not.toEqual("green");
      expect(opt.css("background-color")).not.toEqual("red");
    }
    preDiv.find("label").each(okInit);
  });

  it("should do nothing if nothing selected", function() {
    preDiv.find("button").click();
    expect(mockBlobTable[rcId]).toBeUndefined();
  });

  it("should save and color if something is selected", function() {
    expect(preDiv.find("input[type=radio]").length).toBe(2);
    var opt1 = $(preDiv.find("input[type=radio]")[0]);
    opt1.click();
    // NOTE(dbp): on Firefox, without this, the search for :checked fails, so selected in undefined
    opt1.prop("checked", true);

    preDiv.find("button").click();
    expect(mockBlobTable[rcId]).toEqual({selected: id1});
    var correctLabel = $(preDiv.find("label")[0]);
    var otherLabel = $(preDiv.find("label")[1]);
    // NOTE(dbp): on Firefox, this fails because the color is 'rgb(0,128,0)'
    //expect(correctLabel.css("background-color")).toEqual("green");
    expect(otherLabel.css("background-color")).not.toEqual("red");
    expect(otherLabel.css("background-color")).not.toEqual("green");

    expect(opt1.prop("checked")).toBe(true);

    preDiv.find("input").each(function(_, i) {
      i = $(i);
      expect(i.attr("disabled")).toBe('disabled');
    });

  });
});

describe("reviews and versions", function () {
  var panelContainer;
  var panel;
  var versionsContainer;
  var versionLoadLog;
  var versionsUI;

  beforeEach(function () {
    panelContainer = $("<div>");
    panel = createTabPanel(panelContainer);
    versionsContainer = $("<div>");
    versionLoadLog = [];
    versionsUI = versions(versionsContainer, {
      panel: panel,
      name: "Phooey!",
      onLoadVersion: function(response) {
        versionLoadLog.push(response);
      },
      lookupVersions: function(success) {
        success([
          {
            time: "Jun 6, 2014",
            lookup: function(success2) { success2("Version 3"); },
            reviews: []
          },
          {
            time: "Jun 5, 2014",
            lookup: function(success2) { success2("Version 2"); },
            reviews: [{
              lookup: function(success2) {
                success2({ review: {
                  done: true,
                  correct: "7",
                  design: "8",
                  comments: "Helpers are there, still not passing tests"
                }});
              }
            }, {
              lookup: function(success2) {
                success2({review: {
                  done: true,
                  correct: "8",
                  design: "7",
                  comments: "Avoid parentheses when unnecessary"
                }});
              }
            }
                     ]
          },
          {
            time: "Jun 4, 2014",
            lookup: function(success2) { success2("Version 1"); },
            reviews: [{
              lookup: function(success2) {
                success2({ review: {
                  done: true,
                  correct: "6",
                  design: "7",
                  comments: "Nice try, use more helpers"
                }});
              }
            }]
          }
        ])
      },
      save: function(success) {
        success();
      }
    });
  });

  it("should have rev. links for each version w/ revs", function () {
    expect(versionsContainer.find(".reviewLink").length)
      .toEqual(2);
  });

  it("should put the contents of review in tab when you click",
    function () {
      // the first link is for the Jun 5 one, which has two reviews
      $(versionsContainer.find(".reviewLink")[0]).click();
      var reviews = panelContainer.find(".reviewContents");
      expect(reviews.length).toEqual(2);
      expect($(reviews.find("p")[0]).text()).toEqual("Design score: 8");
      // the panel should now have one tab
      expect(panelContainer.find(".tab").length).toEqual(1);
      // close it, to clean up
      panelContainer.find('.closeTab').click();
      expect(panelContainer.find(".tab").length).toEqual(0);
    });

  it("should create two tabs if you click the review button twice",
    function () {
      $(versionsContainer.find(".reviewLink")[0]).click();
      $(versionsContainer.find(".reviewLink")[0]).click();
      expect(panelContainer.find(".tab").length).toEqual(2);
      $(panelContainer.find('.closeTab')[0]).click();
      expect(panelContainer.find(".tab").length).toEqual(1);
      $(panelContainer.find('.closeTab')[0]).click();
      expect(panelContainer.find(".tab").length).toEqual(0);
    });

  it("should call onload handler when the version button is clicked",
    function () {
      $(versionsContainer.find("button.versionButton")[0]).click();
      expect(versionLoadLog).toContain("Version 3");
      $(versionsContainer.find("button.versionButton")[1]).click();
      $(versionsContainer.find("button.versionButton")[2]).click();
      $(versionsContainer.find("button.versionButton")[0]).click();
      expect(versionLoadLog.length).toEqual(4);
    });

  describe("student reviews", function() {
    var container;
    var theReview;
    var run = function(prog, options1, options2) {
      ct_log("Running: ", prog, options1, options2);
    };

    beforeEach(function() {
      container = $("<div>");
      theReview = null;
    });

    it("should save a review", function() {

      studentCodeReview(
        container,
        {
          run: run,
          lookupCode: function(k) { k("# Proggy"); },
          reviewOptions: {
            reviews: {
              lookup: function(k) { k(theReview); },
              save: function(v, k) { theReview = v; k(); }
            },
            hasReviews: true
          }
        }
      );
      var comments = "Not so fast, bucko.";
      container.find("button.writeReview").click();
      container.find("textarea.reviewText").val(comments);

      var dScore = '5';
      var cScore = '7';
      var revD = container.find(".reviewScore-design");
      var revC = container.find(".reviewScore-correct");
      revD.find("input[value=" + dScore + "]").prop("checked", true).click();
      revC.find("input[value=" + cScore + "]").prop("checked", true).click();

      container.find("button.submitReview").click();

      expect(theReview.review.comments).toEqual(comments);
      expect(theReview.review.design).toEqual(dScore);
      expect(theReview.review.correct).toEqual(cScore);
    });

    it("should not be enabled if the review is done", function() {
      theReview = {
        review: {
          done: true,
          comments: "You are the best coder I have ever seen fail completely",
          design: "10",
          correct: "1"
        }
      };
      studentCodeReview(
        container,
        {
          run: run,
          lookupCode: function(k) { k("# Proggy"); },
          reviewOptions: {
            reviews: {
              lookup: function(k) { k(theReview); },
              save: function(v, k) { theReview = v; k(); }
            },
            hasReviews: true
          }
        }
      );

      container.find("button.writeReview").click();
      var rt = container.find("textarea.reviewText");
      expect(rt.val()).toEqual(theReview.review.comments);
      expect(rt.prop("disabled")).toEqual(true);
      var rsd = container.find(".reviewScore-design input:checked");
      ct_log("rsd; ", rsd);
      expect(rsd.val()).toEqual("10");
      expect(rsd.prop("disabled")).toEqual(true);
      var rsc = container.find(".reviewScore-correct input:checked");
      ct_log("rsc; ", rsc);
      expect(rsc.val()).toEqual("1");
      expect(rsc.prop("disabled")).toEqual(true);

    });
  });
});

describe("Student review interface", function() {

  it("should start with a button that starts the review", function() {

  });

});
