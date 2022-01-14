defmodule FieldValidatorTest do
  use ExUnit.Case, async: true

  defmodule Post do
    defstruct author: nil
  end

  defmodule SimpleModule do

  end

  doctest FieldValidator

  describe "for_struct/2 " do
    test "raise KeyError on non-existent key in the struct" do
      assert_raise KeyError, ~r/Key :non_existent_key not found in [\w\.]+/,
                   fn ->
                     defmodule Posts do
                       import FieldValidator
                       for_struct(Post, %{non_existent_key: 1})
                     end
                   end
    end

    test "raise KeyError when module is not a defstruct module" do
      assert_raise KeyError, ~r/Module [\w\.]+ is not a struct module/, fn ->
        defmodule Posts do
          import FieldValidator
          for_struct(SimpleModule, %{non_existent_key: 1})
        end
      end
    end

    test "successful validation " do
      require FieldValidator
      assert %{author: "Jakub"} == FieldValidator.for_struct(Post, %{author: "Jakub"})
      assert %{author: "Jakub"} == FieldValidator.for_struct(%Post{}, %{author: "Jakub"})
      assert [author: "Jakub"] == FieldValidator.for_struct(Post, author: "Jakub")
      assert [author: "Jakub"] == FieldValidator.for_struct(%Post{}, author: "Jakub")
    end
  end
end
