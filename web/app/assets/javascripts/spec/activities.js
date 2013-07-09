mockServerTable = {};

AUTOSAVE_ENABLED = false;

function setMockServerTable(table) {
  mockServerTable = table || {};
}

window.lookupResource = function(resource, present, absent, error) {
  if (mockServerTable.hasOwnProperty(resource)) {
    console.log("Mock server fetching, ", resource, mockServerTable);
    present(mockServerTable[resource]);
  } else {
    console.log("Mock server missed, ", resource, mockServerTable);
    absent();
  }
};

window.lookupVersions = function(resource, callback, error) {
  // TODO(dbp): make this actually do something?
  callback([]);
}

window.saveResource = function(resource, data, success, failure) {
  console.log("Mock server saving, ", resource, data, mockServerTable);
  mockServerTable[resource] = data;
  success();
};

describe("function activities", function() {
  var functionData;
  var functionArgs = {includes: [], check: "checkers.check-equals(my_foo(),...)", header: "fun my_foo():"};
  beforeEach(function() {
    functionData = builders["function"]($("<div>"), {path: "p:rw:my-id:1", blob: "b:rw:my-id:1"}, functionArgs);
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
    expect(functionData.container.find("button").length).toBeGreaterThan(0);
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
    mockServerTable = {};
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
    expect(mockServerTable[rcId]).toBeUndefined();
  });

  it("should save and color if something is selected", function() {
    expect(preDiv.find("input[type=radio]").length).toBe(2);
    var opt1 = $(preDiv.find("input[type=radio]")[0]);
    opt1.click();
    preDiv.find("button").click();
    expect(mockServerTable[rcId]).toEqual({selected: id1});
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

