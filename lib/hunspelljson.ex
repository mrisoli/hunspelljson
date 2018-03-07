defmodule HunspellJson do
  @moduledoc """
  Generate a json file from a hunspell affix and dictionary file
  """

  alias HunspellJson.{AffParser, DicParser}

  @doc """
  parse generates the json from the affix and dictionary contents
  """
  def parse(aff_contents, dic_contents) do
    aff_contents
    |> AffParser.parse
    |> set_compound_rule_codes
    |> only_in_compound_flag
    |> DicParser.parse(dic_contents)
    # |> Poison.encode!
    # |> (&File.write("output.json", &1)).()
  end

  defp set_compound_rule_codes(rule_set) do
    Map.put(
      rule_set,
      :compoundRuleCodes,
      set_codes_for_compound_rule(rule_set[:compoundRules])
    )
  end

  defp set_codes_for_compound_rule(compound_rules) do
    compound_rules
    |> Enum.join("")
    |> String.graphemes
    |> Map.new(fn x -> {x, []} end)
  end

  defp only_in_compound_flag(rule_set) do
    compound_rule_codes = rule_set[:compoundRuleCodes]
    rule_set[:flags]
    |> Map.keys
    |> Enum.member?("ONLYINCOMPOUND")
    |> if(do: Map.put(compound_rule_codes, "ONLYINCOMPOUND", []), else: compound_rule_codes)
    |> (&put_in(rule_set[:compoundRuleCodes], &1)).()
  end
end
