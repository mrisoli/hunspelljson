defmodule HunspellJson.RuleApplier do
  @moduledoc """
  recursively applies the rules to the given word
  """
  def apply_rule_entries(rule_set, word, rule) do
    apply_entries(rule_set, word, rule, [], rule[:entries])
  end

  defp apply_entries(rule_set, word, rule, new_words, []), do: new_words
  defp apply_entries(rule_set, word, rule, new_words, [entry | entries]) do
    if entry[:match] != nil and Regex.match?(entry[:match], word) do
      new_word = word
      |> remove_affix(entry[:remove])
      |> add_affix(rule[:type], entry[:add])
      add_continuation_classes(
        rule_set,
        word,
        rule,
        new_words ++ [new_word],
        entries,
        entry[:continuationClasses]
      )
    else
      apply_entries(rule_set, word, rule, new_words, entries)
    end
  end

  defp remove_affix(word, nil), do: word
  defp remove_affix(word, remove), do: String.replace(word, remove, "")

  defp add_affix(word, "SFX", add), do: word <> add
  defp add_affix(word, _, add), do: add <> word

  defp add_continuation_classes(rule_set, word, rule, new_words, entries, []) do
    apply_entries(rule_set, word, rule, new_words, entries)
  end

  defp add_continuation_classes(
    rule_set,
    word,
    rule,
    new_words,
    entries,
    [cont_class | classes]
  ) do
    cont_rule = rule_set[:rules][cont_class]
    updated_words = case cont_rule do
      nil -> new_words
      _ -> new_words ++ apply_rule_entries(rule_set, List.last(new_words), cont_rule)
    end
    add_continuation_classes(
      rule_set,
      word,
      rule,
      updated_words,
      entries,
      classes
    )
  end
end
