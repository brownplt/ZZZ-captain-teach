"use strict";

var Encounter = Backbone.Model.extend({
  render: function (container) {
    throw "trying to render encounter without render function";
  },

  save: function () {
    throw "trying to save encounter without save function";
  },

  getResults: function () {
    return {};
  },

  isComplete: function () {
    throw "trying to call is_complete encounter without is_complete function";
  },

  getThumbnail: function () {
    throw "trying to call get_thumbnail encounter without that function";
  }
});

// code, instructions
var ReplEncounter = Encounter.extend({
  render: function (container) {
    var instructions = jQuery("<div>");
    instructions.html(this.instructions);
    
    var replContainer = jQuery("<div>");
    var codeContainer = jQuery("<div>");
    container.append(codeContainer);
    container.append(replContainer);

    var runFun = makeRepl(replContainer);
    this.editor = makeEditor(codeContainer,
                             { initial: this.code,
                               run: runFun });
  },

  save: function () {
    this.code = this.editor.getValue();
    // NOTE(dbp): we need to rig up persistence for this to work.
    // Backbone.Model.prototype.save.apply(this);
  },

  getResults: function () {

  }
});


var StepSpec = Backbone.Model.extend({ });
/*
  constructed with:
  {
    instructions: DOM,
    initialCode: PyretString,
    reviewed: Bool,
  }
*/

var StepData = Backbone.Model.extend({ });
/*
  constructed with:
  {
    encounter: Encounter U undefined,
    reviews: 
  }
*/


var DATA = 'data', EXAMPLES = 'examples', TEMPLATE = 'template',
    HEADER = 'header', CHECK = 'check', FUNCTION = 'function';
var STAGES = [DATA, EXAMPLES, TEMPLATE, HEADER, CHECK, FUNCTION];
var DesignRecipeEncounter = Encounter.extend({
/*
  constructed with:
  {
    name: String,
    instructions: DOM,
    specStages: { [data, examples, template, header, check, function] : StepSpec },
    userStages: { [data, examples, template, header, check, function] : StepData }
  }
  also has:
  {
    state: STAGES
  }
*/
  initialize: function() {
    this.validate();
    this.state = DATA;
  },

  validate: function () {
    _.keys(this.encounters).intersection(STAGES).length === STAGES.length;
  },

  render: function (container) {
    
  }
  
});

