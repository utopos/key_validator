# FieldValidator

Validates at compile time conformity between given struct and fields keys.

- `struct` argument may be an atom (which defines defstruct) or a struct literal (%MyStruct{}).
- `fields` argument may be a `map` or `keyword` **literal**.

Validation is done at compile time by ensuring all the fields keys are found in the struct.

Returns `fields` when all the field keys are included in the `struct`.
Raises `KeyError` at compile-time a fields key is not found in `struct` keys.

## Examples

```elixir

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
```

## Extended example

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
    import FieldValidator

    def list_posts do
      Post
      |> select_merge([p], for_struct(Post, %{author: p.author_firstname <> " " <> p.author_lastname}))
      |> Repo.all()
    end
  end


  The following code will raise a Key Error with message: "Key :author_non_existent_key not found in Post"

  defmodule Posts do
    import FieldValidator

    def list_posts_error do
        Post
        |> select_merge([p], for_struct(Post, %{author_non_existent_key: "some value"}))
        |> Repo.all()
      end
    end
```
"""

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `field_validator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:field_validator, git: "https://github.com/utopos/field_validator"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/field_validator>.

