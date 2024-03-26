with {:module, Ecto.Query.API} <- Code.ensure_loaded(Ecto.Query.API) do
  defmodule Warder.Query do
    @moduledoc """
    `ecto` Query Helper Functions

    Postgres Functions and Operators:
    https://www.postgresql.org/docs/current/functions-range.html

    Usage: `require` or `import` `Warder.Query`

    ## Postgres Types

    Make sure that you cast the types to the correct Postgres type. This can be
    achieved by using `Ecto.Query.API.type/2` or if the type is not directly
    supported by ecto `fragment("?::type", value)`.
    """

    @doc """
    Does `first` contain `second`?

    Operator: `@>`

    ## Signatures

    * `anyrange @> anyrange → boolean`
    * `anyrange @> anyelement → boolean`
    * `anymultirange @> anymultirange → boolean`
    * `anymultirange @> anyrange → boolean`
    * `anymultirange @> anyelement → boolean`
    * `anyrange @> anymultirange → boolean`

    ## Examples

        where(q in query, where: contains?(q.range, 7))

    """
    defmacro contains?(first, second) do
      quote do
        fragment("? @> ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` contained in `second`?

    Operator: `<@`

    ## Signatures

    * `anyrange <@ anyrange → boolean`
    * `anyelement <@ anyrange → boolean`
    * `anymultirange <@ anymultirange → boolean`
    * `anymultirange <@ anyrange → boolean`
    * `anyrange <@ anymultirange → boolean`
    * `anyelement <@ anymultirange → boolean`

    ## Examples

        where(q in query, where: contained?(7, q.range))

    """
    defmacro contained?(first, second) do
      quote do
        fragment("? <@ ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Does `first` overlap `second`?

    Operator: `&&`

    ## Signatures

    * `anyrange && anyrange → boolean`
    * `anymultirange && anymultirange → boolean`
    * `anymultirange && anyrange → boolean`
    * `anyrange && anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: overlap?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro overlap?(first, second) do
      quote do
        fragment("? && ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` strictly left of `second`?

    Operator: `<<`

    ## Signatures

    * `anyrange << anyrange → boolean`
    * `anymultirange << anymultirange → boolean`
    * `anymultirange << anyrange → boolean`
    * `anyrange << anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: left?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro left?(first, second) do
      quote do
        fragment("? << ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` strictly right of `second`?

    Operator: `>>`

    ## Signatures

    * `anyrange >> anyrange → boolean`
    * `anymultirange >> anymultirange → boolean`
    * `anymultirange >> anyrange → boolean`
    * `anyrange >> anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: right?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro right?(first, second) do
      quote do
        fragment("? >> ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` not extend to the right of `second`?

    Operator: `&<`

    ## Signatures

    * `anyrange &< anyrange → boolean`
    * `anymultirange &< anymultirange → boolean`
    * `anymultirange &< anyrange → boolean`
    * `anyrange &< anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: no_extend_right?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro no_extend_right?(first, second) do
      quote do
        fragment("? &< ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` not extend to the left of `second`?

    Operator: `&>`

    ## Signatures

    * `anyrange &> anyrange → boolean`
    * `anymultirange &> anymultirange → boolean`
    * `anymultirange &> anyrange → boolean`
    * `anyrange &> anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: no_extend_left?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro no_extend_left?(first, second) do
      quote do
        fragment("? &> ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Is `first` adjacent to `second`?

    Operator: `-|-`

    ## Signatures

    * `anyrange -|- anyrange → boolean`
    * `anymultirange -|- anymultirange → boolean`
    * `anymultirange -|- anyrange → boolean`
    * `anyrange -|- anymultirange → boolean`

    ## Examples

        where(
          q in query,
          where: adjacent?(q.range, type(Warder.Range.new!(1, 7), q.range))
        )

    """
    defmacro adjacent?(first, second) do
      quote do
        fragment("? -|- ?", unquote(first), unquote(second))
      end
    end

    @doc """
    Create union of `first` and `second`.

    Operator: `+`

    ## Signatures

    * `anyrange + anyrange → anyrange`
    * `anymultirange + anymultirange → anymultirange`

    ## Examples

        where(
          q in query,
          select: type(union(q.range, ^Range.new!(10, 20)), q.range))
        )

    """
    defmacro union(first, second) do
      quote do
        unquote(first) + unquote(second)
      end
    end

    @doc """
    Create intersection of `first` and `second`.

    Operator: `*`

    ## Signatures

    * `anyrange * anyrange → anyrange`
    * `anymultirange * anymultirange → anymultirange`

    ## Examples

        where(
          q in query,
          select: type(intersection(q.range, ^Range.new!(10, 20)), q.range))
        )

    """
    defmacro intersection(first, second) do
      quote do
        unquote(first) * unquote(second)
      end
    end

    @doc """
    Create difference of `first` and `second`.

    Operator: `-`

    ## Signatures

    * `anyrange - anyrange → anyrange`
    * `anymultirange - anymultirange → anymultirange`

    ## Examples

        where(
          q in query,
          select: type(difference(q.range, ^Range.new!(10, 20)), q.range))
        )

    """
    defmacro difference(first, second) do
      quote do
        unquote(first) - unquote(second)
      end
    end

    @doc """
    Get lower bound of range or multirange.

    Function: `LOWER`

    ## Signatures

    * `lower ( anyrange ) → anyelement`
    * `lower ( anymultirange ) → anyelement`

    ## Examples

        where(
          q in query,
          select: lower(q.range)
        )

    """
    defmacro lower(subject) do
      quote do
        fragment("LOWER(?)", unquote(subject))
      end
    end

    @doc """
    Get upper bound of `subject`.

    Function: `UPPER`

    ## Signatures

    * `upper ( anyrange ) → anyelement`
    * `upper ( anymultirange ) → anyelement`

    ## Examples

        where(
          q in query,
          select: upper(q.range)
        )

    """
    defmacro upper(subject) do
      quote do
        fragment("UPPER(?)", unquote(subject))
      end
    end

    @doc """
    Check if `subject` is empty.

    Function: `ISEMPTY`

    ## Signatures

    * `isempty ( anyrange ) → boolean`
    * `isempty ( anymultirange ) → boolean`

    ## Examples

        where(
          q in query,
          select: is_empty?(q.range)
        )

    """
    defmacro empty?(subject) do
      quote do
        fragment("ISEMPTY(?)", unquote(subject))
      end
    end

    @doc """
    Check if lower of `subject` is inclusive.

    Function: `LOWER_INC`

    ## Signatures

    * `lower_inc ( anyrange ) → boolean`
    * `lower_inc ( anymultirange ) → boolean`

    ## Examples

        where(
          q in query,
          select: is_lower_inclusive?(q.range)
        )

    """
    defmacro lower_inclusive?(subject) do
      quote do
        fragment("LOWER_INC(?)", unquote(subject))
      end
    end

    @doc """
    Check if upper of `subject` is inclusive.

    Function: `UPPER_INC`

    ## Signatures

    * `upper_inc ( anyrange ) → boolean`
    * `upper_inc ( anymultirange ) → boolean`

    ## Examples

        where(
          q in query,
          select: is_upper_inclusive?(q.range)
        )

    """
    defmacro upper_inclusive?(subject) do
      quote do
        fragment("UPPER_INC(?)", unquote(subject))
      end
    end

    @doc """
    Check if lower of `subject` is infinite.

    Function: `LOWER_INF`

    ## Signatures

    * `lower_inf ( anyrange ) → boolean`
    * `lower_inf ( anymultirange ) → boolean`

    ## Examples

        where(
          q in query,
          select: is_lower_infinite?(q.range)
        )

    """
    defmacro lower_infinite?(subject) do
      quote do
        fragment("LOWER_INF(?)", unquote(subject))
      end
    end

    @doc """
    Check if upper of `subject` is infinite.

    Function: `UPPER_INF`

    ## Signatures

    * `upper_inf ( anyrange ) → boolean`
    * `upper_inf ( anymultirange ) → boolean`

    ## Examples

        where(
          q in query,
          select: is_upper_infinite?(q.range)
        )

    """
    defmacro upper_infinite?(subject) do
      quote do
        fragment("UPPER_INF(?)", unquote(subject))
      end
    end

    @doc """
    Merge two ranges.

    Function: `RANGE_MERGE`

    ## Signatures

    * `range_merge ( anyrange, anyrange ) → anyrange`

    ## Examples

        where(
          q in query,
          select: merge_ranges(q.range, q.range)
        )

    """
    defmacro merge_ranges(first, second) do
      quote do
        fragment("RANGE_MERGE(?, ?)", unquote(first), unquote(second))
      end
    end

    @doc """
    Merge multirange into range.

    Function: `RANGE_MERGE`

    ## Signatures

    * `range_merge ( anymultirange ) → anyrange`

    ## Examples

        where(
          q in query,
          select: merge_multirange(q.multirange)
        )

    """
    defmacro merge_multirange(subject) do
      quote do
        fragment("RANGE_MERGE(?)", unquote(subject))
      end
    end

    @doc """
    Create multirange from range.

    Function: `MULTIRANGE`

    ## Signatures

    * `multirange ( anyrange ) → anymultirange`

    ## Examples

        where(
          q in query,
          select: multirange(q.range)
        )

    """
    defmacro multirange(subject) do
      quote do
        fragment("MULTIRANGE(?)", unquote(subject))
      end
    end

    @doc """
    Unnest ranges from multirange.

    Function: `UNNEST`

    ## Signatures

    * `unnest ( anymultirange ) → setof anyrange`

    ## Examples

        where(
          q in query,
          cross_join: r in unnest(q.multirange),
          select: r
        )

    """
    defmacro unnest(subject) do
      quote do
        fragment("UNNEST(?)", unquote(subject))
      end
    end
  end
end
