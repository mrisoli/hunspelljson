defmodule HunspellJson.RuleApplier do
  @moduledoc """
  recursively applies the rules to the given word
  """
  def apply_rule_entries(word, rule, rules) do
    apply_entries([], rule[:entries], word, rule, rules)
  end

  defp apply_entries(new_words, [], _w, _r, _rules), do: new_words

  defp apply_entries(new_words, [entry | entries], word, rule, rules) do
    new_words
    |> apply_match(entry[:match], entry, word, rule, rules)
    |> apply_entries(entries, word, rule, rules)
  end

  defp apply_match(new_words, nil, entry, word, rule, rules) do
    gen_new_words(new_words, entry, word, rule, rules)
  end

  defp apply_match(new_words, match, entry, word, rule, rules) do
    if Regex.match?(match, word) do
      gen_new_words(new_words, entry, word, rule, rules)
    else
      new_words
    end
  end

  defp gen_new_words(new_words, entry, word, rule, rules) do
    new_word = word
               |> remove_affix(entry[:remove])
               |> add_affix(rule[:type], entry[:add])
    new_words ++ [new_word]
    |> add_continuation(
      entry[:continuationClasses],
      rules,
      new_word
    )
  end

  defp remove_affix(word, nil), do: word
  defp remove_affix(word, remove), do: String.replace(word, remove, "")

  defp add_affix(word, "SFX", add), do: word <> add
  defp add_affix(word, _, add), do: add <> word

  defp add_continuation(new_words, [], rules, new_word), do: new_words

  defp add_continuation(new_words, [c_class | classes], rules, new_word) do
    add_c_rule(new_words, rules[c_class], new_word, rules)
  end

  defp add_c_rule(new_words, nil, _nw, _rules), do: new_words

  defp add_c_rule(new_words, c_rule, new_word, rules) do
    new_words ++ apply_rule_entries(new_word, c_rule, rules)
  end
end
