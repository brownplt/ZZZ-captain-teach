mockReviewTable = {};
// mapping from resource to json
mockBlobTable = {};
// mapping from resource to list of gitref, json pairs, most recent first
mockPathTable = {};

AUTOSAVE_ENABLED = false;

var GIT_ID = 0;

function resetMockServer(table) {
  mockBlobTable = {};
  mockPathTable = {};
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
        return {time: "Unknown Time", resource: gitRefPair[0]};
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
    mockPathTable[functionPathRef] = [["g:r:1:1", {body: 'my new program', userChecks: ''}],["g:r:0:1", {body: 'my cool program', userChecks: ''}]];
    
    var container = $("<div>");
    container.hide();
    $("body").append(container);
    functionData = builders["function"](container, {path: functionPathRef, blob: functionBlobRef}, functionArgs);

    functionData.container.find("button.switch-version")[1].click();
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
      expect(reviewContainer.css("display")).toEqual("none");

      var reviewText = c.find(".reviewText");
      expect(reviewText.text()).toEqual("");

      var reviewButton = c.find("button:contains(Review)");
      reviewButton.click();

      expect(reviewContainer.css("display")).not.toEqual("none");
    });

    it("should save a review", function() {
      var reviewText = c.find(".reviewText");
      var comments = "My review body"
      reviewText.text(comments);

      var reviewButton = c.find("button:contains(Review)");
      reviewButton.click();

      var dScore = '5';
      var cScore = '7';
      var revD = c.find(".reviewDesignScore");
      var revC = c.find(".reviewCorrectScore");
      console.log("Input for revD: ", revD.find("input[value=" + dScore + "]"));
      revD.find("input[value=" + dScore + "]").click();
      revC.find("input[value=" + cScore + "]").click();

      var submitButton = c.find("button:contains(Save this review)");
      console.log("Submit: ", submitButton);
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
    preDiv.find("button").click();
    expect(mockBlobTable[rcId]).toEqual({selected: id1});
    var correctLabel = $(preDiv.find("label")[0]);
    var otherLabel = $(preDiv.find("label")[1]);
    expect(correctLabel.css("background-color")).toEqual("green");
    expect(otherLabel.css("background-color")).not.toEqual("red");
    expect(otherLabel.css("background-color")).not.toEqual("green");

    expect(opt1.prop("checked")).toBe(true);

    preDiv.find("input").each(function(_, i) {
      i = $(i);
      expect(i.attr("disabled")).toBe('disabled');
    });
    
  });
});


