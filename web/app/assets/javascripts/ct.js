var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = "http://localhost:3000";

function clean(str) {
  return str.replace(/^\n+/, "").replace(/\n+$/, "");
}

// global used for walking page finding pieces of code
var ASSIGNMENT_PIECES = [];

function getPreludeFor(id) {
  var prelude = "";
  for (var i = 0; i < ASSIGNMENT_PIECES.length; i++) {
    if (ASSIGNMENT_PIECES[i].id === id) {
      break;
    }
    var piece = ASSIGNMENT_PIECES[i];
    if (piece.mode === "include" || piece.mode === "include-run") {
      if (piece.code) {
        prelude += piece.code;
      } else if (piece.editor) {
        prelude += piece.editor.getValue();
      }
      prelude += "\n\n";
    }
  }

  return prelude;
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
  args.mode = "inert";
  codeExample(container, id, args);
}

function codeExample(container, resourceId, args) {
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

  ASSIGNMENT_PIECES.push({id: resourceId, editor: editor, mode: args.mode});
  
  return { container: container, activityData: {editor: editor} };
}

function functionBuilder(container, resourceId, args) {

  var header = args.header;
  var check = args.check;

  var codeContainer = jQuery("<div>");
  container.append(codeContainer);
  var editor = makeEditor(codeContainer,
                         { initial: "\n\n\n\n",
                           run: function(src, uiOpts, replOpts) {
                             console.log("running from editor for: ", header);
                             console.log("code: ", src);
                             var prelude = getPreludeFor(resourceId);
                             // console.log(prelude + src);
                             RUN_CODE(prelude + src, uiOpts, replOpts);
                           }});
  
  var doc = editor.getDoc();

  ASSIGNMENT_PIECES.push({id: resourceId, editor: editor, mode: args.mode});

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
    var prelude = getPreludeFor(resourceId);
    var defn = clean(doc.getRange(headerPoint.to(), checkPoint.from()));
    var userChecks = clean(doc.getRange(checkPoint.to(), endPoint.from()));
    var prgm = prelude + "\n" + header + "\n" + defn + "\ncheck:\n" + check + "\nend";
    console.log(prgm);
    RUN_CODE(prgm, {
        write: function(str) { /* Intentional no-op */ }
      },
      {check: true});
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
}

function multipleChoice(container, id, args)  {
    function optionId(option) {
      return args.id + option.name;
    }
    function colorify(data) {
      args.choices.forEach(function(option) {
        var optNode = container.find("#" + optionId(option));
        var labelNode = container.find("[for=" + optionId(option) + "]");
        if(data.selected === option.name) {
          optNode.prop('checked',true);
          if(option.type === "choice-incorrect") {
            labelNode.css("background-color", "red");
            optNode.css("background-color", "red");
          }
        }
        if(option.type === "choice-correct") {
          labelNode.css("background-color", "green");
          optNode.css("background-color", "green");
        }
        optNode.attr("disabled", true);
      });
    }
    function addElements() {
      var form = $("<form>");
      args.choices.forEach(function(option) {
        var optDiv = container.find("#" + option.name);
        var optNode = $("<input type='radio'>").
          attr('id', optionId(option)).
          attr('data-name', option.name).
          attr('name', args.id);
        var labelNode = $("<label>").attr("for", optionId(option));
        form.append(optNode).append(labelNode).append($("<br>"));
        labelNode.append(optDiv.contents());
      });
      container.append(form);
    }
    lookupResource(id, 
      function(response) {
        addElements();
        colorify(response);
      },
      function() {
        addElements();
        var button = $("<button>Submit</button>");
        button.attr("disabled", true);
        container.find("input[type=radio]").click(function() {
          button.attr("disabled", false);
        });
        button.click(function() {
          // NOTE(joe): Early return to simulate real mouse clicks on
          // disabled buttons when clicks sent programatically
          if (button.attr("disabled") === "disabled") return false;
          var selected = container.find(":checked").attr("data-name");
          var data = {"selected": selected};
          saveResource(id, data, function() {
              button.hide();
              colorify(data);
            },
            function(xhr, error) {
              console.error("Save failed: ", xhr, error); 
            });
          return false;
        });
        container.append(button);
      },
      function(xhr, error) {
        console.error(error);
      });
    return {container: container};
  }

var builders = {
  "inline-example": inlineExample,
  "code-example": codeExample,
  "function": functionBuilder,
  "multiple-choice": multipleChoice,
  "code-library": function(container, id, args) {
    ASSIGNMENT_PIECES.push({id: id, code: args.code, mode: args.mode});
    return $("<div>");
  }
};


// ct_transform looks for elements with data-ct-node=1,
// and then looks up their data-type in the builders hash,
// extracts args and passes the unique id, the args, and the node
// itself to the builder. The builder does whatever it needs to do,
// and eventually should replace the node with content.
function ct_transform(dom) {
  dom.find("[data-ct-node=1]").each(function (_, node) {
    var jnode = $(node);
    var args = JSON.parse(jnode.attr("data-args"));
    var type = jnode.attr("data-type");
    var id = jnode.attr("data-id");
    function clean(node) {
      node.removeAttr("data-id").removeAttr("data-type").removeAttr("data-args").removeAttr("data-ct-node");
    }
    if (builders.hasOwnProperty(type)) {
      clean(jnode);
      var rv = builders[type](jnode, id, args);
    } else {
      console.error("Unknown builder type: ", type);
    }
  });
}

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

