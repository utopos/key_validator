# FieldValidator

Validates at copile time conformity between given struct and fields keys.

- `struct` argument may be an atom (which defines defstruct) or a struct conustrctor (%MyStruct{}).
- `fields` argument may be a `map` or `keyword` literal.

Validation is done at compile time by ensuring that all the keys in the fields preexist in specified struct.

Returns `fields` when all the map keys are also declared in the `struct`.
Raises `CompilError` when any of the `map` keys is not included in the `struct` key.

Designed to be used inside another macro like `Ecto.Query.select_merge`.

## Examples
```elixir
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
```

## Extended example
```elixir
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
```

  The following code will raise a CompileError with message: "Key ":author_non_existen_key" does not exist in struct Post"

```elixir
    defmodule Posts do
      import FieldValidator

      def list_posts_error do
          Post
          |> select_merge([p], for_struct(Post, %{author_non_existen_key: p.author_firstname <> " " <> p.author_lastname}))
          |> Repo.all()
        end
      end
```
## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `field_validator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:field_validator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/field_validator>.

