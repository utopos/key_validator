# Key Validator

Compile-time validation to assure all the map/keyword keys exist in the target struct. Use case: maps that will be merged with structs.

Exposes the `KeyValidator.for_struct/2` macro.

# Installation

The package can be installed by adding live_stream_async to your list of dependencies in mix.exs:

```elixir
def deps do
  [
    {:key_validator, "~> 0.1.0", runtime: false}
  ]
end
```

## Testing

Library ready for testing:

```bash
mix test
```

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


