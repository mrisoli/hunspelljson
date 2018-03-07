defmodule HunspellJson.AffParser do
  @moduledoc """
  Parses the aff file and returns a rule set
  """

  alias HunspellJson.AffixRuleParser

  def parse(aff_contents) do
    aff_contents
    |> remove_affix_comments
    |> String.split("\n")
    |> AffixRuleParser.parse
  end

  defp remove_affix_comments(data) do
    data
    |> String.replace(~r/#.*$/m, "") # Remove comments
    |> String.replace(~r/^\s\s*/m, "")
    |> String.replace(~r/\s\s*$/m, "") # Trim each line
    |> String.replace(~r/\n{2,}/, "\n") # Remove blank lines.
    |> String.replace(~r/^\s\s*/, "")
    |> String.replace(~r/\s\s*$/, "") # Trim the entire string
  end
end
