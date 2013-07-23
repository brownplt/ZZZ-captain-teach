var LOG = true;
function ct_log(/* varargs */) {
  if (window.console && LOG) {
    console.log("Applying...", arguments);
    console.log(arguments);
  }
}

var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = "http://localhost:3000";

function clean(str) {
  return str.replace(/^\n+/, "").replace(/\n+$/, "");
}

var AUTOSAVE_ENABLED = true;
var COUNTER = 0;

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

function lookupVersions(resource, callback, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) { console.error(xhr, e); }
  }
  $.ajax(rails_host + '/resource/versions?resource=' + resource, {
    success: function(response, _, xhr) {
      callback(response);
    },
    error: function(xhr, error) {
      if (xhr.status === 404) {
        callback([]);
      } else {
        error(xhr, error);
      }
    }
  });
}

function lookupReview(lookupLink, success, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) { console.error(xhr, e); }
  }
  $.ajax(lookupLink, {
    success: function(response, _, xhr) {
      success(response);
    },
    error: error
  });
}

function saveResource(resource, data, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') {
    failure = function(xhr, e) {
      console.error(xhr, e);
    };
  }
  $.ajax(rails_host + "/resource/save?resource=" + resource, {
         data: {data: JSON.stringify(data)},
         success: function(response, status, xhr) { success(response); },
         error: failure,
         type: "POST"});
}

function saveReview(saveLink, data, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') {
    failure = function(xhr, e) {
      console.error(xhr, e);
    };
  }
  $.ajax(rails_host + saveLink, {
         data: {data: JSON.stringify(data)},
         success: function(response, status, xhr) { success(response); },
         error: failure,
         type: "POST"});
}

function inlineExample(container, resources, args){
  container.css("display", "inline-block");
  args.mode = "inert";
  codeExample(container, resources, args);
}

function codeExample(container, resources, args) {
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

  ASSIGNMENT_PIECES.push({id: resources, editor: editor, mode: args.mode});
  
  return { container: container, activityData: {editor: editor} };
}

function functionBuilder(container, resources, args) {

  var header = args.header;
  var check = args.check;
  var blobId = resources.blob;
  var pathId = resources.path;

  var codeContainer = jQuery("<div>");
  container.append(codeContainer);

  var gradeMode = typeof resources.reviews !== 'undefined';
  
  var versionsButton = jQuery("<button>+</button>")
    .addClass("versions");
  versionsButton.css({float: "right", padding: "0", width: "20px", height: "20px"});
  codeContainer.css("position", "relative");
  var versionsContainer = jQuery("<div>");
  var versionsList = jQuery("<div>");
  versionsContainer.append(versionsButton);
  versionsContainer.append("<div>").addClass("clearfix");
  versionsContainer.append(versionsList);
  versionsContainer.css({position: "absolute",
                         top: "0",
                         right: "0",
                         "background-color": "white",
                         "z-index": "10"});
  versionsList.css("display","none");

  codeContainer.append(versionsContainer);
  
  var versionsShown = false;
  versionsButton.click(function () {
    if (versionsShown) {
      versionsList.css("display", "none");
      versionsShown = false;
    } else {
      versionsList.css("display", "block");
      versionsShown = true;
    }
  });
  
  var editor = makeEditor(codeContainer,
                         { initial: "\n\n\n\n",
                           cmOptions: { readOnly: gradeMode },
                           run: function(src, uiOpts, replOpts) {
                             var prelude = getPreludeFor(pathId);
                             RUN_CODE(prelude + src, uiOpts, replOpts);
                           }});

  // NOTE(dbp): When we change to an old version, we save the current work as
  // a revision. However, if we are switching between many versions, we don't want
  // to keep creating new ones (only the first one).
  var onChangeVersionsCreateRevision = true;
  editor.on("change", function () {
    onChangeVersionsCreateRevision = true;
  });
  
  var doc = editor.getDoc();

  ASSIGNMENT_PIECES.push({id: pathId, editor: editor, mode: args.mode});


  function setUpEditor(doc) {
    doc.setValue("\n\n\n\n");
    var headerPoint = createInsertionPoint(doc, 0, 0);
    var bodyPoint = createInsertionPoint(doc, 1, 0);
    var checkPoint = createInsertionPoint(doc, 2, 0);
    var userChecksPoint = createInsertionPoint(doc, 3, 0);
    var endPoint = createInsertionPoint(doc, 4, 0);

    headerPoint.insert(header + "\n", { readOnly: true, left: true });
    checkPoint.insert("check:\n", { readOnly: true });
    endPoint.insert("end", { readOnly: true, right: true });

    return {header: headerPoint, body: bodyPoint, check: checkPoint,
            userChecks: userChecksPoint, end: endPoint};
  }
  
  var edData = setUpEditor(doc);
  var headerPoint = edData.header;
  var bodyPoint = edData.body;
  var checkPoint = edData.check;
  var userChecksPoint = edData.userChecks;
  var endPoint = edData.end;
  
  var button = $("<button>Save and Submit</button>")
    .addClass("submit");

  if (gradeMode) {
    button.hide();
  }

  function handleResponse(data, version) {
    console.log("handling: ", data);
    // NOTE(dbp): cache it so our changes don't count
    var oc = onChangeVersionsCreateRevision;
    
    var edData = setUpEditor(doc);
    headerPoint = edData.header;
    bodyPoint = edData.body;
    checkPoint = edData.check;
    userChecksPoint = edData.userChecks;
    endPoint = edData.end;
    
    var body = data.body || "\n";
    var userChecks = data.userChecks || "\n";
    console.log("inserting body: ", body);
    bodyPoint.insert(body);
    userChecksPoint.insert(userChecks);

    onChangeVersionsCreateRevision = oc;
  }
  
  function getWork() {
    var defn = clean(doc.getRange(headerPoint.to(), checkPoint.from()));
    var userChecks = clean(doc.getRange(checkPoint.to(), endPoint.from()));
    return {body: defn, userChecks: userChecks};
  }

  function saveWork() {
    var spinnerId = "spinner-" + COUNTER++;
    versionsButton.html("<img src='/assets/spinner.gif'/>");
    saveResource(blobId, getWork(), function () {
      setTimeout(function () {
        versionsButton.text("+");
      }, 1000);
    }, function (xhr, response) {
      console.error("Saving failed.");
    });
  }

  function loadVersions() {
    versionsList.text("");
    lookupVersions(pathId, function (versions) {
      if (versions.length == 0) {
        versionsList.append(jQuery("<span>No versions</span>"));
      }
      versions.forEach(function (v) {
        var b = jQuery("<button>").addClass("switch-version");
        b.text(v.time);
        b.on('click', function () {
          if (onChangeVersionsCreateRevision) {
            saveVersion();
          }
          lookupResource(v.resource, function (response) {
            console.log("got: ", response);
            loadVersions();
            handleResponse(JSON.parse(response.file));
          },
           function () { console.error("Couldn't find resource from version. This is bad!"); });
        });
        versionsList.append(b);
        versionsList.append(jQuery("<br>"));
      });
    });
  }

  loadVersions();

  
  function saveVersion() {
    onChangeVersionsCreateRevision = false;
    var spinnerId = "spinner-" + COUNTER++;
    versionsButton.html("<img src='/assets/spinner.gif'/>");
    saveResource(pathId, getWork(), function () {
      setTimeout(function () {
        versionsButton.text("+");
        loadVersions();
      }, 1000);
    }, function (xhr, response) {
      console.error("Saving failed.");
    });
  }
  
  button.click(function () {
    saveVersion();
    
    var lastLine = doc.lineCount()-1;
    var prelude = getPreludeFor(pathId);
    var work = getWork();
    var defn = work.body;
    var userChecks = work.userChecks;
    var prgm = prelude + "\n" + header + "\n" + defn + "\ncheck:\n" + check + "\nend";
    RUN_CODE(prgm, {
        write: function(str) { /* Intentional no-op */ }
      },
      {check: true});
  });
  container.append(button);

  // NOTE(dbp): We look up the blob first, as that is the "current" version of the file,
  // if it exists; if it doesn't exist, we look up the path-ref resource.
  
  lookupResource(blobId, handleResponse, function () {
    lookupResource(pathId,
                   function (response) {
                     console.log("response: ", response);
                     handleResponse(JSON.parse(response.file))
                   },
                   function() { });
  });

  // NOTE(dbp): We autosave to the blob. Clicking on "Save and Submit" creates a new
  // version. Switching to an old version makes a new version with the current blob version,
  // and replaces the blob with the old version.
  setInterval(function () {
    if (AUTOSAVE_ENABLED) {
      saveWork
    }
  }, 30000);
  

  var reviews = resources.reviews;
  if (typeof reviews !== 'undefined') {
    function radios(name, labels, values) {
      var radioContainer = $("<div>");
      var id;
      for(var i = 0; i < labels.length; i++) {
        id = name + i;
        radioContainer.append($("<label for='" + id + "'>")
          .text(labels[i])
          .append($("<input type='radio' id='" + id + "' name='" + name + "'>")
          .attr("value", values[i])));
      }
      return radioContainer;
    }

    var showReview = $("<button>").css({float: "right"}).text("Review");
    var reviewContainer = $("<div>").addClass("reviewContainer");

    function setupReview() {
      var submitReviewButton = $("<button>")
        .text("Save this review")
        .css({float: 'right'})
        .on("click", function(e) {
          console.log("Clicking on submit", e);
          var designScore = reviewContainer.find("input[name=design]:checked").val();
          var correctScore = reviewContainer.find("input[name=correct]:checked").val();
          console.log("Clicking on submit after scores", designScore, correctScore);
          if (designScore === undefined) {
            designRadios.css({'background-color': 'red'});
          }
          if (correctScore === undefined) {
            correctRadios.css({'background-color': 'red'});
          }
          if (designScore && correctScore) {
            designRadios.css({'background-color': 'transparent'});
            correctRadios.css({'background-color': 'transparent'});
            saveReview(reviews.path.versions[0].save, {
              review: {
                comments: reviewText.val(),
                design: designScore,
                correct: correctScore
              }
            }, function() {
              // TODO(joe 22 July 2013): Give some feedback
            });
          }
        });
      var designRadios = radios(
          "design",
          ["(Worst design) 1", 2, 3, 4, 5, 6, 7, 8, 9, "10 (Best design)"],
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        .addClass("reviewDesignScore");
      var correctRadios = radios(
          "correct",
          ["(Completely incorrect) 1", 2, 3, 4, 5, 6, 7, 8, 9, "10 (Completely correct)"],
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        .addClass("reviewCorrectScore");
      var reviewText = $("<textarea>").css({width: "100%"}).addClass("reviewText");

      reviewText.prop("disabled", true);
      if (reviews.path.versions.length === 0) {
        designRadios.hide();
        correctRadios.hide();
        reviewText.val("No versions to review");
      } else {
        lookupReview(reviews.path.versions[0].lookup, function(rev) {
            reviewText.prop("disabled", false);
            if (rev !== null) {
              reviewText.val(rev.review.comments);
              designRadios.find("input[value=" + rev.review.design + "]").click();
              correctRadios.find("input[value=" + rev.review.correct + "]").click();
            }
          },
          function(e) {
            console.error(e);
          });
      }

      reviewContainer.append(designRadios)
        .append(correctRadios)
        .append(reviewText)
        .append(submitReviewButton);
    }
    setupReview();
    container.append(showReview).append(reviewContainer);
    reviewContainer.hide();


    showReview.on("click", function(_) { reviewContainer.toggle(); })
  }

  return {container: container, activityData: {codemirror: editor}};
}

function multipleChoice(container, resources, args)  {
  var id = resources.blob;
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
    var resources;
    if (jnode.attr("data-resources")) {
      resources = JSON.parse(jnode.attr("data-resources"));
    }
    function clean(node) {
      node.removeAttr("data-resources").removeAttr("data-type").removeAttr("data-args").removeAttr("data-ct-node");
    }
    if (builders.hasOwnProperty(type)) {
      clean(jnode);
      var rv = builders[type](jnode, resources, args);
    } else {
      console.error("Unknown builder type: ", type);
    }
  });
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

