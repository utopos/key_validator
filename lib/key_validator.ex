defmodule KeyValidator do
  @moduledoc """
  Compile-time validation to assure all the map/keyword keys exist in the target struct.
  Use case: maps that will be merged with structs.

  Library proivdes compile-time check macro for key validity of map/keyword keys for merge with structs.

  Exposes the `KeyValidator.for_struct/2` macro.

  ## Use cases

  The macro targets the situations where working with map/keyword literals that will be later cast onto the known structs.

  Elixir and Ecto has built-in functions that perform the key validity check, but only at runtime:

  - `Kernel.struct!/2`
  - `Ecto.Query.API.merge/2`

  In certain situations, the conformity between map/keyword keys can be checked already at the compile-time. One example is when we have present map/keyword **literals** in our code that we know ahead that will be used for casting onto structs. Let's take a look at the following example:

  ```elixir
  defmodule User do
  defstruct name: "john"
  end

  # Following line is a runtime only check:

  Kernel.struct!(User, %{name: "Jakub"})
  #=> %User{name: "Jakub"}

  # Runtime error on key typo:

  Kernel.struct!(User, %{nam__e: "Jakub"})
  #=> ** (KeyError) key :nam__e not found
  ```

  The expression `Kernel.struct!(User, %{name: "Jakub"})` uses a map literal (`%{name: "Jakub"}`). Since the User struct module together with the map literal is defined at the compile time, we can leverage the power of compile-time macros to validate those. This is where `KeyValidator.for_struct/2` comes to help:

  ```elixir
  defmodule User do
  defstruct name: "john"
  end

  import KeyValidator

  # Succesfull validation. Returns the map:

  user_map = for_struct(User, %{name: "Jakub"})
  #=> %{name: "Jakub"}

  Kernel.struct!(User, user_map)
  #=> %User{name: "Jakub"}

  # Compile time error on "nam__e:" key typo

  user_map2 = for_struct(User, %{nam__e: "Jakub"})
  #=>** (KeyError) Key :name_e not found in User
  ```

  As we can see `for_struct/2` macro allows some category of errors to be caught at very early stage in the development workflow. No need to wait the code to crash at runtime if there's a opportunity to check the key conformity before that. This is not a silver bullet though: the macro cannot accept dynamic variables, because their content cannot be evaluated during compilation.

  ## Extended example

  Useful to work with Ecto.Query.select_merge/3 when working with `virtual_fields`

  ```elixir
  defmodule Post do
  use Ecto.Schema
  schema "posts" do
   field :author_firstname, :string
   field :author_lastname, :string
   field :author, :string, virtual_field: true
  end
  end

  defmodule Posts do
  import KeyValidator

  def list_posts do
   Post
   |> select_merge([p], for_struct(Post, %{author: p.author_firstname <> " " <> p.author_lastname}))
   |> Repo.all()
  end
  end
  ```

  The following code will raise a Key Error with message: "Key :author_non_existent_key not found in Post"

  ```elixir
  defmodule Posts do
  import KeyValidator

  def list_posts_error do
  Post
  |> select_merge([p], for_struct(Post, %{author_non_existent_key: "some value"}))
  |> Repo.all()
   end
  end
  ```


  """

  @doc """
    Validates all the map/keyword keys exist in the target struct at compile-time.

    Raises compile-time errors if key does not exist.

    - `module_or_struct` : Module atom (which defines defstruct) or struct (ex. %ModuleStruct{}).
    - `fields` : map or keyword **literal**.


    Returns `fields` when all the keys in`fields` are included in the target struct.

    Raises:

    - `KeyError` when any key in the fields is not found in struct.
    - `ArgumentError` when
      + `module` is not a module that defines struct
      + `fields` are not a map/keyword literal

    ## Examples


      iex> import KeyValidator
      iex> defmodule Post do
            defstruct [:author]
          end

      iex> for_struct(Post, %{author: "Jakub"})
      %{author: "Jakub"}

      iex> for_struct(%Post{}, %{author: "Jakub"})
      %{author: "Jakub"}

      iex> for_struct(Post, author: "Jakub")
      [author: "Jakub"]

      iex> for_struct(Post, %{auth_typo_or: "Jakub"})
      ** (KeyError) Key :auth_typo_or not found in Elixir.Post

      iex> for_struct(ModuleWithNoStruct, %{author: "Jakub"})
      ** (ArgumentError) Argument is not a module that defines a struct.

  """
  defmacro for_struct(module_or_struct, fields) do
    try do
      defstruct_module =
        module_or_struct
        |> Macro.expand(__CALLER__)
        |> assert_is_struct(__CALLER__)

      fields
      |> Macro.expand(__CALLER__)
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

  defp assert_keyword({:%{}, _metadata, keyword}), do: assert_keyword(keyword)

  defp assert_keyword(keyword) do
    case Keyword.keyword?(keyword) do
      true -> keyword
      false -> raise_keywords_argument_error(keyword)
    end
  end

  defp validate_keyword(keyword, module) do
    struct_keys = Map.keys(module.__struct__())

    keyword
    |> Enum.each(fn {key, _v} ->
      if key not in struct_keys,
        do: raise_keywords_key_error(key, module)
    end)
  end

  defp raise_keywords_key_error(key, module) do
    raise KeyError, message: "Key #{inspect(key)} not found in #{module}", key: key
  end

  defp raise_keywords_argument_error(_keywords) do
    raise ArgumentError,
      message: "Fields argument must be map or keyword literal."
  end

  defp raise_struct_argument_error(_term) do
    raise ArgumentError,
      message: "Argument is not a module that defines a struct."
  end
end
