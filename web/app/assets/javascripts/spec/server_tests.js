describe("reviews interactions", function () {

  it("should work", function () {
    var resources = TESTDATA.resources;
    var args = TESTDATA.args;

    var editorContainer = $("<div>");
    var tabs = createTabPanel($("#review-editor"));
    tabs.addTab("Code", editorContainer, { cannotClose: true });

    lookupResource(resources.path, function(activityState) {
      var currentState = activityState.status;
      var names = args.parts;
      var steps = [];
      resources.steps.forEach(function(elt) {
        steps.push(elt.name);
      });
      var sharedOptions = {
        run: function() {},
        names: names,
        steps: steps,
        afterHandlers: {}
      };

      function review_fun(step) { return function(editor, resume) {
          editor.disableAll();
          lookupResource(step.do_reviews, function(reviewData) {
            var doneCount = 0;
            function incrementDone() {
              doneCount += 1;
              finishReview();
            }
            function finishReview() {
              if(doneCount === reviewData.length) {
                editor.enableAll();
                resume();
              }
            }
            finishReview(); // A first try if reviewData is empty
            reviewData.forEach(function(review) {
              lookupResource(review.save_review, function(existingReview) {
                  incrementDone();
                },
                function(/* notFound */) {
                  var reviewsTab = $("<div>");
                  var reviewTabHandle =
                    tabs.addTab("Reviews", reviewsTab, { cannotClose: true });

                  lookupResource(review.resource, function(otherActivityState) {
                    var editorContainer = $("<div>");
                    reviewsTab.append(editorContainer);
                    var cm = makeEditor(
                      $(editorContainer),
                      {
                        initial: "",
                        run: function() {}
                      }
                    );
                    var reviewEditorOptions = _.merge(sharedOptions, {
                      initial: otherActivityState.parts
                    });
                    var editor = createEditor(cm, args.codeDelimiters, reviewEditorOptions);
                    editor.disableAll();
                    writeReviews(reviewsTab, {
                        hasReviews: true,
                        noResubmit: true,
                        reviews: {
                            save: function(val, f) {
                              saveResource(review.save_review, val, function() {
                                  reviewTabHandle.close();
                                  incrementDone();
                                },
                                function(e) {
                                  // TODO(joe 31 July 2013): Just let them move on if this fails?
                                  ct_error("Saving review failed:", e);
                                });
                            },
                            lookup: function(f) { f(null); }
                          }
                      })
                });
              });
            });
          });
        };
      }


      var editorOptions = _.merge(sharedOptions, { initial: activityState.parts });

      resources.steps.forEach(function(step) {
        editorOptions.afterHandlers[step.name] = review_fun(step);
      });

      var editor = steppedEditor(
          editorContainer,
          args.codeDelimiters,
          editorOptions
        );

      if (currentState.reviewing) {
        review_fun(resources.steps[currentState.step]);
      }
      
    });
  });
  
});
