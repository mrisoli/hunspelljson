defmodule HunspellJson.DicParser do
  @moduledoc """
  parse .dic file to generate the dictionaryTable
  """

  alias HunspellJson.{RuleCodeParser, WordRuleParser}

  def parse(rule_set, data) do
    data
    |> String.replace(~r/^\t.*$/m, "") # Remove comments
    |> String.split("\n")
    |> Enum.drop(1)
    |> (&parse_words(rule_set, &1)).()
  end

  defp parse_words(rule_set, []), do: rule_set

  defp parse_words(rule_set, [line | data]) do
    rule_set
    |> handle_word(String.split(line, "/"))
    |> parse_words(data)
  end

  defp handle_word(rule_set, wordset) when length(wordset) == 1 do
    WordRuleParser.add_word(rule_set, List.first(wordset), [])
  end

  defp handle_word(rule_set, [word, rule_codes]) do
    rule_codes_array = RuleCodeParser.parse(rule_set[:flags], rule_codes)
    rule_set
    |> handle_needaffix(
      word, rule_codes_array, Map.has_key?(rule_set[:flags], "NEEDAFFIX")
    )
    |> WordRuleParser.parse_rule_codes(word, rule_codes_array)
  end

  defp handle_needaffix(rule_set, word, rule_codes_array, true) do
    WordRuleParser.add_word(rule_set, word, rule_codes_array)
  end

  defp handle_needaffix(rule_set, word, rule_codes_array, false) do
    affix_in_rule_codes_array(rule_set, word, rule_codes_array)
  end

  defp affix_in_rule_codes_array(rule_set, word, rule_codes_array) do
    if Enum.member?(rule_codes_array, rule_set[:flags]["NEEDAFFIX"]) do
      rule_set
    else
      WordRuleParser.add_word(rule_set, word, rule_codes_array)
    end
  end

end
