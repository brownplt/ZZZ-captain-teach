var casper = require('casper').create();
// var cedric = require('casper').create();

casper.start('http://localhost:4000/', function() {
  this.click(".awesome-toggle");
  // NOTE(dbp 2013-08-08): henry is created after edward, so second
  this.click("#awesome-panel div a:nth-child(2)");
  this.waitForResource("become_user/2", function() {
    this.echo("Logged in as Henry");
  });
});

// cedric.start('http://localhost:4000/', function() {
//   this.click(".awesome-toggle");
//   // NOTE(dbp 2013-08-08): cedric is created after henry, so third
//   this.click("#awesome-panel div a:nth-child(3)");
//   this.waitForResource("become_user/3", function() {
//     this.echo("Logged in as Cedric");
//   });
// });

casper.thenOpen('http://localhost:4000/course', function() {
  this.click("a.course a:first-child");
  this.evaluate(function () {
    // $(".CodeMirror")[0].focus();
  });
  // this.sendKeys(".CodeMirror .textarea", "Some code! Yay");
  this.capture("casper-ss-henry.png");
});

// cedric.thenOpen('http://localhost:4000/course', function() {

// });


casper.run();
// cedric.run();
