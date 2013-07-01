var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = "http://localhost:3000";

var builders = {
  "multiple-choice": function (node,id,args) {
    var form = $("<form>");
    $.ajax(rails_host + "/blob/lookup?resource="+id, {
      success: function(response,_,xhr) {
        // in this case, there was an entry, so the choice has already
        // been made. we just want to display options with their choice
        // selected.
        args.forEach(function(option, index) {
          console.log(option);
          var optNode = $("<input type='checkbox' id='option"+index+
                          "' value='" +
                          option.name + "'>" + "</input>");
          
          var labelNode = $("<label for='option"+index+"'></label");
          labelNode.text(option.content);
          if (response.selected === option.name) {
            optNode.prop('checked',true);
          }
          if (option.type === "choice-correct") {
            labelNode.css("background-color", "green");
          }
          optNode.attr("disabled", true);
          form.append(labelNode);
          form.append(optNode);
          form.append($("<br/>"));
        });
      },
      error: function(xhr,_,error) {
        window.x = xhr;
        window.e = error;
        if (xhr.status == 404) {
          // no entry, so create form
          args.forEach(function(option, index) {
            console.log(option);
            console.log(option.content);
            var optNode = $("<input type='checkbox' id='option"+index+
                            "' value='" +
                            option.name + "'>" + "</input>");
            var labelNode = $("<label for='option"+index+"'></label");
            labelNode.text(option.content);
            form.append(labelNode);
            form.append(optNode);
            form.append($("<br/>"));
          });
          var button = $("<button>Submit</button>");
          button.click(function() {
            var selected = form.find(":checked").attr("value");
            console.log(selected);
            $.post(rails_host + "/blob/save?resource="+id, {
              data: JSON.stringify({"selected": selected})
            });
            return false;
          });
          form.append(button);
        } else {
          console.error(error);
        }
      }})
    return form;
  }
};

// ct_transform looks for elements with data-ct-node=1,
// and then looks up their data-type in the builders hash,
// extracts args and passes the unique id, the args, and the node
// itself to the builder. The builder does whatever it needs to do,
// and eventually should replace the node with content.
function ct_transform(dom) {
  $("div[data-ct-node=1]").each(function (_, node) {
    var jnode = $(node);
    var args = JSON.parse(jnode.attr("data-args"));
    // NOTE(dbp): all of this code obviously needs to be fixed,
    // but this is particularly agregious - we are just setting the
    // user id here.
    var id = jnode.attr("data-id") + ":1";
    if (builders.hasOwnProperty(jnode.attr("data-type"))) {
      var newNode = builders[jnode.attr("data-type")](jnode,id,args);
      jnode.replaceWith(newNode);
    }
  });
}

$(function() {
    ct_transform(document.body);
});

function ct_blob(resource, params) {
  params.dataType = 'json';
  params.data = { data : JSON.stringify(params.blobData) };
  return ct_ajax("/blob?resource="+resource, params);
}

function ct_ajax(url, params) {
    if (typeof params === 'undefined') { params = {}; }
    if (!params.hasOwnProperty("error")) {
        params.error = function (error) {
            console.error(error);
        }
    }
    var receiver = receiverE();
    function handleSuccess(response, _, xhr) {
      receiver.sendEvent({status: xhr.status, response: response, xhr: xhr});
    }
    function handleError(xhr, _, error) {
      try {
        receiver.sendEvent({status: xhr.status, response: error, xhr: xhr});
      }
      catch(e) {
        console.error("Failed to process error", e, url, xhr, error);
      }
    }
    params.success = handleSuccess;
    params.error = handleError;
    $.ajax(url, params);
    return receiver;
}

function worldB(init, handlers, transformers) 
/*: ∀ α . α
        * Array<∃ β . {0: EventStream<β>, 1: α * β -> α}>
        * ∃ (γ₁ ...) { key₁: α -> γ₁, ... }
        -> { key₁: EventStream<γ₁>, ... }
        */
{
  var theWorld = mergeE.apply(zeroE,
    handlers.map(function(handler)
    /*: ∃ β . {0: EventStream<β>, 1: α * β -> α} -> EventStream<α -> α> */
    {
      return handler[0].mapE(function(eventValue) /*: β -> (α -> α) */ {
        return function(world) /*: α -> α */ {
          return handler[1](world, eventValue);
        };
      });
    }))
   .collectE(init, function(handler, world) /*: (α -> α) * α -> α */ {
      return handler(world);
    })
   .startsWith(init);

  var facets = {};
  Object.keys(transformers).forEach(function(key) {
    if (typeof transformers[key] === 'function') {
      facets[key] = theWorld.liftB(transformers[key]);
    } else {
      facets[key] = transformers[key];
    }
  });
  return facets;
}

