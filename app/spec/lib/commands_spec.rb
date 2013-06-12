require 'spec_helper'

describe "Commands" do
  it "should explode if an invalid version/name pair is specified" do
    expect {Commands::interp_tag(-1, "assignment", {})}.to(
     raise_error(Commands::InvalidCommand)
    )
    expect {Commands::interp_tag(1, "fooINVALIDTAG", {})}.to(
     raise_error(Commands::InvalidCommand)
    )
  end
  describe "version 1" do
    VERSION = 1
    describe "assignment" do
      it "should error if it is missing tag" do
        expect {Commands::interp_tag(VERSION, "assignment", {})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if tag isn't the string 'assignment'" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: ["assignment"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "foo"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing name" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if name isn't a string" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: false})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                      name: {}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing description" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: 1})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: [10,10]})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if description isn't a string" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: true})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing instructions" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment"
                                     })}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if instructions is not a string" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: 10})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: ["blah"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: {string: "foo"}})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if it is missing pieces" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!"})}.to(
          raise_error(Commands::InvalidTag)
        )
      end
      it "should error if pieces isn't a list of tags" do
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: "foo"})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: ["foo", "bar"]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
                                     {tag: "assignment",
                                     name: "My Assignment",
                                     description: "The greatest assignment",
                                     instructions: "Do it all!",
                                     pieces: [{a:"foo"}, {b:"bar"}]})}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION, "assignment",
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
        Commands::interp_tag(VERSION, "assignment",
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
  end
end
