# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  inputs: ["mix.exs", "config/*.exs"],
  line_length: 120,
  locals_without_parens: [
    # Ecto
    field: :*
  ]
]
