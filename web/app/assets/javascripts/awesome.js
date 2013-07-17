// BrowserId passhtru in awesome mode, if offline
if(typeof window.navigator.id === 'undefined') {
  window.navigator.id = {
    watch: function(currentUser) {
      console.log("BrowserId set up with ", currentUser);
    }
  };
}
$(function() {

  $.ajax("/all_users", {
    success: function(response, _, xhr) {
      var container = $("<div>");
      response.forEach(function(u) {
        var d = $("<div>");
        d.append($("<a>").text(u.email).attr("href", "#").click(function(e) {
          $.ajax("/become_user/" + u.id, {
            type: "POST",
            success: function(response, _, xhr) {
              console.log("Became user ", u.email);
            }
          });
        }));
        container.append(d);
      });

      var toggleAwesome = $("<a>↓</a>").click(function(e) {
        container.toggle();
        return false;
      }).addClass("awesome-toggle");

      $(document).click(function(e) {
        container.hide();
      });

      $("#awesome-panel").append(toggleAwesome).append(container);
      container.hide();

    }
  });
});

