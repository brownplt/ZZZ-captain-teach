var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = "http://localhost:3000";

function lookupBlob(resource, present, absent, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) { console.error(xhr, e); }
  }
  $.ajax(rails_host + '/blob/lookup?resource=' + resource, {
    success: function(response, _, xhr) {
      present(response);
    },
    error: function(xhr, error) {
      if (xhr.status === 404) {
        absent();
      } else {
        error(xhr, error);
      }
    }
  });
}

function saveBlob(resource, data, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') { failure = function() {}; }
  $.post(rails_host + "/blob/save?resource=" + resource, {
    data: JSON.stringify(data),
    success: function(_, __, response) { success(response); },
    error: failure
  });
}

function codeExample(container, id, args) {
  var code = args.code;
  var codeContainer = jQuery("<div>");
  container.append(codeContainer);
  var editor = makeEditor(codeContainer, {
      cmOptions: {
        readOnly: 'nocursor'   
      },
      initial: code,
      run: function() {}
   });
  return { container: container, activityData: {editor: editor} };
}

var builders = {
  "code-example": codeExample,
  "function": function (container, resourceId, args) {
    var header = args.header;
    var check = args.check;

    var replContainer = jQuery("<div>");
    var codeContainer = jQuery("<div>");
    container.append(codeContainer);
    container.append(replContainer);
    var runFun = makeRepl(replContainer);
    var editor = makeEditor(codeContainer,
                           { initial: "",
                             run: runFun });
    var doc = editor.getDoc();

    doc.setValue(header + "\n\ncheck:\n\nend");

    function markFixed(startLine, endLine) {
      return doc.markText(CodeMirror.Pos(startLine, 0), CodeMirror.Pos(endLine, 0),
                 {className: 'cptteach-fixed',
                  readOnly: true, atomic: true});
    }


    var headerMark = markFixed(0, 1);
    var checkMark = markFixed(2, 3);
    var endMark = markFixed(4, 5);

    var button = $("<button>Submit</button>");
    button.click(function () {
      var lastLine = doc.lineCount()-1;
      console.log(headerMark.find());
      console.log(checkMark.find());
      var defn = doc.getRange(headerMark.find().to, checkMark.find().from);
      var userChecks = doc.getRange(checkMark.find().to, endMark.find().from);
      var prgm = header + "\n" + defn + "\ncheck:\n" + userChecks + "\n" +
        check + "\nend";
      console.log(prgm);
      runFun(prgm, {check: true});
      saveBlob(resourceId, { body: defn, userChecks: userChecks });
    });

    container.append(button);

    lookupBlob(resourceId,
      function(data) {
        var body = data.body || "\n";
        var userChecks = data.userChecks || "\n";
        doc.replaceRange(body, headerMark.find().to, checkMark.find().from);
        doc.replaceRange(userChecks, checkMark.find().to, endMark.find().from);
      },
      function() { });
    
    return {container: container, activityData: {codemirror: editor}};
  },
  "multiple-choice": function (container,id,args) {
    var form = $("<form>");
    container.append(form);
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
    return {container: container};
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
    if (builders.hasOwnProperty(jnode.attr("data-type"))) {
      var container = $("<div>");
      jnode.replaceWith(container);
      var rv = builders[jnode.attr("data-type")](container, jnode.attr("data-id"), args);
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

