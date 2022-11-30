defmodule Ezstanza.DeploymentProvider do #Provisioner/Service?
  @moduledoc ~S"""
  Defines a deployment behaviour
  """

  #TODO: Fields schema stuff should/could be broken out to separate module/behavior?

  @optional_callbacks changeset_alter: 1

  @form_field_types ~w(integer float decimal boolean string)a

  @form_field_options ~w(component required label help_text)a

  @form_field_required_options ~w(label)a

  @form_field_default_options [
    required: false
  ]

  #@form_field_type_default_component %{
  #  integer: :number,
  #  float: :number,
  #  decimal: :number,
  #  boolean: :checkbox,
  #  string: :text
  #}

  @form_field_type_components %{
    integer: [:number],
    float: [:number],
    decimal: [:number],
    string: [:text, :textarea],
    boolean: [:checkbox]
  }

  @type form_field_type :: :integer | :float | :decimal | :boolean | :string

  #@composite_types ~w(array) ??

  defmacro __using__(_) do
    quote do
      @behaviour Ezstanza.DeploymentProvider
      @derive Jason.Encoder

      import Ezstanza.DeploymentProvider, only: [form_schema: 1]
      Module.register_attribute(__MODULE__, :form_fields, accumulate: true)
    end
  end

  @spec form_field_type?(atom) :: boolean
  def form_field_type?(atom), do: atom in @form_field_types


  defmacro form_schema([do: block]) do
    prelude = quote do
      if line = Module.get_attribute(__MODULE__, :form_schema_defined) do
        raise "form schema already defined for #{inspect(__MODULE__)} on line #{line}"
      end
      @form_schema_defined unquote(__CALLER__.line)
      # try do / after :ok?
      import Ezstanza.DeploymentProvider, only: [form_field: 3]
      unquote(block)
    end

    postlude = quote unquote: false do

      form_fields = @form_fields |> Enum.reverse

      use Ecto.Schema # Put here or in __using__??

      embedded_schema do
        for {name, type, _opts} <- form_fields do
          field name, type
        end
      end

      frontend_form_schema = for {name, type, opts} <- form_fields, into: %{} do
        opts = Keyword.update!(opts, :component, fn
          {component, opts} ->
            %{
              is: component,
              options: Enum.into(opts, %{})
            }
          component ->
            %{
              is: component,
              options: %{}
            }
        end)
        {name, Enum.into(opts, %{})}
      end

      def frontend_form_schema(), do: unquote(Macro.escape(frontend_form_schema))

      fields = Enum.map(form_fields, &elem(&1, 0))
      required_fields = Enum.filter(form_fields, fn {_field, _type, opts} ->
        opts[:required]
      end)
      |> Enum.map(&elem(&1, 0))

      def changeset(struct, attrs) do
        struct
        |> Ecto.Changeset.cast(attrs, unquote(Macro.escape(fields)))
        |> Ecto.Changeset.validate_required(unquote(Macro.escape(required_fields)))
        |> then(fn changeset ->
          if function_exported?(__MODULE__, :changeset_alter, 1) do
            changeset_alter(changeset)
          else
            changeset
          end
        end)
      end
    end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  defmacro form_field(name, type \\ :string, opts \\ []) do
    # TODO: use bind_quoted instead?
    quote do
      Ezstanza.DeploymentProvider.__form_field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  def __form_field__(mod, name, type, opts) do
    cond do
      not is_atom(name) ->
        raise ArgumentError, "invalid name #{inspect name} for form field"
      not is_atom(type) ->
        raise ArgumentError, "invalid type #{inspect type} for form field #{inspect name}"
      not form_field_type?(type) ->
        raise ArgumentError, "unknown type #{inspect type} for form field #{inspect name}"
      true -> :ok
    end

    #valid_options = form_field_options(type, opts[:component])

    case Enum.find(opts, fn {k, _} -> not(k in @form_field_options) end) do
      {k, _} -> raise ArgumentError, "invalid form field option #{inspect k}"
      nil -> :ok
    end
    Enum.each(opts, fn
      {:component, component} ->
        check_component!(component, name, type)
        #if component not in Map.get(@form_field_type_components, type) do
        #  raise ArgumentError, "invalid component #{inspect component} for form field type #{inspect type}"
        #end
      {:required, required} when not is_boolean(required) ->
        raise ArgumentError, "invalid type for form_field option :required #{inspect required}"
      _ -> :ok
    end)

    opts = form_field_default_options(type)
           |> Keyword.merge(opts)

    Module.put_attribute(mod, :form_fields, {name, type, opts})
  end

  defp check_component!({component, opts}, field_name, field_type) do
    case component do
      :number ->
        Enum.each(opts, fn
          {:min_fraction_digits, value} when field_type in [:decimal, :float] ->
            if not is_integer(value) do
              raise ArgumentError,
                "invalid :min_faction_digits value #{inspect value} for component #{inspect component} in field #{inspect field_name}"
            end
          option ->
            raise ArgumentError, "invalid component option #{inspect option} for field #{inspect field_name}"
        end)
      _ ->
        raise ArgumentError, "options are not allowed for component #{inspect component}"
    end
    check_component!(component, field_name, field_type)
  end

  defp check_component!(component, field_name, field_type) do
    cond do
      not is_atom(component) ->
        raise ArgumentError, "invalid component #{inspect component} for field #{inspect field_name}"
      component not in Map.get(@form_field_type_components, field_type) ->
        raise ArgumentError, "unknown component #{inspect component} for field #{inspect field_name} with type #{inspect field_type}"
      true ->
        :ok
    end
  end

#  def __form_field__(mod, name, type, opts) do
#    quote do
#      cond do
#        not is_atom(unquote(name)) ->
#          raise ArgumentError, "invalid name #{inspect unquote(name)} for form field"
#        not is_atom(unquote(type)) ->
#          raise ArgumentError, "invalid type #{inspect unquote(type)} for form field #{inspect unquote(name)}"
#        not Ezstanza.DeploymentProvider.form_field_type?(unquote(type)) -> #Why does not import work?
#          raise ArgumentError, "unknown type #{inspect unquote(type)} for form field #{inspect unquote(name)}"
#        true -> :ok
#      end
#
#      case Enum.find(unquote(opts), fn {k, _} -> not(k in @form_field_options) end) do
#        {k, _} -> raise ArgumentError, "invalid form field option #{inspect k}"
#        nil -> :ok
#      end
#
#      Enum.each(unquote(opts), fn
#        {:component, component} ->
#          if component not in Map.get(@form_field_type_components, unquote(type)) do
#            raise ArgumentError, "invalid component #{inspect component} for form field type #{inspect unquote(type)}"
#          end
#        {:required, required} when not is_boolean(required) ->
#          raise ArgumentError, "invalid type for form_field option :required #{inspect required}"
#      end)
#
#      opts = form_field_default_options(unquote(type))
#        |> Keyword.merge(opts)
#
#      Module.put_attribute(mod, :fields, {name, type, opts})
#    end
#  end
  # TODO: component default options + validate options?

  defp form_field_default_options(type) when type in [:integer, :float, :decimal] do
    Keyword.merge(@form_field_default_options, [component: :text])
  end

  defp form_field_default_options(:string) do
    Keyword.merge(@form_field_default_options, [component: :number])
  end

  defp form_field_default_options(:boolean) do
    Keyword.merge(@form_field_default_options, [component: :checkbox])
  end


  #defp form_field_required_options(type) do
  #end


  @callback changeset_alter(Ecto.Changeset.t()) ::  Ecto.Changeset.t()

  def form_changeset() do

  end

  def form_json() do


  end

  def form_validate() do

  end
end
