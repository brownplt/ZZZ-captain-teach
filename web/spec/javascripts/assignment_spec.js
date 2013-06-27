//= require assignment/do_assignment
//= require flapjax-impl
//= require ct
describe('loadResource', function() {
  it("Produces an event stream", function() {
    var clientThing = loadResource({resource: "r::1"}, function(s, e) {
      // do nothing
    });
    window.c = clientThing;
    expect(clientThing instanceof EventStream).toBe(true);
  });
});
