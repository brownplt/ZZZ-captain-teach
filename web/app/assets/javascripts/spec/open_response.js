$(function() {
    var resources = TESTDATA.user1.resources;
    var args = TESTDATA.user1.args;
    ct_log(args);
    ct_log(resources);
    openResponse(
        $("#review-editor1"),
        TESTDATA.user1.resources,
        TESTDATA.user1.args
    );
    openResponse(
        $("#review-editor2"),
        TESTDATA.user2.resources,
        TESTDATA.user2.args
    );
});
