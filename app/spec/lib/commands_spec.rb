require 'spec_helper'

describe "Commands" do
  it "should explode if an invalid version/name pair is specified" do
    expect {Commands::interp_tag(-1, {"tag" => "assignment"}, "")}.to(
     raise_error(Commands::InvalidTag)
    )
    expect {Commands::interp_tag(1, {"tag" => "fooINVALIDTAG"}, "")}.to(
     raise_error(Commands::InvalidTag)
    )
  end

  describe "version 1" do
    VERSION = 1

    describe "assignment" do
      it "should error if pieces isn't a list of tags" do
        expect {Commands::interp_tag(VERSION,
                                     {"tag" => "assignment",
                                     "name" => "My Assignment",
                                     "description" => "The greatest assignment",
                                     "instructions" => "Do it all!",
                                     "pieces" => "foo"},
                                     "")}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {"tag" => "assignment",
                                     "name" => "My Assignment",
                                     "description" => "The greatest assignment",
                                     "instructions" => "Do it all!",
                                     "pieces" => ["foo", "bar"]},
                                     "")}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {"tag" => "assignment",
                                     "name" => "My Assignment",
                                     "description" => "The greatest assignment",
                                     "instructions" => "Do it all!",
                                     "pieces" => [{a:"foo"}, {b:"bar"}]},
                                     "")}.to(
          raise_error(Commands::InvalidTag)
        )
        expect {Commands::interp_tag(VERSION,
                                     {"tag" => "assignment",
                                     "name" => "My Assignment",
                                     "description" => "The greatest assignment",
                                     "instructions" => "Do it all!",
                                     "pieces" => [{"tag" =>"fooINVALIDTAG"}]},
                                     "")}.to(
          raise_error(Commands::InvalidTag)
        )
      end

      it "should produce object with a resource attribute from path" do
        Commands::interp_tag(VERSION,
                             {"tag" => "assignment",
                             "name" => "",
                             "description" => "",
                             "instructions" => "",
                             "pieces" => [{"tag" => "test"}]},
                             "/path/to/assignment")["resource"].should(eq("rw:/path/to/assignment:1"))
      end

      
      it "it should produce an object with nested paths to pieces" do
        Commands::interp_tag(VERSION,
                             {"tag" => "assignment",
                             "name" => "",
                             "description" => "",
                             "instructions" => "",
                             "pieces" => [{"tag" => "test"}]},
                             "/path/to/assignment")["pieces"][0]["resource"].should(eq("r:/path/to/assignment/pieces/0:1"))
      end


      it "should produce an object with the same attributes" do
        name = "My Assignment"
        description = "The greatest assignment"
        instructions = "Do it all!"
        Commands::interp_tag(VERSION,
                             {"tag" => "assignment",
                             "name" => name,
                             "description" => description,
                             "instructions" => instructions,
                             "pieces" => []},
                             "").should(
            eq({"type" => "assignment",
               "name" => name,
               "description" => description,
               "instructions" => instructions,
               "pieces" => [],
               "resource" => "rw::1"}))
      end
    end

    describe "function" do
      before(:all) do
        @name = "My Function"
        @desc = "The greatest function"
        @inst = "Write the greatest function ever"
      end
      it "should pass name, description, and instructions on" do
      newtag = Commands::interp_tag(VERSION,
                             {"tag" => "function",
                               "name" => @name,
                               "description" => @desc,
                               "instructions" => @inst,
                               "header" => nil,
                               "check_block" => nil,
                               "definition" => nil},
                                      "")
        newtag["name"].should(eq(@name))
        newtag["description"].should(eq(@desc))
        newtag["instructions"].should(eq(@inst))
      end
      it "should interp header" do
        Commands::interp_tag(VERSION,
           {"tag" => "function",
            "name" => @name,
            "description" => @desc,
            "instructions" => @inst,
            "header" => {"tag" => "test"},
            "check_block" => nil,
            "definition" => nil}, "")["header"].should(
           eq({"type" => "test", "resource" => "r:/header:1"}))
      end
      it "should interp check_block" do
        Commands::interp_tag(VERSION,
           {"tag" => "function",
            "name" => @name,
            "description" => @desc,
            "instructions" => @inst,
            "header" => nil,
            "check_block" => {"tag" => "test"},
            "definition" => nil}, "")["check_block"].should(
           eq({"type" => "test", "resource" => "r:/check_block:1"}))
      end
      it "should interp definition" do
        Commands::interp_tag(VERSION,
           {"tag" => "function",
            "name" => @name,
            "description" => @desc,
            "instructions" => @inst,
            "header" => nil,
            "check_block" => nil,
            "definition" => {"tag" => "test"}}, "")["definition"].should(
           eq({"type" => "test", "resource" => "r:/definition:1"}))
      end
    end
    describe "header_given" do
      before(:all) do
        @fun_name = "bubble-sort"
        @inst = "Write the greatest sort ever"
        @args = [["lst","List<A>"]]
        @ret = "List<A>"
        @purpose = "Sort by bubbling"
      end
      it "should pass through all attributes and add editable" do
        Commands::interp_tag(VERSION,
           {"tag" => "header_given",
            "fun_name" => @fun_name,
            "instructions" => @inst,
            "arguments" => @args,
            "return" => @ret,
            "purpose" => @purpose}, "").should(
           eq({"type" => "header",
               "editable" => false,
               "fun_name" => @fun_name,
               "instructions" => @inst,
               "arguments" => @args,
               "return" => @ret,
               "purpose" => @purpose,
                "resource" => "r::1"
              }))
      end
    end
  end
end
