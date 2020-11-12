# Used by "mix format"
[
  inputs: ["mix.exs", "config/*.exs"],
  subdirectories: ["apps/*"],
  line_length: 120,
  locals_without_parens: [
    # Plug
    plug: :*,
    forward: :*,
    get: :*,
    post: :*
  ]
]
