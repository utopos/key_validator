defmodule KeyValidatorTest do
  use ExUnit.Case, async: true

  defmodule Post do
    defstruct author: nil
  end

  defmodule SimpleModule do
  end

  describe "for_struct/2 " do
    test "raise KeyError on non-existent key in the struct" do
      assert_raise KeyError, ~r/Key :non_existent_key not found in [\w\.]+/, fn ->
        defmodule Posts do
          import KeyValidator
          for_struct(Post, %{non_existent_key: 1})
        end
      end
    end

    test "raise ArgumentError when module is not a defstruct module" do
      assert_raise ArgumentError,
                   ~r/Argument is not a module that defines a struct./,
                   fn ->
                     defmodule Posts do
                       import KeyValidator
                       for_struct(SimpleModule, %{non_existent_key: 1})
                     end
                   end
    end

    test "raise ArgumentError when passed module is not a module" do
      assert_raise ArgumentError,
                   ~r/Argument is not a module that defines a struct./,
                   fn ->
                     defmodule Posts do
                       import KeyValidator
                       for_struct(SimpleModules, %{non_existent_key: 1})
                     end
                   end
    end

    test "raise ArgumentError when fields not a map or keyword literal" do
      assert_raise ArgumentError, ~r/Fields argument must be map or keyword literal./, fn ->
        defmodule Posts do
          import KeyValidator
          for_struct(Post, 123)
        end
      end

      assert_raise ArgumentError, ~r/Fields argument must be map or keyword literal./, fn ->
        defmodule Posts do
          import KeyValidator
          for_struct(Post, [2, 123])
        end
      end
    end

    test "successful validation " do
      require KeyValidator
      assert %{author: "Jakub"} == KeyValidator.for_struct(Post, %{author: "Jakub"})
      assert [author: "Jakub"] == KeyValidator.for_struct(Post, author: "Jakub")
      assert %{author: "Jakub"} == KeyValidator.for_struct(%Post{}, %{author: "Jakub"})
      assert [author: "Jakub"] == KeyValidator.for_struct(%Post{}, author: "Jakub")
    end
  end
end
