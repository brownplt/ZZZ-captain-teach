// NOTE(joe): this relies on the presence of window.RUN_CODE, and some global
// ids, like #prompt and #output defined in repl.js.  That code and these
// tests would benefit from refactoring to make that unnecessary

describe("repls", function() {
  var done = true;
  var finish = function() { done = true; };
  beforeEach(function() {
    if (done) {
      done = false;
    } else {
      waitsFor(function() { return done; }, "Waiting to be done", 1000);
    }
  });

  it("should echo numbers as numbers", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    console.log(prompt);
    console.log(output);
    runs(function() {
      prompt.val("5");
      var e = $.Event("keypress");
      e.which = 13;
      prompt.trigger(e);
    });
    waitsFor(function() {
      return output.find(".repl-output").length > 0;
    }, "some output to be seen", 1000);
    runs(function() {
      expect(output.find(".repl-output").text()).toBe("5");
      finish();
    });
  });

  it("should create a red div for an failure with the function name", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    var code = "fun foo(): nothing check:" +
               "  checkers.check-equals('returns 2', foo(), 2) end";
    runs(function() {
      window.RUN_CODE(code, {}, {check:true});
    });
    waitsFor(function() {
      return output.find("div[style*='red']").length > 0;
    });
    runs(function() {
      expect(output.find("div[style*='gray']").text().indexOf("foo"))
        .toBeGreaterThan(-1);

      expect(output.find("div[style*='red']").text().indexOf("foo"))
        .toBe(-1);

      expect(output.find("div[style*='red']").text().indexOf("Values not equal"))
        .toBeGreaterThan(-1);
      finish();
    });
  });

  it("should create a green div for a success", function() {
    var prompt = $("#prompt");
    var output = $("#output");
    var code = "fun bar(): 5 check: " +
               "  checkers.check-equals('returns 5', bar(), 5) end";
    runs(function() {
      window.RUN_CODE(code, {}, {check:true});
    });
    waitsFor(function() {
      return output.find("div[style*='green']").length > 0;
    });
    runs(function() {
      expect(output.find("div[style*='gray']").text().indexOf("bar"))
        .toBeGreaterThan(-1);

      expect(output.find("div[style*='green']").text().indexOf("bar"))
        .toBe(-1);

      expect(output.find("div[style*='green']").text().indexOf("returns 5"))
        .toBeGreaterThan(-1);
      finish();
    });
  });

});

