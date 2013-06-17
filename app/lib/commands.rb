module Commands

  class InvalidCommand < Exception
  end
  class InvalidTag < Exception
    attr :tag, :msg
    def initialize(tag, msg)
      super("#{msg}: #{tag}")
      @tag = tag
      @msg = msg
    end
  end

  module Helpers
    String_checker = lambda {|field| field.is_a?(String) }
    Array_checker = lambda {|field| field.is_a?(Array) }
    Hash_nil_checker = lambda {|field| field.nil? or field.is_a?(Hash)}

    def tag_assert(tag, name, type)
      if !tag.is_a?(Hash)
        raise InvalidTag.new(tag, "Tag is not a hash")
      end
      if !tag.has_key?(name)
        raise InvalidTag.new(tag, "Tag does not have key '#{name}'")
      end

      case type
      when :string
        pred = String_checker
      when :hash_nil
        pred = Hash_nil_checker
      when :array
        pred = Array_checker
      end

      if !pred.call(tag[name])
        raise InvalidTag.new(tag, "Tag attribute '#{name}' is not a '#{type.to_s}'")
      end
    end
    module_function :tag_assert

  end

  def interp_tag(version, tag)
    Helpers.tag_assert(tag, "tag", :string)
    name = tag["tag"]
    pair = [version,name]
    if @versions.has_key?(version) and
       @versions[version].respond_to?(name)
      @versions[version].send(name, tag)
    else
      raise InvalidCommand, tag
    end
  end
  module_function :interp_tag

  class Version1
    # NOTE(dbp): this just used so that we can test nested constructs
    def test(tag)
      {"type" => "test"}
    end
    def assignment(tag)
      Helpers.tag_assert(tag, "name", :string)
      Helpers.tag_assert(tag, "description", :string)
      Helpers.tag_assert(tag, "instructions", :string)
      Helpers.tag_assert(tag, "pieces", :array)

      pieces = tag["pieces"].collect {|t|
        begin
          Commands::interp_tag(1, t)
        rescue InvalidCommand
          # an invalid command on a nested tag means this is
          # an invalid tag
          raise InvalidTag.new(tag, "Nested tag is invalid: #{t}")
        end
      }

      { "type" => "assignment",
        "name" => tag["name"],
        "description" => tag["description"],
        "instructions" => tag["instructions"],
        "pieces" => pieces }
    end
    
    def function(tag)
      Helpers.tag_assert(tag,"name", :string)
      Helpers.tag_assert(tag,"description", :string)
      Helpers.tag_assert(tag,"instructions", :string)
      Helpers.tag_assert(tag,"header", :hash_nil)
      Helpers.tag_assert(tag,"check_block", :hash_nil)
      Helpers.tag_assert(tag,"definition", :hash_nil)
      
      header = tag["header"].nil? ? nil : 
        Commands::interp_tag(1, tag["header"])
      checkblock = tag["check_block"].nil? ? nil : 
        Commands::interp_tag(1, tag["check_block"])
      definition = tag["definition"].nil? ? nil : 
        Commands::interp_tag(1, tag["definition"])
      
      { "type" => "function",
        "name" => tag["name"],
        "description" => tag["description"],
        "instructions" => tag["instructions"],
        "header" => header,
        "check_block" => checkblock,
        "definition" => definition
        }
    end

    def header_given(tag)
      Helpers.tag_assert(tag, "fun_name", :string)
      Helpers.tag_assert(tag, "instructions", :string)
      # NOTE(dbp): only checking one level deep in arguments for now
      Helpers.tag_assert(tag, "arguments", :array)
      Helpers.tag_assert(tag, "return", :string)
      Helpers.tag_assert(tag, "purpose", :string)

      { "type" => "header",
        "editable" => false,
        "fun_name" => tag["fun_name"],
        "instructions" => tag["instructions"],
        # NOTE(dbp): not checking arguments, just passing through.
        "arguments" => tag["arguments"],
        "return" => tag["return"],
        "purpose" => tag["purpose"] }
    end

    def check_block(tag)
      tag
    end

    def definition(tag)
      tag
    end
  end

  # commands is a mapping from [VERSION, "TAGNAME"] to a function
  # that interprets the content of the specified tag.
  @versions = {1 => Version1.new()}

end
