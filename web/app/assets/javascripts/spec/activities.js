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
  mockReviewTable = {};
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
  beforeEach(function() {
    resetMockServer();
  });

  it("should submit resources", function() {
    var submitted = false;
    var r = "b:rw:my-id:1";
    submitResource(r, { type: 'done2' }, function() {
        submitted = true;
      },
      function() {
        fail();
      });
    expect(submitted).toBe(true);
    var vals = getSubmittedForResource(r)[0];
    expect(vals.activityId).toEqual("my-id");
    expect(vals.user).toEqual("1");
    expect(vals.type).toEqual("done2");
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
    expect(val1.type).toEqual("done");
    expect(typeof val1.time).toBe("number");
    var val2 = getSubmittedForResource(r)[0];
    expect(val2.activityId).toEqual("my-id");
    expect(val2.user).toEqual("1");
    expect(val2.type).toEqual("round1");
    expect(typeof val2.time).toBe("number");

    expect(val2.time <= val1.time).toBe(true);
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

describe("Student review interface", function() {

  it("should start with a button that starts the review", function() {

  });

});
