defmodule Shrink.HtmlHelpers do
  @moduledoc """
  `Access`-compatible getters for asserting on HTML documents' structure and
  contents using `EasyHTML`.

  Extracted from my own personal project, so not synthesized specifically for
  this code assessment.
  """

  @type html :: %EasyHTML{}

  @doc "Fan out to HTML children nodes, equivalent to `Access.all/0`"
  @spec html_all :: Access.get_fun(html)
  def html_all do
    fn :get, %EasyHTML{nodes: nodes} = _subject, next ->
      nodes
      |> Enum.map(&struct(EasyHTML, nodes: [&1]))
      |> Enum.map(next)
    end
  end

  @doc "Extract a specific element attribute by name, such as `href` or `class` or `value`"
  @spec html_attribute(String.t()) :: Access.get_fun(html)
  def html_attribute(attribute) do
    fn :get, %EasyHTML{nodes: nodes} = _subject, next ->
      next.(Floki.attribute(nodes, attribute))
    end
  end

  @doc "Limit the children to the elements given as `range`, equivalent to `Access.slice/1`"
  @spec html_children_slice(Range.t()) :: Access.get_fun(html)
  def html_children_slice(range) do
    fn :get, %EasyHTML{nodes: nodes} = _subject, next ->
      next.(%EasyHTML{nodes: Enum.slice(nodes, range)})
    end
  end

  @doc "Apply `to_string` and `String.trim/1` to each direct HTML child"
  @spec html_trimmed_text :: Access.get_fun(html)
  def html_trimmed_text do
    fn :get, %EasyHTML{} = subject, next ->
      subject
      |> EasyHTML.to_string()
      |> String.trim()
      |> then(next)
    end
  end
end
