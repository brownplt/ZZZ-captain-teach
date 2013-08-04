var casper = require('casper').create();

function logPage(casper) {
  casper.echo("Loaded page: " + casper.getTitle());
}

casper.start('http://localhost:4000/', function() {
  logPage(this);
  this.click(".awesome-toggle");
  this.click("#awesome-panel div a:first-child");
  this.waitForResource("become_user/1", function() {
    this.echo("Logged in as the Captain");
  });
});

casper.thenOpen('http://localhost:4000/course/1', function() {
  logPage(this);
});

casper.run();
