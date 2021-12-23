require 'set'
require 'parser/current'
require 'active_support/inflector'

def get_association(node)
  # send is of the form [_, _, is_an_association, [:sym, :classAssociatedPlural]]
  if (associations = [:has_many, :has_one]
  node.respond_to?(:type) &&
  node.type == :send &&
  associations.include?(node.to_sexp_array[2]))
    association = node.to_sexp_array[2]
    associated_class = node.to_sexp_array[3].last.to_s.singularize.capitalize.to_sym
    [association, associated_class]
  end
end

def get_child_class_name(node, parent)
  # class is of the form children = [[_, _, ClassName], [_, _, Parent], ...]
  if (node.respond_to?(:type) &&
  node.type == :class &&
  !node.children[1].nil? &&
  node.children[1].to_sexp_array.last == parent)
    node.children.first.to_sexp_array.last
  end
end

def get_model(node, models_name)
  # model is of the form [:send, [:const, nil, Model], ...]
  if (node.respond_to?(:type) &&
  node.type == :send &&
  node.to_sexp_array[1].kind_of?(Array) &&
  models_name.include?(node.to_sexp_array[1].last))
    node.to_sexp_array[1].last
  end
end

class ModelNode
  attr_reader :name

  def initialize
    @name = nil
    @associations = []
  end

  def traverse_ast_model(node)
    if (name = get_child_class_name(node, :ApplicationRecord))
        @name = name
    end
    if (association = get_association(node))
        @associations.append(association)
    end

    if node.respond_to?(:children)
      for child in node.children
        traverse_ast_model(child)
      end
    end
  end

  def to_mermaid_diagram
    mermaid_diagram = ""
    for model in @associations
      mermaid_diagram += "#{@name}[#{@name}] -->|#{model.first}| #{model.last}[#{model.last}]\n"
    end
    mermaid_diagram
  end

end

class ControllerNode

  def initialize
    @name = nil
    @models = Set.new
  end

  def traverse_ast_controller(node, controllers, models_name)
    if (model = get_model(node, models_name))
      @models.add(model)
    end
    if (name = get_child_class_name(node, :ApplicationController))
      @name = name
    end
    if node.respond_to?(:children)
      for child in node.children
        traverse_ast_controller(child, controllers, models_name)
      end
    end
  end

  def to_mermaid_diagram
    mermaid_diagram = ""
    for model in @models.to_a
      mermaid_diagram += "#{@name}{#{@name}} -->|uses| #{model.name}[#{model.name}]\n"
    end
    mermaid_diagram
  end

end

models = []
# Stores the name of the Models, to determine if a Model is used in a Controller Class
models_name = []
model_files = Dir["app/models/**/*.rb"]
for model_file in model_files
  file = File.open(model_file)
  node = Parser::CurrentRuby.parse(file.read)
  model = ModelNode.new()
  model.traverse_ast_model(node)
  models_name.append(model.name)
  models.append(model)
end

controllers = []
controller_files = Dir["app/controllers/**/*.rb"]
for controller_file in controller_files
  file = File.open(controller_file)
  root = Parser::CurrentRuby.parse(file.read)
  controller = ControllerNode.new()
  controller.traverse_ast_controller(root, controllers, models_name)
  controllers.append(controller)
end

mermaid_diagram = "```mermaid\ngraph LR\n"
for controller in controllers
  mermaid_diagram += controller.to_mermaid_diagram
end
for model in models
  mermaid_diagram += model.to_mermaid_diagram
end
mermaid_diagram += "```"

File.write("rails-relations-graph.md", mermaid_diagram)
