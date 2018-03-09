defmodule HunspellJson.WordRuleParser do
  @moduledoc """
  parses rule per words and adds them to dictionaryTable
  """
  alias HunspellJson.RuleApplier

  def add_word(rule_set, word, rules) do
    rule_set[:dictionaryTable]
    |> Map.get(word, [])
    |> (&put_in(rule_set[:dictionaryTable][word], &1 ++ rules)).()
  end

  def parse_rule_codes(rule_set, _word, []), do: rule_set

  def parse_rule_codes(rule_set, word, [code | rule_codes_array]) do
    rule_set
    |> parse_rule(word, rule_set[:rules][code], rule_codes_array)
    |> add_code(word, code)
    |> parse_rule_codes(word, rule_codes_array)
  end

  defp parse_rule(rule_set, _word, nil, rule_codes_array), do: rule_set

  defp parse_rule(rule_set, word, rule, rule_codes_array) do
    word
    |> RuleApplier.apply_rule_entries(rule, rule_set[:rules])
    |> (&add_new_words(rule_set, &1, rule_codes_array, word, rule)).()
  end

  defp add_new_words(rule_set, [], _rca, _w, _r), do: rule_set

  defp add_new_words(rule_set, [new_word | new_words], rule_codes_array, word, rule) do
    rule_set
    |> add_word(new_word, [])
    |> combine_rule_sets(
      rule[:combineable],
      rule_codes_array,
      new_word,
      rule[:type]
    )
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
    new_word
    |> RuleApplier.apply_rule_entries(crule, rule_set[:rules])
    |> (&add_other_words(rule_set, &1)).()
  end

  defp add_other_words(rule_set, []), do: rule_set

  defp add_other_words(rule_set, [word | other_words]) do
    rule_set
    |> add_word(word, [])
    |> add_other_words(other_words)
  end

  defp add_code(rule_set, word, code) do
    if Map.has_key?(rule_set[:compoundRuleCodes], code) do
      put_in(
        rule_set[:compoundRuleCodes][code],
        rule_set[:compoundRuleCodes][code] ++ [word]
      )
    else
      rule_set
    end
  end

end
