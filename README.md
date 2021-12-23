# rails-relations-graph

A small script to parse the folders `controllers` and `models` of a Rails application and find the relations between them. It will then generate a [mermaid](https://mermaid-js.github.io/mermaid/#/) flow diagram to represent these relations.

You can see an exemple output of the folder `app` in [rails-relations-graph.md](rails-relations-graph.md).

## Controllers and Models

A `Controller` is defined as the child of the class `ApplicationController`. Example:
```rb
class MyControler < ApplicationController
...
end
```

A `Model` is defined as the child of the class `ApplicationRecord`. Example:
```rb
class MyModel < ApplicationRecord
...
end
```

## Relations
### `Controller` uses `Model`

When a `Controller` is using the method of a `Model`, this will create the relation:
```
Controller{Controller} -->|uses| Model[Model]
```
Example of a `Controller` using a `Model`:
```rb
class MyController < ApplicationController

def uses_model
  Model.all
end

end
```

### `Model` has other `Model`s

When a `Model` has an association with other `Model`, this will create the relation:
```
Model[Model] -->|has_<one/many>| Model[Model]
```

An association is defined with the keywords `has_one` or `has_many`.

Example of a `Model` having associations:
```rb
class MyModel < ApplicationRecord
  has_one :one_model
  has_many :many_models
end
```
Corresponding mermaid:
```
Model[Model] -->|has_one| OneModel[OneModel]
Model[Model] -->|has_many| ManyModel[ManyModel]
```

## Dependencies
  - [Parser](https://github.com/whitequark/parser)
