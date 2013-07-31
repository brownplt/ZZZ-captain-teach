describe("reviews interactions", function () {

  it("should work", function () {
    var resources = TESTDATA.user1.resources;
    var args = TESTDATA.user1.args;
    codeAssignment(
        $("#review-editor1"),
        TESTDATA.user1.resources,
        TESTDATA.user1.args
    );
    codeAssignment(
        $("#review-editor2"),
        TESTDATA.user2.resources,
        TESTDATA.user2.args
    );
  });
});
