describe("function activities", function() {
  var functionData;
  var functionArgs = {check: "checkers.check-equals(my_foo(),...)", header: "fun my_foo():"};
  beforeEach(function() {
    functionData = builders["function"]($("<div>"), "rw:my-id:1", functionArgs);
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
    expect(functionData.container.find("button").length).toEqual(1);
  });
  
});
