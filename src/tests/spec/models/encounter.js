describe("Encounter", function() {

  describe("ReplEncounter", function() {
    var encounter;

    beforeEach(function() {
      encounter = new ReplEncounter({code: "fun foo(): 'bar' end",
                                instructions: "These are the instructions"});
    });

    it("should be able to render itself", function() {
      var div = jQuery("<div>");
      encounter.render(div);
      expect(div[0].childNodes.length).not.toEqual(0);
    });

    it("should update it's code attribute on save", function() {
      var msg = "ARRRRRRRRRRRRRRRR!!!!";
      encounter.render(jQuery("<div>"));
      encounter.editor.setValue(msg);
      encounter.save();
      expect(encounter.code).toEqual(msg);
    });
  });

  describe("DesignRecipeEncounter", function() {
    var encounter;
    

  });

});
