defmodule HunspellJson.DicParser do
  @moduledoc """
  parse .dic file to generate the dictionaryTable
  """
  def parse(rule_set, data) do
    data
    |> String.replace(~r/^\t.*$/m, "") # Remove comments
    |> String.split("\n")
    |> Enum.drop(1)
    |> (&parse_words({rule_set, &1})).()
  end

  defp parse_words({rule_set, []}), do: rule_set

  defp parse_words({rule_set, [line | data]}) do
    {rule_set, data}
    |> handle_word(String.split(line, "/"))
    |> parse_words
  end

  defp handle_word({rule_set, data}, wordset) when length(wordset) == 1 do
    {add_word(rule_set, List.first(wordset), []), data}
  end

  defp handle_word({rule_set, data}, [word | rule_codes_array]) do
    {rule_set, data}
  end

  defp add_word(rule_set, word, rules) do
    case rule_set[:dictionaryTable][word] do
      nil -> put_in(rule_set[:dictionaryTable][word], rules)
      _ -> put_in(
        rule_set[:dictionaryTable][word],
        rule_set[:dictionaryTable][word] ++ rules
      )
    end
  end
end
