defmodule FieldValidator do
  @moduledoc """
  Macros for validating map structure.
  """

  @doc """
  Validates at compile-time conformity between given struct module and fields keys.

  - `module` : atom (which defines defstruct).
  - `fields` : map or keyword **literal**.


  Returns `fields` when all the keys in`fields are included in the struct.

  Raises:

  - `KeyError` when any key in the fields is not found in struct.
  - `ArgumentError` when
    + `fields` are not a map/keyword literal
    + `module` is not a module atom
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

  defmacro for_struct(module, fields) do
    try do

      defstruct_module =
        module
        |> Macro.expand(__CALLER__)
        |> validate_module()
        |> validate_struct_module()

        fields
        |> get_keywords()
        |> validate_keywords(defstruct_module)

      fields
    rescue
      e in KeyError -> reraise e, []
      e in ArgumentError -> reraise e, []
    end
  end

  ###################
  # PRIVATE HELPERS #
  ###################

  defp validate_module(module_atom) when is_atom(module_atom) do
    try do
      module_atom.__info__(:functions)
      module_atom
    rescue
      UndefinedFunctionError ->
        raise_not_module_argument_error()
    end
  end

  defp validate_module(_module_atom), do: raise_not_module_argument_error()


  defp get_keywords({:%{}, _metadata, keywords}), do: get_keywords(keywords)

  defp get_keywords(keywords) do
    case Keyword.keyword?(keywords) do
      true -> keywords
      false -> raise_keywords_argument_error(keywords)
    end
  end



  defp validate_struct_module(module) do
    is_struct_module? =
      module.__info__(:functions)
      |> Keyword.has_key?(:__struct__)

    case is_struct_module? do
      true -> module
      false -> raise_struct_argument_error(module)
    end
  end

  defp validate_keywords(keywords, module) do
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
    raise ArgumentError, message: "Fields argument must be map or key literal. Found: #{inspect(keywords)}"
  end

  defp raise_not_module_argument_error() do
    raise ArgumentError, message: "Argument must be a module"
  end

  defp raise_struct_argument_error(module) do
    raise ArgumentError, message: "Module #{module} is not a struct module"
  end
end
