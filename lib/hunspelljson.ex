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
    |> clean_compound_rule_codes
    |> build_compound_rules
    |> Map.take([:compoundRules, :dictionaryTable, :flags, :replacementTable])
    |> Poison.encode!
    |> (&File.write("output.json", &1)).()
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

  defp clean_compound_rule_codes(rule_set) do
    rule_set[:compoundRuleCodes]
    |> Map.to_list
    |> Enum.filter(fn {_, value} -> length(value) > 0 end)
    |> Enum.map(fn {key, _} -> key end)
    |> (&Map.take(rule_set[:compoundRuleCodes], &1)).()
    |> (&put_in(rule_set[:compoundRuleCodes], &1)).()
  end

  defp build_compound_rules(rule_set) do
    compound_rules = build_compound_rules(
      [], rule_set[:compoundRules], rule_set
    )
    put_in(rule_set[:compoundRules], compound_rules)
  end

  defp build_compound_rules(rules, [], _rule_set), do: rules

  defp build_compound_rules(rules, [rule_text | compound_rules], rule_set) do
    expression_text = get_expression_text(
      "",
      String.graphemes(rule_text),
      rule_set
    )
    build_compound_rules(
      rules ++ [expression_text],
      compound_rules,
      rule_set
    )
  end

  defp get_expression_text(text, [], _rule_set) do
    {:ok, regex} = Regex.compile(text, "i")
    regex
    |> inspect
    |> (&String.slice(&1, 2..String.length(&1))).()
  end

  defp get_expression_text(text, [char | rule_text], rule_set) do
    updated_text = case rule_set[:compoundRuleCodes][char] do
      nil -> text <> char
      c_rule_code -> text <> "(" <> Enum.join(c_rule_code, "|") <> ")"
    end
    get_expression_text(updated_text, rule_text, rule_set)
  end
end
