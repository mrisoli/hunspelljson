defmodule HunspellJson.DicParser do
  @moduledoc """
  parse .dic file to generate the dictionaryTable
  """

  alias HunspellJson.{RuleApplier, RuleCodeParser}

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
    add_word(rule_set, List.first(wordset), [])
  end

  defp handle_word(rule_set, [word, rule_codes]) do
    rule_codes_array = RuleCodeParser.parse(rule_set[:flags], rule_codes)
    rule_set
    |> handle_needaffix(word, rule_codes_array, Map.has_key?(rule_set[:flags], "NEEDAFFIX"))
    |> parse_rule_codes(word, rule_codes_array)
  end

  defp add_word(rule_set, word, rules) do
    if Map.has_key?(rule_set[:dictionaryTable], word) do
      put_in(
        rule_set[:dictionaryTable][word],
        rule_set[:dictionaryTable][word] ++ rules
      )
    else
      put_in(rule_set[:dictionaryTable][word], rules)
    end
  end


  defp handle_needaffix(rule_set, word, rule_codes_array, true) do
    add_word(rule_set, word, rule_codes_array)
  end

  defp handle_needaffix(rule_set, word, rule_codes_array, false) do
    affix_in_rule_codes_array(rule_set, word, rule_codes_array)
  end

  defp affix_in_rule_codes_array(rule_set, word, rule_codes_array) do
    if Enum.member?(rule_codes_array, rule_set[:flags]["NEEDAFFIX"]) do
      add_word(rule_set, word, rule_codes_array)
    else
      rule_set
    end
  end

  defp parse_rule_codes(rule_set, _word, []), do: rule_set

  defp parse_rule_codes(rule_set, word, [code | rule_codes_array]) do
    rule_set
    |> parse_rule(word, rule_set[:rules][code], rule_codes_array)
    |> add_code(word, code)
    |> parse_rule_codes(word, rule_codes_array)
  end

  defp parse_rule(rule_set, _word, nil, rule_codes_array), do: rule_set

  defp parse_rule(rule_set, word, rule, rule_codes_array) do
    rule_set
    |> RuleApplier.apply_rule_entries(word, rule)
    |> (&add_new_words(rule_set, rule_codes_array, &1, word, rule)).()
  end

  defp add_code(rule_set, word, code) do
    case rule_set[:compoundRuleCodes][code] do
      nil -> rule_set
      _ -> put_in(
        rule_set[:compoundRuleCodes][code],
        rule_set[:compoundRuleCodes][code] ++ [word]
      )
    end
  end

  defp add_new_words(rule_set, _rca, [], _w, _r), do: rule_set

  defp add_new_words(rule_set, rule_codes_array, [new_word | new_words], word, rule) do
    rule_set
    |> add_word(new_word, [])
    |> combine_rule_sets(rule[:combineable], rule_codes_array, new_word, rule[:type])
    |> add_new_words(rule_codes_array, new_words, word, rule)
  end

  defp combine_rule_sets(rule_set, false, _r_c_a, _n_w, _r_type), do: rule_set

  defp combine_rule_sets(rule_set, true, [], _n_w, _r_type), do: rule_set

  defp combine_rule_sets(rule_set, true, [code | rule_codes_array], new_word, rule_type) do
    crule = rule_set[:rules][code]
    combine_rule(
      rule_set,
      crule,
      crule[:combineable],
      rule_type,
      crule[:type],
      new_word
    )
  end

  defp combine_rule(rule_set, nil, _crule_c, _r_type, _cr_type, _n_w), do: rule_set
  defp combine_rule(rule_set, _crule, false, _r_type, _cr_type, _n_w), do: rule_set
  defp combine_rule(rule_set, _crule, true, r_type, cr_type, _n_w) when r_type != cr_type, do: rule_set

  defp combine_rule(rule_set, crule, true, r_type, r_type, new_word) do
    rule_set
    |> RuleApplier.apply_rule_entries(new_word, crule)
    |> (&add_other_words(rule_set, &1)).()
  end

  defp add_other_words(rule_set, []), do: rule_set

  defp add_other_words(rule_set, [word | other_words]) do
    rule_set
    |> add_word(word, [])
    |> add_other_words(other_words)
  end
end
