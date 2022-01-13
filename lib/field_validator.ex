defmodule FieldValidator do
  @moduledoc """
  Macros for validating map structure.
  """

  @doc """
  Validates at copile time conformity between given struct and fields keys.

  - `struct` argument may be an atom (which defines defstruct) or a struct conustrctor (%MyStruct{}).
  - `fields` argument may be a `map` or `keyword` literal.

  Validation is done at compile time by ensuring that all the keys in the fields preexist in specified struct.

  Returns `fields` when all the map keys are also declared in the `struct`.
  Raises `CompilError` when any of the `map` keys is not included in the `struct` key.

  Designed to be used inside another macro like `Ecto.Query.select_merge`.

  ## Examples

     defmodule Post do
       defstruct author: nil
     end

    iex> require FieldValidator
    iex> import Post
    iex> FieldValidator.for_struct(Post, %{author: "Jakub"})
    %{author: "Jakub"}
    iex> FieldValidator.for_struct(%Post{}, %{author: "Jakub"})
    %{author: "Jakub"}
    iex> FieldValidator.for_struct(Post, author: "Jakub")
    [author: "Jakub"]
    iex> FieldValidator.for_struct(%Post{}, author: "Jakub")
    [author: "Jakub"]


  ## Extended example

      defmodule Post do
        use Ecto.Schema
        schema "posts do
          field :author_firstname, :string
          field :author_lastname, :string
          field :author, :string, virtual_field: true
        end
      end

      defmodule Posts do
        import FieldValidator

        def list_posts do
          Post
          |> select_merge([p], for_struct(Post, %{author: p.author_firstname <> " " <> p.author_lastname}))
          |> Repo.all()
        end
      end

    The following code will raise a CompileError with message: "Key ":author_non_existen_key" does not exist in struct Post"

      defmodule Posts do
        import FieldValidator

        def list_posts_error do
            Post
            |> select_merge([p], for_struct(Post, %{author_non_existen_key: p.author_firstname <> " " <> p.author_lastname}))
            |> Repo.all()
          end
        end

  """

  defmacro for_struct(struct, fields) do
    defstruct_module =
    struct
    |> define_defstruct_module()
    |> Macro.expand(__CALLER__)

    keywords =
      fields
      |> define_keywords()

     :ok = validate(defstruct_module, keywords, __CALLER__)
     fields
  end

  defp define_defstruct_module({:__aliases__, _, _} = module), do: module

  defp define_defstruct_module({:%, _, [{:__aliases__, _, _} = module, {:%{}, _, _}]}), do: module

  defp define_keywords({:%{}, _metadata, keywords}), do: keywords

  defp define_keywords(keywords) when is_list(keywords), do: keywords


  # Private helpers

  defp validate(module, keywords, env) do
    module
    |> validate__defstruct_module(env)
    |> validate_keywords(keywords,env)
  end

  defp validate__defstruct_module(module, env) do
    is_defstruct? =
      module.__info__(:functions)
      |> Keyword.has_key?(:__struct__)

    case is_defstruct? do
      true -> module
      false -> raise_compile_error("Module #{module} is not a struct", env)
    end
  end

  defp validate_keywords(module, keywords, env) do
    struct_keys = Map.keys(module.__struct__())

    keywords
    |> Enum.each(fn {key, _v} ->
      if key not in struct_keys,
        do: raise_compile_error("Key \"#{inspect(key)}\" does not exist in struct #{module}", env)
    end)

    :ok
  end

  defp raise_compile_error(descirption, env) do
    raise %CompileError{
      description: descirption,
      file: env.file,
      line: env.line
    }
  end
end
