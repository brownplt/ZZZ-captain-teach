require 'spec_helper'

describe "Commands" do
  it "should explode if an invalid version/name pair is specified" do
    expect {Commands::interp_tag(-1, {tag: "assignment"})}.to(
     raise_error(Commands::InvalidCommand)
    )
    expect {Commands::interp_tag(1, {tag: "fooINVALIDTAG"})}.to(
     raise_error(Commands::InvalidCommand)
    )
  end
  describe "version 1" do
    VERSION = 1
    describe "assignment" do
      it "should error if it is missing name" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if name isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: false})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                      name: {}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing description" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: 1})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: [10,10]})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: true})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing instructions" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment"
                                     })}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if instructions is not a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: 10})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: ["blah"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: {string: "foo"}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing pieces" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if pieces isn't a list of tags" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: "foo"})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: ["foo", "bar"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: [{a:"foo"}, {b:"bar"}]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: [{tag:"fooINVALIDTAG"}]})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should produce an object with the same attributes" do
        name = "My Assignment"
        description = "The greatest assignment"
        instructions = "Do it all!"
        Commands::interp_tag(VERSION,
                             {tag: "assignment",
                             name: name,
                             description: description,
                             instructions: instructions,
                             pieces: []}).should(
            eq({type: "assignment",
               name: name,
               description: description,
               instructions: instructions,
               pieces: []}))
      end
    end

    describe "function" do

      it "should error if it is missing name" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if name isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: false})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                      name: {}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing description" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: 1})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: [10,10]})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: true})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing instructions" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function"
                                     })}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if instructions is not a string" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: 10})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: ["blah"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: {string: "foo"}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if header isn't present'" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: ""})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if header isn't nil or a tag" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: "foo"})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: true})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: [1]})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if checkblock isn't present'" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if checkblock isn't nil or a tag" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: 10})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: false})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: "checks!"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if definition isn't present'" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: nil})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if definition isn't nil or a tag" do
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: nil,
                                     definition: 10})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: nil,
                                     definition: false})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {tag: "function",
                                     name: "My Function",
                                     description: "The greatest function",
                                     instructions: "",
                                     header: nil,
                                     checkblock: nil,
                                     definition: []})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should pass name, description, and instructions on" do
        name = "My Function"
        desc = "The greatest function"
        inst = "Do something great."
        newtag = Commands::interp_tag(VERSION,
                             {tag: "function",
                               name: name,
                               description: desc,
                               instructions: inst,
                               header: nil,
                               checkblock: nil,
                               definition: nil})
        newtag[:name].should(eq(name))
        newtag[:description].should(eq(desc))
        newtag[:instructions].should(eq(inst))
      end
      it "should interp header" do
        Commands::interp_tag(VERSION,
           {tag: "function",
            name: "My Function",
            description: "The greatest function",
            instructions: "",
            header: {tag: "test"},
            checkblock: nil,
            definition: nil})[:header].should(
           eq({type: "test"}))
      end
      it "should interp checkblock" do
        Commands::interp_tag(VERSION,
           {tag: "function",
            name: "My Function",
            description: "The greatest function",
            instructions: "",
            header: nil,
            checkblock: {tag: "test"},
            definition: nil})[:checkblock].should(
           eq({type: "test"}))
      end
      it "should interp definition" do
        Commands::interp_tag(VERSION,
           {tag: "function",
            name: "My Function",
            description: "The greatest function",
            instructions: "",
            header: nil,
            checkblock: nil,
            definition:  {tag: "test"}})[:definition].should(
           eq({type: "test"}))
      end
    end
  end
end
