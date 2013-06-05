describe("Encounter", function() {
  var encounter;

  beforeEach(function() {
    encounter = new ReplEncounter({code: "fun foo(): 'bar' end",
                              instructions: "These are the instructions"});
  });

  it("should be able to render itself", function() {
    var div = jQuery("<div>");
    encounter.render(div);
    expect(div[0].childNodes.length).not.toEqual(0)
  });
});
