// NOTE(joe): this relies on the presence of window.RUN_CODE, and some global
// ids, like #prompt and #output defined in repl.js.  That code and these
// tests would benefit from refactoring to make that unnecessary

describe("repls", function() {
  var done = true;
  var finish = function() { done = true; };
  var CM;
  beforeEach(function() {
    CM = $(".repl div.CodeMirror")[0].CodeMirror;
    if (done) {
      done = false;
    } else {
      waitsFor(function() { return done; },
               "Waiting to be done", 1000);
    }
  });

  it("should echo numbers as numbers", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    console.log(prompt);
    console.log(output);
    runs(function() {
      CM.setValue("5");
      CM.options.extraKeys['Shift-Enter'](CM);
    });
    waitsFor(function() {
      return output.find(".repl-output").length > 0;
    }, "some output to be seen", 1000);
    runs(function() {
      expect(output.find(".repl-output").text()).toBe("5");
      finish();
    });
  });

  it("should create a check-failure div for a failure with the function name", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    var code = "fun foo(): nothing where:" +
               "  checkers.check-equals('returns 2', foo(), 2) end";
    runs(function() {
      window.RUN_CODE(code, {}, {check:true});
    });
    waitsFor(function() {
      return output.find("div.check-failure").length > 0;
    });
    runs(function() {
      expect(output.find("div.check-block").text().indexOf("foo"))
        .toBeGreaterThan(-1);

      expect(output.find("div.check-failure").text().indexOf("foo"))
        .toBe(-1);

      expect(output.find("div.check-failure").text().indexOf("Values not equal"))
        .toBeGreaterThan(-1);
      finish();
    });
  });

  it("should create a green div for a success", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    var code = "fun bar(): 5 where: " +
               "  checkers.check-equals('returns 5', bar(), 5) end";
    runs(function() {
      window.RUN_CODE(code, {}, {check:true});
    });
    waitsFor(function() {
      return output.find("div.check-success").length > 0;
    });
    runs(function() {
      expect(output.find("div.check-block").text().indexOf("bar"))
        .toBeGreaterThan(-1);

      expect(output.find("div.check-success").text().indexOf("bar"))
        .toBe(-1);

      expect(output.find("div.check-success").text().indexOf("returns 5"))
        .toBeGreaterThan(-1);
      finish();
    });
  });

});

