"use strict";
var NO_INSTANCE_DATA = {no_instance_data: true};

var rails_host = RAILS_HOST;

function clean(str) {
  return str.replace(/^\n/, "");//.replace(/\n+$/, "");
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

function lookupResource(resource, present, absent, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) {
      ct_error("lookupResource failed:", resource, xhr, e);
    }
  }
  $.ajax(rails_host + '/resource/lookup?resource=' + resource, {
    success: function(response, _, xhr) {
      present(response);
    },
    error: function(xhr, errorMsg) {
      if (xhr.status === 404) {
        ct_log("Not found (expected): ", resource, xhr);
        absent();
      } else {
        error(xhr, errorMsg);
      }
    }
  });
}

function lookupVersions(resource, callback, error) {
  if (typeof error === 'undefined') {
    error = function(xhr, e) {
      ct_error("lookupVersions failed:", resource, xhr, e);
    }
  }
  $.ajax(rails_host + '/resource/versions?resource=' + resource, {
    success: function(response, _, xhr) {
      callback(response);
    },
    error: function(xhr, errorMsg) {
      if (xhr.status === 404) {
        callback([]);
      } else {
        error(xhr, errorMsg);
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

function submitResource(resource, type, toSave, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') {
    failure = function(xhr, e) {
      ct_error(xhr, e);
    };
  }
  $.ajax(rails_host + "/resource/submit?resource=" + resource, {
    data: { data: JSON.stringify({step_type: type, to_save: toSave}) },
    success: function(response, _, xhr) {
      success(response);
    },
    error: failure,
    type: "POST"
  });
}

function saveResource(resource, data, success, failure) {
  if (typeof success === 'undefined') { success = function() {}; }
  if (typeof failure === 'undefined') {
    failure = function(xhr, e) {
      ct_error(xhr, e);
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
      ct_error(xhr, e);
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
  var elem = $("<span class='inlineExample cm-s-default'>");
  container.append(elem);
  formatCode(elem[0], args.code);
}

var runningLib = false;
function codeLibrary(container, resources, args) {
  var code = args.code;
  var codeContainer = jQuery("<div>");

  var run = namedRunner(RUN_CODE, "example");

  container.append(codeContainer);
  var cm = makeEditor(codeContainer, {
      simpleEditor: true,
      initial: code,
      run: run
    });

  window.ADDITIONAL_IDS = window.ADDITIONAL_IDS.concat(args.ids);

  // TODO(joe): Depending on how rigidly setTimeout() orders things,
  // this may have a race condition for many libraries
  function runNextLib() {
    if(runningLib === false) {
      runningLib = true;
      run(code, {
          cm: cm,
          handleReturn: function(v) {
            runningLib = false;
          }
        }, {
          "cache?": true,
          check: false,
          "allow-shadow": true,
          "additional-ids": window.ADDITIONAL_IDS
        });
    }
    else {
      window.setTimeout(runNextLib, 0);
    }
  }
  runNextLib();

  return { container: container, activityData: {editor: cm} };
}

function codeExample(container, resources, args) {
  var code = args.code;
  var codeContainer = jQuery("<div>");
  var simple = (args.mode === "no-run") || (args.mode === "library");
  if (!simple) {
    var resetButton = drawResetButton();
    container.append(resetButton);
    resetButton.on("click", function () {
      if (ct_confirm("Are you sure you want to reset the editor?")) {
        cm.setValue(code);
      }
    });
  }

  var run = makeLoggingRunCode(makeHighlightingRunCode(RUN_CODE), "example");

  container.append(codeContainer);
  var cm = makeEditor(codeContainer, {
      simpleEditor: simple,
      initial: code,
      run: run
    });

  if(args.mode === "library") {
    run(code, {cm: cm}, {check: false, "allow-shadow": true});
  }

  ASSIGNMENT_PIECES.push({id: resources, editor: cm, mode: args.mode});

  return { container: container, activityData: {editor: cm} };
}

function fileUpload(container, resources, args) {
  var uploadContainer = $("<div>").css({
        width: "100%",
        border: "1px solid #111",
        margin: "1em",
        padding: "1em"
      });
  var name = $("<p>").text(args.name);
  var submit = $("<button>").text("Submit file").prop("disabled", true);

  var widget = $("<input type='file'>").on("change", function() {
    submit.prop("disabled", false);
  });

  var showCurrent = function() {
    var current = $("<div>");
    var submission = $("<textarea>").css({
        height: "20em",
        width: "100%",
        overflow: "auto"
      });
    var message = $("<label>Most recent submission: </label>");
    current.append(message).append("<br/>").append(submission);
    lookupResource(resources.path, function(data) {
        submission.val(JSON.parse(data.file));
        drawModal(current, function() { /* intentional no-op */});
      }, function() {
        submission.val("(No submission yet)");
        drawModal(current, function() { /* intentional no-op */});
      });
  };

  var seeCurrent = $("<a href='#'>").text("See current submission").
    on("click", function() {
      showCurrent();
      return false;
    });
  
  submit.on("click", function(elt) {
    var file = widget[0].files[0];
    var reader = new FileReader();

    reader.onload = function(e) {
      saveResource(resources.path, reader.result, function() {
        showCurrent();
      })
    }

    reader.readAsText(file);
  });
  uploadContainer.append(name).append(widget).append(submit).append("<br>").append(seeCurrent);
  container.append(uploadContainer);
  return {};
}

function openResponse(container, resources, args) {
  var options = {
    tabName: "Response",
    runButton: false,
    highlight: false,
    lineWrap: true,
    overrideSectionName: args.name
  };
  args.codeDelimiters = [{type: "code", value: " "}, {type: "code", value: "\n "}];
  return steppedAssignment(container, resources, args, options);
}

function codeAssignment(container, resources, args) {
  var options = {
    tabName: "Code",
    runButton: true,
    highlight: true,
    lineWrap: true,
    overrideSectionName: false
  };
  return steppedAssignment(container, resources, args, options);
}

function steppedAssignment(container, resources, args, options) {
  var tabs = createTabPanel(container);
  var editorContainer = drawEditorContainer();
  tabs.addTab(options.tabName, editorContainer, { cannotClose: true });

  var saveContainer = drawSaveContainer();
  editorContainer.append(saveContainer);

  var sharedCmOptions = {
    mode: options.highlight ? "pyret" : null,
    lineWrapping: options.lineWrap
  };

  var codeDelimiters =
    args.codeDelimiters.map(function (cd) {
    if (cd.type === "code") {
      return cd;
    } else if (cd.type === "instructions") {
      return {type: "dom", value: drawInstructionsWidget(cd.value)[0]};
    } else {
      ct_error("codeAssignment: got a code delimiter I didn't understand: ", cd);
    }
  });

  var delimiterValues = codeDelimiters.map(function (codeDelimiter) {
    return codeDelimiter.value;
  }).filter(function (val) {
    return typeof val === "string";
  });

  var defaultParts = {};
  args.parts.forEach(function(n) {
    defaultParts[n.value] = "\n";
  });

  var defaultStep = resources.steps.length > 0 ? resources.steps[0].name : "no-step";
  var defaultActivityState = {
    status: {
      step: defaultStep,
      reviewing: false
    },
    parts: defaultParts
  };

  function setupAssignment(activityState) {
    ct_log("as: ", activityState);
    ct_log("Args: ", args);
    ct_log("Resources: ", resources);

    var currentState = activityState.status;
    var names = _.pluck(args.parts, "value");
    var steps = [];
    resources.steps.forEach(function(elt) {
      steps.push(elt.name);
    });
    var sharedOptions = {
      run: options.runButton ?
        makeLoggingRunCode(makeHighlightingRunCode(RUN_CODE), args.name) :
        false,
      names: names,
      steps: steps,
      afterHandlers: {},
      cmOptions: sharedCmOptions
    };

    function getContents() {
      var parts = {};
      args.parts.forEach(function(p) {
        parts[p.value] = editor.getAt(p.value);
      });
      return parts;
    }


    var afterReview = ctC("afterReview", [TString, TFunction],
      function(step, resumeCoding) {
        var toSaveAfterReview = {};
        toSaveAfterReview.parts = getContents();
        var indexOfStep = _.indexOf(steps, step);
        var status;
        editor.enableAll();
        if (indexOfStep === (resources.steps.length - 1)) {
          status = { done: true, step: step };
          ct_alert("You have submitted all parts of this assignment.  You can still edit it, and changes you make before the deadline can help your final grade.");
        }
        else {
          status = {
            reviewing: false,
            step: resources.steps[indexOfStep + 1].name
          };
        }
        toSaveAfterReview.status = status;
        currentState = status;
        saveResource(resources.path, toSaveAfterReview, resumeCoding);
      });

    function wrapStepForReview(step) {
      return {
        type: step.type,
        getReviewData: function(f, e) {
          function wrapResult(reviewData) {
            f(reviewData.map(function(rd) {
                return {
                  submission_id: rd.submission_id,
                  saveReview: function(val, success, failure) {
                    saveResource(
                        rd.save_review,
                        _.extend(val, { resource: rd.resource }),
                        function() {
                          lookupResource(
                              step.read_feedback,
                              success,
                              function() { success([]); },
                              failure
                          );
                        },
                        failure
                    );
                  },
                  getReview: function(present, absent) {
                    lookupResource(rd.save_review, present, absent);
                  },
                  attachWorkToReview: function(editorContainer, f, e) {
                    function wrapReviewContent(_content) {
                      var content = JSON.parse(_content.file);
                      var editor = readOnlyEditorFromParts(editorContainer, delimiterValues, content.parts, sharedOptions);
                      var reviewsInline = $("<div>");
                      editor.addWidgetAt(step.name, reviewsInline[0]);
                      f(reviewsInline);
                      // NOTE(dbp 2013-08-16): Reset reviewsTab size.
                      editorContainer.css("min-height", "");
                    }
                    ct_log(rd);
                    lookupResource(rd.resource, wrapReviewContent, e);
                  }
                }
              }))
          }
          lookupResource(step.do_reviews, wrapResult, e);
        }
      };
    }

    var editorOptions = merge(sharedOptions, {
        overrideSectionName: options.overrideSectionName,
        initial: activityState.parts,
        done: currentState.done,
        drawPartGutter: function(stepName, insert) {
          function insertOnce(elt) {
            insert(elt[0]);
            insertOnce = function() {}
          }
          var step = _.findWhere(resources.steps, { name: stepName });
          var toRead = step.read_reviews;
          var elt = drawReviewsButton();
          lookupResource(toRead, function(reviews) {
            if (reviews.length !== 0) {
              setReviewNumber(elt, reviews.length);
              insertOnce(elt);
              elt.on("click", function() {
                var reviewsDiv = drawReviewsDiv(args.name, stepName);
                reviews.forEach(function(r) {
                  ct_log("Review is: ", r);
                  lookupResource(r.resource, function(_data) {
                    var data = JSON.parse(_data.file);
                    var editor = readOnlyEditorFromParts(
                      reviewsDiv,
                      delimiterValues,
                      data.parts,
                      sharedOptions);

                    function handleFeedback(feedback) {
                      showReview(editor, step, r, feedback,
                                 function (f, succ, fail) {
                                   saveResource(r.feedback,
                                                f,
                                                succ,
                                                fail);
                                 },
                                 reviewAbuseData(r, toRead, step));
                    }
                    lookupResource(r.feedback, function(feedback) {
                      handleFeedback(feedback);
                    }, function () {
                      handleFeedback(null);
                    });
                  }, function () {});
                });
                window.PANEL.addTab("Rev: " +
                                    args.name +
                                    ":" +
                                    stepName, reviewsDiv);
                return false;
             });
            }
          }, function() { /* intentional no-op */ });

          ct_log("step is: ", step);
          lookupResource(step.read_feedback, function(feedback) {
            if(feedback.length > 0) {
              var feedbackContainer = drawFeedbackContainer();
              setHasFeedback(elt);
              insertOnce(elt);
              elt.on("click", function() {
                feedback.forEach(function(f) {
                  var reviewsDiv = drawReviewsDiv(args.name, stepName);
                  feedbackContainer.append(reviewsDiv);
                  lookupResource(f.content, function(_code) {
                       lookupResource(f.review, function(r) {
                         var code = JSON.parse(_code.file);
                         var editor = readOnlyEditorFromParts(
                           reviewsDiv,
                           delimiterValues,
                           code.parts,
                           sharedOptions);
                         showReview(editor, step, r, f, function() { /* intentional no-op */ }, feedbackAbuseData(r, step.read_feedback, step));
                      });
                   }, function() { ct_log("Review target content failed"); });
                });
                window.PANEL.addTab("Feedback: " +
                                args.name +
                                ":" +
                                stepName, feedbackContainer);
                return false;
              });
            }
          }, function() { ct_log("read_feedback failed"); });
        }
      });

    function reviewAbuseData(rev, resource, step) {
      var url = String(window.location);
      return {
        review: { type: "review", review: rev, resource: resource, url: url, step: step },
        feedback: false
      }
    }
    function feedbackAbuseData(rev, resource, step) {
      var url = String(window.location);
      return {
        review: false,
        feedback: { type: "feedback", review: rev, resource: resource, url: url, step: step }
      };
    }


    resources.steps.forEach(function(step) {
      editorOptions.afterHandlers[step.name] = function(editor, resume) {
        ct_log("after ", step.name);
        var toSave = {};
        toSave.parts = getContents();
        var status = { step: step.name, reviewing: true };
        toSave.status = status;
        currentState = status;

        //saveResource(resources.path, toSave, function() {
        editor.disableAll();
        function afterSubmit() {
          // NOTE(dbp 2013-08-16): Scroll so the tab panel is
          // visible.
          var top = tabs.container.offset().top;
          if (window.pageYOffset > top) {
            $("body").animate({
              scrollTop: top
            });
          }

          reviewTabs(tabs, wrapStepForReview(step), function() { afterReview(step.name, resume); });
        }
        submitResource(resources.path, step.name, toSave, afterSubmit);
        //}, function() {
        //  ct_error("Shouldn't fail to save work: ", resources.path, toSave);
        // });
      }
    });

    var editor = steppedEditor(
        editorContainer,
        codeDelimiters,
        editorOptions
      );

    var saver = autoSaver(saveContainer, {
        save: function(f, e) {
          saveResource(resources.path, {
              parts: getContents(),
              status: currentState
            },
            f,
            e
          );
        }
      });

    editor.cm.on("change", saver.onEdit);

    if (currentState.reviewing) {
      editor.disableAll();
      reviewTabs(
          tabs,
          wrapStepForReview(_.findWhere(resources.steps, { name: currentState.step })),
          function() {
            afterReview(
              currentState.step,
              function() { editor.advanceFrom(currentState.step); });
          }
      );
    }
    else {
      editor.resumeAt(currentState.step);
    }
  }

  lookupResource(
      resources.path,
      function(state) { setupAssignment(JSON.parse(state.file)); },
      function() { setupAssignment(defaultActivityState); }
  );

  return {
    container: container,
    activityData: {}
  };
}

function functionBuilder(container, resources, args) {

  var header = args.header;
  var check = args.check;
  var blobId = resources.blob;
  var pathId = resources.path;

  var codeContainer = jQuery("<div>");
  container.append(codeContainer);
  codeContainer.css("position", "relative");

  var gradeMode = typeof resources.reviews !== 'undefined';

  var cm = makeEditor(codeContainer,
                      { initial: "",
                        cmOptions: { readOnly: gradeMode, lineNumbers: true },
                        run: function(src, uiOpts, replOpts) {
                          var prelude = getPreludeFor(pathId);
                          RUN_CODE(prelude + src, uiOpts, replOpts);
                        }});

  var doc = cm.getDoc();

  ASSIGNMENT_PIECES.push({id: pathId, editor: cm, mode: args.mode});

  var editor = createEditor(cm, [
      header,
      "\ncheck:",
      "\nend"
    ], {
      names: ["definition", "checks"],
      initial: {definition: "\n", checks: "\n"}
    });

  var button = $("<button>Save and Submit</button>")
    .addClass("submit");

  if (gradeMode) {
    button.hide();
  }

  function handleResponse(data, version) {
    console.log("handling: ", data);

    editor.setAt("definition", data.body);
    editor.setAt("checks", data.userChecks);
  }

  function getWork() {
    var defn = editor.getAt("definition");
    var userChecks = editor.getAt("checks");
    return {body: defn, userChecks: userChecks};
  }

  function saveWork() {
    // TODO(joe): Some gif for pending save goes here
    versionsUI.onStartSave();
    saveResource(blobId, getWork(), function () {
      setTimeout(function () {
        versionsUI.onFinishSave();
      }, 1000);
    }, function (xhr, response) {
      ct_error("Saving failed.");
    });
  }

  var versionsUI = versions(codeContainer, {
    panel: window.PANEL,
    name: "Function Definition",
    lookupVersions: function(success, error) {
      lookupVersions(pathId, function(versions) {
        success(versions.map(function(v) {
          return {
            lookup: function(success2, error2) {
              lookupResource(v.resource, success2, error2, error2);
            },
            time: v.time,
            reviews: v.reviews.map(function(r) {
              return {
                lookup: function(success2) {
                  lookupReview(r.lookup, success2);
                }
              };
            }),
            original: v
          };
        }));
      });
    },
    save: function(success, error) {
      saveResource(pathId, getWork(), success, error);
    },
    onLoadVersion: function(response) {
      handleResponse(JSON.parse(response.file));
    }
  });

  cm.on("change", versionsUI.onChange);

  button.click(function () {
    versionsUI.saveVersion();

    var prelude = getPreludeFor(pathId);
    var work = getWork();
    var defn = work.body;
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
  if (gradeMode) {
    writeReviews(container, {
      hasReviews: Number(reviews.path.versions.length) > 0,
      reviews: {
          save: function(review, success, failure) {
            saveReview(
              reviews.path.versions[0].save,
              review,
              success,
              failure
            );
          },
          lookup: function(success, failure) {
            lookupReview(
              reviews.path.versions[0].lookup,
              success,
              failure
            );
          }
        }
      });
  }

  return {container: container, activityData: {codemirror: cm}};
}

function textResponse(container, blob, input, pred, transform) {
  var button = $("<button>").prop("disabled", true).text("Submit");
  function drawExisting(response) {
    input.val(response.answer);
    input.prop("disabled", true);
    button.prop("disabled", true);
  }
  lookupResource(blob, drawExisting, function() {
    input.on("keyup", function(e) {
      var okVal = pred(input.val());
      button.prop("disabled", !okVal);
    });
    button.on("click", function(e) {
      var response = { answer: transform(input.val()) };
      saveResource(blob, response, function() { drawExisting(response); },
        function() { ct_error("Failed to save answer: ", answer); });
    });
  })
  container.append(input).append(button);
  return {container: container, activityData: {}};

}

function freeResponse(container, resources, args) {
  return textResponse(
      container,
      resources.blob,
      $("<textarea>").addClass("freeResponse"),
      function(val) { return val != ""; },
      function(val) { return val; }
  );
}

function numberResponse(container, resources, args) {
  return textResponse(
      container,
      resources.blob,
      $("<input type='text'>").addClass("numberResponse"),
      function(val) {
        var nval = Number(val);
        return (val != "") && (nval <= args.max) && (nval >= args.min);
      },
      function(val) {
        return Number(val);
      }
  );
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
        if(option.type === "choice-neutral") {
          labelNode.css("background-color", "gray");
          optNode.css("background-color", "gray");
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
            ct_error("Save failed: ", xhr, error);
          });
        return false;
      });
      container.append(button);
    },
    function(xhr, error) {
      ct_error(error);
    });
  return {container: container};
}

var builders = {
  "inline-example": inlineExample,
  "code-example": codeExample,
  "function": functionBuilder,
  "file-upload": fileUpload,
  "code-assignment": codeAssignment,
  "multiple-choice": multipleChoice,
  "number-response": numberResponse,
  "free-response": freeResponse,
  "code-library": codeLibrary,
  "open-response": openResponse
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
    if (jnode.attr("data-parts")) {
      resources.steps = JSON.parse(jnode.attr("data-parts"));
    }
    function clean(node) {
      node
        .removeAttr("data-resources")
        .removeAttr("data-type")
        .removeAttr("data-args")
        .removeAttr("data-parts")
        .removeAttr("data-ct-node");
    }
    if (builders.hasOwnProperty(type)) {
      clean(jnode);
      var rv = builders[type](jnode, resources, args);
    } else {
      ct_error("Unknown builder type: ", type);
    }
  });
}
