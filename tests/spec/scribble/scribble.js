describe("Scribble documents", function() {
  function testFrame(message, id, test) {
    console.log("#" + id);
    var elt = $("#" + id);
    function runTest() {
      it(message, function() {
        var body = $(elt[0].contentDocument.body);
        test(body);
      });
    }
    if(elt.length === 0) { 
      elt.on('load', runTest);
    }
    else {
      runTest();
    }
  }

  describe("Multiple-choice", function() {
    testFrame("should have a div called 'multiple-choice'",
              "multiple-choice", function(body) {
      var thediv = body.find("[data-type='multiple-choice']");
      expect(thediv.length).toEqual(1)
    });
    testFrame("multiple-choice div should have valid JSON for args",
              "multiple-choice", function(body) {
      var thediv = body.find("[data-type='multiple-choice']");
      console.log(expect(5));
      expect(JSON.parse(thediv.attr('data-args'))[0]).toEqual(
        {content: 'YES!', type: 'choice-correct', name: 'yes-answer'}
      );
    });
  });
});
