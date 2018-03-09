defmodule HunspellJson.AffParser do
  @moduledoc """
  Parses the aff file and returns a rule set
  """

  alias HunspellJson.RuleCodeParser

  def parse(aff_contents) do
    aff_contents
    |> remove_affix_comments
    |> String.split("\n")
    |> parse_rules
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

  defp parse_rules(data) do
    handle_rule({%{
      flags: %{},
      rules: %{},
      compoundRules: [],
      replacementTable: [],
      dictionaryTable: %{}
    }, data})
  end

  defp handle_rule({rule_set, []}), do: rule_set

  defp handle_rule({rule_set, [rule | data]}) do
    {rule_set, data}
    |> define_rule(String.split(rule, ~r/\s+/))
    |> handle_rule
  end

  defp define_rule({rule_set, data}, [rule_type | rule_data]) when rule_type in ["PFX", "SFX"] do
    [rule_code, combineable, num_entries] = rule_data
    {
      remaining_data, entries
    } = get_entries({rule_set, data}, [], String.to_integer(num_entries))
    {put_in(rule_set[:rules][rule_code], %{
      type: rule_type, combineable: combineable == "Y", entries: entries
    }), remaining_data}
  end

  defp define_rule({rule_set, data}, ["COMPOUNDRULE" | rule_data]) do
    rule_data
    |> List.first
    |> String.to_integer
    |> (&handle_compound_rules({rule_set, data}, &1)).()
  end

  defp define_rule(data_set, ["REP" | rep_data]) when length(rep_data) != 2, do: data_set

  defp define_rule({rule_set, data}, ["REP" | replacement_entry]) do
    {
      put_in(
        rule_set[:replacementTable],
        rule_set[:replacementTable] ++ [replacement_entry]
      ),
      data
    }
  end

  defp define_rule({rule_set, data}, [rule_type | rule_data]) do
    # ONLYINCOMPOUND
    # COMPOUNDMIN
    # FLAG
    # KEEPCASE
    # NEEDAFFIX
    # SET

    {put_in(rule_set[:flags][rule_type], Enum.join(rule_data, " ")), data}
  end

  defp handle_affix_rule({rule_set, [rule | data]}, rule_type, rule_data) do
    {rule_set, data, nil}
  end

  defp get_entries({rule_set, data}, entries, 0), do: {data, entries}

  defp get_entries({rule_set, [line | data]}, entries, num_entries) do
    [
      rule_type,
      _rule_code,
      remove_part,
      addition_parts,
      regex_to_match
    ] = String.split(line, ~r/\s+/)
    [add | continuation] = String.split(addition_parts, "/")
    {_, match} = get_match(regex_to_match, rule_type)
    {_, remove} = get_remove_chars(remove_part, rule_type)
    continuation_classes = RuleCodeParser.parse(
      rule_set[:flags], List.first(continuation)
    )
    get_entries(
      {rule_set, data},
      entries ++ [%{
        add: if(add == "0", do: "", else: add),
        continuationClasses: continuation_classes,
        match: match,
        remove: remove
      }],
      num_entries - 1
    )
  end

  defp get_remove_chars("0", _rule_type), do: {:ok, nil}

  defp get_remove_chars(remove_part, "SFX"),  do: Regex.compile(remove_part <> "$")
  defp get_remove_chars(remove_part, _rule_type), do: {:ok, remove_part}

  defp get_match(".", _rule_type), do: {:ok, nil}

  defp get_match(regex, "SFX"), do: Regex.compile(regex <> "$")
  defp get_match(regex, _rule_type), do: Regex.compile("^" <> regex)

  defp handle_compound_rules(data_set, 0), do: data_set

  defp handle_compound_rules({rule_set, [line | data]}, n) do
    line
    |> String.split(~r/\s/)
    |> List.last
    |> (&handle_compound_rules({
      put_in(rule_set[:compoundRules], rule_set[:compoundRules] ++ [&1]), data
    }, n - 1)).()
  end
end
