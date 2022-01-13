defmodule FieldValidatorTest do
  use ExUnit.Case, async: true

  defmodule Post do
    defstruct author: nil
  end

  defmodule SimpleModule do

  end

  doctest FieldValidator

  describe "for_struct/2 " do
    test "raise CompileError on non existent key in the struct" do
      assert_raise CompileError,
                   fn ->
                     defmodule Posts do
                       import FieldValidator
                       for_struct(Post, %{non_existent_key: 1})
                     end
                   end
    end

    test "raise CompileError when module is not a defstruct module" do
      assert_raise CompileError, ~r/Module [\w\.]+ is not a struct/, fn ->
        defmodule Posts do
          import FieldValidator
          for_struct(SimpleModule, %{non_existent_key: 1})
        end
      end
    end

    test "successful validation " do
      require FieldValidator
      FieldValidator.for_struct(Post, %{author: "Jakub"})
      FieldValidator.for_struct(%Post{}, %{author: "Jakub"})
      FieldValidator.for_struct(Post, author: "Jakub")
      FieldValidator.for_struct(%Post{}, author: "Jakub")
    end
  end
end
