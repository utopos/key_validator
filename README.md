# FieldValidator

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

```elixir
    iex> require FieldValidator
    FieldValidator

    iex> import Post
    Post

    iex> FieldValidator.for_struct(Post, %{author: "Jakub"})
    %{author: "Jakub"}

    iex> FieldValidator.for_struct(Post, author: "Jakub")
    [author: "Jakub"]
```

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
<!-- 
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/field_validator>.
-->