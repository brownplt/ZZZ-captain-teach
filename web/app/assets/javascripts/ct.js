var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = "http://localhost:3000";

function clean(str) {
  return str.replace(/^\n+/, "").replace(/\n+$/, "");
}

function createInsertionPoint(doc, line, ch) {
  function markReadOnly(from, to, left, right) {
    return doc.markText(
        from, to,
        {className: 'cptteach-fixed',
         inclusiveLeft: left,
         inclusiveRight: right,
         readOnly: true});
  }
  var start = doc.setBookmark({line: line, ch: ch});
  var end = doc.setBookmark({line: line, ch: ch}, {insertLeft: true});
  return {
    from: function() { return start.find(); },
    to: function() { return end.find(); },
    get: function() {
      return doc.getRange(start.find(), end.find());
    },
    insert: function(val, options) {
      var defaults = {
        left: false,
        right: false,
        readOnly: false
      };
      var realOptions = _.extend(defaults, options || {});
      doc.replaceRange(val, start.find());
      if (realOptions.readOnly) {
        markReadOnly(
            start.find(),
            end.find(),
            realOptions.left,
            realOptions.right);
      }
    }
  };
}

function lookupResource(resource, present, absent, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) { console.error(xhr, e); }
  }
  $.ajax(rails_host + '/resource/lookup?resource=' + resource, {
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

function saveResource(resource, data, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') { failure = function() {}; }
  $.post(rails_host + "/resource/save?resource=" + resource, {
    data: JSON.stringify(data),
    success: function(_, __, response) { success(response); },
    error: failure
  });
}

function inlineExample(container, id, args){
  container.css("display", "inline-block");
  codeExample(container, id, args);
}

function codeExample(container, _, args) {
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
  "inline-example": inlineExample,
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
                           { initial: "\n\n\n\n",
                             run: runFun });
    var doc = editor.getDoc();

    var headerPoint = createInsertionPoint(doc, 0, 0);
    var bodyPoint = createInsertionPoint(doc, 1, 0);
    var checkPoint = createInsertionPoint(doc, 2, 0);
    var userChecksPoint = createInsertionPoint(doc, 3, 0);
    var endPoint = createInsertionPoint(doc, 4, 0);

    headerPoint.insert(header + "\n", { readOnly: true, left: true });
    checkPoint.insert("check:\n", { readOnly: true });
    endPoint.insert("end", { readOnly: true, right: true });
    var button = $("<button>Submit</button>");
    button.click(function () {
      var lastLine = doc.lineCount()-1;
      var defn = clean(doc.getRange(headerPoint.to(), checkPoint.from()));
      var userChecks = clean(doc.getRange(checkPoint.to(), endPoint.from()));
      var prgm = header + "\n" + defn + "\ncheck:\n" + check + "\nend";
      runFun(prgm, {check: true});
      saveResource(resourceId, { body: defn, userChecks: userChecks });
    });
    container.append(button);

    lookupResource(resourceId,
      function(response) {
        var data = JSON.parse(response.file);
        var body = data.body || "\n";
        var userChecks = data.userChecks || "\n";
        bodyPoint.insert(body);
        userChecksPoint.insert(userChecks);
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
            $.post(rails_host + "/resource/save?resource="+id, {
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
  $("[data-ct-node=1]").each(function (_, node) {
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

