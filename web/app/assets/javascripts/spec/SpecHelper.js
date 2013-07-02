beforeEach(function() {
  this.addMatchers({
    toContainStr: function(expectedStr) {
      var inputStr = this.actual;
      return inputStr.indexOf(expectedStr) !== -1;
    }
  });
});
