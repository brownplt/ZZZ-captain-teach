"use strict";

var Encounter = Backbone.Model.extend({
    render: function (container) {
        throw "trying to render encounter without render function";
    },

    save: function () {
        throw "trying to save encounter without save function";
    },

    get_results: function () {
        return {};
    },

    is_complete: function () {
        throw "trying to call is_complete encounter without is_complete function";
    },

    get_thumbnail: function () {
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
        ReplEncounter.save.apply(this);
    },

    get_results: function () {

    }
});
