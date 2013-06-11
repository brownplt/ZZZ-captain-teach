require 'spec_helper'

describe "Commands" do
  it "should explode if an invalid version/name pair is specified" do
    expect {Commands::interp_tag(-1, "summary", {})}.to(
     raise_error(Commands::InvalidCommand)
    )
  end
  describe "version 1" do
    describe "summary" do
      it "should result in an object with type 'description'" do
        Commands.interp_tag(1,"summary",
                   {tag: "summary", 
                    content: "Foo"})[:type].should(eq("description"))
      end
      it "should result in an object with content equal to content" do
        Commands.interp_tag(1,"summary",
                   {tag: "summary", 
                    content: "Foo"})[:content].should(eq("Foo"))
      end
    end
  end
end
