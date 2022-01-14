defmodule FieldValidator do
  @moduledoc """
  Macros for validating map structure.
  """

  @doc """
  Validates at compile time conformity between given struct and fields keys.

  - `struct` argument may be an atom (which defines defstruct) or a struct literal (%MyStruct{}).
  - `fields` argument may be a `map` or `keyword` **literal**.

  Validation is done at compile time by ensuring all the fields keys are found in the struct.

  Returns `fields` when all the field keys are included in the `struct`.

  Raises `KeyError` at compile-time a fields key is not found in `struct` keys.

  ## Examples


    iex> require FieldValidator
    FieldValidator

    iex> import Post
    Post

    iex> FieldValidator.for_struct(Post, %{author: "Jakub"})
    %{author: "Jakub"}

    iex> FieldValidator.for_struct(%Post{}, %{author: "Jakub"})
    %{author: "Jakub"}

    iex> FieldValidator.for_struct(Post, author: "Jakub")
    [author: "Jakub"]

    iex> FieldValidator.for_struct(%Post{}, author: "Jakub")
    [author: "Jakub"]
"""

  defmacro for_struct(struct, fields) do
    try do
      defstruct_module =
        struct
        |> get_struct_ast()
        |> get_module(__CALLER__)
        |> validate_struct_module()

        fields
        |> get_keywords()
        |> validate_keywords(defstruct_module)

      fields
    rescue
      e in KeyError -> reraise e, []
    end
  end

  # Private helpers

  defp get_struct_ast({:__aliases__, _, _} = module), do: module

  defp get_struct_ast({:%, _, [{:__aliases__, _, _} = module, {:%{}, _, _}]}), do: module

  defp get_module(module_ast, caller), do: Macro.expand(module_ast, caller)

  defp get_keywords({:%{}, _metadata, keywords}), do: keywords

  defp get_keywords(keywords) when is_list(keywords), do: keywords


  defp validate_struct_module(module) do
    is_struct_module? =
      module.__info__(:functions)
      |> Keyword.has_key?(:__struct__)

    case is_struct_module? do
      true -> module
      false -> raise_key_error("Module #{module} is not a struct module", nil)
    end
  end

  defp validate_keywords(keywords, module) do
    struct_keys = Map.keys(module.__struct__())

    keywords
    |> Enum.each(fn {key, _v} ->
      if key not in struct_keys,
        do: raise_key_error("Key #{inspect(key)} not found in #{module}", key)
    end)

    :ok
  end

  defp raise_key_error(message, key) do
    raise KeyError, message: message, key: key
  end
end
