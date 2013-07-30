describe("reviews interactions", function () {

  it("should work", function () {
    var name = TESTDATA.parts[0].name;

    function review_fun(editor, resume) {
      console.log("HELLO!");
      resume();
    }

    options = {
      run: function() {},
      names: [name, "foo"],
      initial: {foo: "\n\n"},
      steps: [name, "foo"],
      afterHandlers: {}
    };
    options.initial[name] = "\n";
    options.afterHandlers[name] = review_fun;
    
    var editor = steppedEditor(
      $("#review-editor"),
      [
        "check:",
        "\nend",
        "\nFoo Stage"
      ],
      options);


  });
  
});
