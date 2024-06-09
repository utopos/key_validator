defmodule FieldValidator do
  @moduledoc """
  Macros for validating map structure.
  """

  @doc """
    Validates at compile-time conformity between given struct module and fields keys.

    - `module_or_struct` : Module atom (which defines defstruct) or struct (ex. %ModuleStruct{}).
    - `fields` : map or keyword **literal**.


    Returns `fields` when all the keys in`fields are included in the struct.

    Raises:

    - `KeyError` when any key in the fields is not found in struct.
    - `ArgumentError` when
      + `fields` are not a map/keyword literal
      + `module` is not a module atom that defines defstruct

    ## Examples


      iex> require FieldValidator
      FieldValidator

      iex> import Post
      Post

      iex> FieldValidator.for_struct(Post, %{author: "Jakub"})
      %{author: "Jakub"}

      iex> FieldValidator.for_struct(Post, author: "Jakub")
      [author: "Jakub"]

  """
  defmacro for_struct(module_or_struct, fields) do
    try do
      defstruct_module =
        module_or_struct
        |> Macro.expand(__CALLER__)
        |> assert_is_struct(__CALLER__)

      fields
      |> assert_keyword()
      |> validate_keyword(defstruct_module)

      fields
    rescue
      e in KeyError -> reraise e, []
      e in ArgumentError -> reraise e, []
    end
  end

  ###################
  # PRIVATE HELPERS #
  ###################

  defp assert_is_struct({:%, _, [module, _fields]}, env) do
    module_atom = Macro.expand(module, env)
    assert_is_struct(module_atom, env)
  end

  defp assert_is_struct(module_atom, _env) when is_atom(module_atom) do
    case function_exported?(module_atom, :__struct__, 0) do
      true -> module_atom
      false -> raise_struct_argument_error(module_atom)
    end
  end

  defp assert_is_struct(term, _env) do
    raise_struct_argument_error(term)
  end

  defp assert_keyword({:%{}, _metadata, keywords}), do: assert_keyword(keywords)

  defp assert_keyword(keywords) do
    case Keyword.keyword?(keywords) do
      true -> keywords
      false -> raise_keywords_argument_error(keywords)
    end
  end

  defp validate_keyword(keywords, module) do
    struct_keys = Map.keys(module.__struct__())

    keywords
    |> Enum.each(fn {key, _v} ->
      if key not in struct_keys,
        do: raise_keywords_key_error(key, module)
    end)
  end

  defp raise_keywords_key_error(key, module) do
    raise KeyError, message: "Key #{inspect(key)} not found in #{module}", key: key
  end

  defp raise_keywords_argument_error(keywords) do
    raise ArgumentError,
      message: "Fields argument must be map or key literal. Found: #{inspect(keywords)}"
  end

  defp raise_struct_argument_error(term) do
    raise ArgumentError,
      message:
        "Argument is not a module does that defines a struct. Instead found: #{Macro.escape(term)}"
  end
end
